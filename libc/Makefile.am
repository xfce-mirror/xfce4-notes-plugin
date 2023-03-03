noinst_LTLIBRARIES = libcnotes.la

libcnotes_la_SOURCES = \
	xfce-autostart.c \
	xfce-autostart.h

libcnotes_la_CFLAGS = \
	-DPKGDATADIR=\""$(pkgdatadir)"\" \
	-DGETTEXT_PACKAGE=\""$(GETTEXT_PACKAGE)"\" \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	$(LIBX11_CFLAGS) \
	$(GIO_CFLAGS) \
	$(GTK_CFLAGS) \
	$(LIBXFCE4UTIL_CFLAGS) \
	$(XFCONF_CFLAGS)

libcnotes_la_LIBADD = \
	$(MATH_LIBS \
	$(LIBX11_LIBS \
	$(GIO_LIBS \
	$(GTK_LIBS \
	$(LIBXFCE4UTIL_LIBS \
	$(XFCONF_LIBS)
