@SET_MAKE@

SUBDIRS =								\
	icons								\
	panel-plugin							\
	po

distclean-local:
	rm -rf *.cache *~

desktopdir = $(datadir)/applications
desktop_in_files = xfce4-notes.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

EXTRA_DIST =								\
	AUTHORS								\
	ChangeLog							\
	COPYING								\
	INSTALL								\
	NEWS								\
	README								\
	intltool-extract.in						\
	intltool-merge.in						\
	intltool-update.in						\
	$(desktop_in_files)

DISTCLEANFILES =							\
	aclocal.m4							\
	compile								\
	config.guess							\
	config.h.in							\
	config.sub							\
	configure							\
	configure.ac							\
	depcomp								\
	install-sh							\
	ltmain.sh							\
	missing								\
	mkinstalldirs							\
	intltool-extract						\
	intltool-merge							\
	intltool-update							\
	$(desktop_DATA)

