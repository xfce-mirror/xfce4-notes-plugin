INCLUDES =								\
	-I$(top_srcdir)							\
	-I$(top_srcdir)/lib						\
	-DPKGDATADIR=\""$(pkgdatadir)"\"				\
	-DGETTEXT_PACKAGE=\""$(GETTEXT_PACKAGE)"\"			\
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\"

#
# Popup program
#

if ENABLE_GTK3
bin_PROGRAMS = 
else
bin_PROGRAMS = xfce4-popup-notes

xfce4_popup_notes_SOURCES =						\
	$(top_srcdir)/lib/popup.h					\
	xfce4-popup-notes.c

xfce4_popup_notes_CFLAGS =						\
	@LIBX11_CFLAGS@							\
	@GTK_CFLAGS@

xfce4_popup_notes_LDADD =						\
	@LIBX11_LIBS@							\
	@GTK_LIBS@
endif

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
	@XFCONF_CFLAGS@							\
	@UNIQUE_CFLAGS@

xfce4_notes_settings_LDADD =						\
	$(top_builddir)/lib/libnotes.la					\
	@LIBX11_LIBS@							\
	@GTK_LIBS@							\
	@LIBXFCE4UI_LIBS@						\
	@XFCONF_LIBS@							\
	@UNIQUE_LIBS@

#
# Panel plugin
#

if !ENABLE_GTK3
# REM Xfce Panel is not yet built with GTK3 support
# hence it's impossible to build a panel plugin yet

if MAINTAINER_MODE
notes_VALAFLAGS =							\
	--vapidir=$(top_srcdir)/lib					\
	--pkg=libnotes							\
	--pkg=config							\
	--pkg=libxfce4panel-1.0						\
	--pkg=libxfconf-0						\
	--pkg=libxfce4util-1.0

if ENABLE_GTK3
notes_VALAFLAGS +=							\
	-D ENABLE_GTK3							\
	--pkg=gtk+-3.0
else
notes_VALAFLAGS +=							\
	--pkg=popup							\
	--pkg=gtk+-2.0
endif

BUILT_SOURCES = main-panel-plugin.c
main-panel-plugin.c: main-panel-plugin.vala
	$(AM_V_GEN) $(VALAC) $(notes_VALAFLAGS) $< -C
endif

plugindir = $(libdir)/xfce4/panel-plugins
plugin_LTLIBRARIES = libnotes.la

libnotes_la_SOURCES =							\
	main-panel-plugin.c

libnotes_la_CFLAGS =							\
	@LIBX11_CFLAGS@							\
	@LIBXFCE4PANEL_CFLAGS@						\
	@LIBXFCE4UTIL_CFLAGS@						\
	@XFCONF_CFLAGS@

libnotes_la_LIBADD =							\
	$(top_builddir)/lib/libnotes.la					\
	@LIBX11_LIBS@							\
	@LIBXFCE4PANEL_LIBS@						\
	@LIBXFCE4UTIL_LIBS@						\
	@XFCONF_LIBS@

else
BUILT_SOURCES =
endif

#
# Status icon
#

bin_PROGRAMS += xfce4-notes

if MAINTAINER_MODE
xfce4_notes_VALAFLAGS =							\
	--vapidir=$(top_srcdir)/lib					\
	--pkg=libnotes							\
	--pkg=config							\
	--vapidir=.							\
	--pkg=xfce-autostart						\
	--pkg=libxfconf-0						\
	--pkg=libxfce4util-1.0

if ENABLE_GTK3
xfce4_notes_VALAFLAGS +=						\
	-D ENABLE_GTK3							\
	--pkg=gtk+-3.0
else
xfce4_notes_VALAFLAGS +=						\
	--pkg=popup							\
	--pkg=unique-1.0						\
	--pkg=gtk+-2.0
endif

BUILT_SOURCES += main-status-icon.c
main-status-icon.c: main-status-icon.vala
	$(AM_V_GEN) $(VALAC) $(xfce4_notes_VALAFLAGS) $< -C
endif

xfce4_notes_SOURCES =							\
	xfce-autostart.c						\
	xfce-autostart.h						\
	main-status-icon.c

xfce4_notes_CFLAGS =							\
	@LIBX11_CFLAGS@							\
	@GTK_CFLAGS@							\
	@LIBXFCE4UTIL_CFLAGS@						\
	@XFCONF_CFLAGS@							\
	@UNIQUE_CFLAGS@

xfce4_notes_LDADD =							\
	$(top_builddir)/lib/libnotes.la					\
	@LIBX11_LIBS@							\
	@GTK_LIBS@							\
	@LIBXFCE4UTIL_LIBS@						\
	@XFCONF_LIBS@							\
	@UNIQUE_LIBS@

#
# Plugin desktop file
#

desktopdir = $(datadir)/xfce4/panel-plugins
desktop_in_files = xfce4-notes-plugin.desktop.in
desktop_DATA = xfce4-notes-plugin.desktop
@INTLTOOL_DESKTOP_RULE@

#
# Applications desktop file
#

applicationsdir = $(datadir)/applications
applications_in_files = xfce4-notes.desktop.in
applications_DATA = xfce4-notes.desktop
@INTLTOOL_DESKTOP_RULE@

#
# Autostart desktop file
#

autostartdir = $(sysconfdir)/xdg/autostart
autostart_in_files = xfce4-notes-autostart.desktop.in
autostart_DATA = xfce4-notes-autostart.desktop
@INTLTOOL_DESKTOP_RULE@

#
# Extra
#

EXTRA_DIST =								\
	main-panel-plugin.vala						\
	main-status-icon.vala						\
	$(desktop_in_files)						\
	$(applications_in_files)					\
	$(autostart_in_files)

if ENABLE_GTK3
EXTRA_DIST +=								\
	xfce4-popup-notes.c
endif

DISTCLEANFILES =							\
	$(desktop_DATA)							\
	$(applications_DATA)						\
	$(autostart_DATA)

