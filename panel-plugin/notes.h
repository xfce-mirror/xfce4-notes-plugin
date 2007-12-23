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

#include <gtk/gtk.h>
#include <libxfce4panel/xfce-panel-plugin.h>
#include <libxfce4panel/xfce-panel-convenience.h>
#include <libxfcegui4/libxfcegui4.h>
#ifdef HAVE_THUNAR_VFS
#include <thunar-vfs/thunar-vfs.h>
#endif

typedef struct _NotesPlugin     NotesPlugin;
struct _NotesPlugin
{
  XfcePanelPlugin      *panel_plugin;
  GSList               *windows;
  gchar                *config_file;
  gchar                *notes_path;
  guint                 timeout;

  GtkWidget            *btn_panel;
  GtkWidget            *icon_panel;
  GtkWidget            *menu;
  GtkWidget            *icon;
  GtkWidget            *icon_rev;

  GtkTooltips          *tooltips;

#ifdef HAVE_THUNAR_VFS
  ThunarVfsMonitor     *monitor;
  ThunarVfsPath        *thunar_vfs_path;
  ThunarVfsMonitorHandle *monitor_handle;
#endif
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

  gchar                *name;
  guint                 timeout_start_move;
  gint                  x, y, w, h;
  ShowOnStartup         show_on_startup;
  gboolean              show_statusbar;
  gboolean              above;
  gboolean              sticky;
  gboolean              visible;
  gint                  transparency;
  gchar                *font;

  GtkWidget            *window;
  GtkWidget            *frame;
  GtkWidget            *vbox;
  GtkWidget            *hbox;
  GtkWidget            *btn_add;
  GtkWidget            *btn_del;
  GtkWidget            *btn_menu;
  GtkWidget            *btn_close;
  GtkWidget            *menu;
  GtkWidget            *menu_options;
  GtkWidget            *mi_options;
  GtkWidget            *eb_move; /* event box */
  GtkWidget            *title;
  GtkWidget            *notebook;
  GtkWidget            *statusbar;

  GtkAccelGroup        *accel_group;

#ifdef HAVE_THUNAR_VFS
  ThunarVfsPath        *thunar_vfs_path;
  ThunarVfsMonitorHandle *monitor_handle;
#endif
};

typedef struct _NotesNote       NotesNote;
struct _NotesNote
{
  NotesWindow          *notes_window;

  gchar                *name;
  guint                 timeout;

  GtkWidget            *title;
  GtkWidget            *scrolled_window;
  GtkWidget            *text_view;
};

typedef struct _NotesOptions    NotesOptions;
struct _NotesOptions
{
};



const gchar *           notes_window_read_name          (NotesPlugin *notes_plugin);

NotesWindow *           notes_window_new                (NotesPlugin *notes_plugin);

NotesWindow *           notes_window_new_with_label     (NotesPlugin *notes_plugin,
                                                         const gchar *window_name);
void                    notes_window_load_data          (NotesWindow *notes_window);

void                    notes_window_save_data          (NotesWindow *notes_window);

void                    notes_window_destroy            (NotesWindow *notes_window);

void                    notes_window_show               (NotesWindow *notes_window);

gboolean                notes_window_hide               (NotesWindow *notes_window);

inline void             notes_window_sort_names         (NotesWindow *notes_window);

gint                    notes_window_strcasecmp         (NotesWindow *notes_window0,
                                                         NotesWindow *notes_window1);


const gchar *           notes_note_read_name            (NotesWindow *notes_window);

NotesNote *             notes_note_new                  (NotesWindow *notes_window,
                                                         const gchar *note_name);
void                    notes_note_load_data            (NotesNote *notes_note,
                                                         GtkTextBuffer *buffer);
gboolean                notes_note_save_data            (NotesNote *notes_note);

void                    notes_note_destroy              (NotesNote *notes_note);

#endif
