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
# Vala sources
#
if MAINTAINER_MODE
xfce4_notes_plugin_VALASOURCES =					\
	hypertextview.vala

vala_built_SOURCES =							\
	$(xfce4_notes_plugin_VALASOURCES:.vala=.c)			\
	$(xfce4_notes_plugin_VALASOURCES:.vala=.h)

BUILT_SOURCES = vala.stamp
vala.stamp: $(xfce4_notes_plugin_VALASOURCES)
	$(VALAC) --pkg=gtk+-2.0 $^ -C -H vala-objects.h
	touch $@
endif

#
# Plugin
#
plugindir = $(libexecdir)/xfce4/panel-plugins
plugin_PROGRAMS = xfce4-notes-plugin

xfce4_notes_plugin_SOURCES =						\
	defines.h							\
	xfce-arrow-button.c						\
	xfce-arrow-button.h						\
	color.c								\
	color.h								\
	panel-plugin.c							\
	settings-dialog.c						\
	settings-dialog.h						\
	notes.c								\
	notes.h
xfce4_notes_plugin_SOURCES += $(vala_built_SOURCES)

xfce4_notes_plugin_CFLAGS =						\
	-I$(top_srcdir)							\
	@LIBXFCE4PANEL_CFLAGS@						\
	@LIBXFCE4UTIL_CFLAGS@						\
	@LIBXFCEGUI4_CFLAGS@						\
	@THUNAR_VFS_CFLAGS@						\
	@XFCONF_CFLAGS@							\
	-DPACKAGE_LOCALE_DIR=\"$(localedir)\"

xfce4_notes_plugin_LDADD =						\
	@LIBXFCE4PANEL_LIBS@						\
	@LIBXFCE4UTIL_LIBS@						\
	@LIBXFCEGUI4_LIBS@						\
	@THUNAR_VFS_LIBS@						\
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

DISTCLEANFILES =							\
	$(desktop_DATA) $(desktop_in_files) $(BUILT_SOURCES) $(vala_built_SOURCES)

