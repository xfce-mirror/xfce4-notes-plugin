dnl configure.ac
dnl
dnl xfce4-notes-plugin - Notes applet for the XFce4 panel
dnl
dnl 2003 Jakob Henriksson <b0kaj+dev@lysator.liu.se>
dnl

AC_INIT([configure])

AM_CONFIG_HEADER([config.h])

AM_INIT_AUTOMAKE([xfce4-notes-plugin], [0.10.0])

AM_MAINTAINER_MODE

dnl Check for UNIX variants
AC_AIX
AC_ISC_POSIX
AC_MINIX

dnl Check for basic programs
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_LIBTOOL

dnl Check for standard header files
AC_HEADER_STDC

dnl configure the panel plugin
XFCE_PANEL_PLUGIN([XFCE4_PANEL], [4.1.90])

dnl Check for debugging support
BM_DEBUG_SUPPORT

AC_OUTPUT([
Makefile
panel-plugin/Makefile
pixmaps/Makefile
xfce4-notes-plugin.spec
])
