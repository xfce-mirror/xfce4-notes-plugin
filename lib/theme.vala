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

	public class Theme : GLib.Object {

		public static void set_background_color (string color) {
			Gdk.Color gdkcolor;
			if (!Gdk.Color.parse (color, out gdkcolor)) {
				warning ("Cannot parse background color %s", color);
				return;
			}

			Xnp.ThemeGtkcss.update_css (gdkcolor);
			Xnp.ThemeGtkcss.update_style_context ();
		}

	}

}
