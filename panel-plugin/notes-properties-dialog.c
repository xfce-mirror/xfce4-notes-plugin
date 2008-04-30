/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2008  Mike Massonnet <mmassonnet@gmail.com>
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
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <xfconf/xfconf.h>

#include "defines.h"
#include "notes-properties-dialog.h"
#include "notes.h"



static XfconfChannel *channel_panel_plugin = NULL;
static XfconfChannel *channel_new_window = NULL;

static void
cb_channel_panel_plugin_toggled (GtkToggleButton *button,
                                 const gchar *property)
{
  xfconf_channel_set_bool (channel_panel_plugin, property, gtk_toggle_button_get_active (button));
}

static void
cb_channel_new_window_toggled (GtkToggleButton *button,
                               const gchar *property)
{
  xfconf_channel_set_bool (channel_new_window, property, gtk_toggle_button_get_active (button));
}

static void
cb_channel_new_window_fontset (GtkFontButton *fontbutton,
                               const gchar *property)
{
  xfconf_channel_set_string (channel_new_window, property, gtk_font_button_get_font_name (fontbutton));
}

static void
cb_channel_new_window_scale (GtkRange *range,
                             const gchar *property)
{
  xfconf_channel_set_int (channel_new_window, property, (gint32)gtk_range_get_value (range));
}

GtkWidget *
prop_dialog_new (NotesPlugin *notes_plugin)
{
  GtkWidget *dialog, *frame, *box, *hbox, *button, *scale, *label;
  GtkWidget *fontbutton, *size_box;

  /* Configuration channel */
  if (NULL == channel_panel_plugin && NULL == channel_new_window)
    {
      channel_panel_plugin = notes_plugin->channel_panel_plugin;
      channel_new_window = notes_plugin->channel_new_window;
    }

  /* Dialog */
  dialog =
    xfce_titled_dialog_new_with_buttons (_("Xfce 4 Notes Plugin"),
                                         GTK_WINDOW (gtk_widget_get_toplevel (GTK_WIDGET (notes_plugin->panel_plugin))),
                                         GTK_DIALOG_DESTROY_WITH_PARENT|GTK_DIALOG_NO_SEPARATOR,
                                         GTK_STOCK_HELP, GTK_RESPONSE_HELP,
                                         GTK_STOCK_CLOSE, GTK_RESPONSE_OK,
                                         NULL);
  gtk_window_set_icon_name (GTK_WINDOW (dialog), "xfce4-notes-plugin");
  gtk_window_set_keep_above (GTK_WINDOW (dialog), TRUE);
  gtk_window_set_position (GTK_WINDOW (dialog), GTK_WIN_POS_CENTER);
  gtk_window_set_default_size (GTK_WINDOW (dialog), 375, -1);
  gtk_window_stick (GTK_WINDOW (dialog));

  /* === Default settings === */
  box = gtk_vbox_new (TRUE, BORDER);
  frame = xfce_create_framebox_with_content (_("Default settings"), box);
  gtk_container_set_border_width (GTK_CONTAINER (frame), BORDER);
  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox), frame);

  /* Hide from taskbar */
  button = gtk_check_button_new_with_label (_("Hide windows from taskbar"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button),
                                xfconf_channel_get_bool (channel_panel_plugin, "/hide_windows_from_taskbar", FALSE));
  gtk_container_add (GTK_CONTAINER (box), button);
  g_signal_connect (button, "toggled", G_CALLBACK (cb_channel_panel_plugin_toggled), "/hide_windows_from_taskbar");

  /* Hide arrow button */
  button = gtk_check_button_new_with_label (_("Hide arrow button"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button),
                                xfconf_channel_get_bool (channel_panel_plugin, "/hide_arrow_button", FALSE));
  gtk_container_add (GTK_CONTAINER (box), button);
  g_signal_connect (button, "toggled", G_CALLBACK (cb_channel_panel_plugin_toggled), "/hide_arrow_button");

  /* === New window settings === */
  box = gtk_vbox_new (TRUE, BORDER);
  frame = xfce_create_framebox_with_content (_("New window settings"), box);
  gtk_container_set_border_width (GTK_CONTAINER (frame), BORDER);
  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox), frame);

  /* Always on top */
  button = gtk_check_button_new_with_label (_("Always on top"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button),
                                xfconf_channel_get_bool (channel_new_window, "/window_state/always_on_top", FALSE));
  gtk_box_pack_start (GTK_BOX (box), button, TRUE, FALSE, 0);
  g_signal_connect (button, "toggled", G_CALLBACK (cb_channel_new_window_toggled), "/window_state/always_on_top");

  /* Sticky window */
  button = gtk_check_button_new_with_label (_("Sticky window"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button),
                                xfconf_channel_get_bool (channel_new_window, "/window_state/sticky", TRUE));
  gtk_box_pack_start (GTK_BOX (box), button, TRUE, FALSE, 0);
  g_signal_connect (button, "toggled", G_CALLBACK (cb_channel_new_window_toggled), "/window_state/sticky");

  /* Resize grip */
  button = gtk_check_button_new_with_label (_("Resize grip"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button),
                                xfconf_channel_get_bool (channel_new_window, "/window_state/resize_grip", FALSE));
  gtk_box_pack_start (GTK_BOX (box), button, TRUE, FALSE, 0);
  g_signal_connect (button, "toggled", G_CALLBACK (cb_channel_new_window_toggled), "/window_state/resize_grip");

  /* Font */
  hbox = gtk_hbox_new (FALSE, BORDER);
  gtk_box_pack_start (GTK_BOX (box), hbox, TRUE, FALSE, 0);

  button = gtk_check_button_new_with_label (_("Font"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button),
                                xfconf_channel_get_bool (channel_new_window, "/window_state/use_font", FALSE));
  gtk_box_pack_start (GTK_BOX (hbox), button, FALSE, FALSE, 0);
  g_signal_connect (button, "toggled", G_CALLBACK (cb_channel_new_window_toggled), "/window_state/use_font");

  gchar *description = xfconf_channel_get_string (channel_new_window, "/font/description", "Sans 10");
  fontbutton = gtk_font_button_new_with_font (description);
  g_free (description);
  gtk_box_pack_start (GTK_BOX (hbox), fontbutton, TRUE, TRUE, 0);
  g_signal_connect (fontbutton, "font-set", G_CALLBACK (cb_channel_new_window_fontset), "/font/description");

  /* Size */
  hbox = gtk_hbox_new (FALSE, BORDER);
  gtk_box_pack_start (GTK_BOX (box), hbox, TRUE, FALSE, 0);

  label = gtk_label_new (_("Size"));
  gtk_box_pack_start (GTK_BOX (hbox), label, FALSE, FALSE, 0);

  size_box = gtk_hbox_new (FALSE, 0);
  gtk_box_pack_start (GTK_BOX (hbox), size_box, TRUE, TRUE, 0);

  scale = gtk_hscale_new_with_range (20, 600, 10);
  gtk_range_set_value (GTK_RANGE (scale),
                       (gdouble)xfconf_channel_get_int (channel_new_window, "/geometry/width", 375));
  gtk_scale_set_value_pos (GTK_SCALE (scale), GTK_POS_RIGHT);
  gtk_box_pack_start (GTK_BOX (size_box), scale, TRUE, TRUE, 0);
  g_signal_connect (scale, "value-changed", G_CALLBACK (cb_channel_new_window_scale), "/geometry/width");

  label = gtk_label_new ("×");
  gtk_box_pack_start (GTK_BOX (size_box), label, FALSE, FALSE, 0);

  scale = gtk_hscale_new_with_range (20, 600, 10);
  gtk_range_set_value (GTK_RANGE (scale),
                       (gdouble)xfconf_channel_get_int (channel_new_window, "/geometry/height", 430));
  gtk_scale_set_value_pos (GTK_SCALE (scale), GTK_POS_LEFT);
  gtk_box_pack_start (GTK_BOX (size_box), scale, TRUE, TRUE, 0);
  g_signal_connect (scale, "value-changed", G_CALLBACK (cb_channel_new_window_scale), "/geometry/height");

  /* === Ending === */
  gtk_widget_show_all (GTK_DIALOG (dialog)->vbox);

  return dialog;
}

