pkgdatadir = $(datadir)/xfce4/notes
noinst_LTLIBRARIES = libcnotes.la

libcnotes_la_SOURCES = \
	xfce-autostart.c \
	xfce-autostart.h

libcnotes_la_CFLAGS = \
	-DSYSCONFDIR=\""$(sysconfdir)"\" \
	-DPKGDATADIR=\""$(pkgdatadir)"\" \
	-DGETTEXT_PACKAGE=\""$(GETTEXT_PACKAGE)"\" \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	$(GIO_CFLAGS) \
	$(GTK_CFLAGS) \
	$(LIBXFCE4UTIL_CFLAGS) \
	$(XFCONF_CFLAGS)

libcnotes_la_LIBADD = \
	$(MATH_LIBS) \
	$(GIO_LIBS) \
	$(GTK_LIBS) \
	$(LIBXFCE4UTIL_LIBS) \
	$(XFCONF_LIBS)
