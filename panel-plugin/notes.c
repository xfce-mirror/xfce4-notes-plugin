/* $Id$
 *
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2003  Jakob Henriksson <b0kaj+dev@lysator.liu.se>
 *                2006  Mike Massonnet <mmassonnet@gmail.com>
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

#include <stdlib.h>
#include <gtk/gtk.h>
#include <libxfcegui4/libxfcegui4.h>

#include <libxfce4panel/xfce-panel-plugin.h>
#include <libxfce4panel/xfce-panel-convenience.h>

#include "note.h"
#include "notes.h"

#define PLUGIN_NAME "xfce4-notes-plugin"


/* Panel Plugin Interface */

XFCE_PANEL_PLUGIN_REGISTER_EXTERNAL(notes_construct);


/* internal functions */

static void 
notes_free_data (XfcePanelPlugin *plugin, NotesPlugin *notes)
{
    if (notes->timeout_id > 0)
        g_source_remove (notes->timeout_id);

    notes_save (plugin, notes);

    DBG ("Free data: %s", PLUGIN_NAME);
    gtk_main_quit ();
}

static void 
notes_save (XfcePanelPlugin *plugin, NotesPlugin *notes)
{
    char *file;
    XfceRc *rc;

    GtkTextBuffer *buffer;
    GtkTextIter start, end;
    gchar *text;

    DBG ("Save: %s", PLUGIN_NAME);

    if (!(file = xfce_panel_plugin_save_location (plugin, TRUE)))
        return;

    rc = xfce_rc_simple_open (file, FALSE);
    g_free (file);

    if (rc)
      {
        buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (notes->note->text));
        gtk_text_buffer_get_bounds (buffer, &start, &end);
        text = gtk_text_buffer_get_text (GTK_TEXT_BUFFER (buffer), &start, 
                                         &end, TRUE);

        xfce_rc_write_entry (rc, "note", text);
        g_free (text);

        if (GTK_WIDGET_VISIBLE (notes->note->window))
          {
            gtk_window_get_position (GTK_WINDOW (notes->note->window), 
                                     &notes->note->x, &notes->note->y);
          }

        xfce_rc_write_int_entry (rc, "pos_x", notes->note->x);
        xfce_rc_write_int_entry (rc, "pos_y", notes->note->y);

        xfce_rc_close (rc);
      }
}

gboolean
save_on_timeout (NotesPlugin *notes)
{
    notes_save (notes->plugin, notes);

    return FALSE;
}

static void
notes_configure (XfcePanelPlugin *plugin, NotesPlugin *notes)
{
    DBG ("Configure: %s", PLUGIN_NAME);
}

static gboolean 
notes_set_size (XfcePanelPlugin *plugin, int size, NotesPlugin *notes)
{
    GdkPixbuf *pixbuf;

    DBG ("Set size to %d: %s", size, PLUGIN_NAME);

    gtk_widget_set_size_request (notes->button, size, size);

    size = size - 2 - (2 * MAX (notes->button->style->xthickness,
                                notes->button->style->ythickness));
    pixbuf = xfce_themed_icon_load (GTK_STOCK_EDIT, size);
    gtk_image_set_from_pixbuf (GTK_IMAGE (notes->icon), pixbuf);
    g_object_unref (G_OBJECT (pixbuf));

    return TRUE;
}


/* create widgets and connect to signals */ 

static void 
notes_construct (XfcePanelPlugin *plugin)
{
    NotesPlugin *notes;
    
    xfce_textdomain (GETTEXT_PACKAGE, PACKAGE_LOCALE_DIR, "UTF-8"); 

    DBG ("Construct: %s", PLUGIN_NAME);
    
    DBG ("Properties: size = %d, panel_position = %d", 
         xfce_panel_plugin_get_size (plugin),
         xfce_panel_plugin_get_screen_position (plugin));

    notes = notes_new (plugin);
    
    gtk_container_add (GTK_CONTAINER (plugin), notes->button);

    xfce_panel_plugin_add_action_widget (plugin, notes->button);

    g_signal_connect (plugin, "free-data", 
                      G_CALLBACK (notes_free_data), notes);

    g_signal_connect (notes->button, "toggled",
                      G_CALLBACK (notes_button_toggled), notes);

    g_signal_connect (plugin, "save", 
                      G_CALLBACK (notes_save), notes);

    g_signal_connect (plugin, "size-changed", 
                      G_CALLBACK (notes_set_size), notes);

    xfce_panel_plugin_menu_show_configure (plugin);
    g_signal_connect (plugin, "configure-plugin", 
                      G_CALLBACK (notes_configure), notes);
}

NotesPlugin *
notes_new (XfcePanelPlugin *plugin)
{
    NotesPlugin *notes;
    GtkTextBuffer *buffer;

    DBG ("New Notes Plugin");

    notes = g_new0 (NotesPlugin, 1);
    
    notes->plugin = plugin;
    notes->timeout_id = 0;
    
    notes->button = xfce_create_panel_toggle_button ();
    gtk_widget_show (notes->button);

    notes->icon = gtk_image_new ();
    gtk_widget_show (notes->icon);
    gtk_container_add (GTK_CONTAINER (notes->button), notes->icon);

    notes->tooltips = gtk_tooltips_new ();
    gtk_tooltips_set_tip (GTK_TOOLTIPS (notes->tooltips), notes->button, 
                          _("Notes\nClick this button to show/hide your notes"),
                          NULL);

    notes->note = note_new (plugin);

    g_signal_connect (notes->note->close_button, "clicked", 
                      G_CALLBACK (on_note_close), notes->button);

    g_signal_connect (notes->note->text, "key-press-event", 
                      G_CALLBACK (on_note_key_press), notes);

    buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (notes->note->text));
    g_signal_connect (buffer, "changed", G_CALLBACK (on_note_changed), notes);

    return notes;
}

static void
notes_button_toggled (XfcePanelPlugin *plugin, NotesPlugin *notes)
{
    /* Show/hide the note */
    if (gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (notes->button)))
      {
        gtk_window_move (GTK_WINDOW (notes->note->window), notes->note->x, 
                                     notes->note->y);

        gtk_widget_show (notes->note->window);

        gtk_window_set_keep_above (GTK_WINDOW (notes->note->window), FALSE);
        gtk_window_stick (GTK_WINDOW (notes->note->window));
      }
    else
      {
        gtk_window_get_position (GTK_WINDOW (notes->note->window), 
                                 &notes->note->x, &notes->note->y);

        gtk_widget_hide (notes->note->window);
      }
}

static void
on_note_close (GtkWidget *widget, GtkToggleButton *panel_button)
{
    gtk_toggle_button_set_active (panel_button, FALSE);
}

static gboolean
on_note_key_press (GtkWidget *widget, GdkEventKey *event, NotesPlugin *notes)
{
    if (event->type == GDK_KEY_PRESS && event->keyval == GDK_Escape)
        on_note_close (widget, GTK_TOGGLE_BUTTON (notes->button));

    return FALSE;
}

static void
on_note_changed (GtkWidget *widget, NotesPlugin *notes)
{
    if (notes->timeout_id > 0)
      {
        g_source_remove (notes->timeout_id);
        notes->timeout_id = 0;
      }

    notes->timeout_id = g_timeout_add (5000, (GSourceFunc) save_on_timeout, 
                                       notes);
}
