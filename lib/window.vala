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

	public class Window : Gtk.Window {

		private Xnp.Application app;
		private int width;
		private int height;
		private Gtk.Menu menu;
		private Gtk.CheckMenuItem mi_above;
		private Gtk.CheckMenuItem mi_sticky;
		private Gtk.Image menu_image;
		private Gtk.Label title_label;
		private Xnp.TitleBarButton refresh_button;
		private Xnp.TitleBarButton left_arrow_button;
		private Xnp.TitleBarButton right_arrow_button;
		private Xnp.TitleBarButton close_button;
		private Gtk.Box content_box;
		private Gtk.Notebook notebook;

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
  <accelerator action="undo" />
  <accelerator action="redo" />
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
			{ "undo",          null, null, "<Ctrl>z", null, action_undo },
			{ "redo",          null, null, "<Ctrl>y", null, action_redo },
			{ "next-note",     null, null, "<Ctrl>Page_Down", null, action_next_note },
			{ "prev-note",     null, null, "<Ctrl>Page_Up", null, action_prev_note }
		};

		private int CORNER_MARGIN = 20;
		private Gdk.Cursor CURSOR_TOP_LC = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.TOP_LEFT_CORNER);
		private Gdk.Cursor CURSOR_TOP = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.TOP_SIDE);
		private Gdk.Cursor CURSOR_TOP_RC = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.TOP_RIGHT_CORNER);
		private Gdk.Cursor CURSOR_RIGHT = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.RIGHT_SIDE);
		private Gdk.Cursor CURSOR_LEFT = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.LEFT_SIDE);
		private Gdk.Cursor CURSOR_BOTTOM_RC = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.BOTTOM_RIGHT_CORNER);
		private Gdk.Cursor CURSOR_BOTTOM = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.BOTTOM_SIDE);
		private Gdk.Cursor CURSOR_BOTTOM_LC = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.BOTTOM_LEFT_CORNER);

		public new string name { default = _("Notes"); get; set; }

		public Xnp.Note current_note {
			get {
				return (Xnp.Note)this.notebook.get_nth_page (this.notebook.page);
			}
		}

		public int n_pages {
			get {
				return this.notebook.get_n_pages ();
			}
		}

		public bool empty {
			get {
				int n_pages = this.n_pages;
				return n_pages == 1 ? get_note (0).text == "" : n_pages == 0;
			}
		}

		public bool show_tabs {
			get {
				return this.notebook.show_tabs;
			}
			set {
				this.notebook.show_tabs = value;
			}
		}

		private int _tabs_position;
		public int tabs_position {
			get {
				return this._tabs_position;
			}
			set {
				this._tabs_position = value;
				if (this._tabs_position == 0)
					show_tabs = false;
				else {
					show_tabs = true;
					_notebook_update_tabs_angle ();
					if (this._tabs_position == 1)
						this.notebook.tab_pos = Gtk.PositionType.TOP;
					else if (this._tabs_position == 2)
						this.notebook.tab_pos = Gtk.PositionType.RIGHT;
					else if (this._tabs_position == 3)
						this.notebook.tab_pos = Gtk.PositionType.BOTTOM;
					else if (this._tabs_position == 4)
						this.notebook.tab_pos = Gtk.PositionType.LEFT;
					else {
						this.show_tabs = false;
						warning ("Bad value for tabs-position");
					}
				}
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
				if (this.mi_sticky is Gtk.CheckMenuItem)
					this.mi_sticky.active = this._sticky;
			}
		}

		private bool _show_refresh_button;
		public bool show_refresh_button {
			get {
				return this._show_refresh_button;
			}
			set {
				this._show_refresh_button = value;
				if (value == true) {
					this.refresh_button.show ();
				}
				else {
					this.refresh_button.hide ();
				}
			}
		}

		public signal void action (string action);
		public signal void save_data (Xnp.Note note);
		public signal void note_inserted (Xnp.Note note);
		public signal void note_deleted (Xnp.Note note);
		public signal void note_renamed (Xnp.Note note, string name);
		public signal bool note_moved (Xnp.Window src_win, Xnp.Note note);

		construct {
			((Gtk.Widget)this).name = "notes-window";
			this.title = _("Notes");
			this.deletable = false;
			this.skip_taskbar_hint = true;
			this.default_height = 380;
			this.default_width = 300;
			this.decorated = false;
			this.icon_name = "org.xfce.notes";
			this.sticky = true;
			this.opacity = 0.9;
		}

		public Window (Xnp.Application app) {
			this.app = app;

			/* Window responses on pointer motion */
			add_events (Gdk.EventMask.POINTER_MOTION_MASK|Gdk.EventMask.BUTTON_PRESS_MASK);

			/* Build accelerators */
			this.action_group = new Gtk.ActionGroup ("XNP");
			this.action_group.add_actions (action_entries, this);

			this.ui = new Gtk.UIManager ();
			this.ui.insert_action_group (this.action_group, 0);
			try {
				this.ui.add_ui_from_string (ui_string , -1);
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
			var vbox_frame = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

			vbox_frame.spacing = 1;
			vbox_frame.show ();
			frame.add (vbox_frame);

			/* Build title bar */
			var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
			title_box.name = "titlebar";
			var menu_evbox = new Gtk.EventBox ();
			menu_evbox.tooltip_text = _("Menu");
			menu_evbox.set_visible_window (false);
			this.menu_image = new Gtk.Image.from_icon_name ("org.xfce.notes.menu", IconSize.MENU);
			menu_evbox.add (this.menu_image);
			menu_evbox.enter_notify_event.connect (() => {
				this.menu_image.set_from_icon_name ("org.xfce.notes.menu-active", IconSize.MENU);
				menu_evbox.get_window ().invalidate_rect (null, false);
				return false;
			});
			menu_evbox.leave_notify_event.connect (() => {
				this.menu_image.set_from_icon_name ("org.xfce.notes.menu", IconSize.MENU);
				menu_evbox.get_window ().invalidate_rect (null, false);
				return false;
			});
			title_box.pack_start (menu_evbox, false, false, 2);
			var title_evbox = new Gtk.EventBox ();
			title_evbox.add_events (Gdk.EventMask.SCROLL_MASK);
			title_evbox.set_visible_window (false);
			this.title_label = new Gtk.Label (null);
			this.title_label.set_markup (Markup.printf_escaped ("<b>%s</b>", this.title));
			this.title_label.ellipsize = Pango.EllipsizeMode.END;
			this.title_label.xalign = (float)0.0;
			title_evbox.add (this.title_label);
			title_box.pack_start (title_evbox, true, true, 6);
			this.refresh_button = new Xnp.TitleBarButton (Xnp.TitleBarButtonType.REFRESH);
			this.refresh_button.tooltip_text = _("Refresh notes");
			this.refresh_button.no_show_all = true;
			this.refresh_button.sensitive = false;
			title_box.pack_start (this.refresh_button, false, false, 2);
			this.left_arrow_button = new Xnp.TitleBarButton (Xnp.TitleBarButtonType.LEFT_ARROW);
			this.left_arrow_button.add_events (Gdk.EventMask.SCROLL_MASK);
			this.left_arrow_button.tooltip_text = Gtk.accelerator_get_label (Gdk.Key.Page_Up, Gdk.ModifierType.CONTROL_MASK);
			this.left_arrow_button.enabled = false;
			title_box.pack_start (this.left_arrow_button, false, false, 2);
			this.right_arrow_button = new Xnp.TitleBarButton (Xnp.TitleBarButtonType.RIGHT_ARROW);
			this.right_arrow_button.add_events (Gdk.EventMask.SCROLL_MASK);
			this.right_arrow_button.tooltip_text = Gtk.accelerator_get_label (Gdk.Key.Page_Down, Gdk.ModifierType.CONTROL_MASK);
			this.right_arrow_button.enabled = false;
			title_box.pack_start (this.right_arrow_button, false, false, 2);
			this.close_button = new Xnp.TitleBarButton (Xnp.TitleBarButtonType.CLOSE);
			this.close_button.tooltip_text = _("Hide (%s)").printf (Gtk.accelerator_get_label (Gdk.Key.Escape, 0));
			title_box.pack_start (this.close_button, false, false, 2);
			title_box.show_all ();
			vbox_frame.pack_start (title_box, false, false, 0);

			/* Build content box */
			this.content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			this.content_box.show ();
			vbox_frame.pack_start (this.content_box, true, true, 0);

			/* Build Notebook */
			this.notebook = new Gtk.Notebook ();
			this.notebook.add_events (Gdk.EventMask.SCROLL_MASK);
			this.notebook.name = "notes-notebook";
			this.notebook.group_name = "notes";
			this.notebook.show_border = true;
			this.notebook.show_tabs = false;
			this.notebook.tab_pos = Gtk.PositionType.TOP;
			this.notebook.scrollable = true;
			this.notebook.show ();
			this.content_box.pack_start (this.notebook, true, true, 0);

			/* Connect mouse click signals */
			menu_evbox.button_press_event.connect (menu_evbox_pressed_cb);
			this.refresh_button.clicked.connect (action_refresh_notes);
			this.left_arrow_button.clicked.connect (action_prev_note);
			this.right_arrow_button.clicked.connect (action_next_note);
			this.close_button.clicked.connect (() => { hide (); });

			/* Connect extra signals */
			delete_event.connect (() => {
				/* Replace ALT+F4 action */
				hide ();
				return true;
			});
			this.notify["is-active"].connect (() => {
				if (this.is_active) {
					menu_image.sensitive = true;
					refresh_button.sensitive = true;
					close_button.sensitive = true;
					update_navigation_sensitivity (this.notebook.page);
				} else {
					menu_image.sensitive = false;
					refresh_button.sensitive = false;
					left_arrow_button.enabled = false;
					right_arrow_button.enabled = false;
					close_button.sensitive = false;
					save_current_note ();
				}
			});
			leave_notify_event.connect (window_leaved_cb);
			motion_notify_event.connect (window_motion_cb);
			button_press_event.connect (window_pressed_cb);
			window_state_event.connect (window_state_cb);
			title_evbox.button_press_event.connect (title_evbox_pressed_cb);
			title_evbox.scroll_event.connect (title_evbox_scrolled_cb);
			left_arrow_button.scroll_event.connect (notebook_tab_scroll_cb);
			right_arrow_button.scroll_event.connect (notebook_tab_scroll_cb);
			this.notebook.page_added.connect ((n, c, p) => {
				notebook.page = (int)p;
				update_navigation_sensitivity ((int)p);
			});
			this.notebook.page_removed.connect ((n, c, p) => {
				update_navigation_sensitivity ((int)p);
			});
			this.notebook.switch_page.connect ((n, c, p) => {
				save_current_note ();
				update_title (get_note ((int)p).name);
				update_navigation_sensitivity ((int)p);
			});
			this.notebook.scroll_event.connect (notebook_tab_scroll_cb);
			notify["name"].connect (() => {
				var current_note = this.current_note;
				if (current_note != null) {
					update_title (current_note.name);
				} else {
					this.title = this.name;
				}
				if (this.title_label.get_mapped ()) {
					this.title_label.get_window ().invalidate_rect (null, false);
				}
			});
			notify["title"].connect (() => {
				title_label.set_markup (Markup.printf_escaped ("<b>%s</b>", title));
			});
			this.notebook.drag_drop.connect ((c, x, y, t) => {
				var src_notebook = Gtk.drag_get_source_widget (c) as Gtk.Notebook;
				if (src_notebook == null || src_notebook == this.notebook)
					return false;
				var src_win = (Xnp.Window)src_notebook.get_toplevel ();
				if (this.note_moved (src_win, src_win.current_note))
					return false;
				Gtk.drag_finish (c, false, false, t);
				return true;
			});
			this.notebook.drag_data_received.connect_after ((c) => {
				var src_notebook = Gtk.drag_get_source_widget (c) as Gtk.Notebook;
				if (src_notebook == null)
					return;
				var src_win = (Xnp.Window)src_notebook.get_toplevel ();
				if (src_win.n_pages == 0)
					src_win.action ("delete");
			});
		}

		~Window () {
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
			var new_focus = this.app.next_focus;
			get_position (out winx, out winy);
			if (new_focus != null) {
				new_focus.skip_taskbar_hint = false;
				new_focus.present ();
				base.hide ();
				new_focus.skip_taskbar_hint = this.app.skip_taskbar_hint;
			} else {
				base.hide ();
			}
			action ("hide");
			deiconify ();
			unshade ();
			move (winx, winy);
			set_keep_above (this.above);
		}

		/**
		 * window_leaved_cb:
		 *
		 * Reset the mouse cursor.
		 */
		private bool window_leaved_cb (Gdk.EventCrossing event) {
			Gtk.Allocation allocation;
			get_allocation (out allocation);
			bool outside = event.x <= 0 || event.x >= allocation.width
				|| event.y <= 0 || event.y >= allocation.height;
			if (!outside) return true;
			get_window ().set_cursor (null);
			return true;
		}

		/**
		 * window_motion_cb:
		 *
		 * Update mouse cursor.
		 */
		private bool window_motion_cb (Gdk.EventMotion event) {
			Gtk.Allocation allocation;
			Gdk.Cursor cursor;
			void *widget;

			event.window.get_user_data (out widget);
			if (widget != this) {
				get_window ().set_cursor (null);
				return false;
			}

			get_allocation (out allocation);

			if (event.x > 4 && event.y > 4
				&& event.x < allocation.width - 4
				&& event.y < allocation.height - 4) {
				get_window ().set_cursor (null);
				return false;
			}

			// Top
			if (event.y <= CORNER_MARGIN) {
				// Top left corner
				if (event.x <= CORNER_MARGIN)
					cursor = CURSOR_TOP_LC;
				// Top right corner
				else if (event.x >= allocation.width - CORNER_MARGIN)
					cursor = CURSOR_TOP_RC;
				else
					cursor = CURSOR_TOP;
			}
			// Bottom
			else if (event.y > allocation.height - CORNER_MARGIN) {
				// Bottom left corner
				if (event.x <= CORNER_MARGIN)
					cursor = CURSOR_BOTTOM_LC;
				// Bottom right corner
				else if (event.x >= allocation.width - CORNER_MARGIN)
					cursor = CURSOR_BOTTOM_RC;
				else
					cursor = CURSOR_BOTTOM;
			}
			// Left
			else if (event.x <= CORNER_MARGIN)
				cursor = CURSOR_LEFT;
			// Right
			else
				cursor = CURSOR_RIGHT;

			this.notebook.motion_notify_event (event);
			get_window ().set_cursor (cursor);
			return true;
		}

		/**
		 * window_pressed_cb:
		 *
		 * Start a window resize depending on mouse pointer location.
		 */
		private bool window_pressed_cb (Gdk.EventButton event) {
			var cursor = get_window ().get_cursor ();
			Gdk.WindowEdge edge;

			if (cursor == CURSOR_TOP)
				edge = NORTH;
			else if (cursor == CURSOR_BOTTOM)
				edge = SOUTH;
			else if (cursor == CURSOR_LEFT)
				edge = WEST;
			else if (cursor == CURSOR_RIGHT)
				edge = EAST;
			else if (cursor == CURSOR_TOP_LC)
				edge = NORTH_WEST;
			else if (cursor == CURSOR_TOP_RC)
				edge = NORTH_EAST;
			else if (cursor == CURSOR_BOTTOM_LC)
				edge = SOUTH_WEST;
			else if (cursor == CURSOR_BOTTOM_RC)
				edge = SOUTH_EAST;
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
		private bool window_state_cb (Gdk.EventWindowState event) {
			if ((bool)(event.changed_mask & Gdk.WindowState.ABOVE)) {
				/* FIXME above state is never notified despit
				 * of xfwm4 switching the state */
				this.mi_above.active = (bool)(event.new_window_state & Gdk.WindowState.ABOVE);
			}
			if ((bool)(event.changed_mask & Gdk.WindowState.STICKY) && get_visible ()) {
				this.sticky = (bool)((event.new_window_state & Gdk.WindowState.STICKY) != 0);
			}
			return false;
		}

		/**
		 * title_evbox_pressed_cb:
		 *
		 * Raise/lower the window and popup window menu.
		 */
		private bool title_evbox_pressed_cb (Gtk.Widget widget, Gdk.EventButton event) {
			if (event.type != Gdk.EventType.BUTTON_PRESS)
				return false;
			if (get_window ().get_cursor () != null)
				return false;
			if (event.button == Gdk.BUTTON_PRIMARY) {
				get_window ().show ();
				int winx, winy, curx, cury;
				get_position (out winx, out winy);
				get_pointer (out curx, out cury);
				winx += curx;
				winy += cury;
				begin_move_drag (1, winx, winy, Gtk.get_current_event_time ());
			}
			else if (event.button == Gdk.BUTTON_MIDDLE) {
				get_window ().lower ();
			}
			else if (event.button == Gdk.BUTTON_SECONDARY) {
				this.menu.popup (null, null, null, 0, Gtk.get_current_event_time ());
			}
			return false;
		}

		/**
		 * title_evbox_scrolled_cb:
		 *
		 * Shade/unshade the window and set transparency by holding ALT.
		 */
		private bool title_evbox_scrolled_cb (Gtk.Widget widget, Gdk.EventScroll event) {
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
		 * notebook_tab_scroll_cb:
		 *
		 * Switch tabs with mouse scroll wheel.
		 */
		private bool notebook_tab_scroll_cb (Gdk.EventScroll event) {
			var current_note = this.current_note;

			if (current_note == null)
				return false;

			var event_widget = Gtk.get_event_widget (event);

			/* Ignore scroll events from the content of the page */
			if (event_widget == null ||
				event_widget == current_note ||
				event_widget.is_ancestor (current_note))
				return false;

			/* We only want to switch tabs on mouse wheel when no accelerators pressed */
			if ((event.state & Gtk.accelerator_get_default_mod_mask ()) != 0)
				return false;

			switch (event.direction) {
				case Gdk.ScrollDirection.RIGHT:
				case Gdk.ScrollDirection.DOWN:
					notebook.next_page ();
					break;
				case Gdk.ScrollDirection.LEFT:
				case Gdk.ScrollDirection.UP:
					notebook.prev_page ();
					break;
				default:
					return false;
			}

			return true;
		}

		/**
		 * note_notify_name_cb:
		 *
		 */
		private void note_notify_name_cb (GLib.Object object, GLib.ParamSpec? pspec) {
			Xnp.Note note = object as Xnp.Note;
			var tab_evbox = get_tab_evbox (note);
			var label = tab_evbox.get_child () as Gtk.Label;
			label.set_text (note.name);
			_notebook_update_tabs_angle ();
			if (note == this.current_note)
				this.update_title (note.name);
		}

		/**
		 * tab_evbox_pressed_cb:
		 *
		 * Handle mouse click events on notebook tabs.
		 */
		private bool tab_evbox_pressed_cb (Gdk.EventButton event, Xnp.Note note) {
			if (event.type == DOUBLE_BUTTON_PRESS && event.button == Gdk.BUTTON_PRIMARY)
				action_rename_note ();
			else if (event.button == Gdk.BUTTON_MIDDLE) {
				notebook.page = notebook.page_num (note);
				delete_current_note ();
			}
			else
				return false;

			return true;
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

		private void action_undo () {
			var current_note = this.current_note;
			if (current_note != null)
				current_note.text_view.undo ();
		}

		private void action_redo () {
			var current_note = this.current_note;
			if (current_note != null)
				current_note.text_view.redo ();
		}

		private void action_refresh_notes () {
			action ("refresh-notes");
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
		 * menu_evbox_pressed_cb:
		 *
		 * Popup the window menu.
		 */
		private bool menu_evbox_pressed_cb (Gtk.Widget widget, Gdk.EventButton event) {
			this.menu.popup (null, null, menu_position, 0, Gtk.get_current_event_time ());
			return false;
		}

		/**
		 * menu_position:
		 *
		 * Menu position function for the window menu.
		 */
		private void menu_position (Gtk.Menu menu, out int x, out int y, out bool push_in) {
			int winx, winy, width, height;
			Gtk.Requisition requisition;
			Gtk.Allocation allocation;

			get_window ().get_geometry (out winx, out winy, out width, out height);
			menu.get_preferred_size (out requisition, null);
			get_window ().get_origin (out x, out y);
			push_in = false;

			content_box.get_allocation (out allocation);

			if (y + allocation.y + requisition.height > Gdk.Screen.height ()) {
				/* Show menu above */
				y -= requisition.height;
			}
			else {
				/* Show menu below */
				y += allocation.y;
			}
			if (x + requisition.width > Gdk.Screen.width ()) {
				/* Adjust menu left */
				int menu_width;
				menu.get_preferred_width (out menu_width, null);
				x = x - menu_width + allocation.y;
			}
		}

		/**
		 * Menu creation helpers
		 */

		delegate void Callback();

		private void menu_add_icon_item (Gtk.Menu menu, string text, string icon, string? accel, Callback callback) {
			var mi = new Gtk.ImageMenuItem.with_mnemonic (text);
			var image = new Gtk.Image.from_icon_name (icon, Gtk.IconSize.MENU);
			mi.set_image (image);
			if (accel != null) {
				mi.set_accel_path (this.action_group.get_action (accel).get_accel_path ());
			}
			mi.activate.connect (() => { callback (); });
			menu.append (mi);
		}

		private Gtk.CheckMenuItem menu_add_check_item (Gtk.Menu menu, string text, bool active, Callback callback) {
			var mi = new Gtk.CheckMenuItem.with_label (text);
			mi.active = active;
			mi.toggled.connect (() => { callback (); });
			menu.append (mi);
			return mi;
		}

		private void menu_add_separator (Gtk.Menu menu) {
			var mi = new Gtk.SeparatorMenuItem ();
			menu.append (mi);
		}

		/**
		 * build_menu:
		 *
		 * Build the window menu.
		 */
		private Gtk.Menu build_menu () {
			var menu = new Gtk.Menu ();
			menu.set_accel_group (this.ui.get_accel_group ());

			var mi = new Gtk.MenuItem.with_mnemonic (_("_Groups"));
			menu.append (mi);

			/* Navigation */
			var menu_go = new Gtk.Menu ();
			menu_go.set_accel_group (this.ui.get_accel_group ());
			menu_go.show.connect (update_menu_go);
			mi.set_submenu (menu_go);

			/* Note items */
			menu_add_separator (menu);
			menu_add_icon_item (menu, _("_New"), "gtk-new", "new-note", action_new_note);
			menu_add_icon_item (menu, _("_Delete"), "gtk-delete", "delete-note", action_delete_note);
			menu_add_icon_item (menu, _("_Rename"), "gtk-edit", "rename-note", action_rename_note);

			/* Window options */
			menu_add_separator (menu);
			this.mi_above = menu_add_check_item (menu, _("Always on top"), above, () => { above = mi_above.active; });
			this.mi_sticky = menu_add_check_item (menu, _("Sticky window"), sticky, () => { sticky = mi_sticky.active; });

			/* Settings/About dialog */
			menu_add_separator (menu);
			menu_add_icon_item (menu, _("_Properties"), "gtk-properties", null, () => { action("properties"); });
			menu_add_icon_item (menu, _("_About"), "gtk-about", null, () => { action("about"); });

			return menu;
		}

		/**
		 * update_menu_go:
		 *
		 * Update the menu Go when it is shown.
		 */
		private void update_menu_go (Gtk.Widget widget) {
			Gtk.Menu menu = widget as Gtk.Menu;
			Gtk.MenuItem mi;
			Gtk.Image image;

			menu.@foreach ((w) => {
					w.destroy ();
				});

			foreach (var win in app.get_window_list ()) {
				if (win == this) {
					mi = new Gtk.MenuItem.with_label (win.name);
					mi.sensitive = false;
					menu.append (mi);

					var current_note = this.current_note;
					int n_pages = this.n_pages;

					for (int p = 0; p < n_pages; p++) {
						var note = get_note (p);
						mi = new Gtk.ImageMenuItem.with_label (note.name);
						if (note == current_note) {
							image = new Gtk.Image.from_icon_name ("gtk-go-forward", Gtk.IconSize.MENU);
							((Gtk.ImageMenuItem)mi).set_image (image);
						}
						mi.set_data ("page", p.to_pointer ());
						mi.activate.connect ((i) => {
							notebook.page = i.get_data<int> ("page");
						});
						menu.append (mi);
					}

					menu_add_separator (menu);
				}
				else {
					mi = new Gtk.MenuItem.with_label (win.name);
					mi.set_data ("window", (void*)win);
					mi.activate.connect ((i) => {
						var w = i.get_data<Xnp.Window> ("window");
						w.present ();
					});
					menu.append (mi);

					menu_add_separator (menu);
				}
			}

			menu_add_icon_item (menu, _("_Rename group"), "gtk-edit", "rename-window", action_rename_window);
			menu_add_icon_item (menu, _("_Delete group"), "gtk-remove", "delete-window", action_delete_window);
			menu_add_icon_item (menu, _("_Add a new group"), "gtk-add", "new-window", action_new_window);

			menu.show_all ();
		}

		/**
		 * get_geometry:
		 *
		 * Returns the X,Y position and width/height.
		 */
		public void get_geometry (out int winx, out int winy, out int width, out int height) {
			// Window is shaded
			if (!this.content_box.get_visible ()) {
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
			return this.notebook.page;
		}

		/**
		 * set_current_page:
		 *
		 * Set the current page in the notebook.
		 */
		public void set_current_page (int page) {
			this.notebook.page = page;
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
			if (this.content_box.get_visible ()) {
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
			if (!this.content_box.get_visible ()) {
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
			int n_pages = this.n_pages;
			if (n_pages <= 1) {
				this.left_arrow_button.enabled = false;
				this.right_arrow_button.enabled = false;
			}
			else {
				this.left_arrow_button.enabled = page_num > 0;
				this.right_arrow_button.enabled = page_num + 1 < n_pages;
			}
		}

		/**
		 * popup_error:
		 *
		 * Show a pop-up error message.
		 */
		public void popup_error (string message) {
			var error_dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
				Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "%s", message);
			error_dialog.icon_name = "gtk-dialog-error";
			error_dialog.title = this.name;
			error_dialog.run ();
			dialog_destroy (error_dialog);
		}

		/**
		 * dialog_hide:
		 *
		 * Hide dialog window and stay focused.
		 */
		public void dialog_hide (Gtk.Dialog dialog) {
			this.skip_taskbar_hint = false;
			dialog.hide ();
			this.skip_taskbar_hint = this.app.skip_taskbar_hint;
		}


		/**
		 * dialog_destroy:
		 *
		 * Destroy dialog window and stay focused.
		 */
		public void dialog_destroy (Gtk.Dialog dialog) {
			this.skip_taskbar_hint = false;
			dialog.destroy ();
			this.skip_taskbar_hint = this.app.skip_taskbar_hint;
		}

		/*
		 * Note management
		 */

		/**
		 * get_note:
		 *
		 * Get note from page.
		 */
		private Xnp.Note get_note (int p) {
			return (Xnp.Note)this.notebook.get_nth_page (p);
		}

		/**
		 * insert_note:
		 *
		 * Create a new note and insert it inside the notebook after
		 * the current position.
		 */
		public Xnp.Note insert_note (string? name = null) {
			string note_name = "";

			if (name == null) {
				int len = this.n_pages;
				for (int i = 1; i <= len + 1; i++) {
					note_name = _("Note %d").printf (i);
					if (!note_name_exists (note_name)) {
						break;
					}
				}
			} else {
				note_name = name;
			}

			var note = new Xnp.Note (note_name);
			this.note_inserted (note);
			if (!note.backed) {
				return note;
			}

			note.show ();
			var tab_evbox = new Gtk.EventBox ();
			tab_evbox.add_events (Gdk.EventMask.POINTER_MOTION_MASK|Gdk.EventMask.SCROLL_MASK);
			var label = new Gtk.Label (note_name);
			tab_evbox.add (label);
			label.show ();
			connect_note_signals (note, tab_evbox);
			this.notebook.insert_page (note, tab_evbox, this.notebook.page + 1);
			this.notebook.set_tab_reorderable (note, true);
			this.notebook.set_tab_detachable (note, true);
			_notebook_update_tabs_angle ();
			return note;
		}

		/**
		 * connect_note_signals:
		 *
		 * Connect note signals.
		 */
		public void connect_note_signals (Xnp.Note note, Gtk.EventBox tab_evbox) {
			note.notify["name"].connect (note_notify_name_cb);
			note.save_handler_id = note.save_data.connect ((note) => {
				this.save_data (note);
			});
			note.tab_handler_id = tab_evbox.button_press_event.connect ((e) => {
				return tab_evbox_pressed_cb (e, note);
			});
		}

		/**
		 * disconnect_note_signals:
		 *
		 * Disconnect note signals.
		 */
		public void disconnect_note_signals (Xnp.Note note, Gtk.EventBox tab_evbox) {
			note.notify["name"].disconnect (note_notify_name_cb);
			tab_evbox.disconnect (note.tab_handler_id);
			note.disconnect (note.save_handler_id);
		}

		/**
		 * move_note:
		 *
		 * Moves the note named @note_name to position @page.
		 */
		public void move_note (string note_name, int page) {
			int n_pages = this.n_pages;
			for (int p = 0; p < n_pages; p++) {
				var note = get_note (p);
				if (note.name == note_name) {
					this.notebook.reorder_child (note, page);
					update_navigation_sensitivity (page);
					break;
				}
			}
		}

		/**
		 * get_note_names:
		 *
		 * Returns a string list of the note names in the order they are currently displayed
		 * in the notebook.
		 */
		public string[] get_note_names () {
			string[] note_names = null;
			int n_pages = this.n_pages;
			for (int p = 0; p < n_pages; p++) {
				note_names += get_note (p).name;
			}
			return note_names;
		}

		/**
		 * get_tab_evbox:
		 *
		 * Get tab event box for note.
		 */
		public Gtk.EventBox get_tab_evbox (Xnp.Note note) {
			return this.notebook.get_tab_label (note) as Gtk.EventBox;
		}

		/**
		 * delete_current_note:
		 *
		 * Delete the current note.
		 */
		public void delete_current_note () {
			var note = this.current_note;
			var page = this.notebook.page;

			if (note == null) {
				if (this.n_pages == 0)
					action ("delete");
				return;
			}

			if (note.text_view.buffer.get_char_count () > 0) {
				var dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
					Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, _("Are you sure you want to delete this note?"));
				dialog.title = this.name + " - " + note.name;
				dialog.icon_name = "gtk-delete";
				int res = dialog.run ();
				dialog_destroy (dialog);
				if (res != Gtk.ResponseType.YES)
					return;
			}

			this.note_deleted (note);
			if (note.backed)
				return;

			this.notebook.remove_page (this.notebook.page);
			note.destroy ();

			if (this.notebook.page > 0 && page != this.n_pages)
				this.notebook.page--;

			if (this.n_pages == 0)
				action ("delete");
		}

		/**
		 * rename_current_note:
		 *
		 * Rename the current note.
		 */
		public void rename_current_note () {
			var note = this.current_note;
			if (note == null)
				return;

			var dialog = new Gtk.Dialog.with_buttons (_("Rename note"), (Gtk.Window)get_toplevel (),
				Gtk.DialogFlags.MODAL|Gtk.DialogFlags.DESTROY_WITH_PARENT,
				"gtk-cancel", Gtk.ResponseType.CANCEL, "gtk-ok", Gtk.ResponseType.OK);
			Gtk.Box content_area = (Gtk.Box)dialog.get_content_area ();
			dialog.set_default_response (Gtk.ResponseType.OK);
			dialog.resizable = false;
			dialog.icon_name = "gtk-edit";
			dialog.border_width = 4;
			content_area.border_width = 6;

			var entry = new Gtk.Entry ();
			entry.text = note.name;
			entry.activates_default = true;
			content_area.add (entry);
			content_area.show_all ();

			int res = dialog.run ();
			dialog_hide (dialog);
			if (res == Gtk.ResponseType.OK && entry.text != note.name) {
				string name = entry.text;
				if (note_name_exists (name)) {
					var error_dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
						Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, _("The name %s is already in use"), name);
					error_dialog.icon_name = "gtk-dialog-error";
					error_dialog.title = _("Error");
					error_dialog.run ();
					dialog_destroy (error_dialog);
				}
				else {
					this.note_renamed (note, name);
				}
			}
			dialog.destroy ();
		}

		/**
		 * note_name_exists:
		 *
		 * Verify if the given name already exists in the notebook.
		 */
		private bool note_name_exists (string name) {
			int n_pages = this.n_pages;
			for (int p = 0; p < n_pages; p++) {
				if (get_note (p).name == name) {
					return true;
				}
			}
			return false;
		}

		/**
		 * save_notes:
		 *
		 * Save notes.
		 */
		public void save_notes () {
			int n_pages = this.n_pages;
			for (int p = 0; p < n_pages; p++) {
				get_note (p).save ();
			}
		}

		private void save_current_note () {
			var note = this.current_note;
			if (note != null)
				note.save ();
		}

		/**
		 * _notebook_update_tabs_angle:
		 *
		 * Set the angle of each label in the tab.
		 */
		private void _notebook_update_tabs_angle () {
			int angle = 0;
			if (_tabs_position == 2)
				angle = 270;
			else if (_tabs_position == 4)
				angle = 90;

			int n_pages = this.n_pages;
			for (int i = 0; i < n_pages; i++) {
				var tab_evbox = get_tab_evbox (get_note (i));
				if (tab_evbox == null)
					continue;
				var label = tab_evbox.get_child () as Gtk.Label;
				if (label != null)
					label.angle = angle;
			}
		}

/* valac -X '-I..' -X '-DGETTEXT_PACKAGE="xfce4-notes-plugin"' -X '-DPKGDATADIR="../data"' -D DEBUG_XNP_WINDOW --pkg=gtk+-3.0 --pkg=libxfce4util-1.0 --pkg=libxfconf-0 --pkg=color --pkg=config --vapidir=.. --vapidir=. window.vala note.vala hypertextview.vala icon-button.vala */
#if DEBUG_XNP_WINDOW
		static int main (string[] args) {
			Gtk.init (ref args);
			var sample = new Xnp.Window ();
			sample.show ();
			Gtk.main ();
			return 0;
		}
#endif
	}

}
