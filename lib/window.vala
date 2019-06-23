/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (c) 2009-2010  Mike Massonnet <mmassonnet@xfce.org>
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
		private Gtk.Image menu_image;
		private Gdk.Pixbuf menu_pixbuf;
		private Gdk.Pixbuf menu_hover_pixbuf;
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
		private Gdk.Cursor CURSOR_RIGHT = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.RIGHT_SIDE);
		private Gdk.Cursor CURSOR_LEFT = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.LEFT_SIDE);
		private Gdk.Cursor CURSOR_BOTTOM_RC = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.BOTTOM_RIGHT_CORNER);
		private Gdk.Cursor CURSOR_BOTTOM = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.BOTTOM_SIDE);
		private Gdk.Cursor CURSOR_BOTTOM_LC = new Gdk.Cursor.for_display (Gdk.Display.get_default(), Gdk.CursorType.BOTTOM_LEFT_CORNER);

		private unowned SList<Xnp.Window> window_list;

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
		public signal void note_renamed (Xnp.Note note, string old_name);

		construct {
			((Gtk.Widget)this).name = "notes-window";
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
			var vbox_frame = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

			vbox_frame.spacing = 1;
			vbox_frame.show ();
			frame.add (vbox_frame);

			/* Build title bar */
			var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
			var menu_evbox = new Gtk.EventBox ();
			menu_evbox.tooltip_text = _("Menu");
			menu_evbox.set_visible_window (false);
			try {
				this.menu_pixbuf = new Gdk.Pixbuf.from_file ("%s/pixmaps/notes-menu.png".printf (Config.PKGDATADIR));
				this.menu_hover_pixbuf = new Gdk.Pixbuf.from_file ("%s/pixmaps/notes-menu-active.png".printf (Config.PKGDATADIR));
			}
			catch (Error e) {
				this.menu_pixbuf = this.menu_hover_pixbuf = null;
			}
			this.menu_image = new Gtk.Image.from_pixbuf (this.menu_pixbuf);
			menu_evbox.add (this.menu_image);
			menu_evbox.enter_notify_event.connect (() => {
				this.menu_image.set_from_pixbuf (this.menu_hover_pixbuf);
				return false;
			});
			menu_evbox.leave_notify_event.connect (() => {
				this.menu_image.set_from_pixbuf (this.menu_pixbuf);
				return false;
			});
			title_box.pack_start (menu_evbox, false, false, 2);
			var title_evbox = new Gtk.EventBox ();
			title_evbox.set_visible_window (false);
			this.title_label = new Gtk.Label (null);
			this.title_label.set_markup ("<b>"+this.title+"</b>");
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
			this.left_arrow_button.tooltip_text = Gtk.accelerator_get_label (0xff55, Gdk.ModifierType.CONTROL_MASK); // GDK_Page_Up
			this.left_arrow_button.sensitive = false;
			title_box.pack_start (this.left_arrow_button, false, false, 2);
			this.right_arrow_button = new Xnp.TitleBarButton (Xnp.TitleBarButtonType.RIGHT_ARROW);
			this.right_arrow_button.tooltip_text = Gtk.accelerator_get_label (0xff56, Gdk.ModifierType.CONTROL_MASK); // GDK_Page_Down
			this.right_arrow_button.sensitive = false;
			title_box.pack_start (this.right_arrow_button, false, false, 2);
			this.close_button = new Xnp.TitleBarButton (Xnp.TitleBarButtonType.CLOSE);
			this.close_button.tooltip_text = _("Hide (%s)").printf (Gtk.accelerator_get_label (0xff1b, 0)); // GDK_Escape
			title_box.pack_start (this.close_button, false, false, 2);
			title_box.show_all ();
			vbox_frame.pack_start (title_box, false, false, 0);

			/* Build content box */
			this.content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			this.content_box.show ();
			vbox_frame.pack_start (this.content_box, true, true, 0);

			/* Build Notebook */
			this.notebook = new Gtk.Notebook ();
			this.notebook.name = "notes-notebook";
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
			focus_in_event.connect (() => {
				menu_image.sensitive = true;
				title_label.sensitive = true;
				refresh_button.sensitive = true;
				update_navigation_sensitivity (this.notebook.get_current_page ());
				close_button.sensitive = true;
				return false;
			});
			focus_out_event.connect (() => {
				menu_image.sensitive = false;
				title_label.sensitive = false;
				refresh_button.sensitive = false;
				left_arrow_button.sensitive = false;
				right_arrow_button.sensitive = false;
				close_button.sensitive = false;
				return false;
			});
			leave_notify_event.connect (window_leaved_cb);
			motion_notify_event.connect (window_motion_cb);
			button_press_event.connect (window_pressed_cb);
			window_state_event.connect (window_state_cb);
			title_evbox.button_press_event.connect (title_evbox_pressed_cb);
			title_evbox.scroll_event.connect (title_evbox_scrolled_cb);
			this.notebook.page_added.connect ((n, c, p) => {
				notebook.set_current_page ((int)p);
				update_navigation_sensitivity ((int)p);
			});
			this.notebook.page_removed.connect ((n, c, p) => {
				update_navigation_sensitivity ((int)p);
			});
			this.notebook.switch_page.connect ((n, c, p) => {
				var note = (Xnp.Note)(notebook.get_nth_page ((int)p));
				update_title (note.name);
				update_navigation_sensitivity ((int)p);
			});
			notify["name"].connect (() => {
				int page = this.notebook.get_current_page ();
				if (page == -1)
					return;
				var current_note = (Xnp.Note)(this.notebook.get_nth_page (page));
				update_title (current_note.name);
			});
			notify["title"].connect (() => {
				title_label.set_markup ("<b>"+title+"</b>");
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
			get_position (out winx, out winy);
			base.hide ();
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
		private bool window_leaved_cb () {
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

			get_allocation (out allocation);

			if (event.x > 4 && event.y > 4
				&& event.x < allocation.width - 4
				&& event.y < allocation.height - 4) {
				get_window ().set_cursor (null);
				return false;
			}

			// Right
			if (event.x >= allocation.width - this.CORNER_MARGIN
				&& event.y >= this.CORNER_MARGIN
				&& event.y < allocation.height - this.CORNER_MARGIN)
				get_window ().set_cursor (this.CURSOR_RIGHT);
			// Bottom right corner
			else if (event.x >= allocation.width - this.CORNER_MARGIN
				&& event.y >= allocation.height - this.CORNER_MARGIN)
				get_window ().set_cursor (this.CURSOR_BOTTOM_RC);
			// Bottom
			else if (event.x > this.CORNER_MARGIN
				&& event.y > allocation.height - this.CORNER_MARGIN
				&& event.x < allocation.width - this.CORNER_MARGIN)
				get_window ().set_cursor (this.CURSOR_BOTTOM);
			// Bottom left corner
			else if (event.x <= this.CORNER_MARGIN
				&& event.y >= allocation.height - this.CORNER_MARGIN)
				get_window ().set_cursor (this.CURSOR_BOTTOM_LC);
			// Left
			else if (event.x <= this.CORNER_MARGIN && event.y >= this.CORNER_MARGIN
				&& event.y < allocation.height - this.CORNER_MARGIN)
				get_window ().set_cursor (this.CURSOR_LEFT);
			// Default
			else
				get_window ().set_cursor (null);

			return true;
		}

		/**
		 * window_pressed_cb:
		 *
		 * Start a window resize depending on mouse pointer location.
		 */
		private bool window_pressed_cb (Gdk.EventButton event) {
			Gdk.WindowEdge edge;
			Gtk.Allocation allocation;

			get_allocation (out allocation);

			if (event.x > 4 && event.y > 4
				&& event.x < allocation.width - 4
				&& event.y < allocation.height - 4)
				return false;

			// Right
			if (event.y > this.CORNER_MARGIN
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
			if (event.button == 1) {
				get_window ().show ();
				int winx, winy, curx, cury;
				get_position (out winx, out winy);
				get_pointer (out curx, out cury);
				winx += curx;
				winy += cury;
				begin_move_drag (1, winx, winy, Gtk.get_current_event_time ());
			}
			else if (event.button == 2) {
				get_window ().lower ();
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
		 * note_notify_name_cb:
		 *
		 */
		private void note_notify_name_cb (GLib.Object object, GLib.ParamSpec pspec) {
			Xnp.Note note = object as Xnp.Note;
			this.notebook.set_tab_label_text (note, note.name);
			_notebook_update_tabs_angle ();
			int page = this.notebook.get_current_page ();
			var current_note = (Xnp.Note)(this.notebook.get_nth_page (page));
			if (note == current_note)
				this.update_title (note.name);
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
			mi = new Gtk.SeparatorMenuItem ();
			menu.append (mi);

			mi = new Gtk.MenuItem.with_mnemonic (_("_New"));
			mi.set_accel_path (this.action_group.get_action ("new-note").get_accel_path ());
			mi.activate.connect (action_new_note);
			menu.append (mi);

			mi = new Gtk.MenuItem.with_mnemonic (_("_Delete"));
			mi.set_accel_path (this.action_group.get_action ("delete-note").get_accel_path ());
			mi.activate.connect (action_delete_note);
			menu.append (mi);

			mi = new Gtk.MenuItem.with_mnemonic (_("_Rename"));
            //var image = new Gtk.Image.from_stock (Gtk.Stock.EDIT, Gtk.IconSize.MENU);
			//((Gtk.ImageMenuItem)mi).set_image (image);
			mi.set_accel_path (this.action_group.get_action ("rename-note").get_accel_path ());
			mi.activate.connect (action_rename_note);
			menu.append (mi);

			mi = new Gtk.MenuItem.with_mnemonic (_("_Undo"));
			mi.set_accel_path (this.action_group.get_action ("cancel").get_accel_path ());
			mi.activate.connect (action_cancel);
			menu.append (mi);

			/* Window options */
			mi = new Gtk.SeparatorMenuItem ();
			menu.append (mi);

			mi = this.mi_above = new Gtk.CheckMenuItem.with_label (_("Always on top"));
			((Gtk.CheckMenuItem)mi).active = this.above;
			((Gtk.CheckMenuItem)mi).toggled.connect ((o) => { above = o.active; });
			menu.append (mi);

			mi = this.mi_sticky = new Gtk.CheckMenuItem.with_label (_("Sticky window"));
			((Gtk.CheckMenuItem)mi).active = this.sticky;
			((Gtk.CheckMenuItem)mi).toggled.connect ((o) => { sticky = o.active; });
			menu.append (mi);

			/* Settings/About dialog */
			mi = new Gtk.SeparatorMenuItem ();
			menu.append (mi);

			mi = new Gtk.MenuItem.with_mnemonic ("_Properties");
			mi.activate.connect (() => { action ("properties"); });
			menu.append (mi);

			mi = new Gtk.MenuItem.with_mnemonic ("_About");
			mi.activate.connect (() => { action ("about"); });
			menu.append (mi);

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
						mi = new Gtk.MenuItem.with_label (note.name);
						//if (note == current_note) {
						//	image = new Gtk.Image.from_icon_name ("go-next", Gtk.IconSize.MENU);
						//	((Gtk.ImageMenuItem)mi).set_image (image);
						//}
						mi.set_data ("page", p.to_pointer ());
						mi.activate.connect ((i) => {
							int page = i.get_data<int> ("page");
							notebook.set_current_page (page);
						});
						menu.append (mi);
					}

					mi = new Gtk.SeparatorMenuItem ();
					menu.append (mi);
				}
				else {
					mi = new Gtk.MenuItem.with_label (win.name);
					mi.set_data ("window", (void*)win);
					mi.activate.connect ((i) => {
						var w = i.get_data<Xnp.Window> ("window");
						w.present ();
					});
					menu.append (mi);

					mi = new Gtk.SeparatorMenuItem ();
					menu.append (mi);
				}
			}

			mi = new Gtk.MenuItem.with_mnemonic (_("_Rename group"));
			//image = new Gtk.Image.from_icon_name ("gtk-edit", Gtk.IconSize.MENU);
			//((Gtk.ImageMenuItem)mi).set_image (image);
			mi.set_accel_path (this.action_group.get_action ("rename-window").get_accel_path ());
			mi.activate.connect (action_rename_window);
			menu.append (mi);

			mi = new Gtk.MenuItem.with_mnemonic (_("_Delete group"));
			//image = new Gtk.Image.from_icon_name ("list-remove", Gtk.IconSize.MENU);
			//((Gtk.ImageMenuItem)mi).set_image (image);
			mi.set_accel_path (this.action_group.get_action ("delete-window").get_accel_path ());
			mi.activate.connect (action_delete_window);
			menu.append (mi);

			mi = new Gtk.MenuItem.with_mnemonic (_("_Add a new group"));
			//image = new Gtk.Image.from_icon_name ("list-add", Gtk.IconSize.MENU);
			//((Gtk.ImageMenuItem)mi).set_image (image);
			mi.set_accel_path (this.action_group.get_action ("new-window").get_accel_path ());
			mi.activate.connect (action_new_window);
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
		 * set_window_list:
		 *
		 * Saves a list of window inside window.window_list to be shown
		 * within the window menu.
		 */
		public void set_window_list (SList <Xnp.Window> list) {
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
			int n_pages = notebook.get_n_pages ();
			if (n_pages <= 1) {
				this.left_arrow_button.sensitive = false;
				this.right_arrow_button.sensitive = false;
			}
			else {
				this.left_arrow_button.sensitive = page_num > 0 ? true : false;
				this.right_arrow_button.sensitive = page_num + 1 < n_pages ? true : false;
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

			note.notify["name"].connect (note_notify_name_cb);
			note.save_data.connect ((note) => { save_data (note); });

			note.show ();
			this.n_pages++;
			this.notebook.insert_page (note, null, page);
			this.notebook.set_tab_reorderable (note, true);
			note.name = note.name; //note.notify ("name");
			this.note_inserted (note);
			_notebook_update_tabs_angle ();
			return note;
		}

		/**
		 * move_note:
		 *
		 * Moves the note named @note_name to position @page.
		 */
		public void move_note (string note_name, int page) {
			int n_pages = this.notebook.get_n_pages ();
			for (int p = 0; p < n_pages; p++) {
				var note = (Xnp.Note)this.notebook.get_nth_page (p);
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
			int n_pages = this.notebook.get_n_pages ();
			for (int p = 0; p < n_pages; p++) {
				var note = (Xnp.Note)this.notebook.get_nth_page (p);
				note_names += note.name;
			}
			return note_names;
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
				Gtk.DialogFlags.MODAL|Gtk.DialogFlags.DESTROY_WITH_PARENT,
				"_Cancel", Gtk.ResponseType.CANCEL, "_OK", Gtk.ResponseType.OK);
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
			dialog.hide ();
			if (res == Gtk.ResponseType.OK) {
				string name = entry.text;
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

			var dialog = new Gtk.FontChooserDialog ("Choose current note font", this);
			dialog.set_font (note.text_view.font);
			int res = dialog.run ();
			dialog.hide ();
			if (res == Gtk.ResponseType.OK) {
				note.text_view.font = dialog.get_font ();
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

			int pages = this.notebook.get_n_pages ();
			for (int i = 0; i < pages; i++) {
				var widget = this.notebook.get_nth_page (i);
				var label = this.notebook.get_tab_label (widget) as Gtk.Label;
				if (label is Gtk.Label) {
					label.angle = angle;
				}
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
