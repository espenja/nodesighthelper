# NodeSightZygorHide

Hides Zygor's minimap navigation markers during NodeSight's hidden scanning
phase, then restores their original opacity when scanning pauses or ends.
World-map and taxi-map markers, animations and navigation settings are unchanged.

## Use

For WoW Forever. Install in `Interface\AddOns\NodeSightHelper`, enable it
alongside `NodeSight` and `ZygorGuidesViewerForever`, then reload.
Works automatically; no configuration is needed.

## Recovery

Use `/nszgh restore` to restore saved opacity and disable further hiding until
reload. If restoration is deferred, it retries after combat when not scanning.
Retry the command out of combat if needed, before reloading: saved opacity
does not survive reload or logout.

## Limitations

- Detects scanning through NodeSight's minimap icon-scale changes, not an
  official scan event. Another addon setting that scale to zero can also
  trigger hiding.
- Covers the hidden scanning phase, not the earlier fade-in.
- Restricted or secret-valued frames may remain visible.
- Future NodeSight or Zygor updates may change detection or hiding behavior.
