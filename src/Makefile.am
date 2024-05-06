pkgdatadir = $(datadir)/xfce4/notes

BUILT_SOURCES =

AM_CPPFLAGS =								\
	-I$(top_srcdir)							\
	-I$(top_srcdir)/lib						\
	-DSYSCONFDIR=\""$(sysconfdir)"\"				\
	-DPKGDATADIR=\""$(pkgdatadir)"\"				\
	-DGETTEXT_PACKAGE=\""$(GETTEXT_PACKAGE)"\"			\
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\"

#
# Popup program
#

bin_PROGRAMS = xfce4-popup-notes

if MAINTAINER_MODE
xfce4_popup_notes_VALAFLAGS =						\
	--pkg=gtk+-3.0

BUILT_SOURCES += main-popup.c
main-popup.c: main-popup.vala
	$(AM_V_GEN) $(VALAC) $(xfce4_popup_notes_VALAFLAGS) $< -C
endif

xfce4_popup_notes_SOURCES =						\
	main-popup.c

xfce4_popup_notes_CFLAGS =						\
	@GTK_CFLAGS@ \
	@VALAC_CFLAGS@

xfce4_popup_notes_LDADD =						\
	@GTK_LIBS@

#
# Settings dialog
#

bin_PROGRAMS += xfce4-notes-settings

xfce4_notes_settings_SOURCES =						\
	defines.h							\
	main-settings-dialog.c

xfce4_notes_settings_CFLAGS =						\
	@LIBX11_CFLAGS@							\
	@GTK_CFLAGS@							\
	@LIBXFCE4UI_CFLAGS@						\
	@XFCONF_CFLAGS@

xfce4_notes_settings_LDADD =						\
	$(top_builddir)/lib/libnotes.la					\
	@LIBX11_LIBS@							\
	@GTK_LIBS@							\
	@LIBXFCE4UI_LIBS@						\
	@XFCONF_LIBS@

#
# Panel plugin
#

if MAINTAINER_MODE
notes_VALAFLAGS =							\
   --vapidir=$(top_srcdir)/lib						\
   --pkg=libnotes							\
	--pkg=config							\
	--pkg=gtksourceview-4						\
	--pkg=libxfce4panel-2.0						\
	--pkg=libxfconf-0						\
	--pkg=libxfce4util-1.0

notes_VALAFLAGS +=							\
	-D ENABLE_GTK3							\
	--pkg=gtk+-3.0

BUILT_SOURCES += main-panel-plugin.c
main-panel-plugin.c: main-panel-plugin.vala
	$(AM_V_GEN) $(VALAC) $(notes_VALAFLAGS) $< -C
endif

plugindir = $(libdir)/xfce4/panel/plugins
plugin_LTLIBRARIES = libnotes.la
#
libnotes_la_SOURCES =							\
	main-panel-plugin.c
#
libnotes_la_CFLAGS =							\
	@LIBX11_CFLAGS@							\
	@GTKSOURCEVIEW_CFLAGS@						\
	@LIBXFCE4PANEL_CFLAGS@						\
	@LIBXFCE4UTIL_CFLAGS@						\
	@XFCONF_CFLAGS@ \
	@VALAC_CFLAGS@
#
libnotes_la_LIBADD =							\
	$(top_builddir)/lib/libnotes.la					\
	@LIBX11_LIBS@							\
	@GTKSOURCEVIEW_LIBS@						\
	@LIBXFCE4PANEL_LIBS@						\
	@LIBXFCE4UTIL_LIBS@						\
	@XFCONF_LIBS@
#
libnotes_la_LDFLAGS =							\
	-avoid-version							\
	-module								\
	-no-undefined							\
	-export-symbols-regex '^xfce_panel_module_(preinit|init|construct)' \
	$(PLATFORM_LDFLAGS)
#endif

#
# Status icon
#

bin_PROGRAMS += xfce4-notes

if MAINTAINER_MODE
xfce4_notes_VALAFLAGS =							\
	--vapidir=$(top_srcdir)/lib					\
	--vapidir=$(top_srcdir)/libc					\
	--pkg=libnotes							\
	--pkg=config							\
	--pkg=xfce-autostart						\
	--pkg=libxfconf-0						\
	--pkg=gtksourceview-4						\
	--pkg=libxfce4util-1.0						\
	--pkg=gtk+-3.0

BUILT_SOURCES += main-status-icon.c
main-status-icon.c: main-status-icon.vala
	$(AM_V_GEN) $(VALAC) $(xfce4_notes_VALAFLAGS) $< -C
endif

xfce4_notes_SOURCES =							\
	main-status-icon.c

xfce4_notes_CFLAGS =							\
	@LIBX11_CFLAGS@							\
	@GTK_CFLAGS@							\
	@GTKSOURCEVIEW_CFLAGS@						\
	@LIBXFCE4UTIL_CFLAGS@						\
	@XFCONF_CFLAGS@ \
	@VALAC_CFLAGS@

xfce4_notes_LDADD =							\
	$(top_builddir)/lib/libnotes.la					\
	$(top_builddir)/libc/libcnotes.la				\
	@LIBX11_LIBS@							\
	@GTK_LIBS@							\
	@GTKSOURCEVIEW_LIBS@						\
	@LIBXFCE4UTIL_LIBS@						\
	@XFCONF_LIBS@

#
# Plugin desktop file
#

desktopdir = $(datadir)/xfce4/panel/plugins
desktop_in_files = xfce4-notes-plugin.desktop.in
desktop_DATA = xfce4-notes-plugin.desktop

#
# Applications desktop file
#

applicationsdir = $(datadir)/applications
applications_in_files = xfce4-notes.desktop.in
applications_DATA = xfce4-notes.desktop

#
# Autostart desktop file
#

autostartdir = $(sysconfdir)/xdg/autostart
autostart_in_files = xfce4-notes-autostart.desktop.in
autostart_DATA = xfce4-notes-autostart.desktop

%.desktop: %.desktop.in
	$(AM_V_GEN) $(MSGFMT) --desktop --template $< -d $(top_srcdir)/po -o $@

#
# Extra
#

EXTRA_DIST =								\
	main-panel-plugin.vala						\
	main-status-icon.vala						\
	main-popup.vala							\
	$(desktop_in_files)						\
	$(applications_in_files)					\
	$(autostart_in_files)

DISTCLEANFILES =							\
	$(desktop_DATA)							\
	$(applications_DATA)						\
	$(autostart_DATA)
