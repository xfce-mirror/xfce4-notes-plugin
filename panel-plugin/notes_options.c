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

extern NoteApplet notes_applet;

void
on_sticky_check_button_toggled(GtkToggleButton *button, gpointer data)
{
    if (gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(button)) == TRUE) {
	notes_applet.notes_sticky = TRUE;
    } else {
	notes_applet.notes_sticky = FALSE;
    }

    notes_update_sticky();

    return;
}

void
on_system_colors_check_button_toggled(GtkToggleButton *button, gpointer data)
{
    GtkWidget *color_sel = (GtkWidget *)data;

    if (gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(button)) == TRUE) {
	notes_applet.system_colors = TRUE;
	gtk_widget_set_sensitive(color_sel, FALSE);
    } else {
	notes_applet.system_colors = FALSE;
	gtk_widget_set_sensitive(color_sel, TRUE);
    }

    notes_update_colors();

    return;
}

void
notes_color_selection_ok(GtkDialog *color_dialog)
{
    gtk_dialog_response(color_dialog, GTK_RESPONSE_OK);
    return;
}


void
notes_color_selection_cancel(GtkDialog *color_dialog)
{
    gtk_dialog_response(color_dialog, GTK_RESPONSE_CANCEL);
    return;
}

void
notes_color_selection_dialog(GtkWidget *widget, gpointer data)
{
    GtkWidget *color_dialog;
    GtkWidget *colorsel;

    GdkColor color;
    guint32 rgba;

    GdkPixbuf *pixbuf = (GdkPixbuf *)data;

    color_dialog = gtk_color_selection_dialog_new("select");
    colorsel = GTK_COLOR_SELECTION_DIALOG(color_dialog)->colorsel;
    gtk_color_selection_set_current_color(GTK_COLOR_SELECTION(colorsel), 
					  &notes_applet.note_color);

    gtk_window_set_position(GTK_WINDOW(color_dialog), GTK_WIN_POS_CENTER);

    g_signal_connect_swapped(G_OBJECT (GTK_COLOR_SELECTION_DIALOG
				       (color_dialog)->ok_button),
			     "clicked", 
			     G_CALLBACK (notes_color_selection_ok),
			     color_dialog);

    g_signal_connect_swapped (G_OBJECT (GTK_COLOR_SELECTION_DIALOG
					(color_dialog)->cancel_button),
			      "clicked", 
			      G_CALLBACK (notes_color_selection_cancel), 
			      color_dialog);
    
    if (gtk_dialog_run(GTK_DIALOG(color_dialog)) == GTK_RESPONSE_OK) {
	/* get the selected color */
	gtk_color_selection_get_current_color(GTK_COLOR_SELECTION(colorsel),
					      &notes_applet.note_color);
	/* update settings dialog */
	color.red = notes_applet.note_color.red;
	color.green = notes_applet.note_color.green;
	color.blue = notes_applet.note_color.blue;
	rgba = (((color.red & 0xff00) << 8) | 
		((color.green & 0xff00)) | 
		((color.blue & 0xff00) >> 8)) << 8;
	gdk_pixbuf_fill(pixbuf, rgba);
	/* update the notes colors */
	notes_update_colors();
    }

    gtk_widget_destroy(color_dialog);

    return;
}

void
notes_icon_selection_dialog(GtkWidget *widget, gpointer data)
{
    GtkWidget *image = (GtkWidget *)data;
    GdkPixbuf *pixbuf, *pixbuf_orig, *pixbuf_tmp;

    /* select a file, from xfce_support */
    gchar *icon_filename = select_file_with_preview("Select Icon", "", NULL);
    
    /* if a file was selected */
    if (icon_filename != NULL) {
	pixbuf_orig = gdk_pixbuf_new_from_file(icon_filename, NULL);

	if (pixbuf_orig != NULL) {
	    /* save icon_filename */
	    notes_applet.icon_filename = icon_filename;
	    /* change the icon */
	    pixbuf_tmp = notes_applet.pixbuf;
	    notes_applet.pixbuf = gdk_pixbuf_copy(pixbuf_orig);
	    g_object_unref(pixbuf_tmp);

	    pixbuf = gdk_pixbuf_scale_simple(pixbuf_orig, 
					     icon_size[0], icon_size[0],
					     GDK_INTERP_BILINEAR);
	    g_object_unref(pixbuf_orig);
	    gtk_image_set_from_pixbuf(GTK_IMAGE(image), pixbuf);
	    g_object_unref(pixbuf);

	    /* reset the icon in the panel through a shortcut */
	    notes_set_size(NULL, notes_applet.panel_size);
	}
    }
    
    return;
}

/* options dialog */
GtkWidget*
notes_create_applet_options (GtkContainer *con)
{
    GtkWidget *vbox, *hbox;
    GtkWidget *label;
    GtkWidget *button;

    GtkWidget *framebox;

    GtkWidget *color_vbox;
    GtkWidget *color_button;
    GtkWidget *frame;
    GdkPixbuf *pixbuf;
    GtkWidget *image;
    GdkColor color;
    guint32 rgba;
    
    vbox = gtk_vbox_new(FALSE, 0);
    gtk_widget_show(vbox);

    /* STICKY */

    framebox = xfce_framebox_new("Sticky", TRUE);
    gtk_box_pack_start_defaults(GTK_BOX(vbox), framebox);
    gtk_widget_show(framebox);

    button = gtk_check_button_new_with_label("Make notes sticky");
    gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(button),
				 (notes_applet.notes_sticky == TRUE) ?
				 TRUE : FALSE);
    xfce_framebox_add(XFCE_FRAMEBOX(framebox), button);
    g_signal_connect(G_OBJECT(button), "toggled",
		     G_CALLBACK(on_sticky_check_button_toggled), NULL);
    gtk_widget_show(button);

    /* COLOR */

    framebox = xfce_framebox_new("Color", TRUE);
    gtk_box_pack_start_defaults(GTK_BOX(vbox), framebox);
    gtk_widget_show(framebox);
    
    color_vbox = gtk_vbox_new(FALSE, 0);
    gtk_widget_show(color_vbox);
    xfce_framebox_add(XFCE_FRAMEBOX(framebox), color_vbox);

    /* system color */
    button = gtk_check_button_new_with_label("Use system colors");
    /* use system colors by default */
    gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(button),
				 (notes_applet.system_colors == TRUE) ?
				 TRUE : FALSE);
    gtk_box_pack_start_defaults(GTK_BOX(color_vbox), button);
    gtk_widget_show(button);



    hbox = gtk_hbox_new(FALSE, 0);
    gtk_box_pack_start_defaults(GTK_BOX(color_vbox), hbox);
    gtk_widget_show(hbox);

    /* color label */
    label = gtk_label_new("Color:");
    gtk_box_pack_start_defaults(GTK_BOX(hbox), label);
    gtk_widget_show(label);
    
    /* select color button */
    color_button = gtk_button_new();
    gtk_box_pack_start_defaults(GTK_BOX(hbox), color_button);
    gtk_widget_show(color_button);

    /* use system color check button */
    /* it's down here because we want to send the color_button to make
       toggle its sensitivety */
    g_signal_connect(G_OBJECT(button), "toggled",
		     G_CALLBACK(on_system_colors_check_button_toggled),
		     (gpointer)color_button);

    /* frame */
    frame = gtk_frame_new(NULL);
    gtk_frame_set_shadow_type(GTK_FRAME(frame), GTK_SHADOW_IN);
    gtk_container_set_border_width(GTK_CONTAINER(frame), 0);
    gtk_container_add(GTK_CONTAINER(color_button), frame);
    gtk_widget_show(frame);
    
    /* rgba */
    color.red = notes_applet.note_color.red;
    color.green = notes_applet.note_color.green;
    color.blue = notes_applet.note_color.blue;
    pixbuf = gdk_pixbuf_new(GDK_COLORSPACE_RGB, FALSE, 8, 
			    /* icon_size[0] = tiny */
			    icon_size[0], icon_size[0]);
    rgba = (((color.red & 0xff00) << 8) | 
	    ((color.green & 0xff00)) | 
	    ((color.blue & 0xff00) >> 8)) << 8;
    gdk_pixbuf_fill(pixbuf, rgba);
    image = gtk_image_new_from_pixbuf(pixbuf);
    gtk_container_add(GTK_CONTAINER(frame), image);
    gtk_widget_show(image);

    /* select color dialog button */
    g_signal_connect(G_OBJECT(color_button), "clicked",
		     G_CALLBACK(notes_color_selection_dialog),
		     (gpointer)pixbuf);

    /* ICON */

    framebox = xfce_framebox_new("Icon", TRUE);
    gtk_box_pack_start_defaults(GTK_BOX(vbox), framebox);
    gtk_widget_show(framebox);

    hbox = gtk_hbox_new(FALSE, 0);
    xfce_framebox_add(XFCE_FRAMEBOX(framebox), hbox);
    gtk_widget_show(hbox);

    /* icon label */
    label = gtk_label_new("Icon:");
    gtk_box_pack_start_defaults(GTK_BOX(hbox), label);
    gtk_widget_show(label);
    
    /* select icon button */
    button = gtk_button_new();
    gtk_box_pack_start_defaults(GTK_BOX(hbox), button);
    gtk_widget_show(button);

    /* frame */
    frame = gtk_frame_new(NULL);
    gtk_frame_set_shadow_type(GTK_FRAME(frame), GTK_SHADOW_IN);
    gtk_container_set_border_width(GTK_CONTAINER(frame), 0);
    gtk_container_add(GTK_CONTAINER(button), frame);
    gtk_widget_show(frame);
    
    /* icon */
    image = 
	gtk_image_new_from_pixbuf 
	(gdk_pixbuf_scale_simple(notes_applet.pixbuf, 
				 /* icon_size[0] = tiny */
				 icon_size[0],
				 icon_size[0], 
				 GDK_INTERP_BILINEAR));

    gtk_container_add(GTK_CONTAINER(frame), image);
    gtk_widget_show(image);

    g_signal_connect(G_OBJECT(button), "clicked",
		     G_CALLBACK(notes_icon_selection_dialog), 
		     (gpointer)image);

    return vbox;
}
