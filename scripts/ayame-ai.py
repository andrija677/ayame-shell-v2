#!/usr/bin/env python3
"""Streaming provider bridge for Ayame Shell V2.

Prompts and responses use JSON lines on standard streams so message contents
never appear in the process list. Existing Ayame V1 keyring entries are reused.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request


def emit(kind: str, **values: object) -> None:
    print(json.dumps({"type": kind, **values}, ensure_ascii=False), flush=True)


def secret(provider: str) -> str:
    if not shutil.which("secret-tool"):
        return ""
    result = subprocess.run(
        ["secret-tool", "lookup", "service", "ayame-shell-ai", "provider", provider],
        check=False,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip() if result.returncode == 0 else ""


def start_secret_service() -> bool:
    for command in (["ksecretd"], ["gnome-keyring-daemon", "--start", "--components=secrets"]):
        try:
            subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, start_new_session=True)
            time.sleep(0.8)
            return True
        except FileNotFoundError:
            continue
    return False


def secret_action(arguments: list[str], input_text: str | None = None) -> subprocess.CompletedProcess:
    result = subprocess.run(["secret-tool", *arguments], input=input_text, check=False,
                            capture_output=True, text=True)
    if result.returncode and "not activatable" in result.stderr.lower() and start_secret_service():
        result = subprocess.run(["secret-tool", *arguments], input=input_text, check=False,
                                capture_output=True, text=True)
    return result


def store_secret(provider: str, value: str) -> int:
    if not value:
        return 2
    if not shutil.which("secret-tool"):
        print("Install libsecret to store API keys securely", file=sys.stderr)
        return 127
    result = secret_action(["store", "--label", f"Ayame AI ({provider})",
                            "service", "ayame-shell-ai", "provider", provider], value)
    if result.returncode:
        print(result.stderr.strip() or "No Secret Service keyring is available", file=sys.stderr)
    return result.returncode


def delete_secret(provider: str) -> int:
    if not shutil.which("secret-tool"):
        print("secret-tool is not installed", file=sys.stderr)
        return 127
    result = secret_action(["clear", "service", "ayame-shell-ai", "provider", provider])
    if result.returncode:
        print(result.stderr.strip(), file=sys.stderr)
    return result.returncode


def provider_test(config: dict) -> int:
    provider = str(config.get("provider") or "gemini")
    model = str(config.get("model") or "").strip()
    if not model:
        raise RuntimeError("Choose a model before testing")
    if provider == "gemini":
        key = secret("gemini")
        if not key:
            raise RuntimeError("Add a Gemini API key before testing")
        url = ("https://generativelanguage.googleapis.com/v1beta/models/"
               + urllib.parse.quote(model, safe="") + "?key=" + urllib.parse.quote(key, safe=""))
        request_object = urllib.request.Request(url, method="GET")
    elif provider == "openai":
        key = secret("openai")
        if not key:
            raise RuntimeError("Add an OpenAI-compatible API key before testing")
        base = str(config.get("baseUrl") or "https://api.openai.com").rstrip("/")
        request_object = urllib.request.Request(base + "/v1/models/" + urllib.parse.quote(model, safe=""),
                                               headers={"Authorization": f"Bearer {key}"}, method="GET")
    elif provider == "ollama":
        base = str(config.get("baseUrl") or "http://127.0.0.1:11434").rstrip("/")
        data = json.dumps({"model": model}).encode()
        request_object = urllib.request.Request(base + "/api/show", data=data,
                                               headers={"Content-Type": "application/json"}, method="POST")
    else:
        raise RuntimeError("Unsupported AI provider")
    with urllib.request.urlopen(request_object, timeout=15) as response:
        response.read(1024)
    print(f"Connected • {model} is available")
    return 0


def request(url: str, headers: dict[str, str], body: dict) -> urllib.response.addinfourl:
    data = json.dumps(body, ensure_ascii=False).encode()
    return urllib.request.urlopen(
        urllib.request.Request(url, data=data, headers=headers, method="POST"),
        timeout=90,
    )


def clean_history(items: list[dict]) -> list[dict[str, str]]:
    history: list[dict[str, str]] = []
    for item in items[-20:]:
        role = str(item.get("role", ""))
        content = str(item.get("content", ""))
        if role in {"user", "assistant"} and content:
            history.append({"role": role, "content": content})
    return history


def stream_openai(config: dict, messages: list[dict[str, str]]) -> None:
    key = secret("openai")
    if not key:
        raise RuntimeError("Add an OpenAI-compatible API key in Ayame V2 Settings")
    base = str(config.get("baseUrl") or "https://api.openai.com").rstrip("/")
    body = {
        "model": config.get("model") or "gpt-4.1-mini",
        "messages": messages,
        "stream": True,
    }
    headers = {"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
    with request(base + "/v1/chat/completions", headers, body) as response:
        for raw in response:
            line = raw.decode("utf-8", "replace").strip()
            if not line.startswith("data:"):
                continue
            payload = line[5:].strip()
            if payload == "[DONE]":
                break
            data = json.loads(payload)
            text = data.get("choices", [{}])[0].get("delta", {}).get("content", "")
            if text:
                emit("delta", text=text)


def stream_gemini(config: dict, messages: list[dict[str, str]]) -> None:
    key = secret("gemini")
    if not key:
        raise RuntimeError("Add a Gemini API key in Ayame V2 Settings")
    model = urllib.parse.quote(str(config.get("model") or "gemini-2.5-flash"), safe="")
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{model}:streamGenerateContent?alt=sse&key={urllib.parse.quote(key, safe='')}"
    )
    contents = [
        {
            "role": "model" if item["role"] == "assistant" else "user",
            "parts": [{"text": item["content"]}],
        }
        for item in messages[1:]
    ]
    body = {
        "system_instruction": {"parts": [{"text": messages[0]["content"]}]},
        "contents": contents,
    }
    with request(url, {"Content-Type": "application/json"}, body) as response:
        for raw in response:
            line = raw.decode("utf-8", "replace").strip()
            if not line.startswith("data:"):
                continue
            data = json.loads(line[5:].strip())
            parts = data.get("candidates", [{}])[0].get("content", {}).get("parts", [])
            for part in parts:
                if part.get("text"):
                    emit("delta", text=part["text"])


def stream_ollama(config: dict, messages: list[dict[str, str]]) -> None:
    base = str(config.get("baseUrl") or "http://127.0.0.1:11434").rstrip("/")
    body = {
        "model": config.get("model") or "llama3.2",
        "messages": messages,
        "stream": True,
    }
    with request(base + "/api/chat", {"Content-Type": "application/json"}, body) as response:
        for raw in response:
            if not raw.strip():
                continue
            data = json.loads(raw)
            text = data.get("message", {}).get("content", "")
            if text:
                emit("delta", text=text)
            if data.get("done"):
                break


def chat() -> int:
    config = json.loads(sys.stdin.readline())
    messages = [{"role": "system", "content": str(config["systemPrompt"])}]
    messages.extend(clean_history(config.get("history", [])))
    provider = str(config.get("provider") or "gemini")
    try:
        if provider == "gemini":
            stream_gemini(config, messages)
        elif provider == "openai":
            stream_openai(config, messages)
        elif provider == "ollama":
            stream_ollama(config, messages)
        else:
            raise RuntimeError("Unsupported AI provider")
        emit("done")
        return 0
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", "replace")
        try:
            detail = json.loads(detail).get("error", {}).get("message", detail)
        except json.JSONDecodeError:
            pass
        emit("error", message=f"Provider error {error.code}: {detail[:240]}")
    except (urllib.error.URLError, TimeoutError) as error:
        emit("error", message=f"Could not reach the AI provider: {getattr(error, 'reason', error)}")
    except (KeyError, ValueError, RuntimeError) as error:
        emit("error", message=str(error))
    return 1


def main() -> int:
    action = sys.argv[1] if len(sys.argv) > 1 else ""
    provider = sys.argv[2] if len(sys.argv) > 2 else ""
    if action == "chat":
        return chat()
    if action == "key-store":
        return store_secret(provider, sys.stdin.readline().strip())
    if action == "key-delete":
        return delete_secret(provider)
    if action == "key-status":
        print("1" if secret(provider) else "0")
        return 0
    if action == "test":
        try:
            return provider_test(json.loads(sys.stdin.readline()))
        except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError,
                KeyError, ValueError, RuntimeError) as error:
            print(str(error), file=sys.stderr)
            return 1
    print("Usage: ayame-ai.py {chat|test|key-store|key-delete|key-status} [provider]", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
