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

#ifdef HAVE_STRING_H
#include <string.h>
#endif

#include <stdlib.h>
#include <gtk/gtk.h>
#include <libxfcegui4/libxfcegui4.h>

#include <libxfce4panel/xfce-panel-plugin.h>
#include <libxfce4panel/xfce-panel-convenience.h>

#include "notes.h"
#include "notes-options.h"
#include "xfce4-popup-notes.h"

#define PLUGIN_NAME "xfce4-notes-plugin"


static void         notes_construct         (XfcePanelPlugin *);

static void         notes_free_data         (XfcePanelPlugin *,
                                             NotesPlugin *);
static void         notes_save              (XfcePanelPlugin *,
                                             NotesPlugin *);
static gboolean     save_on_timeout_execute (NotesPlugin *);

static void         notes_configure         (XfcePanelPlugin *, 
                                             NotesPlugin *);
static gboolean     notes_set_size          (XfcePanelPlugin *, 
                                             int size, 
                                             NotesPlugin *);
static void         notes_load_data         (XfcePanelPlugin *, 
                                             NotesPlugin *);
static gboolean     notes_button_clicked    (XfcePanelPlugin *, 
                                             NotesPlugin *);
static void         on_options_response     (GtkWidget *,
                                             int response, 
                                             NotesPlugin *);
static gboolean     notes_message_received  (GtkWidget *, 
                                             GdkEventClient *,
                                             gpointer data);
static gboolean     notes_set_selection     (NotesPlugin *notes);


/* Panel Plugin Interface */

XFCE_PANEL_PLUGIN_REGISTER_EXTERNAL (notes_construct);


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
    gint id;
    NotePage *page;
    GList *pages;
    GtkTextBuffer *buffer;
    GtkTextIter start, end;
    gchar *text;
    const gchar *label;
    gchar note_entry[12], label_entry[13];

    DBG ("Save: %s", PLUGIN_NAME);

    file = xfce_resource_save_location (XFCE_RESOURCE_CONFIG, 
                                        "xfce4/panel/notes.rc", TRUE);
    if (G_UNLIKELY (!file))
        return;

    rc = xfce_rc_simple_open (file, FALSE);
    g_free (file);

    if (rc)
      {
        if (GTK_WIDGET_VISIBLE (notes->note->window))
          {
            gtk_window_get_position (GTK_WINDOW (notes->note->window),
                                     &notes->note->x, &notes->note->y);
            if (GTK_WIDGET_VISIBLE (notes->note->notebook))
                gtk_window_get_size (GTK_WINDOW (notes->note->window),
                                     &notes->note->w, &notes->note->h);
            else
                gtk_window_get_size (GTK_WINDOW (notes->note->window),
                                     &notes->note->w, NULL);
          }

        xfce_rc_set_group (rc, "settings");

        xfce_rc_write_int_entry (rc, "pos_x", notes->note->x);
        xfce_rc_write_int_entry (rc, "pos_y", notes->note->y);
        xfce_rc_write_int_entry (rc, "width", notes->note->w);
        xfce_rc_write_int_entry (rc, "height", notes->note->h);

        xfce_rc_write_bool_entry (rc, "visible", GTK_WIDGET_VISIBLE (notes->note->window));
        xfce_rc_write_bool_entry (rc, "show", notes->options.show);
        xfce_rc_write_bool_entry (rc, "task_switcher", notes->options.task_switcher);
        xfce_rc_write_bool_entry (rc, "always_on_top", notes->options.always_on_top);
        xfce_rc_write_bool_entry (rc, "stick", notes->options.stick);
        xfce_rc_write_bool_entry (rc, "statusbar", notes->options.statusbar);

        pages = notes->note->pages;
        xfce_rc_set_group (rc, "notes");

        for (id = 0, page = (NotePage *)g_list_nth_data (pages, id);
             page != NULL;
             id++, page = (NotePage *)g_list_nth_data (pages, id))
          {
            if (page->label_dirty)
              {
                label = gtk_label_get_text (GTK_LABEL (page->label));
                g_snprintf (label_entry, 13, "label%d", id);

                xfce_rc_write_entry (rc, label_entry, label);

                DBG ("Label %d: %s", id, label);
              }

            g_snprintf (note_entry, 12, "note%d", id);
            buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (page->text));
            gtk_text_buffer_get_bounds (buffer, &start, &end);
            text = gtk_text_buffer_get_text (GTK_TEXT_BUFFER (buffer), &start,
                                             &end, TRUE);

            DBG ("Note %d (%s): %s", id, note_entry, text);
            xfce_rc_write_entry (rc, note_entry, text);
            g_free (text);
          }

        xfce_rc_close (rc);
      }
}

static gboolean
save_on_timeout_execute (NotesPlugin *notes)
{
    notes_save (notes->plugin, notes);

    return FALSE;
}

void
save_on_timeout (NotesPlugin *notes)
{
    if (notes->timeout_id > 0)
      {
        g_source_remove (notes->timeout_id);
        notes->timeout_id = 0;
      }

    notes->timeout_id = g_timeout_add (60000,
                                       (GSourceFunc) save_on_timeout_execute,
                                       notes);
}

static void
notes_configure (XfcePanelPlugin *plugin, NotesPlugin *notes)
{
    GtkWidget *dialog;

    DBG ("Configure: %s", PLUGIN_NAME);

    xfce_panel_plugin_block_menu (plugin);
    dialog = notes_options_new (notes);

    g_object_set_data (G_OBJECT (notes->plugin), "configure", dialog);

    g_signal_connect (dialog, "response", G_CALLBACK (on_options_response),
                      notes);
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

    notes_set_selection (notes);

    gtk_container_add (GTK_CONTAINER (plugin), notes->button);

    xfce_panel_plugin_add_action_widget (plugin, notes->button);

    g_signal_connect (plugin, "free-data",
                      G_CALLBACK (notes_free_data), notes);

    g_signal_connect (notes->button, "clicked",
                      G_CALLBACK (notes_button_clicked), notes);

    g_signal_connect (plugin, "save",
                      G_CALLBACK (notes_save), notes);

    g_signal_connect (plugin, "size-changed",
                      G_CALLBACK (notes_set_size), notes);

    xfce_panel_plugin_menu_show_configure (plugin);
    g_signal_connect (plugin, "configure-plugin",
                      G_CALLBACK (notes_configure), notes);

    if (notes->options.show || notes->options.visible)
        gtk_button_clicked (GTK_BUTTON (notes->button));
}

NotesPlugin *
notes_new (XfcePanelPlugin *plugin)
{
    NotesPlugin *notes;

    DBG ("New Notes Plugin");

    notes = g_new0 (NotesPlugin, 1);

    notes->plugin = plugin;
    notes->timeout_id = 0;

    notes->button = xfce_create_panel_button ();
    gtk_widget_show (notes->button);

    notes->icon = gtk_image_new ();
    gtk_widget_show (notes->icon);
    gtk_container_add (GTK_CONTAINER (notes->button), notes->icon);

    notes->tooltips = gtk_tooltips_new ();
    gtk_tooltips_set_tip (GTK_TOOLTIPS (notes->tooltips), notes->button,
                          _("Notes"), NULL);

    notes->note = note_new (notes);
    notes_load_data (plugin, notes);

    return notes;
}

static void
notes_load_data (XfcePanelPlugin *plugin, NotesPlugin *notes)
{
    gchar *file;
    XfceRc *rc;
    gchar note_entry[12];
    gint id;

    file = xfce_resource_save_location (XFCE_RESOURCE_CONFIG, 
                                        "xfce4/panel/notes.rc", TRUE);
    if (G_UNLIKELY (!file))
        return;

    DBG ("Look up file (%s)", file);

    rc = xfce_rc_simple_open (file, FALSE);
    g_free (file);

    if (rc)
      {
        id = 0;
        g_snprintf (note_entry, 12, "note%d", id++);
        xfce_rc_set_group (rc, "notes");
        while (xfce_rc_has_entry (rc, note_entry))
          {
            note_page_new (plugin, notes);
            g_snprintf (note_entry, 12, "note%d", id++);
          }
        if (id == 1 && !xfce_rc_has_entry (rc, note_entry))
            note_page_new (plugin, notes);

        xfce_rc_set_group (rc, "settings");

        notes->note->x = xfce_rc_read_int_entry (rc, "pos_x", -1);
        notes->note->y = xfce_rc_read_int_entry (rc, "pos_y", -1);
        notes->note->w = xfce_rc_read_int_entry (rc, "width", 242);
        notes->note->h = xfce_rc_read_int_entry (rc, "height", 200);

        notes->options.visible = xfce_rc_read_bool_entry (rc, "visible", FALSE);
        notes->options.show = xfce_rc_read_bool_entry (rc, "show", FALSE);
        notes->options.task_switcher = xfce_rc_read_bool_entry (rc, "task_switcher", TRUE);
        notes->options.always_on_top = xfce_rc_read_bool_entry (rc, "always_on_top", FALSE);
        notes->options.stick = xfce_rc_read_bool_entry (rc, "stick", TRUE);
        notes->options.statusbar = xfce_rc_read_bool_entry (rc, "statusbar", TRUE);

        xfce_rc_close (rc);
      }
}

static gboolean
notes_button_clicked (XfcePanelPlugin *plugin, NotesPlugin *notes)
{
    DBG ("Notes Button Clicked");

    /* Show/hide the note */
    if (!GTK_WIDGET_VISIBLE (notes->note->window))
      {
        if (notes->note->x != -1 && notes->note->y != -1)
            gtk_window_move (GTK_WINDOW (notes->note->window), notes->note->x,
                                         notes->note->y);
        gtk_window_resize (GTK_WINDOW (notes->note->window), notes->note->w,
                           notes->note->h);

        GTK_WIDGET_UNSET_FLAGS (notes->note->notebook, GTK_CAN_FOCUS);

        gtk_widget_show_all (notes->note->window);

        gtk_window_set_keep_above (GTK_WINDOW (notes->note->window),
                                   notes->options.always_on_top);

        if (notes->options.stick)
            gtk_window_stick (GTK_WINDOW (notes->note->window));
        else
            gtk_window_unstick (GTK_WINDOW (notes->note->window));

        if (!notes->options.task_switcher)
          {
            gtk_window_set_skip_pager_hint (GTK_WINDOW (notes->note->window), TRUE);
            gtk_window_set_skip_taskbar_hint (GTK_WINDOW (notes->note->window), TRUE);
          }

        if (!notes->options.statusbar)
          {
            gtk_widget_hide (notes->note->statusbar);
            /* and fix some GTK+2 oddy */
            if (notes->note->x != -1 && notes->note->y != -1)
              {
                gtk_window_move (GTK_WINDOW (notes->note->window), 
                                 notes->note->x,
                                 notes->note->y);
              }
          }
      }
    else
      {
        gtk_window_get_position (GTK_WINDOW (notes->note->window),
                                 &notes->note->x, &notes->note->y);
        if (GTK_WIDGET_VISIBLE (notes->note->notebook))
            gtk_window_get_size (GTK_WINDOW (notes->note->window),
                                 &notes->note->w, &notes->note->h);
        else
            gtk_window_get_size (GTK_WINDOW (notes->note->window),
                                 &notes->note->w, NULL);

        gtk_widget_hide (notes->note->window);
      }

    return FALSE;
}

static void
on_options_response (GtkWidget *widget, int response, NotesPlugin *notes)
{
    xfce_panel_plugin_unblock_menu (notes->plugin);
    gtk_widget_destroy (widget);

    notes_save (notes->plugin, notes);
}


/* handle user messages */

static gboolean
notes_message_received (GtkWidget *widget, GdkEventClient *ev, gpointer data)
{
    NotesPlugin *notes;

    notes = data;

    if (ev->data_format == 8 && *(ev->data.b) != '\0')
      {
        if (!strcmp (XFCE_NOTES_MESSAGE, ev->data.b))
          {
            notes_button_clicked (notes->plugin, notes);
            /* Show the text view */
            gtk_widget_show (notes->note->notebook);
            gtk_window_resize (GTK_WINDOW (notes->note->window), 
                               notes->note->w, notes->note->h);
            return TRUE;
          }
      }

    return FALSE;
}

static gboolean
notes_set_selection (NotesPlugin *notes)
{
    GdkScreen *gscreen;
    gchar selection_name[32];
    Atom selection_atom;
    GtkWidget *win;
    Window xwin;

    win = gtk_invisible_new ();
    gtk_widget_realize (win);
    xwin = GDK_WINDOW_XID (GTK_WIDGET (win)->window);

    gscreen = gtk_widget_get_screen (win);
    g_snprintf (selection_name, sizeof (selection_name),
                XFCE_NOTES_SELECTION"%d", gdk_screen_get_number (gscreen));
    selection_atom = XInternAtom (GDK_DISPLAY (), selection_name, FALSE);

    if (XGetSelectionOwner (GDK_DISPLAY (), selection_atom))
      {
        gtk_widget_destroy (win);
        return FALSE;
      }

    XSelectInput (GDK_DISPLAY (), xwin, PropertyChangeMask);
    XSetSelectionOwner (GDK_DISPLAY (), selection_atom, xwin, GDK_CURRENT_TIME);

    g_signal_connect (win, "client-event",
                      G_CALLBACK (notes_message_received), notes);

    return TRUE;
}

