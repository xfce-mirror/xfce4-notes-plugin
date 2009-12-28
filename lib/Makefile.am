INCLUDES =								\
	-DGETTEXT_PACKAGE=\""$(GETTEXT_PACKAGE)"\"

noinst_LTLIBRARIES = libnotes.la

libnotes_la_VALAFLAGS =							\
	--library=libnotes						\
	--header=libnotes.h						\
	--vapidir=.							\
	--pkg=config							\
	--pkg=color							\
	--pkg=gtk+-2.0							\
	--pkg=libxfconf-0						\
	--pkg=libxfce4util-1.0

libnotes_la_SOURCES =							\
	application.vala						\
	hypertextview.vala						\
	note.vala							\
	window.vala							\
	color.c								\
	popup.c

libnotes_la_CFLAGS =							\
	@LIBX11_CFLAGS@							\
	@GTK_CFLAGS@							\
	@LIBXFCE4UTIL_CFLAGS@						\
	@XFCONF_CFLAGS@

libnotes_la_LIBADD =							\
	@LIBX11_LIBS@							\
	@GTK_LIBS@							\
	@LIBXFCE4UTIL_LIBS@						\
	@XFCONF_LIBS@

EXTRA_DIST =								\
	libnotes.vapi							\
	libnotes.h