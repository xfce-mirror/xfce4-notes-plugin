/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (c) 2006-2013  Mike Massonnet <mmassonnet@xfce.org>
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

#ifdef HAVE_STRING_H
#include <string.h>
#endif

#include <glib.h>
#include <gdk/gdk.h>

#include "ext-gdk.h"



#define RC_STYLE \
  "gtk_color_scheme = \"notes_fg_color:#xxxxxxxxxxxx\\nnotes_bg_color:#xxxxxxxxxxxx\\n" \
  "notes_base_color:#xxxxxxxxxxxx\\nnotes_text_color:#xxxxxxxxxxxx\\n" \
  "notes_selected_bg_color:#xxxxxxxxxxxx\\nnotes_selected_fg_color:#xxxxxxxxxxxx\"\n" \
  "include \"" PKGDATADIR "/gtk-2.0/notes.gtkrc\""



void
update_gtkrc (const GdkColor *color)
{
  GdkColor *color2;
  gchar *notesrc_file;
  gchar *bg;
  gchar *text;
  gchar *selected;
  gchar rc_style[] = RC_STYLE;
  gchar *offset;

  /* bg */
  bg = gdk_color_to_string (color);

  /* text */
  color2 = gdk_color_copy (color);
  __gdk_color_contrast (color2, 5.);
  text = gdk_color_to_string (color2);
  gdk_color_free (color2);

  /* selected */
  color2 = gdk_color_copy (color);
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

  g_free (notesrc_file);
  g_free (bg);
  g_free (text);
  g_free (selected);
}

