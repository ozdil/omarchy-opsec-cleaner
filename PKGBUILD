# Maintainer: Ozan Özdil <ozan@pm.me>
pkgname=omarchy-opsec-cleaner
pkgver=1.1.0
pkgrel=1
pkgdesc="Digital privacy and OpSec metadata scrubber for Omarchy Linux"
arch=('x86_64')
url="https://github.com/ozdil/omarchy-opsec-cleaner"
license=('MIT')
depends=('glibc' 'gcc-libs')
makedepends=('cargo' 'rust')

build() {
    cd "${startdir}"
    cargo build --release --locked
}

package() {
    cd "${startdir}"
    install -Dm755 "target/release/opsec-engine" "${pkgdir}/usr/bin/opsec-engine"
    install -Dm755 "target/release/opsec-engine" "${pkgdir}/usr/share/omarchy/plugins/ozdil.opsec-cleaner/opsec-engine"
    install -Dm755 "cleaner-status" "${pkgdir}/usr/share/omarchy/plugins/ozdil.opsec-cleaner/cleaner-status"
    install -Dm755 "cleaner-dashboard" "${pkgdir}/usr/share/omarchy/plugins/ozdil.opsec-cleaner/cleaner-dashboard"
    install -Dm644 "manifest.json" "${pkgdir}/usr/share/omarchy/plugins/ozdil.opsec-cleaner/manifest.json"
    install -Dm644 "Panel.qml" "${pkgdir}/usr/share/omarchy/plugins/ozdil.opsec-cleaner/Panel.qml"
    install -Dm644 "README.md" "${pkgdir}/usr/share/doc/${pkgname}/README.md"
    install -Dm644 "LICENSE" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
