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
  "style \"notes-default\" {\n" \
  "xthickness = 2\n" \
  "ythickness = 2\n" \
  "fg[NORMAL] = @notes_fg_color\n" \
  "fg[ACTIVE] = @notes_fg_color\n" \
  "fg[PRELIGHT] = @notes_fg_color\n" \
  "fg[SELECTED] = @notes_selected_fg_color\n" \
  "fg[INSENSITIVE] = shade(3.0,@notes_fg_color)\n" \
  "bg[NORMAL] = @notes_bg_color\n" \
  "bg[ACTIVE] = shade(1.0233,@notes_bg_color)\n" \
  "bg[PRELIGHT] = mix(0.90,shade(1.1,@notes_bg_color),@notes_selected_bg_color)\n" \
  "bg[SELECTED] = @notes_selected_bg_color\n" \
  "bg[INSENSITIVE] = shade(1.03,@notes_bg_color)\n" \
  "base[NORMAL] = @notes_base_color\n" \
  "base[ACTIVE] = shade(0.65,@notes_base_color)\n" \
  "base[PRELIGHT] = @notes_base_color\n" \
  "base[SELECTED] = @notes_selected_bg_color\n" \
  "base[INSENSITIVE] = shade(1.025,@notes_bg_color)\n" \
  "text[NORMAL] = @notes_text_color\n" \
  "text[ACTIVE] = shade(0.95,@notes_base_color)\n" \
  "text[PRELIGHT] = @notes_text_color\n" \
  "text[SELECTED] = @notes_selected_fg_color\n" \
  "text[INSENSITIVE] = mix(0.675,shade(0.95,@notes_bg_color),@notes_fg_color)\n" \
  "}\n" \
  "widget \"xfce4-notes-plugin*\" style \"notes-default\"\n"

#define INCLUDE_CONTENT \
  "\n\n# include rc style for the xfce4-notes-plugin" \
  "\n\n%s" \
  "\n\n# end of automatic change\n\n"

static inline void
update_gtkrc (const gchar *notesrc_file)
{
  gchar *gtkrc_file;
  gchar *include_line;
  gchar *include_content;
  gchar *contents, *tmp;

  gtkrc_file = g_strdup_printf ("%s/.gtkrc-2.0", g_get_home_dir ());
  include_line = g_strdup_printf ("include \"%s\"", notesrc_file);
  include_content = g_strdup_printf (INCLUDE_CONTENT, include_line);

  g_file_get_contents (gtkrc_file, &contents, NULL, NULL);

  if (contents == NULL)
    {
      g_file_set_contents (gtkrc_file, include_content, -1, NULL);
    }
  else if (!g_strrstr (contents, include_line))
    {
      tmp = contents;
      contents = g_strconcat (tmp, include_content, NULL);
      g_free (tmp);

      g_file_set_contents (gtkrc_file, contents, -1, NULL);
    }

  g_free (include_content);
  g_free (include_line);
  g_free (gtkrc_file);
  g_free (contents);
}

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
  notesrc_file = g_strdup_printf ("%s/xfce4/panel/xfce4-notes-plugin.gtkrc", g_get_user_config_dir ());
  g_file_set_contents (notesrc_file, rc_style, -1, NULL);
  update_gtkrc (notesrc_file);

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

#if GTK_CHECK_VERSION (2,12,0)
gchar *
gdk_color_to_string (const GdkColor *color)
{
  g_return_val_if_fail (color != NULL, NULL);

  return g_strdup_printf ("#%04x%04x%04x", color->red, color->green, color->blue);
}
#endif

