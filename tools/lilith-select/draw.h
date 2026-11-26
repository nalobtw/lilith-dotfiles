/* ======================================================================
 *  draw.h — lilith-select: what a frame looks like (pure cairo, no Wayland)
 * ====================================================================== */
#ifndef LILITH_SELECT_DRAW_H
#define LILITH_SELECT_DRAW_H

#include <cairo.h>

struct sel_style {
	double r, g, b;      /* the accent colour: cursor, lines and selection outline */
	double dim;          /* 0..1: how dark the screen is outside the selection */
};

struct sel_state {
	int x, y;            /* pointer position */
	int dragging;        /* 1 while the button is held */
	int sx, sy;          /* where the drag started */
};

/* Draw one frame into cr for a surface of w x h pixels. */
void select_draw(cairo_t *cr, int w, int h, const struct sel_state *s, const struct sel_style *st);

#endif
