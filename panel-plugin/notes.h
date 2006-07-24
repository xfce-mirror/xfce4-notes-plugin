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

#ifndef NOTES_H
#define NOTES_H

#include <gdk/gdkkeysyms.h>

#include "note.h"

typedef struct
{
    XfcePanelPlugin *plugin;
    
    GtkWidget *button;
    GtkWidget *icon;
    GtkTooltips *tooltips;

    Note *note;

    gboolean show;
}
NotesPlugin;

NotesPlugin *   notes_new (XfcePanelPlugin *);
static void     notes_button_toggled (XfcePanelPlugin *, NotesPlugin *);
static void     on_note_close (GtkWidget *, GtkToggleButton *);
static gboolean on_note_key_press (GtkWidget *, GdkEventKey *, 
                                   GtkToggleButton *);

NotesPlugin *
notes_new (XfcePanelPlugin *plugin)
{
    NotesPlugin *notes;

    DBG ("New Notes Plugin");

    notes = g_new0 (NotesPlugin, 1);
    
    notes->plugin = plugin;
    
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
                      G_CALLBACK (on_note_key_press), notes->button);

    return notes;
}

static void
notes_button_toggled (XfcePanelPlugin *plugin, NotesPlugin *notes)
{
    /* Show/hide the note */
    if (gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (notes->button)))
      {
        gtk_widget_show (notes->note->window);

        gtk_window_set_keep_above (GTK_WINDOW (notes->note->window), TRUE);
        gtk_window_stick (GTK_WINDOW (notes->note->window));
        gtk_window_move (GTK_WINDOW (notes->note->window), notes->note->x, 
                                     notes->note->y);
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
on_note_key_press (GtkWidget *widget, GdkEventKey *event, 
                   GtkToggleButton *panel_button)
{
    if (event->type == GDK_KEY_PRESS)
        if (event->keyval == GDK_Escape)
            on_note_close (widget, panel_button);

    return FALSE;
}

#endif

