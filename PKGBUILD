# Maintainer: Your Name <you@example.com>
pkgname=homed-workspace-git
_pkgname=homed-workspace
pkgver=0.0.0
pkgrel=1
pkgdesc="Run commands as the systemd-homed user matching your current XFCE workspace (one homed account per client)"
arch=('any')
url="https://github.com/USER/homed-workspace"
license=('MIT')
depends=('bash' 'systemd' 'polkit' 'wmctrl' 'xdotool' 'xorg-xhost' 'xfce4-terminal')
optdepends=('pipewire-pulse: shared audio socket for client sessions (auto-configured)'
            'gnome-keyring: per-client secret unlock (enable via homed-workspace-setup)')
makedepends=('git')
provides=('homed-workspace')
conflicts=('homed-workspace')
install="${_pkgname}.install"
# git source -> 'SKIP' is valid here (VCS). For a local test replace the URL with
# "git+file:///path/to/repo".
source=("${_pkgname}::git+https://github.com/USER/homed-workspace.git")
sha256sums=('SKIP')

pkgver() {
    cd "$srcdir/$_pkgname"
    git describe --long --tags 2>/dev/null | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g' \
      || printf '0.0.0.r%s.g%s' "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
    cd "$srcdir/$_pkgname"
    install -Dm755 runas                  "$pkgdir/usr/bin/runas"
    install -Dm755 homed-workspace-logout "$pkgdir/usr/bin/homed-workspace-logout"
    install -Dm755 homed-workspace-setup  "$pkgdir/usr/bin/homed-workspace-setup"
    install -Dm644 packaging/50-homed-workspace.rules \
        "$pkgdir/usr/share/polkit-1/rules.d/50-homed-workspace.rules"
    install -Dm644 packaging/homed-workspace.tmpfiles \
        "$pkgdir/usr/lib/tmpfiles.d/homed-workspace.conf"
    install -Dm644 README.md "$pkgdir/usr/share/doc/${_pkgname}/README.md"
    install -Dm644 LICENSE   "$pkgdir/usr/share/licenses/${_pkgname}/LICENSE"
}
