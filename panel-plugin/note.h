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

#ifndef NOTE_H
#define NOTE_H

typedef struct
{
    GtkWidget *window;

    GtkWidget *frame;

    GtkWidget *icon;
    GtkWidget *move_event_box;
    GtkWidget *title;
    GtkWidget *close_button;
    GtkWidget *close_icon;

    GtkWidget *scroll;
    GtkWidget *text;

    GtkWidget *vbox;
    GtkWidget *hbox;

    /* Window position */
    gint x, y;
}
Note;

Note *          note_new (XfcePanelPlugin *);
static gboolean on_note_delete ();
static gboolean on_title_press (GtkWidget *, GdkEventButton *, GtkWindow *);
static gboolean on_title_scroll (GtkWidget *, GdkEventScroll *, Note *);
static void     note_load_data (XfcePanelPlugin *, Note *);

Note *
note_new (XfcePanelPlugin *plugin)
{
    Note *note;

    DBG ("Create Note Window");

    note = g_new0 (Note, 1);


    /* Window */
    note->window = gtk_window_new (GTK_WINDOW_TOPLEVEL);
    
    gtk_window_set_default_size (GTK_WINDOW (note->window), 242, 200);
    gtk_window_set_decorated (GTK_WINDOW (note->window), FALSE);
    gtk_window_set_skip_pager_hint (GTK_WINDOW (note->window), FALSE);
    gtk_window_set_skip_taskbar_hint (GTK_WINDOW (note->window), FALSE);
    gtk_window_set_icon_name (GTK_WINDOW (note->window), GTK_STOCK_EDIT);

    /* Prevent close window (Alt-F4) */
    g_signal_connect (note->window, "delete-event", G_CALLBACK (on_note_delete),
                      NULL);


    /* Frame */
    note->frame = gtk_frame_new (NULL);
    gtk_widget_show (note->frame);

    gtk_frame_set_shadow_type (GTK_FRAME (note->frame), GTK_SHADOW_OUT);
    gtk_container_add (GTK_CONTAINER (note->window), note->frame);


    /* Vertical box */
    note->vbox = gtk_vbox_new (FALSE, 0);
    gtk_widget_show (note->vbox);

    gtk_box_set_spacing (GTK_BOX (note->vbox), 2);
    gtk_container_add (GTK_CONTAINER (note->frame), note->vbox);


    /* Horizontal box: icon + title + close button */
    note->hbox = gtk_hbox_new (FALSE, 2);
    gtk_widget_show (note->hbox);

    gtk_box_pack_start (GTK_BOX (note->vbox), note->hbox, FALSE, FALSE, 0);

    /* Icon */
    note->icon = gtk_image_new_from_stock (GTK_STOCK_EDIT, 
                                           GTK_ICON_SIZE_MENU);
    gtk_widget_show (note->icon);

    gtk_box_pack_start (GTK_BOX (note->hbox), note->icon, FALSE, FALSE, 0);

    /* Event box move + Title */
    note->move_event_box = gtk_event_box_new ();
    gtk_widget_show (note->move_event_box);

    gtk_box_pack_start (GTK_BOX (note->hbox), note->move_event_box, TRUE, TRUE,
                        0);
    g_signal_connect (G_OBJECT (note->move_event_box), "button-press-event",
                      G_CALLBACK (on_title_press), note->window);

    g_signal_connect (G_OBJECT (note->move_event_box), "scroll-event",
                      G_CALLBACK (on_title_scroll), note);

    gtk_widget_realize (note->move_event_box);

    note->title = gtk_label_new (_("Notes"));
    gtk_widget_show (note->title);

    gtk_container_add (GTK_CONTAINER (note->move_event_box), note->title);

    /* Close button + icon */
    note->close_button = xfce_create_panel_button ();
    gtk_widget_show (note->close_button);

    gtk_widget_set_size_request (note->close_button, 16, 16);
    gtk_box_pack_start (GTK_BOX (note->hbox), note->close_button, FALSE, FALSE,
                        0);

    note->close_icon = gtk_image_new_from_stock (GTK_STOCK_CLOSE, 
                                                 GTK_ICON_SIZE_MENU);
    gtk_widget_show (note->close_icon);

    gtk_container_add (GTK_CONTAINER (note->close_button), note->close_icon);


    /* Scrolled window + Text view */
    note->scroll = gtk_scrolled_window_new (NULL, NULL);
    gtk_widget_show (note->scroll);

    gtk_scrolled_window_set_shadow_type (GTK_SCROLLED_WINDOW (note->scroll),
                                         GTK_SHADOW_IN);
    gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW (note->scroll), 
                                    GTK_POLICY_AUTOMATIC, GTK_POLICY_ALWAYS);
    gtk_box_pack_start (GTK_BOX (note->vbox), note->scroll, TRUE, TRUE, 0);

    /* Text view */
    note->text = gtk_text_view_new ();
    gtk_widget_show (note->text);

    gtk_text_view_set_wrap_mode (GTK_TEXT_VIEW (note->text), GTK_WRAP_WORD);
    gtk_container_add (GTK_CONTAINER (note->scroll), note->text);


    /* Load the data */
    note_load_data (plugin, note);

    return note;
}

static gboolean
on_note_delete ()
{
    /* Prevent close window (Alt-F4) */
    return TRUE;
}

static gboolean
on_title_press (GtkWidget *widget, GdkEventButton *event, GtkWindow *window)
{
    if (event->type == GDK_BUTTON_PRESS && event->button == 1)
        /* Move the window */
        gtk_window_begin_move_drag (window, event->button, event->x_root, 
                                    event->y_root, event->time);

    return FALSE;
}

static gboolean
on_title_scroll (GtkWidget *widget, GdkEventScroll *event, Note *note)
{
    gint width, height;

    gtk_window_get_default_size (GTK_WINDOW  (note->window), &width, &height);

    if (event->type == GDK_SCROLL)
      {
        if (event->direction == GDK_SCROLL_UP)
          {
            /* Hide the text view */
            gtk_widget_hide (note->scroll);
            gtk_window_resize (GTK_WINDOW (note->window), width, 1);
          }
        else if (event->direction == GDK_SCROLL_DOWN)
          {
            /* Show the text view */
            gtk_widget_show (note->scroll);
            gtk_window_resize (GTK_WINDOW (note->window), width, height);
          }
      }

    return FALSE;
}

static void
note_load_data (XfcePanelPlugin *plugin, Note *note)
{
    char *file;
    XfceRc *rc;

    GtkTextBuffer *buffer;
    const gchar *text;

    if (!(file = xfce_panel_plugin_lookup_rc_file (plugin)))
        return;

    DBG ("Look up file (%s)", file);

    rc = xfce_rc_simple_open (file, FALSE);
    g_free (file);

    if (rc)
      {
        text = xfce_rc_read_entry (rc, "note", "");

        DBG ("Text: %s", text);

        buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (note->text));
        gtk_text_buffer_set_text (buffer, text, -1);

        gtk_text_view_set_buffer (GTK_TEXT_VIEW (note->text), buffer);

        note->x = xfce_rc_read_int_entry (rc, "pos_x", -1);
        note->y = xfce_rc_read_int_entry (rc, "pos_y", -1);

        DBG ("Position: x(%d) y(%d)", note->x, note->y);

        xfce_rc_close (rc);
      }
}

#endif

