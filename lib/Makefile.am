noinst_LTLIBRARIES = libnotes.la

libnotes_la_VALAFLAGS =							\
	--library=libnotes						\
	--header=libnotes.h						\
	--vapidir=$(srcdir)						\
	--vapidir=$(top_srcdir)/data/vapi/gtk214			\
	--pkg=config							\
	--pkg=color							\
	--pkg=gtk+-2.0							\
	--pkg=libxfconf-0						\
	--pkg=libxfce4util-1.0

libnotes_la_SOURCES =							\
	icon-button.vala						\
	window-monitor.vala						\
	application.vala						\
	hypertextview.vala						\
	note.vala							\
	window.vala							\
	color.c								\
	popup.c

libnotes_la_CFLAGS =							\
	-DPKGDATADIR=\""$(pkgdatadir)"\"				\
	-DGETTEXT_PACKAGE=\""$(GETTEXT_PACKAGE)"\"			\
	@LIBX11_CFLAGS@							\
	@GIO_CFLAGS@							\
	@GTK_CFLAGS@							\
	@LIBXFCE4UTIL_CFLAGS@						\
	@XFCONF_CFLAGS@

libnotes_la_LIBADD =							\
	@MATH_LIBS@							\
	@LIBX11_LIBS@							\
	@GIO_LIBS@							\
	@GTK_LIBS@							\
	@LIBXFCE4UTIL_LIBS@						\
	@XFCONF_LIBS@

EXTRA_DIST =								\
	color.h								\
	popup.h								\
	libnotes.vapi							\
	libnotes.h
