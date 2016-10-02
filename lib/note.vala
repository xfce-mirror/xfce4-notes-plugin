/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (c) 2009-2010  Mike Massonnet <mmassonnet@xfce.org>
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
using Pango;

namespace Xnp {

	public class Note : Gtk.ScrolledWindow {

		public Xnp.HypertextView text_view;
		public new string name { get; set; }

		private uint save_timeout;
		private bool _dirty = false;
		public bool dirty {
			get {
				return this._dirty;
			}
			set {
				this._dirty = value;
				if (this.save_timeout > 0) {
					Source.remove (this.save_timeout);
				}
				if (value == false) {
					this.save_timeout = 0;
				}
				else {
					this.save_timeout = Timeout.add_seconds (60, save_cb);
				}
			}
		}

		public signal void save_data ();

		public Note (string name) {
			GLib.Object ();

			this.name = name;

			this.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);

			this.text_view = new Xnp.HypertextView ();
			this.text_view.show ();
			this.text_view.wrap_mode = Gtk.WrapMode.WORD;
			this.text_view.left_margin = 2;
			this.text_view.right_margin = 2;
			this.text_view.pixels_above_lines = 1;
			this.text_view.pixels_below_lines = 1;

			add (this.text_view);

			var buffer = this.text_view.get_buffer ();
			buffer.changed.connect (buffer_changed_cb);
		}

		~Note () {
			this.dirty = false;
		}

		/*
		 * Signal callbacks
		 */

		/**
		 * buffer_changed_cb:
		 *
		 * Reset the save_timeout as long as the buffer is under constant
		 * changes and send the save-data signal.
		 */
		private void buffer_changed_cb () {
			this.dirty = true;
		}

		/**
		 * save_cb:
		 *
		 * Send save-data signal.
		 */
		private bool save_cb () {
			this.save_data ();
			this.save_timeout = 0;
			this._dirty = false;
			return false;
		}

	}

}

#if DEBUG_XNP_NOTE
public class GtkSample : Window {

	public GtkSample () {
		this.title = "Sample Window";
		this.destroy += Gtk.main_quit;
		set_default_size (300, 300);
		var note = new Xnp.Note ("my-note");
		add (note);
	}

	static int main (string[] args) {
		Gtk.init (ref args);
		var sample = new GtkSample ();
		sample.show_all ();
		Gtk.main ();
		return 0;
	}

}
#endif

