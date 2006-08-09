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

#include <stdlib.h>
#include <gtk/gtk.h>
#include <libxfcegui4/libxfcegui4.h>

#include <libxfce4panel/xfce-panel-plugin.h>
#include <libxfce4panel/xfce-panel-convenience.h>

#include "notes.h"

#define PLUGIN_NAME "xfce4-notes-plugin"


static void     note_page_load_data (XfcePanelPlugin *, NotePage *);
static gboolean on_note_delete ();
static void     on_note_close (GtkWidget *, GtkToggleButton *);
static gboolean on_title_press (GtkWidget *, GdkEventButton *, GtkWindow *);
static gboolean on_title_scroll (GtkWidget *, GdkEventScroll *, Note *);
static gboolean on_note_key_press (GtkWidget *, GdkEventKey *, NotesPlugin *);
static void     on_note_changed (GtkWidget *, NotesPlugin *);
static gboolean on_note_rename (GtkWidget *, GdkEventButton *, Note *);
static void     on_note_rename_response (GtkDialog *, gint response, GSList *);
static void     on_page_create (GtkWidget *, NotesPlugin *);
static gboolean on_page_delete (GtkWidget *, NotesPlugin *);
static void     note_page_destroy (GtkWidget *, gint response_id,
                                   NotesPlugin *);

Note *
note_new (NotesPlugin *notes)
{
    Note *note;
    GtkWidget *image_add, *image_del, *image_close, *trick;

    DBG ("Create Note Window");

    note = g_new0 (Note, 1);
    note->pages = NULL;

    /* Window */
    note->window = gtk_window_new (GTK_WINDOW_TOPLEVEL);

    gtk_window_set_title (GTK_WINDOW (note->window), _("Notes"));
    gtk_window_set_default_size (GTK_WINDOW (note->window), 242, 200);
    gtk_window_set_decorated (GTK_WINDOW (note->window), FALSE);
    gtk_window_set_icon_name (GTK_WINDOW (note->window), GTK_STOCK_EDIT);

    /* Prevent close window */
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


    /* Horizontal box: create new page button + title + close button */
    note->hbox = gtk_hbox_new (FALSE, 2);
    gtk_widget_show (note->hbox);

    gtk_box_pack_start (GTK_BOX (note->vbox), note->hbox, FALSE, FALSE, 0);

    /* Add button */
    note->add = xfce_create_panel_button ();
    gtk_widget_show (note->add);

    gtk_tooltips_set_tip (GTK_TOOLTIPS (notes->tooltips), note->add,
                          _("Create new note"), NULL);
    gtk_widget_set_size_request (note->add, 22, 22);
    gtk_box_pack_start (GTK_BOX (note->hbox), note->add, FALSE, FALSE, 0);

    image_add = gtk_image_new_from_stock (GTK_STOCK_ADD, GTK_ICON_SIZE_MENU);
    gtk_widget_show (image_add);

    gtk_container_add (GTK_CONTAINER (note->add), image_add);

    g_signal_connect (note->add, "clicked", G_CALLBACK (on_page_create), notes);

    /* Remove button */
    note->del = xfce_create_panel_button ();
    gtk_widget_show (note->del);

    gtk_tooltips_set_tip (GTK_TOOLTIPS (notes->tooltips), note->del,
                          _("Delete this note"), NULL);
    gtk_widget_set_size_request (note->del, 22, 22);
    gtk_box_pack_start (GTK_BOX (note->hbox), note->del, FALSE, FALSE, 0);

    image_del = gtk_image_new_from_stock (GTK_STOCK_REMOVE, GTK_ICON_SIZE_MENU);
    gtk_widget_show (image_del);

    gtk_container_add (GTK_CONTAINER (note->del), image_del);

    g_signal_connect (note->del, "clicked", G_CALLBACK (on_page_delete), notes);

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

    note->title = gtk_label_new (_("<b>Notes</b>"));
    gtk_label_set_use_markup (GTK_LABEL (note->title), TRUE);
    gtk_widget_show (note->title);

    gtk_container_add (GTK_CONTAINER (note->move_event_box), note->title);

    /* A little trick to center the text :S */
    trick = gtk_label_new ("");
    gtk_widget_show (trick);

    gtk_widget_set_size_request (trick, 22, 22);
    gtk_box_pack_start (GTK_BOX (note->hbox), trick, FALSE, FALSE, 0);

    /* Close button + icon */
    note->close = xfce_create_panel_button ();
    gtk_widget_show (note->close);

    gtk_widget_set_size_request (note->close, 22, 22);
    gtk_box_pack_start (GTK_BOX (note->hbox), note->close, FALSE, FALSE, 0);

    image_close = gtk_image_new_from_stock (GTK_STOCK_CLOSE,
                                            GTK_ICON_SIZE_MENU);
    gtk_widget_show (image_close);

    gtk_container_add (GTK_CONTAINER (note->close), image_close);

    g_signal_connect (note->close, "clicked", G_CALLBACK (on_note_close),
                      notes->button);


    /* Notebook */
    note->notebook = gtk_notebook_new ();
    gtk_widget_show (note->notebook);

    gtk_notebook_set_show_tabs (GTK_NOTEBOOK (note->notebook), FALSE);
    gtk_notebook_set_tab_pos (GTK_NOTEBOOK (note->notebook), GTK_POS_LEFT);
    gtk_notebook_set_scrollable (GTK_NOTEBOOK (note->notebook), TRUE);

    gtk_box_pack_start (GTK_BOX (note->vbox), note->notebook, TRUE, TRUE, 0);

    return note;
}

void
note_page_new (XfcePanelPlugin *plugin, NotesPlugin *notes)
{
    NotePage *page;
    Note *note;
    GtkTextBuffer *buffer;
    gint id;
    gchar label[8];

    DBG ("Create a new page");

    page = g_new0 (NotePage, 1);
    note = notes->note;
    note->pages = g_list_append (note->pages, page);
    id = g_list_length (note->pages);

    /* Label */
    GtkWidget *eventbox;
    eventbox = gtk_event_box_new ();
    gtk_widget_show (eventbox);

    g_snprintf (label, 8, "%d", id);
    page->label = gtk_label_new (label);
    gtk_widget_show (page->label);

    gtk_event_box_set_visible_window (GTK_EVENT_BOX (eventbox), FALSE);
    gtk_container_add (GTK_CONTAINER (eventbox), page->label);
    gtk_container_set_border_width (GTK_CONTAINER (eventbox), 3);

    /* Scrolled window + Text view */
    page->scroll = gtk_scrolled_window_new (NULL, NULL);
    gtk_widget_show (page->scroll);

    gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW (page->scroll),
                                    GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);

    /* Text view */
    page->text = gtk_text_view_new ();
    gtk_widget_show (page->text);

    gtk_text_view_set_wrap_mode (GTK_TEXT_VIEW (page->text), GTK_WRAP_WORD);
    gtk_container_add (GTK_CONTAINER (page->scroll), page->text);


    /* Append the widget to the notebook */
    page->id = gtk_notebook_append_page (GTK_NOTEBOOK (note->notebook),
                                         page->scroll, eventbox);
    gtk_notebook_set_show_tabs (GTK_NOTEBOOK (note->notebook),
                                (gboolean) page->id);

    note_page_load_data (plugin, page);

    g_signal_connect (page->text, "key-press-event",
                      G_CALLBACK (on_note_key_press), notes);
    buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (page->text));
    g_signal_connect (buffer, "changed", G_CALLBACK (on_note_changed), notes);
    g_signal_connect (eventbox, "button-press-event",
                      G_CALLBACK (on_note_rename), note);
}

static void
note_page_load_data (XfcePanelPlugin *plugin, NotePage *page)
{
    gchar *file;
    XfceRc *rc;

    if (!(file = xfce_panel_plugin_lookup_rc_file (plugin)))
        return;

    DBG ("Look up file (%s)", file);

    rc = xfce_rc_simple_open (file, FALSE);
    g_free (file);

    if (rc)
      {
        gchar note_entry[12], label_entry[13];
        GtkTextBuffer *buffer;
        const gchar *text, *label;

        page->label_dirty = FALSE;
        g_snprintf (label_entry, 13, "label%d", page->id);
        if (xfce_rc_has_entry (rc, label_entry))
          {
            page->label_dirty = TRUE;
            label = xfce_rc_read_entry (rc, label_entry, ":)");
            gtk_label_set_text (GTK_LABEL (page->label), label);
            gtk_label_set_angle (GTK_LABEL (page->label), 90);
          }

        g_snprintf (note_entry, 12, "note%d", page->id);
        text = xfce_rc_read_entry (rc, note_entry, "");

        DBG ("Note %d (%s): %s", page->id, note_entry, text);

        buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (page->text));
        gtk_text_buffer_set_text (buffer, text, -1);
        gtk_text_view_set_buffer (GTK_TEXT_VIEW (page->text), buffer);

        xfce_rc_close (rc);
      }
}

static gboolean
on_note_delete ()
{
    /* Prevent close window (Alt-F4) */
    return TRUE;
}

static void
on_note_close (GtkWidget *widget, GtkToggleButton *panel_button)
{
    gtk_toggle_button_set_active (panel_button, FALSE);
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
    if (event->type == GDK_SCROLL)
      {
        if (GTK_WIDGET_VISIBLE (note->notebook))
            gtk_window_get_size (GTK_WINDOW (note->window), &note->w, &note->h);
        else
            gtk_window_get_size (GTK_WINDOW (note->window), &note->w, NULL);

        if (event->direction == GDK_SCROLL_UP)
          {
            /* Hide the text view */
            gtk_widget_hide (note->notebook);
            gtk_window_resize (GTK_WINDOW (note->window), note->w, 1);
          }
        else if (event->direction == GDK_SCROLL_DOWN)
          {
            /* Show the text view */
            gtk_widget_show (note->notebook);
            gtk_window_resize (GTK_WINDOW (note->window), note->w, note->h);
          }
      }

    return FALSE;
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

    notes->timeout_id = g_timeout_add (60000, (GSourceFunc) save_on_timeout,
                                       notes);
}

static gboolean
on_note_rename (GtkWidget *widget, GdkEventButton *event, Note *note)
{
    if (event->type == GDK_2BUTTON_PRESS && event->button == 1)
    {
        DBG ("Rename the note_page_menu_label");

        GSList *slist = NULL;
        gint id;
        GtkWidget *dialog, *vbox;
        GtkWidget *label, *entry;
        NotePage *page;

        id = gtk_notebook_get_current_page (GTK_NOTEBOOK (note->notebook));
        page = (NotePage *)g_list_nth_data (note->pages, id);
        label = page->label;

        dialog =
            gtk_dialog_new_with_buttons (_("Rename"),
                                         GTK_WINDOW (note->window),
                                         GTK_DIALOG_MODAL|GTK_DIALOG_DESTROY_WITH_PARENT,
                                         GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL,
                                         GTK_STOCK_OK, GTK_RESPONSE_OK,
                                         NULL);

        gtk_window_set_resizable (GTK_WINDOW (dialog), FALSE);
        gtk_window_set_icon_name (GTK_WINDOW (dialog), GTK_STOCK_EDIT);

        vbox = gtk_vbox_new (2, FALSE);
        gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox), vbox);
        gtk_widget_show (vbox);

        gtk_container_set_border_width (GTK_CONTAINER (vbox), 12);

        entry = gtk_entry_new ();
        gtk_entry_set_text (GTK_ENTRY (entry),
                            gtk_label_get_text (GTK_LABEL (label)));
        gtk_widget_show (entry);

        gtk_container_add (GTK_CONTAINER (vbox), entry);

        slist = g_slist_append (slist, entry);
        slist = g_slist_append (slist, page);

        g_signal_connect (dialog, "response",
                          G_CALLBACK (on_note_rename_response), slist);

        gtk_widget_show (dialog);
    }

    return FALSE;
}

static void
on_note_rename_response (GtkDialog *dialog, gint response, GSList *slist)
{
    GtkWidget *entry;
    NotePage *page;

    if (response == GTK_RESPONSE_OK)
      {
		entry = GTK_WIDGET (g_slist_nth_data (slist, 0));
		page = (NotePage *) g_slist_nth_data (slist, 1);

		DBG ("Rename to: %s", gtk_entry_get_text (GTK_ENTRY (entry)));

		page->label_dirty = TRUE;
		gtk_label_set_text (GTK_LABEL (page->label),
							gtk_entry_get_text (GTK_ENTRY (entry)));
        gtk_label_set_angle (GTK_LABEL (page->label), 90);
      }

    g_slist_free (slist);
    gtk_widget_destroy (GTK_WIDGET (dialog));
}

static void
on_page_create (GtkWidget *widget, NotesPlugin *notes)
{
    note_page_new (notes->plugin, notes);
    gtk_notebook_set_current_page (GTK_NOTEBOOK (notes->note->notebook), -1);
}

static gboolean
on_page_delete (GtkWidget *widget, NotesPlugin *notes)
{
    gint id;
    NotePage *page;
    GtkTextBuffer *buffer;

    id = gtk_notebook_get_current_page (GTK_NOTEBOOK (notes->note->notebook));
    page = (NotePage *)g_list_nth_data (notes->note->pages, id);
    buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (page->text));

    if (gtk_text_buffer_get_char_count (buffer) > 0 || page->label_dirty)
      {
        /* Ask for confirmation */
        GtkWidget *dialog;
        dialog = gtk_message_dialog_new (GTK_WINDOW (notes->note->window),
                                         GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
                                         GTK_MESSAGE_QUESTION, GTK_BUTTONS_YES_NO,
                                         _("Are you sure you want to delete this note?"));

        g_signal_connect (dialog, "response", G_CALLBACK (note_page_destroy),
                          notes);

        gtk_widget_show (dialog);
      }
    else
        note_page_destroy (NULL, GTK_RESPONSE_YES, notes);

    return TRUE;
}

static void
note_page_destroy (GtkWidget *widget, gint response_id, NotesPlugin *notes)
{
    if (GTK_IS_WIDGET (widget))
        gtk_widget_destroy (widget);

    if (response_id == GTK_RESPONSE_YES)
      {
        gchar *file;
        XfceRc *rc;
        gint id;
        GtkNotebook *notebook;
        GList *pages;
        NotePage *page;
        GtkTextBuffer *buffer;
        gchar tab_label[8];
        gchar note_entry[12], label_entry[13];

        notebook = GTK_NOTEBOOK (notes->note->notebook);
        id = gtk_notebook_get_current_page (notebook);

        DBG ("Delete id %d", id);

        if (!(file = xfce_panel_plugin_save_location (notes->plugin, TRUE)))
            return;

        rc = xfce_rc_simple_open (file, FALSE);
        g_free (file);

        if (gtk_notebook_get_n_pages (notebook) == 1)
          {
            page = (NotePage *)g_list_nth_data (notes->note->pages, id);
            buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (page->text));
            gtk_text_buffer_set_text (buffer, "", -1);

            gtk_label_set_text (GTK_LABEL (page->label), "1");
            gtk_label_set_angle (GTK_LABEL (page->label), 0);
            if (rc)
              {
                xfce_rc_delete_entry (rc, "label0", TRUE);
                xfce_rc_close (rc);
                page->label_dirty = FALSE;
              }

            return;
          }

        gtk_notebook_remove_page (notebook, id);

        notes->note->pages = g_list_nth (notes->note->pages, 0);
        pages = g_list_nth (notes->note->pages, id);

        notes->note->pages = g_list_remove_link (notes->note->pages, pages);
        g_list_free_1 (pages);

        pages = g_list_nth (notes->note->pages, 0);
        for (id = 0, page = (NotePage *)g_list_nth_data (pages, id);
             page != NULL;
             id++, page = (NotePage *)g_list_nth_data (pages, id))
          {
            page->id = id;

            DBG ("id:%d", id);

            if (!page->label_dirty)
              {
                g_snprintf (tab_label, 8, "%d", id+1);
                gtk_label_set_text (GTK_LABEL (page->label), tab_label);
              }
          }

        if (rc)
          {
            g_snprintf (note_entry, 12, "note%d", g_list_length (pages));
            g_snprintf (label_entry, 13, "label%d", g_list_length (pages));

            xfce_rc_delete_entry (rc, note_entry, TRUE);
            xfce_rc_delete_entry (rc, label_entry, TRUE);
            xfce_rc_close (rc);
          }

        gtk_notebook_set_show_tabs (notebook,
                                    (gboolean)g_list_length (pages)-1);

        save_on_timeout (notes);
      }
}
