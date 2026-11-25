/* ======================================================================
 *  draw.c — lilith-select: the dimmed screen, the cross cursor, the lines, the selection box
 * ----------------------------------------------------------------------
 *  Copies only these four things from Ryoku's screenshot tool: dimming, a small cross
 *  cursor, a vertical and a horizontal line spanning the screen from it (with a small gap
 *  around the cross), and the selection box. Everything is the accent colour. The selection
 *  itself is not dimmed.
 * ====================================================================== */
#include "draw.h"

#define CROSS_ARM 10     /* the small cross: this many pixels each way */
#define CROSS_WIDTH 3     /* odd, so the cross is centred on the 1 px lines */
#define GAP 7            /* clear space between the cross and the start of the long lines */
#define LINE_WIDTH 1
#define BOX_WIDTH 2

static void normalise(const struct sel_state *s, int *x, int *y, int *w, int *h)
{
	*x = s->sx < s->x ? s->sx : s->x;
	*y = s->sy < s->y ? s->sy : s->y;
	*w = (s->sx < s->x ? s->x - s->sx : s->sx - s->x);
	*h = (s->sy < s->y ? s->y - s->sy : s->sy - s->y);
}

void select_draw(cairo_t *cr, int w, int h, const struct sel_state *s, const struct sel_style *st)
{
	int bx = 0, by = 0, bw = 0, bh = 0;

	/* 1. dim everything */
	cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
	cairo_set_source_rgba(cr, 0, 0, 0, st->dim);
	cairo_paint(cr);

	/* 2. the selected area is left undimmed */
	if (s->dragging) {
		normalise(s, &bx, &by, &bw, &bh);
		cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
		cairo_rectangle(cr, bx, by, bw, bh);
		cairo_fill(cr);
	}

	cairo_set_operator(cr, CAIRO_OPERATOR_OVER);
	cairo_set_source_rgba(cr, st->r, st->g, st->b, 1.0);
	cairo_set_antialias(cr, CAIRO_ANTIALIAS_NONE);   /* crisp one-pixel lines */

	/* 3. the long lines: they start a little away from the cross, so the cross stays distinct */
	cairo_set_line_width(cr, LINE_WIDTH);
	cairo_move_to(cr, 0, s->y + 0.5);
	cairo_line_to(cr, s->x - CROSS_ARM - GAP, s->y + 0.5);
	cairo_move_to(cr, s->x + CROSS_ARM + GAP + 1, s->y + 0.5);
	cairo_line_to(cr, w, s->y + 0.5);
	cairo_move_to(cr, s->x + 0.5, 0);
	cairo_line_to(cr, s->x + 0.5, s->y - CROSS_ARM - GAP);
	cairo_move_to(cr, s->x + 0.5, s->y + CROSS_ARM + GAP + 1);
	cairo_line_to(cr, s->x + 0.5, h);
	cairo_stroke(cr);

	/* 4. the selection box (an outline, drawn inside the area) */
	if (s->dragging && bw > 1 && bh > 1) {
		cairo_set_line_width(cr, BOX_WIDTH);
		cairo_rectangle(cr, bx + BOX_WIDTH / 2.0, by + BOX_WIDTH / 2.0, bw - BOX_WIDTH, bh - BOX_WIDTH);
		cairo_stroke(cr);
	}

	/* 5. the small cross cursor, on top */
	cairo_set_line_width(cr, CROSS_WIDTH);
	cairo_move_to(cr, s->x - CROSS_ARM, s->y + 0.5);
	cairo_line_to(cr, s->x + CROSS_ARM + 1, s->y + 0.5);
	cairo_move_to(cr, s->x + 0.5, s->y - CROSS_ARM);
	cairo_line_to(cr, s->x + 0.5, s->y + CROSS_ARM + 1);
	cairo_stroke(cr);
}
