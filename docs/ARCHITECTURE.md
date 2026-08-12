# Architecture

Ayame Shell V2 is developed independently from Ayame Shell V1. Its Quickshell
configuration path gives it separate data, state, cache, reload, and instance
identity. Development previews must not claim notification ownership, reserve a
desktop edge, change the wallpaper, register global shortcuts, or perform
session actions while V1 is running.

The initial layers are intentionally small:

- `settings`: typed persistent preferences owned by the V2 shell identity
- `theme`: semantic color, depth, typography, shape, and motion roles
- `components`: presentation primitives that consume semantic roles
- `modules`: complete V2 experiences assembled from components and services

Wallpaper adaptation is a core system capability, not a panel-specific effect.
The palette pipeline will derive semantic light and dark roles from the active
wallpaper, choose an accessible appearance automatically, allow an explicit
user override, and transition all consumers together. Opacity, blur, tint, and
color intensity remain independent user controls. Components only consume
semantic roles so the palette engine can evolve without rewriting the UI.

V1 implementations may be studied and selectively ported after their system
integration is separated from presentation assumptions. V1 UI components are
not inherited.

The first executable is a normal floating design-preview window. It provides a
safe place to validate QML, rendering, theme roles, and settings persistence
without replacing the active desktop shell.
