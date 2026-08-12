pragma Singleton

import QtQuick
import "../settings"

QtObject {
    readonly property bool light: ShellSettings.appearanceMode === "light"

    function alpha(color, opacity) {
        return Qt.rgba(color.r, color.g, color.b, opacity);
    }

    function mix(base, tint, amount) {
        return Qt.rgba(
            base.r * (1 - amount) + tint.r * amount,
            base.g * (1 - amount) + tint.g * amount,
            base.b * (1 - amount) + tint.b * amount,
            base.a
        );
    }

    // Temporary semantic seed. Wallpaper-derived roles will replace the seed;
    // components must continue to consume roles rather than literal colors.
    readonly property color accent: light ? "#405F91" : "#A9C7FF"
    readonly property color onAccent: light ? "#FFFFFF" : "#0A305F"
    readonly property color accentSoft: light ? "#D7E3FF" : "#264776"
    readonly property color onAccentSoft: light ? "#244777" : "#D7E3FF"
    readonly property color background: light ? "#F8F9FF" : "#0A101A"
    readonly property color surfaceBase: light ? "#F5F7FF" : "#151D2A"
    readonly property color surfaceRaisedBase: light ? "#EEF2FC" : "#202A39"
    readonly property color surfaceHighestBase: light ? "#E7ECF7" : "#2A3546"
    readonly property color onSurface: light ? "#171C24" : "#E9EEF8"
    readonly property color onSurfaceMuted: light ? "#454B55" : "#B7C1D0"
    readonly property color outline: light ? "#727985" : "#8490A1"
    readonly property color outlineSoft: light ? "#C2C7D0" : "#3D4858"
    readonly property color success: light ? "#2D6A46" : "#88D6A7"
    readonly property color warning: light ? "#795A00" : "#F1CB72"
    readonly property color danger: light ? "#BA1A1A" : "#FFB4AB"

    readonly property color glass: alpha(
        mix(surfaceBase, accent, ShellSettings.surfaceTint),
        ShellSettings.glassOpacity)
    readonly property color glassRaised: alpha(
        mix(surfaceRaisedBase, accent, ShellSettings.surfaceTint * 0.8),
        Math.min(0.96, ShellSettings.glassOpacity + 0.08))
    readonly property color glassHighest: alpha(
        mix(surfaceHighestBase, accent, ShellSettings.surfaceTint * 0.65),
        Math.min(0.98, ShellSettings.glassOpacity + 0.14))
    readonly property color glassStroke: alpha(outlineSoft, light ? 0.72 : 0.62)
    readonly property color glassHighlight: alpha(light ? "#FFFFFF" : "#DCE8FF",
        light ? 0.56 : 0.12)

    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space20: 20
    readonly property int space24: 24
    readonly property int space32: 32

    readonly property int radiusSmall: Math.round(10 * ShellSettings.cornerScale)
    readonly property int radiusMedium: Math.round(16 * ShellSettings.cornerScale)
    readonly property int radiusLarge: Math.round(24 * ShellSettings.cornerScale)
    readonly property int radiusXLarge: Math.round(32 * ShellSettings.cornerScale)
    readonly property int radiusPill: 999

    readonly property string fontFamily: "Adwaita Sans"
    readonly property string numericFontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSmall: 11
    readonly property int fontBody: 13
    readonly property int fontLabel: 12
    readonly property int fontTitle: 18
    readonly property int fontDisplay: 28

    function duration(value) {
        return ShellSettings.motionEnabled
            ? Math.round(value * ShellSettings.motionScale) : 0;
    }

    readonly property int motionQuick: duration(110)
    readonly property int motionResponsive: duration(190)
    readonly property int motionExpressive: duration(360)
    readonly property int easeEnter: Easing.OutCubic
    readonly property int easeExit: Easing.InCubic
}
