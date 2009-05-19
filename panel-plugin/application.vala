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

		public Application () {
			/* TODO Load existing notes */
			/* Load an empty note */
			var window = new Xnp.Window ();
			var note = window.insert_note ();
			note.notify += note_property_notify;
			window.show ();
		}

		/**
		 * note_property_notify:
		 * @object
		 *
		 * Emitted when a property is changed.
		 */
		private void note_property_notify (GLib.Object object, GLib.ParamSpec pspec) {
			var note = (Xnp.Note)object;
			debug ("notify %s", pspec.name);
			if (pspec.name == "name") {
				debug ("name of note changed to `%s'", note.name);
			}
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
