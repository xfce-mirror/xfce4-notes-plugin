dnl configure.ac
dnl
dnl xfce4-notes-plugin - Notes applet for the Xfce4 panel
dnl
dnl 2003 Jakob Henriksson <b0kaj+dev@lysator.liu.se>
dnl 2006 Mike Massonnet <mmassonnet@gmail.com>
dnl

m4_define([xfce4_notes_plugin_version], [0.11.1])

AC_INIT([xfce4-mpc-plugin], [xfce4_notes_plugin_version()], 
        [mmassonnet@gmail.com])

AM_INIT_AUTOMAKE([xfce4-mpc-plugin], [xfce4_notes_plugin_version()])

AM_MAINTAINER_MODE

dnl Check for basic programs
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_LIBTOOL
AC_PROG_INTLTOOL

dnl Check for standard header files
AC_HEADER_STDC

dnl Check for X11 installed
XDT_CHECK_LIBX11_REQUIRE

dnl configure the panel plugin
XDT_CHECK_PACKAGE([GTK], [gtk+-2.0], [2.6.0])
XDT_CHECK_PACKAGE([LIBXFCEGUI4], [libxfcegui4-1.0], [4.3.90])
XDT_CHECK_PACKAGE([LIBXFCE4UTIL], [libxfce4util-1.0], [4.3.90])
XDT_CHECK_PACKAGE([LIBXFCE4PANEL], [libxfce4panel-1.0], [4.3.90])

dnl Translations
XDT_I18N([@LINGUAS@])

dnl Check for debugging support
XDT_FEATURE_DEBUG()

AC_OUTPUT([
Makefile
panel-plugin/Makefile
po/Makefile.in
])
