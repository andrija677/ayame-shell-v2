# Development

Run the isolated design preview without stopping Ayame Shell V1:

```sh
./scripts/ayame-v2-preview
```

Validate the shell and helper scripts:

```sh
./scripts/check
```

The preview is deliberately a regular floating window. Until V2 reaches an
integration-testing milestone, it must not become a layer-shell surface, claim
the notification server, reserve screen space, bind global shortcuts, change
the wallpaper, or execute session actions while V1 is active.
