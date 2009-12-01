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
	@LIBX11_CFLAGS@							\
	@GTK_CFLAGS@							\
	@LIBXFCEGUI4_CFLAGS@						\
	@XFCONF_CFLAGS@

xfce4_notes_settings_LDADD =						\
	@LIBX11_LIBS@							\
	@GTK_LIBS@							\
	@LIBXFCEGUI4_LIBS@						\
	@XFCONF_LIBS@

#
# Vala sources
#

notes_VAPISOURCES =							\
	config.vapi							\
	color.vapi							\
	popup.vapi							\
	xfce-autostart.vapi

notes_VALASOURCES =							\
	hypertextview.vala						\
	note.vala							\
	window.vala							\
	application.vala

notes_panel_plugin_VALASOURCES =					\
	main-panel-plugin.vala

notes_status_icon_VALASOURCES =						\
	main-status-icon.vala

notes_VALABUILTSOURCES = $(notes_VALASOURCES:.vala=.c)
notes_panel_plugin_VALABUILTSOURCES = $(notes_panel_plugin_VALASOURCES:.vala=.c)
notes_status_icon_VALABUILTSOURCES = $(notes_status_icon_VALASOURCES:.vala=.c)

if MAINTAINER_MODE
if HAVE_LIBXFCE4PANEL47
DEFINES=-D HAVE_LIBXFCE4PANEL47
PACKAGES=--pkg=config --pkg=color --pkg=popup --pkg=libxfcegui4-1.0 --pkg=gtk+-2.0
else
PACKAGES=--pkg=config --pkg=color --pkg=popup --pkg=gtk+-2.0
endif
BUILT_SOURCES = vala.stamp
vala.stamp: $(notes_VALASOURCES) $(notes_panel_plugin_VALASOURCES) $(notes_status_icon_VALASOURCES)
	$(VALAC) $(DEFINES) --vapidir=$(srcdir) $(PACKAGES)				\
		 --pkg=libxfconf-0 --pkg=libxfce4panel-1.0				\
		 $(notes_VALASOURCES) $(notes_panel_plugin_VALASOURCES) -C
	$(VALAC) $(DEFINES) --vapidir=$(srcdir) $(PACKAGES)				\
		 --pkg=xfce-autostart --pkg=libxfconf-0 --pkg=libxfce4util-1.0		\
		 $(notes_VALASOURCES) $(notes_status_icon_VALASOURCES) -C
	touch $@
endif

#
# Panel plugin
#

if HAVE_LIBXFCE4PANEL47

plugindir = $(libdir)/xfce4/panel-plugins
plugin_LTLIBRARIES = libnotes.la

libnotes_la_SOURCES =							\
	color.c								\
	color.h								\
	popup.c								\
	popup.h								\
	$(notes_VALABUILTSOURCES)					\
	$(notes_panel_plugin_VALABUILTSOURCES)

libnotes_la_CFLAGS =							\
	@LIBX11_CFLAGS@							\
	@LIBXFCE4PANEL_CFLAGS@						\
	@LIBXFCE4UTIL_CFLAGS@						\
	@LIBXFCEGUI4_CFLAGS@						\
	@XFCONF_CFLAGS@

libnotes_la_LIBADD =							\
	@LIBX11_LIBS@							\
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
	$(notes_VALABUILTSOURCES)					\
	$(notes_panel_plugin_VALABUILTSOURCES)

xfce4_notes_plugin_CFLAGS =						\
	@LIBX11_CFLAGS@							\
	@LIBXFCE4PANEL_CFLAGS@						\
	@LIBXFCE4UTIL_CFLAGS@						\
	@LIBXFCEGUI4_CFLAGS@						\
	@XFCONF_CFLAGS@

xfce4_notes_plugin_LDADD =						\
	@LIBX11_LIBS@							\
	@LIBXFCE4PANEL_LIBS@						\
	@LIBXFCE4UTIL_LIBS@						\
	@LIBXFCEGUI4_LIBS@						\
	@XFCONF_LIBS@

endif

#
# Status icon
#

bin_PROGRAMS += xfce4-notes

xfce4_notes_SOURCES =							\
	color.c								\
	color.h								\
	popup.c								\
	popup.h								\
	xfce-autostart.c						\
	xfce-autostart.h						\
	$(notes_VALABUILTSOURCES)					\
	$(notes_status_icon_VALABUILTSOURCES)

xfce4_notes_CFLAGS =							\
	@LIBX11_CFLAGS@							\
	@GTK_CFLAGS@							\
	@LIBXFCE4UTIL_CFLAGS@						\
	@LIBXFCEGUI4_CFLAGS@						\
	@XFCONF_CFLAGS@

xfce4_notes_LDADD =							\
	@LIBX11_LIBS@							\
	@GTK_LIBS@							\
	@LIBXFCE4UTIL_LIBS@						\
	@LIBXFCEGUI4_LIBS@						\
	@XFCONF_LIBS@

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
	$(notes_VAPISOURCES)						\
	$(notes_VALASOURCES)						\
	$(notes_panel_plugin_VALASOURCES)				\
	$(notes_status_icon_VALASOURCES)				\
	$(desktop_in_in_files)

if MAINTAINER_MODE
CLEANFILES =								\
	$(BUILT_SOURCES)						\
	$(notes_VALABUILTSOURCES)
endif

DISTCLEANFILES =							\
	$(desktop_DATA)							\
	$(desktop_in_files)

