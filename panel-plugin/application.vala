/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (c) 2009  Mike Massonnet <mmassonnet@xfce.org>
 *
 *  TODO:
 *  - Nothing
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

using Gtk;

namespace Xnp {

	public class Application : GLib.Object {

		private SList<unowned Xnp.Window> window_list;

		public Application () {
			/* TODO Load existing notes */

			/* Load an empty note */
			create_window (null);
			create_window (null);
		}

		public void create_window (string? name) {
			var window = new Xnp.Window ();
			this.window_list.append (window);
			foreach (var win in this.window_list) {
				win.set_window_list (ref this.window_list);
				debug ("%p.set_window_list (%p)", win, this.window_list);
			}

			if (name == null) {
				uint len = this.window_list.length ();
				if (len > 1)
					window.name = "Notes %u".printf (len);
			}
			else {
				window.name = name;
			}

			this.load_window_data (window);

			window.show ();
		}

		private void load_window_data (Xnp.Window window) {
			window.insert_note ();
		}

/**/
		static int main (string[] args) {
			Gtk.init (ref args);
			new Xnp.Application ();
			Gtk.main ();
			return 0;
		}

	}

}
