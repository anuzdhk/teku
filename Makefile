PREFIX ?= /usr
DESTDIR ?=
SHARE := $(DESTDIR)$(PREFIX)/share
BINDIR := $(PREFIX)/bin
# Menu entries call teku by absolute path, so ~/.local/bin needn't be on PATH.
FIXPATH = sed -i -e 's|^Exec=teku|Exec=$(BINDIR)/teku|' -e 's|@BINDIR@|$(BINDIR)|'

.PHONY: install install-user uninstall uninstall-user test deb rpm appimage

install:
	install -Dm755 teku $(SHARE)/teku/teku
	install -Dm644 -t $(SHARE)/teku/lib lib/*.sh
	install -d $(DESTDIR)$(BINDIR)
	ln -sf ../share/teku/teku $(DESTDIR)$(BINDIR)/teku
	install -Dm644 data/teku.desktop $(SHARE)/applications/teku.desktop
	install -Dm644 data/icons/teku.png $(SHARE)/icons/hicolor/512x512/apps/teku.png
	install -Dm644 data/filemanager/dolphin/teku.desktop $(SHARE)/kio/servicemenus/teku.desktop
	install -Dm644 data/filemanager/nemo/teku.nemo_action $(SHARE)/nemo/actions/teku.nemo_action
	install -Dm644 data/filemanager/nautilus/teku_nautilus.py $(SHARE)/nautilus-python/extensions/teku_nautilus.py
	$(FIXPATH) $(SHARE)/applications/teku.desktop $(SHARE)/kio/servicemenus/teku.desktop \
		$(SHARE)/nemo/actions/teku.nemo_action $(SHARE)/nautilus-python/extensions/teku_nautilus.py
	# Packages leave the caches to the package manager's triggers.
	if [ -z "$(DESTDIR)" ]; then \
		update-desktop-database $(SHARE)/applications 2>/dev/null; \
		gtk-update-icon-cache -q $(SHARE)/icons/hicolor 2>/dev/null; \
	fi; true

# No root: everything under ~/.local, plus the Nautilus Scripts entry.
install-user:
	$(MAKE) install PREFIX=$(HOME)/.local
	$(HOME)/.local/bin/teku --integrate

uninstall:
	rm -rf $(SHARE)/teku
	rm -f $(DESTDIR)$(BINDIR)/teku $(SHARE)/applications/teku.desktop \
		$(SHARE)/icons/hicolor/512x512/apps/teku.png \
		$(SHARE)/kio/servicemenus/teku.desktop $(SHARE)/nemo/actions/teku.nemo_action \
		$(SHARE)/nautilus-python/extensions/teku_nautilus.py

uninstall-user:
	$(MAKE) uninstall PREFIX=$(HOME)/.local
	rm -f "$(HOME)/.local/share/nautilus/scripts/Install with Teku"

test:
	tests/run.sh

deb:
	packaging/debian/build-deb.sh

rpm:
	packaging/rpm/build-rpm.sh

appimage:
	packaging/appimage/build-appimage.sh
