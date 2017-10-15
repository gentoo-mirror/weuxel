# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

PYTHON_COMPAT=( python{2_6,2_7} )

inherit eutils git-r3 linux-info systemd python-single-r1 flag-o-matic


DESCRIPTION="Encrypted networking for regular people."
HOMEPAGE="https://github.com/cjdelisle/cjdns"
EGIT_REPO_URI="git://github.com/cjdelisle/cjdns.git \
               https://github.com/cjdelisle/cjdns.git"
EGIT_BRANCH="master"
EGIT_COMMIT="7ebbdce18641e9e6779e322ff021700eabf12619"
LICENSE="GPL-3"

SLOT="0"
KEYWORDS="~amd64 ~x86"
ISUE=""

DEPEND=">=net-libs/nodejs-0.10.30
	${PYTHON_DEPS}"

pkg_setup() {
	linux-info_pkg_setup
	if ! linux_config_exists; then
		eerror "Unable to check your kernel for TUN support"
	else
		CONFIG_CHECK="~TUN"
		ERROR_TUN="Your kernel lacks TUN support."
	fi
}

src_compile() {
	python-single-r1_pkg_setup
	append-flags -Wno-error
	Seccomp_NO=1 ./do || die "./do failed"
}

src_install() {
	systemd_dounit contrib/systemd/cjdns.service
	newinitd "${FILESDIR}/cjdns.runscript" cjdns

	dodoc README.md
	dodir doc/ contrib/
	dosbin cjdroute
}

pkg_postinst() {
	local config_file="cjdroute.conf"
	local config_path="${ROOT}etc/${config_file}"

	if [[ ! -e "${config_path}" ]] ; then
		ebegin "Generating ${config_file}..."
		(umask 077 && cjdroute --genconf > "${T}/${config_file}") || die "cjdroute --genconf failed"
		mv "${T}/${config_file}" "${config_path}"
		eend ${?} || die "Failed to generate and install ${config_file}"
		elog "The keys in ${config_path} have been autogenerated during "
		elog "emerge, they are not defaults and do not need to be overwritten."
	fi
	ewarn "Protect ${config_path}! A lost conf file means you have "
	ewarn "lost your password and connections and anyone who connected "
	ewarn "to you will no longer be able to connect. A *compromised* "
	ewarn "conf file means that other people can impersonate you on "
	ewarn "the network."
	ewarn
	einfo "The cjdns runscript will load the TUN kernel module automatically."
	einfo "If you are using systemd and have TUN built as a module, add tun "
	einfo "to /etc/modules-load.d/ for automatic loading at boot-time."
	einfo "echo tun > /etc/modules-load.d/cjnds.conf"
}
