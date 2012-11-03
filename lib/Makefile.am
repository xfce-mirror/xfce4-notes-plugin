noinst_LTLIBRARIES = libnotes.la

libnotes_la_VALAFLAGS =							\
	--library=libnotes						\
	--header=libnotes.h						\
	--vapidir=$(srcdir)						\
	--pkg=config							\
	--pkg=color							\
	--pkg=libxfconf-0						\
	--pkg=libxfce4util-1.0

if ENABLE_GTK3
libnotes_la_VALAFLAGS +=						\
	-D ENABLE_GTK3							\
	--pkg=gtk+-3.0
else
libnotes_la_VALAFLAGS +=						\
	--pkg=gtk+-2.0
endif

libnotes_la_SOURCES =							\
	icon-button.vala						\
	window-monitor.vala						\
	application.vala						\
	hypertextview.vala						\
	note.vala							\
	window.vala							\
	color.c

if !ENABLE_GTK3
libnotes_la_SOURCES +=							\
	popup.c
endif

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

if ENABLE_GTK3
EXTRA_DIST +=								\
	popup.c
endif

