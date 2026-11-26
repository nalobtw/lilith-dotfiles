/* ======================================================================
 *  preview.c — lilith-select: render sample frames to PNG, to see the design without Wayland
 *  usage: preview <accent RRGGBB> <out-prefix>   (make preview)
 * ====================================================================== */
#include <stdio.h>
#include <stdlib.h>
#include "draw.h"

static void frame(const char *path, int w, int h, const struct sel_state *s, const struct sel_style *st)
{
	cairo_surface_t *surf = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, w, h);
	cairo_t *cr = cairo_create(surf);
	/* stand-in for the screen behind: a gradient with some "windows" */
	cairo_set_source_rgb(cr, 0.55, 0.62, 0.72); cairo_paint(cr);
	cairo_set_source_rgb(cr, 0.12, 0.13, 0.15); cairo_rectangle(cr, 100, 80, 640, 420); cairo_fill(cr);
	cairo_set_source_rgb(cr, 0.85, 0.80, 0.70); cairo_rectangle(cr, 800, 200, 500, 380); cairo_fill(cr);
	/* the real thing draws over this with its own operators */
	cairo_surface_t *over = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, w, h);
	cairo_t *oc = cairo_create(over);
	select_draw(oc, w, h, s, st);
	cairo_set_source_surface(cr, over, 0, 0);
	cairo_paint(cr);
	cairo_surface_write_to_png(surf, path);
	cairo_destroy(oc); cairo_surface_destroy(over); cairo_destroy(cr); cairo_surface_destroy(surf);
}

int main(int argc, char **argv)
{
	unsigned rgb = argc > 1 ? (unsigned)strtoul(argv[1], NULL, 16) : 0x7fcfc0;
	const char *prefix = argc > 2 ? argv[2] : "frame";
	struct sel_style st = { ((rgb >> 16) & 255) / 255.0, ((rgb >> 8) & 255) / 255.0, (rgb & 255) / 255.0, 0.45 };
	struct sel_state idle = { 700, 420, 0, 0, 0 };
	struct sel_state drag = { 1180, 540, 1, 330, 210 };
	char name[256];
	snprintf(name, sizeof name, "%s-idle.png", prefix); frame(name, 1440, 810, &idle, &st);
	snprintf(name, sizeof name, "%s-drag.png", prefix); frame(name, 1440, 810, &drag, &st);
	return 0;
}
