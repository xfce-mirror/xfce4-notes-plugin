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
using Xfconf;

namespace Xnp {

	public class Application : GLib.Object {

		private SList<Xnp.WindowMonitor> window_monitor_list;
		private SList<Xnp.Window> window_list;
		public string notes_path { get; set construct; }
		public string config_file { get; construct; }
		private Xfconf.Channel xfconf_channel;

		construct {
			try {
				Xfce.posix_signal_handler_init ();
				Xfce.posix_signal_handler_set_handler(ProcessSignal.TERM, quit);
				Xfce.posix_signal_handler_set_handler(ProcessSignal.INT, quit);
			}
			catch (GLib.Error e) {
				critical ("Unable to connect to UNIX signals. %s", e.message);
			}

			try {
				Xfconf.init ();
			}
			catch (GLib.Error e) {
				critical ("%s", e.message);
			}

			xfconf_channel = new Xfconf.Channel.with_property_base ("xfce4-panel", "/plugins/notes");

			update_color ();
			xfconf_channel.property_changed["/global/background-color"].connect (() => {
				update_color ();
			});
			Gtk.Settings.get_default ().notify["gtk-theme-name"].connect (() => {
				update_color ();
			});

			if (notes_path == null) {
				var default_path = "%s/notes".printf (GLib.Environment.get_user_data_dir ());
				notes_path = xfconf_channel.get_string ("/global/notes-path", default_path);
			}
			xfconf_channel.property_changed["/global/notes-path"].connect (() => {
				update_notes_path ();
			});

			string name;
			bool found = false;
			try {
				/* Load existing windows */
				var dir = Dir.open (notes_path, 0);
				while ((name = dir.read_name ()) != null) {
					create_window (name);
					found = true;
				}
			}
			catch (GLib.Error e) {
				GLib.DirUtils.create_with_parents (notes_path, 0700);
			}
			if (found == false) {
				/* Create first-run window */
				create_window ();
			}
		}

		public Application (string config_file) {
			GLib.Object (config_file: config_file);
		}

		public Application.with_notes_path (string config_file, string notes_path) {
			GLib.Object (config_file: config_file, notes_path: notes_path);
		}

		~Application () {
			save_windows_configuration ();
			xfconf_channel = null;
			Xfconf.shutdown ();
			foreach (var win in this.window_list) {
				win.destroy ();
				win = null;
			}
		}

		private void update_notes_path () {
			var new_notes_path = xfconf_channel.get_string ("/global/notes-path", notes_path);
			if (notes_path == new_notes_path) {
				return;
			}

			/* Check that the new path is empty */
			try {
				var dir = Dir.open (new_notes_path, 0);
				if (dir.read_name () != null) {
					var error_dialog = new Gtk.MessageDialog (null, 0, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE,
						_("Select notes path"));
					error_dialog.format_secondary_text (_("The selected directory (%s) for the new notes path already contains files. You must select or create an empty directory."), new_notes_path);
					error_dialog.run ();
					error_dialog.destroy ();
					xfconf_channel.set_string ("/global/notes-path", notes_path);
					return;
				}
			}
			catch (GLib.Error e) {
			}

			/* Create/move to the new path */
			var dirname = Path.get_dirname (new_notes_path);
			if (GLib.DirUtils.create_with_parents (dirname, 0700) != 0 || GLib.FileUtils.rename (notes_path, new_notes_path) != 0) {
				var error_dialog = new Gtk.MessageDialog (null, 0, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE,
					_("Select notes path"));
				error_dialog.format_secondary_text (_("Unable to select directory for new notes path: %s"), strerror (errno));
				error_dialog.run ();
				error_dialog.destroy ();
				xfconf_channel.set_string ("/global/notes-path", notes_path);
				return;
			}
		}

		private void update_color () {
			string color = xfconf_channel.get_string ("/global/background-color", "#F7EB96");
			if (color == "GTK+") {
				// TODO: Read from StyleContext with default CssProvider
				return;
			}
			Xnp.Theme.set_background_color (color);
		}

		private void quit () {
			// Save notes before leaving the main loop since it works with GObject signals
			save_notes ();
			Gtk.main_quit ();
		}

		/*
		 * Window management
		 */

		/**
		 * create_window:
		 *
		 * Creates a new Xnp.Window and stores it inside window_list.
		 * If a name is given, it assumes it can load existing notes.
		 */
		public Xnp.Window create_window (string? name = null) {
			var window = new Xnp.Window ();

			/* Default settings */
			if (name == null) {
				window.above = xfconf_channel.get_bool ("/new-window/always-on-top", false);
				window.sticky = xfconf_channel.get_bool ("/new-window/sticky", true);
				int width = xfconf_channel.get_int ("/new-window/width", 0);
				int height = xfconf_channel.get_int ("/new-window/height", 0);
				if (width > 0 && height > 0) {
					window.resize (width, height);
				}
			}

			/* Set window name */
			if (name == null) {
				string window_name = _("Notes");
				int len = (int)this.window_list.length ();
				for (int id = 1; id <= len + 1; id++) {
					if (id > 1) {
						window_name = _("Notes %d").printf (id);
					}
					if (!window_name_exists (window_name)) {
						break;
					}
				}
				window.name = window_name;
			}
			else {
				window.name = name;
			}

			/* Add to window_list */
			this.window_list.insert_sorted (window, (GLib.CompareFunc)window.compare_func);
			foreach (var win in this.window_list) {
				win.set_window_list (this.window_list);
			}

			/* Insert initial notes */
			string window_path = "%s/%s".printf (notes_path, window.name);
			if (name == null || !GLib.FileUtils.test (window_path, GLib.FileTest.IS_DIR|GLib.FileTest.EXISTS)) {
				try {
					GLib.DirUtils.create_with_parents (window_path, 0700);
					string note_path = "%s/%s".printf (window_path, _("Notes"));
					GLib.FileUtils.set_contents (note_path, "", -1);
					this.load_window_data (window);
				}
				catch (FileError e) {
					critical ("Unable to initialize a notes group: %s", e.message);
				}
			}
			else {
				this.load_window_data (window);
			}

			/* Window monitor */
			window_monitor_list_add (window);

			/* Global settings */
			Xfconf.property_bind (xfconf_channel, "/global/skip-taskbar-hint",
				typeof (bool), window, "skip-taskbar-hint");
			Xfconf.property_bind (xfconf_channel, "/global/tabs-position",
				typeof (int), window, "tabs-position");

			/* Connect signals */
			window.action.connect ((win, action) => {
				if (action == "rename") {
					rename_window (win);
					set_data_value (win, "internal-change", true);
				}
				else if (action == "delete") {
					delete_window (win);
					set_data_value (win, "internal-change", true);
				}
				else if (action == "create-new-window") {
					var new_win = create_window ();
					new_win.show ();
					set_data_value (win, "internal-change", true);
				}
				else if (action == "refresh-notes") {
					refresh_notes (win);
				}
				else if (action == "properties") {
					open_settings_dialog ();
				}
				else if (action == "about") {
					open_about_dialog ();
				}
			});
			window.save_data.connect ((win, note) => {
				if (!get_data_value (win, "external-change")) {
					set_data_value (win, "internal-change", true);
					save_note (win, note);
				}
			});
			window.note_inserted.connect ((win, note) => {
				Xfconf.property_bind (xfconf_channel, "/global/font-description",
					typeof (string), note.text_view, "font");

				string path = "%s/%s/%s".printf (notes_path, win.name, note.name);
				try {
					GLib.FileUtils.set_contents (path, "", -1);
					set_data_value (win, "internal-change", true);
				}
				catch (FileError e) {
				}
			});
			window.note_deleted.connect ((win, note) => {
				string path = "%s/%s/%s".printf (notes_path, win.name, note.name);
				GLib.FileUtils.unlink (path);
				set_data_value (win, "internal-change", true);
			});
			window.note_renamed.connect ((win, note, old_name) => {
				if (!name_is_valid (note.name)) {
					note.name = old_name;
					return;
				}
				string old_path = "%s/%s/%s".printf (notes_path, win.name, old_name);
				string new_path = "%s/%s/%s".printf (notes_path, win.name, note.name);
				GLib.FileUtils.rename (old_path, new_path);
				set_data_value (win, "internal-change", true);
			});

			return window;
		}

		/**
		 * load_window_data:
		 *
		 * Load existing notes and configuration inside the window.
		 */
		private void load_window_data (Xnp.Window window) {
			/* Load notes */
			string name;
			string path = "%s/%s".printf (notes_path, window.name);
			try {
				var dir = GLib.Dir.open (path, 0);
				while ((name = dir.read_name ()) != null) {
					try {
						string contents;
						var file = File.new_for_path ("%s/%s".printf (path, name));
						GLib.FileUtils.get_contents (file.get_path (), out contents, null);
						var note = window.insert_note ();
						note.name = name;
						var buffer = note.text_view.get_buffer ();
						buffer.set_text (contents, -1);
						Xfconf.property_bind (xfconf_channel, "/global/font-description",
								typeof (string), note.text_view, "font");
					}
					catch (FileError e) {
						warning ("%s", e.message);
					}
				}
			}
			catch (FileError e) {
			}

			/* Load window configuration */
			var keyfile = new GLib.KeyFile ();
			try {
				keyfile.load_from_file (config_file, GLib.KeyFileFlags.NONE);
				int winx = keyfile.get_integer (window.name, "PosX");
				int winy = keyfile.get_integer (window.name, "PosY");
				int width = keyfile.get_integer (window.name, "Width");
				int height = keyfile.get_integer (window.name, "Height");
				string[] tabs_order = keyfile.get_string_list (window.name, "TabsOrder");
				int last_page = keyfile.get_integer (window.name, "LastTab");
				bool above = keyfile.get_boolean (window.name, "Above");
				bool sticky = keyfile.get_boolean (window.name, "Sticky");
				double opacity = 1 - (double)keyfile.get_integer (window.name, "Transparency") / 100;
				bool visible = keyfile.get_boolean (window.name, "Visible");

				window.move (winx, winy);
				window.resize (width, height);
				for (int i = 0; i < tabs_order.length; i++)
					window.move_note (tabs_order[i], i);
				window.set_current_page (last_page);
				window.above = above;
				window.sticky = sticky;
				window.opacity = opacity;
				if (visible)
					window.show ();
			}
			catch (GLib.Error e) {
				window.show ();
			}
		}

		/**
		 * save_windows_configuration:
		 *
		 * Save window configuration inside rc file.
		 */
		public void save_windows_configuration () {
			var keyfile = new GLib.KeyFile ();
			try {
				foreach (var win in this.window_list) {
					int winx, winy, width, height;
					win.get_geometry (out winx, out winy, out width, out height);
					string[] tabs_order = win.get_note_names ();
					int last_page = win.get_current_page ();
					int transparency = (int)((1 - win.opacity) * 100);
					bool visible = win.get_visible ();

					keyfile.set_integer (win.name, "PosX", winx);
					keyfile.set_integer (win.name, "PosY", winy);
					keyfile.set_integer (win.name, "Width", width);
					keyfile.set_integer (win.name, "Height", height);
					keyfile.set_string_list (win.name, "TabsOrder", tabs_order);
					keyfile.set_integer (win.name, "LastTab", last_page);
					keyfile.set_boolean (win.name, "Above", win.above);
					keyfile.set_boolean (win.name, "Sticky", win.sticky);
					keyfile.set_double (win.name, "Transparency", transparency);
					keyfile.set_boolean (win.name, "Visible", visible);
				}
				string contents = keyfile.to_data (null);
				GLib.FileUtils.set_contents (config_file, contents);
			}
			catch (FileError e) {
				message ("Unable to save window configuration from %s: %s", config_file, e.message);
			}
		}

		/**
		 * save_notes:
		 *
		 * Save the contents of every existing notes.
		 */
		public void save_notes () {
			foreach (var win in this.window_list) {
				set_data_value (win, "external-change", false);
				win.save_notes ();
			}
		}

		/**
		 * save_note:
		 *
		 * Save the contents of the given note.
		 */
		private void save_note (Xnp.Window window, Xnp.Note note) {
			string path = "%s/%s/%s".printf (notes_path, window.name, note.name);
			try {
				Gtk.TextIter start, end;
				var buffer = note.text_view.get_buffer ();
				buffer.get_bounds (out start, out end);
				string contents = buffer.get_text (start, end, true);
				GLib.FileUtils.set_contents (path, contents, -1);
			}
			catch (FileError e) {
				warning ("%s", e.message);
			}
		}

		/**
		 * rename_window:
		 *
		 * Renames the window name.
		 */
		private void rename_window (Xnp.Window window) {
			var dialog = new Gtk.Dialog.with_buttons (_("Rename group"), window,
					Gtk.DialogFlags.DESTROY_WITH_PARENT,
					"_Cancel", Gtk.ResponseType.CANCEL, "_OK", Gtk.ResponseType.OK);
			Gtk.Box content_area = (Gtk.Box)dialog.get_content_area ();
			dialog.set_default_response (Gtk.ResponseType.OK);
			dialog.resizable = false;
			dialog.icon_name = "gtk-edit";
			dialog.border_width = 4;

			var entry = new Gtk.Entry ();
			entry.text = window.name;
			entry.activates_default = true;
			content_area.add (entry);
			content_area.show_all ();

			int res = dialog.run ();
			dialog.hide ();
			if (res == Gtk.ResponseType.OK) {
				weak string name = entry.text;
				if (window_name_exists (name)) {
					var error_dialog = new Gtk.MessageDialog (window, Gtk.DialogFlags.DESTROY_WITH_PARENT,
						Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, _("The name %s is already in use"), name);
					error_dialog.run ();
					error_dialog.destroy ();
				}
				else {
					if (!name_is_valid (name)) {
						return;
					}
					string old_path = "%s/%s".printf (notes_path, window.name);
					string new_path = "%s/%s".printf (notes_path, name);
					window.name = name;
					GLib.FileUtils.rename (old_path, new_path);
					this.window_list.sort ((GLib.CompareFunc)window.compare_func);

					window_monitor_list_remove (window);
					window_monitor_list_add (window);
				}
			}
			dialog.destroy ();
		}

		/**
		 * delete_window:
		 *
		 * Delete the window.
		 */
		private void delete_window (Xnp.Window window) {
			if (window.n_pages >= 1) {
				var dialog = new Gtk.MessageDialog (window, Gtk.DialogFlags.DESTROY_WITH_PARENT,
						Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, _("Are you sure you want to delete this group?"));
				int res = dialog.run ();
				dialog.destroy ();
				if (res != Gtk.ResponseType.YES)
					return;
			}

			string name;
			string path = "%s/%s".printf (notes_path, window.name);
			try {
				var dir = GLib.Dir.open (path, 0);
				while ((name = dir.read_name ()) != null) {
					string filename = "%s/%s".printf (path, name);
					GLib.FileUtils.unlink (filename);
				}
				GLib.DirUtils.remove (path);
			}
			catch (FileError e) {
			}

			window_monitor_list_remove (window);

			this.window_list.remove (window);
			window.destroy ();

			if (this.window_list.length () >= 1) {
				foreach (var win in this.window_list) {
					win.set_window_list (this.window_list);
				}
			}
			else {
				var new_win = create_window ();
				new_win.show ();
			}
		}

		/**
		 * refresh_notes:
		 *
		 * Prompt for reloading notes from disk.
		 */
		private void refresh_notes (Xnp.Window window) {
			var dialog = new Gtk.MessageDialog (window, Gtk.DialogFlags.DESTROY_WITH_PARENT,
				Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO,
				_("The group \"%s\" has been modified on the disk"), window.name);
			dialog.set_title (window.name);
			dialog.set_icon_name ("xfce4-notes-plugin");
			dialog.format_secondary_text (_("Do you want to reload the group?"));
			var res = dialog.run ();
			dialog.destroy ();

			if (res == Gtk.ResponseType.YES) {
				// Delete existing window object
				var name = window.name;
				window_monitor_list_remove (window);
				this.window_list.remove (window);
				window.destroy ();
				// Create new window object
				var win = create_window (name);
				win.show ();
			}
			else {
				set_data_value (window, "external-change", false);
				window.show_refresh_button = false;
				window.save_notes ();

			}
		}

		/*
		 * Window monitor list management
		 */

		/**
		 * window_monitor_list_add:
		 *
		 * Creates an Xnp.WindowMonitor object and stores it inside window_monitor_list.
		 */
		private void window_monitor_list_add (Xnp.Window window) {
			var file = File.new_for_path ("%s/%s".printf (notes_path, window.name));
			var monitor = new Xnp.WindowMonitor (window, file);

			monitor.window_updated.connect ((window) => {
				if (get_data_value (window, "internal-change")) {
					set_data_value (window, "internal-change", false);
				}
				else {
					set_data_value (window, "external-change", true);
					window.show_refresh_button = true;
				}
			});

			this.window_monitor_list.prepend (monitor);
		}

		/**
		 * window_monitor_list_remove:
		 *
		 * Removes a monitor from window_monitor_list matching @window.
		 */
		private void window_monitor_list_remove (Xnp.Window window) {
			var monitor = window_monitor_list_lookup (window);
			if (monitor != null) {
				this.window_monitor_list.remove (monitor);
				monitor.unref ();
				monitor = null;
			}
		}

		/**
		 * window_monitor_list_lookup:
		 *
		 * Returns the window_monitor object that contains @window from the window_monitor_list.
		 */
		private Xnp.WindowMonitor window_monitor_list_lookup (Xnp.Window window) {
			Xnp.WindowMonitor window_monitor = null;
			foreach (var monitor in this.window_monitor_list) {
				if (monitor.window == window) {
					window_monitor = monitor;
					break;
				}
			}
			return window_monitor;
		}

		/*
		 * Utility functions
		 */

		/**
		 * get_data_value:
		 *
		 * Convenience function to return a GObject data boolean value.
		 */
		private bool get_data_value (GLib.Object object, string data) {
			return object.get_data<bool> (data);
		}

		/**
		 * set_data_value:
		 *
		 * Convenience function to set a GObject data boolean value.
		 */
		private void set_data_value (GLib.Object object, string data, bool val) {
			object.set_data (data, ((int)val).to_pointer ());
		}

		/**
		 * window_name_exists:
		 *
		 * Verify if the given name already exists in the window list.
		 */
		private bool window_name_exists (string name) {
			foreach (var win in this.window_list) {
				if (win.name == name) {
					return true;
				}
			}
			return false;
		}

		/**
		 * name_is_valid:
		 *
		 * Verify if the given name is valid for window and notes.
		 */
		private bool name_is_valid (string name) {
			bool res = GLib.Regex.match_simple ("^[^*|/\\:\"<>?]+$", name);
			if (!res) {
				var error_dialog = new Gtk.MessageDialog (null, 0,
					Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, _("The name \"%s\" is invalid."), name);
				error_dialog.format_secondary_markup (_("The invalid characters are: %s").printf ("<tt>*|/\\:\"&lt;&gt;?</tt>"));
				error_dialog.run ();
				error_dialog.destroy ();
			}
			return res;
		}

		/**
		 * show_hide_notes:
		 *
		 * Show all the notes or hide them if they are all shown.
		 */
		public void show_hide_notes () {
			bool invisible_found = false;
			bool visible_found = false;
			bool active_found = false;
			foreach (var win in this.window_list) {
				if (win.is_active) {
					active_found = true;
				}
				if (!win.get_visible ()) {
					invisible_found = true;
				}
				else {
					visible_found = true;
				}
			}

			foreach (var win in this.window_list) {
				// Present visible windows
				if (!active_found && visible_found) {
					if (win.get_visible ()) {
						win.present ();
					}
				}
				// Show all windows
				else if (invisible_found) {
					win.show ();
				}
				// Hide all windows
				else {
					win.hide ();
				}
			}
		}

		/**
		 * open_settings_dialog:
		 *
		 * Open the settings dialog.
		 */
		public void open_settings_dialog () {
			try {
				GLib.Process.spawn_command_line_async ("xfce4-notes-settings");
			}
			catch (GLib.Error e) {
				var error_dialog = new Gtk.MessageDialog (null, Gtk.DialogFlags.DESTROY_WITH_PARENT,
						Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, _("Unable to open the settings dialog"));
				error_dialog.format_secondary_text ("%s", e.message);
				error_dialog.run ();
				error_dialog.destroy ();
			}
		}

		/**
		 * open_about_dialog:
		 *
		 * Open the about dialog.
		 */
		public void open_about_dialog () {
			string[] authors = {
					"(c) 2006-2010 Mike Massonnet",
					"(c) 2003 Jakob Henriksson",
					null
				};

			Gtk.show_about_dialog (null,
				"program-name", _("Notes"),
				"logo-icon-name", "xfce4-notes-plugin",
				"comments", _("Ideal for your quick notes"),
				"version", Config.PACKAGE_VERSION,
				"copyright", "Copyright © 2003-2020 The Xfce development team",
				"license", Xfce.get_license_text (Xfce.LicenseTextType.GPL),
				"website", "https://docs.xfce.org/panel-plugins/xfce4-notes-plugin",
				"website-label", "docs.xfce.org",
				"authors", authors,
				"translator-credits", _("translator-credits"),
				null);
		}

		/**
		 * context_menu:
		 *
		 * Provides a GtkMenu to be used for right click context menus
		 * like in trayicons. Its items are destroyed/refreshed every
		 * time the menu is shown.
		 */
		public Gtk.Menu context_menu () {
			var menu = new Gtk.Menu ();

			menu.show.connect (() => {
				// Clean up menu
				menu.@foreach ((w) => {
					w.destroy ();
				});

				// Add fresh items
				foreach (var win in this.window_list) {
					var mi = new Gtk.MenuItem.with_label (win.name);
					mi.set_data ("window", (void*)win);
					mi.activate.connect ((i) => {
						// Jump to win
						var w = i.get_data<Xnp.Window> ("window");
						w.present ();
					});
					menu.append (mi);
				}

				// New group menu item
				var mi_sep = new Gtk.SeparatorMenuItem ();
				menu.append (mi_sep);
				var mi_add = new Gtk.MenuItem.with_mnemonic (_("_Add a new group"));
				mi_add.activate.connect (() => {
					var new_win = create_window ();
					new_win.show ();
				});
				menu.append (mi_add);

				// Show all items
				menu.show_all ();
			});

			return menu;
		}

	}

}

/*static int main (string[] args) {
	Gtk.init (ref args);
	var app = new Xnp.Application ("/tmp/notes-conf.rc");
	Gtk.main ();
	app.unref ();
	return 0;
}*/

