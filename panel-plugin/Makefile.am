INCLUDES =								\
	-I$(top_srcdir)							\
	-DGETTEXT_PACKAGE=\""$(GETTEXT_PACKAGE)"\"			\
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\"

#
# Popup program
#
bin_PROGRAMS = xfce4-popup-notes

xfce4_popup_notes_SOURCES =						\
	popup.h								\
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
	hypertextview.vala						\
	note.vala							\
	window.vala							\
	application.vala						\
	main.vala

vala_built_SOURCES = $(xfce4_notes_plugin_VALASOURCES:.vala=.c)
BUILT_SOURCES = vala.stamp

if HAVE_LIBXFCE4PANEL47
DEFINES=-D HAVE_LIBXFCE4PANEL47
PACKAGES=--pkg=libxfcegui4-1.0 --pkg=libxfce4panel-1.0
else
PACKAGES=--pkg=libxfce4panel-1.0
endif
vala.stamp: $(xfce4_notes_plugin_VALASOURCES)
	$(VALAC) $(DEFINES) --vapidir=$(srcdir) --pkg=config --pkg=color --pkg=popup --pkg=libxfconf-0 $(PACKAGES) $^ -C
	touch $@
endif

#
# Plugin
#
if HAVE_LIBXFCE4PANEL47

plugindir = $(libdir)/xfce4/panel-plugins
plugin_LTLIBRARIES = libnotes.la

libnotes_la_SOURCES =							\
	color.c								\
	color.h								\
	popup.c								\
	popup.h								\
	$(vala_built_SOURCES)

libnotes_la_CFLAGS =							\
	@LIBXFCE4PANEL_CFLAGS@						\
	@LIBXFCE4UTIL_CFLAGS@						\
	@LIBXFCEGUI4_CFLAGS@						\
	@XFCONF_CFLAGS@

libnotes_la_LIBADD =							\
	@LIBXFCE4PANEL_LIBS@						\
	@LIBXFCE4UTIL_LIBS@						\
	@LIBXFCEGUI4_LIBS@						\
	@XFCONF_LIBS@

else

plugindir = $(libexecdir)/xfce4/panel-plugins
plugin_PROGRAMS = xfce4-notes-plugin

xfce4_notes_plugin_SOURCES =						\
	color.c								\
	color.h								\
	popup.c								\
	popup.h								\
	$(vala_built_SOURCES)

xfce4_notes_plugin_CFLAGS =						\
	@LIBXFCE4PANEL_CFLAGS@						\
	@LIBXFCE4UTIL_CFLAGS@						\
	@LIBXFCEGUI4_CFLAGS@						\
	@XFCONF_CFLAGS@

xfce4_notes_plugin_LDADD =						\
	@LIBXFCE4PANEL_LIBS@						\
	@LIBXFCE4UTIL_LIBS@						\
	@LIBXFCEGUI4_LIBS@						\
	@XFCONF_LIBS@

endif

#
# Plugin desktop file
#
if HAVE_LIBXFCE4PANEL47
desktop_in_in_files = xfce4-notes-plugin-47.desktop.in.in
else
desktop_in_in_files = xfce4-notes-plugin.desktop.in.in
endif
desktop_in_files = $(desktop_in_in_files:.desktop.in.in=.desktop.in)

desktopdir = $(datadir)/xfce4/panel-plugins
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

%.desktop.in: %.desktop.in.in
	sed -e "s^@EXTERNAL_PLUGIN_PATH@^$(plugindir)^" \
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

