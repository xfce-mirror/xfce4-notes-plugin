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

		private SList<Xnp.Window> window_list;

		public Application () {
			/* TODO Load existing windows */
			/* Create an initial empty window */
			create_window (null);
			create_window (null);
			create_window (null);
		}

		/*
		 * Window management
		 */

		/**
		 * create_window:
		 *
		 * Creates a new Xnp.Window and stores it inside window_list.
		 */
		public void create_window (string? name) {
			var window = new Xnp.Window ();
			this.window_list.append (window);
			foreach (var win in this.window_list) {
				win.set_window_list (this.window_list);
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

			window.action += (win, action) => {
				if (action == "rename") {
					rename_window (win);
				}
				else if (action == "delete") {
					delete_window (win);
				}
				else if (action == "create-new-window") {
					create_window (null);
				}
			};

			window.show ();
		}

		/**
		 * load_window_data:
		 *
		 * Looks up the window name for existing notes otherwise
		 * inserts an initial empty note.
		 */
		private void load_window_data (Xnp.Window window) {
			/* TODO load existing notes */
			window.insert_note ();
		}

		/**
		 * rename_window:
		 *
		 * Renames the window name.
		 */
		private void rename_window (Xnp.Window window) {
			var dialog = new Gtk.Dialog.with_buttons ("Rename group", window,
				Gtk.DialogFlags.MODAL|Gtk.DialogFlags.DESTROY_WITH_PARENT,
				Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OK, Gtk.ResponseType.OK);
			dialog.set_default_response (Gtk.ResponseType.OK);
			dialog.resizable = false;
			dialog.icon_name = Gtk.STOCK_EDIT;
			dialog.border_width = 4;
			dialog.vbox.border_width = 6;

			var entry = new Gtk.Entry ();
			entry.text = window.name;
			entry.activates_default = true;
			dialog.vbox.add (entry);
			dialog.vbox.show_all ();

			int res = dialog.run ();
			dialog.hide ();
			if (res == Gtk.ResponseType.OK)
				window.name = entry.text;
			dialog.destroy ();
		}

		/**
		 * delete_window:
		 *
		 * Delte the window.
		 */
		private void delete_window (Xnp.Window window) {
			this.window_list.remove (window);
			window.destroy ();

			if (this.window_list.length () >= 1) {
				foreach (var win in this.window_list) {
					win.set_window_list (this.window_list);
				}
			}
			else {
				create_window (null);
			}
		}

/**/
	}

}

static int main (string[] args) {
	Gtk.init (ref args);
	var app = new Xnp.Application ();
	Gtk.main ();
	app.unref ();
	return 0;
}

