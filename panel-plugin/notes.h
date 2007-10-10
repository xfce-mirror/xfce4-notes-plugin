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

#ifndef NOTES_H
#define NOTES_H

#include <libxfce4panel/xfce-panel-plugin.h>
/* #include <gdk/gdkkeysyms.h> FIXME */

typedef struct _NotesPlugin     NotesPlugin;
struct _NotesPlugin
{
  XfcePanelPlugin      *panel_plugin;
  GSList               *windows;
  /* guint                 timeout_id; FIXME */
  gchar                *config_file;
  gchar                *notes_path;

  GtkWidget            *btn_panel;
  GtkWidget            *icon;

  GtkTooltips          *tooltips;
};

typedef enum
{
  LAST_STATE,
  ALWAYS,
  NEVER,
} ShowOnStartup;

typedef struct _NotesWindow     NotesWindow;
struct _NotesWindow
{
  NotesPlugin          *notes_plugin;
  GSList               *notes;

  gint                  x, y, w, h;
  gboolean              always_on_top;
  gboolean              show_in_pager; /* XXX Replaces show in task switcher */
  ShowOnStartup         show_on_startup;
  gboolean              show_statusbar;
  gboolean              stick;
  gboolean              visible;

  GtkWidget            *window;
  GtkWidget            *frame;
  GtkWidget            *vbox;
  GtkWidget            *hbox;
  GtkWidget            *btn_add;
  GtkWidget            *btn_del;
  GtkWidget            *btn_close;
  GtkWidget            *title;
  GtkWidget            *eb_move; /* event box */
  GtkWidget            *notebook;
  GtkWidget            *statusbar;
};

typedef struct _NotesNote       NotesNote;
struct _NotesNote
{
  NotesWindow          *notes_window;

  GtkWidget            *title;
  GtkWidget            *scrolled_window;
  GtkWidget            *text_view;
};

typedef struct _NotesOptions    NotesOptions;
struct _NotesOptions
{
};

const gchar *           notes_window_read_name  (NotesPlugin *notes_plugin);

NotesWindow *           notes_window_new        (NotesPlugin *notes_plugin,
                                                 const gchar *notes_window_name);
void                    notes_window_load_data  (NotesWindow *notes_window);

void                    notes_window_configure  (NotesWindow *notes_window);

void                    notes_window_response   (GtkWidget *widget,
                                                 int response,
                                                 NotesWindow *notes_window);
void                    notes_window_save       (NotesWindow *notes_window);

const gchar *           notes_note_read_name    (NotesWindow *notes_window);

NotesNote *             notes_note_new          (NotesWindow *notes_window,
                                                 const gchar *notes_note_name);
void                    notes_note_load_data    (NotesNote *notes_note,
                                                 GtkTextBuffer *buffer);

#endif
