import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"
import "../../settings"
import "../../theme"

Flickable {
    id: root
    signal aiConfigureRequested()
    contentWidth: width; contentHeight: content.implicitHeight; clip: true
    boundsBehavior: Flickable.StopAtBounds
    ColumnLayout {
        id: content; width: root.width; spacing: Theme.space12
        GlassSurface {
            Layout.fillWidth: true; implicitHeight: 88; radius: Theme.radiusLarge; depth: 1
            RowLayout {
                anchors { fill: parent; margins: Theme.space16 }
                AppIcon { icon:"auto_awesome"; backgroundColor:Theme.accent; iconColor:Theme.onAccent; implicitWidth:48; implicitHeight:48 }
                ColumnLayout { Layout.fillWidth:true; AppText{text:"Ayame AI";font.weight:Font.Bold} AppText{text:ShellSettings.aiProvider+" • "+ShellSettings.aiModel;color:Theme.onSurfaceMuted;font.pixelSize:Theme.fontSmall} }
                ToggleSwitch { checked:ShellSettings.aiEnabled; accessibleName:"Ayame AI"; onToggled:checked=>ShellSettings.aiEnabled=checked }
                ActionPill { label:"Configure"; onActivated:root.aiConfigureRequested() }
            }
        }
        SettingToggleRow { Layout.fillWidth:true; icon:"notifications"; title:"Ayame notifications"; subtitle:checked?"Owns notification popups":"Safe preview mode"; checked:ShellSettings.notificationServerEnabled; onToggled:checked=>ShellSettings.notificationServerEnabled=checked }
        SettingToggleRow { Layout.fillWidth:true; icon:"do_not_disturb_on"; title:"Do Not Disturb"; subtitle:checked?"History only":"Popups allowed"; checked:ShellSettings.doNotDisturb; onToggled:checked=>ShellSettings.doNotDisturb=checked }
        AppText { Layout.fillWidth:true; text:"Enable notification ownership only when V2 replaces your current notification service."; color:Theme.outline; font.pixelSize:Theme.fontSmall; wrapMode:Text.WordWrap }
        SettingToggleRow { Layout.fillWidth:true; icon:"content_paste"; title:"Clipboard history"; subtitle:checked?"Text and images • stored locally":"Off for privacy"; checked:ShellSettings.clipboardHistoryEnabled; onToggled:checked=>ShellSettings.clipboardHistoryEnabled=checked }
        AppText { Layout.fillWidth:true; text:"Password-manager clipboard entries are always excluded."; color:Theme.outline; font.pixelSize:Theme.fontSmall }

        GlassSurface {
            Layout.fillWidth:true; implicitHeight:weatherContent.implicitHeight+Theme.space32; radius:Theme.radiusLarge; depth:1
            ColumnLayout {
                id:weatherContent; anchors{left:parent.left;right:parent.right;verticalCenter:parent.verticalCenter;margins:Theme.space16} spacing:Theme.space12
                RowLayout { Layout.fillWidth:true; AppText{Layout.fillWidth:true;text:"Weather";font.weight:Font.Bold} ToggleSwitch{checked:ShellSettings.weatherEnabled;accessibleName:"Weather";onToggled:checked=>ShellSettings.weatherEnabled=checked} }
                AppText { Layout.fillWidth:true; text:ShellSettings.weatherLocationName||"No location configured"; color:Theme.onSurfaceMuted; elide:Text.ElideRight }
                RowLayout {
                    Layout.fillWidth:true
                    Rectangle {
                        Layout.fillWidth:true; implicitHeight:44; radius:Theme.radiusPill; color:Theme.glassHighest; border.width:1; border.color:weatherInput.activeFocus?Theme.accent:Theme.glassStroke
                        TextInput { id:weatherInput; anchors{fill:parent;leftMargin:Theme.space16;rightMargin:Theme.space16} verticalAlignment:TextInput.AlignVCenter; color:Theme.onSurface; font.family:Theme.fontFamily; font.pixelSize:Theme.fontBody; onAccepted:WeatherService.searchCity(text)
                            AppText{anchors.verticalCenter:parent.verticalCenter;visible:parent.text.length===0;text:"Search for a city…";color:Theme.outline} }
                    }
                    ActionPill { label:WeatherService.searching?"Searching":"Search"; enabled:!WeatherService.searching&&weatherInput.text.length>1; onActivated:WeatherService.searchCity(weatherInput.text) }
                    ActionPill { visible:ShellSettings.weatherLocationName.length>0; label:"Forget"; onActivated:WeatherService.forgetLocation() }
                }
                Repeater {
                    model:WeatherService.searchResults
                    Rectangle {
                        required property var modelData; Layout.fillWidth:true; implicitHeight:44; radius:Theme.radiusMedium; color:locationMouse.containsMouse?Theme.accentSoft:Theme.glassHighest
                        AppText{anchors{left:parent.left;right:parent.right;verticalCenter:parent.verticalCenter;margins:Theme.space12}text:parent.modelData.name+(parent.modelData.admin1?", "+parent.modelData.admin1:"")+(parent.modelData.country?", "+parent.modelData.country:"");elide:Text.ElideRight}
                        MouseArea{id:locationMouse;anchors.fill:parent;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:WeatherService.selectLocation(parent.modelData)}
                    }
                }
                SettingChoiceRow { Layout.fillWidth:true; title:"Temperature unit"; subtitle:"Weather display unit"; options:[{label:"Celsius",value:"celsius"},{label:"Fahrenheit",value:"fahrenheit"}]; value:ShellSettings.weatherTemperatureUnit; onChosen:value=>{ShellSettings.weatherTemperatureUnit=value;WeatherService.refresh();} }
            }
        }
    }
}
