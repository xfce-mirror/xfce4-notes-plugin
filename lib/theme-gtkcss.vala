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

		private string css_path;
		private Gtk.CssProvider css_provider;

		public ThemeGtkcss() {
			css_provider = new Gtk.CssProvider ();
			css_path = Xfce.resource_save_location (Xfce.ResourceType.CONFIG, "xfce4/notes/xfce4-notes.css", true);
			Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		}

		private bool css_changed (string css) {
			string old_css;
			int64 file_size;
			File file = File.new_for_path(css_path);
			try {
				file_size = file.query_info ("standard::size", FileQueryInfoFlags.NONE).get_size ();
				if (file_size != css.size()) return true;
				GLib.FileUtils.get_contents (css_path, out old_css);
				return old_css != css;
			} catch (Error e) {
				return true;
			}
		}

		public void update_css (Gdk.RGBA rgba) {
			char dir_separator = GLib.Path.DIR_SEPARATOR;
			string css = "@define-color notes_bg_color %s;\n@import url(\"%s%c%s%cgtk-main.css\");"
				.printf (rgba.to_string (), Config.PKGDATADIR, dir_separator, "gtk-3.0", dir_separator);
			if (!css_changed (css))
				return;
			try {
				GLib.FileUtils.set_contents (css_path, css, -1);
			} catch (FileError e) {
				warning ("Unable to update CSS file: %s", e.message);
			}
		}

		public void update_style_context () {
			try {
				css_provider.load_from_path (css_path);
			} catch (GLib.Error e) {
				warning ("%s", e.message);
			}
		}

	}

}
