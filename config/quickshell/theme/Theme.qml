pragma Singleton

import QtQuick
import "../settings"
import "../services"

QtObject {
    readonly property bool light: ShellSettings.appearanceMode === "light"
        || (ShellSettings.appearanceMode === "automatic"
            && PaletteService.recommendedAppearance === "light")

    function palette(name, darkFallback, lightFallback) {
        const fallback = light ? lightFallback : darkFallback;
        return PaletteService.active
            ? PaletteService.modeColor(name, light ? "light" : "dark", fallback)
            : fallback;
    }

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

    readonly property color accent: palette("primary", "#A9C7FF", "#405F91")
    readonly property color onAccent: palette("on_primary", "#0A305F", "#FFFFFF")
    readonly property color accentSoft: palette("primary_container", "#264776", "#D7E3FF")
    readonly property color onAccentSoft: palette("on_primary_container", "#D7E3FF", "#244777")
    readonly property color secondary: palette("secondary", "#BBC7DB", "#536175")
    readonly property color secondarySoft: palette("secondary_container", "#3C485B", "#D7E3F8")
    readonly property color tertiary: palette("tertiary", "#D7BDE4", "#6C5675")
    readonly property color tertiarySoft: palette("tertiary_container", "#533E5C", "#F5D9FF")
    readonly property color background: palette("background", "#0A101A", "#F8F9FF")
    readonly property color surfaceBase: palette("surface", "#151D2A", "#F5F7FF")
    readonly property color surfaceRaisedBase: palette("surface_container", "#202A39", "#EEF2FC")
    readonly property color surfaceHighestBase: palette("surface_container_high", "#2A3546", "#E7ECF7")
    readonly property color onSurface: palette("on_surface", "#E9EEF8", "#171C24")
    readonly property color onSurfaceMuted: palette("on_surface_variant", "#B7C1D0", "#454B55")
    readonly property color outline: palette("outline", "#8490A1", "#727985")
    readonly property color outlineSoft: palette("outline_variant", "#3D4858", "#C2C7D0")
    readonly property color success: light ? "#2D6A46" : "#88D6A7"
    readonly property color warning: light ? "#795A00" : "#F1CB72"
    readonly property color danger: palette("error", "#FFB4AB", "#BA1A1A")

    readonly property color glass: alpha(
        mix(surfaceBase, accent, ShellSettings.surfaceTint),
        ShellSettings.glassBlur ? ShellSettings.glassOpacity : 0.98)
    readonly property color glassRaised: alpha(
        mix(surfaceRaisedBase, accent, ShellSettings.surfaceTint * 0.8),
        ShellSettings.glassBlur ? Math.min(0.96, ShellSettings.glassOpacity + 0.08) : 1)
    readonly property color glassHighest: alpha(
        mix(surfaceHighestBase, accent, ShellSettings.surfaceTint * 0.65),
        ShellSettings.glassBlur ? Math.min(0.98, ShellSettings.glassOpacity + 0.14) : 1)
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
    readonly property int space40: 40

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
    readonly property int fontHero: 42

    function duration(value) {
        return ShellSettings.motionEnabled
            ? Math.round(value * ShellSettings.motionScale
                * (ShellSettings.reducedMotion ? 0.35 : 1)) : 0;
    }

    readonly property int motionQuick: duration(110)
    readonly property int motionResponsive: duration(190)
    readonly property int motionExpressive: duration(360)
    readonly property int easeEnter: Easing.OutCubic
    readonly property int easeExit: Easing.InCubic
}
