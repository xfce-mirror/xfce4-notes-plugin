/*
 *  Copyright (c) 2008-2010 Mike Massonnet <mmassonnet@gmail.com>
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
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
 */

#ifndef DEFINES_H
#define DEFINES_H

#define PLUGIN_WEBSITE                  "https://docs.xfce.org/panel-plugins/xfce4-notes-plugin"
#define PLUGIN_XFCONF_CHANNEL           "xfce4-notes-plugin"

#define BORDER                          6
#define CORNER_MARGIN                   20

/* Default settings */
#define GENERAL_HIDE_FROM_TASKBAR       TRUE
#define GENERAL_SHOW_TABS               FALSE
#define GENERAL_SHOW_NAVBAR             TRUE
#define GENERAL_TABS_POSITION           0
#define GENERAL_HIDE_ARROW_BUTTON       FALSE
#define GENERAL_BACKGROUND_COLOR        BACKGROUND_YELLOW
#define NEW_WINDOW_ABOVE                FALSE
#define NEW_WINDOW_STICKY               TRUE
#define NEW_WINDOW_TABS                 TRUE
#define NEW_WINDOW_TRANSPARENCY         10
#define NEW_WINDOW_USE_FONT             FALSE
#define NEW_WINDOW_FONT_DESCR           "Sans 13"
#define NEW_WINDOW_WIDTH                SIZE_NORMAL
#define NEW_WINDOW_HEIGHT               ((gint)NEW_WINDOW_WIDTH*SIZE_FACTOR)

/* Size values */
#define SIZE_SMALL                      240
#define SIZE_NORMAL                     270
#define SIZE_LARGE                      300
#define SIZE_FACTOR                     1.25

/* Background color values */
#define BACKGROUND_YELLOW               "#F7EB96"
#define BACKGROUND_BLUE                 "#88B7E3"
#define BACKGROUND_GREEN                "#C1ECB0"
#define BACKGROUND_INDIGO               "#BFA6E9"
#define BACKGROUND_OLIVE                "#DAF188"
#define BACKGROUND_CARMIN               "#FF96AC"
#define BACKGROUND_MIMOSA               "#FCF66F"
#define BACKGROUND_WHITE                "#F2F1EF"
#define BACKGROUND_ANDROID              "#C1D756"
#define BACKGROUND_GTK                  "GTK+"

#endif
