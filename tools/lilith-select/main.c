/* ======================================================================
 *  main.c — lilith-select: the Wayland side (a fullscreen layer-shell overlay)
 * ----------------------------------------------------------------------
 *  usage: lilith-select [-c RRGGBB] [-d dim]
 *  Drag with the left button to select an area; Esc or the right button cancels.
 *  Prints  "x,y WxH"  on stdout (like slurp) and exits 0; exits 1 when cancelled.
 *  Single-output geometry: the overlay covers one output at the origin (the laptop screen).
 *  What a frame looks like is in draw.c.
 * ====================================================================== */
#define _GNU_SOURCE
#include <linux/input-event-codes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#include <cairo.h>
#include <wayland-client.h>

#include "draw.h"
#include "wlr-layer-shell-unstable-v1-client-protocol.h"

#define NBUF 2

struct buffer {
	struct wl_buffer *buf;
	unsigned char *data;
	int busy;
};

struct app {
	struct wl_display *display;
	struct wl_registry *registry;
	struct wl_compositor *compositor;
	struct wl_shm *shm;
	struct wl_seat *seat;
	struct zwlr_layer_shell_v1 *layer_shell;
	struct wl_pointer *pointer;
	struct wl_keyboard *keyboard;
	struct wl_surface *surface;
	struct zwlr_layer_surface_v1 *layer;
	int w, h;
	int have_buffers;
	int dirty;
	struct buffer bufs[NBUF];
	struct sel_state sel;
	struct sel_style style;
	int done, cancelled;
};

/* ---------------------------------------------------------------- drawing */
static void redraw(struct app *a)
{
	int i;
	if (!a->have_buffers)
		return;
	for (i = 0; i < NBUF && a->bufs[i].busy; i++)
		;
	if (i == NBUF) {              /* both buffers still on screen: draw when one is released */
		a->dirty = 1;
		return;
	}
	cairo_surface_t *surf = cairo_image_surface_create_for_data(a->bufs[i].data, CAIRO_FORMAT_ARGB32, a->w, a->h, a->w * 4);
	cairo_t *cr = cairo_create(surf);
	select_draw(cr, a->w, a->h, &a->sel, &a->style);
	cairo_destroy(cr);
	cairo_surface_destroy(surf);

	wl_surface_attach(a->surface, a->bufs[i].buf, 0, 0);
	wl_surface_damage_buffer(a->surface, 0, 0, a->w, a->h);
	wl_surface_commit(a->surface);
	a->bufs[i].busy = 1;
	a->dirty = 0;
}

static void buffer_release(void *data, struct wl_buffer *buffer)
{
	struct app *a = data;
	for (int i = 0; i < NBUF; i++)
		if (a->bufs[i].buf == buffer)
			a->bufs[i].busy = 0;
	if (a->dirty)
		redraw(a);
}
static const struct wl_buffer_listener buffer_listener = { .release = buffer_release };

static int create_buffers(struct app *a)
{
	size_t stride = (size_t)a->w * 4, one = stride * (size_t)a->h, total = one * NBUF;
	int fd = memfd_create("lilith-select", MFD_CLOEXEC);
	if (fd < 0 || ftruncate(fd, (off_t)total) < 0)
		return -1;
	unsigned char *map = mmap(NULL, total, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (map == MAP_FAILED) {
		close(fd);
		return -1;
	}
	struct wl_shm_pool *pool = wl_shm_create_pool(a->shm, fd, (int32_t)total);
	for (int i = 0; i < NBUF; i++) {
		a->bufs[i].data = map + one * (size_t)i;
		a->bufs[i].buf = wl_shm_pool_create_buffer(pool, (int32_t)(one * (size_t)i), a->w, a->h, (int32_t)stride, WL_SHM_FORMAT_ARGB8888);
		a->bufs[i].busy = 0;
		wl_buffer_add_listener(a->bufs[i].buf, &buffer_listener, a);
	}
	wl_shm_pool_destroy(pool);
	close(fd);
	a->have_buffers = 1;
	return 0;
}

/* ---------------------------------------------------------------- the layer surface */
static void layer_configure(void *data, struct zwlr_layer_surface_v1 *layer, uint32_t serial, uint32_t w, uint32_t h)
{
	struct app *a = data;
	zwlr_layer_surface_v1_ack_configure(layer, serial);
	if (!a->have_buffers) {
		a->w = (int)w;
		a->h = (int)h;
		if (create_buffers(a) < 0) {
			fprintf(stderr, "lilith-select: could not create the shared-memory buffers\n");
			a->done = a->cancelled = 1;
			return;
		}
		a->sel.x = a->w / 2;
		a->sel.y = a->h / 2;
	}
	redraw(a);
}
static void layer_closed(void *data, struct zwlr_layer_surface_v1 *layer)
{
	struct app *a = data;
	(void)layer;
	a->done = a->cancelled = 1;
}
static const struct zwlr_layer_surface_v1_listener layer_listener = { .configure = layer_configure, .closed = layer_closed };

/* ---------------------------------------------------------------- pointer */
static void pointer_enter(void *data, struct wl_pointer *p, uint32_t serial, struct wl_surface *s, wl_fixed_t x, wl_fixed_t y)
{
	struct app *a = data;
	(void)s;
	wl_pointer_set_cursor(p, serial, NULL, 0, 0);   /* hide the system cursor: the cross is ours */
	a->sel.x = wl_fixed_to_int(x);
	a->sel.y = wl_fixed_to_int(y);
	redraw(a);
}
static void pointer_leave(void *data, struct wl_pointer *p, uint32_t serial, struct wl_surface *s)
{
	(void)data; (void)p; (void)serial; (void)s;
}
static void pointer_motion(void *data, struct wl_pointer *p, uint32_t time, wl_fixed_t x, wl_fixed_t y)
{
	struct app *a = data;
	(void)p; (void)time;
	a->sel.x = wl_fixed_to_int(x);
	a->sel.y = wl_fixed_to_int(y);
	redraw(a);
}
static void pointer_button(void *data, struct wl_pointer *p, uint32_t serial, uint32_t time, uint32_t button, uint32_t state)
{
	struct app *a = data;
	(void)p; (void)serial; (void)time;
	if (button == BTN_RIGHT && state == WL_POINTER_BUTTON_STATE_PRESSED) {
		a->done = a->cancelled = 1;
	} else if (button == BTN_LEFT && state == WL_POINTER_BUTTON_STATE_PRESSED) {
		a->sel.sx = a->sel.x;
		a->sel.sy = a->sel.y;
		a->sel.dragging = 1;
		redraw(a);
	} else if (button == BTN_LEFT && state == WL_POINTER_BUTTON_STATE_RELEASED && a->sel.dragging) {
		a->done = 1;
	}
}
static void pointer_axis(void *d, struct wl_pointer *p, uint32_t t, uint32_t axis, wl_fixed_t v) { (void)d; (void)p; (void)t; (void)axis; (void)v; }
static void pointer_frame(void *d, struct wl_pointer *p) { (void)d; (void)p; }
static void pointer_axis_source(void *d, struct wl_pointer *p, uint32_t s) { (void)d; (void)p; (void)s; }
static void pointer_axis_stop(void *d, struct wl_pointer *p, uint32_t t, uint32_t axis) { (void)d; (void)p; (void)t; (void)axis; }
static void pointer_axis_discrete(void *d, struct wl_pointer *p, uint32_t axis, int32_t n) { (void)d; (void)p; (void)axis; (void)n; }
static const struct wl_pointer_listener pointer_listener = {
	.enter = pointer_enter, .leave = pointer_leave, .motion = pointer_motion, .button = pointer_button,
	.axis = pointer_axis, .frame = pointer_frame, .axis_source = pointer_axis_source,
	.axis_stop = pointer_axis_stop, .axis_discrete = pointer_axis_discrete,
};

/* ---------------------------------------------------------------- keyboard (only Esc matters) */
static void kb_keymap(void *d, struct wl_keyboard *k, uint32_t format, int32_t fd, uint32_t size)
{
	(void)d; (void)k; (void)format; (void)size;
	close(fd);                                       /* we read raw key codes, not the keymap */
}
static void kb_enter(void *d, struct wl_keyboard *k, uint32_t serial, struct wl_surface *s, struct wl_array *keys) { (void)d; (void)k; (void)serial; (void)s; (void)keys; }
static void kb_leave(void *d, struct wl_keyboard *k, uint32_t serial, struct wl_surface *s) { (void)d; (void)k; (void)serial; (void)s; }
static void kb_key(void *data, struct wl_keyboard *k, uint32_t serial, uint32_t time, uint32_t key, uint32_t state)
{
	struct app *a = data;
	(void)k; (void)serial; (void)time;
	if (key == KEY_ESC && state == WL_KEYBOARD_KEY_STATE_PRESSED)
		a->done = a->cancelled = 1;
}
static void kb_modifiers(void *d, struct wl_keyboard *k, uint32_t serial, uint32_t dep, uint32_t lat, uint32_t lock, uint32_t group) { (void)d; (void)k; (void)serial; (void)dep; (void)lat; (void)lock; (void)group; }
static void kb_repeat_info(void *d, struct wl_keyboard *k, int32_t rate, int32_t delay) { (void)d; (void)k; (void)rate; (void)delay; }
static const struct wl_keyboard_listener keyboard_listener = {
	.keymap = kb_keymap, .enter = kb_enter, .leave = kb_leave, .key = kb_key,
	.modifiers = kb_modifiers, .repeat_info = kb_repeat_info,
};

/* ---------------------------------------------------------------- seat and registry */
static void seat_capabilities(void *data, struct wl_seat *seat, uint32_t caps)
{
	struct app *a = data;
	if ((caps & WL_SEAT_CAPABILITY_POINTER) && !a->pointer) {
		a->pointer = wl_seat_get_pointer(seat);
		wl_pointer_add_listener(a->pointer, &pointer_listener, a);
	}
	if ((caps & WL_SEAT_CAPABILITY_KEYBOARD) && !a->keyboard) {
		a->keyboard = wl_seat_get_keyboard(seat);
		wl_keyboard_add_listener(a->keyboard, &keyboard_listener, a);
	}
}
static void seat_name(void *d, struct wl_seat *s, const char *name) { (void)d; (void)s; (void)name; }
static const struct wl_seat_listener seat_listener = { .capabilities = seat_capabilities, .name = seat_name };

static void registry_global(void *data, struct wl_registry *reg, uint32_t name, const char *iface, uint32_t version)
{
	struct app *a = data;
	if (!strcmp(iface, wl_compositor_interface.name))
		a->compositor = wl_registry_bind(reg, name, &wl_compositor_interface, version < 4 ? version : 4);
	else if (!strcmp(iface, wl_shm_interface.name))
		a->shm = wl_registry_bind(reg, name, &wl_shm_interface, 1);
	else if (!strcmp(iface, wl_seat_interface.name)) {
		a->seat = wl_registry_bind(reg, name, &wl_seat_interface, version < 5 ? version : 5);
		wl_seat_add_listener(a->seat, &seat_listener, a);
	} else if (!strcmp(iface, zwlr_layer_shell_v1_interface.name))
		a->layer_shell = wl_registry_bind(reg, name, &zwlr_layer_shell_v1_interface, 1);
}
static void registry_remove(void *d, struct wl_registry *r, uint32_t name) { (void)d; (void)r; (void)name; }
static const struct wl_registry_listener registry_listener = { .global = registry_global, .global_remove = registry_remove };

/* ---------------------------------------------------------------- main */
int main(int argc, char **argv)
{
	struct app a;
	unsigned rgb = 0xffffff;
	int opt_i;

	memset(&a, 0, sizeof a);
	a.style.dim = 0.45;
	for (opt_i = 1; opt_i + 1 < argc; opt_i += 2) {
		if (!strcmp(argv[opt_i], "-c"))
			rgb = (unsigned)strtoul(argv[opt_i + 1], NULL, 16);
		else if (!strcmp(argv[opt_i], "-d"))
			a.style.dim = atof(argv[opt_i + 1]);
		else {
			fprintf(stderr, "usage: lilith-select [-c RRGGBB] [-d dim]\n");
			return 2;
		}
	}
	a.style.r = ((rgb >> 16) & 255) / 255.0;
	a.style.g = ((rgb >> 8) & 255) / 255.0;
	a.style.b = (rgb & 255) / 255.0;

	a.display = wl_display_connect(NULL);
	if (!a.display) {
		fprintf(stderr, "lilith-select: cannot connect to the Wayland display\n");
		return 2;
	}
	a.registry = wl_display_get_registry(a.display);
	wl_registry_add_listener(a.registry, &registry_listener, &a);
	wl_display_roundtrip(a.display);
	wl_display_roundtrip(a.display);          /* the seat's capabilities arrive in the second round */
	if (!a.compositor || !a.shm || !a.seat || !a.layer_shell) {
		fprintf(stderr, "lilith-select: the compositor lacks wl_compositor, wl_shm, wl_seat or wlr-layer-shell\n");
		return 2;
	}

	a.surface = wl_compositor_create_surface(a.compositor);
	a.layer = zwlr_layer_shell_v1_get_layer_surface(a.layer_shell, a.surface, NULL, ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY, "lilith-select");
	zwlr_layer_surface_v1_set_anchor(a.layer, ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP | ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM |
	                                          ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT | ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT);
	zwlr_layer_surface_v1_set_exclusive_zone(a.layer, -1);
	zwlr_layer_surface_v1_set_keyboard_interactivity(a.layer, ZWLR_LAYER_SURFACE_V1_KEYBOARD_INTERACTIVITY_EXCLUSIVE);
	zwlr_layer_surface_v1_add_listener(a.layer, &layer_listener, &a);
	wl_surface_commit(a.surface);

	while (!a.done && wl_display_dispatch(a.display) != -1)
		;

	if (!a.cancelled) {
		int x = a.sel.sx < a.sel.x ? a.sel.sx : a.sel.x;
		int y = a.sel.sy < a.sel.y ? a.sel.sy : a.sel.y;
		int w = a.sel.sx < a.sel.x ? a.sel.x - a.sel.sx : a.sel.sx - a.sel.x;
		int h = a.sel.sy < a.sel.y ? a.sel.y - a.sel.sy : a.sel.sy - a.sel.y;
		if (w >= 2 && h >= 2) {
			printf("%d,%d %dx%d\n", x, y, w, h);
			fflush(stdout);
			return 0;
		}
	}
	return 1;
}
