# Maintainer: Twoje Imię <you@example.com>
pkgname=runas-workspace-git
_pkgname=runas-workspace
pkgver=0.0.0
pkgrel=1
pkgdesc="Izolowane środowiska per klient: userzy homed na workspace XFCE, komendy przez machinectl shell"
arch=('any')
url="https://github.com/USER/runas-workspace"
license=('MIT')
depends=('bash' 'systemd' 'polkit' 'wmctrl' 'xdotool' 'xorg-xhost' 'xfce4-terminal')
optdepends=('pipewire-pulse: wspólny socket audio dla sesji klientów (auto-setup)'
            'gnome-keyring: odblokowanie sekretów per klient (włącz przez runas-setup)')
makedepends=('git')
provides=('runas-workspace')
conflicts=('runas-workspace')
install="${_pkgname}.install"
# git jako źródło -> 'SKIP' jest tu LEGALNE (VCS), flaga sum rozbrojona.
# Dla lokalnego testu podmień na: "git+file:///ścieżka/do/repo"
source=("${_pkgname}::git+https://github.com/USER/runas-workspace.git")
sha256sums=('SKIP')

pkgver() {
    cd "$srcdir/$_pkgname"
    # tag typu v1.2.3 -> 1.2.3.rN.gHASH; bez tagów -> 0.0.0.rN.gHASH
    git describe --long --tags 2>/dev/null | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g' \
      || printf '0.0.0.r%s.g%s' "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
    cd "$srcdir/$_pkgname"
    install -Dm755 runas             "$pkgdir/usr/bin/runas"
    install -Dm755 runas-logout-all  "$pkgdir/usr/bin/runas-logout-all"
    install -Dm755 runas-setup       "$pkgdir/usr/bin/runas-setup"
    install -Dm644 packaging/50-runas.rules "$pkgdir/usr/share/polkit-1/rules.d/50-runas.rules"
    install -Dm644 packaging/runas.tmpfiles  "$pkgdir/usr/lib/tmpfiles.d/runas.conf"
    install -Dm644 README.md         "$pkgdir/usr/share/doc/${_pkgname}/README.md"
    install -Dm644 LICENSE           "$pkgdir/usr/share/licenses/${_pkgname}/LICENSE"
}
