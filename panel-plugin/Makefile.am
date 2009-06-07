#
# Popup program
#
bin_PROGRAMS = xfce4-popup-notes

xfce4_popup_notes_SOURCES =						\
	xfce4-popup-notes.c						\
	xfce4-popup-notes.h

xfce4_popup_notes_CFLAGS =						\
	@LIBX11_CFLAGS@							\
	@GTK_CFLAGS@

xfce4_popup_notes_LDADD =						\
	@LIBX11_LDFLAGS@						\
	@LIBX11_LIBS@							\
	@GTK_LIBS@

#
# Settings dialog
#
bin_PROGRAMS += xfce4-notes-settings

xfce4_notes_settings_SOURCES =						\
	color.c								\
	color.h								\
	xfce4-notes-settings.c

xfce4_notes_settings_CFLAGS =						\
	@GTK_CFLAGS@							\
	@LIBXFCEGUI4_CFLAGS@						\
	@XFCONF_CFLAGS@

xfce4_notes_settings_LDADD =						\
	@GTK_LIBS@							\
	@LIBXFCEGUI4_LIBS@						\
	@XFCONF_LIBS@

#
# Vala sources
#
if MAINTAINER_MODE
xfce4_notes_plugin_VALASOURCES =					\
	main.vala							\
	application.vala						\
	window.vala							\
	note.vala							\
	hypertextview.vala

vala_built_SOURCES = $(xfce4_notes_plugin_VALASOURCES:.vala=.c)

BUILT_SOURCES = vala.stamp
vala.stamp: $(xfce4_notes_plugin_VALASOURCES)
	$(VALAC) --vapidir=. --pkg=config --pkg=color --pkg=libxfconf-0 --pkg=libxfce4panel-1.0 $^ -C
	touch $@
endif

#
# Plugin
#
plugindir = $(libexecdir)/xfce4/panel-plugins
plugin_PROGRAMS = xfce4-notes-plugin

xfce4_notes_plugin_SOURCES =						\
	color.c								\
	color.h								\
xfce4_notes_plugin_SOURCES += $(vala_built_SOURCES)

xfce4_notes_plugin_CFLAGS =						\
	-I$(top_srcdir)							\
	@LIBXFCE4PANEL_CFLAGS@						\
	@LIBXFCE4UTIL_CFLAGS@						\
	@LIBXFCEGUI4_CFLAGS@						\
	@XFCONF_CFLAGS@							\
	-DPACKAGE_LOCALE_DIR=\"$(localedir)\"

xfce4_notes_plugin_LDADD =						\
	@LIBXFCE4PANEL_LIBS@						\
	@LIBXFCE4UTIL_LIBS@						\
	@LIBXFCEGUI4_LIBS@						\
	@XFCONF_LIBS@

#
# Plugin desktop file
#
desktop_in_in_files = xfce4-notes-plugin.desktop.in.in
desktop_in_files = $(desktop_in_in_files:.desktop.in.in=.desktop.in)

desktopdir = $(datadir)/xfce4/panel-plugins
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

%.desktop.in: %.desktop.in.in
	sed -e "s^@EXTERNAL_PLUGIN_PATH@^$(libexecdir)/xfce4/panel-plugins^" \
		$< > $@

#
# Extra
#
EXTRA_DIST =								\
	$(desktop_in_in_files) $(xfce4_notes_plugin_VALASOURCES)

CLEANFILES =								\
	$(BUILT_SOURCES) $(vala_built_SOURCES)

DISTCLEANFILES =							\
	$(desktop_DATA) $(desktop_in_files)

