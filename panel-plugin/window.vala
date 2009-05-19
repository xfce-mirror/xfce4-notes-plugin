/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (c) 2009  Mike Massonnet <mmassonnet@xfce.org>
 *
 *  TODO:
 *  - F2/Esc/etc accelerators
 *  - Set widget name for Window
 *  - Extra window properties
 *  - Verify: unshade before hide
 *  - On del_box_clicked_cb verify if the content is empty
 *  - Display note name in title
 *  - Hide navigation bar on leave / show on motion
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

	public class Window : Gtk.Window {

		private int width;
		private int height;
		private bool above;
		private bool sticky;
		private Gtk.AccelGroup accel_group;
		private Gtk.Menu menu;
		private Gtk.VBox content_box;
		private Gtk.Notebook notebook;
		private Gtk.HBox navigation_box;
		private uint navigation_timeout = 0;
		private Gtk.Button goleft_box;
		private Gtk.Button goright_box;

		private int CORNER_MARGIN = 20;
		private Gdk.Cursor CURSOR_TOP_LC = new Gdk.Cursor (Gdk.CursorType.TOP_LEFT_CORNER);
		private Gdk.Cursor CURSOR_TOP_RC = new Gdk.Cursor (Gdk.CursorType.TOP_RIGHT_CORNER);
		private Gdk.Cursor CURSOR_BOTTOM_RC = new Gdk.Cursor (Gdk.CursorType.BOTTOM_RIGHT_CORNER);
		private Gdk.Cursor CURSOR_BOTTOM = new Gdk.Cursor (Gdk.CursorType.BOTTOM_SIDE);
		private Gdk.Cursor CURSOR_BOTTOM_LC = new Gdk.Cursor (Gdk.CursorType.BOTTOM_LEFT_CORNER);

		public Window () {
			/* Build Window properties */
			this.title = "Notes";
			this.deletable = false;
			this.skip_taskbar_hint = true;
			this.default_height = 380;
			this.default_width = 300;
			this.decorated = false;
			this.icon_name = "xfce4-notes-plugin";
			add_events (Gdk.EventMask.POINTER_MOTION_MASK|Gdk.EventMask.POINTER_MOTION_HINT_MASK|Gdk.EventMask.BUTTON_PRESS_MASK);

			/* Build AccelGroup */
			this.accel_group = new Gtk.AccelGroup ();
			add_accel_group (this.accel_group);

			/* Build Menu */
			this.menu = build_menu ();
			this.menu.show_all ();

			/* Build Frame */
			var frame = new Gtk.Frame (null);
			frame.shadow_type = Gtk.ShadowType.NONE;
			var style = frame.get_modifier_style ();
			style.xthickness = 1;
			style.ythickness = 3;
			frame.modify_style (style);
			frame.show ();
			add (frame);
			var vbox_frame = new Gtk.VBox (false, 0);
			vbox_frame.spacing = 1;
			vbox_frame.show ();
			frame.add (vbox_frame);

			/* Build title */
			var title_box = new Gtk.HBox (false, 0);
			var menu_box = new Gtk.EventBox ();
			var menu_image = new Gtk.Image.from_icon_name ("xfce4-notes-plugin", Gtk.IconSize.MENU);
			menu_box.add (menu_image);
			menu_box.set_size_request (22, 22);
			title_box.pack_start (menu_box, false, false, 4);
			var title_evbox = new Gtk.EventBox ();
			var title = new Gtk.Label ("<b>"+this.title+"</b>");
			title.use_markup = true;
			title.ellipsize = Pango.EllipsizeMode.END;
			title_evbox.add (title);
			title_box.pack_start (title_evbox, true, true, 0);
			var close_box = new Gtk.Button ();
			close_box.set_relief (Gtk.ReliefStyle.NONE);
			close_box.can_focus = false;
			var close_label = new Gtk.Label ("<b>x</b>");
			close_label.use_markup = true;
			close_box.add (close_label);
			close_box.set_size_request (22, 22);
			title_box.pack_start (close_box, false, false, 4);
			title_box.show_all ();
			vbox_frame.pack_start (title_box, false, false, 0);

			/* Build content box */
			this.content_box = new Gtk.VBox (false, 0);
			this.content_box.show ();
			vbox_frame.pack_start (this.content_box, true, true, 0);

			/* Build Notebook */
			this.notebook = new Gtk.Notebook ();
			this.notebook.show_border = false;
			this.notebook.show_tabs = false;
			this.notebook.show ();
			this.content_box.pack_start (this.notebook, true, true, 0);

			/* Build navigation toolbar */
			this.navigation_box = new Gtk.HBox (false, 2);
			this.goleft_box = new Gtk.Button ();
			this.goleft_box.set_relief (Gtk.ReliefStyle.NONE);
			this.goleft_box.can_focus = false;
			this.goleft_box.sensitive = false;
			var goleft_label = new Gtk.Label ("<b>&lt;</b>");
			goleft_label.use_markup = true;
			this.goleft_box.add (goleft_label);
			this.goleft_box.set_size_request (22, 22);
			this.navigation_box.pack_start (this.goleft_box, true, false, 0);
			var add_box = new Gtk.Button ();
			add_box.set_tooltip_text (Gtk.accelerator_get_label ('N', Gdk.ModifierType.CONTROL_MASK));
			add_box.set_relief (Gtk.ReliefStyle.NONE);
			add_box.can_focus = false;
			var add_label = new Gtk.Label ("<b>+</b>");
			add_label.use_markup = true;
			add_box.add (add_label);
			add_box.set_size_request (22, 22);
			this.navigation_box.pack_start (add_box, true, false, 0);
			var del_box = new Gtk.Button ();
			del_box.set_tooltip_text (Gtk.accelerator_get_label ('W', Gdk.ModifierType.CONTROL_MASK));
			del_box.set_relief (Gtk.ReliefStyle.NONE);
			del_box.can_focus = false;
			var del_label = new Gtk.Label ("<b>−</b>");
			del_label.use_markup = true;
			del_box.add (del_label);
			del_box.set_size_request (22, 22);
			this.navigation_box.pack_start (del_box, true, false, 0);
			this.goright_box = new Gtk.Button ();
			this.goright_box.set_relief (Gtk.ReliefStyle.NONE);
			this.goright_box.can_focus = false;
			this.goright_box.sensitive = false;
			var goright_label = new Gtk.Label ("<b>&gt;</b>");
			goright_label.use_markup = true;
			this.goright_box.add (goright_label);
			this.goright_box.set_size_request (22, 22);
			this.navigation_box.pack_start (this.goright_box, true, false, 0);
			this.navigation_box.show_all ();
			this.navigation_box.hide ();
			this.content_box.pack_start (this.navigation_box, false, false, 0);

			/* Connect mouse click signals */
			menu_box.button_press_event += menu_box_pressed_cb;
			close_box.clicked += hide_cb;
			add_box.clicked += () => { insert_note (); };
			del_box.clicked += () => { delete_current_note (); };
			this.goleft_box.clicked += () => { notebook.prev_page (); };
			this.goright_box.clicked += () => { notebook.next_page (); };

			/* Connect extra signals */
			delete_event += () => {
				/* Replace ALT+F4 action */
				hide_cb ();
				return true;
			};
			leave_notify_event += () => {
				/* Hide the navigation when the mouse pointer is leaving the window */
				navigation_timeout = Timeout.add_seconds (1, () => {
						navigation_box.hide ();
						navigation_timeout = 0;
						return false;
					});
				return false;
			};
			motion_notify_event += () => {
				/* Show the navigation when the mouse pointer is hovering the window */
				if (navigation_timeout != 0) {
					Source.remove (navigation_timeout);
					navigation_timeout = 0;
				}
				navigation_box.show ();
				return false;
			};
			leave_notify_event += window_leaved_cb;
			motion_notify_event += window_motion_cb;
			button_press_event += window_pressed_cb;
			window_state_event += window_state_cb;
			title_evbox.button_press_event += title_evbox_pressed_cb;
			title_evbox.scroll_event += title_evbox_scrolled_cb;
			this.notebook.page_added += (n, c, p) => {
				notebook.set_current_page ((int)p);
				update_navigation_sensitivity ((int)p);
			};
			this.notebook.page_removed += (n, c, p) => {
				update_navigation_sensitivity ((int)p);
			};
			this.notebook.switch_page += (n, c, p) => {
				update_navigation_sensitivity ((int)p);
			};
		}

		/*
		 * Signal callbacks
		 */

		/**
		 * menu_box_pressed_cb:
		 *
		 * Popup the window menu.
		 */
		private bool menu_box_pressed_cb (Gtk.EventBox box, Gdk.EventButton event) {
			this.menu.popup (null, null, menu_position, 0, Gtk.get_current_event_time ());
			return false;
		}

		/**
		 * menu_position:
		 *
		 * Menu position function for the window menu.
		 */
		private void menu_position (Gtk.Menu menu, out int x, out int y, out bool push_in) {
			int winx, winy, width, height, depth;
			Gtk.Requisition requisition;
			window.get_geometry (out winx, out winy, out width, out height, out depth);
			window.get_origin (out x, out y);
			menu.size_request (out requisition);

			if (y + content_box.allocation.y + requisition.height > Gdk.Screen.height ()) {
				/* Show menu above */
				y -= requisition.height;
			}
			else {
				/* Show menu below */
				y += content_box.allocation.y;
			}
			if (x + requisition.width > Gdk.Screen.width ()) {
				/* Adjust menu left */
				debug ("%d %d", Gdk.Screen.width (), x);
				x = x - menu.requisition.width + content_box.allocation.y;
			}
		}

		/**
		 * hide_cb:
		 *
		 * Save position before hidding.
		 */
		private void hide_cb () {
			int winx, winy;
			get_position (out winx, out winy);
			hide ();
			move (winx, winy);
		}

		/**
		 * window_leaved_cb:
		 *
		 * Reset the mouse cursor.
		 */
		private bool window_leaved_cb () {
			window.set_cursor (null);
			return true;
		}

		/**
		 * window_motion_cb:
		 *
		 * Update mouse cursor.
		 */
		private bool window_motion_cb (Gtk.Widget widget, Gdk.EventMotion event) {
			if (event.x > 4 && event.y > 4
				&& event.x < allocation.width - 4
				&& event.y < allocation.height - 4) {
				window.set_cursor (null);
				return false;
			}

			// Top left corner
			if (event.x <= 4
				&& event.y <= this.CORNER_MARGIN)
				window.set_cursor (this.CURSOR_TOP_LC);
			// Top right corner
			else if (event.x >= allocation.width - 4
				&& event.y <= this.CORNER_MARGIN)
				window.set_cursor (this.CURSOR_TOP_RC);
			// Bottom right corner
			else if (event.x >= allocation.width - this.CORNER_MARGIN
				&& event.y >= allocation.height - this.CORNER_MARGIN)
				window.set_cursor (this.CURSOR_BOTTOM_RC);
			// Bottom
			else if (event.x > this.CORNER_MARGIN
				&& event.y > allocation.height - this.CORNER_MARGIN
				&& event.x < allocation.width - this.CORNER_MARGIN)
				window.set_cursor (this.CURSOR_BOTTOM);
			// Bottom left corner
			else if (event.x <= this.CORNER_MARGIN
				&& event.y >= allocation.height - this.CORNER_MARGIN)
				window.set_cursor (this.CURSOR_BOTTOM_LC);
			// Default
			else
				window.set_cursor (null);

			return true;
		}

		/**
		 * window_pressed_cb:
		 *
		 * Start a window resize depending on mouse pointer location.
		 */
		private bool window_pressed_cb (Gtk.Widget widget, Gdk.EventButton event) {
			Gdk.WindowEdge edge;
			if (event.x > 4 && event.y > 4
				&& event.x < allocation.width - 4
				&& event.y < allocation.height - 4)
				return false;

			// Top left corner
			if (event.x <= 4
				&& event.y <= this.CORNER_MARGIN)
				edge = Gdk.WindowEdge.NORTH_WEST;
			// Top right corner
			else if (event.x >= allocation.width - 4
				&& event.y <= this.CORNER_MARGIN)
				edge = Gdk.WindowEdge.NORTH_EAST;
			// Right
			else if (event.y > this.CORNER_MARGIN
				&& event.x > allocation.width - this.CORNER_MARGIN
				&& event.y < allocation.height - this.CORNER_MARGIN)
				edge = Gdk.WindowEdge.EAST;
			// Bottom right corner
			else if (event.x >= allocation.width - this.CORNER_MARGIN
				&& event.y >= allocation.height - this.CORNER_MARGIN)
				edge = Gdk.WindowEdge.SOUTH_EAST;
			// Bottom
			else if (event.x > this.CORNER_MARGIN
				&& event.y > allocation.height - this.CORNER_MARGIN
				&& event.x < allocation.width - this.CORNER_MARGIN)
				edge = Gdk.WindowEdge.SOUTH;
			// Bottom left corner
			else if (event.x <= this.CORNER_MARGIN
				&& event.y >= allocation.height - this.CORNER_MARGIN)
				edge = Gdk.WindowEdge.SOUTH_WEST;
			// Left
			else if (event.y > this.CORNER_MARGIN && event.x < this.CORNER_MARGIN
				&& event.y < allocation.height - this.CORNER_MARGIN)
				edge = Gdk.WindowEdge.WEST;
			else
				return false;

			begin_resize_drag (edge, (int)event.button,
				(int)event.x_root, (int)event.y_root, event.time);

			return true;
		}

		/**
		 * window_state_cb:
		 *
		 * Watch window manager actions always on top and sticky
		 * window.
		 */
		private bool window_state_cb (Gtk.Widget widget, Gdk.EventWindowState event) {
			if ((bool)(event.changed_mask & Gdk.WindowState.ABOVE)) {
				/* FIXME above state is never notified despit
				 * of xfwm4 switching the state */
				this.above = (bool)(event.new_window_state & Gdk.WindowState.ABOVE);
			}
			if ((bool)(event.changed_mask & Gdk.WindowState.STICKY)) {
				this.sticky = (bool)(event.new_window_state & Gdk.WindowState.STICKY);
			}
			return false;
		}

		/**
		 * title_evbox_pressed_cb:
		 *
		 * Raise/lower the window and popup window menu.
		 */
		private bool title_evbox_pressed_cb (Gtk.EventBox box, Gdk.EventButton event) {
			if (event.type != Gdk.EventType.BUTTON_PRESS)
				return false;
			if (event.button == 1) {
				this.window.show ();
				int winx, winy, curx, cury;
				get_position (out winx, out winy);
				get_pointer (out curx, out cury);
				winx += curx;
				winy += cury;
				begin_move_drag (1, winx, winy, Gtk.get_current_event_time ());
			}
			else if (event.button == 2) {
				this.window.lower ();
			}
			else if (event.button == 3) {
				this.menu.popup (null, null, null, 0, Gtk.get_current_event_time ());
			}
			return false;
		}

		/**
		 * title_evbox_scrolled_cb:
		 *
		 * Shade/unshade the window and set transparency by holding ALT.
		 */
		private bool title_evbox_scrolled_cb (Gtk.EventBox box, Gdk.EventScroll event) {
			if ((bool)(event.state & Gdk.ModifierType.MOD1_MASK)) {
				if (event.direction == Gdk.ScrollDirection.UP) {
					opacity += 0.1;
				} else if (event.direction == Gdk.ScrollDirection.DOWN) {
					if (opacity - 0.1 >= 0.1)
						opacity -= 0.1;
				}
			}
			else {
				if (event.direction == Gdk.ScrollDirection.UP) {
					shade ();
				}
				else if (event.direction == Gdk.ScrollDirection.DOWN) {
					unshade ();
				}
			}
			return false;
		}

		/*
		 * Window menu
		 */

		/**
		 * build_menu:
		 *
		 * Build the window menu.
		 */
		private Gtk.Menu build_menu () {
			var menu = new Gtk.Menu ();
			menu.set_accel_group (this.accel_group);

			var mi = new Gtk.MenuItem.with_mnemonic ("_Go");
			menu.append (mi);

			var menu_go = new Gtk.Menu ();
			mi.set_submenu (menu_go);

			mi = new Gtk.SeparatorMenuItem ();
			menu_go.append (mi);

			mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_ADD, null);
			mi.add_accelerator ("activate", this.accel_group, 'N',
				Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.MASK);
			menu_go.append (mi);

			mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_REMOVE, null);
			mi.add_accelerator ("activate", this.accel_group, 'W',
				Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.MASK);
			menu_go.append (mi);

			mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_PROPERTIES, null);
			menu.append (mi);

			/* Note items */
			mi = new Gtk.SeparatorMenuItem ();
			menu.append (mi);

			mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_NEW, null);
			mi.add_accelerator ("activate", this.accel_group, 'N',
				Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.MASK);
			mi.activate += () => { insert_note (); };
			menu.append (mi);

			mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_DELETE, null);
			mi.add_accelerator ("activate", this.accel_group, 'W',
				Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.MASK);
			mi.activate += () => { delete_current_note (); };
			menu.append (mi);

			mi = new Gtk.MenuItem.with_mnemonic ("_Rename");
			mi.activate += () => { rename_current_note (); };
			menu.append (mi);

			mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_UNDO, null);
			mi.add_accelerator ("activate", this.accel_group, 'Z',
				Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.MASK);
			mi.activate += () => {
				int page = notebook.get_current_page ();
				Gtk.Widget child = notebook.get_nth_page (page);
				((Xnp.Note)child).text_view.undo ();
			};
			menu.append (mi);

			/* Window options */
			mi = new Gtk.SeparatorMenuItem ();
			menu.append (mi);

			mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_SELECT_FONT, null);
			menu.append (mi);

			mi = new Gtk.CheckMenuItem.with_label ("Always on top");
			menu.append (mi);

			mi = new Gtk.CheckMenuItem.with_label ("Sticky window");
			menu.append (mi);

			return menu;
		}

		/*
		 * Shade/unshade
		 */

		/**
		 * shade:
		 *
		 * Shade the window (roll up) to show only the title bar.
		 */
		private void shade () {
			if ((bool)(this.content_box.get_flags () & Gtk.WidgetFlags.VISIBLE)) {
				this.content_box.hide ();
				get_size (out this.width, out this.height);
				resize (this.width, 1);
			}
		}

		/**
		 * unshade:
		 *
		 * Unshade the window (roll down).
		 */
		private void unshade () {
			if (!(bool)(this.content_box.get_flags () & Gtk.WidgetFlags.VISIBLE)) {
				this.content_box.show ();
				get_size (out this.width, null);
				resize (this.width, this.height);
			}
		}

		/*
		 * Tabs, navigation
		 */

		/**
		 * insert_note:
		 *
		 * Create a new note and insert it inside the notebook after
		 * the current position.
		 */
		public Xnp.Note insert_note () {
			int position = this.notebook.get_current_page () + 1;
			var note = new Xnp.Note ("my-note");
			note.save_data += (o, n) => { print ("note `%s' save-data\n", n); };
			note.show ();
			this.notebook.insert_page (note, null, position);
			return note;
		}

		/**
		 * delete_current_note:
		 *
		 * Delete the current note.
		 */
		public void delete_current_note () {
			this.delete_note (this.notebook.get_current_page ());
		}

		/**
		 * delete_note:
		 *
		 * Delete note at position @position.
		 */
		public void delete_note (int position) {
			var child = this.notebook.get_nth_page (position);

			if (((Xnp.Note)child).text_view.buffer.get_char_count () > 0) {
				var dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL|Gtk.DialogFlags.DESTROY_WITH_PARENT,
					Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, "Are you sure you want to delete this note?");
				int res = dialog.run ();
				dialog.destroy ();
				if (res != Gtk.ResponseType.YES)
					return;
			}

			this.notebook.remove_page (position);
			child.destroy ();
			if (this.notebook.get_n_pages () == 0)
				this.insert_note ();
		}

		/**
		 * rename_current_note:
		 *
		 * Rename the current note.
		 */
		public void rename_current_note () {
			int position = this.notebook.get_current_page ();
			if (position == -1)
				return;
			var note = (Xnp.Note)(this.notebook.get_nth_page (position));

			var dialog = new Gtk.Dialog.with_buttons ("Rename note", (Gtk.Window)get_toplevel (),
				Gtk.DialogFlags.MODAL|Gtk.DialogFlags.DESTROY_WITH_PARENT,
				Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OK, Gtk.ResponseType.OK);
			dialog.set_default_response (Gtk.ResponseType.OK);
			dialog.resizable = false;
			dialog.icon_name = Gtk.STOCK_EDIT;
			dialog.border_width = 4;
			dialog.vbox.border_width = 6;

			var entry = new Gtk.Entry ();
			entry.text = note.name;
			entry.activates_default = true;
			dialog.vbox.add (entry);
			dialog.vbox.show_all ();

			int res = dialog.run ();
			if (res == Gtk.ResponseType.OK)
				note.name = entry.text;
			dialog.destroy ();
		}

		/**
		 * update_navigation_sensitivity:
		 *
		 * Update the goleft/right sensitivities.
		 */
		private void update_navigation_sensitivity (int page_num) {
			int n_pages = notebook.get_n_pages ();
			if (n_pages <= 1) {
				this.goleft_box.sensitive = false;
				this.goright_box.sensitive = false;
			}
			else {
				this.goleft_box.sensitive = page_num == 0 ? false : true;
				this.goright_box.sensitive = page_num + 1 == n_pages ? false : true;
			}
		}
/*
		static int main (string[] args) {
			Gtk.init (ref args);
			var sample = new Xnp.Window ("Note");
			sample.show ();
			Gtk.main ();
			return 0;
		}
*/

	}

}

