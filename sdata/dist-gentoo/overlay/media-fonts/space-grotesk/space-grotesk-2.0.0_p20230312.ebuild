# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

inherit font python-any-r1

COMMIT="3672ea5ae67d699f93aac3c1744e5e56112cd4be"
RAW="https://raw.githubusercontent.com/floriankarsten/space-grotesk/${COMMIT}"

DESCRIPTION="Space Grotesk font with Cyrillic (floriankarsten/space-grotesk#50)"
HOMEPAGE="https://github.com/floriankarsten/space-grotesk/pull/50"
SRC_URI="
	${RAW}/OFL.txt -> ${P}-OFL.txt
	${RAW}/fonts/otf/SpaceGrotesk-Light.otf -> ${P}-Light.otf
	${RAW}/fonts/otf/SpaceGrotesk-Regular.otf -> ${P}-Regular.otf
	${RAW}/fonts/otf/SpaceGrotesk-Medium.otf -> ${P}-Medium.otf
	${RAW}/fonts/otf/SpaceGrotesk-Bold.otf -> ${P}-Bold.otf
"
S="${WORKDIR}/${P}"

LICENSE="OFL-1.1"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

BDEPEND="
	${PYTHON_DEPS}
	$(python_gen_any_dep 'dev-python/fonttools[${PYTHON_USEDEP}]')
"

FONT_SUFFIX="otf"

python_check_deps() {
	python_has_version "dev-python/fonttools[${PYTHON_USEDEP}]"
}

pkg_setup() {
	python-any-r1_pkg_setup
	font_pkg_setup
}

src_unpack() {
	mkdir -p "${S}" || die
	cp "${DISTDIR}/${P}-OFL.txt" "${S}/OFL.txt" || die
	local w
	for w in Light Regular Medium Bold; do
		cp "${DISTDIR}/${P}-${w}.otf" "${S}/SpaceGrotesk-${w}.otf" || die
	done
}

src_compile() {
	# The fork shrank ascent/descent to 700/-214; restore upstream's so text boxes keep their height.
	"${EPYTHON}" - SpaceGrotesk-*.otf <<-'EOF' || die
		import sys
		from fontTools.ttLib import TTFont
		for path in sys.argv[1:]:
		    font = TTFont(path)
		    font["hhea"].ascent = font["OS/2"].sTypoAscender = 984
		    font["hhea"].descent = font["OS/2"].sTypoDescender = -292
		    font.save(path)
	EOF
}

src_install() {
	font_src_install
	dodoc OFL.txt
}
