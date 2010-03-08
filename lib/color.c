/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2009  Mike Massonnet <mmassonnet@xfce.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#ifdef HAVE_MATH_H
#include <math.h>
#endif

#ifdef HAVE_STRING_H
#include <string.h>
#endif

#include <glib.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>

#include "color.h"

#define RC_STYLE \
  "gtk_color_scheme = \"notes_fg_color:#xxxxxxxxxxxx\\nnotes_bg_color:#xxxxxxxxxxxx\\nnotes_base_color:#xxxxxxxxxxxx\\nnotes_text_color:#xxxxxxxxxxxx\\nnotes_selected_bg_color:#xxxxxxxxxxxx\\nnotes_selected_fg_color:#xxxxxxxxxxxx\"\n" \
  "include \"" PKGDATADIR "/gtk-2.0/notes.gtkrc\""

void
color_set_background (const gchar *background)
{
  GdkColor color, *color2;
  gchar *notesrc_file;
  gchar *bg;
  gchar *text;
  gchar *selected;
  gchar rc_style[] = RC_STYLE;
  gchar *offset;

  if (!gdk_color_parse (background, &color))
    return;

  /* bg */
  bg = gdk_color_to_string (&color);

  /* text */
  color2 = gdk_color_copy (&color);
  __gdk_color_contrast (color2, 5.);
  text = gdk_color_to_string (color2);
  gdk_color_free (color2);

  /* selected */
  color2 = gdk_color_copy (&color);
  __gdk_color_contrast (color2, 3.2);
  selected = gdk_color_to_string (color2);
  gdk_color_free (color2);

  /* notes_fg_color */
  offset = rc_style + 35;
  memcpy (offset, bg, 13);

  /* notes_bg_color */
  offset += 30;
  memcpy (offset, text, 13);

  /* notes_base_color */
  offset += 32;
  memcpy (offset, bg, 13);

  /* notes_text_color */
  offset += 32;
  memcpy (offset, text, 13);

  /* notes_selected_bg_color */
  offset += 39;
  memcpy (offset, selected, 13);

  /* notes_selected_fg_color */
  offset += 39;
  memcpy (offset, bg, 13);

  /* set the rc style */
  notesrc_file = g_strdup_printf ("%s/xfce4/xfce4-notes.gtkrc", g_get_user_config_dir ());
  g_file_set_contents (notesrc_file, rc_style, -1, NULL);

  gtk_rc_reparse_all ();

  g_free (notesrc_file);
  g_free (bg);
  g_free (text);
  g_free (selected);
}

void
__gdk_color_contrast (GdkColor *color,
                      gdouble contrast)
{
  /* cf. http://accessibility.kde.org/hsl-adjusted.php */
  gdouble N_r, N_g, N_b;
  gdouble f_r = 0.2125, f_g = 0.7154, f_b = 0.0721;
  gdouble L, L_, m, D, D_;
  gdouble N__1, N_0, N_1;
  gdouble N_r_, N_g_, N_b_;

  g_return_if_fail (G_LIKELY (contrast >= 1 && contrast <= 21));

  /* Calculate luminosity */
  N_r = pow ((gdouble)color->red / G_MAXUINT16, 2.2);
  N_g = pow ((gdouble)color->green / G_MAXUINT16, 2.2);
  N_b = pow ((gdouble)color->blue / G_MAXUINT16, 2.2);

  L = f_r * N_r + f_g * N_g + f_b * N_b;

  /* Change luminosity */
  L_ = (L + 0.05) / contrast - 0.05;

  N__1 = MIN (N_r, MIN (N_g, N_b));
  N_1 = MAX (N_r, MAX (N_g, N_b));
  if (N_r > N__1 && N_r < N_1)
    N_0 = N_r;
  else if (N_g > N__1 && N_g < N_1)
    N_0 = N_g;
  else if (N_b > N__1 && N_b < N_1)
    N_0 = N_b;
  else
    N_0 = N_1;

  m = f_g + f_r * (N_0 - N__1) / (N_1 - N__1);
  D = MIN (L / m, (1 - L) / (1 - m));
  D_ = MIN (L_ / m, (1 - L_) / (1 - m));

  N_r_ = L_ + (N_r - L) * D_ / D;
  N_g_ = L_ + (N_g - L) * D_ / D;
  N_b_ = L_ + (N_b - L) * D_ / D;

  /* Conversion to RGB */
  color->red   = G_MAXUINT16 * pow (N_r_, 1 / 2.2);
  color->green = G_MAXUINT16 * pow (N_g_, 1 / 2.2);
  color->blue  = G_MAXUINT16 * pow (N_b_, 1 / 2.2);
}

#if !GTK_CHECK_VERSION (2,12,0)
gchar *
gdk_color_to_string (const GdkColor *color)
{
  g_return_val_if_fail (color != NULL, NULL);

  return g_strdup_printf ("#%04x%04x%04x", color->red, color->green, color->blue);
}
#endif

#if !GTK_CHECK_VERSION (2,14,0)
GtkWidget*
gtk_color_selection_dialog_get_color_selection (GtkColorSelectionDialog *colorsel)
{
  g_return_val_if_fail (GTK_IS_COLOR_SELECTION_DIALOG (colorsel), NULL);

  return colorsel->colorsel;
}
#endif

