@SET_MAKE@

EXTRA_DIST =								\
	xfce4-notes-plugin.spec                                         \
	NOTES

SUBDIRS = panel-plugin pixmaps

distclean-local:
	rm -rf *.cache *~ *.spec

rpm: dist
	rpmbuild -ta $(PACKAGE)-$(VERSION).tar.gz
	@rm -f $(PACKAGE)-$(VERSION).tar.gz

ACLOCAL_AMFLAGS = -I m4
