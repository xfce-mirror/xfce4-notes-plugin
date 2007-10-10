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



static void         notes_plugin_register   (XfcePanelPlugin *panel_plugin);

static NotesPlugin *notes_plugin_new        (XfcePanelPlugin *panel_plugin);

static void         notes_plugin_load_data  (NotesPlugin *notes_plugin);

static gboolean     notes_plugin_set_size   (NotesPlugin *notes_plugin, 
                                             int size);
static void         notes_plugin_save       (NotesPlugin *notes_plugin);

static void         notes_plugin_free       (NotesPlugin *notes_plugin);

static gboolean     notes_plugin_popup      (NotesPlugin *notes_plugin);

/* TODO sort the next functions */
/*static gboolean     save_on_timeout_execute (NotesPlugin *notes_plugin);

static void         save_on_timeout         (NotesPlugin *notes);*/




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
  /* notes_plugin->timeout_id = 0; FIXME */

  notes_plugin->btn_panel = xfce_create_panel_button ();
  notes_plugin->icon = gtk_image_new ();
  notes_plugin->tooltips = gtk_tooltips_new ();

  gtk_container_add (GTK_CONTAINER (notes_plugin->btn_panel),
                     notes_plugin->icon);
  gtk_container_add (GTK_CONTAINER (panel_plugin),
                     notes_plugin->btn_panel);

  g_signal_connect_swapped (panel_plugin,
                            "size-changed",
                            G_CALLBACK (notes_plugin_set_size),
                            notes_plugin);
  g_signal_connect (notes_plugin->btn_panel,
                    "clicked",
                    G_CALLBACK (notes_plugin_popup),
                    notes_plugin);
  g_signal_connect_swapped (panel_plugin,
                            "save",
                            G_CALLBACK (notes_plugin_save),
                            notes_plugin);
  g_signal_connect (panel_plugin,
                    "free-data",
                    G_CALLBACK (notes_plugin_free),
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
      TRACE ("window_name: %s", window_name);
      notes_window = notes_window_new (notes_plugin, window_name);
      if (G_UNLIKELY (window_name != NULL))
        /* If there was no window, don't try to read again since
         * a first window has been created and would be read again. */
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
  gtk_image_set_from_pixbuf (GTK_IMAGE (notes_plugin->icon), pixbuf);
  g_object_unref (G_OBJECT (pixbuf));

  return TRUE;
}

static void
notes_plugin_save (NotesPlugin *notes_plugin)
{
  g_slist_foreach (notes_plugin->windows, (GFunc)notes_window_save, NULL);
}

static void
notes_plugin_free (NotesPlugin *notes_plugin)
{
  /* if (notes->timeout_id > 0)
    g_source_remove (notes->timeout_id); FIXME */

  notes_plugin_save (notes_plugin);
  gtk_main_quit ();
}

static gboolean
notes_plugin_popup (NotesPlugin *notes_plugin)
{
  return FALSE;
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

