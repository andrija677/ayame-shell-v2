import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../components"
import "../../theme"

Flickable {
    id:root
    required property var adapter
    signal backRequested()
    readonly property var devices:{const items=(adapter?.devices?.values??[]).slice();items.sort((a,b)=>a.connected!==b.connected?(a.connected?-1:1):a.paired!==b.paired?(a.paired?-1:1):(a.name||a.deviceName).localeCompare(b.name||b.deviceName));return items;}
    function toggle(device){if(device.connected)device.disconnect();else if(device.paired)device.connect();else device.pair();}
    contentWidth:width;contentHeight:content.implicitHeight;clip:true;boundsBehavior:Flickable.StopAtBounds
    ColumnLayout{id:content;width:root.width;spacing:Theme.space12
        RowLayout{Layout.fillWidth:true;IconButton{icon:"arrow_back";accessibleName:"Back";onActivated:root.backRequested()};ColumnLayout{Layout.fillWidth:true;AppText{text:"Bluetooth devices";font.pixelSize:Theme.fontTitle;font.weight:Font.Bold};AppText{text:!root.adapter?"No adapter detected":root.adapter.enabled?root.adapter.discovering?"Scanning…":"Ready to connect":"Bluetooth off";color:Theme.onSurfaceMuted;font.pixelSize:Theme.fontSmall}};ToggleSwitch{checked:root.adapter?.enabled??false;enabled:root.adapter!==null;accessibleName:"Bluetooth";onToggled:checked=>{root.adapter.enabled=checked;if(checked)root.adapter.discovering=true;}};ActionPill{label:root.adapter?.discovering?"Stop":"Scan";enabled:root.adapter?.enabled??false;onActivated:root.adapter.discovering=!root.adapter.discovering}}
        AppText{Layout.fillWidth:true;Layout.preferredHeight:80;visible:(root.adapter?.enabled??false)&&root.devices.length===0;text:root.adapter?.discovering?"Looking for nearby devices…":"No Bluetooth devices found";color:Theme.onSurfaceMuted;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter}
        Repeater{model:root.devices;GlassSurface{id:deviceRow;required property var modelData;Layout.fillWidth:true;implicitHeight:64;radius:Theme.radiusLarge;depth:1;active:modelData.connected;RowLayout{anchors{fill:parent;margins:Theme.space12};AppIcon{icon:"bluetooth";backgroundColor:deviceRow.modelData.connected?Theme.accentSoft:Theme.glassHighest;iconColor:deviceRow.modelData.connected?Theme.onAccentSoft:Theme.onSurfaceMuted;implicitWidth:38;implicitHeight:38};ColumnLayout{Layout.fillWidth:true;spacing:1;AppText{Layout.fillWidth:true;text:deviceRow.modelData.name||deviceRow.modelData.deviceName||"Bluetooth device";font.weight:Font.Bold;elide:Text.ElideRight};AppText{text:deviceRow.modelData.connected?"Connected":deviceRow.modelData.pairing?"Pairing…":deviceRow.modelData.paired?"Paired":"Available";color:Theme.onSurfaceMuted;font.pixelSize:Theme.fontSmall}};ActionPill{visible:deviceRow.modelData.paired&&!deviceRow.modelData.connected;label:"Forget";onActivated:deviceRow.modelData.forget()};ActionPill{label:deviceRow.modelData.connected?"Disconnect":deviceRow.modelData.paired?"Connect":"Pair";onActivated:root.toggle(deviceRow.modelData)}}}}
        AppText{Layout.fillWidth:true;visible:root.adapter?.enabled??false;text:"Some devices may ask you to confirm a pairing code in another system dialog.";color:Theme.outline;font.pixelSize:Theme.fontSmall;horizontalAlignment:Text.AlignHCenter;wrapMode:Text.WordWrap}
    }
    Component.onCompleted:if(adapter?.enabled)adapter.discovering=true
    Component.onDestruction:if(adapter)adapter.discovering=false
}
