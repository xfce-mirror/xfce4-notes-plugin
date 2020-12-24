/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2008-2010  Mike Massonnet <mmassonnet@gmail.com>
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

#include <xfconf/xfconf.h>
#include <gtk/gtk.h>
#include <libxfce4util/libxfce4util.h>
#include <libxfce4ui/libxfce4ui.h>

#include "defines.h"

#if 0
static GtkWidget *notes_path_button_new ();
static void cb_notes_path_changed (GtkFileChooserButton *button, gpointer data);
#endif

enum
{
  COMBOBOX_TABS_NONE,
  COMBOBOX_TABS_TOP,
  COMBOBOX_TABS_RIGHT,
  COMBOBOX_TABS_BOTTOM,
  COMBOBOX_TABS_LEFT,
};

static GtkWidget *tabs_combo_box_new (void);

enum
{
  COMBOBOX_SIZE_SMALL,
  COMBOBOX_SIZE_NORMAL,
  COMBOBOX_SIZE_LARGE,
};

static GtkWidget *size_combo_box_new (void);
static void cb_size_combobox_changed (GtkComboBox *combobox, gpointer data);

#if 0
enum
{
  COMBOBOX_BACKGROUND_YELLOW,
  COMBOBOX_BACKGROUND_BLUE,
  COMBOBOX_BACKGROUND_GREEN,
  COMBOBOX_BACKGROUND_INDIGO,
  COMBOBOX_BACKGROUND_OLIVE,
  COMBOBOX_BACKGROUND_CARMIN,
  COMBOBOX_BACKGROUND_MIMOSA,
  COMBOBOX_BACKGROUND_WHITE,
  COMBOBOX_BACKGROUND_ANDROID,
  COMBOBOX_BACKGROUND_GTK,
  COMBOBOX_BACKGROUND_CUSTOM,
};

static GtkWidget *background_combo_box_new ();
static void cb_background_changed (GtkComboBox *combobox, gpointer data);

static GtkWidget *background_dialog_new ();
static gchar *background_dialog_get_color (GtkColorSelectionDialog *dialog);
static void cb_selection_changed (GtkColorSelection *selection, gpointer data);
static gboolean timeout_cb_background_changed (gchar *color);

static GtkWidget *color_button_new ();
static gboolean cb_color_button_pressed (GtkButton *button, GdkEventButton *event, gpointer data);
#endif

static GtkWidget *parent_window = NULL;
static XfconfChannel *xfconf_channel = NULL;
#if 0
static GtkWidget *color_combobox = NULL;
static GtkWidget *color_button = NULL;
#endif

static GtkWidget *
prop_dialog_new (void)
{
  GtkWidget *dialog, *notebook, *vbox, *frame, *box, *hbox, *button, *label;

  /* Configuration channel */
  if (NULL == xfconf_channel)
    xfconf_channel = xfconf_channel_new_with_property_base ("xfce4-panel", "/plugins/notes");

  /* Dialog */
  parent_window = dialog =
    xfce_titled_dialog_new_with_buttons (_("Notes"), NULL,
                                         GTK_DIALOG_DESTROY_WITH_PARENT,
                                         GTK_STOCK_CLOSE, GTK_RESPONSE_OK,
                                         NULL);
  xfce_titled_dialog_set_subtitle (XFCE_TITLED_DIALOG (dialog), _("Configure the plugin"));
  gtk_window_set_icon_name (GTK_WINDOW (dialog), "xfce4-notes-plugin");
  gtk_window_set_position (GTK_WINDOW (dialog), GTK_WIN_POS_CENTER);
  gtk_window_set_resizable (GTK_WINDOW (dialog), FALSE);
  gtk_window_stick (GTK_WINDOW (dialog));

  /* Notebook */
  notebook = gtk_notebook_new ();
  gtk_notebook_set_show_tabs (GTK_NOTEBOOK (notebook), FALSE);
  gtk_notebook_set_show_border (GTK_NOTEBOOK (notebook), TRUE);
  gtk_container_set_border_width (GTK_CONTAINER (notebook), 6);
  gtk_container_add (GTK_CONTAINER (gtk_dialog_get_content_area (GTK_DIALOG (dialog))), notebook);

  /* VBox */
  vbox = gtk_box_new (GTK_ORIENTATION_VERTICAL, 0);
  gtk_container_add (GTK_CONTAINER (notebook), vbox);

  /* === Global settings === */
  box = gtk_box_new (GTK_ORIENTATION_VERTICAL, BORDER);
  frame = xfce_gtk_frame_box_new_with_content (_("Global settings"), box);
  gtk_container_set_border_width (GTK_CONTAINER (frame), BORDER);
  gtk_container_add (GTK_CONTAINER (vbox), frame);

  /* Hide from taskbar */
  button = gtk_check_button_new_with_label (_("Hide notes from taskbar"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button), GENERAL_HIDE_FROM_TASKBAR);
  xfconf_g_property_bind (xfconf_channel, "/global/skip-taskbar-hint",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_box_pack_start (GTK_BOX (box), button, TRUE, FALSE, 0);

  /* Notes path */
#if 0
/*
 * I currently dislike this setting in the middle here, plus the
 * setting is not easy to understand since the notes are stored
 * within a specific structure (notes_path/GroupX/NoteY). One has
 * to select an empty directory otherwise things might really get
 * mixed up.
 */
  hbox = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, BORDER);
  gtk_box_pack_start (GTK_BOX (box), hbox, TRUE, FALSE, 0);

  label = gtk_label_new (_("Notes path:"));
  gtk_box_pack_start (GTK_BOX (hbox), label, FALSE, FALSE, 0);

  button = notes_path_button_new (dialog);
  gtk_box_pack_start (GTK_BOX (hbox), button, FALSE, FALSE, 0);
#endif

  /* Tabs position */
  hbox = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, BORDER);
  gtk_box_pack_start (GTK_BOX (box), hbox, TRUE, FALSE, 0);

  label = gtk_label_new (_("Tabs position:"));
  gtk_box_pack_start (GTK_BOX (hbox), label, FALSE, FALSE, 0);

  button = tabs_combo_box_new ();
  gtk_box_pack_start (GTK_BOX (hbox), button, FALSE, FALSE, 0);

#if 0
  /* Background color */
  hbox = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, BORDER);
  gtk_box_pack_start (GTK_BOX (box), hbox, TRUE, FALSE, 0);

  label = gtk_label_new (_("Background:"));
  gtk_box_pack_start (GTK_BOX (hbox), label, FALSE, FALSE, 0);

  color_combobox = background_combo_box_new ();
  gtk_box_pack_start (GTK_BOX (hbox), color_combobox, FALSE, FALSE, 0);

  color_button = color_button_new ();
  gtk_box_pack_start (GTK_BOX (hbox), color_button, FALSE, FALSE, 0);
#endif

  /* Font description */
  hbox = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, BORDER);
  gtk_box_pack_start (GTK_BOX (box), hbox, TRUE, FALSE, 0);

  label = gtk_label_new (_("Font:"));
  gtk_box_pack_start (GTK_BOX (hbox), label, FALSE, FALSE, 0);

  button = gtk_font_button_new_with_font ("Sans 12");
  xfconf_g_property_bind (xfconf_channel, "/global/font-description",
                          G_TYPE_STRING, G_OBJECT (button), "font-name");
  gtk_box_pack_start (GTK_BOX (hbox), button, FALSE, FALSE, 0);

  /* === New window settings === */
  box = gtk_box_new (GTK_ORIENTATION_VERTICAL, BORDER);
  frame = xfce_gtk_frame_box_new_with_content (_("New group settings"), box);
  gtk_container_set_border_width (GTK_CONTAINER (frame), BORDER);
  gtk_container_add (GTK_CONTAINER (vbox), frame);

  /* Always on top */
  button = gtk_check_button_new_with_label (_("Always on top"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button), NEW_WINDOW_ABOVE);
  xfconf_g_property_bind (xfconf_channel, "/new-window/always-on-top",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_box_pack_start (GTK_BOX (box), button, TRUE, FALSE, 0);

  /* Sticky window */
  button = gtk_check_button_new_with_label (_("Sticky"));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (button), NEW_WINDOW_STICKY);
  xfconf_g_property_bind (xfconf_channel, "/new-window/sticky",
                          G_TYPE_BOOLEAN, G_OBJECT (button), "active");
  gtk_box_pack_start (GTK_BOX (box), button, TRUE, FALSE, 0);

  /* Size */
  hbox = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, BORDER);
  gtk_box_pack_start (GTK_BOX (box), hbox, TRUE, FALSE, 0);

  label = gtk_label_new (_("Size:"));
  gtk_box_pack_start (GTK_BOX (hbox), label, FALSE, FALSE, 0);

  button = size_combo_box_new ();
  gtk_box_pack_start (GTK_BOX (hbox), button, FALSE, FALSE, 0);

  /* === Ending === */
  gtk_widget_show_all (gtk_dialog_get_content_area (GTK_DIALOG (dialog)));

  return dialog;
}

#if 0
static GtkWidget *
notes_path_button_new (void)
{
  GtkWidget *dialog, *button;
  gchar *default_path, *notes_path;

  default_path = g_strdup_printf ("%s/notes", g_get_user_data_dir ());
  notes_path = xfconf_channel_get_string (xfconf_channel, "/global/notes-path", default_path);

  dialog = gtk_file_chooser_dialog_new (_("Select notes path"), GTK_WINDOW (parent_window),
                                        GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER,
                                        GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL,
                                        GTK_STOCK_OPEN, GTK_RESPONSE_ACCEPT,
                                        NULL);
  gtk_window_set_icon_name (GTK_WINDOW (dialog), GTK_STOCK_DIRECTORY);

  button = GTK_WIDGET (g_object_new (GTK_TYPE_FILE_CHOOSER_BUTTON,
                                     "title", _("Select notes path"),
                                     "width-chars", 15,
                                     "action", GTK_FILE_CHOOSER_ACTION_OPEN,
                                     "dialog", dialog,
                                     NULL));
  g_object_set (dialog, "action", GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER, NULL);
  gtk_file_chooser_set_current_folder (GTK_FILE_CHOOSER (button), notes_path);

  g_signal_connect (button, "file-set", G_CALLBACK (cb_notes_path_changed), NULL);

  g_free (default_path);
  g_free (notes_path);

  return button;
}

static void
cb_notes_path_changed (GtkFileChooserButton *button,
                       gpointer data)
{
  GFile *file;
  gchar *notes_path;

  file = gtk_file_chooser_get_file (GTK_FILE_CHOOSER (button));
  notes_path = g_file_get_path (file);

  if (notes_path != NULL)
    xfconf_channel_set_string (xfconf_channel, "/global/notes-path", notes_path);

  g_object_unref (file);
  g_free (notes_path);
}
#endif

static GtkWidget *
tabs_combo_box_new (void)
{
  GtkWidget *combobox;

  combobox = gtk_combo_box_text_new ();
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("None"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Top"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Right"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Bottom"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Left"));
  gtk_combo_box_set_active (GTK_COMBO_BOX (combobox), 0);

  xfconf_g_property_bind (xfconf_channel, "/global/tabs-position",
                          G_TYPE_INT, G_OBJECT (combobox), "active");

  return combobox;
}

static GtkWidget *
size_combo_box_new (void)
{
  GtkWidget *combobox;
  gint size;

  combobox = gtk_combo_box_text_new ();
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Small"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Normal"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Large"));

  size = xfconf_channel_get_int (xfconf_channel, "/new-window/width", SIZE_NORMAL);
  if (size == SIZE_SMALL)
    gtk_combo_box_set_active (GTK_COMBO_BOX (combobox), COMBOBOX_SIZE_SMALL);
  else if (size == SIZE_NORMAL)
    gtk_combo_box_set_active (GTK_COMBO_BOX (combobox), COMBOBOX_SIZE_NORMAL);
  else if (size == SIZE_LARGE)
    gtk_combo_box_set_active (GTK_COMBO_BOX (combobox), COMBOBOX_SIZE_LARGE);

  g_signal_connect (combobox, "changed", G_CALLBACK (cb_size_combobox_changed), NULL);

  return combobox;
}

static void
cb_size_combobox_changed (GtkComboBox *combobox,
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
      height = (gint)width*SIZE_FACTOR;
    }
  else if (id == COMBOBOX_SIZE_NORMAL)
    {
      width = SIZE_NORMAL;
      height = (gint)width*SIZE_FACTOR;
    }
  else if (id == COMBOBOX_SIZE_LARGE)
    {
      width = SIZE_LARGE;
      height = (gint)width*SIZE_FACTOR;
    }

  xfconf_channel_set_int (xfconf_channel, "/new-window/width", width);
  xfconf_channel_set_int (xfconf_channel, "/new-window/height", height);
}

#if 0
static GtkWidget *
background_combo_box_new (void)
{
  GtkWidget *combobox;
  gchar *color;
  gint id;

  combobox = gtk_combo_box_text_new ();
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Yellow"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Blue"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Green"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Indigo"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Olive"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Carmine"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Mimosa"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("White"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Android"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("GTK+"));
  gtk_combo_box_text_append_text (GTK_COMBO_BOX_TEXT (combobox), _("Custom..."));

  color = xfconf_channel_get_string (xfconf_channel, "/global/background-color", GENERAL_BACKGROUND_COLOR);
  if (!g_ascii_strcasecmp (color, BACKGROUND_YELLOW))
    id = COMBOBOX_BACKGROUND_YELLOW;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_BLUE))
    id = COMBOBOX_BACKGROUND_BLUE;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_GREEN))
    id = COMBOBOX_BACKGROUND_GREEN;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_INDIGO))
    id = COMBOBOX_BACKGROUND_INDIGO;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_OLIVE))
    id = COMBOBOX_BACKGROUND_OLIVE;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_CARMIN))
    id = COMBOBOX_BACKGROUND_CARMIN;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_MIMOSA))
    id = COMBOBOX_BACKGROUND_MIMOSA;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_WHITE))
    id = COMBOBOX_BACKGROUND_WHITE;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_ANDROID))
    id = COMBOBOX_BACKGROUND_ANDROID;
  else if (!g_ascii_strcasecmp (color, BACKGROUND_GTK))
    id = COMBOBOX_BACKGROUND_GTK;
  else
    id = COMBOBOX_BACKGROUND_CUSTOM;
  gtk_combo_box_set_active (GTK_COMBO_BOX (combobox), id);
  g_free (color);

  g_signal_connect (combobox, "changed", G_CALLBACK (cb_background_changed), NULL);

  return combobox;
}

static gchar *
__gtk_widget_bg (void)
{
  GtkWidget *style_widget = gtk_invisible_new ();
  GtkStyle *style = gtk_widget_get_style (style_widget);
  return gdk_color_to_string (&style->bg[GTK_STATE_NORMAL]);
}

static void
cb_background_changed (GtkComboBox *combobox,
                       gpointer data)
{
  static guint timeout_background;
  GtkWidget *dialog;
  gchar *color = NULL;
  gint id;
  gint res;

  id = gtk_combo_box_get_active (combobox);

  if (id < 0 || id > COMBOBOX_BACKGROUND_CUSTOM)
    {
      g_critical ("Trying to set a default background but got an invalid item");
      return;
    }

  if (id == COMBOBOX_BACKGROUND_YELLOW)
    color = BACKGROUND_YELLOW;
  else if (id == COMBOBOX_BACKGROUND_BLUE)
    color = BACKGROUND_BLUE;
  else if (id == COMBOBOX_BACKGROUND_GREEN)
    color = BACKGROUND_GREEN;
  else if (id == COMBOBOX_BACKGROUND_INDIGO)
    color = BACKGROUND_INDIGO;
  else if (id == COMBOBOX_BACKGROUND_OLIVE)
    color = BACKGROUND_OLIVE;
  else if (id == COMBOBOX_BACKGROUND_CARMIN)
    color = BACKGROUND_CARMIN;
  else if (id == COMBOBOX_BACKGROUND_MIMOSA)
    color = BACKGROUND_MIMOSA;
  else if (id == COMBOBOX_BACKGROUND_WHITE)
    color = BACKGROUND_WHITE;
  else if (id == COMBOBOX_BACKGROUND_ANDROID)
    color = BACKGROUND_ANDROID;
  else if (id == COMBOBOX_BACKGROUND_GTK)
    color = BACKGROUND_GTK;
  else if (id == COMBOBOX_BACKGROUND_CUSTOM)
    {
      dialog = background_dialog_new ();
      gtk_window_set_transient_for (GTK_WINDOW (dialog), GTK_WINDOW (gtk_widget_get_toplevel (GTK_WIDGET (combobox))));
      gtk_window_set_modal (GTK_WINDOW (dialog), TRUE);
      gtk_window_set_position (GTK_WINDOW (dialog), GTK_WIN_POS_CENTER_ON_PARENT);

      res = gtk_dialog_run (GTK_DIALOG (dialog));
      if (res == GTK_RESPONSE_OK)
        {
          color = background_dialog_get_color (GTK_COLOR_SELECTION_DIALOG (dialog));
        }

      gtk_widget_destroy (dialog);

      if (res != GTK_RESPONSE_OK)
        {
          return;
        }
    }

  if (id != COMBOBOX_BACKGROUND_CUSTOM)
    color = g_strdup (color);

  /* Postpone the real-setting change, otherwise switching too briefly through
   * the combobox won't always update the theme. */
  if (timeout_background != 0)
    g_source_remove (timeout_background);
  timeout_background = g_timeout_add (500, (GSourceFunc)timeout_cb_background_changed, color);
}

static gboolean
timeout_cb_background_changed (gchar *color)
{
  GdkColor gdkcolor;
  xfconf_channel_set_string (xfconf_channel, "/global/background-color", color);
  if (!g_strcmp0 (color, "GTK+"))
      color = __gtk_widget_bg ();
  gdk_color_parse (color, &gdkcolor);
  gtk_color_button_set_color (GTK_COLOR_BUTTON (color_button), &gdkcolor);
  return FALSE;
}

static GtkWidget *
background_dialog_new (void)
{
  GtkWidget *dialog;
  GtkWidget *selection;
  GdkColor gdkcolor;
  gchar *color;

  dialog = gtk_color_selection_dialog_new (_("Background Color"));

  selection = gtk_color_selection_dialog_get_color_selection (GTK_COLOR_SELECTION_DIALOG (dialog));
  gtk_color_selection_set_has_opacity_control (GTK_COLOR_SELECTION (selection), FALSE);
  g_signal_connect (selection, "color-changed", G_CALLBACK (cb_selection_changed), NULL);

  color = xfconf_channel_get_string (xfconf_channel, "/global/background-color", GENERAL_BACKGROUND_COLOR);
  if (!g_strcmp0 (color, "GTK+"))
      color = __gtk_widget_bg ();
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
color_button_new (void)
{
  GtkWidget *button;
  GdkColor gdkcolor;
  gchar *color;

  color = xfconf_channel_get_string (xfconf_channel, "/global/background-color", GENERAL_BACKGROUND_COLOR);
  if (!g_strcmp0 (color, "GTK+"))
      color = __gtk_widget_bg ();
  gdk_color_parse (color, &gdkcolor);
  g_free (color);

  button = gtk_color_button_new_with_color (&gdkcolor);

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



gint main (gint argc,
           gchar *argv[])
{
  GtkWidget *dialog;
  GtkApplication *app;
  GError *error = NULL;
  xfce_textdomain (GETTEXT_PACKAGE, PACKAGE_LOCALE_DIR, NULL);
  xfconf_init (NULL);
  gtk_init (&argc, &argv);

  app = gtk_application_new ("org.xfce.NotesSettings", 0);

  g_application_register (G_APPLICATION (app), NULL, &error);
  if (error != NULL)
    {
      g_warning ("Unable to register GApplication: %s", error->message);
      g_error_free (error);
      error = NULL;
    }

  if (g_application_get_is_remote (G_APPLICATION (app)))
    {
      g_application_activate (G_APPLICATION (app));
      g_object_unref (app);
      return 0;
    }

  dialog = prop_dialog_new ();

  g_signal_connect_swapped (app, "activate", G_CALLBACK (gtk_window_present), dialog);

  gtk_dialog_run (GTK_DIALOG (dialog));
  gtk_widget_destroy (dialog);
  xfconf_shutdown ();
  return 0;
}

