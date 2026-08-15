import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import "../../components"
import "../../theme"

Flickable {
    id:root
    required property var wifiDevice
    property var selectedNetwork:null
    property string errorText:""
    signal backRequested()
    readonly property var networks:{const items=(wifiDevice?.networks?.values??[]).filter(n=>(n.name||"").trim());items.sort((a,b)=>a.connected!==b.connected?(a.connected?-1:1):a.known!==b.known?(a.known?-1:1):b.signalStrength-a.signalStrength);return items;}
    function signalPercent(value){return Math.round(Math.max(0,Math.min(1,Number(value)||0))*100);}
    function choose(network){errorText="";if(network.connected)network.disconnect();else if(network.known||network.security===WifiSecurityType.Open)network.connect();else{selectedNetwork=network;passwordInput.text="";Qt.callLater(()=>passwordInput.forceActiveFocus());}}
    function connectSelected(){if(!selectedNetwork||!passwordInput.text)return;selectedNetwork.connectWithPsk(passwordInput.text);passwordInput.text="";selectedNetwork=null;}
    contentWidth:width;contentHeight:content.implicitHeight;clip:true;boundsBehavior:Flickable.StopAtBounds
    ColumnLayout {
        id:content;width:root.width;spacing:Theme.space12
        RowLayout{Layout.fillWidth:true;IconButton{icon:"arrow_back";accessibleName:"Back";onActivated:root.backRequested()};ColumnLayout{Layout.fillWidth:true;AppText{text:"Wi-Fi networks";font.pixelSize:Theme.fontTitle;font.weight:Font.Bold};AppText{text:Networking.wifiEnabled?"Scanning nearby networks":"Wireless disabled";color:Theme.onSurfaceMuted;font.pixelSize:Theme.fontSmall}};ToggleSwitch{checked:Networking.wifiEnabled;accessibleName:"Wi-Fi";onToggled:checked=>Networking.wifiEnabled=checked};ActionPill{label:"Refresh";enabled:Networking.wifiEnabled;onActivated:{if(root.wifiDevice){root.wifiDevice.scannerEnabled=false;scanRestart.restart();}}}}
        AppText{Layout.fillWidth:true;Layout.preferredHeight:80;visible:Networking.wifiEnabled&&root.networks.length===0;text:"Looking for networks…";color:Theme.onSurfaceMuted;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter}
        Repeater {
            model:root.networks
            GlassSurface {
                id:networkRow;required property var modelData;Layout.fillWidth:true;implicitHeight:64;radius:Theme.radiusLarge;depth:1;active:modelData.connected
                Connections{target:networkRow.modelData;function onConnectionFailed(reason){root.errorText="Could not connect to "+networkRow.modelData.name;}}
                RowLayout{anchors{fill:parent;margins:Theme.space12};AppIcon{icon:root.signalPercent(networkRow.modelData.signalStrength)>=67?"signal_wifi_4_bar":root.signalPercent(networkRow.modelData.signalStrength)>=34?"network_wifi_2_bar":"network_wifi_1_bar";backgroundColor:networkRow.modelData.connected?Theme.accentSoft:Theme.glassHighest;iconColor:networkRow.modelData.connected?Theme.onAccentSoft:Theme.onSurfaceMuted;implicitWidth:38;implicitHeight:38};ColumnLayout{Layout.fillWidth:true;spacing:1;AppText{Layout.fillWidth:true;text:networkRow.modelData.name;font.weight:Font.Bold;elide:Text.ElideRight};AppText{text:networkRow.modelData.connected?"Connected":networkRow.modelData.stateChanging?"Connecting…":networkRow.modelData.known?"Saved • "+root.signalPercent(networkRow.modelData.signalStrength)+"%":WifiSecurityType.toString(networkRow.modelData.security)+" • "+root.signalPercent(networkRow.modelData.signalStrength)+"%";color:Theme.onSurfaceMuted;font.pixelSize:Theme.fontSmall}};ActionPill{visible:networkRow.modelData.known&&!networkRow.modelData.connected;label:"Forget";onActivated:networkRow.modelData.forget()};ActionPill{label:networkRow.modelData.connected?"Disconnect":"Connect";enabled:!networkRow.modelData.stateChanging;primary:networkRow.modelData.connected;onActivated:root.choose(networkRow.modelData)}}
            }
        }
        GlassSurface{Layout.fillWidth:true;implicitHeight:116;visible:root.selectedNetwork!==null;radius:Theme.radiusLarge;depth:2;ColumnLayout{anchors{fill:parent;margins:Theme.space12};AppText{text:"Password for "+(root.selectedNetwork?.name??"network");font.weight:Font.Bold};Rectangle{Layout.fillWidth:true;implicitHeight:40;radius:Theme.radiusPill;color:Theme.glassHighest;TextInput{id:passwordInput;anchors{fill:parent;leftMargin:Theme.space16;rightMargin:Theme.space16};verticalAlignment:TextInput.AlignVCenter;echoMode:TextInput.Password;color:Theme.onSurface;font.family:Theme.fontFamily;onAccepted:root.connectSelected()}};RowLayout{Layout.alignment:Qt.AlignRight;ActionPill{label:"Cancel";onActivated:root.selectedNetwork=null};ActionPill{label:"Connect";primary:true;enabled:passwordInput.text.length>0;onActivated:root.connectSelected()}}}}
        AppText{Layout.fillWidth:true;visible:root.errorText.length>0;text:root.errorText;color:Theme.danger;wrapMode:Text.WordWrap}
    }
    Timer{id:scanRestart;interval:120;onTriggered:if(root.wifiDevice)root.wifiDevice.scannerEnabled=true}
    Component.onCompleted:if(wifiDevice&&Networking.wifiEnabled)wifiDevice.scannerEnabled=true
    Component.onDestruction:if(wifiDevice)wifiDevice.scannerEnabled=false
}
