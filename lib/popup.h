/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2002-2006  Olivier Fourdan
 *  Copyright (C) 2009-2010       Mike Massonnet <mmassonnet@xfce.org>
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

#ifndef __POPUP_H__
#define __POPUP_H__

#include <gtk/gtk.h>

#define XFCE_NOTES_SELECTION    "XFCE_NOTES_SELECTION"
#define NOTES_MSG_SHOW_HIDE     "SHOW_HIDE"

gboolean popup_set_x_selection (GtkWidget *widget);
const gchar* popup_get_message_from_event (GdkEventClient *event);

#endif
