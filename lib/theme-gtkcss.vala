/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (c) 2006-2013  Mike Massonnet <mmassonnet@xfce.org>
 *  Copyright (c) 2023       Arthur Demchenkov <spinal.by@gmail.com>
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

namespace Xnp {

	public class ThemeGtkcss : GLib.Object {

		private string css_path_system;
		private string css_path_user;
		private Gtk.CssProvider css_provider_default;
		private Gtk.CssProvider css_provider_system;
		private Gtk.CssProvider css_provider_user;
		private Gdk.RGBA bg_color = {0};

		public ThemeGtkcss() {
			css_provider_default = new Gtk.CssProvider ();
			css_provider_system = new Gtk.CssProvider ();
			css_provider_user = new Gtk.CssProvider ();
			css_path_system = "%s/xdg/xfce4/notes/gtk.css".printf (Config.SYSCONFDIR);
			css_path_user = Xfce.resource_save_location (Xfce.ResourceType.CONFIG, "xfce4/notes/gtk.css", true);
			Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider_default, Gtk.STYLE_PROVIDER_PRIORITY_USER - 2);
			Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider_system, Gtk.STYLE_PROVIDER_PRIORITY_USER - 1);
			Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider_user, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			load_system_css ();
			load_user_css ();
		}

		private bool file_exists (string path) {
			return FileUtils.test (path, FileTest.EXISTS);
		}

		public void update_color_css (Gdk.RGBA rgba) {
			if (bg_color != rgba) {
				bg_color = rgba;
				load_default_css ();
			}
		}

		private void load_default_css () {
			char dir_separator = GLib.Path.DIR_SEPARATOR;
			string css = "@define-color notes_bg_color %s;\n@import url(\"%s%c%s%cgtk.css\");"
				.printf (bg_color.to_string (), Config.PKGDATADIR, dir_separator, "gtk-3.0", dir_separator);
			try {
				css_provider_default.load_from_data (css);
			} catch (GLib.Error e) {
				warning ("%s", e.message);
			}
		}

		private void load_system_css () {
			try {
				if (!file_exists (css_path_system))
					return;
				css_provider_system.load_from_path (css_path_system);
			} catch (GLib.Error e) {
				warning ("%s", e.message);
			}
		}

		private void load_user_css () {
			try {
				if (!file_exists (css_path_user)) {
					string css = "/* Put your fun stuff here */";
						GLib.FileUtils.set_contents (css_path_user, css, -1);
				}
				css_provider_user.load_from_path (css_path_user);
			} catch (GLib.Error e) {
				warning ("%s", e.message);
			}
		}

	}

}
