/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (c) 2009  Mike Massonnet <mmassonnet@xfce.org>
 *
 *  TODO:
 *  - Follow GNOME bug #551184 to change accelerators hexa values
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
		private Gtk.Menu menu;
		private Gtk.CheckMenuItem mi_above;
		private Gtk.CheckMenuItem mi_sticky;
		private Gtk.Label title_label;
		private Gtk.VBox content_box;
		private Gtk.Notebook notebook;
		private Gtk.HBox navigation_box;
		private uint navigation_timeout = 0;
		private Gtk.Button goleft_box;
		private Gtk.Button goright_box;

		private Gtk.UIManager ui;
		private const string ui_string =
"""
<ui>
  <accelerator action="close-window" />
  <accelerator action="new-window" />
  <accelerator action="delete-window" />
  <accelerator action="rename-window" />
  <accelerator action="new-note" />
  <accelerator action="delete-note" />
  <accelerator action="rename-note" />
  <accelerator action="cancel" />
  <accelerator action="next-note" />
  <accelerator action="prev-note" />
</ui>
""";
		private Gtk.ActionGroup action_group;
		private const Gtk.ActionEntry[] action_entries = {
			{ "close-window",  null, null, "Escape", null, hide },
			{ "new-window",    null, null, "<Ctrl><Shift>n", null, action_new_window },
			{ "delete-window", null, null, "<Ctrl><Shift>w", null, action_delete_window },
			{ "rename-window", null, null, "<Shift>F2", null, action_rename_window },
			{ "new-note",      null, null, "<Ctrl>n", null, action_new_note },
			{ "delete-note",   null, null, "<Ctrl>w", null, action_delete_note },
			{ "rename-note",   null, null, "F2", null, action_rename_note },
			{ "cancel",        null, null, "<Ctrl>z", null, action_cancel },
			{ "next-note",     null, null, "<Ctrl>Page_Down", null, action_next_note },
			{ "prev-note",     null, null, "<Ctrl>Page_Up", null, action_prev_note }
		};

		private int CORNER_MARGIN = 20;
		private Gdk.Cursor CURSOR_TOP_LC = new Gdk.Cursor (Gdk.CursorType.TOP_LEFT_CORNER);
		private Gdk.Cursor CURSOR_TOP_RC = new Gdk.Cursor (Gdk.CursorType.TOP_RIGHT_CORNER);
		private Gdk.Cursor CURSOR_BOTTOM_RC = new Gdk.Cursor (Gdk.CursorType.BOTTOM_RIGHT_CORNER);
		private Gdk.Cursor CURSOR_BOTTOM = new Gdk.Cursor (Gdk.CursorType.BOTTOM_SIDE);
		private Gdk.Cursor CURSOR_BOTTOM_LC = new Gdk.Cursor (Gdk.CursorType.BOTTOM_LEFT_CORNER);

		private unowned SList<unowned Xnp.Window> window_list;

		public new string name { default = _("Notes"); get; set; }
		public int n_pages { get; set; }

		public bool show_tabs {
			get {
				return this.notebook.show_tabs;
			}
			set {
				this.notebook.show_tabs = value;
			}
		}

		private bool _above;
		public bool above {
			get {
				return this._above;
			}
			set {
				this._above = value;
				set_keep_above (value);
			}
		}

		private bool _sticky;
		public bool sticky {
			get {
				return this._sticky;
			}
			set {
				this._sticky = value;
				if (value == true)
					stick ();
				else
					unstick ();
			}
		}

		public signal void action (string action);
		public signal void save_data (Xnp.Note note);
		public signal void note_inserted (Xnp.Note note);
		public signal void note_deleted (Xnp.Note note);
		public signal void note_renamed (Xnp.Note note, string old_name);

		construct {
			base.name = "xfce4-notes-plugin";
			this.title = _("Notes");
			this.deletable = false;
			this.skip_taskbar_hint = true;
			this.default_height = 380;
			this.default_width = 300;
			this.decorated = false;
			this.icon_name = "xfce4-notes-plugin";
			this.sticky = true;
			this.opacity = 0.9;
		}

		public Window () {
			/* Window responses on pointer motion */
			add_events (Gdk.EventMask.POINTER_MOTION_MASK|Gdk.EventMask.POINTER_MOTION_HINT_MASK|Gdk.EventMask.BUTTON_PRESS_MASK);

			/* Build accelerators */
			this.action_group = new Gtk.ActionGroup ("XNP");
			this.action_group.add_actions (action_entries, this);

			this.ui = new Gtk.UIManager ();
			this.ui.insert_action_group (this.action_group, 0);
			try {
				this.ui.add_ui_from_string (this.ui_string , -1);
				add_accel_group (this.ui.get_accel_group ());
			}
			catch (Error e) {
				warning ("%s", e.message);
			}

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
			title_box.pack_start (menu_box, false, false, 4);
			var title_evbox = new Gtk.EventBox ();
			this.title_label = new Gtk.Label (null);
			this.title_label.set_markup ("<b>"+this.title+"</b>");
			this.title_label.ellipsize = Pango.EllipsizeMode.END;
			title_evbox.add (this.title_label);
			title_box.pack_start (title_evbox, true, true, 0);
			var close_box = new Gtk.Button ();
			close_box.tooltip_text = Gtk.accelerator_get_label (0xff1b, 0); // GDK_Escape
			close_box.set_relief (Gtk.ReliefStyle.NONE);
			close_box.can_focus = false;
			var close_label = new Gtk.Label ("<b>x</b>");
			close_label.use_markup = true;
			close_box.add (close_label);
			title_box.pack_start (close_box, false, false, 4);
			title_box.show_all ();
			vbox_frame.pack_start (title_box, false, false, 0);
			if (close_box.allocation.width < 22)
				close_box.set_size_request (22, -1);

			/* Build content box */
			this.content_box = new Gtk.VBox (false, 0);
			this.content_box.show ();
			vbox_frame.pack_start (this.content_box, true, true, 0);

			/* Build Notebook */
			this.notebook = new Gtk.Notebook ();
			this.notebook.show_border = false;
			this.notebook.show_tabs = false;
			this.notebook.scrollable = true;
			this.notebook.show ();
			this.content_box.pack_start (this.notebook, true, true, 0);

			/* Build navigation toolbar */
			this.navigation_box = new Gtk.HBox (false, 2);
			this.goleft_box = new Gtk.Button ();
			this.goleft_box.tooltip_text = Gtk.accelerator_get_label (0xff55, Gdk.ModifierType.CONTROL_MASK); // GDK_Page_Up
			this.goleft_box.set_relief (Gtk.ReliefStyle.NONE);
			this.goleft_box.can_focus = false;
			this.goleft_box.sensitive = false;
			var goleft_label = new Gtk.Label ("<b>&lt;</b>");
			goleft_label.use_markup = true;
			this.goleft_box.add (goleft_label);
			this.navigation_box.pack_start (this.goleft_box, true, false, 0);
			if (this.goleft_box.allocation.width < 22)
				this.goleft_box.set_size_request (22, -1);
			var add_box = new Gtk.Button ();
			add_box.set_tooltip_text (Gtk.accelerator_get_label ('N', Gdk.ModifierType.CONTROL_MASK));
			add_box.set_relief (Gtk.ReliefStyle.NONE);
			add_box.can_focus = false;
			var add_label = new Gtk.Label ("<b>+</b>");
			add_label.use_markup = true;
			add_box.add (add_label);
			this.navigation_box.pack_start (add_box, true, false, 0);
			if (add_box.allocation.width < 22)
				add_box.set_size_request (22, -1);
			var del_box = new Gtk.Button ();
			del_box.set_tooltip_text (Gtk.accelerator_get_label ('W', Gdk.ModifierType.CONTROL_MASK));
			del_box.set_relief (Gtk.ReliefStyle.NONE);
			del_box.can_focus = false;
			var del_label = new Gtk.Label ("<b>−</b>");
			del_label.use_markup = true;
			del_box.add (del_label);
			this.navigation_box.pack_start (del_box, true, false, 0);
			if (del_box.allocation.width < 22)
				del_box.set_size_request (22, -1);
			this.goright_box = new Gtk.Button ();
			this.goright_box.tooltip_text = Gtk.accelerator_get_label (0xff56, Gdk.ModifierType.CONTROL_MASK); // GDK_Page_Down
			this.goright_box.set_relief (Gtk.ReliefStyle.NONE);
			this.goright_box.can_focus = false;
			this.goright_box.sensitive = false;
			var goright_label = new Gtk.Label ("<b>&gt;</b>");
			goright_label.use_markup = true;
			this.goright_box.add (goright_label);
			this.navigation_box.pack_start (this.goright_box, true, false, 0);
			if (this.goright_box.allocation.width < 22)
				this.goright_box.set_size_request (22, -1);
			this.navigation_box.show_all ();
			this.navigation_box.hide ();
			this.content_box.pack_start (this.navigation_box, false, false, 1);

			/* Connect mouse click signals */
			menu_box.button_press_event += menu_box_pressed_cb;
			close_box.clicked += () => { hide (); };
			add_box.clicked += action_new_note;
			del_box.clicked += action_delete_note;
			this.goleft_box.clicked += action_prev_note;
			this.goright_box.clicked += action_next_note;

			/* Connect extra signals */
			delete_event += () => {
				/* Replace ALT+F4 action */
				hide ();
				return true;
			};
			focus_in_event += () => {
				title_label.sensitive = true;
				return false;
			};
			focus_out_event += () => {
				title_label.sensitive = false;
				return false;
			};
			leave_notify_event += navigation_leaved_cb;
			motion_notify_event += navigation_motion_cb;
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
				var note = (Xnp.Note)(notebook.get_nth_page ((int)p));
				update_title (note.name);
				update_navigation_sensitivity ((int)p);
			};
			notify += (o, p) => {
				if (p.name == "name") {
					int page = this.notebook.get_current_page ();
					if (page == -1)
						return;
					var current_note = (Xnp.Note)(this.notebook.get_nth_page (page));
					update_title (current_note.name);
				}
				else if (p.name == "title") {
					title_label.set_markup ("<b>"+title+"</b>");
				}
			};
		}

		~Window () {
			if (this.navigation_timeout != 0)
				Source.remove (this.navigation_timeout);
		}

		/*
		 * Signal callbacks
		 */

		/**
		 * hide:
		 *
		 * Save position before hidding.
		 */
		public new void hide () {
			int winx, winy;
			get_position (out winx, out winy);
			base.hide ();
			deiconify ();
			unshade ();
			move (winx, winy);
		}

		/**
		 * navigation_leaved_cb:
		 *
		 * Hide the navigation when the mouse pointer is leaving the window.
		 */
		private bool navigation_leaved_cb () {
			int timeout = 2;
			if (is_active) {
				int x, y;
				get_pointer (out x, out y);
				if (x >= 0 && x < allocation.width && y >= 0 && y < allocation.height) {
					timeout = 10;
				}
			}
			navigation_timeout = Timeout.add_seconds (timeout, () => {
				navigation_box.hide ();
				navigation_timeout = 0;
				return false;
				});
			return false;
		}

		/**
		 * navigation_motion_cb:
		 *
		 * Show the navigation when the mouse pointer is hovering the window.
		 */
		private bool navigation_motion_cb () {
			if (navigation_timeout != 0) {
				Source.remove (navigation_timeout);
				navigation_timeout = 0;
			}
			navigation_box.show ();
			return false;
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
				this.mi_above.active = (bool)(event.new_window_state & Gdk.WindowState.ABOVE);
			}
			if ((bool)(event.changed_mask & Gdk.WindowState.STICKY) &&
				(bool)(get_flags () & Gtk.WidgetFlags.VISIBLE)) {
				this.mi_sticky.active = (bool)(event.new_window_state & Gdk.WindowState.STICKY);
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

		/**
		 * note_notify:
		 *
		 * Update the window title on note name changes.
		 */
		private void note_notify (GLib.Object object, GLib.ParamSpec pspec) {
			if (pspec.name == "name") {
				/* Update the window title */
				var note = (Xnp.Note)object;
				this.notebook.set_tab_label_text (note, note.name);
				int page = this.notebook.get_current_page ();
				var current_note = (Xnp.Note)(this.notebook.get_nth_page (page));
				if (note == current_note)
					this.update_title (note.name);
			}
		}

		/*
		 * Action callbacks
		 */

		private void action_new_window () {
			action ("create-new-window");
		}

		private void action_delete_window () {
			action ("delete");
		}

		private void action_rename_window () {
			action ("rename");
		}

		private void action_new_note () {
			insert_note ();
		}

		private void action_delete_note () {
			delete_current_note ();
		}

		private void action_rename_note () {
			rename_current_note ();
		}

		private void action_cancel () {
			int page = notebook.get_current_page ();
			if (page < 0)
				return;
			Gtk.Widget child = notebook.get_nth_page (page);
			((Xnp.Note)child).text_view.undo ();
		}

		private void action_next_note () {
			notebook.next_page ();
		}

		private void action_prev_note () {
			notebook.prev_page ();
		}

		/*
		 * Window menu
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
				x = x - menu.requisition.width + content_box.allocation.y;
			}
		}

		/**
		 * build_menu:
		 *
		 * Build the window menu.
		 */
		private Gtk.Menu build_menu () {
			var menu = new Gtk.Menu ();
			menu.set_accel_group (this.ui.get_accel_group ());

			var mi = new Gtk.MenuItem.with_mnemonic (_("_Go"));
			menu.append (mi);

			/* Navigation */
			var menu_go = new Gtk.Menu ();
			menu_go.set_accel_group (this.ui.get_accel_group ());
			menu_go.show += update_menu_go;
			mi.set_submenu (menu_go);

			/* Note items */
			mi = new Gtk.SeparatorMenuItem ();
			menu.append (mi);

			mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_NEW, null);
			mi.set_accel_path (this.action_group.get_action ("new-note").get_accel_path ());
			mi.activate += action_new_note;
			menu.append (mi);

			mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_DELETE, null);
			mi.set_accel_path (this.action_group.get_action ("delete-note").get_accel_path ());
			mi.activate += action_delete_note;
			menu.append (mi);

			mi = new Gtk.ImageMenuItem.with_mnemonic (_("_Rename"));
			var image = new Gtk.Image.from_stock (Gtk.STOCK_EDIT, Gtk.IconSize.MENU);
			((Gtk.ImageMenuItem)mi).set_image (image);
			mi.set_accel_path (this.action_group.get_action ("rename-note").get_accel_path ());
			mi.activate += action_rename_note;
			menu.append (mi);

			mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_UNDO, null);
			mi.set_accel_path (this.action_group.get_action ("cancel").get_accel_path ());
			mi.activate += action_cancel;
			menu.append (mi);

			/* Window options */
			mi = new Gtk.SeparatorMenuItem ();
			menu.append (mi);

			mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_PROPERTIES, null);
			mi.activate += () => { action ("properties"); };
			menu.append (mi);

			mi = this.mi_above = new Gtk.CheckMenuItem.with_label (_("Always on top"));
			((Gtk.CheckMenuItem)mi).active = this.above;
			((Gtk.CheckMenuItem)mi).toggled += (o) => { above = o.active; };
			menu.append (mi);

			mi = this.mi_sticky = new Gtk.CheckMenuItem.with_label (_("Sticky window"));
			((Gtk.CheckMenuItem)mi).active = this.sticky;
			((Gtk.CheckMenuItem)mi).toggled += (o) => { sticky = o.active; };
			menu.append (mi);

			return menu;
		}

		/**
		 * update_menu_go:
		 *
		 * Update the menu Go when it is shown.
		 */
		private void update_menu_go (Gtk.Menu menu) {
			Gtk.MenuItem mi;
			Gtk.Image image;

			menu.@foreach ((w) => {
					w.destroy ();
				});

			foreach (var win in this.window_list) {
				if (win == this) {
					mi = new Gtk.MenuItem.with_label (win.name);
					mi.sensitive = false;
					menu.append (mi);

					int current_page = this.notebook.get_current_page ();
					var current_note = (Xnp.Note)(this.notebook.get_nth_page (current_page));
					int n_pages = this.notebook.get_n_pages ();
					for (int p = 0; p < n_pages; p++) {
						var note = (Xnp.Note)(this.notebook.get_nth_page (p));
						mi = new Gtk.ImageMenuItem.with_label (note.name);
						if (note == current_note) {
							image = new Gtk.Image.from_stock (Gtk.STOCK_GO_FORWARD, Gtk.IconSize.MENU);
							((Gtk.ImageMenuItem)mi).set_image (image);
						}
						mi.set_data ("page", (void*)p);
						mi.activate += (i) => {
							int page = (int)i.get_data ("page");
							notebook.set_current_page (page);
						};
						menu.append (mi);
					}

					mi = new Gtk.SeparatorMenuItem ();
					menu.append (mi);
				}
				else {
					mi = new Gtk.MenuItem.with_label (win.name);
					mi.set_data ("window", (void*)win);
					mi.activate += (i) => {
						var w = (Xnp.Window)i.get_data ("window");
						w.present ();
					};
					menu.append (mi);

					mi = new Gtk.SeparatorMenuItem ();
					menu.append (mi);
				}
			}

			mi = new Gtk.ImageMenuItem.with_mnemonic (_("_Rename group"));
			image = new Gtk.Image.from_stock (Gtk.STOCK_EDIT, Gtk.IconSize.MENU);
			((Gtk.ImageMenuItem)mi).set_image (image);
			mi.set_accel_path (this.action_group.get_action ("rename-window").get_accel_path ());
			mi.activate += action_rename_window;
			menu.append (mi);

			mi = new Gtk.ImageMenuItem.with_mnemonic (_("_Delete group"));
			image = new Gtk.Image.from_stock (Gtk.STOCK_REMOVE, Gtk.IconSize.MENU);
			((Gtk.ImageMenuItem)mi).set_image (image);
			mi.set_accel_path (this.action_group.get_action ("delete-window").get_accel_path ());
			mi.activate += action_delete_window;
			menu.append (mi);

			mi = new Gtk.ImageMenuItem.with_mnemonic (_("_Add a new group"));
			image = new Gtk.Image.from_stock (Gtk.STOCK_ADD, Gtk.IconSize.MENU);
			((Gtk.ImageMenuItem)mi).set_image (image);
			mi.set_accel_path (this.action_group.get_action ("new-window").get_accel_path ());
			mi.activate += action_new_window;
			menu.append (mi);

			menu.show_all ();
		}

		/**
		 * get_geometry:
		 *
		 * Returns the X,Y position and width/height.
		 */
		public void get_geometry (out int winx, out int winy, out int width, out int height) {
			// Window is shaded
			if (!(bool)(this.content_box.get_flags () & Gtk.WidgetFlags.VISIBLE)) {
				get_size (out this.width, null);
			}
			else {
				get_size (out this.width, out this.height);
			}
			get_position (out winx, out winy);
			width = this.width;
			height = this.height;
		}

		/**
		 * set_window_list:
		 *
		 * Saves a list of window inside window.window_list to be shown
		 * within the window menu.
		 */
		public void set_window_list (SList<Xnp.Window> list) {
			this.window_list = list;
		}

		/**
		 * compare_func:
		 *
		 * Compare function for the window name to use with GLib.CompareFunc delegates.
		 */
		public int compare_func (Xnp.Window win2) {
			return name.collate (win2.name);
		}

		/**
		 * get_current_page:
		 *
		 * Get the current page in the notebook.
		 */
		public int get_current_page () {
			return this.notebook.get_current_page ();
		}

		/**
		 * set_current_page:
		 *
		 * Set the current page in the notebook.
		 */
		public void set_current_page (int page) {
			this.notebook.set_current_page (page);
		}

		/*
		 * Window management
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

		/**
		 * update_title:
		 *
		 * Updates the window title.
		 */
		private void update_title (string note_name) {
			title = this.name + " - " + note_name;
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
				this.goleft_box.sensitive = page_num > 0 ? true : false;
				this.goright_box.sensitive = page_num + 1 < n_pages ? true : false;
			}
		}

		/*
		 * Note management
		 */

		/**
		 * insert_note:
		 *
		 * Create a new note and insert it inside the notebook after
		 * the current position.
		 */
		public Xnp.Note insert_note () {
			int len = this.notebook.get_n_pages ();
			string name = _("Notes");
			for (int id = 1; id <= len + 1; id++) {
				if (id > 1) {
					name = _("Notes %d").printf (id);
				}
				if (!note_name_exists (name)) {
					break;
				}
			}

			int page = this.notebook.get_current_page () + 1;
			var note = new Xnp.Note (name);

			note.notify += note_notify;
			note.save_data += (note) => { save_data (note); };

			note.show ();
			this.n_pages++;
			this.notebook.insert_page (note, null, page);
			this.note_inserted (note);
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
		 * Delete note at page @page.
		 */
		public void delete_note (int page) {
			var note = (Xnp.Note)this.notebook.get_nth_page (page);

			if (note.text_view.buffer.get_char_count () > 0) {
				var dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
					Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, _("Are you sure you want to delete this note?"));
				int res = dialog.run ();
				dialog.destroy ();
				if (res != Gtk.ResponseType.YES)
					return;
			}

			this.n_pages--;
			this.notebook.remove_page (page);
			this.note_deleted (note);
			note.destroy ();
			if (this.notebook.get_n_pages () == 0)
				action ("delete");
		}

		/**
		 * rename_current_note:
		 *
		 * Rename the current note.
		 */
		public void rename_current_note () {
			int page = this.notebook.get_current_page ();
			if (page == -1)
				return;
			var note = (Xnp.Note)(this.notebook.get_nth_page (page));

			var dialog = new Gtk.Dialog.with_buttons (_("Rename note"), (Gtk.Window)get_toplevel (),
				Gtk.DialogFlags.MODAL|Gtk.DialogFlags.DESTROY_WITH_PARENT|Gtk.DialogFlags.NO_SEPARATOR,
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
			dialog.hide ();
			if (res == Gtk.ResponseType.OK) {
				weak string name = entry.text;
				if (note_name_exists (name)) {
					var error_dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
						Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, _("The name %s is already in use"), name);
					error_dialog.run ();
					error_dialog.destroy ();
				}
				else {
					string old_name = note.name;
					note.name = name;
					this.note_renamed (note, old_name);
				}
			}
			dialog.destroy ();
		}

		/**
		 * set_font:
		 *
		 * Set the font for the window.
		 */
		public void set_font () {
			int page = this.notebook.get_current_page ();
			if (page == -1)
				return;
			var note = (Xnp.Note)(this.notebook.get_nth_page (page));

			var dialog = new Gtk.FontSelectionDialog ("Choose current note font");
			dialog.set_font_name (note.text_view.font);
			int res = dialog.run ();
			dialog.hide ();
			if (res == Gtk.ResponseType.OK) {
				note.text_view.font = dialog.get_font_name ();
			}
			dialog.destroy ();
		}

		/**
		 * note_name_exists:
		 *
		 * Verify if the given name already exists in the notebook.
		 */
		private bool note_name_exists (string name) {
			int n_pages = this.notebook.get_n_pages ();
			for (int p = 0; p < n_pages; p++) {
				var note = (Xnp.Note)this.notebook.get_nth_page (p);
				if (note.name == name) {
					return true;
				}
			}
			return false;
		}

		/**
		 * save_notes:
		 *
		 * Send the save-data signal on every dirty note.
		 */
		public void save_notes () {
			int n_pages = this.notebook.get_n_pages ();
			for (int p = 0; p < n_pages; p++) {
				var note = (Xnp.Note)this.notebook.get_nth_page (p);
				if (note.dirty) {
					note.dirty = false;
					save_data (note);
				}
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

