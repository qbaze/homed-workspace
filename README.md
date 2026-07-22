# homed-workspace

Per-client isolated work environments on Arch Linux: each client is a separate
`systemd-homed` user (encrypted home), mapped to an XFCE workspace of the same
name. Commands launched on a given workspace run as that dedicated user — with
working audio and without constant password prompts.

The command you actually run is `runas`:

```bash
runas firefox        # on workspace 'clientA' -> Firefox as user clientA
```

> **Scope:** XFCE + X11 + systemd-homed. This is a personal workflow packaged up,
> not a general-purpose tool. It won't work on Wayland/GNOME/KDE without changes.

## How it works

On the first command for a client, `runas` activates that client's encrypted home
with `homectl activate` (in a small terminal, so you can type the password — the
home encryption key). `enable-linger` keeps `user@UID.service` alive, so every
later command is injected via `machinectl shell` into the running user manager —
no password, working audio. The password is entered once per client per boot.

Why not `su -l`: it cannot hold a homed home reference (`su -l` fails with "Called
without reference on home taken"), so `homectl activate` is used instead. A side
effect is that the login keyring is not auto-unlocked — see **Keyring** below.

## Install

```bash
# from the AUR (once published):
#   yay -S homed-workspace-git
# locally from the repo:
makepkg -si
```

Requirement: your account is in the `wheel` group (polkit authorisation relies on
it; such a user can already `sudo su - X`, so this grants no new privilege).

The `runas` command and audio work immediately. To also tear down client sessions
automatically when you log out, install the logout hook explicitly:

```bash
sudo homed-workspace-setup            # reverse: sudo homed-workspace-setup --undo
```

This adds one `optional` `pam_exec` line to your display manager's PAM stack. The
package does **not** do this during installation — it does not modify files owned
by other packages without your explicit consent. Being `optional`, it cannot lock
you out of login.

## Security — read this

This is a **UID boundary, not a sandbox.** It protects each client's files and
profile via a separate encrypted home. However:

- **X11 does not isolate clients.** `runas` grants the client user access to your X
  server via `xhost +si:localuser:` (least-privilege, not `xhost +`) and revokes it
  on logout. While access is granted, a client process can in principle log
  keystrokes or capture other windows. If you need hard display isolation, look at
  Wayland or xpra-per-user.
- **The shared audio socket** (`/run/homed-workspace/pulse-<uid>`,
  `client.access=unrestricted`) is reachable by other local UIDs. In the "all users
  are your own accounts" model this is irrelevant; on a box with untrusted local
  users, disable audio or tunnel it per session.

## Keyring

`runas` activates the client's encrypted home but does **not** unlock its login
keyring (GNOME Keyring). Unlocking a keyring needs a password-carrying PAM login,
which neither `homectl activate` nor `machinectl shell` (authorised via polkit,
not a password) provide — so apps that store secrets in the system keyring will
prompt on first use.

Recommended approach: since the home is already encrypted (and only mounts after
the homed password), point apps at their own in-home store instead of the system
keyring — the encryption you already have is the real protection:

- Chromium/Brave: launch with `--password-store=basic` (secrets kept in the
  profile inside the encrypted home).
- Firefox: uses its own password store; optionally set a primary password.

A wired-in solution (e.g. app defaults per client) is a possible future addition.

## Workspace-change notifications (optional)

A small service pops a desktop notification with the workspace name whenever you
switch — handy since the workspace name is the client you're about to act as. It
is **event-driven** where the WM supports it (X11 via the `_NET_CURRENT_DESKTOP`
root property with `xprop -spy`; Sway via `swaymsg subscribe`) and falls back to
light polling elsewhere. All of that is hidden behind `watch_ws()` in the shared
library, so it works the same across window managers.

Opt-in, per user (no root):

```bash
systemctl --user enable --now homed-workspace-notify.service
```

Needs `libnotify` (for `notify-send`); on X11, `xorg-xprop` upgrades it from
polling to true events. If your desktop doesn't export `DISPLAY` into the systemd
user manager, add once to your session startup:
`dbus-update-activation-environment --systemd DISPLAY XAUTHORITY`.

## Commands

| command | purpose |
|---|---|
| `runas <cmd>` | run `<cmd>` as the client owning the current workspace |
| `homed-workspace-setup [--undo]` | install/remove the logout hook (DM PAM) |
| `homed-workspace-logout` | tear down client sessions (also runs on your logout) |
| `homed-workspace-notify` | notify on workspace change (run via the `--user` service) |

## Portability

Workspace detection and change-watching live in `/usr/lib/homed-workspace/lib.sh`
(`current_ws` / `watch_ws`), backend-switched per WM: X11 (wmctrl/xprop) today,
with Sway (swaymsg) and Hyprland (hyprctl) branches in place. Adding a WM means
filling one branch — the commands on top don't change.

## Uninstall

```bash
sudo homed-workspace-setup --undo     # remove the logout hook first
sudo pacman -R homed-workspace-git
```

## Caveats

- **homed + linger can be finicky** — after long inactivity homed may deactivate a
  home and the client will ask for its password again.

## License

MIT.
