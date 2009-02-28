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
#include "color.h"

enum
{
  COMBOBOX_SIZE_SMALL,
  COMBOBOX_SIZE_NORMAL,
  COMBOBOX_SIZE_LARGE,
};

static GtkWidget *size_combo_box_new ();
static void cb_size_changed (GtkComboBox *combobox, gpointer data);

enum
{
  COMBOBOX_BACKGROUND_YELLOW,
  COMBOBOX_BACKGROUND_RED,
  COMBOBOX_BACKGROUND_BLUE,
  COMBOBOX_BACKGROUND_GREEN,
  COMBOBOX_BACKGROUND_PURPLE,
  COMBOBOX_BACKGROUND_WHITE,
  COMBOBOX_BACKGROUND_CUSTOM,
};

static GtkWidget *background_combo_box_new ();
static void cb_background_changed (GtkComboBox *combobox, gpointer data);

static GtkWidget *background_dialog_new ();
static gchar *background_dialog_get_color (GtkColorSelectionDialog *dialog);
static void cb_selection_changed (GtkColorSelection *selection, gpointer data);

static GtkWidget *color_button_new ();
static gboolean cb_color_button_pressed (GtkButton *button, GdkEventButton *event, gpointer data);

static XfconfChannel *xfconf_channel = NULL;
static GtkWidget *color_combobox = NULL;
static GtkWidget *color_button = NULL;

GtkWidget *
prop_dialog_new (NotesPlugin *notes_plugin)
{
  GtkWidget *dialog, *frame, *box, *hbox, *button, *label;

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
  gtk_window_set_default_size (GTK_WINDOW (dialog), 300, -1);
  gtk_window_set_icon_name (GTK_WINDOW (dialog), "xfce4-notes-plugin");
  gtk_window_set_position (GTK_WINDOW (dialog), GTK_WIN_POS_CENTER);
  gtk_window_stick (GTK_WINDOW (dialog));

  /* === Default settings === */
  box = gtk_vbox_new (FALSE, BORDER);
  frame = xfce_create_framebox_with_content (_("Default settings"), box);
  gtk_container_set_border_width (GTK_CONTAINER (frame), BORDER);
  gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox), frame);

  /* Hide from taskbar */
  button = gtk_check_button_new_with_label (_("Hide windows from taskbar"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button), GENERAL_HIDE_FROM_TASKBAR);
  xfconf_g_property_bind (xfconf_channel, "/general/hide_windows_from_taskbar",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_box_pack_start (GTK_BOX (box), button, TRUE, FALSE, 0);

  /* Hide arrow button */
  button = gtk_check_button_new_with_label (_("Hide arrow button"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button), GENERAL_HIDE_ARROW_BUTTON);
  xfconf_g_property_bind (xfconf_channel, "/general/hide_arrow_button",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_box_pack_start (GTK_BOX (box), button, TRUE, FALSE, 0);

  /* Background color */
  hbox = gtk_hbox_new (FALSE, BORDER);
  gtk_box_pack_start (GTK_BOX (box), hbox, TRUE, FALSE, 0);

  label = gtk_label_new (_("Background:"));
  gtk_box_pack_start (GTK_BOX (hbox), label, FALSE, FALSE, 0);

  color_combobox = background_combo_box_new ();
  gtk_box_pack_start (GTK_BOX (hbox), color_combobox, FALSE, FALSE, 0);

  color_button = color_button_new ();
  gtk_box_pack_start (GTK_BOX (hbox), color_button, FALSE, FALSE, 0);

  /* === New window settings === */
  box = gtk_vbox_new (FALSE, BORDER);
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

  button = size_combo_box_new ();
  gtk_box_pack_start (GTK_BOX (hbox), button, FALSE, FALSE, 0);

  /* === Ending === */
  gtk_widget_show_all (GTK_DIALOG (dialog)->vbox);

  return dialog;
}

static GtkWidget *
size_combo_box_new ()
{
  GtkWidget *combobox;
  gint size;

  combobox = gtk_combo_box_new_text ();
  gtk_combo_box_append_text (GTK_COMBO_BOX (combobox), _("Small"));
  gtk_combo_box_append_text (GTK_COMBO_BOX (combobox), _("Normal"));
  gtk_combo_box_append_text (GTK_COMBO_BOX (combobox), _("Large"));

  size = xfconf_channel_get_int (xfconf_channel, "/new_window/width", SIZE_NORMAL);
  if (size == SIZE_SMALL)
    gtk_combo_box_set_active (GTK_COMBO_BOX (combobox), COMBOBOX_SIZE_SMALL);
  else if (size == SIZE_NORMAL)
    gtk_combo_box_set_active (GTK_COMBO_BOX (combobox), COMBOBOX_SIZE_NORMAL);
  else if (size == SIZE_LARGE)
    gtk_combo_box_set_active (GTK_COMBO_BOX (combobox), COMBOBOX_SIZE_LARGE);

  g_signal_connect (combobox, "changed", G_CALLBACK (cb_size_changed), NULL);

  return combobox;
}

static void
cb_size_changed (GtkComboBox *combobox,
                 gpointer data)
{
  gint id;
  gint width = 0, height = 0;

  id = gtk_combo_box_get_active (combobox);

  if (id < 0 || id > COMBOBOX_SIZE_LARGE)
    {
      g_critical ("Trying to set a default size but got an invalid item");
      return;
    }

  if (id == COMBOBOX_SIZE_SMALL)
    {
      width = SIZE_SMALL;
      height = (gint)SIZE_SMALL*SIZE_FACTOR;
    }
  else if (id == COMBOBOX_SIZE_NORMAL)
    {
      width = SIZE_NORMAL;
      height = (gint)SIZE_NORMAL*SIZE_FACTOR;
    }
  else if (id == COMBOBOX_SIZE_LARGE)
    {
      width = SIZE_LARGE;
      height = (gint)SIZE_LARGE*SIZE_FACTOR;
    }

  xfconf_channel_set_int (xfconf_channel, "/new_window/width", width);
  xfconf_channel_set_int (xfconf_channel, "/new_window/height", height);
}

static GtkWidget *
background_combo_box_new ()
{
  GtkWidget *combobox;
  gchar *color;
  gint id;

  combobox = gtk_combo_box_new_text ();
  gtk_combo_box_append_text (GTK_COMBO_BOX (combobox), _("Yellow"));
  gtk_combo_box_append_text (GTK_COMBO_BOX (combobox), _("Red"));
  gtk_combo_box_append_text (GTK_COMBO_BOX (combobox), _("Blue"));
  gtk_combo_box_append_text (GTK_COMBO_BOX (combobox), _("Green"));
  gtk_combo_box_append_text (GTK_COMBO_BOX (combobox), _("Purple"));
  gtk_combo_box_append_text (GTK_COMBO_BOX (combobox), _("White"));
  gtk_combo_box_append_text (GTK_COMBO_BOX (combobox), _("Custom..."));

  color = xfconf_channel_get_string (xfconf_channel, "/general/background_color", GENERAL_BACKGROUND_COLOR);
  if (!g_ascii_strcasecmp (color, BACKGROUND_YELLOW))
    id = COMBOBOX_BACKGROUND_YELLOW;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_RED))
    id = COMBOBOX_BACKGROUND_RED;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_BLUE))
    id = COMBOBOX_BACKGROUND_BLUE;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_GREEN))
    id = COMBOBOX_BACKGROUND_GREEN;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_PURPLE))
    id = COMBOBOX_BACKGROUND_PURPLE;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_WHITE))
    id = COMBOBOX_BACKGROUND_WHITE;
  else
    id = COMBOBOX_BACKGROUND_CUSTOM;
  gtk_combo_box_set_active (GTK_COMBO_BOX (combobox), id);
  g_free (color);

  g_signal_connect (combobox, "changed", G_CALLBACK (cb_background_changed), NULL);

  return combobox;
}

static void
cb_background_changed (GtkComboBox *combobox,
                       gpointer data)
{
  GtkWidget *dialog;
  GdkColor gdkcolor;
  gchar *color = NULL;
  gint id;

  id = gtk_combo_box_get_active (combobox);

  if (id < 0 || id > COMBOBOX_BACKGROUND_CUSTOM)
    {
      g_critical ("Trying to set a default background but got an invalid item");
      return;
    }

  if (id == COMBOBOX_BACKGROUND_YELLOW)
    color = BACKGROUND_YELLOW;
  else if (id == COMBOBOX_BACKGROUND_RED)
    color = BACKGROUND_RED;
  else if (id == COMBOBOX_BACKGROUND_BLUE)
    color = BACKGROUND_BLUE;
  else if (id == COMBOBOX_BACKGROUND_GREEN)
    color = BACKGROUND_GREEN;
  else if (id == COMBOBOX_BACKGROUND_PURPLE)
    color = BACKGROUND_PURPLE;
  else if (id == COMBOBOX_BACKGROUND_WHITE)
    color = BACKGROUND_WHITE;
  else if (id == COMBOBOX_BACKGROUND_CUSTOM)
    {
      dialog = background_dialog_new ();
      gtk_window_set_transient_for (GTK_WINDOW (dialog), GTK_WINDOW (gtk_widget_get_toplevel (GTK_WIDGET (combobox))));
      gtk_window_set_modal (GTK_WINDOW (dialog), TRUE);
      gtk_window_set_position (GTK_WINDOW (dialog), GTK_WIN_POS_CENTER_ON_PARENT);

      if (gtk_dialog_run (GTK_DIALOG (dialog)) == GTK_RESPONSE_OK)
        {
          color = background_dialog_get_color (GTK_COLOR_SELECTION_DIALOG (dialog));
          gdk_color_parse (color, &gdkcolor);
          xfconf_channel_set_string (xfconf_channel, "/general/background_color", color);
          g_free (color);

          gtk_color_button_set_color (GTK_COLOR_BUTTON (color_button), &gdkcolor);
        }

      gtk_widget_destroy (dialog);
      return;
    }

  xfconf_channel_set_string (xfconf_channel, "/general/background_color", color);

  gdk_color_parse (color, &gdkcolor);
  gtk_color_button_set_color (GTK_COLOR_BUTTON (color_button), &gdkcolor);
}

static GtkWidget *
background_dialog_new ()
{
  GtkWidget *dialog;
  GtkWidget *selection;
  GdkColor gdkcolor;
  gchar *color;

  dialog = gtk_color_selection_dialog_new (_("Background Color"));

  selection = gtk_color_selection_dialog_get_color_selection (GTK_COLOR_SELECTION_DIALOG (dialog));
  gtk_color_selection_set_has_opacity_control (GTK_COLOR_SELECTION (selection), FALSE);
  g_signal_connect (selection, "color-changed", G_CALLBACK (cb_selection_changed), NULL);

  color = xfconf_channel_get_string (xfconf_channel, "/general/background_color", GENERAL_BACKGROUND_COLOR);
  gdk_color_parse (color, &gdkcolor);
  gtk_color_selection_set_current_color (GTK_COLOR_SELECTION (selection), &gdkcolor);
  g_free (color);

  return dialog;
}

static gchar *
background_dialog_get_color (GtkColorSelectionDialog *dialog)
{
  GtkWidget *selection;
  GdkColor color;

  selection = gtk_color_selection_dialog_get_color_selection (GTK_COLOR_SELECTION_DIALOG (dialog));
  gtk_color_selection_get_current_color (GTK_COLOR_SELECTION (selection), &color);

  return gdk_color_to_string (&color);
}

static void
cb_selection_changed (GtkColorSelection *selection,
                      gpointer data)
{
  GdkColor color, *color2;

  gtk_color_selection_get_current_color (selection, &color);

  color2 = gdk_color_copy (&color);
  __gdk_color_contrast (color2, 5.);

  gtk_color_selection_set_previous_color (selection, color2);

  gdk_color_free (color2);
}

static GtkWidget *
color_button_new ()
{
  GtkWidget *button;
  GdkColor gdkcolor;
  gchar *color;

  color = xfconf_channel_get_string (xfconf_channel, "/general/background_color", GENERAL_BACKGROUND_COLOR);
  gdk_color_parse (color, &gdkcolor);
  g_free (color);

  button = gtk_color_button_new_with_color (&gdkcolor);
  gtk_button_set_relief (GTK_BUTTON (button), GTK_RELIEF_NONE);

  g_signal_connect (button, "button-press-event", G_CALLBACK (cb_color_button_pressed), NULL);

  return button;
}

static gboolean
cb_color_button_pressed (GtkButton *button,
                         GdkEventButton *event,
                         gpointer data)
{
  gint id;

  if (event->button != 1)
    return TRUE;

  id = gtk_combo_box_get_active (GTK_COMBO_BOX (color_combobox));

  if (id == COMBOBOX_BACKGROUND_CUSTOM)
    cb_background_changed (GTK_COMBO_BOX (color_combobox), NULL);
  else
    gtk_combo_box_set_active (GTK_COMBO_BOX (color_combobox), COMBOBOX_BACKGROUND_CUSTOM);

  return TRUE;
}

#endif

