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

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <gtk/gtk.h>
#include <gdk/gdkkeysyms.h>
#include <libxml/parser.h>

#include <libxfce4util/debug.h>
#include <libxfce4util/i18n.h>
#include <libxfcegui4/dialogs.h>
#include <libxfce4util/util.h>
#include <panel/plugins.h>
#include <panel/xfce.h>

#define APPLET_PIXMAP ICONDIR "/note.png"
#define ICON_W 12
#define ICON_H 12

typedef struct __note {
    /* the window */
    GtkWidget *note_w;
    GtkWidget *close_button;
    GtkWidget *text_view;

    /* title */
    GtkWidget *title_label;
    GtkWidget *title_entry;

    /* needed to colour setting */
    GtkWidget *event_box_move1;
    GtkWidget *event_box_move2;
    GtkWidget *event_box_resize;

    /* pointer to the tag <note></note> */
    xmlNodePtr xml_tag;

    gint x, y;
    gint w, h;

    gint id;

} Note;

typedef struct __note_applet {
    /* all notes */
    GList *notes;
    /* config  */
    xmlDocPtr doc;

    /* tooltips */
    GtkTooltips *tooltips;
    
    /* needed for set_resize */
    GtkWidget *event_box;
    /* pixbuf of icon shown in panel */
    GdkPixbuf *pixbuf;
    gchar *icon_filename;

    /* note pixbufs */
    GdkPixbuf *close_pixbuf, *resize_pixbuf;

    gint panel_size;

    /* notes edited flag */
    gboolean notes_saved;

    /* user color */
    GdkColor note_color;
    gboolean system_colors;

    /* other options */
    gboolean notes_sticky;
    gboolean show_notes;
} NoteApplet;


/* function declarations */

/* notes_applet.c */
void
notes_update_note_colors(Note *note);
void
notes_update_colors(void);
void
notes_set_tooltips(void);
void
notes_update_sticky(void);
void
notes_update_visibility(void);
gboolean 
on_applet_button_press_event(GtkWidget *widget, GdkEventButton *event, 
			     gpointer data);
gboolean 
notes_load_config(void);
void 
notes_store_config(void);
void 
notes_new_note_with_attr(gchar *text, gchar *title, 
			 gint x, gint y, gint w, gint h);
void
notes_note_changed(GtkEditable *editable, gpointer data);
Note*
notes_new_note(void);
void
notes_set_size(Control *ctrl, int size);

/* notes_options.c */
void
on_sticky_check_button_toggled(GtkToggleButton *button, gpointer data);
void
on_system_colors_check_button_toggled(GtkToggleButton *button, gpointer data);
void
notes_color_selection_ok(GtkDialog *color_dialog);
void
notes_color_selection_cancel(GtkDialog *color_dialog);
void
notes_color_selection_dialog(GtkWidget *widget, gpointer data);
void
notes_icon_selection_dialog(GtkWidget *widget, gpointer data);
GtkWidget*
notes_create_applet_options(GtkContainer *con);

/* notes.c */
gboolean
on_title_change(GtkWidget *widget, GdkEventButton *event, gpointer data);
void
on_title_change_done(Note *note);
gboolean
on_title_key_press(GtkWidget *widget, GdkEventKey *event, gpointer data);
gboolean
on_text_view_focus_in(GtkWidget *widget, GdkEventFocus *ev, gpointer data);
gboolean
on_move_window(GtkWidget *widget, GdkEventButton *event, gpointer data);
gboolean
on_resize_window(GtkWidget *widget, GdkEventButton *event, gpointer data);
void
notes_init_note(void);
Note*
notes_create_note(void);

    
    
