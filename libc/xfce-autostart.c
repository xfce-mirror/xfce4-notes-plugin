/*
 *  xfce-autostart - convenience functions to handle autostart files
 *  Copyright (C) 2009  Mike Massonnet <mmassonnet@xfce.org>
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

#include <glib.h>
#include <libxfce4util/libxfce4util.h>

void        xfce_autostart_set              (gchar *name,
                                             gchar *exec,
                                             gboolean hidden);
void        xfce_autostart_set_full         (gchar *name,
                                             gchar *exec,
                                             gboolean hidden,
                                             gboolean terminal,
                                             gchar *comment,
                                             gchar *icon);

/**
 * xfce_autostart_set:
 * @name:   name of the autostart also used for the filename
 * @exec:   command to execute
 * @hidden: set to FALSE to make the file visible and enable the autostart
 *
 * Simple version of xfce_autostart_set_full() that passes FALSE to @terminal
 * and %NULL to comment and icon. See xfce_autostart_set_full() for more info.
 */
void
xfce_autostart_set (gchar *name,
                    gchar *exec,
                    gboolean hidden)
{
  xfce_autostart_set_full (name, exec, hidden, FALSE, NULL, NULL);
}

/**
 * xfce_autostart_set_full:
 * @name:       name of the autostart also used for the filename
 * @exec:       command to execute
 * @hidden:     set to FALSE to make the file visible and enable the autostart
 * @terminal:   set to TRUE to run the program within a terminal
 * @comment:    comment/description of the program
 * @icon:       icon name
 *
 * Convenience function to install and modify an autostart file within the home
 * directory of the user. If none previously exists and an autostart file is
 * found on the system it will first be copied then modified otherwise it will
 * be created.
 */
void
xfce_autostart_set_full (gchar *name,
                         gchar *exec,
                         gboolean hidden,
                         gboolean terminal,
                         gchar *comment,
                         gchar *icon)
{
  gchar *relpath = NULL;
  gchar *usrfile = NULL;
  gchar *sysfile = NULL;
  GKeyFile *keyfile;
  gchar *data;

  g_return_if_fail (G_LIKELY (name != NULL));
  g_return_if_fail (G_LIKELY (exec != NULL));

  keyfile = g_key_file_new ();

  relpath = g_strdup_printf ("autostart/%s.desktop", name);
  usrfile = g_strdup_printf ("%s/%s", g_get_user_config_dir (), relpath);

  if (g_file_test (usrfile, G_FILE_TEST_EXISTS))
    {
      TRACE ("User file exists, load it");
      g_key_file_load_from_file (keyfile, usrfile, G_KEY_FILE_KEEP_TRANSLATIONS, NULL);
    }
  else
    {
      TRACE ("User file doesn't exist, lookup for a system-wide file");
      sysfile = xfce_resource_lookup (XFCE_RESOURCE_CONFIG, relpath);
      if (sysfile != NULL)
        {
          TRACE ("System-wide file found, load it");
          g_key_file_load_from_file (keyfile, sysfile, G_KEY_FILE_KEEP_TRANSLATIONS, NULL);
        }
      else
        {
          TRACE ("No file found, iniate one");
          g_key_file_set_string (keyfile, G_KEY_FILE_DESKTOP_GROUP, G_KEY_FILE_DESKTOP_KEY_TYPE,
                                 G_KEY_FILE_DESKTOP_TYPE_APPLICATION);
          g_key_file_set_string (keyfile, G_KEY_FILE_DESKTOP_GROUP, G_KEY_FILE_DESKTOP_KEY_NAME, name);
        }
    }

  g_key_file_set_string (keyfile, G_KEY_FILE_DESKTOP_GROUP, G_KEY_FILE_DESKTOP_KEY_EXEC, exec);
  g_key_file_set_boolean (keyfile, G_KEY_FILE_DESKTOP_GROUP, G_KEY_FILE_DESKTOP_KEY_HIDDEN, hidden);
  g_key_file_set_boolean (keyfile, G_KEY_FILE_DESKTOP_GROUP, G_KEY_FILE_DESKTOP_KEY_TERMINAL, terminal);
  if (comment != NULL)
    g_key_file_set_string (keyfile, G_KEY_FILE_DESKTOP_GROUP, G_KEY_FILE_DESKTOP_KEY_COMMENT, comment);
  if (icon != NULL)
    g_key_file_set_string (keyfile, G_KEY_FILE_DESKTOP_GROUP, G_KEY_FILE_DESKTOP_KEY_ICON, icon);

  data = g_key_file_to_data (keyfile, NULL, NULL);
  g_file_set_contents (usrfile, data, -1, NULL);
  TRACE ("File updated:\n%s", data);

  g_free (relpath);
  g_free (usrfile);
  g_free (sysfile);
  g_free (data);
}

