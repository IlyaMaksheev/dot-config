# Agent instructions

## Validate changes

After changing QML, run:

```sh
timeout 4s quickshell --path ~/.config/quickshell --no-color
```

Validation succeeds when the output contains `INFO: Configuration Loaded`. Exit code 124 is expected because `timeout` stops the running shell.

## Preserve boundaries

Keep complete visual features with their owning module. Put broadly reusable visual primitives in `components`, shared non-visual state and external integrations in `services`, and global visual tokens in `theme`. Keep `shell.qml` focused on assembling top-level modules.

Every directory that exposes QML types has a `qmldir`. Update the relevant catalog whenever a type is added, removed, renamed, or changed between regular and singleton status. Use explicit relative imports across architectural boundaries.

## Niri integration

Keep `services/Niri.qml` as the single owner of Niri IPC and shared Niri state. Visual components consume its API instead of opening additional Niri processes or sockets.

Join Quickshell screens to Niri outputs by the runtime connector name. Use `is_active` for per-output workspace state and globally unique workspace IDs for IPC actions.

## Appearance

Keep shared palette, typography, and dimensions in `theme/Appearance.qml`. Build reusable styled primitives instead of repeating appearance bindings across feature components.
