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

	public class Theme : GLib.Object {

		private Xnp.ThemeGtkcss theme_gtk_css;

		public Theme() {
			theme_gtk_css = new Xnp.ThemeGtkcss ();
		}

		public void use_gtk_style () {
			theme_gtk_css.use_gtk_style = true;
		}

		public void use_color (string color) {
			Gdk.RGBA rgba = {0};
			if (!rgba.parse (color)) {
				warning ("Cannot parse background color %s", color);
				use_gtk_style ();
				return;
			}

			theme_gtk_css.update_color_css (rgba);
			theme_gtk_css.use_gtk_style = false;
		}

	}

}
