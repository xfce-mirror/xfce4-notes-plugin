/* $Id$
 *
 *  Notes - panel plugin for Xfce Desktop Environment
 *          popup command to show the notes
 *  Copyright (C) 2002-2006  Olivier Fourdan
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
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <X11/Xlib.h>

#include "xfce4-popup-notes.h"



static gboolean
notes_plugin_check_is_running (GtkWidget *widget,
                               Window *xid)
{
  GdkScreen          *gscreen;
  gchar              *selection_name;
  Atom                selection_atom;

  gscreen = gtk_widget_get_screen (widget);
  selection_name = g_strdup_printf (XFCE_NOTES_SELECTION"%d",
                                    gdk_screen_get_number (gscreen));
  selection_atom = XInternAtom (GDK_DISPLAY (), selection_name, FALSE);

  if ((*xid = XGetSelectionOwner (GDK_DISPLAY (), selection_atom)))
    return TRUE;

  return FALSE;
}

gint
main (gint argc, gchar *argv[])
{
  GdkEventClient        gev;
  GtkWidget            *win;
  Window                id;
  gchar                *message = NULL;

  gboolean              opt_show_hide = FALSE;
  gboolean              opt_menu = FALSE;
  GError               *opt_error = NULL;

  GOptionContext *context =
    g_option_context_new ("- command the Xfce 4 notes plugin");
  GOptionEntry entries[] = 
    {
      { "show-hide", 0, 0, G_OPTION_ARG_NONE, &opt_show_hide,
        "Default action that show/hide all the windows", NULL },
      { "menu", 'm', 0, G_OPTION_ARG_NONE, &opt_menu,
        "Popup the menu from the panel button", NULL },
      { NULL }
    };

#if GLIB_CHECK_VERSION (2, 12, 0)
  g_option_context_set_summary (context, "The default action is to show/hide all windows");
#endif
  g_option_context_add_main_entries (context, entries, NULL);
  if (G_LIKELY (! g_option_context_parse (context, &argc, &argv, &opt_error)))
    {
      g_printerr ("%s\n", opt_error->message);
      g_error_free (opt_error);
      return -1;
    }

  if (opt_menu)
    message = g_strdup_printf (NOTES_MSG_MENU);
  else
    message = g_strdup_printf (NOTES_MSG_SHOW_HIDE);

  gtk_init (&argc, &argv);

  win = gtk_invisible_new ();
  gtk_widget_realize (win);

  gev.type              = GDK_CLIENT_EVENT;
  gev.window            = win->window;
  gev.send_event        = TRUE;
  gev.message_type      = gdk_atom_intern ("STRING", FALSE);
  gev.data_format       = 8;
  g_snprintf (gev.data.b, sizeof (gev.data.b), message);

  if (notes_plugin_check_is_running (win, &id))
    gdk_event_send_client_message ((GdkEvent *)&gev, (GdkNativeWindow)id);
  else
    g_warning ("Can't find the xfce4-notes-plugin.\n");
  gdk_flush ();

  gtk_widget_destroy (win);

  return FALSE;
}

