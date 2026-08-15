import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"

Flickable {
    id: root
    property var diagnostics: []
    property string diagnosticStatus: "Run a check whenever something feels off"
    property string updateStatus: "Development build"
    contentWidth:width; contentHeight:content.implicitHeight; clip:true
    boundsBehavior:Flickable.StopAtBounds
    ColumnLayout {
        id:content; width:root.width; spacing:Theme.space12
        SettingToggleRow { Layout.fillWidth:true; icon:"bedtime"; title:"Night Light"; subtitle:!ControlService.nightLightAvailable?"hyprsunset unavailable":checked?ShellSettings.nightLightTemperature+" K":"Natural display colors"; available:ControlService.nightLightAvailable; checked:ShellSettings.nightLightEnabled; onToggled:checked=>{ShellSettings.nightLightEnabled=checked;ControlService.applyNightLight();} }
        SettingChoiceRow { Layout.fillWidth:true; title:"Night Light warmth"; subtitle:"Lower values are warmer"; options:[{label:"Warm",value:3500},{label:"Balanced",value:4500},{label:"Gentle",value:5500}]; value:ShellSettings.nightLightTemperature; onChosen:value=>{ShellSettings.nightLightTemperature=value;if(ShellSettings.nightLightEnabled)ControlService.applyNightLight();} }
        SettingToggleRow { Layout.fillWidth:true; icon:"timer"; title:"Screen timeout"; subtitle:!ControlService.idleAvailable?"hypridle unavailable":checked?"Automatic after "+Math.round(ShellSettings.idleTimeoutSeconds/60)+" minutes":"Disabled"; available:ControlService.idleAvailable; checked:ShellSettings.idleEnabled; onToggled:checked=>ShellSettings.idleEnabled=checked }
        SettingChoiceRow { Layout.fillWidth:true; title:"Automatic screen timeout"; subtitle:"Idle duration before Ayame acts"; options:[{label:"5 min",value:300},{label:"10 min",value:600},{label:"20 min",value:1200},{label:"30 min",value:1800}]; value:ShellSettings.idleTimeoutSeconds; onChosen:value=>ShellSettings.idleTimeoutSeconds=value }
        SettingToggleRow { Layout.fillWidth:true; icon:"lock"; title:"Lock before turning the display off"; subtitle:checked?"Authentication required on return":"Display only"; checked:ShellSettings.idleLockEnabled; onToggled:checked=>ShellSettings.idleLockEnabled=checked }

        GlassSurface {
            Layout.fillWidth:true; implicitHeight:diagnosticContent.implicitHeight+Theme.space32; radius:Theme.radiusLarge; depth:1
            ColumnLayout {
                id:diagnosticContent; anchors{left:parent.left;right:parent.right;verticalCenter:parent.verticalCenter;margins:Theme.space16}; spacing:Theme.space12
                RowLayout { Layout.fillWidth:true; ColumnLayout{Layout.fillWidth:true;AppText{text:"Ayame Diagnostics";font.weight:Font.Bold};AppText{text:root.diagnosticStatus;color:Theme.onSurfaceMuted;font.pixelSize:Theme.fontSmall}}; ActionPill{label:doctor.running?"Checking":"Run check";enabled:!doctor.running;primary:true;onActivated:doctor.running=true}; ActionPill{label:"Test notification";onActivated:{actionProcess.command=["bash",Quickshell.shellDir+"/../../scripts/ayame-doctor","test-notification"];actionProcess.running=true}} }
                Repeater {
                    model:root.diagnostics
                    Rectangle {
                        required property var modelData; Layout.fillWidth:true; implicitHeight:52; radius:Theme.radiusMedium; color:Theme.glassHighest
                        RowLayout { anchors{fill:parent;margins:Theme.space12}; Rectangle{width:9;height:9;radius:5;color:parent.parent.modelData.state==="healthy"?Theme.success:parent.parent.modelData.state==="error"?Theme.danger:Theme.warning}; ColumnLayout{Layout.fillWidth:true;spacing:0;AppText{text:parent.parent.parent.modelData.label;font.weight:Font.Bold};AppText{Layout.fillWidth:true;text:parent.parent.parent.modelData.detail;color:Theme.onSurfaceMuted;font.pixelSize:Theme.fontSmall;elide:Text.ElideRight}}; AppText{text:parent.parent.modelData.state;color:parent.parent.modelData.state==="healthy"?Theme.success:Theme.warning;font.pixelSize:Theme.fontSmall;font.weight:Font.Bold} }
                    }
                }
            }
        }
        GlassSurface {
            Layout.fillWidth:true; implicitHeight:82; radius:Theme.radiusLarge; depth:1
            RowLayout { anchors{fill:parent;margins:Theme.space16}; AppIcon{icon:"system_update";backgroundColor:Theme.accentSoft;iconColor:Theme.onAccentSoft;implicitWidth:42;implicitHeight:42}; ColumnLayout{Layout.fillWidth:true;AppText{text:"Ayame Shell V2";font.weight:Font.Bold};AppText{text:root.updateStatus;color:Theme.onSurfaceMuted;font.pixelSize:Theme.fontSmall}}; ActionPill{label:updateProcess.running?"Checking":"Check for updates";enabled:!updateProcess.running;onActivated:{updateProcess.command=["git","ls-remote","--exit-code","origin","refs/heads/main"];updateProcess.running=true}} }
        }
    }
    Process {
        id:doctor; command:["bash",Quickshell.shellDir+"/../../scripts/ayame-doctor","status"]
        stdout:StdioCollector{onStreamFinished:{const rows=[];for(const line of text.trim().split("\n")){const f=line.split("|");if(f.length>=4)rows.push({id:f[0],label:f[1],state:f[2],detail:f.slice(3).join("|")});}root.diagnostics=rows;const failures=rows.filter(row=>row.state==="error").length;root.diagnosticStatus=failures?failures+" issue"+(failures===1?"":"s")+" need attention":"Everything essential looks healthy";}}
    }
    Process { id:actionProcess }
    Process { id:updateProcess; onExited:(exitCode,exitStatus)=>root.updateStatus=exitCode===0?"Remote repository reachable":"Could not check for updates" }
}
