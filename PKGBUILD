# Maintainer: Your Name <you@example.com>
pkgname=homed-workspace-git
_pkgname=homed-workspace
pkgver=0.0.0.r7.g4692c09
pkgrel=1
pkgdesc="Run commands as the systemd-homed user matching your current workspace (one homed account per client)"
arch=('any')
url="https://github.com/qbaze/homed-workspace"
license=('MIT')
depends=('bash' 'systemd' 'polkit' 'wmctrl' 'xorg-xhost' 'xfce4-terminal'
         'python-gobject' 'gtk3' 'python-cairo' 'python-xlib'
         'libnotify' 'rofi' 'libayatana-appindicator')
optdepends=('pipewire-pulse: shared audio socket for client sessions (auto-configured)'
            'xorg-xprop: event-driven workspace notifications on X11 (else polling)'
            'xdotool: more robust active-workspace detection on X11'
            'sway: workspace detection & notifications on Sway'
            'hyprland: workspace detection on Hyprland')
makedepends=('git')
provides=('homed-workspace')
conflicts=('homed-workspace')
install="${_pkgname}.install"
# Branch to build from — override with HW_BRANCH=<branch> makepkg ..., defaults to main.
# (makepkg has no --branch flag; this is a plain bash var read at parse time.)
_branch="${HW_BRANCH:-main}"
source=("${_pkgname}::git+https://github.com/qbaze/homed-workspace.git#branch=${_branch}")
sha256sums=('SKIP')

pkgver() {
    cd "$srcdir/$_pkgname"
    local v
    if v=$(git describe --long --tags 2>/dev/null); then
        printf '%s' "$v" | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
    else
        printf '0.0.0.r%s.g%s' "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
    fi
}

package() {
    cd "$srcdir/$_pkgname"
    # commands
    install -Dm755 runas                  "$pkgdir/usr/bin/runas"
    install -Dm755 homed-workspace-logout "$pkgdir/usr/bin/homed-workspace-logout"
    install -Dm755 homed-workspace-setup  "$pkgdir/usr/bin/homed-workspace-setup"
    install -Dm755 homed-workspace-notify "$pkgdir/usr/bin/homed-workspace-notify"
    install -Dm755 homed-workspace-overlay "$pkgdir/usr/bin/homed-workspace-overlay"
    install -Dm755 homed-workspace-tray   "$pkgdir/usr/bin/homed-workspace-tray"
    install -Dm755 homed-workspace-tidy   "$pkgdir/usr/bin/homed-workspace-tidy"
    install -Dm755 homed-workspace-menu   "$pkgdir/usr/bin/homed-workspace-menu"
    install -Dm755 homed-workspace-gui    "$pkgdir/usr/bin/homed-workspace-gui"
    # shared library
    install -Dm644 lib/lib.sh "$pkgdir/usr/lib/homed-workspace/lib.sh"
    # systemd --user unit (opt-in)
    install -Dm644 systemd/homed-workspace-notify.service \
        "$pkgdir/usr/lib/systemd/user/homed-workspace-notify.service"
    install -Dm644 systemd/homed-workspace-overlay.service \
        "$pkgdir/usr/lib/systemd/user/homed-workspace-overlay.service"
    # system integration files
    install -Dm644 packaging/50-homed-workspace.rules \
        "$pkgdir/usr/share/polkit-1/rules.d/50-homed-workspace.rules"
    install -Dm644 packaging/homed-workspace.tmpfiles \
        "$pkgdir/usr/lib/tmpfiles.d/homed-workspace.conf"
    # app launcher for the GUI
    install -Dm644 desktop/homed-workspace-gui.desktop \
        "$pkgdir/usr/share/applications/homed-workspace-gui.desktop"
    # tray autostart (XDG autostart for every login session)
    install -Dm644 desktop/homed-workspace-tray.desktop \
        "$pkgdir/etc/xdg/autostart/homed-workspace-tray.desktop"
    # docs
    install -Dm644 README.md "$pkgdir/usr/share/doc/${_pkgname}/README.md"
    install -Dm644 LICENSE   "$pkgdir/usr/share/licenses/${_pkgname}/LICENSE"
}
