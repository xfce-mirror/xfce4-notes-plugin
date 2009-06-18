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
	defines.h							\
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

notes_VAPISOURCES =							\
	config.vapi							\
	color.vapi							\
	popup.vapi

notes_VALASOURCES =							\
	hypertextview.vala						\
	note.vala							\
	window.vala							\
	application.vala						\
	main.vala

notes_VALABUILTSOURCES = $(notes_VALASOURCES:.vala=.c)

if MAINTAINER_MODE
if HAVE_LIBXFCE4PANEL47
DEFINES=-D HAVE_LIBXFCE4PANEL47
PACKAGES=--pkg=libxfcegui4-1.0 --pkg=libxfce4panel-1.0
else
PACKAGES=--pkg=libxfce4panel-1.0
endif
BUILT_SOURCES = vala.stamp
$(notes_VALABUILTSOURCES): vala.stamp
vala.stamp: $(notes_VALASOURCES)
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
	$(notes_VALABUILTSOURCES)

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
	$(notes_VALABUILTSOURCES)

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

desktop_in_in_files =							\
	xfce4-notes-plugin-47.desktop.in.in				\
	xfce4-notes-plugin.desktop.in.in
desktop_in_files = $(desktop_in_in_files:.desktop.in.in=.desktop.in)

desktopdir = $(datadir)/xfce4/panel-plugins
if HAVE_LIBXFCE4PANEL47
desktop_DATA = xfce4-notes-plugin-47.desktop
else
desktop_DATA = xfce4-notes-plugin.desktop
endif
@INTLTOOL_DESKTOP_RULE@

%.desktop.in: %.desktop.in.in
	sed -e "s^@EXTERNAL_PLUGIN_PATH@^$(plugindir)^" \
		$< > $@

#
# Extra
#

EXTRA_DIST =								\
	$(notes_VAPISOURCES)						\
	$(notes_VALASOURCES)						\
	$(desktop_in_in_files)

if MAINTAINER_MODE
CLEANFILES =								\
	$(BUILT_SOURCES)						\
	$(notes_VALABUILTSOURCES)
endif

DISTCLEANFILES =							\
	$(desktop_DATA)							\
	$(desktop_in_files)

