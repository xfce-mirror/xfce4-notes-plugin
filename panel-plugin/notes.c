/*  $Id$
 *
 *  Copyright (c) 2006 Mike Massonnet <mmassonnet@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <glib/gstdio.h>
#include <gtk/gtk.h>
#include <libxfce4panel/xfce-panel-convenience.h>
#include <libxfce4util/libxfce4util.h>

#include "notes.h"

#define PLUGIN_NAME "xfce4-notes-plugin"



static void             notes_window_menu_new           (NotesWindow *notes_window);

static gboolean         notes_window_menu_popup         (NotesWindow *notes_window,
                                                         GdkEvent *event);
static void             notes_window_set_sos_always     (NotesWindow *notes_window);

static void             notes_window_set_sos_never      (NotesWindow *notes_window);

static void             notes_window_set_sos_last_state (NotesWindow *notes_window);

static void             notes_window_set_statusbar      (NotesWindow *notes_window);

static void             notes_window_set_always_on_top  (NotesWindow *notes_window);

static void             notes_window_set_stick          (NotesWindow *notes_window);

static void             notes_window_show               (NotesWindow *notes_window);

static gboolean         notes_window_hide               (NotesWindow *notes_window);

static gboolean         notes_window_start_move         (NotesWindow *notes_window,
                                                         GdkEventButton *event);
static gboolean         notes_window_shade              (NotesWindow *notes_window,
                                                         GdkEventScroll *event);
static void             notes_window_rename             (NotesWindow *notes_window);

static void             notes_window_destroy            (NotesWindow *notes_window);

/* FIXME */
static void             notes_window_add_note           (GtkWidget *widget,
                                                         NotesWindow *notes_window);
static gboolean         notes_window_delete_note        (GtkWidget *widget,
                                                         NotesWindow *notes_window);
static gboolean         notes_note_rename               (GtkWidget *widget,
                                                         GdkEventButton *event,
                                                         NotesNote *notes_note);
static void             notes_note_buffer_changed       (GtkWidget *widget,
                                                         NotesNote *notes_note);
static gboolean         notes_note_key_pressed          (GtkWidget *widget,
                                                         GdkEventKey *event,
                                                         NotesNote *notes_note);



const gchar *
notes_window_read_name (NotesPlugin *notes_plugin)
{
  static GDir          *dir = NULL;
  static gchar         *notes_path = NULL;
  static const gchar   *window_name = NULL;

  if (G_UNLIKELY (dir == NULL))
    {
      notes_path = notes_plugin->notes_path;
      dir = g_dir_open (notes_path, 0, NULL);
    }

  window_name = g_dir_read_name (dir);
  TRACE ("window_name: %s", window_name);
  if (G_UNLIKELY (window_name == NULL))
    {
      g_dir_close (dir);
      dir = NULL;
    }

  return window_name;
}

NotesWindow *
notes_window_new (NotesPlugin *notes_plugin)
{
  return notes_window_new_with_label (notes_plugin, NULL);
}

NotesWindow *
notes_window_new_with_label (NotesPlugin *notes_plugin,
                             const gchar *window_name)
{
  DBG ("New window: %s", window_name);

  NotesWindow          *notes_window;
  GtkAccelGroup        *accel_group;
  GtkWidget            *img_add, *img_del, *img_close, *arrow_menu;
  gchar                *window_name_tmp;

  notes_window = g_slice_new0 (NotesWindow);
  notes_window->notes_plugin = notes_plugin;
  notes_window->name = g_strdup (window_name);
  notes_plugin->windows = g_slist_prepend (notes_plugin->windows, notes_window);

  /* Window */
  notes_window->window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
  gtk_window_set_deletable (GTK_WINDOW (notes_window->window), FALSE);
  gtk_window_set_title (GTK_WINDOW (notes_window->window), window_name);
  gtk_window_set_default_size (GTK_WINDOW (notes_window->window), 375, 430);
  gtk_window_set_decorated (GTK_WINDOW (notes_window->window), FALSE);
  gtk_window_set_icon_name (GTK_WINDOW (notes_window->window), "xfce4-notes-plugin");
  gtk_widget_set_name (notes_window->window, PLUGIN_NAME);

  /* Frame */
  notes_window->frame = gtk_frame_new (NULL);
  gtk_frame_set_shadow_type (GTK_FRAME (notes_window->frame), GTK_SHADOW_OUT);
  gtk_container_add (GTK_CONTAINER (notes_window->window),
                     notes_window->frame);
  gtk_widget_show (notes_window->frame);

  /* Vertical box */
  notes_window->vbox = gtk_vbox_new (FALSE, 0);
  gtk_box_set_spacing (GTK_BOX (notes_window->vbox), 1);
  gtk_container_add (GTK_CONTAINER (notes_window->frame),
                     notes_window->vbox);
  gtk_widget_show (notes_window->vbox);

  /* Horizontal box */
  notes_window->hbox = gtk_hbox_new (FALSE, 2);
  gtk_box_pack_start (GTK_BOX (notes_window->vbox),
                      notes_window->hbox,
                      FALSE,
                      FALSE,
                      0);
  gtk_widget_show (notes_window->hbox);

  /* Add button XXX create panel button ?! */
  notes_window->btn_add = xfce_create_panel_button ();
  gtk_widget_set_size_request (notes_window->btn_add, 22, 22);
  img_add = gtk_image_new_from_stock (GTK_STOCK_ADD, GTK_ICON_SIZE_MENU);
  gtk_container_add (GTK_CONTAINER (notes_window->btn_add),
                     img_add);
  gtk_box_pack_start (GTK_BOX (notes_window->hbox),
                      notes_window->btn_add,
                      FALSE,
                      FALSE,
                      0);
  gtk_widget_show_all (notes_window->btn_add);

  /* Remove button */
  notes_window->btn_del = xfce_create_panel_button ();
  gtk_widget_set_size_request (notes_window->btn_del, 22, 22);
  img_del = gtk_image_new_from_stock (GTK_STOCK_REMOVE, GTK_ICON_SIZE_MENU);
  gtk_container_add (GTK_CONTAINER (notes_window->btn_del),
                     img_del);
  gtk_box_pack_start (GTK_BOX (notes_window->hbox),
                      notes_window->btn_del,
                      FALSE,
                      FALSE,
                      0);
  gtk_widget_show_all (notes_window->btn_del);

  /* Event box move */
  notes_window->eb_move = gtk_event_box_new ();
  gtk_event_box_set_visible_window (GTK_EVENT_BOX (notes_window->eb_move), FALSE);
  gtk_box_pack_start (GTK_BOX (notes_window->hbox),
                      notes_window->eb_move,
                      TRUE,
                      TRUE,
                      0);
  gtk_widget_show (notes_window->eb_move);
  gtk_widget_realize (notes_window->eb_move);

  /* Title */
  window_name_tmp = g_strdup_printf ("<b>%s</b>", window_name);
  notes_window->title = gtk_label_new (window_name_tmp);
  g_free (window_name_tmp);
  gtk_label_set_use_markup (GTK_LABEL (notes_window->title), TRUE);
  gtk_container_add (GTK_CONTAINER (notes_window->eb_move),
                     notes_window->title);
  gtk_widget_show (notes_window->title);

  /* Menu button */
  notes_window->btn_menu = xfce_create_panel_button ();
  gtk_widget_set_size_request (notes_window->btn_menu, 22, 22);
  arrow_menu = gtk_arrow_new (GTK_ARROW_DOWN, GTK_SHADOW_NONE);
  gtk_container_add (GTK_CONTAINER (notes_window->btn_menu),
                     arrow_menu);
  gtk_box_pack_start (GTK_BOX (notes_window->hbox),
                      notes_window->btn_menu,
                      FALSE,
                      FALSE,
                      0);
  gtk_widget_show_all (notes_window->btn_menu);

  /* Close button */
  notes_window->btn_close = xfce_create_panel_button ();
  gtk_widget_set_size_request (notes_window->btn_close, 22, 22);
  img_close = gtk_image_new_from_stock (GTK_STOCK_CLOSE, GTK_ICON_SIZE_MENU);
  gtk_container_add (GTK_CONTAINER (notes_window->btn_close),
                     img_close);
  gtk_box_pack_start (GTK_BOX (notes_window->hbox),
                      notes_window->btn_close,
                      FALSE,
                      FALSE,
                      0);
  gtk_widget_show_all (notes_window->btn_close);

  /* Notebook */
  notes_window->notebook = gtk_notebook_new ();
  gtk_notebook_set_show_tabs (GTK_NOTEBOOK (notes_window->notebook), FALSE);
  gtk_notebook_set_tab_pos (GTK_NOTEBOOK (notes_window->notebook), GTK_POS_LEFT);
  gtk_notebook_set_scrollable (GTK_NOTEBOOK (notes_window->notebook), TRUE);
  gtk_box_pack_start (GTK_BOX (notes_window->vbox),
                      notes_window->notebook,
                      TRUE,
                      TRUE,
                      0);
  gtk_widget_show (notes_window->notebook);

  /* Status bar */
  notes_window->statusbar = gtk_statusbar_new ();
  gtk_box_pack_start (GTK_BOX (notes_window->vbox),
                      notes_window->statusbar,
                      FALSE,
                      FALSE,
                      0);

  /* Accel group */
  accel_group = gtk_accel_group_new ();
  gtk_window_add_accel_group (GTK_WINDOW (notes_window->window), accel_group);
  gtk_widget_add_accelerator (notes_window->btn_add,
                              "clicked",
                              accel_group,
                              'N',
                              GDK_CONTROL_MASK,
                              GTK_ACCEL_MASK);
  gtk_widget_add_accelerator (notes_window->btn_del,
                              "clicked",
                              accel_group,
                              'W',
                              GDK_CONTROL_MASK,
                              GTK_ACCEL_MASK);

  /* Signals FIXME */
  g_signal_connect_swapped (G_OBJECT (notes_window->eb_move),
                            "button-press-event",
                            G_CALLBACK (notes_window_start_move),
                            notes_window);
  g_signal_connect_swapped (G_OBJECT (notes_window->eb_move),
                            "scroll-event",
                            G_CALLBACK (notes_window_shade),
                            notes_window);
  g_signal_connect_swapped (G_OBJECT (notes_window->btn_menu),
                            "event",
                            G_CALLBACK (notes_window_menu_popup),
                            notes_window);
  g_signal_connect_swapped (notes_window->window,
                            "delete-event",
                            G_CALLBACK (notes_window_hide), /* XXX should prevent ALT+F4 */
                            notes_window);
  g_signal_connect_swapped (notes_window->btn_close,
                            "clicked",
                            G_CALLBACK (notes_window_hide),
                            notes_window);
  g_signal_connect (notes_window->btn_add,
                    "clicked",
                    G_CALLBACK (notes_window_add_note),
                    notes_plugin);
  g_signal_connect (notes_window->btn_del,
                    "clicked",
                    G_CALLBACK (notes_window_delete_note),
                    notes_plugin);

  /* Load data */
  notes_window_load_data (notes_window);
  notes_window_menu_new (notes_window);

  /* Show the stuff, or not */
  if (G_UNLIKELY (notes_window->show_statusbar))
    gtk_widget_show (notes_window->statusbar);

  if (G_LIKELY (notes_window->show_on_startup == ALWAYS
                || (notes_window->visible
                    && notes_window->show_on_startup == LAST_STATE)))
    notes_window_show (notes_window);

  return notes_window;
}

void
notes_window_load_data (NotesWindow *notes_window)
{
  XfceRc               *rc;
  NotesNote            *notes_note;
  const gchar          *note_name;
  gchar                *window_name_tmp;

  if (G_LIKELY (notes_window->name == NULL))
    {
      guint id = g_slist_length (notes_window->notes_plugin->windows);
      if (G_LIKELY (id > 1))
        notes_window->name = g_strdup_printf (_("Notes %d"), id);
      else
        notes_window->name = g_strdup (_("Notes"));

      window_name_tmp = g_strdup_printf ("<b>%s</b>", notes_window->name);
      gtk_label_set_text (GTK_LABEL (notes_window->title), window_name_tmp);
      gtk_label_set_use_markup (GTK_LABEL (notes_window->title), TRUE);
      g_free (window_name_tmp);
    }

  rc = xfce_rc_simple_open (notes_window->notes_plugin->config_file, FALSE);
  xfce_rc_set_group (rc, notes_window->name);

  notes_window->x = xfce_rc_read_int_entry (rc, "PosX", -1);
  notes_window->y = xfce_rc_read_int_entry (rc, "PosY", -1);
  notes_window->w = xfce_rc_read_int_entry (rc, "Width", 375);
  notes_window->h = xfce_rc_read_int_entry (rc, "Height", 430);

  notes_window->always_on_top   = xfce_rc_read_bool_entry (rc, "AlwaysOnTop", FALSE);
  notes_window->show_on_startup = xfce_rc_read_int_entry (rc, "ShowOnStartup", LAST_STATE);
  notes_window->show_statusbar  = xfce_rc_read_bool_entry (rc, "ShowStatusbar", FALSE);
  notes_window->stick           = xfce_rc_read_bool_entry (rc, "Stick", TRUE);
  notes_window->visible         = xfce_rc_read_bool_entry (rc, "Visible", TRUE);

  xfce_rc_close (rc);

  TRACE ("\nalways_on_top: %d"
         "\nshow_on_startup: %d"
         "\nshow_statusbar: %d"
         "\nstick: %d"
         "\nvisible: %d",
         notes_window->always_on_top,
         notes_window->show_on_startup,
         notes_window->show_statusbar,
         notes_window->stick,
         notes_window->visible);

  note_name = notes_note_read_name (notes_window);
  do
    {
      TRACE ("note_name: %s", note_name);
      notes_note = notes_note_new (notes_window, note_name);
      note_name = notes_note_read_name (notes_window);
    }
  while (G_LIKELY (note_name != NULL));
}

void
notes_window_save_data (NotesWindow *notes_window)
{
  XfceRc               *rc;
  const gchar          *window_name;

  rc = xfce_rc_simple_open (notes_window->notes_plugin->config_file, FALSE);
  g_return_if_fail (G_LIKELY (rc != NULL));

  window_name = gtk_label_get_text (GTK_LABEL (notes_window->title));

  xfce_rc_set_group (rc, window_name);

  if (GTK_WIDGET_VISIBLE (notes_window->window))
    {
      gtk_window_get_position (GTK_WINDOW (notes_window->window),
                               &notes_window->x,
                               &notes_window->y);
      gtk_window_get_size (GTK_WINDOW (notes_window->window),
                           &notes_window->w,
                           &notes_window->h);
    }

  xfce_rc_write_int_entry (rc, "PosX", notes_window->x);
  xfce_rc_write_int_entry (rc, "PosY", notes_window->y);
  xfce_rc_write_int_entry (rc, "Width", notes_window->w);
  xfce_rc_write_int_entry (rc, "Height", notes_window->h);

  xfce_rc_write_bool_entry (rc, "AlwaysOnTop",
                            notes_window->always_on_top);
  xfce_rc_write_int_entry (rc, "ShowOnStartup",
                           notes_window->show_on_startup);
  xfce_rc_write_bool_entry (rc, "ShowStatusbar",
                            notes_window->show_statusbar);
  xfce_rc_write_bool_entry (rc, "Stick",
                            notes_window->stick);
  xfce_rc_write_bool_entry (rc, "Visible",
                            GTK_WIDGET_VISIBLE (notes_window->window));

  xfce_rc_close (rc);
}

void
notes_window_menu_new (NotesWindow *notes_window)
{
  /* Menu */
  notes_window->menu = gtk_menu_new ();
  GtkWidget *mi_new_window      = gtk_image_menu_item_new_with_label (_("New window"));
  GtkWidget *img_new_window     = gtk_image_new_from_stock (GTK_STOCK_NEW, GTK_ICON_SIZE_MENU);
  gtk_image_menu_item_set_image (GTK_IMAGE_MENU_ITEM (mi_new_window), img_new_window);
  GtkWidget *mi_destroy_window  = gtk_image_menu_item_new_with_label (_("Destroy window"));
  GtkWidget *img_destroy_window = gtk_image_new_from_stock (GTK_STOCK_DELETE, GTK_ICON_SIZE_MENU);
  gtk_image_menu_item_set_image (GTK_IMAGE_MENU_ITEM (mi_destroy_window), img_destroy_window);
  GtkWidget *mi_rename_window   = gtk_menu_item_new_with_label (_("Rename window..."));
  GtkWidget *mi_separator1      = gtk_separator_menu_item_new ();
  GtkWidget *mi_show_on_startup = gtk_menu_item_new_with_label (_("Show on startup"));
  GtkWidget *mi_show_statusbar  = gtk_check_menu_item_new_with_label (_("Show statusbar"));
  GtkWidget *mi_always_on_top   = gtk_check_menu_item_new_with_label (_("Always on top"));
  GtkWidget *mi_stick           = gtk_check_menu_item_new_with_label (_("Sticky window"));

  gtk_menu_shell_append (GTK_MENU_SHELL (notes_window->menu), mi_new_window);
  gtk_menu_shell_append (GTK_MENU_SHELL (notes_window->menu), mi_destroy_window);
  gtk_menu_shell_append (GTK_MENU_SHELL (notes_window->menu), mi_rename_window);
  gtk_menu_shell_append (GTK_MENU_SHELL (notes_window->menu), mi_separator1);
  gtk_menu_shell_append (GTK_MENU_SHELL (notes_window->menu), mi_show_on_startup);
  gtk_menu_shell_append (GTK_MENU_SHELL (notes_window->menu), mi_show_statusbar);
  gtk_menu_shell_append (GTK_MENU_SHELL (notes_window->menu), mi_always_on_top);
  gtk_menu_shell_append (GTK_MENU_SHELL (notes_window->menu), mi_stick);
  gtk_menu_attach_to_widget (GTK_MENU (notes_window->menu), notes_window->btn_menu, NULL);

  /* Sub-menu "Show on startup" */
  GtkWidget *menu_show_on_startup = gtk_menu_new ();
  GSList *menu_group = NULL;
  GtkWidget *mi_sos_always      = gtk_radio_menu_item_new_with_label (menu_group, _("Always"));
  menu_group = gtk_radio_menu_item_get_group (GTK_RADIO_MENU_ITEM (mi_sos_always));
  GtkWidget *mi_sos_never       = gtk_radio_menu_item_new_with_label (menu_group, _("Never"));
  menu_group = gtk_radio_menu_item_get_group (GTK_RADIO_MENU_ITEM (mi_sos_never));
  GtkWidget *mi_sos_last_state  = gtk_radio_menu_item_new_with_label (menu_group, _("Last state"));
  menu_group = gtk_radio_menu_item_get_group (GTK_RADIO_MENU_ITEM (mi_sos_last_state));

  gtk_menu_shell_append (GTK_MENU_SHELL (menu_show_on_startup), mi_sos_always);
  gtk_menu_shell_append (GTK_MENU_SHELL (menu_show_on_startup), mi_sos_never);
  gtk_menu_shell_append (GTK_MENU_SHELL (menu_show_on_startup), mi_sos_last_state);
  gtk_menu_item_set_submenu (GTK_MENU_ITEM (mi_show_on_startup), menu_show_on_startup);

  /* Activate check menu items */
  gtk_check_menu_item_set_active (GTK_CHECK_MENU_ITEM (mi_sos_always),
                                  (notes_window->show_on_startup == ALWAYS));
  gtk_check_menu_item_set_active (GTK_CHECK_MENU_ITEM (mi_sos_never),
                                  (notes_window->show_on_startup == NEVER));
  gtk_check_menu_item_set_active (GTK_CHECK_MENU_ITEM (mi_sos_last_state),
                                  (notes_window->show_on_startup == LAST_STATE));
  gtk_check_menu_item_set_active (GTK_CHECK_MENU_ITEM (mi_show_statusbar),
                                  notes_window->show_statusbar);
  gtk_check_menu_item_set_active (GTK_CHECK_MENU_ITEM (mi_always_on_top),
                                  notes_window->always_on_top);
  gtk_check_menu_item_set_active (GTK_CHECK_MENU_ITEM (mi_stick),
                                  notes_window->stick);

  /* Signals */
  g_signal_connect_swapped (mi_new_window,
                            "activate",
                            G_CALLBACK (notes_window_new),
                            notes_window->notes_plugin);
  g_signal_connect_swapped (mi_destroy_window,
                            "activate",
                            G_CALLBACK (notes_window_destroy),
                            notes_window);
  g_signal_connect_swapped (mi_rename_window,
                            "activate",
                            G_CALLBACK (notes_window_rename),
                            notes_window);
  g_signal_connect_swapped (mi_sos_always,
                            "activate",
                            G_CALLBACK (notes_window_set_sos_always),
                            notes_window);
  g_signal_connect_swapped (mi_sos_never,
                            "activate",
                            G_CALLBACK (notes_window_set_sos_never),
                            notes_window);
  g_signal_connect_swapped (mi_sos_last_state,
                            "activate",
                            G_CALLBACK (notes_window_set_sos_last_state),
                            notes_window);
  g_signal_connect_swapped (mi_show_statusbar,
                            "activate",
                            G_CALLBACK (notes_window_set_statusbar),
                            notes_window);
  g_signal_connect_swapped (mi_always_on_top,
                            "activate",
                            G_CALLBACK (notes_window_set_always_on_top),
                            notes_window);
  g_signal_connect_swapped (mi_stick,
                            "activate",
                            G_CALLBACK (notes_window_set_stick),
                            notes_window);

  /* Show the stuff */
  gtk_widget_show_all (notes_window->menu);
}

static gboolean
notes_window_menu_popup (NotesWindow *notes_window,
                         GdkEvent *event)
{
  if (event->type == GDK_BUTTON_PRESS)
    gtk_menu_popup (GTK_MENU (notes_window->menu),
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    event->button.button,
                    event->button.time);
  return FALSE;
}

static void
notes_window_set_sos_always (NotesWindow *notes_window)
{
  notes_window->show_on_startup = ALWAYS;
  notes_window_save_data (notes_window);
}

static void
notes_window_set_sos_never (NotesWindow *notes_window)
{
  notes_window->show_on_startup = ALWAYS;
  notes_window_save_data (notes_window);
}

static void
notes_window_set_sos_last_state (NotesWindow *notes_window)
{
  notes_window->show_on_startup = LAST_STATE;
  notes_window_save_data (notes_window);
}

static void
notes_window_set_statusbar (NotesWindow *notes_window)
{
  notes_window->show_statusbar = !notes_window->show_statusbar;
  if (notes_window->show_statusbar)
    gtk_widget_show (notes_window->statusbar);
  else
    gtk_widget_hide (notes_window->statusbar);
}

static void
notes_window_set_always_on_top (NotesWindow *notes_window)
{
  notes_window->always_on_top = !notes_window->always_on_top;
  gtk_window_set_keep_above (GTK_WINDOW (notes_window->window),
                             notes_window->always_on_top);
}

static void
notes_window_set_stick (NotesWindow *notes_window)
{
  notes_window->stick = !notes_window->stick;
  if (notes_window->stick)
    gtk_window_stick (GTK_WINDOW (notes_window->window));
  else
    gtk_window_unstick (GTK_WINDOW (notes_window->window));
}

static void
notes_window_show (NotesWindow *notes_window)
{
  if (notes_window->x != -1 && notes_window->y != -1)
    gtk_window_move (GTK_WINDOW (notes_window->window),
                     notes_window->x,
                     notes_window->y);
  gtk_window_resize (GTK_WINDOW (notes_window->window),
                     notes_window->w,
                     notes_window->h);
  gtk_window_set_keep_above (GTK_WINDOW (notes_window->window),
                             notes_window->always_on_top);
  if (notes_window->stick)
    gtk_window_stick (GTK_WINDOW (notes_window->window));
  else
    gtk_window_unstick (GTK_WINDOW (notes_window->window));

  GTK_WIDGET_UNSET_FLAGS (notes_window->notebook,
                          GTK_CAN_FOCUS);
  gtk_widget_show (notes_window->window);
}

static gboolean
notes_window_hide (NotesWindow *notes_window)
{
  gtk_window_get_position (GTK_WINDOW (notes_window->window),
                           &notes_window->x,
                           &notes_window->y);
  if (GTK_WIDGET_VISIBLE (notes_window->notebook))
    gtk_window_get_size (GTK_WINDOW (notes_window->window),
                         &notes_window->w,
                         &notes_window->h);
  else
    gtk_window_get_size (GTK_WINDOW (notes_window->window),
                         &notes_window->w,
                         NULL);
  
  gtk_widget_hide (notes_window->window);
  gtk_widget_show (notes_window->notebook);
  return FALSE;
}

static gboolean
notes_window_start_move (NotesWindow *notes_window,
                         GdkEventButton *event)
{
  if (G_LIKELY (event->type == GDK_BUTTON_PRESS))
    {
      if (event->button == 1)
        {
          /* Send to foreground and move the window */
          gdk_window_show (notes_window->window->window);
          gtk_window_begin_move_drag (GTK_WINDOW (notes_window->window),
                                      event->button,
                                      event->x_root,
                                      event->y_root,
                                      event->time);
        }
      else if (event->button == 2)
        /* Send to background */
        gdk_window_lower (notes_window->window->window);
    }

  return FALSE;
}

static gboolean
notes_window_shade (NotesWindow *notes_window,
                    GdkEventScroll *event)
{
  if (G_LIKELY (event->type == GDK_SCROLL))
    {
      if (event->direction == GDK_SCROLL_UP)
        {
          /* Hide the text view */
          if (G_LIKELY (GTK_WIDGET_VISIBLE (notes_window->notebook)))
            gtk_window_get_size (GTK_WINDOW (notes_window->window),
                                 &notes_window->w,
                                 &notes_window->h);
          if (G_LIKELY (notes_window->show_statusbar))
            gtk_widget_hide (notes_window->statusbar);
          gtk_widget_hide (notes_window->notebook);
          gtk_window_resize (GTK_WINDOW (notes_window->window),
                             notes_window->w,
                             1);
        }
      else if (event->direction == GDK_SCROLL_DOWN)
        {
          /* Show the text view */
          gtk_window_get_size (GTK_WINDOW (notes_window->window),
                               &notes_window->w,
                               NULL);
          if (notes_window->show_statusbar)
            gtk_widget_show (notes_window->statusbar);
          gtk_widget_show (notes_window->notebook);
          gtk_window_resize (GTK_WINDOW (notes_window->window),
                             notes_window->w,
                             notes_window->h);
        }
    }

  return FALSE;
}

static void
notes_window_rename (NotesWindow *notes_window)
{
}

static void
notes_window_destroy (NotesWindow *notes_window)
{
}

static void
notes_window_add_note (GtkWidget *widget,
                       NotesWindow *notes_window)
{
}

static gboolean
notes_window_delete_note (GtkWidget *widget,
                          NotesWindow *notes_window)
{
  return FALSE;
}



const gchar *
notes_note_read_name (NotesWindow *notes_window)
{
  static GDir          *dir = NULL;
  static gchar         *notes_path = NULL;
  const gchar          *window_name = NULL;
  static gchar         *path = NULL;
  const gchar          *note_name = NULL;

  TRACE ("NotesWindow: %p", notes_window);
  if (G_UNLIKELY (dir == NULL))
    {
      if (G_UNLIKELY (notes_path == NULL))
        {
          notes_path = notes_window->notes_plugin->notes_path;
          window_name = gtk_label_get_text (GTK_LABEL (notes_window->title));
          path = g_build_path (G_DIR_SEPARATOR_S,
                               notes_path,
                               window_name,
                               NULL);
          TRACE ("path: %s", path);
        }

      if (G_UNLIKELY (!g_file_test (path, (G_FILE_TEST_EXISTS | G_FILE_TEST_IS_DIR))))
        g_mkdir (path, 0755);

      dir = g_dir_open (path, 0, NULL);
    }

  note_name = g_dir_read_name (dir);
  TRACE ("note_name: %s", note_name);
  if (G_UNLIKELY (note_name == NULL))
    {
      g_dir_close (dir);
      dir = NULL;
      g_free (path);
    }

  return note_name;
}

/**
 * notes_note_new:
 * @notes_window    : a NotesWindow pointer
 * @notes_note_name : the name of the notes to open
 * or %NULL to create a new note
 *
 * Create a new note.
 *
 * Return value: a pointer to a new allocated NotesNote.
 **/
NotesNote *
notes_note_new (NotesWindow *notes_window,
                const gchar *notes_note_name)
{
  DBG ("New note: %s", notes_note_name);

  NotesNote            *notes_note;
  GtkTextBuffer        *buffer;

  notes_note = g_slice_new0 (NotesNote);
  notes_note->notes_window = notes_window;
  notes_window->notes = g_slist_prepend (notes_window->notes, notes_note);

  /* Label */
  GtkWidget *eb_border = gtk_event_box_new ();
  gtk_container_set_border_width (GTK_CONTAINER (eb_border), 3);
  gtk_event_box_set_visible_window (GTK_EVENT_BOX (eb_border), FALSE);
  notes_note->title = gtk_label_new (notes_note_name);
  gtk_container_add (GTK_CONTAINER (eb_border),
                     notes_note->title);

  /* Scrolled window */
  notes_note->scrolled_window = gtk_scrolled_window_new (NULL, NULL);
  gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW (notes_note->scrolled_window),
                                  GTK_POLICY_AUTOMATIC,
                                  GTK_POLICY_AUTOMATIC);

  /* Text view */
  notes_note->text_view = gtk_text_view_new ();
  buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (notes_note->text_view));
  gtk_text_view_set_wrap_mode (GTK_TEXT_VIEW (notes_note->text_view), GTK_WRAP_WORD);
  gtk_container_add (GTK_CONTAINER (notes_note->scrolled_window),
                     notes_note->text_view);

  /* Notebook */
  gtk_notebook_append_page (GTK_NOTEBOOK (notes_window->notebook),
                            notes_note->scrolled_window,
                            eb_border);
  /* gtk_notebook_set_show_tabs (GTK_NOTEBOOK (notes_window->notebook),
                              (gboolean) g_slist_length (notes_window->notes)); FIXME */

  /* Signals FIXME */
  g_signal_connect (notes_note->text_view,
                    "key-press-event",
                    G_CALLBACK (notes_note_key_pressed),
                    notes_note);
  g_signal_connect (buffer,
                    "changed",
                    G_CALLBACK (notes_note_buffer_changed),
                    notes_note);
  g_signal_connect (eb_border,
                    "button-press-event",
                    G_CALLBACK (notes_note_rename),
                    notes_note);

  /* Load data */
  notes_note_load_data (notes_note, buffer);

  /* Show the stuff */
  /* gtk_widget_show_all (eb_border); XXX */
  gtk_widget_show_all (notes_note->scrolled_window);

  return notes_note;
}

void
notes_note_load_data (NotesNote *notes_note,
                      GtkTextBuffer *buffer)
{
  const gchar          *note_name;
  gchar                *note_name_tmp;
  gchar                *filename;
  gchar                *contents = NULL;

  note_name = gtk_label_get_text (GTK_LABEL (notes_note->title));
  if (G_UNLIKELY (g_ascii_strncasecmp (note_name, "", 1) == 0))
    {
      guint id = g_slist_length (notes_note->notes_window->notes);
      note_name_tmp = g_strdup_printf ("%d", id);
      gtk_label_set_text (GTK_LABEL (notes_note->title), note_name_tmp);
      note_name = gtk_label_get_text (GTK_LABEL (notes_note->title));
      g_free (note_name_tmp);
    }

  filename = g_build_path (G_DIR_SEPARATOR_S,
                           notes_note->notes_window->notes_plugin->notes_path,
                           notes_note->notes_window->title,
                           note_name,
                           NULL);

  if (G_LIKELY (g_file_get_contents (filename, &contents, NULL, NULL)))
    {
      gtk_text_buffer_set_text (buffer, contents, -1);
      gtk_text_view_set_buffer (GTK_TEXT_VIEW (notes_note->text_view), buffer);
    }

  g_free (contents);
  g_free (filename);
}

static gboolean
notes_note_key_pressed (GtkWidget *widget,
                        GdkEventKey *event,
                        NotesNote *notes_note)
{
  return FALSE;
}

static void
notes_note_buffer_changed (GtkWidget *widget,
                           NotesNote *notes_note)
{
}

static gboolean
notes_note_rename (GtkWidget *widget,
                   GdkEventButton *event,
                   NotesNote *notes_note)
{
  return FALSE;
}

