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



static XfconfChannel *xfconf_channel = NULL;

GtkWidget *
prop_dialog_new (NotesPlugin *notes_plugin)
{
  GtkWidget *dialog, *frame, *box, *hbox, *button, *spin, *label;
  GtkWidget *size_box;

  /* Configuration channel */
  if (NULL == xfconf_channel)
    xfconf_channel = notes_plugin->xfconf_channel;

  /* Set unset xfconf values */
  if (!xfconf_channel_has_property (xfconf_channel, "/general/hide_windows_from_taskbar"))
    xfconf_channel_set_bool (xfconf_channel,
                             "/general/hide_windows_from_taskbar",
                             GENERAL_HIDE_FROM_TASKBAR);
  if (!xfconf_channel_has_property (xfconf_channel, "/general/hide_arrow_button"))
    xfconf_channel_set_bool (xfconf_channel,
                             "/general/hide_arrow_button",
                             GENERAL_HIDE_ARROW_BUTTON);
  if (!xfconf_channel_has_property (xfconf_channel, "/new_window/width"))
    xfconf_channel_set_int (xfconf_channel,
                            "/new_window/width",
                            NEW_WINDOW_WIDTH);
  if (!xfconf_channel_has_property (xfconf_channel, "/new_window/height"))
    xfconf_channel_set_int (xfconf_channel,
                            "/new_window/height",
                            NEW_WINDOW_HEIGHT);
  if (!xfconf_channel_has_property (xfconf_channel, "/new_window/always_on_top"))
    xfconf_channel_set_bool (xfconf_channel,
                             "/new_window/always_on_top",
                             NEW_WINDOW_ABOVE);
  if (!xfconf_channel_has_property (xfconf_channel, "/new_window/sticky"))
    xfconf_channel_set_bool (xfconf_channel,
                             "/new_window/sticky",
                             NEW_WINDOW_STICKY);
  if (!xfconf_channel_has_property (xfconf_channel, "/new_window/show_tabs"))
    xfconf_channel_set_bool (xfconf_channel,
                             "/new_window/show_tabs",
                             NEW_WINDOW_TABS);
  if (!xfconf_channel_has_property (xfconf_channel, "/new_window/transparency"))
    xfconf_channel_set_int (xfconf_channel,
                            "/new_window/transparency",
                            NEW_WINDOW_TRANSPARENCY);
  if (!xfconf_channel_has_property (xfconf_channel, "/new_window/use_font"))
    xfconf_channel_set_bool (xfconf_channel,
                             "/new_window/use_font",
                             NEW_WINDOW_USE_FONT);
  if (!xfconf_channel_has_property (xfconf_channel, "/new_window/font_description"))
    xfconf_channel_set_string (xfconf_channel,
                               "/new_window/font_description",
                               NEW_WINDOW_FONT_DESCR);

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
  xfconf_g_property_bind (xfconf_channel, "/general/hide_windows_from_taskbar",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_container_add (GTK_CONTAINER (box), button);

  /* Hide arrow button */
  button = gtk_check_button_new_with_label (_("Hide arrow button"));
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
  xfconf_g_property_bind (xfconf_channel, "/new_window/always_on_top",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_box_pack_start (GTK_BOX (box), button, TRUE, FALSE, 0);

  /* Sticky window */
  button = gtk_check_button_new_with_label (_("Sticky window"));
  xfconf_g_property_bind (xfconf_channel, "/new_window/sticky",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_box_pack_start (GTK_BOX (box), button, TRUE, FALSE, 0);

  /* Font */
  hbox = gtk_hbox_new (FALSE, BORDER);
  gtk_box_pack_start (GTK_BOX (box), hbox, TRUE, FALSE, 0);

  button = gtk_check_button_new_with_label (_("Font"));
  xfconf_g_property_bind (xfconf_channel, "/new_window/use_font",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_box_pack_start (GTK_BOX (hbox), button, FALSE, FALSE, 0);

  button = gtk_font_button_new ();
  xfconf_g_property_bind (xfconf_channel, "/new_window/font_description",
                          G_TYPE_STRING, G_OBJECT (button), "font-name");
  gtk_box_pack_start (GTK_BOX (hbox), button, TRUE, TRUE, 0);

  /* Size */
  hbox = gtk_hbox_new (FALSE, BORDER);
  gtk_box_pack_start (GTK_BOX (box), hbox, TRUE, FALSE, 0);

  label = gtk_label_new (_("Size"));
  gtk_box_pack_start (GTK_BOX (hbox), label, FALSE, FALSE, 0);

  size_box = gtk_hbox_new (FALSE, 0);
  gtk_box_pack_start (GTK_BOX (hbox), size_box, TRUE, TRUE, 0);

  spin = gtk_spin_button_new_with_range (20.0, 600.0, 10.0);
  xfconf_g_property_bind (xfconf_channel, "/new_window/width",
                          G_TYPE_INT, G_OBJECT (spin), "value");
  gtk_box_pack_start (GTK_BOX (size_box), spin, TRUE, TRUE, 0);

  label = gtk_label_new ("×");
  gtk_box_pack_start (GTK_BOX (size_box), label, FALSE, FALSE, BORDER);

  spin = gtk_spin_button_new_with_range (20.0, 600.0, 10.0);
  xfconf_g_property_bind (xfconf_channel, "/new_window/height",
                          G_TYPE_INT, G_OBJECT (spin), "value");
  gtk_box_pack_start (GTK_BOX (size_box), spin, TRUE, TRUE, 0);

  /* === Ending === */
  gtk_widget_show_all (GTK_DIALOG (dialog)->vbox);

  return dialog;
}
#endif

