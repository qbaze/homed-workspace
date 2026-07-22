# Maintainer: Your Name <you@example.com>
pkgname=homed-workspace-git
_pkgname=homed-workspace
pkgver=0.0.0.r6.ga8bc237
pkgrel=1
pkgdesc="Run commands as the systemd-homed user matching your current workspace (one homed account per client)"
arch=('any')
url="https://github.com/qbaze/homed-workspace"
license=('MIT')
depends=('bash' 'systemd' 'polkit' 'wmctrl' 'xorg-xhost' 'xfce4-terminal')
optdepends=('pipewire-pulse: shared audio socket for client sessions (auto-configured)'
            'gnome-keyring: per-client secret unlock (enable via homed-workspace-setup)'
            'libnotify: workspace-change notifications (homed-workspace-notify)'
            'xorg-xprop: event-driven workspace notifications on X11 (else polling)'
            'xdotool: more robust active-workspace detection on X11'
            'sway: workspace detection & notifications on Sway'
            'hyprland: workspace detection on Hyprland')
makedepends=('git')
provides=('homed-workspace')
conflicts=('homed-workspace')
install="${_pkgname}.install"
source=("${_pkgname}::git+https://github.com/qbaze/homed-workspace.git")
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
    # shared library
    install -Dm644 lib/lib.sh "$pkgdir/usr/lib/homed-workspace/lib.sh"
    # systemd --user unit (opt-in)
    install -Dm644 systemd/homed-workspace-notify.service \
        "$pkgdir/usr/lib/systemd/user/homed-workspace-notify.service"
    # system integration files
    install -Dm644 packaging/50-homed-workspace.rules \
        "$pkgdir/usr/share/polkit-1/rules.d/50-homed-workspace.rules"
    install -Dm644 packaging/homed-workspace.tmpfiles \
        "$pkgdir/usr/lib/tmpfiles.d/homed-workspace.conf"
    # docs
    install -Dm644 README.md "$pkgdir/usr/share/doc/${_pkgname}/README.md"
    install -Dm644 LICENSE   "$pkgdir/usr/share/licenses/${_pkgname}/LICENSE"
}
