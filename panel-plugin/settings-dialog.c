/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2008-2009  Mike Massonnet <mmassonnet@gmail.com>
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

#ifdef HAVE_XFCONF
#include <xfconf/xfconf.h>

#include "defines.h"
#include "settings-dialog.h"
#include "notes.h"



static void cb_size_changed (GtkComboBox *button,
                             gpointer data);

static XfconfChannel *xfconf_channel = NULL;

GtkWidget *
prop_dialog_new (NotesPlugin *notes_plugin)
{
  GtkWidget *dialog, *frame, *box, *hbox, *button, *label;
  gint size;

  /* Configuration channel */
  if (NULL == xfconf_channel)
    xfconf_channel = notes_plugin->xfconf_channel;

#if 0
  /* Set unset xfconf values */
  if (!xfconf_channel_has_property (xfconf_channel, "/new_window/transparency"))
    xfconf_channel_set_int (xfconf_channel,
                            "/new_window/transparency",
                            NEW_WINDOW_TRANSPARENCY);
#endif

  /* Dialog */
  dialog =
    xfce_titled_dialog_new_with_buttons (_("Notes"),
                                         GTK_WINDOW (gtk_widget_get_toplevel (GTK_WIDGET (notes_plugin->panel_plugin))),
                                         GTK_DIALOG_DESTROY_WITH_PARENT|GTK_DIALOG_NO_SEPARATOR,
                                         GTK_STOCK_HELP, GTK_RESPONSE_HELP,
                                         GTK_STOCK_CLOSE, GTK_RESPONSE_OK,
                                         NULL);
  xfce_titled_dialog_set_subtitle (XFCE_TITLED_DIALOG (dialog), _("Configure the plugin"));
  gtk_window_set_icon_name (GTK_WINDOW (dialog), "xfce4-notes-plugin");
  gtk_window_set_keep_above (GTK_WINDOW (dialog), TRUE);
  gtk_window_set_position (GTK_WINDOW (dialog), GTK_WIN_POS_CENTER);
  gtk_window_stick (GTK_WINDOW (dialog));

  /* === Default settings === */
  box = gtk_vbox_new (TRUE, BORDER);
  frame = xfce_create_framebox_with_content (_("Default settings"), box);
  gtk_container_set_border_width (GTK_CONTAINER (frame), BORDER);
  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox), frame);

  /* Hide from taskbar */
  button = gtk_check_button_new_with_label (_("Hide windows from taskbar"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button), GENERAL_HIDE_FROM_TASKBAR);
  xfconf_g_property_bind (xfconf_channel, "/general/hide_windows_from_taskbar",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_container_add (GTK_CONTAINER (box), button);

  /* Hide arrow button */
  button = gtk_check_button_new_with_label (_("Hide arrow button"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button), GENERAL_HIDE_ARROW_BUTTON);
  xfconf_g_property_bind (xfconf_channel, "/general/hide_arrow_button",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_container_add (GTK_CONTAINER (box), button);

  /* === New window settings === */
  box = gtk_vbox_new (TRUE, BORDER);
  frame = xfce_create_framebox_with_content (_("New window settings"), box);
  gtk_container_set_border_width (GTK_CONTAINER (frame), BORDER);
  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox), frame);

  /* Always on top */
  button = gtk_check_button_new_with_label (_("Always on top"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button), NEW_WINDOW_ABOVE);
  xfconf_g_property_bind (xfconf_channel, "/new_window/always_on_top",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_box_pack_start (GTK_BOX (box), button, TRUE, FALSE, 0);

  /* Sticky window */
  button = gtk_check_button_new_with_label (_("Sticky window"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button), NEW_WINDOW_STICKY);
  xfconf_g_property_bind (xfconf_channel, "/new_window/sticky",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_box_pack_start (GTK_BOX (box), button, TRUE, FALSE, 0);

  /* Tabs */
  button = gtk_check_button_new_with_label (_("Show tabs"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button), NEW_WINDOW_TABS);
  xfconf_g_property_bind (xfconf_channel, "/new_window/show_tabs",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_box_pack_start (GTK_BOX (box), button, TRUE, FALSE, 0);

  /* Font */
  hbox = gtk_hbox_new (FALSE, BORDER);
  gtk_box_pack_start (GTK_BOX (box), hbox, TRUE, FALSE, 0);

  button = gtk_check_button_new_with_label (_("Font:"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button), NEW_WINDOW_USE_FONT);
  xfconf_g_property_bind (xfconf_channel, "/new_window/use_font",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_box_pack_start (GTK_BOX (hbox), button, FALSE, FALSE, 0);

  button = gtk_font_button_new_with_font (NEW_WINDOW_FONT_DESCR);
  xfconf_g_property_bind (xfconf_channel, "/new_window/font_description",
                          G_TYPE_STRING, G_OBJECT (button), "font-name");
  gtk_box_pack_start (GTK_BOX (hbox), button, TRUE, TRUE, 0);

  /* Size */
  hbox = gtk_hbox_new (FALSE, BORDER);
  gtk_box_pack_start (GTK_BOX (box), hbox, TRUE, FALSE, 0);

  label = gtk_label_new (_("Size:"));
  gtk_box_pack_start (GTK_BOX (hbox), label, FALSE, FALSE, 0);

  button = gtk_combo_box_new_text ();
  gtk_combo_box_append_text (GTK_COMBO_BOX (button), _("Small"));
  gtk_combo_box_append_text (GTK_COMBO_BOX (button), _("Normal"));
  gtk_combo_box_append_text (GTK_COMBO_BOX (button), _("Large"));
  size = xfconf_channel_get_int (xfconf_channel, "/new_window/width", SIZE_NORMAL);
  if (size == SIZE_SMALL)
    gtk_combo_box_set_active (GTK_COMBO_BOX (button), 0);
  else if (size == SIZE_NORMAL)
    gtk_combo_box_set_active (GTK_COMBO_BOX (button), 1);
  else if (size == SIZE_LARGE)
    gtk_combo_box_set_active (GTK_COMBO_BOX (button), 2);
  g_signal_connect (button, "changed", G_CALLBACK (cb_size_changed), NULL);
  gtk_box_pack_start (GTK_BOX (hbox), button, TRUE, TRUE, 0);

  /* === Ending === */
  gtk_widget_show_all (GTK_DIALOG (dialog)->vbox);

  return dialog;
}

static void
cb_size_changed (GtkComboBox *button,
                 gpointer data)
{
  gint id;
  gint width, height;

  id = gtk_combo_box_get_active (button);

  if (id < 0)
    {
      g_critical ("Trying to set a default size but got an active item < 0");
      return;
    }

  if (id == 0)
    {
      width = SIZE_SMALL;
      height = (gint)SIZE_SMALL*SIZE_FACTOR;
    }
  else if (id == 1)
    {
      width = SIZE_NORMAL;
      height = (gint)SIZE_NORMAL*SIZE_FACTOR;
    }
  else if (id == 2)
    {
      width = SIZE_LARGE;
      height = (gint)SIZE_LARGE*SIZE_FACTOR;
    }

  xfconf_channel_set_int (xfconf_channel, "/new_window/width", width);
  xfconf_channel_set_int (xfconf_channel, "/new_window/height", height);
}
#endif

