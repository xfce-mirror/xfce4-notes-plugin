/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2002-2006  Olivier Fourdan
 *  Copyright (C) 2009       Mike Massonnet <mmassonnet@xfce.org>
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
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
 */

#include <X11/Xlib.h>
#include <gdk/gdkx.h>
#include <gtk/gtk.h>

#include "popup.h"

gboolean popup_set_x_selection (GtkWidget *widget) {
	GdkScreen *screen;
	gchar     *selection_name;
	Atom       selection_atom;
	Window     id;
	Display   *display;

	gtk_widget_realize (widget);
	id = GDK_WINDOW_XID (widget->window);

	display = GDK_DISPLAY ();
	screen = gtk_widget_get_screen (widget);
	selection_name = g_strdup_printf (XFCE_NOTES_SELECTION"%d", gdk_screen_get_number (screen));
	selection_atom = XInternAtom (display, selection_name, FALSE);

	if (XGetSelectionOwner (display, selection_atom)) {
		return FALSE;
	}

	XSelectInput (display, id, PropertyChangeMask);
	XSetSelectionOwner (display, selection_atom, id, GDK_CURRENT_TIME);

	return TRUE;
}

const gchar* popup_get_message_from_event (GdkEventClient *event) {
	if (G_LIKELY (event->data_format == 8 && *(event->data.b) != '\0')) {
		return event->data.b;
	}
	return NULL;
}

