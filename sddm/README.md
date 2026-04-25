# SDDM Gruvbox Breeze

This package is **not** installed with GNU Stow.

SDDM's greeter runs as the `sddm` user. If the theme under `/usr/share/sddm/themes` is a symlink into `~/dot-config`, the greeter must be able to traverse `/home/korvin`. Because `/home/korvin` is private (`0700`), a Stow symlink makes the greeter fail with:

```text
file:///usr/share/sddm/themes/gruvbox-breeze/Main.qml: No such file or directory
Fallback to embedded theme
```

So this package keeps the source in `~/dot-config`, but installs by **copying** files into system locations.

## Source layout

```text
~/dot-config/sddm/
├── config/zz-gruvbox.conf
├── scripts/xsetup
├── theme/gruvbox-breeze/
└── install.sh
```

## Install / update

From the dotfiles repo:

```bash
cd ~/dot-config/sddm
sudo ./install.sh
```

The installer copies:

```text
~/dot-config/sddm/theme/gruvbox-breeze -> /usr/share/sddm/themes/gruvbox-breeze
~/dot-config/sddm/config/zz-gruvbox.conf -> /etc/sddm.conf.d/zz-gruvbox.conf
~/dot-config/sddm/scripts/xsetup -> /usr/local/bin/sddm-gruvbox-xsetup
```

It also removes the obsolete earlier config:

```text
/etc/sddm.conf.d/99-gruvbox.conf
```

`zz-gruvbox.conf` is intentionally named with a late-sorting prefix so it overrides KDE's `/etc/sddm.conf.d/kde_settings.conf`, which may set `Current=breeze`.

It also sets:

```ini
[X11]
DisplayCommand=/usr/local/bin/sddm-gruvbox-xsetup
```

The custom Xsetup script applies the SDDM/Xorg monitor layout. SDDM's Xorg output names differ from niri on this machine:

```text
niri/Wayland: DP-2, DP-3
SDDM/Xorg:    DP-2, DP-0
```

Desired physical SDDM greeter layout:

```text
DP-0:         physical left monitor,  2560x1440+0+0
DP-2 primary: physical right monitor, 2560x1440+2560+0
```

The SDDM theme uses SDDM's `primaryScreen` property to show the login UI only on the primary/right monitor. Non-primary monitors show only the solid Gruvbox background color.

The script also attempts to move the initial Xorg pointer to the center of the right/primary monitor. Xorg often starts the pointer at `0,0` on the leftmost monitor even when another output is primary.

## Preview

```bash
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/gruvbox-breeze
```

## Restart SDDM

Restarting SDDM logs out the current graphical session:

```bash
sudo systemctl restart sddm
```

Or reboot:

```bash
sudo reboot
```

## Verify

```bash
journalctl -u sddm -b --no-pager | grep -Ei 'theme|gruvbox|breeze|Main.qml|error|warning'
journalctl -b --no-pager | grep -Ei 'sddm-gruvbox-xsetup|Running display setup'
```

Expected lines:

```text
Loading theme configuration from "/usr/share/sddm/themes/gruvbox-breeze/theme.conf"
--theme /usr/share/sddm/themes/gruvbox-breeze
```

Check that the installed theme is a real directory, not a symlink:

```bash
ls -ld /usr/share/sddm/themes/gruvbox-breeze
```

Expected first character:

```text
d
```

not:

```text
l
```

Check the installed SDDM monitor script:

```bash
grep -nE 'DisplayCommand|DP-0|DP-2' /etc/sddm.conf.d/zz-gruvbox.conf /usr/local/bin/sddm-gruvbox-xsetup
```

## Uninstall

```bash
sudo rm -rf /usr/share/sddm/themes/gruvbox-breeze
sudo rm -f /etc/sddm.conf.d/zz-gruvbox.conf
sudo rm -f /usr/local/bin/sddm-gruvbox-xsetup
```
