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

namespace Xnp {

	public class Note : Gtk.ScrolledWindow {

		public Xnp.HypertextView text_view;
		public new string name { get; set; }
		public ulong save_handler_id;
		public ulong tab_handler_id;
		public bool backed = true;

		public string text {
			owned get {
				return this.text_view.buffer.text;
			}
			set {
				var buffer = this.text_view.buffer as Gtk.SourceBuffer;
				buffer.begin_not_undoable_action ();
				this.text_view.buffer.text = value;
				this.text_view.update_tags ();
				buffer.end_not_undoable_action ();
				this.dirty = false;
			}
		}

		public int cursor {
			get {
				return this.text_view.buffer.cursor_position;
			}
			set {
				var buffer = this.text_view.buffer;
				Gtk.TextIter iter;
				buffer.get_iter_at_offset (out iter, value);
				buffer.place_cursor (iter);
			}
		}

		private uint src_idle = 0;
		public double adjustment {
			get {
				return get_vadjustment ().value;
			}
			set {
				if (src_idle == 0) {
					var window = get_window ();
					if (window != null) window.freeze_updates ();
				} else
					Source.remove (src_idle);

				src_idle = Idle.add (() => {
					src_idle = 0;
					var window = get_window ();
					get_vadjustment ().value = value;
					if (window != null) window.thaw_updates ();
					return Source.REMOVE;
				});
			}
		}

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
					this.save_timeout = 0;
				}
				if (value) {
					this.save_timeout = Timeout.add_seconds (60, save_cb);
				}
			}
		}

		public signal void save_data ();

		public void save () {
			if (this.dirty) {
				this.save_data ();
			}
		}

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
			if (src_idle != 0)
				Source.remove (src_idle);
			if (save_timeout != 0)
				Source.remove (save_timeout);
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
			this.save_timeout = 0;
			this.save_data ();
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

