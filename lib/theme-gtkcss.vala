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

		private string css_path_default;
		private string css_path_system;
		private string css_path_user;
		private Gtk.CssProvider css_provider_color;
		private Gtk.CssProvider css_provider_default;
		private Gtk.CssProvider css_provider_system;
		private Gtk.CssProvider css_provider_user;
		private bool _use_gtk_style = true;
		private Gdk.RGBA bg_color = {0};

		public ThemeGtkcss() {
			css_path_default = "%s/gtk-3.0/gtk.css".printf (Config.PKGDATADIR);
			css_path_system = "%s/xdg/xfce4/notes/gtk.css".printf (Config.SYSCONFDIR);
			css_path_user = Xfce.resource_save_location (Xfce.ResourceType.CONFIG, "xfce4/notes/gtk.css", true);
			css_provider_color = new Gtk.CssProvider ();
		}

		public bool use_gtk_style {
			get {
				return _use_gtk_style;
			}

			set {
				if (_use_gtk_style == value)
					return;
				var default_screen = Gdk.Screen.get_default ();
				if (value) {
					Gtk.StyleContext.remove_provider_for_screen (default_screen, css_provider_color);
					Gtk.StyleContext.remove_provider_for_screen (default_screen, css_provider_default);
					Gtk.StyleContext.remove_provider_for_screen (default_screen, css_provider_system);
					Gtk.StyleContext.remove_provider_for_screen (default_screen, css_provider_user);
					css_provider_default = null;
					css_provider_system = null;
					css_provider_user = null;
				}
				else {
					css_provider_default = new Gtk.CssProvider ();
					css_provider_system = new Gtk.CssProvider ();
					css_provider_user = new Gtk.CssProvider ();
					Gtk.StyleContext.add_provider_for_screen (default_screen, css_provider_color, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
					Gtk.StyleContext.add_provider_for_screen (default_screen, css_provider_default, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
					Gtk.StyleContext.add_provider_for_screen (default_screen, css_provider_system, Gtk.STYLE_PROVIDER_PRIORITY_USER - 1);
					Gtk.StyleContext.add_provider_for_screen (default_screen, css_provider_user, Gtk.STYLE_PROVIDER_PRIORITY_USER + 1);
					load_default_css ();
					load_system_css ();
					load_user_css ();
				}
				_use_gtk_style = value;
			}
		}

		public void update_color_css (Gdk.RGBA rgba) {
			try {
				if (bg_color != rgba) {
					bg_color = rgba;
					string css = "@define-color notes_bg_color %s;"
						.printf (bg_color.to_string ());
					css_provider_color.load_from_data (css);
				}
			} catch (GLib.Error e) {
				warning ("%s", e.message);
			}
		}

		private bool file_exists (string path) {
			return FileUtils.test (path, FileTest.EXISTS);
		}

		private void load_default_css () {
			try {
				css_provider_default.load_from_path (css_path_default);
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
