import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../components"
import "../../settings"
import "../../theme"

Flickable {
    id:root
    property string keyStatus:""
    property string keyAction:"status"
    contentWidth:width; contentHeight:content.implicitHeight; clip:true
    boundsBehavior:Flickable.StopAtBounds
    function checkKey(){if(ShellSettings.aiProvider==="ollama"){keyStatus="Ollama stays local and needs no API key.";return;}keyAction="status";keyProcess.command=["python3",Quickshell.shellDir+"/../../scripts/ayame-ai.py","key-status",ShellSettings.aiProvider];keyProcess.running=true;}
    function saveKey(){if(!keyInput.text.trim()||keyProcess.running)return;keyAction="store";keyProcess.command=["python3",Quickshell.shellDir+"/../../scripts/ayame-ai.py","key-store",ShellSettings.aiProvider];keyProcess.running=true;}
    function removeKey(){if(keyProcess.running)return;keyAction="delete";keyProcess.command=["python3",Quickshell.shellDir+"/../../scripts/ayame-ai.py","key-delete",ShellSettings.aiProvider];keyProcess.running=true;}
    function testConnection(){if(keyProcess.running)return;keyAction="test";keyStatus="Testing connection…";keyProcess.command=["python3",Quickshell.shellDir+"/../../scripts/ayame-ai.py","test"];keyProcess.running=true;}
    ColumnLayout {
        id:content; width:root.width; spacing:Theme.space12
        SettingToggleRow{Layout.fillWidth:true;icon:"auto_awesome";title:"AI companion";subtitle:checked?"Visible in the dock":"Disabled • no network activity";checked:ShellSettings.aiEnabled;onToggled:checked=>ShellSettings.aiEnabled=checked}
        SettingChoiceRow{Layout.fillWidth:true;title:"Provider";subtitle:"Choose cloud or local inference";options:[{label:"Gemini",value:"gemini"},{label:"OpenAI",value:"openai"},{label:"Ollama",value:"ollama"}];value:ShellSettings.aiProvider;onChosen:value=>{ShellSettings.aiProvider=value;ShellSettings.aiModel=value==="gemini"?"gemini-2.5-flash":value==="openai"?"gpt-4.1-mini":"llama3.2";root.checkKey();}}
        GlassSurface{Layout.fillWidth:true;implicitHeight:60;radius:Theme.radiusLarge;depth:1;TextField{anchors{fill:parent;margins:Theme.space12}text:ShellSettings.aiModel;placeholderText:"Model name";color:Theme.onSurface;placeholderTextColor:Theme.outline;font.family:Theme.fontFamily;background:null;onEditingFinished:ShellSettings.aiModel=text.trim()}}
        GlassSurface{Layout.fillWidth:true;implicitHeight:60;visible:ShellSettings.aiProvider!=="gemini";radius:Theme.radiusLarge;depth:1;TextField{anchors{fill:parent;margins:Theme.space12}text:ShellSettings.aiBaseUrl;placeholderText:ShellSettings.aiProvider==="ollama"?"http://127.0.0.1:11434":"https://api.openai.com";color:Theme.onSurface;placeholderTextColor:Theme.outline;font.family:Theme.fontFamily;background:null;onEditingFinished:ShellSettings.aiBaseUrl=text.trim()}}
        SettingChoiceRow{Layout.fillWidth:true;title:"Personality";subtitle:"How Ayame speaks";options:[{label:"Assistant",value:"assistant"},{label:"Cat-girl",value:"cat"},{label:"Fox-girl",value:"fox"},{label:"Custom",value:"custom"}];value:ShellSettings.aiPersonality;onChosen:value=>ShellSettings.aiPersonality=value}
        GlassSurface{Layout.fillWidth:true;implicitHeight:140;visible:ShellSettings.aiPersonality==="custom";radius:Theme.radiusLarge;depth:1;TextArea{anchors{fill:parent;margins:Theme.space12}text:ShellSettings.aiCustomPrompt;placeholderText:"Write the custom system prompt…";color:Theme.onSurface;placeholderTextColor:Theme.outline;font.family:Theme.fontFamily;wrapMode:TextEdit.Wrap;background:null;onTextChanged:ShellSettings.aiCustomPrompt=text}}
        GlassSurface {
            Layout.fillWidth:true; implicitHeight:keyContent.implicitHeight+Theme.space32; visible:ShellSettings.aiProvider!=="ollama"; radius:Theme.radiusLarge; depth:1
            ColumnLayout{id:keyContent;anchors{left:parent.left;right:parent.right;verticalCenter:parent.verticalCenter;margins:Theme.space16}spacing:Theme.space12;AppText{text:"Secure API key";font.weight:Font.Bold}RowLayout{Layout.fillWidth:true;Rectangle{Layout.fillWidth:true;implicitHeight:44;radius:Theme.radiusPill;color:Theme.glassHighest;TextInput{id:keyInput;anchors{fill:parent;leftMargin:Theme.space16;rightMargin:Theme.space16}verticalAlignment:TextInput.AlignVCenter;echoMode:TextInput.Password;color:Theme.onSurface;font.family:Theme.fontFamily;AppText{anchors.verticalCenter:parent.verticalCenter;visible:parent.text.length===0;text:"Stored in your system keyring";color:Theme.outline}}}ActionPill{label:"Save key";enabled:keyInput.text.trim().length>0&&!keyProcess.running;onActivated:root.saveKey()}ActionPill{label:"Remove";enabled:!keyProcess.running;onActivated:root.removeKey()}}RowLayout{Layout.fillWidth:true;AppText{Layout.fillWidth:true;text:root.keyStatus;color:Theme.onSurfaceMuted;font.pixelSize:Theme.fontSmall;wrapMode:Text.WordWrap}ActionPill{label:keyProcess.running&&root.keyAction==="test"?"Testing":"Test connection";enabled:!keyProcess.running;primary:true;onActivated:root.testConnection()}}}
        }
        AppText{Layout.fillWidth:true;text:"Ayame never gives the model automatic command, clipboard, screenshot, or file access.";color:Theme.outline;font.pixelSize:Theme.fontSmall;wrapMode:Text.WordWrap}
    }
    Process{id:keyProcess;stdinEnabled:true;property string outputText:"";property string failureText:"";stdout:StdioCollector{onStreamFinished:{keyProcess.outputText=text.trim();if(root.keyAction==="status")root.keyStatus=text.trim()==="1"?"A key is stored securely.":"No key stored yet.";}}stderr:StdioCollector{onStreamFinished:keyProcess.failureText=text.trim()}onStarted:{outputText="";failureText="";if(root.keyAction==="store")write(keyInput.text.trim()+"\n");else if(root.keyAction==="test")write(JSON.stringify({provider:ShellSettings.aiProvider,model:ShellSettings.aiModel,baseUrl:ShellSettings.aiBaseUrl})+"\n");}onExited:(code,status)=>{if(root.keyAction==="store"){root.keyStatus=code===0?"Key saved securely.":failureText||"The key could not be saved.";if(code===0)keyInput.text="";}else if(root.keyAction==="delete")root.keyStatus=code===0?"Key removed.":failureText||"The key could not be removed.";else if(root.keyAction==="test")root.keyStatus=code===0?outputText:failureText||"Connection test failed.";root.keyAction="status";}}
    Component.onCompleted:checkKey()
}
