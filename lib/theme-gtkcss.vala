/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (c) 2006-2013  Mike Massonnet <mmassonnet@xfce.org>
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

		public static string get_css_path () {
			return Xfce.resource_save_location (Xfce.ResourceType.CONFIG, "xfce4/xfce4-notes.css", true);
		}

		public static void update_css (Gdk.RGBA rgba) {
			string css = "@define-color notes_bg_color %s;\n@import url(\"%s%c%s%cgtk-main.css\");"
				.printf (rgba.to_string (), Config.PKGDATADIR, GLib.Path.DIR_SEPARATOR, "gtk-3.0", GLib.Path.DIR_SEPARATOR);
			try {
				GLib.FileUtils.set_contents (get_css_path (), css, -1);
			} catch (FileError e) {
				warning ("Unable to update CSS file: %s", e.message);
			}
		}

		public static void update_style_context () {
			try {
				var cssprovider = new Gtk.CssProvider ();
				cssprovider.load_from_path (get_css_path ());
				Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), cssprovider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			} catch (GLib.Error e) {
				warning ("%s", e.message);
			}
		}

	}

}
