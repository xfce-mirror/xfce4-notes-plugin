ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

@SET_MAKE@

SUBDIRS =								\
	data								\
	lib								\
	src								\
	po

distclean-local:
	rm -rf *.cache *~

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

