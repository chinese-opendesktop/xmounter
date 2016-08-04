VERSION = 0.3
DESTDIR =
PREFIX = /usr
PACKAGE = xmounter

all:
	xgettext -L Shell -o $(PACKAGE).pot $(PACKAGE).sh
	for i in *.po ; do msgfmt $$i -o $${i%%.po}.gmo ; done

clean:
	rm -f *.gmo

install:
	install -D -m 755 $(PACKAGE).sh $(DESTDIR)$(PREFIX)/bin/$(PACKAGE)
	install -D -m 644 $(PACKAGE).desktop $(DESTDIR)$(PREFIX)/share/applications/$(PACKAGE).desktop
	install -D -m 644 $(PACKAGE).xpm $(DESTDIR)$(PREFIX)/share/pixmaps/$(PACKAGE).xpm
	for i in *.gmo ; do install -D -m 644 $$i $(DESTDIR)$(PREFIX)/share/locale/$${i%.gmo}/LC_MESSAGES/$(PACKAGE).mo ; done

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(PACKAGE)
	rm -f $(DESTDIR)$(PREFIX)/share/pixmaps/$(PACKAGE).xpm
	rm -f $(DESTDIR)$(PREFIX)/share/applications/$(PACKAGE).desktop
	rm -f $(DESTDIR)$(PREFIX)/share/locale/*/LC_MESSAGES/$(PACKAGE).mo

rpm:
	rm -rf $(HOME)/rpmbuild/SOURCES/$(PACKAGE)-$(VERSION)
	cp -Rf ../$(PACKAGE) $(HOME)/rpmbuild/SOURCES/$(PACKAGE)-$(VERSION)
	sed -i 's/@VERSION@/$(VERSION)/' $(HOME)/rpmbuild/SOURCES/$(PACKAGE)-$(VERSION)/{$(PACKAGE).sh,$(PACKAGE).spec}
	sed -i '/rpm:/,$$d' $(HOME)/rpmbuild/SOURCES/$(PACKAGE)-$(VERSION)/Makefile
	tar czvf $(HOME)/rpmbuild/SOURCES/$(PACKAGE)-$(VERSION).tar.gz -C $(HOME)/rpmbuild/SOURCES $(PACKAGE)-$(VERSION)
	rpmbuild -ta $(HOME)/rpmbuild/SOURCES/$(PACKAGE)-$(VERSION).tar.gz
