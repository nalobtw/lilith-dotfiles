# ======================================================================
#  Makefile — lilith-select: the crosshair area selector for screenshots and recording
# ----------------------------------------------------------------------
#  make            build lilith-select (needs: cairo-devel wayland-devel wayland-protocols)
#  make preview    build the Wayland-free preview and render sample frames to PNG
#  The protocol code is generated at build time from XML: wlr-layer-shell comes from lilith's
#  source tree (WLR_XML), xdg-shell from the wayland-protocols package.
#  `lilith-rice select` runs this and installs the binary to ~/.local/bin.
# ======================================================================
CC       ?= cc
CFLAGS   ?= -O2 -Wall -Wextra
WLR_XML  ?= $(HOME)/.local/src/lilith/protocols/wlr-layer-shell-unstable-v1.xml
XDG_XML  ?= $(shell pkg-config --variable=pkgdatadir wayland-protocols)/stable/xdg-shell/xdg-shell.xml
PKGS     = wayland-client cairo
GEN      = wlr-layer-shell-unstable-v1-client-protocol.h wlr-layer-shell-unstable-v1-protocol.c \
           xdg-shell-client-protocol.h xdg-shell-protocol.c

lilith-select: main.c draw.c draw.h $(GEN)
	$(CC) $(CFLAGS) -o $@ main.c draw.c wlr-layer-shell-unstable-v1-protocol.c xdg-shell-protocol.c \
		$(shell pkg-config --cflags --libs $(PKGS))

wlr-layer-shell-unstable-v1-client-protocol.h: $(WLR_XML)
	wayland-scanner client-header $< $@
wlr-layer-shell-unstable-v1-protocol.c: $(WLR_XML)
	wayland-scanner private-code $< $@
xdg-shell-client-protocol.h: $(XDG_XML)
	wayland-scanner client-header $< $@
xdg-shell-protocol.c: $(XDG_XML)
	wayland-scanner private-code $< $@

preview: preview.c draw.c draw.h
	$(CC) $(CFLAGS) -o preview preview.c draw.c $(shell pkg-config --cflags --libs cairo)
	./preview 7fcfc0 frame

clean:
	rm -f lilith-select preview frame-*.png $(GEN)

.PHONY: preview clean
