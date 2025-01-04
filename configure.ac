dnl
dnl xfce4-notes-plugin - Notes plugin for the Xfce4 panel
dnl
dnl 2003 Jakob Henriksson <b0kaj+dev@lysator.liu.se>
dnl 2006-2016 Mike Massonnet <mmassonnet@xfce.org>
dnl 2023 Arthur Demchenkov <spinal.by@gmail.com>
dnl

XDT_VERSION_INIT([1.11.1], [git])

AC_COPYRIGHT([Copyright (c) 2003-2025 The Xfce development team. All rights reserved.])
AC_PREREQ([2.69])
AC_INIT([Notes], [xdt_version], [https://gitlab.xfce.org/panel-plugins/xfce4-notes-plugin], [xfce4-notes-plugin],
	[https://docs.xfce.org/panel-plugins/xfce4-notes-plugin])
AC_REVISION([xdt_version_build])
AC_CANONICAL_TARGET()
AC_CONFIG_HEADERS([config.h])

LT_PREREQ([2.2.6])
LT_INIT([disable-static])

AM_INIT_AUTOMAKE([1.13 dist-bzip2 no-dist-gzip foreign])
AM_MAINTAINER_MODE()
AM_SILENT_RULES([yes])
AC_CONFIG_MACRO_DIRS([m4])

dnl Check for basic programs
AM_PROG_CC_C_O()
LT_PATH_LD([])
AC_PROG_INSTALL()

dnl Check for Math lib useful for lib/color.c
AC_CHECK_HEADERS([math.h])
AC_SUBST([MATH_LIBS], [" -lm"])

dnl Check for required packages
XDT_CHECK_PACKAGE([GLIB], [glib-2.0], [2.50.0])
XDT_CHECK_PACKAGE([GIO], [gio-2.0], [2.50.0])
XDT_CHECK_PACKAGE([GTK], [gtk+-3.0], [3.22.0])
XDT_CHECK_PACKAGE([LIBXFCE4UTIL], [libxfce4util-1.0], [4.16.0])
XDT_CHECK_PACKAGE([LIBXFCE4UI], [libxfce4ui-2], [4.16.0])
XDT_CHECK_PACKAGE([XFCONF], [libxfconf-0], [4.16.0])
XDT_CHECK_PACKAGE([LIBXFCE4PANEL], [libxfce4panel-2.0], [4.16.0])
XDT_CHECK_PACKAGE([GTKSOURCEVIEW], [gtksourceview-4], [4.0.0])
dnl Check for valac
if test "x$USE_MAINTAINER_MODE" = "xyes" ; then
        AM_PROG_VALAC([0.46.0],
                      [VALAC_CFLAGS="-w"]
                      [AC_SUBST([VALAC_CFLAGS])],
                      [AC_MSG_ERROR([Cannot find "valac" compiler in your PATH])])
fi

dnl Translations
GETTEXT_PACKAGE="$PACKAGE"
AC_DEFINE_UNQUOTED([GETTEXT_PACKAGE], ["$GETTEXT_PACKAGE"], [Name of default gettext domain])
AC_SUBST([GETTEXT_PACKAGE])
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.19.8])

dnl Check for debugging support
XDT_FEATURE_DEBUG(xdt_debug_default)

AC_CONFIG_FILES([
Makefile
data/Makefile
data/gtk-3.0/Makefile
data/gtk-3.0/gtk.css
data/icons/Makefile
data/icons/16x16/Makefile
data/icons/22x22/Makefile
data/icons/24x24/Makefile
data/icons/32x32/Makefile
data/icons/scalable/Makefile
lib/Makefile
libc/Makefile
src/Makefile
po/Makefile.in
])
AC_OUTPUT

dnl ***************************
dnl *** Print configuration ***
dnl ***************************
echo
echo "Build Configuration:"
echo
echo "* Maintainer Mode:        $USE_MAINTAINER_MODE"
if test "x$USE_MAINTAINER_MODE" = "xyes" ; then
echo
echo "    * Vala:               $VALAC $am__vala_version"
echo
fi
echo "* GTK+:                   $GTK_VERSION"
echo "* Xfce Panel:             $LIBXFCE4PANEL_VERSION"
echo "* Debug Support:          $enable_debug"
echo
