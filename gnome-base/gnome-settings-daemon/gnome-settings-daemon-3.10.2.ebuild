# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/gnome-settings-daemon/gnome-settings-daemon-3.8.6.1.ebuild,v 1.2 2013/11/13 19:30:31 pacho Exp $

EAPI="5"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"

inherit autotools eutils gnome2 systemd virtualx

DESCRIPTION="Gnome Settings Daemon"
HOMEPAGE="https://git.gnome.org/browse/gnome-settings-daemon"
SRC_URI="${SRC_URI}
	https://launchpad.net/ubuntu/+archive/primary/+files/gnome-settings-daemon_3.8.6.1-0ubuntu2.debian.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
IUSE="+colord +cups debug +i18n input_devices_wacom -openrc-force packagekit policykit +short-touchpad-timeout smartcard +ubuntu +udev"
REQUIRED_USE="
	packagekit? ( udev )
	smartcard? ( udev )
"
KEYWORDS="~alpha ~amd64 ~arm ~ppc ~ppc64 ~x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~x86-solaris"

COMMON_DEPEND="
	>=dev-libs/glib-2.37.7:2
	>=x11-libs/gtk+-3.7.8:3
	>=gnome-base/gnome-desktop-3.9:3=
	>=gnome-base/gsettings-desktop-schemas-3.9.91.1
	>=gnome-base/librsvg-2.36.2
	media-fonts/cantarell
	media-libs/fontconfig
	>=media-libs/lcms-2.2:2
	media-libs/libcanberra[gtk3]
	>=media-sound/pulseaudio-2
	>=sys-power/upower-0.9.11
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	>=x11-libs/libnotify-0.7.3:=
	x11-libs/libX11
	x11-libs/libxkbfile
	x11-libs/libXi
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXtst
	x11-libs/libXxf86misc

	app-misc/geoclue:2.0
	>=dev-libs/libgweather-3.9.5:2
	>=sci-geosciences/geocode-glib-3.10
	>=sys-auth/polkit-0.103

	colord? ( >=x11-misc/colord-1.0.2:= )
	cups? ( >=net-print/cups-1.4[dbus] )
	i18n? ( >=app-i18n/ibus-1.4.99 )
	input_devices_wacom? (
		>=dev-libs/libwacom-0.7
		>=x11-libs/pango-1.20
		x11-drivers/xf86-input-wacom
		virtual/udev[gudev] )
	packagekit? ( >=app-admin/packagekit-base-0.8.1 )
	smartcard? ( >=dev-libs/nss-3.11.2 )
	udev? ( virtual/udev[gudev] )
"
# Themes needed by g-s-d, gnome-shell, gtk+:3 apps to work properly
# <gnome-color-manager-3.1.1 has file collisions with g-s-d-3.1.x
# <gnome-power-manager-3.1.3 has file collisions with g-s-d-3.1.x
# systemd needed for power and session management, bug #464944
RDEPEND="${COMMON_DEPEND}
	gnome-base/dconf
	!openrc-force? ( sys-apps/systemd )
	>=x11-themes/gnome-themes-standard-2.91
	>=x11-themes/gnome-icon-theme-2.91
	>=x11-themes/gnome-icon-theme-symbolic-2.91
	!<gnome-base/gnome-control-center-2.22
	!<gnome-extra/gnome-color-manager-3.1.1
	!<gnome-extra/gnome-power-manager-3.1.3
"
# xproto-7.0.15 needed for power plugin
DEPEND="${COMMON_DEPEND}
	cups? ( sys-apps/sed )
	dev-libs/libxml2:2
	sys-devel/gettext
	>=dev-util/intltool-0.40
	virtual/pkgconfig
	x11-proto/inputproto
	x11-proto/xf86miscproto
	>=x11-proto/xproto-7.0.15
"

src_prepare() {
	# Ubuntu patches
	if use ubuntu; then
		einfo "Applying patches from Ubuntu:"
		for patch in `cat "${FILESDIR}/${P}-ubuntu-patch-series"`; do
			epatch "${WORKDIR}/debian/patches/${patch}"
		done

		local PATCHDIR="${WORKDIR}/debian/patches"

		epatch "${FILESDIR}/${P}-16_use_synchronous_notifications.patch"
		epatch "${FILESDIR}/${P}-43_disable_locale_settings.patch"
		epatch "${FILESDIR}/${P}-45_suppress-printer-may-not-be-connected-notification.patch"
		epatch "${FILESDIR}/${P}-revert_background_dropping.patch"
		epatch "${PATCHDIR}/52_sync_background_to_accountsservice.patch"
		epatch "${FILESDIR}/${P}-53_sync_input_sources_to_accountsservice.patch"
		epatch "${FILESDIR}/${P}-64_restore_terminal_keyboard_shortcut_schema.patch"
		epatch "${FILESDIR}/${P}-nexus-orientation.patch"
		epatch "${FILESDIR}/${P}-fix_broken_user_sounds_permissions.patch"
		epatch "${FILESDIR}/${P}-git_revert_remove-unused-keygrab-code.patch"
		epatch "${FILESDIR}/${P}-git_revert_gsd-keygrab.patch"
		epatch "${FILESDIR}/${P}-fix_media_keys_on_unity.patch"
		epatch "${PATCHDIR}/fix_input_switching_on_unity.patch"
		epatch "${PATCHDIR}/fix_screenshots_on_unity.patch"
		epatch "${FILESDIR}/${P}-git_revert_remove_automount_helper.patch"
		epatch "${FILESDIR}/${P}-ubuntu-lid-close-suspend.patch"
		epatch "${PATCHDIR}/unity-modifier-media-keys.patch"
	fi

	# https://bugzilla.gnome.org/show_bug.cgi?id=621836
	# Apparently this change severely affects touchpad usability for some
	# people, so revert it if USE=short-touchpad-timeout.
	# Revisit if/when upstream adds a setting for customizing the timeout.
	use short-touchpad-timeout &&
		epatch "${FILESDIR}/${PN}-3.7.90-short-touchpad-timeout.patch"

	# Make colord and wacom optional; requires eautoreconf
	epatch "${FILESDIR}/${PN}-3.10.2-optional.patch"

	epatch_user
	eautoreconf

	gnome2_src_prepare
}

src_configure() {
	gnome2_src_configure \
		--disable-static \
		--enable-man \
		$(use_enable colord color) \
		$(use_enable cups) \
		$(use_enable debug) \
		$(use_enable debug more-warnings) \
		$(use_enable i18n ibus) \
		$(use_enable packagekit) \
		$(use_enable smartcard smartcard-support) \
		$(use_enable udev gudev) \
		$(use_enable input_devices_wacom wacom)
}

src_test() {
	Xemake check
}

pkg_postinst() {
	gnome2_pkg_postinst

	if ! systemd_is_booted; then
		ewarn "${PN} needs Systemd to be *running* for working"
		ewarn "properly. Please follow the this guide to migrate:"
		ewarn "http://wiki.gentoo.org/wiki/Systemd"
	fi

	if use openrc-force; then
		ewarn "You are enabling 'openrc-force' USE flag to skip systemd requirement,"
		ewarn "this can lead to unexpected problems and is not supported neither by"
		ewarn "upstream neither by Gnome Gentoo maintainers. If you suffer any problem,"
		ewarn "you will need to disable this USE flag system wide and retest before"
		ewarn "opening any bug report."
	fi
}
