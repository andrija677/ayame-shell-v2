import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"

Flickable {
    id:root
    property string query:""
    signal backRequested()
    readonly property var filtered:ClipboardService.entries.filter(entry=>!query||entry.preview.toLowerCase().includes(query.toLowerCase()))
    contentWidth:width;contentHeight:content.implicitHeight;clip:true;boundsBehavior:Flickable.StopAtBounds
    ColumnLayout{id:content;width:root.width;spacing:Theme.space12
        RowLayout{Layout.fillWidth:true;IconButton{icon:"arrow_back";accessibleName:"Back";onActivated:root.backRequested()}ColumnLayout{Layout.fillWidth:true;AppText{text:"Clipboard history";font.pixelSize:Theme.fontTitle;font.weight:Font.Bold}AppText{text:ShellSettings.clipboardHistoryEnabled?"Text and images stay on this device":"Disabled for privacy";color:Theme.onSurfaceMuted;font.pixelSize:Theme.fontSmall}}ToggleSwitch{checked:ShellSettings.clipboardHistoryEnabled;accessibleName:"Clipboard history";onToggled:checked=>ShellSettings.clipboardHistoryEnabled=checked}ActionPill{label:"Clear";enabled:ShellSettings.clipboardHistoryEnabled&&ClipboardService.entries.length>0;onActivated:ClipboardService.run("clear")}}
        Rectangle{Layout.fillWidth:true;implicitHeight:44;radius:Theme.radiusPill;color:Theme.glassHighest;RowLayout{anchors{fill:parent;leftMargin:Theme.space16;rightMargin:Theme.space16}AppIcon{icon:"search";implicitWidth:22;implicitHeight:22;iconSize:18}TextInput{Layout.fillWidth:true;color:Theme.onSurface;font.family:Theme.fontFamily;font.pixelSize:Theme.fontBody;onTextChanged:root.query=text;AppText{anchors.verticalCenter:parent.verticalCenter;visible:parent.text.length===0;text:"Search clipboard";color:Theme.outline}}}}
        AppText{Layout.fillWidth:true;Layout.preferredHeight:100;visible:!ShellSettings.clipboardHistoryEnabled||root.filtered.length===0;text:!ShellSettings.clipboardHistoryEnabled?"Enable clipboard history to begin. Password-manager entries are always ignored.":"Your clipboard history is empty.";color:Theme.onSurfaceMuted;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;wrapMode:Text.WordWrap}
        Repeater{model:root.filtered;GlassSurface{id:clipRow;required property var modelData;Layout.fillWidth:true;implicitHeight:modelData.kind==="image"?110:70;radius:Theme.radiusLarge;depth:1;RowLayout{anchors{fill:parent;margins:Theme.space12}Image{visible:clipRow.modelData.kind==="image";Layout.preferredWidth:visible?88:0;Layout.fillHeight:true;source:visible?"file://"+clipRow.modelData.path:"";fillMode:Image.PreserveAspectCrop;asynchronous:true;cache:false}ColumnLayout{Layout.fillWidth:true;AppText{Layout.fillWidth:true;text:clipRow.modelData.preview;maximumLineCount:3;elide:Text.ElideRight;wrapMode:Text.Wrap}AppText{text:clipRow.modelData.kind==="image"?"Image":"Text";color:Theme.outline;font.pixelSize:Theme.fontSmall}}ActionPill{label:"Copy";onActivated:ClipboardService.run("copy",clipRow.modelData.id)}IconButton{icon:"delete";accessibleName:"Delete clipboard item";onActivated:ClipboardService.run("delete",clipRow.modelData.id)}}}}
    }
    Component.onCompleted:ClipboardService.refresh()
}
