INCLUDES =								\
	-I$(top_srcdir)							\
	-I$(top_srcdir)/lib						\
	-DGETTEXT_PACKAGE=\""$(GETTEXT_PACKAGE)"\"			\
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\"

#
# Popup program
#

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

#
# Settings dialog
#

bin_PROGRAMS += xfce4-notes-settings

xfce4_notes_settings_SOURCES =						\
	$(top_srcdir)/lib/color.c					\
	$(top_srcdir)/lib/color.h					\
	defines.h							\
	xfce4-notes-settings.c

xfce4_notes_settings_CFLAGS =						\
	@LIBX11_CFLAGS@							\
	@GTK_CFLAGS@							\
	@LIBXFCEGUI4_CFLAGS@						\
	@XFCONF_CFLAGS@							\
	@UNIQUE_CFLAGS@

xfce4_notes_settings_LDADD =						\
	@LIBX11_LIBS@							\
	@GTK_LIBS@							\
	@LIBXFCEGUI4_LIBS@						\
	@XFCONF_LIBS@							\
	@UNIQUE_LIBS@

#
# Panel plugin
#

if HAVE_LIBXFCE4PANEL47

plugindir = $(libdir)/xfce4/panel-plugins
plugin_LTLIBRARIES = libnotes.la

libnotes_la_VALAFLAGS =							\
	--vapidir=$(top_srcdir)/lib					\
	--pkg=libnotes							\
	--pkg=config							\
	--pkg=popup							\
	--pkg=gtk+-2.0							\
	--pkg=libxfce4panel-1.0						\
	--pkg=libxfconf-0						\
	--pkg=libxfce4util-1.0

libnotes_la_SOURCES =							\
	main-panel-plugin-47.vala

libnotes_la_CFLAGS =							\
	@LIBX11_CFLAGS@							\
	@LIBXFCE4PANEL_CFLAGS@						\
	@LIBXFCE4UTIL_CFLAGS@						\
	@XFCONF_CFLAGS@

libnotes_la_LIBADD =							\
	$(top_srcdir)/lib/libnotes.la					\
	@LIBX11_LIBS@							\
	@LIBXFCE4PANEL_LIBS@						\
	@LIBXFCE4UTIL_LIBS@						\
	@XFCONF_LIBS@

else

plugindir = $(libexecdir)/xfce4/panel-plugins
plugin_PROGRAMS = xfce4-notes-plugin

xfce4_notes_plugin_VALAFLAGS =						\
	--vapidir=$(top_srcdir)/lib					\
	--pkg=libnotes							\
	--pkg=config							\
	--pkg=popup							\
	--pkg=gtk+-2.0							\
	--pkg=libxfce4panel-1.0						\
	--pkg=libxfconf-0						\
	--pkg=libxfce4util-1.0

xfce4_notes_plugin_SOURCES =						\
	main-panel-plugin.vala

xfce4_notes_plugin_CFLAGS =						\
	@LIBX11_CFLAGS@							\
	@LIBXFCE4PANEL_CFLAGS@						\
	@LIBXFCE4UTIL_CFLAGS@						\
	@XFCONF_CFLAGS@

xfce4_notes_plugin_LDADD =						\
	$(top_srcdir)/lib/libnotes.la					\
	@LIBX11_LIBS@							\
	@LIBXFCE4PANEL_LIBS@						\
	@LIBXFCE4UTIL_LIBS@						\
	@XFCONF_LIBS@

endif

#
# Status icon
#

bin_PROGRAMS += xfce4-notes

xfce4_notes_VALAFLAGS =							\
	--vapidir=$(top_srcdir)/lib					\
	--pkg=libnotes							\
	--pkg=config							\
	--pkg=popup							\
	--vapidir=.							\
	--pkg=xfce-autostart						\
	--pkg=unique-1.0						\
	--pkg=gtk+-2.0							\
	--pkg=libxfconf-0						\
	--pkg=libxfce4util-1.0

xfce4_notes_SOURCES =							\
	xfce-autostart.c						\
	main-status-icon.vala

xfce4_notes_CFLAGS =							\
	@LIBX11_CFLAGS@							\
	@GTK_CFLAGS@							\
	@LIBXFCE4UTIL_CFLAGS@						\
	@XFCONF_CFLAGS@							\
	@UNIQUE_CFLAGS@

xfce4_notes_LDADD =							\
	$(top_srcdir)/lib/libnotes.la					\
	@LIBX11_LIBS@							\
	@GTK_LIBS@							\
	@LIBXFCE4UTIL_LIBS@						\
	@XFCONF_LIBS@							\
	@UNIQUE_LIBS@

#
# Plugin desktop file
#

desktopdir = $(datadir)/xfce4/panel-plugins
desktop_in_in_files =							\
	xfce4-notes-plugin-47.desktop.in				\
	xfce4-notes-plugin.desktop.in.in
desktop_in_files = xfce4-notes-plugin.desktop.in
if HAVE_LIBXFCE4PANEL47
desktop_DATA = xfce4-notes-plugin-47.desktop
else
desktop_DATA = xfce4-notes-plugin.desktop
endif
@INTLTOOL_DESKTOP_RULE@

xfce4-notes-plugin.desktop.in: xfce4-notes-plugin.desktop.in.in
	$(AM_V_GEN) sed -e "s^@EXTERNAL_PLUGIN_PATH@^$(plugindir)^" $< > $@

#
# Autostart file
#

autostartdir = $(sysconfdir)/xdg/autostart
autostart_in_files = xfce4-notes-autostart.desktop.in
autostart_DATA = $(autostart_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

#
# Extra
#

EXTRA_DIST =								\
	$(desktop_in_in_files)						\
	$(autostart_in_files)

DISTCLEANFILES =							\
	$(desktop_DATA)							\
	$(desktop_in_files)						\
	$(autostart_DATA)

