plugindir = @XFCE4_PANEL_PLUGINSDIR@

plugin_LTLIBRARIES =							\
	libnotes.la

libnotes_la_LDFLAGS =							\
	-avoid-version							\
	-export-dynamic							\
	-module

libnotes_la_SOURCES =							\
	notes.c								\
	notes_applet.c							\
	notes_options.c							\
	notes.h								\
	notes_icons.h

libnotes_la_CFLAGS =							\
	-DPACKAGE_LOCALE_DIR=\"$(localedir)\"				\
	-DICONDIR=\"$(datadir)/xfce4/notes\"				\
	@XFCE4_PANEL_CFLAGS@

libnotes_la_LIBADD = 							\
	@XFCE4_PANEL_LIBS@
