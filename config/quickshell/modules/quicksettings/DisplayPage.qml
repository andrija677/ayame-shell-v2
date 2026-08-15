import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../components"
import "../../services"
import "../../theme"

Flickable {
    id:root
    property var selectedDisplay:null
    property var modes:[]
    property string selectedMode:""
    property real selectedScale:1
    property string applyStatus:""
    signal backRequested()
    function selectDisplay(display){selectedDisplay=display;selectedMode=display.width+"x"+display.height+"@"+display.rate;selectedScale=display.scale;applyStatus="";modeProcess.command=["bash",ControlService.controlScript,"display-modes",display.name];modeProcess.running=true;}
    contentWidth:width;contentHeight:content.implicitHeight;clip:true;boundsBehavior:Flickable.StopAtBounds
    ColumnLayout{id:content;width:root.width;spacing:Theme.space12
        RowLayout{Layout.fillWidth:true;IconButton{icon:"arrow_back";accessibleName:"Back";onActivated:root.backRequested()}ColumnLayout{Layout.fillWidth:true;AppText{text:"Display controls";font.pixelSize:Theme.fontTitle;font.weight:Font.Bold}AppText{text:"Resolution, refresh rate and scaling";color:Theme.onSurfaceMuted;font.pixelSize:Theme.fontSmall}}ActionPill{label:"Refresh";onActivated:ControlService.refreshDisplays()}}
        Flow{Layout.fillWidth:true;spacing:Theme.space8;Repeater{model:ControlService.displays;ActionPill{required property var modelData;label:modelData.name;checked:root.selectedDisplay?.name===modelData.name;onActivated:root.selectDisplay(modelData)}}}
        AppText{Layout.fillWidth:true;Layout.preferredHeight:100;visible:root.selectedDisplay===null;text:"Choose a display to adjust it. Ayame preserves its current desktop position.";color:Theme.onSurfaceMuted;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;wrapMode:Text.WordWrap}
        ColumnLayout{Layout.fillWidth:true;visible:root.selectedDisplay!==null;spacing:Theme.space12;AppText{Layout.fillWidth:true;text:root.selectedDisplay?.description??"";font.weight:Font.Bold;elide:Text.ElideRight}SectionTitle{title:"Display mode";detail:root.modes.length+" available"}Repeater{model:root.modes;ActionPill{required property string modelData;Layout.fillWidth:true;label:modelData;checked:root.selectedMode===modelData;onActivated:root.selectedMode=modelData}}SettingChoiceRow{Layout.fillWidth:true;title:"Scale";subtitle:"Integer scales keep layer input aligned";options:[{label:"1×",value:1},{label:"2×",value:2}];value:root.selectedScale;onChosen:value=>root.selectedScale=value}ActionPill{label:"Save for next login";primary:true;enabled:!applyProcess.running;onActivated:{root.applyStatus="Saving…";applyProcess.command=["bash",ControlService.controlScript,"display-save",root.selectedDisplay.name,root.selectedMode,String(root.selectedScale)];applyProcess.running=true}}AppText{Layout.fillWidth:true;text:root.applyStatus;visible:text.length>0;color:text.startsWith("Could")?Theme.danger:Theme.success;horizontalAlignment:Text.AlignHCenter}}
    }
    Process{id:modeProcess;stdout:StdioCollector{onStreamFinished:root.modes=text.trim()?text.trim().split("\n"):[]}}
    Process{id:applyProcess;stdout:StdioCollector{onStreamFinished:if(text.trim()==="saved")root.applyStatus="Saved • applies after logging out and back in"}stderr:StdioCollector{onStreamFinished:if(text.trim())root.applyStatus="Could not save • "+text.trim()}onExited:(code,status)=>{if(code!==0&&!root.applyStatus.startsWith("Could"))root.applyStatus="Could not save display settings";ControlService.refreshDisplays();}}
    Component.onCompleted:ControlService.refreshDisplays()
}
