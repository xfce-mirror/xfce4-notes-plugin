/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2003  Jakob Henriksson <b0kaj+dev@lysator.liu.se>
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

static void notes_free_note(Note *note);
static void notes_free(Control *ctrl);
static void notes_delete_note(GtkWidget *widget, gpointer data);
static void notes_read_config(Control *ctrl, xmlNodePtr parent);
static void notes_write_config(Control *ctrl, xmlNodePtr parent);
static gboolean notes_control_new(Control *ctrl);
static void notes_create_options (Control *ctrl, GtkContainer *con, 
				  GtkWidget *done);

NoteApplet notes_applet;

void 
notes_update_note_colors(Note *note)
{
    GtkRcStyle *rc_style;
    GtkRcStyle *rc_style_base;
    GtkRcStyle *rc_style_bg;

    GdkColor note_color_off;

    /* make note_color_off same as note_color but a bit more dark, 
       a bit more off */
    note_color_off.red = (notes_applet.note_color.red * 8) / 10;
    note_color_off.green = (notes_applet.note_color.green * 8)/10;
    note_color_off.blue = (notes_applet.note_color.blue * 8) / 10;

    /* system color */
    if (notes_applet.system_colors == TRUE) {
	rc_style = gtk_rc_style_new();
	gtk_widget_modify_style(note->note_w, rc_style);
	gtk_widget_modify_style(note->title_entry, rc_style);
	gtk_widget_modify_style(note->title_label, rc_style);
	gtk_widget_modify_style(note->close_button, rc_style);
	gtk_widget_modify_style(note->text_view, rc_style);
	gtk_widget_modify_style(note->event_box_move1, rc_style);
	gtk_widget_modify_style(note->event_box_move2, rc_style);
	gtk_widget_modify_style(note->event_box_resize, rc_style);
	gtk_rc_style_unref(rc_style);
    } 
    /* user color */
    else {
	
	rc_style_base = gtk_rc_style_new();
	rc_style_bg = gtk_rc_style_new();
	/* base */
	rc_style_base->base[GTK_STATE_NORMAL] = notes_applet.note_color;
	rc_style_base->bg[GTK_STATE_NORMAL] = note_color_off;
	rc_style_base->color_flags[GTK_STATE_NORMAL] = GTK_RC_BASE|GTK_RC_BG;
	/* bg */
	rc_style_bg->bg[GTK_STATE_NORMAL] = note_color_off;
	rc_style_bg->bg_pixmap_name[GTK_STATE_NORMAL] = g_strdup("<none>");
	
	rc_style_bg->bg[GTK_STATE_PRELIGHT] = note_color_off;
	rc_style_bg->bg[GTK_STATE_ACTIVE] = notes_applet.note_color;

	rc_style_bg->color_flags[GTK_STATE_NORMAL] = GTK_RC_BG;
	rc_style_bg->color_flags[GTK_STATE_PRELIGHT] = GTK_RC_BG;
	rc_style_bg->color_flags[GTK_STATE_ACTIVE] = GTK_RC_BG;
	
	gtk_widget_modify_style(note->note_w, rc_style_bg);
	gtk_widget_modify_style(note->title_entry, rc_style_base);
	gtk_widget_modify_style(note->title_label, rc_style_bg);
	gtk_widget_modify_style(note->close_button, rc_style_bg);
	gtk_widget_modify_style(note->text_view, rc_style_base);
	gtk_widget_modify_style(note->event_box_move1, rc_style_bg);
	gtk_widget_modify_style(note->event_box_move2, rc_style_bg);
	gtk_widget_modify_style(note->event_box_resize, rc_style_bg);

	gtk_rc_style_unref(rc_style_base);
	gtk_rc_style_unref(rc_style_bg);
    }

    return;
}

void
notes_update_colors(void)
{
    GList *list;
    Note *note;

    if (notes_applet.notes != NULL) {
	list = g_list_first(notes_applet.notes);
	while (list != NULL) {
	    note = list->data;
	    /* update */
	    notes_update_note_colors(note);
	    list = g_list_next(list);
	}
    }

    return;
}

/* set new tooltips */
void
notes_set_tooltips(void)
{
    gchar *tooltips;
    gint length = g_list_length(notes_applet.notes);

    tooltips = g_malloc(sizeof(gchar) * 100);
    
    if (length == 0) {
	sprintf(tooltips, 
		"Doubleclick or press the middle mouse "
		"button to create a note");
    } else {
	sprintf(tooltips, "%d notes\nLeft mouse button to show/hide notes", 
		length);
    }
    gtk_tooltips_set_tip(notes_applet.tooltips, notes_applet.event_box, 
			 tooltips, NULL);
    g_free(tooltips);
    
    return;
}

/* update all notes to set their sticky state */
void
notes_update_sticky(void)
{
    GList *list;
    Note *note;

    if (notes_applet.notes != NULL) {
	list = g_list_first(notes_applet.notes);
	while (list != NULL) {
	    note = list->data;
	    /* update */
	    if (notes_applet.notes_sticky == TRUE) {
		gtk_window_stick(GTK_WINDOW(note->note_w));
	    } else {
		gtk_window_unstick(GTK_WINDOW(note->note_w));
	    }
	    list = g_list_next(list);
	}
    }

    return;
}

/* iterates over notes and if notes_applet.show_notes is TRUE then
   display all notes otherwise hide them, of course */
void
notes_update_visibility(void)
{
    GList *list;
    Note *note;
    
    list = g_list_first(notes_applet.notes);
    while (list != NULL) {
	note = list->data;
	/* update visibility*/
	if (notes_applet.show_notes == TRUE) {
	    /* only show if not already visibile */
	    /* use gtk_window_present? */
	    if (gdk_window_is_visible((note->note_w)->window) == FALSE) {
		/* move window to position */
		gtk_window_move(GTK_WINDOW(note->note_w), 
			    note->x, note->y);
		
		gtk_widget_show(note->note_w);
	    }
	} else {
	    /* store window position */
	    if (gdk_window_is_visible((note->note_w)->window) == TRUE) {
		gtk_window_get_position(GTK_WINDOW(note->note_w),
					&note->x, &note->y);
		gtk_widget_hide(note->note_w);
	    }
	}
	list = g_list_next(list);
    }

    return;
}

gboolean
timeout_button_press(int *id)
{
    /* reset id */
    *id = 0;
    
    notes_applet.show_notes = (notes_applet.show_notes == FALSE);
	
    notes_update_visibility();
    notes_update_sticky();

    return FALSE;
}

gboolean
on_applet_button_press_event(GtkWidget *widget, GdkEventButton *event,
			     gpointer data)
{
    Note* note;
    static int timeout_id = 0;

    /* Double click event sequence:
     * GDK_BUTTON_PRESS, GDK_BUTTON_RELEASE, GDK_BUTTON_PRESS,
     * GDK_2BUTTON_PRESS, GDK_BUTTON_RELEASE
     */
    
    /* single button press and button 1 */
    if ((event->type == GDK_BUTTON_PRESS) && (event->button == 1)) {
	/* hide or show */
	if (timeout_id <= 0)
	{
	    timeout_id = g_timeout_add(250, 
				       (GSourceFunc)timeout_button_press,
			               &timeout_id);
	}
    }
    /* double button click and button 1  or button 2 */
    else if ((event->type == GDK_BUTTON_PRESS && event->button == 2) || 
	     (event->type == GDK_2BUTTON_PRESS && event->button == 1)) 
    {
	if (timeout_id > 0)
	{
	    g_source_remove(timeout_id);
	    timeout_id = 0;
	}

	/* show the other notes */
	notes_applet.show_notes = TRUE;
	notes_update_visibility();

	/* create a new note, it will be added to list of notes */
	note = notes_new_note();

	/* store window position */
	gtk_widget_show(note->note_w);
	
	gtk_window_get_position(GTK_WINDOW(note->note_w),
				&note->x, &note->y);

	/* update colors */
	notes_update_note_colors(note);
	notes_update_sticky();

	DBG("Note added\n");
    }  
    
    return FALSE;
}

gboolean
notes_load_config(void)
{
    xmlNodePtr cur;
    xmlDocPtr doc;

    gchar *filename;
    gchar *error_str;
    /* note info in config file */
    gchar *x, *y, *w, *h, *title, *text; 

    error_str = g_malloc(sizeof(char) * 256);

    /* set config file name */
    filename = xfce_get_userfile("notes.xml", NULL);

    if (!g_file_test(filename, G_FILE_TEST_EXISTS)) {
	g_free(error_str);
	g_free(filename);
	return FALSE;
    }

    /* parse the file */
    doc = xmlParseFile(filename);
    if (doc == NULL) {
	sprintf(error_str, "Error parsing config file '%s'", filename);
	xfce_info(_(error_str));
	g_free(error_str);
	return FALSE;
    }
    cur = xmlDocGetRootElement(doc);

    if (xmlStrcmp(cur->name, (const xmlChar *)"notes")) {
	sprintf(error_str, "Config file '%s' of wrong type", filename);
	g_free(error_str);
	xmlFreeDoc(doc);
	xfce_info(_(error_str));
	return FALSE;
    }

    cur = cur->xmlChildrenNode;
    while (cur != NULL) {
	/* NOTE */
	if ((!xmlStrcmp(cur->name, (const xmlChar *)"note"))) {
	    x = xmlGetProp(cur, "x");
	    y = xmlGetProp(cur, "y");
	    w = xmlGetProp(cur, "w");
	    h = xmlGetProp(cur, "h");
	    title = xmlGetProp(cur, "title");
	    text = xmlNodeGetContent(cur);
	    /* recreate the note */
	    notes_new_note_with_attr(text, title,
				     atoi(x), atoi(y),
				     atoi(w), atoi(h));
	}
	cur = cur->next;
    }

    /* prevent from saving loaded notes */
    notes_applet.notes_saved = TRUE;
    
    g_free(error_str);

    return TRUE;
}

void
notes_store_config(void)
{
    GList *list;
    Note *note;
    
    GtkTextIter start, end;
    GtkTextBuffer *buffer;
    gchar *text;

    gchar *filename;

    /* note info in config file */
    gchar x[5], y[5], w[5], h[5];

    filename = xfce_get_userfile("notes.xml", NULL);

    list = g_list_first(notes_applet.notes);
    while (list != NULL) {
	note = list->data;
	/* get info about note to store */
	/* only get it if the windows are visible, otherwise x and y will
	   be 0 */
	if (notes_applet.show_notes == TRUE) {
	    gtk_window_get_position(GTK_WINDOW(note->note_w),
				    &note->x, &note->y);
	}
	gtk_window_get_size(GTK_WINDOW(note->note_w), &note->w, &note->h);
	/* convert info */
	sprintf(x, "%d", note->x);
	sprintf(y, "%d", note->y);
	sprintf(w, "%d", note->w);
	sprintf(h, "%d", note->h);

	xmlSetProp(note->xml_tag, "x", x);
	xmlSetProp(note->xml_tag, "y", y);
	xmlSetProp(note->xml_tag, "w", w);
	xmlSetProp(note->xml_tag, "h", h);

	/* title */
	xmlSetProp(note->xml_tag, "title", 
		   gtk_label_get_text(GTK_LABEL(note->title_label)));

	/* get text from text view */
	buffer 
	    = gtk_text_view_get_buffer(GTK_TEXT_VIEW(note->text_view));
	gtk_text_buffer_get_bounds (buffer, &start, &end);
	text = gtk_text_iter_get_text (&start, &end);

	/* set it */
	xmlNodeSetContent(note->xml_tag, text);

	g_free(text);
	
	list = g_list_next(list);
    }

    /* deleting old config file */
    unlink(filename);
    /* saving new config file */
    xmlSaveFile(filename, notes_applet.doc);


    return;
}

void
notes_new_note_with_attr(gchar *text, gchar *title, 
			 gint x, gint y, gint w, gint h)
{
    GtkTextBuffer *buffer;
    Note *note;

    note = notes_new_note();
    /* set attribs */
    note->x = x;
    note->y = y;
    note->w = w;
    note->h = h;
    gtk_label_set_text(GTK_LABEL(note->title_label), title);
    gtk_window_resize(GTK_WINDOW(note->note_w), w, h);
    gtk_window_move(GTK_WINDOW(note->note_w), x, y);
    /* set text */
    buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(note->text_view));
    gtk_text_buffer_set_text(buffer, text, strlen(text));
    gtk_text_view_set_buffer(GTK_TEXT_VIEW(note->text_view), buffer);

    /* display note */
    if (notes_applet.show_notes == TRUE) {
	gtk_widget_show(note->note_w);
    }

    return;
}

void
notes_note_changed(GtkEditable *editable, gpointer data)
{
    /* set flag */
    notes_applet.notes_saved = FALSE;
    g_timer_start(notes_applet.notes_timer);
    return;
}

/* the caller of notes_new_node have to show the note->note_w widget,
   i.e. it is not done here */
Note*
notes_new_note(void)
{
    GtkTextBuffer *text_buffer;
    Note *note;
    xmlNodePtr xmlptr;
    static gint note_id_count = 0;
    
    note = notes_create_note();

    /* id count */
    note->id = note_id_count;
    note_id_count++;

    /* connect close button on the note */
    g_signal_connect(G_OBJECT(note->close_button), "clicked",
		     G_CALLBACK(notes_delete_note), (gpointer)note);
    /* notify if something was changed */
    text_buffer = gtk_text_view_get_buffer(GTK_TEXT_VIEW(note->text_view));
    g_signal_connect(G_OBJECT(text_buffer), "changed",
		     G_CALLBACK(notes_note_changed), (gpointer)note);

    /* setup the xml */
    xmlptr = xmlDocGetRootElement(notes_applet.doc);
    note->xml_tag = xmlNewTextChild(xmlptr, NULL, "note", NULL);

    /* add to list */
    notes_applet.notes = g_list_append(notes_applet.notes, note);

    /* set new tooltips */
    notes_set_tooltips();
    
    return note;
}

static void
notes_free_note(Note *note)
{
    /* by destroying the note_w, close_button will also be destroyed */
    gtk_widget_destroy(note->note_w);

    xmlUnlinkNode(note->xml_tag);
    //xmlFreeNode(note->xml_tag);

    g_object_unref(notes_applet.resize_pixbuf);
    g_object_unref(notes_applet.close_pixbuf);

    return;
}

static void
notes_free(Control *ctrl)
{
    GList *cur;
    Note *note;
    
    g_return_if_fail(ctrl != NULL);
    g_return_if_fail(ctrl->data != NULL);

    /* save notes */
    notes_store_config();

    cur = g_list_first(notes_applet.notes);
    while (cur) {
	note = cur->data;
	/* get rid of the widgets */
	notes_free_note(note);
	cur = g_list_next(cur);
    }
    g_list_free(notes_applet.notes);
    return;
    
}

static void
notes_delete_note(GtkWidget *widget, gpointer data)
{
    GList *cur;
    Note *note, *note_user;

    note_user = (Note *)data;

    cur = g_list_first(notes_applet.notes);
    while (cur != NULL) {
	note = cur->data;
	/* we found it, remove it */
	if (note->id == note_user->id) {
	    notes_applet.notes = g_list_remove_link(notes_applet.notes, cur);
	    notes_free_note(note);
	    g_list_free(cur);

	    /* set new tooltips */
	    notes_set_tooltips();

	    return;
	}
	cur = g_list_next(cur);
    }

    return;
}

static void
notes_read_config(Control *ctrl, xmlNodePtr parent)
{
    xmlNodePtr cur, node;
    xmlChar *user_color;
    GdkColor *colors;
    GdkPixbuf *pixbuf_orig;
    gint n_colors;
    

    /* parse */
    node = parent->children;
    while (node != NULL) {
	if (xmlStrEqual(node->name, (const xmlChar *)"notes")) {
	    cur = node->children;
	    while (cur != NULL) {
		/* icon */
		if (xmlStrEqual(cur->name, (const xmlChar *)"icon")) {
		    notes_applet.icon_filename = xmlNodeGetContent(cur);
		    /* update the pixbuf */
		    pixbuf_orig = notes_applet.pixbuf;
		    notes_applet.pixbuf = 
			gdk_pixbuf_new_from_file(notes_applet.icon_filename,
						 NULL);
		    g_object_unref(pixbuf_orig);
		    /* reset the icon in the panel through a shortcut */
		    notes_set_size(NULL, notes_applet.panel_size);
		}
		/* show notes */
		if (xmlStrEqual(cur->name, (const xmlChar *)"show_notes")) {
		    if (xmlStrEqual(xmlNodeGetContent(cur), 
				    (const xmlChar *)"true")) {
			notes_applet.show_notes = TRUE;
		    } else {
			notes_applet.show_notes = FALSE;
		    }
		}
		/* user color */
		if (xmlStrEqual(cur->name, (const xmlChar *)"user_color")) {
		    user_color = xmlNodeGetContent(cur);
		    /* if successfully parsed */
		    if (gtk_color_selection_palette_from_string(user_color,
								&colors,
								&n_colors)) {
			/* the first in the array is the user color */
			notes_applet.note_color = colors[0];
		    }
		}
		/* sticky notes */
		if (xmlStrEqual(cur->name, (const xmlChar *)"notes_sticky")) {
		    if (xmlStrEqual(xmlNodeGetContent(cur),
				    (const xmlChar *)"true")) {
			notes_applet.notes_sticky = TRUE;
		    } else {
			notes_applet.notes_sticky = FALSE;
		    }
		}
		/* system color boolean */
		if (xmlStrEqual(cur->name, (const xmlChar *)"system_colors")) {
		    if (xmlStrEqual(xmlNodeGetContent(cur), 
				    (const xmlChar *)"true")) {
			notes_applet.system_colors = TRUE;
		    } else {
			notes_applet.system_colors = FALSE;
		    }
		}
		
		cur = cur->next;
	    }
	}
	node = node->next;
    }

    /* load config file, i.e. this constructs old notes which have
       been stored on disk */
    notes_load_config();

    /* do some updating */
    notes_update_visibility();
    notes_update_colors();
    /* set tooltips */
    notes_set_tooltips();

    return;
}

static void
notes_write_config(Control *ctrl, xmlNodePtr parent)
{
    xmlNodePtr cur;
    GdkColor colors[1];
    gchar *color_palette;

    cur = xmlNewTextChild(parent, NULL, "notes", NULL);
    /* icon */
    xmlNewTextChild(cur, NULL, "icon", notes_applet.icon_filename);
    /* show notes */
    xmlNewTextChild(cur, NULL, "show_notes",
		    (notes_applet.show_notes == TRUE) ? "true" : "false");
    /* user color */
    /* make an array of colors but use only first item, i.e. index 0 */
    colors[0] = notes_applet.note_color;
    color_palette = 
	gtk_color_selection_palette_to_string(colors, 1);
    xmlNewTextChild(cur, NULL, "user_color", color_palette);
    /* sticky notes */
    xmlNewTextChild(cur, NULL, "notes_sticky",
		    (notes_applet.notes_sticky == TRUE) ? "true" : "false");
    /* system color boolean */
    xmlNewTextChild(cur, NULL, "system_colors",
		    (notes_applet.system_colors == TRUE) ? "true" : "false");

    return;
}

static void
notes_attach_callback(Control *ctrl, const gchar *signal, GCallback cb,
		gpointer data)
{
    return;
}

void 
notes_destroy_cb(GtkWidget *widget, gpointer data)
{
    gtk_widget_destroy(widget);
    return;
}

gboolean
notes_save_notes_timeout(gpointer data)
{
    if (notes_applet.notes_saved == FALSE) {
	if (g_timer_elapsed(notes_applet.notes_timer, NULL) > 5.0) {
	    notes_store_config();
	    DBG("notes saved\n");
	    notes_applet.notes_saved = TRUE;
	    g_timer_stop(notes_applet.notes_timer);
	}
    }
    /* return tree to keep timeout active */
    return TRUE;
}

static gboolean
notes_control_new(Control *ctrl)
{
    GtkWidget *event_box;
    GdkPixbuf *pixbuf;
    GtkWidget *image;

    xmlNodePtr xmlptr;

    /* create event box */
    event_box = gtk_event_box_new();
    gtk_container_add(GTK_CONTAINER(ctrl->base), event_box);

    /* tooltips */
    notes_applet.tooltips = gtk_tooltips_new();

    notes_applet.event_box = event_box;

    gtk_widget_show(event_box);
    /* connect main applet event box */
    g_signal_connect(G_OBJECT(event_box), "button-press-event",
		     G_CALLBACK(on_applet_button_press_event),
		     NULL);

    /* icon for applet */
    notes_applet.icon_filename = APPLET_PIXMAP;
    pixbuf = gdk_pixbuf_new_from_file(APPLET_PIXMAP, NULL);
    notes_applet.pixbuf = pixbuf;

    image = gtk_image_new_from_pixbuf(pixbuf);
    /* will be replaced in set_size anyway, don't display it ... */
    gtk_container_add(GTK_CONTAINER(event_box), image);
    gtk_widget_show(image);

    ctrl->data = (gpointer)&notes_applet;
    ctrl->with_popup = FALSE;
    
    /* init */
    /* loads the close and resize pixbufs needed for the notes */
    notes_init_note();
    notes_applet.show_notes = TRUE;
    notes_applet.notes = NULL;
    notes_applet.system_colors = TRUE;
    notes_applet.notes_saved = TRUE;
    /* make a default user color, yellow */
    gdk_color_parse("yellow", &notes_applet.note_color);

    /* create a timer */
    notes_applet.notes_timer = g_timer_new();

    /* create a root elmt  */
    notes_applet.doc = xmlNewDoc("1.0");
    xmlptr = xmlNewNode(NULL, "notes");
    xmlDocSetRootElement(notes_applet.doc, xmlptr);

    /* add timeout to save notes if required */
    /* call notes_save_notes_timeout every 2 seconds */
    g_timeout_add(5000, notes_save_notes_timeout, NULL);

    gtk_widget_set_size_request(ctrl->base, -1, -1);

    return TRUE;
}

void
notes_set_size(Control *ctrl, int size)
{
    GList *list;
    GtkWidget *img;
    GdkPixbuf *pix;
    gint dim = icon_size[size];

    list = gtk_container_get_children(GTK_CONTAINER(notes_applet.event_box));
    list = g_list_first(list);

    g_object_ref(notes_applet.event_box);
    gtk_container_foreach(GTK_CONTAINER(notes_applet.event_box),
			  (GtkCallback)notes_destroy_cb, NULL);
    
    pix = gdk_pixbuf_copy(notes_applet.pixbuf);
    pix = gdk_pixbuf_scale_simple(pix, dim, dim, GDK_INTERP_BILINEAR);
    img = gtk_image_new_from_pixbuf(pix);
    gtk_widget_show(img);
    gtk_container_add(GTK_CONTAINER(notes_applet.event_box), img);
    g_object_unref(notes_applet.event_box); 

    gtk_widget_set_size_request(notes_applet.event_box, dim, dim);

    /* save size, needed for changing icon */
    notes_applet.panel_size = size;

    return;
}

static void
notes_create_options (Control *ctrl, GtkContainer *con, GtkWidget *done)
{
    GtkWidget *widget;

    widget = notes_create_applet_options(con);
    gtk_container_add(con, widget);

    return;
}

/* initialization */
G_MODULE_EXPORT void
xfce_control_class_init(ControlClass *cc)
{

    cc->name		= "notes";
    cc->caption		= _("Notes");
    
    cc->create_control	= (CreateControlFunc)notes_control_new;
    
    cc->free		= notes_free;
    cc->attach_callback	= notes_attach_callback;
    
    cc->read_config	= notes_read_config;
    cc->write_config	= notes_write_config;
    cc->create_options  = notes_create_options;
    
    cc->set_size	= notes_set_size;
    
    /* unused
     * cc->set_orientation
     * cc->set_theme
     */

    return;
}

/* required! defined in panel/plugins.h */
XFCE_PLUGIN_CHECK_INIT
