/* $Id$
 *
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2003  Jakob Henriksson <b0kaj+dev@lysator.liu.se>
 *  Copyright (C) 2006  Mike Massonnet <mmassonnet@gmail.com>
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

#ifdef HAVE_STRING_H
#include <string.h>
#endif

#include <stdlib.h>
#include <gtk/gtk.h>
#include <libxfcegui4/libxfcegui4.h>
#include <libxfce4panel/xfce-panel-plugin.h>
#include <libxfce4panel/xfce-panel-convenience.h>

#include "notes.h"

#define PLUGIN_NAME "xfce4-notes-plugin"



static void             notes_plugin_register           (XfcePanelPlugin *panel_plugin);

static NotesPlugin     *notes_plugin_new                (XfcePanelPlugin *panel_plugin);

static void             notes_plugin_load_data          (NotesPlugin *notes_plugin);

static void             notes_plugin_save_data          (NotesPlugin *notes_plugin);

static void             notes_plugin_free               (NotesPlugin *notes_plugin);

static gboolean         notes_plugin_set_size           (NotesPlugin *notes_plugin, 
                                                         int size);
static void             notes_plugin_menu_new           (NotesPlugin *notes_plugin);

static gboolean         notes_plugin_menu_popup         (NotesPlugin *notes_plugin,
                                                         GdkEvent *event);
static void             notes_plugin_menu_position      (GtkMenu *menu,
                                                         gint *x0,
                                                         gint *y0,
                                                         gboolean *push_in,
                                                         gpointer user_data);
static void             notes_plugin_menu_destroy       (NotesPlugin *notes_plugin);

/* TODO sort the next functions */
/*static gboolean         save_on_timeout_execute         (NotesPlugin *notes_plugin);

static void             save_on_timeout                 (NotesPlugin *notes);*/




static void
notes_plugin_register (XfcePanelPlugin *panel_plugin)
{
  DBG ("\nProperties: size = %d, screen_position = %d",
       xfce_panel_plugin_get_size (panel_plugin),
       xfce_panel_plugin_get_screen_position (panel_plugin));

  xfce_textdomain (GETTEXT_PACKAGE, PACKAGE_LOCALE_DIR, "UTF-8");

  NotesPlugin *notes_plugin = notes_plugin_new (panel_plugin);
  g_return_if_fail (G_LIKELY (notes_plugin != NULL));
  notes_plugin_load_data (notes_plugin);
}

static NotesPlugin *
notes_plugin_new (XfcePanelPlugin *panel_plugin)
{
  NotesPlugin *notes_plugin = g_slice_new0 (NotesPlugin);
  notes_plugin->panel_plugin = panel_plugin;
  notes_plugin->windows = NULL;
  /* notes_plugin->timeout_id = 0; FIXME */

  notes_plugin->btn_panel = xfce_create_panel_toggle_button ();
  notes_plugin->icon_panel = gtk_image_new ();
  notes_plugin->tooltips = gtk_tooltips_new ();

  gtk_container_add (GTK_CONTAINER (notes_plugin->btn_panel),
                     notes_plugin->icon_panel);
  gtk_container_add (GTK_CONTAINER (panel_plugin),
                     notes_plugin->btn_panel);

  g_signal_connect_swapped (panel_plugin,
                            "size-changed",
                            G_CALLBACK (notes_plugin_set_size),
                            notes_plugin);
  g_signal_connect_swapped (panel_plugin,
                            "save",
                            G_CALLBACK (notes_plugin_save_data),
                            notes_plugin);
  g_signal_connect_swapped (panel_plugin,
                            "free-data",
                            G_CALLBACK (notes_plugin_free),
                            notes_plugin);
  g_signal_connect_swapped (notes_plugin->btn_panel,
                            "event",
                            G_CALLBACK (notes_plugin_menu_popup),
                            notes_plugin);

  xfce_panel_plugin_add_action_widget (panel_plugin, notes_plugin->btn_panel);
  gtk_widget_show_all (notes_plugin->btn_panel);

  return notes_plugin;
}

static void
notes_plugin_load_data (NotesPlugin *notes_plugin)
{
  NotesWindow          *notes_window;
  const gchar          *window_name;

  notes_plugin->notes_path =
    xfce_resource_save_location (XFCE_RESOURCE_DATA,
                                 "notes/",
                                 TRUE);
  g_return_if_fail (G_LIKELY (notes_plugin->notes_path != NULL));

  notes_plugin->config_file =
    xfce_panel_plugin_save_location (notes_plugin->panel_plugin,
                                     TRUE);
  g_return_if_fail (G_LIKELY (notes_plugin->config_file != NULL));

  DBG ("\nLook up file: %s\nNotes path: %s", notes_plugin->config_file,
                                           notes_plugin->notes_path);
  window_name = notes_window_read_name (notes_plugin);
  do
    {
      notes_window = notes_window_new_with_label (notes_plugin, window_name);
      if (G_UNLIKELY (NULL != window_name))
        /**
         * If there was no window, don't try to read again since
         * a first window has been created and would be duplicated.
         **/
        window_name = notes_window_read_name (notes_plugin);
    }
  while (G_LIKELY (window_name != NULL));
}

static gboolean
notes_plugin_set_size (NotesPlugin *notes_plugin,
                       int size)
{
  DBG ("Set size to %d", size);

  gtk_widget_set_size_request (notes_plugin->btn_panel, size, size);
  size = size - 2 - (2 * MAX (notes_plugin->btn_panel->style->xthickness,
                              notes_plugin->btn_panel->style->ythickness));
  GdkPixbuf *pixbuf = xfce_themed_icon_load ("xfce4-notes-plugin", size);
  gtk_image_set_from_pixbuf (GTK_IMAGE (notes_plugin->icon_panel), pixbuf);
  g_object_unref (G_OBJECT (pixbuf));

  return TRUE;
}

static void
notes_plugin_save_data (NotesPlugin *notes_plugin)
{
  g_slist_foreach (notes_plugin->windows, (GFunc)notes_window_save_data, NULL);
}

static void
notes_plugin_free (NotesPlugin *notes_plugin)
{
  /* if (notes->timeout_id > 0)
    g_source_remove (notes->timeout_id); FIXME */

  notes_plugin_save_data (notes_plugin);
  gtk_main_quit ();
}

static void
notes_plugin_menu_new (NotesPlugin *notes_plugin)
{
  guint                 i = 0;
  NotesWindow          *notes_window;

  notes_plugin->menu = gtk_menu_new ();

  while ((notes_window = (NotesWindow *)g_slist_nth_data (notes_plugin->windows, i++)) != NULL)
    {
      TRACE ("notes_window (%d): %p", (i-1), notes_window);
      GtkWidget *mi_foo = gtk_image_menu_item_new_with_label (notes_window->name);
      GtkWidget *icon = gtk_image_new_from_icon_name ("xfce4-notes-plugin",
                                                      GTK_ICON_SIZE_MENU);
      gtk_widget_set_sensitive (icon, GTK_WIDGET_VISIBLE (notes_window->window));

      gtk_image_menu_item_set_image (GTK_IMAGE_MENU_ITEM (mi_foo), icon);

      g_signal_connect_swapped (mi_foo,
                                "activate",
                                G_CALLBACK (notes_window_show),
                                notes_window);

      gtk_menu_shell_append (GTK_MENU_SHELL (notes_plugin->menu), mi_foo);
    }

  gtk_menu_attach_to_widget (GTK_MENU (notes_plugin->menu),
                             notes_plugin->btn_panel,
                             NULL);
  gtk_menu_set_screen (GTK_MENU (notes_plugin->menu),
                      gtk_widget_get_screen (notes_plugin->btn_panel));
  xfce_panel_plugin_register_menu (notes_plugin->panel_plugin,
                                   GTK_MENU (notes_plugin->menu));

  g_signal_connect_swapped (notes_plugin->menu,
                            "deactivate",
                            G_CALLBACK (notes_plugin_menu_destroy),
                            notes_plugin);

  gtk_widget_show_all (notes_plugin->menu);
}

static gboolean
notes_plugin_menu_popup (NotesPlugin *notes_plugin,
                         GdkEvent *event)
{
  /**
   * If GDK_CONTROL_MASK is set the panel displays its context menu
   * therefore we prefer to *not* popup our menu.
   */
  if (event->type == GDK_BUTTON_PRESS &&
      event->button.button == 1 && !(event->button.state & GDK_CONTROL_MASK))
    {
      gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (notes_plugin->btn_panel), TRUE);
      notes_plugin_menu_new (notes_plugin);
      gtk_menu_popup (GTK_MENU (notes_plugin->menu),
                      NULL,
                      NULL,
                      (GtkMenuPositionFunc) notes_plugin_menu_position,
                      notes_plugin,
                      event->button.button,
                      event->button.time);
    }
  return FALSE;
}

static void
notes_plugin_menu_position (GtkMenu *menu,
                            gint *x,
                            gint *y,
                            gboolean *push_in,
                            gpointer user_data)
{
  NotesPlugin          *notes_plugin;
  GtkRequisition        requisition;
  GtkOrientation        orientation;

  notes_plugin = (NotesPlugin *)user_data;
  g_return_if_fail (GTK_IS_MENU (menu));
  g_return_if_fail (NULL != notes_plugin);

  orientation = xfce_panel_plugin_get_orientation (notes_plugin->panel_plugin);
  gtk_widget_size_request (GTK_WIDGET (menu), &requisition);
  gdk_window_get_origin (notes_plugin->btn_panel->window, x, y);

  switch (orientation)
    {
    case GTK_ORIENTATION_HORIZONTAL:
      if (*y + notes_plugin->btn_panel->allocation.height + requisition.height > gdk_screen_height ())
        /* Show menu above */
        *y -= requisition.height;
      else
        /* Show menu below */
        *y += notes_plugin->btn_panel->allocation.height;

      if (*x + requisition.width > gdk_screen_width ())
        /* Adjust horizontal position */
        *x = gdk_screen_width () - requisition.width;
      break;

    case GTK_ORIENTATION_VERTICAL:
      if (*x + notes_plugin->btn_panel->allocation.width + requisition.width > gdk_screen_width ())
        /* Show menu on the right */
        *x -= requisition.width;
      else
        /* Show menu on the left */
        *x += notes_plugin->btn_panel->allocation.width;

      if (*y + requisition.height > gdk_screen_height ())
        /* Adjust vertical position */
        *y = gdk_screen_height () - requisition.height;
      break;

    default:
      break;
    }
}

static void
notes_plugin_menu_destroy (NotesPlugin *notes_plugin)
{
  DBG ("Dettach window menu");
  gtk_menu_detach (GTK_MENU (notes_plugin->menu));
  gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (notes_plugin->btn_panel), FALSE);
}



XFCE_PANEL_PLUGIN_REGISTER_EXTERNAL (notes_plugin_register);

/* TODO sort the next functions */

/*static gboolean
save_on_timeout_execute (NotesPlugin *notes)
{
  notes_save (notes->plugin, notes);
  return FALSE;
}

static void
save_on_timeout (NotesPlugin *notes)
{
  if (notes->timeout_id > 0)
    {
      g_source_remove (notes->timeout_id);
      notes->timeout_id = 0;
    }
  notes->timeout_id = g_timeout_add (60000, (GSourceFunc) save_on_timeout_execute, notes);
}*/

