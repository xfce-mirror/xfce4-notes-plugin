/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2003  Jakob Henriksson <b0kaj+www@lysator.liu.se>
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

#include "notes.h"
#include "notes_icons.h"

gboolean title_changing = FALSE;

/* definied in notes_applet.c */
extern NoteApplet notes_applet;

gboolean
on_title_change(GtkWidget *widget, GdkEventButton *event, gpointer data)
{
    Note *note = (Note *)data;
    gchar *title_text;

    if (event->type == GDK_2BUTTON_PRESS) {
	
	/* get text from label */
	title_text = (gchar *)gtk_label_get_text(GTK_LABEL(note->title_label));
	/* remove label from container */
	gtk_widget_hide(note->title_label);
	gtk_container_remove(GTK_CONTAINER(widget), note->title_label);
	/* update the entry with the text */
	gtk_entry_set_text(GTK_ENTRY(note->title_entry), title_text);
	/* add entry to container instead */
	gtk_container_add(GTK_CONTAINER(widget), note->title_entry);
	gtk_widget_show(note->title_entry);
	gtk_widget_grab_focus(note->title_entry);

	title_changing = TRUE;
	
    }
    
    return FALSE;
}

void
on_title_change_done(Note *note)
{
    /* reverse the effect of on_title_change */

    gtk_label_set_text(GTK_LABEL(note->title_label),
		       gtk_editable_get_chars(GTK_EDITABLE(note->title_entry),
					      0, -1));
    /* remove entry */
    gtk_widget_hide(note->title_entry);
    gtk_container_remove(GTK_CONTAINER(note->event_box_move1),
			 note->title_entry);
    /* add the label again */
    gtk_container_add(GTK_CONTAINER(note->event_box_move1), note->title_label);
    gtk_widget_show(note->title_label);
    
    title_changing = FALSE;

    return;
}

gboolean
on_title_key_press(GtkWidget *widget, GdkEventKey *event, gpointer data)
{
    if (event->type == GDK_KEY_PRESS) {
	if ((event->keyval == GDK_Return) || (event->keyval == GDK_KP_Enter)) {
	    on_title_change_done((Note *)data);
	}
    }
    return FALSE;
}

gboolean
on_text_view_focus_in(GtkWidget *widget, GdkEventFocus *ev, gpointer data)
{
    /* update title if we were editing it */
    if (title_changing == TRUE) {
	on_title_change_done((Note *)data);
    }

    return FALSE;
}

gboolean
on_move_window(GtkWidget *widget, GdkEventButton *event, gpointer data)
{
    GtkWidget *window = (GtkWidget *)data;

    if (event->type == GDK_BUTTON_PRESS) {
	if (event->button == 1) {
	    gtk_window_begin_move_drag(GTK_WINDOW(window),
				       event->button, 
				       event->x_root, event->y_root, 
				       event->time);
	}
    } 

    return FALSE;
}


gboolean
on_resize_window(GtkWidget *widget, GdkEventButton *event, gpointer data)
{
    GtkWidget *window = (GtkWidget *)data;

    if (event->type == GDK_BUTTON_PRESS) {
	if (event->button == 1) {
	    gtk_window_begin_resize_drag(GTK_WINDOW(window),
					 GDK_WINDOW_EDGE_SOUTH_EAST,
					 event->button, 
					 event->x_root, event->y_root, 
					 event->time);
	}
    }

    return FALSE;
}

void
notes_init_note(void)
{
    GdkPixbuf *tmp;

    /* close image */
    tmp = gdk_pixbuf_new_from_inline(-1, note_close_pixbuf, FALSE, NULL);
    notes_applet.close_pixbuf = 
	gdk_pixbuf_scale_simple(tmp, ICON_W, ICON_H, GDK_INTERP_BILINEAR);
    g_object_unref(tmp);

    /* resize image */
    tmp = gdk_pixbuf_new_from_inline(-1, note_resize_pixbuf, FALSE, NULL);
    notes_applet.resize_pixbuf = 
	gdk_pixbuf_scale_simple(tmp, ICON_W, ICON_H, GDK_INTERP_BILINEAR);
    g_object_unref(tmp);

    return;
}

Note*
notes_create_note(void)
{
    GtkWidget *main_w;

    GtkWidget *title;
    GtkWidget *label;

    GtkWidget *vbox, *hbox;
    GtkWidget *event_box;

    GtkWidget *button;

    GtkWidget *text_view;

    GtkWidget *image;

    Note *note;

    /* create or note structure */
    note = g_new(Note, 1);

    /* main window */
    main_w = gtk_window_new(GTK_WINDOW_TOPLEVEL);

    gtk_window_set_default_size(GTK_WINDOW(main_w), 200, 200);
    gtk_window_set_decorated(GTK_WINDOW(main_w), FALSE);
    gtk_window_set_skip_pager_hint(GTK_WINDOW(main_w), TRUE);
    gtk_window_set_skip_taskbar_hint(GTK_WINDOW(main_w), TRUE);

    /* vertical box */
    vbox = gtk_vbox_new(FALSE, 0);
    gtk_container_add(GTK_CONTAINER(main_w), vbox);
    gtk_widget_show(vbox);


    /* first horizontal box */
    hbox = gtk_hbox_new(FALSE, 2);
    gtk_box_pack_start(GTK_BOX(vbox), hbox, FALSE, FALSE, 0);
    gtk_widget_show(hbox);

    /* textview */
    text_view = gtk_text_view_new();
    gtk_box_pack_start(GTK_BOX(vbox), text_view, TRUE, TRUE, 1);
    gtk_widget_show(text_view);
    /* add to note structure */
    note->text_view = text_view;


    /* close button */
    button = gtk_button_new();
    gtk_button_set_relief(GTK_BUTTON(button), GTK_RELIEF_NONE);
    /* add to note structure */
    note->close_button = button;

    gtk_box_pack_start(GTK_BOX(hbox), button, FALSE, FALSE, 0);
    gtk_widget_show(button);
    

    /* cursor */
    /*
    gtk_widget_realize(event_box);
    gdk_window_set_cursor(event_box->window, 
			  gdk_cursor_new(GDK_X_CURSOR));
    */

    /* close image */
    g_object_ref(notes_applet.close_pixbuf);
    image = gtk_image_new_from_pixbuf(notes_applet.close_pixbuf);
    gtk_container_add(GTK_CONTAINER(button), image);
    gtk_widget_show(image);

    /* move event box */
    event_box = gtk_event_box_new();
    /* set a tooltip */
    gtk_tooltips_set_tip(notes_applet.tooltips, event_box,
			 "Double-click to edit title", NULL);
    /* add to note structure */
    note->event_box_move1 = event_box;
    gtk_box_pack_start(GTK_BOX(hbox), event_box, TRUE, TRUE, 0);
    gtk_widget_show(event_box);
    /* add action to event box */
    g_signal_connect(G_OBJECT(event_box), "button_press_event",
		     G_CALLBACK(on_move_window), (gpointer)main_w);
    gtk_widget_realize(event_box);
    gdk_window_set_cursor(event_box->window,
			  gdk_cursor_new(GDK_FLEUR));

    /* title */
    label = gtk_label_new("note");
    /* need to save title label even when removed from a container */
    g_object_ref(label);
    /* add to note structure */
    note->title_label = label;
    gtk_container_add(GTK_CONTAINER(event_box), label);
    gtk_widget_show(label);

    title = gtk_entry_new();
    /* need to save title entry even when removed from a container */
    g_object_ref(title);
    /* add to note structure */
    note->title_entry = title;
    /* when double-clicked the title becomes visible, send Note as data */
    g_signal_connect(G_OBJECT(event_box), "button_press_event",
		     G_CALLBACK(on_title_change), (gpointer)note);
    g_signal_connect(G_OBJECT(title), "key-press-event",
		     G_CALLBACK(on_title_key_press), (gpointer)note);
    
    g_signal_connect(G_OBJECT(text_view), "focus-in-event",
		     G_CALLBACK(on_text_view_focus_in), (gpointer)note);
    


    /* second horizontal box */
    hbox = gtk_hbox_new(FALSE, 0);
    gtk_box_pack_end(GTK_BOX(vbox), hbox, FALSE, FALSE, 0);
    gtk_widget_show(hbox);


    /* move event box again */
    event_box = gtk_event_box_new();
    note->event_box_move2 = event_box;
    gtk_box_pack_start(GTK_BOX(hbox), event_box, TRUE, TRUE, 0);
    gtk_widget_show(event_box);
    /* add action to event box */
    g_signal_connect(G_OBJECT(event_box), "button_press_event",
		     G_CALLBACK(on_move_window), (gpointer)main_w);
    gtk_widget_realize(event_box);
    gdk_window_set_cursor(event_box->window,
			  gdk_cursor_new(GDK_FLEUR));


    /* resize event box */
    event_box = gtk_event_box_new();
    note->event_box_resize = event_box;
    gtk_box_pack_end(GTK_BOX(hbox), event_box, FALSE, FALSE, 4);
    gtk_widget_show(event_box);

    /* resize image */
    g_object_ref(notes_applet.resize_pixbuf);
    image = gtk_image_new_from_pixbuf(notes_applet.resize_pixbuf);
    gtk_container_add(GTK_CONTAINER(event_box), image);
    gtk_widget_show(image);

    /* add action to event box */
    g_signal_connect(G_OBJECT(event_box), "button_press_event",
		     G_CALLBACK(on_resize_window), (gpointer)main_w);
    gtk_widget_realize(event_box);
    gdk_window_set_cursor(event_box->window, 
			  gdk_cursor_new(GDK_BOTTOM_RIGHT_CORNER));


    /* add main widget to note structure */
    note->note_w = main_w;

    return note;
}

    
