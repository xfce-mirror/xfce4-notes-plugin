ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

@SET_MAKE@

SUBDIRS =								\
	data								\
	lib								\
	libc								\
	src								\
	po

distclean-local:
	rm -rf *.cache *~

.PHONY: ChangeLog

ChangeLog: Makefile
	(GIT_DIR=$(top_srcdir)/.git git log > .changelog.tmp \
	&& mv .changelog.tmp ChangeLog; rm -f .changelog.tmp) \
	|| (touch ChangeLog; echo 'Git directory not found: installing possibly empty changelog.' >&2)

dist-hook: ChangeLog

EXTRA_DIST =								\
	AUTHORS								\
	ChangeLog							\
	COPYING								\
	NEWS								\
	README.md								\
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
	po/.intltool-merge-cache.lock					\
	$(desktop_DATA)
