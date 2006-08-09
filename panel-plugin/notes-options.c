/* $Id$
 *
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2003  Jakob Henriksson <b0kaj+dev@lysator.liu.se>
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


static void     on_toggle_show (GtkWidget *, NotesPlugin *);
static void     on_toggle_task_switcher (GtkWidget *, NotesPlugin *);
static void     on_toggle_always_on_top (GtkWidget *, NotesPlugin *);
static void     on_toggle_stick (GtkWidget *, NotesPlugin *);
static void     on_toggle_vscrollbar (GtkWidget *, NotesPlugin *);


GtkWidget *
notes_options_new (NotesPlugin *notes)
{
    GtkWidget *dialog, *vbox;
    GtkWidget *cb_show, *cb_task_switcher, *cb_always_on_top, *cb_stick;
    GtkWidget *hseparator;
    GtkWidget *cb_vscrollbar;
    NotesOptions *options;

    DBG ("New Notes Options");

    options = &notes->options;

    dialog =
        xfce_titled_dialog_new_with_buttons (_("Notes"), NULL,
                                             GTK_DIALOG_NO_SEPARATOR,
                                             GTK_STOCK_CLOSE, GTK_RESPONSE_OK,
                                             NULL);
    xfce_titled_dialog_set_subtitle (XFCE_TITLED_DIALOG (dialog),
                                     _("Properties"));

    gtk_window_set_position (GTK_WINDOW (dialog), GTK_WIN_POS_CENTER);
    gtk_window_set_icon_name (GTK_WINDOW (dialog), "xfce4-panel");
    gtk_window_set_keep_above (GTK_WINDOW (dialog), TRUE);
    gtk_window_stick (GTK_WINDOW (dialog));

    /* Create main box */
    vbox = gtk_vbox_new (2, FALSE);
    gtk_container_add (GTK_CONTAINER (GTK_DIALOG (dialog)->vbox), vbox);
    gtk_widget_show (vbox);

    gtk_container_set_border_width (GTK_CONTAINER (vbox), 12);

    cb_show = gtk_check_button_new_with_label (_("Show notes at startup"));
    gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (cb_show), options->show);
    gtk_box_pack_start (GTK_BOX (vbox), cb_show, FALSE, FALSE, 0);
    gtk_widget_show (cb_show);

    g_signal_connect (cb_show, "toggled", G_CALLBACK (on_toggle_show), notes);

    cb_task_switcher =
        gtk_check_button_new_with_label (_("Show in the task list"));
    gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (cb_task_switcher),
                                  options->task_switcher);
    gtk_box_pack_start (GTK_BOX (vbox), cb_task_switcher, FALSE, FALSE, 0);
    gtk_widget_show (cb_task_switcher);

    g_signal_connect (cb_task_switcher, "toggled",
                      G_CALLBACK (on_toggle_task_switcher), notes);

    cb_always_on_top =
        gtk_check_button_new_with_label (_("Always on top"));
    gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (cb_always_on_top),
                                  options->always_on_top);
    gtk_box_pack_start (GTK_BOX (vbox), cb_always_on_top, FALSE, FALSE, 0);
    gtk_widget_show (cb_always_on_top);

    g_signal_connect (cb_always_on_top, "toggled",
                      G_CALLBACK (on_toggle_always_on_top), notes);

    cb_stick = gtk_check_button_new_with_label (_("Stick mode"));
    gtk_toggle_button_set_active (GTK_TOGGLE_BUTTON (cb_stick), options->stick);
    gtk_box_pack_start (GTK_BOX (vbox), cb_stick, FALSE, FALSE, 0);
    gtk_widget_show (cb_stick);

    g_signal_connect (cb_stick, "toggled", G_CALLBACK (on_toggle_stick), notes);

    g_signal_connect (cb_vscrollbar, "toggled", 
                      G_CALLBACK (on_toggle_vscrollbar), notes);

    gtk_widget_show (dialog);

    return dialog;
}

static void
on_toggle_show (GtkWidget *widget, NotesPlugin *notes)
{
    gboolean toggle_value;

    g_object_get (G_OBJECT (widget), "active", &toggle_value, NULL);
    notes->options.show = toggle_value;

    DBG ("Set option show: %d", toggle_value);
}

static void
on_toggle_task_switcher (GtkWidget *widget, NotesPlugin *notes)
{
    gboolean toggle_value;

    g_object_get (G_OBJECT (widget), "active", &toggle_value, NULL);
    notes->options.task_switcher = toggle_value;

    gtk_window_set_skip_pager_hint (GTK_WINDOW (notes->note->window),
                                    !toggle_value);
    gtk_window_set_skip_taskbar_hint (GTK_WINDOW (notes->note->window),
                                      !toggle_value);

    DBG ("Set option task_switcher: %d", toggle_value);
}

static void
on_toggle_always_on_top (GtkWidget *widget, NotesPlugin *notes)
{
    gboolean toggle_value;

    g_object_get (G_OBJECT (widget), "active", &toggle_value, NULL);
    notes->options.always_on_top = toggle_value;

    gtk_window_set_keep_above (GTK_WINDOW (notes->note->window), toggle_value);

    DBG ("Set option always_on_top: %d", toggle_value);
}

static void
on_toggle_stick (GtkWidget *widget, NotesPlugin *notes)
{
    gboolean toggle_value;

    g_object_get (G_OBJECT (widget), "active", &toggle_value, NULL);
    notes->options.stick = toggle_value;

    if (toggle_value)
        gtk_window_stick (GTK_WINDOW (notes->note->window));
    else
        gtk_window_unstick (GTK_WINDOW (notes->note->window));

    DBG ("Set option stick: %d", toggle_value);
}

static void
on_toggle_vscrollbar (GtkWidget *widget, NotesPlugin *notes)
{
    gboolean toggle_value;
    GtkPolicyType vpolicy;
    gint i;
    GList *pages;
    NotePage *page;

    g_object_get (G_OBJECT (widget), "active", &toggle_value, NULL);
    notes->options.vscrollbar = toggle_value;

    vpolicy = (toggle_value) ? GTK_POLICY_AUTOMATIC : GTK_POLICY_ALWAYS;
    pages = g_list_nth (notes->note->pages, 0);

    for (i = 0, page = (NotePage *)g_list_nth_data (pages, i); page != NULL;
         i++, page = (NotePage *)g_list_nth_data (pages, i))
      {
        gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW (page->scroll), 
                                        GTK_POLICY_AUTOMATIC, vpolicy);
        /* This is being very obvious... it doesn't work!
         * But the setting is correct if you restart the panel */
      }

    DBG ("Set option vscrollbar: %d", toggle_value);
}

