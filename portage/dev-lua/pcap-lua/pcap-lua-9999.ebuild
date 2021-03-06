# TODO
#Package lua5.1 was not found in the pkg-config search path.
#Perhaps you should add the directory containing `lua5.1.pc'
#to the PKG_CONFIG_PATH environment variable
#No package 'lua5.1' found

EAPI=5
inherit multilib toolchain-funcs git-2

DESCRIPTION="lua bindings for libpcap"
HOMEPAGE="https://github.com/sam-github/pcap-lua"
SRC_URI=""
EGIT_REPO_URI="https://github.com/sam-github/pcap-lua.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~hppa ~mips ~ppc ~ppc64 ~x86 ~x86-fbsd"
IUSE=""

DEPEND=">=dev-lang/lua-5.1"
RDEPEND="${DEPEND}"

src_prepare() {
	sed -i \
		-e "s|gcc|$(tc-getCC)|" \
		-e "s|/usr/local|/usr|" \
		-e "s|/lib|/$(get_libdir)|" \
		-e "s|-O2|${CFLAGS}|" \
		Makefile || die
}

src_install() {
#	emake PREFIX="${ED}usr" install
	dodir /usr/lib/lua/5.1
	cp "${S}/pcap.so" "${D}/usr/lib/lua/5.1/pcap.so" || die "Install failed!"
	dodoc README.txt
}
