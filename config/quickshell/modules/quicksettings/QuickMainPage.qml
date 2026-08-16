import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"

Flickable {
    id:root
    property var hostWindow:null
    property bool keepAwake:false
    property bool outputsOpen:false
    signal wifiRequested()
    signal bluetoothRequested()
    signal keybindsRequested()
    signal clipboardRequested()
    signal displaysRequested()
    signal settingsRequested()
    signal powerRequested()
    readonly property var sink:Pipewire.defaultAudioSink
    readonly property var audio:sink?.audio??null
    readonly property var audioSinks:{Pipewire.nodes.values;const sinks=[];for(const node of Pipewire.nodes.values){if(node.ready&&node.audio&&(node.type&PwNodeType.AudioSink)!==0)sinks.push(node);}sinks.sort((a,b)=>a.description.localeCompare(b.description));return sinks;}
    readonly property var battery:UPower.displayDevice
    readonly property bool batteryAvailable:battery?.isPresent&&battery?.isLaptopBattery
    readonly property var powerProfileOptions:{const options=[{label:"Saver",value:PowerProfile.PowerSaver},{label:"Balanced",value:PowerProfile.Balanced}];if(PowerProfiles.hasPerformanceProfile)options.push({label:"Performance",value:PowerProfile.Performance});return options;}
    contentWidth:width;contentHeight:content.implicitHeight;clip:true;boundsBehavior:Flickable.StopAtBounds
    PwObjectTracker{objects:root.audioSinks}
    IdleInhibitor{window:root.hostWindow;enabled:root.keepAwake}
    ColumnLayout {
        id:content;width:root.width;spacing:Theme.space12
        MediaCard{Layout.fillWidth:true}
        SettingSliderRow{Layout.fillWidth:true;title:"Volume";subtitle:root.audio?.muted?"Muted":root.sink?.description||"Default output";available:root.audio!==null;from:0;to:1;value:root.audio?.volume??0;valueText:root.audio?.muted?"Muted":Math.round(value*100)+"%";onMoved:value=>root.audio.volume=value}
        RowLayout{Layout.fillWidth:true;ActionPill{label:root.audio?.muted?"Unmute":"Mute";enabled:root.audio!==null;onActivated:root.audio.muted=!root.audio.muted}ActionPill{visible:root.audioSinks.length>1;label:root.outputsOpen?"Hide outputs":"Audio outputs";onActivated:root.outputsOpen=!root.outputsOpen}Item{Layout.fillWidth:true}}
        Repeater{model:root.outputsOpen?root.audioSinks:[];GlassSurface{id:outputRow;required property var modelData;Layout.fillWidth:true;implicitHeight:52;radius:Theme.radiusMedium;depth:1;active:modelData===Pipewire.defaultAudioSink;RowLayout{anchors{fill:parent;margins:Theme.space12}AppIcon{icon:"speaker";implicitWidth:30;implicitHeight:30}AppText{Layout.fillWidth:true;text:outputRow.modelData.description||outputRow.modelData.name;elide:Text.ElideRight}ActionPill{label:outputRow.modelData===Pipewire.defaultAudioSink?"Default":"Use";checked:outputRow.modelData===Pipewire.defaultAudioSink;onActivated:Pipewire.preferredDefaultAudioSink=outputRow.modelData}}}}
        SettingSliderRow{Layout.fillWidth:true;visible:ControlService.brightnessAvailable;title:"Screen brightness";subtitle:"Hardware backlight";from:1;to:100;value:ControlService.brightness;valueText:Math.round(value)+"%";onMoved:value=>ControlService.setBrightness(value)}
        SettingSliderRow{Layout.fillWidth:true;visible:ControlService.keyboardBacklightAvailable;title:"Keyboard backlight";subtitle:"Keyboard illumination";from:0;to:100;value:ControlService.keyboardBrightness;valueText:Math.round(value)+"%";onMoved:value=>ControlService.setKeyboardBrightness(value)}

        GridLayout{Layout.fillWidth:true;columns:2;columnSpacing:Theme.space12;rowSpacing:Theme.space12
            SettingToggleRow{Layout.fillWidth:true;icon:"wifi";title:ControlService.networkName||"Network";subtitle:ControlService.networkingBusy?"Switching…":!ControlService.networkingAvailable?"Unavailable":ControlService.networkingEnabled?"Connected":"Off";available:ControlService.networkingAvailable&&!ControlService.networkingBusy;checked:ControlService.networkingEnabled;onToggled:ControlService.toggleNetworking()}
            SettingToggleRow{Layout.fillWidth:true;icon:"bluetooth";title:"Bluetooth";subtitle:!ControlService.bluetoothAvailable?"No adapter":ControlService.bluetoothEnabled?"On":"Off";available:ControlService.bluetoothAvailable;checked:ControlService.bluetoothEnabled;onToggled:ControlService.toggleBluetooth()}
        }
        RowLayout{Layout.fillWidth:true;ActionPill{Layout.fillWidth:true;label:"Wi-Fi networks";enabled:ControlService.wifiDevice!==null;onActivated:root.wifiRequested()}ActionPill{Layout.fillWidth:true;label:"Bluetooth devices";enabled:ControlService.bluetoothAvailable;onActivated:root.bluetoothRequested()}}
        GridLayout{Layout.fillWidth:true;columns:2;columnSpacing:Theme.space12;rowSpacing:Theme.space12
            SettingToggleRow{Layout.fillWidth:true;icon:"coffee";title:"Keep awake";subtitle:checked?"Screen stays on":"Uses idle rules";checked:root.keepAwake;onToggled:checked=>root.keepAwake=checked}
            SettingToggleRow{Layout.fillWidth:true;icon:"sports_esports";title:"Gaming mode";subtitle:SessionService.gameModeBusy?"Switching…":checked?"Effects reduced":"Normal desktop";available:!SessionService.gameModeBusy;checked:SessionService.gameMode;onToggled:SessionService.toggleGameMode()}
            SettingToggleRow{Layout.fillWidth:true;icon:"bedtime";title:"Night light";subtitle:!ControlService.nightLightAvailable?"Unavailable":checked?ShellSettings.nightLightTemperature+" K":"Off";available:ControlService.nightLightAvailable&&!ControlService.nightLightBusy;checked:ShellSettings.nightLightEnabled;onToggled:ControlService.toggleNightLight()}
            SettingToggleRow{Layout.fillWidth:true;icon:"do_not_disturb_on";title:"Focus";subtitle:checked?"Quiet mode":"Notifications on";checked:ShellSettings.doNotDisturb;onToggled:ControlService.toggleDoNotDisturb()}
        }
        SettingChoiceRow{Layout.fillWidth:true;title:"Power profile";subtitle:"Choose performance and battery balance";options:root.powerProfileOptions;value:PowerProfiles.profile;onChosen:value=>PowerProfiles.profile=value}
        GlassSurface{Layout.fillWidth:true;implicitHeight:68;visible:root.batteryAvailable;radius:Theme.radiusLarge;depth:1;RowLayout{anchors{fill:parent;margins:Theme.space16}AppIcon{icon:"battery_full";backgroundColor:Theme.accentSoft;iconColor:Theme.onAccentSoft;implicitWidth:38;implicitHeight:38}ColumnLayout{Layout.fillWidth:true;AppText{text:"Battery";font.weight:Font.Bold}AppText{text:root.battery?.state===UPowerDeviceState.Charging?"Charging":"On battery";color:Theme.onSurfaceMuted;font.pixelSize:Theme.fontSmall}}AppText{text:Math.round((root.battery?.percentage??0)*100)+"%";font.family:Theme.numericFontFamily;font.weight:Font.Bold}}}
        SectionTitle{title:"Utilities";detail:"Everything V1 carried"}
        GridLayout{Layout.fillWidth:true;columns:2;columnSpacing:Theme.space8;rowSpacing:Theme.space8
            ActionPill{Layout.fillWidth:true;label:"Keybinds";symbol:"⌨";onActivated:root.keybindsRequested()}
            ActionPill{Layout.fillWidth:true;label:"Screenshot";symbol:"◉";onActivated:RecordingService.showCapturePill()}
            ActionPill{Layout.fillWidth:true;label:"Ayame Settings";symbol:"⚙";onActivated:root.settingsRequested()}
            ActionPill{Layout.fillWidth:true;label:"Clipboard";symbol:"▣";onActivated:root.clipboardRequested()}
            ActionPill{Layout.fillWidth:true;label:"Displays";symbol:"▤";enabled:ControlService.displaysAvailable;onActivated:root.displaysRequested()}
            ActionPill{Layout.fillWidth:true;label:"Power";symbol:"⏻";onActivated:root.powerRequested()}
        }
    }
}
