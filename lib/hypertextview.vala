/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (c) 2009-2010  Mike Massonnet <mmassonnet@xfce.org>
 *  Copyright (c) 2009       Cornelius Hald <hald@icandy.de>
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
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
 */

using Gtk;
using Pango;

namespace Xnp {

	public class HypertextView : Gtk.SourceView {

		private Gdk.Cursor hand_cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.HAND2);
		private Gdk.Cursor regular_cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.XTERM);

		private bool cursor_over_link = false;

		private Gtk.TextTag tag_link;
		private Regex regex_link;

		private string _font;
		public string font {
			get {
				return this._font;
			}
			set {
				this._font = value;
				Pango.FontDescription font_descr = Pango.FontDescription.from_string (value);
				override_font (font_descr);
			}
		}

		construct {
			this.font = "Sans 13";
			this.tabs = new Pango.TabArray.with_positions (1, true, Pango.TabAlign.LEFT, 12);
			try {
				this.regex_link = new Regex ("((\\b((news|http|https|ftp|file|irc)://|mailto:|(www|ftp)\\." +
							     "|\\S*@\\S*\\.)|(?<=^|\\s)/\\S+/|(?<=^|\\s)~/\\S+)\\S*\\b/?)",
							     RegexCompileFlags.CASELESS|RegexCompileFlags.OPTIMIZE);
			} catch (GLib.RegexError e) {
				critical ("%s", e.message);
			}
		}

		public HypertextView () {
			this.style_updated.connect (style_updated_cb);
			this.button_release_event.connect (button_release_event_cb);
			this.motion_notify_event.connect_after (motion_notify_event_cb);
			this.state_flags_changed.connect (state_flags_changed_cb);
			this.buffer.insert_text.connect_after (insert_text_cb);
			this.buffer.delete_range.connect_after (delete_range_cb);

			var source_buffer = this.buffer as Gtk.SourceBuffer;
			source_buffer.highlight_matching_brackets = false;

			this.tag_link = this.buffer.create_tag ("link",
					"foreground", "blue",
					"underline", Pango.Underline.SINGLE,
					null);
		}

		/*
		 * Signal callbacks
		 */

		/**
		 * style_updated_cb:
		 *
		 * Get the link color from the css.
		 */
		private void style_updated_cb (Gtk.Widget hypertextview) {
			Gtk.StyleContext context = this.get_style_context ();
			Gtk.StateFlags state = context.get_state ();
			state &= ~Gtk.StateFlags.VISITED;
			state |= Gtk.StateFlags.LINK;
			context.save ();
			context.set_state (state);
			/* Remove the 'view' style, because it can "confuse" some themes */
			context.remove_class (Gtk.STYLE_CLASS_VIEW);
			tag_link.foreground_rgba = context.get_color (state);
			context.restore ();
		}

		/**
		 * button_release_event_cb:
		 *
		 * Event to open links.
		 */
		private bool button_release_event_cb (Gtk.Widget hypertextview, Gdk.EventButton event) {
			Gtk.TextIter start, end, iter;
			string link;
			int x, y;

			if (event.button != Gdk.BUTTON_PRIMARY)
				return false;

			this.buffer.get_selection_bounds (out start, out end);
			if (start.get_offset () != end.get_offset ())
				return false;

			window_to_buffer_coords (Gtk.TextWindowType.WIDGET, (int)event.x, (int)event.y, out x, out y);
			get_iter_at_location (out iter, x, y);

			if (iter.has_tag (this.tag_link)) {
				start = end = iter;

				if (!start.starts_tag (this.tag_link)) {
					start.backward_to_tag_toggle (this.tag_link);
				}

				end.forward_to_tag_toggle (this.tag_link);

				link = start.get_text (end);

				if (link[0:2] == "~/")
					link = "%s/%s".printf (Environment.get_home_dir (), link.substring (2));

				try {
					GLib.Process.spawn_command_line_async ("exo-open "+link);
					return false;
				} catch (Error e) {
				}
				try {
					GLib.AppInfo.launch_default_for_uri (link, null);
					return false;
				} catch (Error e) {
					message ("Unable to open link with default handler: %s", e.message);
				}
				try {
					GLib.Process.spawn_command_line_async ("xdg-open "+link);
					return false;
				}
				catch (Error e) {
				}
				try {
					GLib.Process.spawn_command_line_async ("firefox "+link);
					return false;
				}
				catch (Error e) {
				}

				message ("Unable to find an appropriate fallback to open the link");
			}

			return false;
		}

		/**
		 * motion_notify_event_cb:
		 *
		 * Event to update the cursor of the pointer.
		 */
		private bool motion_notify_event_cb (Gtk.Widget hypertextview, Gdk.EventMotion event) {
			Gtk.TextIter iter;
			Gdk.Window win;
			int x, y;

			window_to_buffer_coords (Gtk.TextWindowType.WIDGET, (int)event.x, (int)event.y, out x, out y);
			get_iter_at_location (out iter, x, y);
			this.cursor_over_link = iter.has_tag (this.tag_link);
			var cursor = this.cursor_over_link ? this.hand_cursor : this.regular_cursor;
			win = get_window (Gtk.TextWindowType.TEXT);

			if (win.cursor != cursor) {
				win.cursor = cursor;
			}

			return false;
		}

		/**
		 * state_flags_changed_cb:
		 *
		 * Fix mouse cursor behavior after clicking on a link.
		 */
		private void state_flags_changed_cb () {
			if (get_realized () && this.sensitive) {
				var win = get_window (Gtk.TextWindowType.TEXT);
				win.set_cursor (this.cursor_over_link ? this.hand_cursor : this.regular_cursor);
			}
		}

		/**
		 * insert_text_cb:
		 *
		 * Event to create and update existing tags within the buffer.
		 */
		private void insert_text_cb (Gtk.TextBuffer buffer, Gtk.TextIter location, string text, int len) {
			Gtk.TextIter end_iter = location;
			end_iter.forward_chars (text.char_count ());
			auto_highlight_urls (location, end_iter);
		}

		/**
		 * delete_range_cb:
		 *
		 * Event to delete and update existing tags within the buffer.
		 */
		private void delete_range_cb (Gtk.TextBuffer buffer, Gtk.TextIter start, Gtk.TextIter end) {
			auto_highlight_urls (start, end);
		}

		/*
		 * Undo/redo
		 */

		public void undo () {
			var buffer = this.buffer as Gtk.SourceBuffer;
			if (buffer.can_undo)
				buffer.undo ();
		}

		public void redo () {
			var buffer = this.buffer as Gtk.SourceBuffer;
			if (buffer.can_redo)
				buffer.redo ();
		}

		/*
		 * Tags
		 */

		/**
		 * update_tags:
		 *
		 * Goes through the entire document to search for untagged links and tag them.
		 */
		public void update_tags () {
			Gtk.TextIter start, end;
			this.buffer.get_start_iter (out start);
			this.buffer.get_end_iter (out end);
			auto_highlight_urls (start, end);
		}

		private void auto_highlight_urls (Gtk.TextIter start, Gtk.TextIter end) {
			/* Grow the block by 256 chars (max url length) which will be checked for links */
			extend_block (ref start, ref end, 256);

			/* Remove existing link tag */
			this.buffer.remove_tag (this.tag_link, start, end);

			/* The piece of text we are interested in */
			string str = start.get_slice (end);

			/* Match the regex */
			MatchInfo match_info;
			this.regex_link.match (str, 0, out match_info);

			/* Iterate through the matches and apply the link tag */
			try {
				while (match_info.matches ()) {
					int start_pos, end_pos;

					/* Get start and end position of the match */
					match_info.fetch_pos (0, out start_pos, out end_pos);

					/* Move the iters and apply tag */
					Gtk.TextIter xstart = start;
					xstart.forward_chars (str.char_count (start_pos));

					Gtk.TextIter xend = start;
					xend.forward_chars (str.char_count (end_pos));

					this.buffer.apply_tag (tag_link, xstart, xend);

					match_info.next ();
				}
			} catch (GLib.RegexError e) {
				warning ("%s", e.message);
			}
		}

		private void extend_block (ref Gtk.TextIter start_iter, ref Gtk.TextIter end_iter, int max_len) {
			/* Set start_iter max_len chars to the left or to the start of the line */
			if (start_iter.get_line_offset () - max_len > 0) {
				start_iter.backward_chars (max_len);
				/* Expand selection to the left, if there is a tag_link inside */
				if (start_iter.has_tag (this.tag_link)) {
					start_iter.backward_to_tag_toggle (this.tag_link);
				}
			} else {
				start_iter.set_line_offset (0);
			}

			/* Set end_iter max_len chars to the right or to the end of the line */
			if (!end_iter.ends_line ()) {
				if (end_iter.get_line_offset () + max_len < end_iter.get_chars_in_line ()) {
					end_iter.forward_chars (max_len);
					/* Expand selection to the right, if there is a tag_link inside */
					if (end_iter.has_tag (this.tag_link)) {
						end_iter.forward_to_tag_toggle(this.tag_link);
					}
				} else {
					end_iter.forward_to_line_end ();
				}
			}
		}

	}

}
