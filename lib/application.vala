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

		public string notes_path { get; set construct; }
		public string config_file { get; construct; }
		public bool system_tray_mode = false;

		private SList<Xnp.Window> window_list;
		private SList<Xnp.Window> focus_order;
		private Xfconf.Channel xfconf_channel;
		private bool lock_focus_order = false;
		private uint save_config_timeout = 0;
		private string default_notes_path;
		private Xnp.Theme theme;

		private bool main_instance {
			get {
				if (this.system_tray_mode) {
					return true;
				}

				Gtk.Application app = new Gtk.Application ("org.xfce.Notes", 0);
				app.activate.connect (() => {;});
				try {
					app.register ();
				} catch (GLib.Error e) {
				}

				if (app.is_remote) {
					return false;
				}

				app.run ();
				app.quit ();

				return true;
			}
		}

		private bool _skip_taskbar_hint = true;
		public bool skip_taskbar_hint {
			get {
				return this._skip_taskbar_hint;
			}
			set {
				if (this._skip_taskbar_hint == value)
					return;
				this._skip_taskbar_hint = value;
				foreach (var win in this.window_list)
					win.skip_taskbar_hint = value;
			}
		}

		public Xnp.Window? next_focus {
			get {
				if (this.lock_focus_order)
					return null;
				var win_count = this.focus_order.length ();
				if (win_count < 2)
					return null;
				var window = this.focus_order.nth_data (win_count - 2);
				return window.get_visible () ? window : null;
			}
		}

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
			update_version ();

			theme = new Xnp.Theme ();
			update_color ();
			xfconf_channel.property_changed["/global/background-color"].connect (() => {
				update_color ();
			});

			Xfconf.property_bind (xfconf_channel, "/global/skip-taskbar-hint",
				typeof (bool), this, "skip-taskbar-hint");

			default_notes_path = "%s/notes".printf (GLib.Environment.get_user_data_dir ());
			if (notes_path == null) {
				notes_path = xfconf_channel.get_string ("/global/notes-path", default_notes_path);
			}
			xfconf_channel.property_changed["/global/notes-path"].connect (() => {
				update_notes_path ();
			});

			string name;
			bool found = false;
			try {
				/* Load existing windows */
				SList<string> groups = null;
				var dir = Dir.open (notes_path, 0);
				while ((name = dir.read_name ()) != null) {
					groups.prepend (name);
					found = true;
				}
				sort_groups_by_focus_order (ref groups);
				foreach (var group_name in groups) {
					create_window (group_name);
				}
			}
			catch (GLib.Error e) {
				GLib.DirUtils.create_with_parents (notes_path, 0700);
			}
			if (found == false) {
				/* Create first-run window */
				create_window ();
			}

			Gtk.Window.set_default_icon_name ("org.xfce.notes");
		}

		public Application (string config_file) {
			GLib.Object (config_file: config_file);
		}

		public Application.with_notes_path (string config_file, string notes_path) {
			GLib.Object (config_file: config_file, notes_path: notes_path);
		}

		~Application () {
			xfconf_channel = null;
			Xfconf.shutdown ();
			if (this.save_config_timeout != 0) {
				Source.remove (this.save_config_timeout);
			}
			foreach (var win in this.window_list) {
				win.destroy ();
				win = null;
			}
		}

		private void update_version () {
			var version = xfconf_channel.get_string ("/global/version", "0");
			if (version == Config.PACKAGE_VERSION)
				return;
			if (version < "1.11") {
				try {
					var css = Xfce.resource_save_location (Xfce.ResourceType.CONFIG, "xfce4/xfce4-notes.css", false);
					var css_file = File.new_for_path (css);
					css_file.delete ();
					var old_save_location = Xfce.resource_save_location (Xfce.ResourceType.CONFIG, "xfce4/xfce4-notes.rc", false);
					var old_save_location_file = File.new_for_path (old_save_location);
					if (old_save_location_file.query_exists ()) {
						var save_location = Xfce.resource_save_location (Xfce.ResourceType.CONFIG, "xfce4/notes/xfce4-notes.rc", true);
						var save_location_file = File.new_for_path (save_location);
						old_save_location_file.move (save_location_file, FileCopyFlags.NONE);
					}
				} catch (GLib.Error e) {
				}
			}
			xfconf_channel.set_string ("/global/version", Config.PACKAGE_VERSION);
		}

		private void update_notes_path () {
			var new_notes_path = xfconf_channel.get_string ("/global/notes-path", this.default_notes_path);
			if (this.notes_path == new_notes_path) {
				return;
			}

			/*
			 * Handle the case when panel plugin and system tray
			 * application are running at the same time
			 */
			if (!this.main_instance) {
				this.notes_path = new_notes_path;
				return;
			}

			/* Check that the new path is empty */
			try {
				var dir = Dir.open (new_notes_path, 0);
				if (dir.read_name () != null) {
					notes_path_error (_("The selected directory (%s) for the new notes path already contains files. "
							    + "You must select or create an empty directory.").printf (new_notes_path));
					return;
				}
			}
			catch (GLib.Error e) {
			}

			/* Create/move to the new path */
			var dirname = Path.get_dirname (new_notes_path);
			if (GLib.DirUtils.create_with_parents (dirname, 0700) != 0
			    || GLib.FileUtils.rename (this.notes_path, new_notes_path) != 0) {
				notes_path_error (_("Unable to select directory for new notes path: %s").printf (strerror (errno)));
				return;
			}

			this.notes_path = new_notes_path;
		}

		private void notes_path_error (string message) {
			var error_dialog = new Gtk.MessageDialog (null, 0, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, _("Notes path is unacceptable"));
			error_dialog.format_secondary_text (message);
			error_dialog.icon_name = "gtk-dialog-error";
			error_dialog.title = _("Error");
			error_dialog.run ();
			error_dialog.destroy ();
			if (this.notes_path == this.default_notes_path) {
				xfconf_channel.reset_property ("/global/notes-path", false);
			} else {
				xfconf_channel.set_string ("/global/notes-path", this.notes_path);
			}
		}

		private void update_color () {
			string color = xfconf_channel.get_string ("/global/background-color", "#F7EB96");
			if (color == "GTK+")
				theme.use_gtk_style ();
			else
				theme.use_color (color);
		}

		/**
		 * sort_groups_by_focus_order:
		 *
		 * Sort groups by last memorized windows focus order.
		 */
		private void sort_groups_by_focus_order (ref SList<string> groups) {
			try {
				var last_focus_order = new SList<string> ();
				var keyfile = new GLib.KeyFile ();
				unowned SList<string> entry;
				keyfile.load_from_file (this.config_file, GLib.KeyFileFlags.NONE);
				foreach (var name in keyfile.get_groups ()) {
					last_focus_order.prepend (name);
				}
				foreach (var name in last_focus_order) {
					if ((entry = groups.find_custom (name, strcmp)) != null) {
						groups.prepend (entry.data);
						groups.remove_link (entry);
					}
				}
			}
			catch (GLib.Error e) {
			}
		}

		public void quit () {
			// Save notes before leaving the main loop since it works with GObject signals
			save_notes ();
			save_windows_configuration ();
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
		public Xnp.Window? create_window (string? name = null) {
			var window = new Xnp.Window (this);

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
			this.focus_order.append (window);

			/* Insert initial notes */
			string window_path = "%s/%s".printf (notes_path, window.name);
			if (name == null || !GLib.FileUtils.test (window_path, GLib.FileTest.IS_DIR|GLib.FileTest.EXISTS)) {
				try {
					GLib.DirUtils.create_with_parents (window_path, 0700);
					string note_path = "%s/%s".printf (window_path, _("Note %d").printf (1));
					GLib.FileUtils.set_contents (note_path, "", -1);
					this.load_window_data (window);
				}
				catch (FileError e) {
					window.popup_error (e.message);
					destroy_window (window);
					return null;
				}
			}
			else {
				this.load_window_data (window);
			}

			/* Window monitor */
			set_window_monitor (window);

			/* Global settings */
			Xfconf.property_bind (xfconf_channel, "/global/tabs-position",
				typeof (int), window, "tabs-position");

			window.skip_taskbar_hint = this.skip_taskbar_hint;

			/* Connect signals */
			window.action.connect ((win, action) => {
				if (action == "hide") {
					if (this.lock_focus_order)
						return;
					int hidden_windows = 0;
					foreach (var w in this.focus_order) {
						if (!w.get_visible ()) {
							hidden_windows++;
						}
					}
					this.focus_order.remove (window);
					this.focus_order.insert (window, hidden_windows - 1);
				}
				else if (action == "rename") {
					rename_window (win);
					set_data_value (win, "internal-change", true);
				}
				else if (action == "delete") {
					delete_window (win);
					set_data_value (win, "internal-change", true);
				}
				else if (action == "create-new-window") {
					var new_win = create_window ();
					if (new_win == null)
						return;
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

				try {
					note.backed = false;
					var file = File.new_build_filename (notes_path, win.name, note.name);
					file.create (FileCreateFlags.NONE);
					set_data_value (win, "internal-change", true);
					note.backed = true;
				}
				catch (GLib.Error e) {
					win.popup_error (e.message);
				}
			});
			window.note_deleted.connect ((win, note) => {
				try {
					var file = File.new_build_filename (notes_path, win.name, note.name);
					file.delete ();
					set_data_value (win, "internal-change", true);
					note.backed = false;
				}
				catch (GLib.Error e) {
					win.popup_error (e.message);
				}
			});
			window.note_renamed.connect ((win, note, name) => {
				if (!name_is_valid (name)) {
					return;
				}
				try {
					var file = File.new_build_filename (notes_path, win.name, note.name);
					file.set_display_name (name);
					set_data_value (win, "internal-change", true);
					note.name = name;
				}
				catch (GLib.Error e) {
					win.popup_error (e.message);
				}
			});
			/*
			 * When working in system tray mode, save windows configuration
			 * two seconds after going to the background
			 */
			window.notify["is-active"].connect (() => {
				if (this.save_config_timeout > 0) {
					Source.remove (this.save_config_timeout);
					this.save_config_timeout = 0;
				}

				if (window.is_active) {
					this.focus_order.remove (window);
					this.focus_order.append (window);
				}
				else if (this.system_tray_mode) {
					this.save_config_timeout = Timeout.add_seconds (2, save_windows_configuration);
				}
			});
			/* Handle exchange of tabs between windows */
			window.note_moved.connect ((to_win, from_win, note) => {
				try {
					var from_file = File.new_build_filename (notes_path, from_win.name, note.name);
					var to_file = File.new_build_filename (notes_path, to_win.name, note.name);
					from_file.move (to_file, FileCopyFlags.NONE);
					set_data_value (from_win, "internal-change", true);
					set_data_value (to_win, "internal-change", true);
					var tab_evbox = from_win.get_tab_evbox (note);
					from_win.disconnect_note_signals (note, tab_evbox);
					to_win.connect_note_signals (note, tab_evbox);
					return true;
				}
				catch (GLib.Error e) {
					to_win.popup_error (e.message);
					return false;
				}
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
						var file = File.new_build_filename (path, name);
						GLib.FileUtils.get_contents (file.get_path (), out contents, null);
						var note = window.insert_note (name);
						note.text = contents;
						Xfconf.property_bind (xfconf_channel, "/global/font-description",
								typeof (string), note.text_view, "font");
						note.backed = true;
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
				window.above = xfconf_channel.get_bool ("/new-window/always-on-top", false);
				window.sticky = xfconf_channel.get_bool ("/new-window/sticky", true);
				int width = xfconf_channel.get_int ("/new-window/width", 0);
				int height = xfconf_channel.get_int ("/new-window/height", 0);
				if (width > 0 && height > 0) {
					window.resize (width, height);
				}
				window.show ();
			}
		}

		/**
		 * save_windows_configuration:
		 *
		 * Save window configuration inside rc file.
		 */
		public bool save_windows_configuration () {
			var keyfile = new GLib.KeyFile ();
			string old_contents;
			try {
				GLib.FileUtils.get_contents (config_file, out old_contents);
			}
			catch (FileError e) {
			}
			try {
				foreach (var win in this.focus_order) {
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
				if (contents != old_contents)
					GLib.FileUtils.set_contents (config_file, contents);
			}
			catch (FileError e) {
				message ("Unable to save window configuration from %s: %s", config_file, e.message);
			}
			if (this.save_config_timeout > 0) {
				Source.remove (this.save_config_timeout);
				this.save_config_timeout = 0;
			}
			return false;
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
			string old_contents;
			try {
				GLib.FileUtils.get_contents (path, out old_contents);
			}
			catch (FileError e) {
			}
			try {
				string contents = note.text;
				if (contents != old_contents)
					GLib.FileUtils.set_contents (path, contents, -1);
				note.dirty = false;
				note.backed = true;
			}
			catch (FileError e) {
				window.popup_error (e.message);
			}
		}

		/**
		 * rename_window:
		 *
		 * Rename the window.
		 */
		private void rename_window (Xnp.Window window) {
			var dialog = new Gtk.Dialog.with_buttons (_("Rename group"), window,
					Gtk.DialogFlags.DESTROY_WITH_PARENT,
					"gtk-cancel", Gtk.ResponseType.CANCEL, "gtk-ok", Gtk.ResponseType.OK);
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
			window.dialog_hide (dialog);
			if (res == Gtk.ResponseType.OK) {
				weak string name = entry.text;
				if (window_name_exists (name)) {
					window.popup_error (_("The name %s is already in use").printf (name));
				}
				else {
					if (!name_is_valid (name)) {
						return;
					}
					try {
						var group_dir = File.new_build_filename (notes_path, window.name);
						group_dir.set_display_name (name);
						window.name = name;
						this.window_list.sort ((GLib.CompareFunc)window.compare_func);

						set_window_monitor (window);
					} catch (GLib.Error e) {
						window.popup_error (e.message);
					}
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
			if (!window.empty) {
				var dialog = new Gtk.MessageDialog (window, Gtk.DialogFlags.DESTROY_WITH_PARENT,
						Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, _("Are you sure you want to delete this group?"));
				dialog.icon_name = "gtk-delete";
				dialog.title = window.name;
				int res = dialog.run ();
				window.dialog_destroy (dialog);
				if (res != Gtk.ResponseType.YES)
					return;
			}

			string name;
			var path = File.new_build_filename (notes_path, window.name);
			if (path.query_exists ()) {
				try {
					var dir = GLib.Dir.open (path.get_path (), 0);
					name = dir.read_name ();
					if (window.n_pages == 0) {
						/* From the user's point of view, it looks like the directory is empty.
						   So we don't want to delete any files here, as this is not expected
						   behavior. */
						if (name == null) {
							path.delete ();
						} else {
							name = window.name;
							destroy_window (window);
							var win = create_window (name);
							if (win != null)
								win.show ();
							return;
						}
					} else {
						/* The user clearly wants to delete a group of notes */
						if (name != null) {
							do {
								path.get_child (name).delete ();
							} while ((name = dir.read_name ()) != null);
						}
						path.delete ();
					}
				}
				catch (GLib.Error e) {
					window.popup_error (e.message);
					name = window.name;
					destroy_window (window);
					var win = create_window (name);
					if (win != null)
						win.show ();
					return;
				}
			}

			if (this.window_list.length () < 2) {
				destroy_window (window);
				var new_win = create_window ();
				if (new_win != null)
					new_win.show ();
			} else {
				var new_focus = this.next_focus;
				if (new_focus != null) {
					new_focus.skip_taskbar_hint = false;
					destroy_window (window);
					new_focus.skip_taskbar_hint = this.skip_taskbar_hint;
				} else {
					destroy_window (window);
				}
			}
		}

		/**
		 * destroy_window:
		 *
		 * Destroy window and forget it exists.
		 */
		private void destroy_window (Xnp.Window window) {
			this.window_list.remove (window);
			this.focus_order.remove (window);
			window.destroy ();
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
			dialog.set_icon_name ("org.xfce.notes");
			dialog.format_secondary_text (_("Do you want to reload the group?"));
			var res = dialog.run ();
			window.dialog_destroy (dialog);

			if (res == Gtk.ResponseType.YES) {
				save_windows_configuration ();
				// Delete existing window object
				var name = window.name;
				destroy_window (window);
				// Create new window object
				var win = create_window (name);
				if (win != null)
					win.show ();
			}
			else {
				set_data_value (window, "external-change", false);
				window.show_refresh_button = false;
				window.save_notes ();

			}
		}

		/**
		 * get_window_list:
		 *
		 * Get the window_list property value.
		 */
		public unowned SList<Xnp.Window> get_window_list () {
			return window_list;
		}

		/**
		 * Window monitor management
		 */

		/**
		 * set_window_monitor:
		 *
		 * Creates an Xnp.WindowMonitor object and stores it inside window.
		 */
		private void set_window_monitor (Xnp.Window window) {
			var path = File.new_build_filename (notes_path, window.name);
			window.monitor = new Xnp.WindowMonitor (path);

			window.monitor.window_updated.connect (() => {
				if (get_data_value (window, "internal-change")) {
					set_data_value (window, "internal-change", false);
				}
				else {
					set_data_value (window, "external-change", true);
					window.show_refresh_button = true;
				}
			});

			window.monitor.note_deleted.connect ((note_name) => {
				window.externally_removed (note_name);
				/* Avoid refresh button appearance */
				set_data_value (window, "internal-change", true);
			});

			window.monitor.note_renamed.connect ((note_name, new_name) => {
				window.rename_note (note_name, new_name);
				/* Avoid refresh button appearance */
				set_data_value (window, "internal-change", true);
			});
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
				error_dialog.icon_name = "gtk-dialog-error";
				error_dialog.title = _("Error");
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

			if (!active_found && visible_found) {
				present_windows ();
			}
			else if (invisible_found) {
				show_windows ();
			}
			else {
				hide_windows ();
			}
		}

		/**
		 * present_windows:
		 *
		 * Present visible notes windows.
		 */
		private void present_windows () {
			foreach (var win in this.focus_order) {
				if (win.get_visible ()) {
					win.present ();
				}
			}
		}

		/**
		 * show_windows:
		 *
		 * Show all notes windows.
		 */
		private void show_windows () {
			var focus = this.focus_order.last ().data;
			foreach (var win in this.focus_order) {
				if (win != focus) {
					win.focus_on_map = false;
					win.show ();
					win.focus_on_map = true;
				} else {
					win.show ();
					win.present ();
				}
			}
		}

		/**
		 * hide_windows:
		 *
		 * Hide all notes windows.
		 */
		private void hide_windows () {
			this.lock_focus_order = true;
			foreach (var win in this.focus_order.copy ()) {
				win.hide ();
			}
			this.lock_focus_order = false;
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
				error_dialog.icon_name = "gtk-dialog-error";
				error_dialog.title = _("Error");
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
					"© 2003 Jakob Henriksson",
					"© 2006 Mike Massonnet",
					"© 2023 Arthur Demchenkov",
					null
				};

			Gtk.show_about_dialog (null,
				"program-name", _("Notes"),
				"logo-icon-name", "org.xfce.notes.logo",
				"comments", _("Ideal for your quick notes"),
				"version", Config.PACKAGE_VERSION,
				"copyright", "Copyright © 2003-2024 The Xfce development team",
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
					menu.insert (mi as Gtk.Widget, -1);
				}

				// New group menu item
				var mi_sep = new Gtk.SeparatorMenuItem ();
				menu.insert (mi_sep as Gtk.Widget, -1);
				var mi_add = new Gtk.ImageMenuItem.with_mnemonic (_("_Add a new group"));
				mi_add.activate.connect (() => {
					var new_win = create_window ();
					if (new_win != null)
						new_win.show ();
				});
				var image = new Gtk.Image.from_icon_name ("gtk-add", Gtk.IconSize.MENU);
				mi_add.set_image (image);
				menu.insert (mi_add as Gtk.Widget, -1);

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

