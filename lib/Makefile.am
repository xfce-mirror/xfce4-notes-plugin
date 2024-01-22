pkgdatadir = $(datadir)/xfce4/notes
noinst_LTLIBRARIES = libnotes.la

libnotes_la_VALAFLAGS =							\
	--library=libnotes						\
	--header=libnotes.h						\
	--vapidir=$(srcdir)						\
	--pkg=config							\
	--pkg=libxfconf-0						\
	--pkg=libxfce4util-1.0						\
	--pkg=gtksourceview-4						\
	--pkg=gtk+-3.0

libnotes_la_SOURCES =							\
	icon-button.vala						\
	window-monitor.vala						\
	application.vala						\
	hypertextview.vala						\
	note.vala							\
	window.vala							\
	theme.vala							\
	theme-gtkcss.vala

libnotes_la_CFLAGS =							\
	-DSYSCONFDIR=\""$(sysconfdir)"\"				\
	-DPKGDATADIR=\""$(pkgdatadir)"\"				\
	-DGETTEXT_PACKAGE=\""$(GETTEXT_PACKAGE)"\"			\
	@LIBX11_CFLAGS@							\
	@GIO_CFLAGS@							\
	@GTK_CFLAGS@							\
	@GTKSOURCEVIEW_CFLAGS@						\
	@LIBXFCE4UTIL_CFLAGS@						\
	@XFCONF_CFLAGS@ \
	@VALAC_CFLAGS@

libnotes_la_LIBADD =							\
	@MATH_LIBS@							\
	@LIBX11_LIBS@							\
	@GIO_LIBS@							\
	@GTK_LIBS@							\
	@GTKSOURCEVIEW_LIBS@						\
	@LIBXFCE4UTIL_LIBS@						\
	@XFCONF_LIBS@

EXTRA_DIST =								\
	libnotes.vapi							\
	libnotes.h

libnotes.vapi libnotes.h: libnotes_la_vala.stamp
