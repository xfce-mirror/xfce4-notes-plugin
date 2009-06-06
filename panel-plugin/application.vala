/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (c) 2009  Mike Massonnet <mmassonnet@xfce.org>
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

		private SList<Xnp.Window> window_list;
		private string notes_path;
		private string config_file;
		private Xfconf.Channel xfconf_channel;

		construct {
			notes_path = "%s/notes".printf (GLib.Environment.get_user_data_dir ());
			config_file = "%s/xfce4/panel/xfce4-notes-plugin.rc".printf (GLib.Environment.get_user_config_dir ());
		}

		public Application () {
			try {
				Xfconf.init ();
				xfconf_channel = new Xfconf.Channel.with_property_base ("xfce4-panel", "/plugins/notes");
			}
			catch (Xfconf.Error e) {
				warning ("%s", e.message);
			}

			string name;
			bool found = false;
			try {
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
				create_window ();
			}
		}

		~Application () {
			save_windows_configuration ();
			save_notes ();
			xfconf_channel.unref ();
			Xfconf.shutdown ();
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
		public void create_window (string? name = null) {
			var window = new Xnp.Window ();

			/* Global settings */
			Xfconf.Property.bind (xfconf_channel, "/global/skip-taskbar-hint",
				typeof (bool), window, "skip-taskbar-hint");

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
				string window_name = "Notes";
				int len = (int)this.window_list.length ();
				for (int id = 1; id <= len + 1; id++) {
					if (id > 1) {
						window_name = "Notes %d".printf (id);
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
			if (name == null) {
				var note = window.insert_note ();
				Xfconf.Property.bind (xfconf_channel, "/global/font-description",
					typeof (string), note.text_view, "font");

				string window_path = "%s/%s".printf (notes_path, window.name);
				GLib.DirUtils.create_with_parents (window_path, 0700);
				try {
					string note_path = "%s/%s".printf (window_path, note.name);
					GLib.FileUtils.set_contents (note_path, "", -1);
				}
				catch (FileError e) {
				}

				window.show ();
			}
			else {
				this.load_window_data (window);
			}

			/* Connect signals */
			window.action += (win, action) => {
				if (action == "rename") {
					rename_window (win);
				}
				else if (action == "delete") {
					delete_window (win);
				}
				else if (action == "create-new-window") {
					create_window ();
				}
			};
			window.save_data += (win, note) => {
				save_note (win, note);
			};
			window.note_inserted += (win, note) => {
				Xfconf.Property.bind (xfconf_channel, "/global/font-description",
					typeof (string), note.text_view, "font");

				string path = "%s/%s/%s".printf (notes_path, win.name, note.name);
				try {
					GLib.FileUtils.set_contents (path, "", -1);
				}
				catch (FileError e) {
				}
			};
			window.note_deleted += (win, note) => {
				string path = "%s/%s/%s".printf (notes_path, win.name, note.name);
				GLib.FileUtils.unlink (path);
			};
			window.note_renamed += (win, note, old_name) => {
				if (!name_is_valid (note.name)) {
					note.name = old_name;
					return;
				}
				string old_path = "%s/%s/%s".printf (notes_path, win.name, old_name);
				string new_path = "%s/%s/%s".printf (notes_path, win.name, note.name);
				GLib.FileUtils.rename (old_path, new_path);
			};
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
						string filename = "%s/%s".printf (path, name);
						GLib.FileUtils.get_contents (filename, out contents, null);
						var note = window.insert_note ();
						note.name = name;
						var buffer = note.text_view.get_buffer ();
						buffer.set_text (contents, -1);
						Xfconf.Property.bind (xfconf_channel, "/global/font-description",
								typeof (string), note.text_view, "font");
					}
					catch (FileError e) {
						warning ("%s", e.message);
					}
				}
			}
			catch (FileError e) {
			}

			/* Load configuration */
			var keyfile = new GLib.KeyFile ();
			try {
				keyfile.load_from_file (config_file, GLib.KeyFileFlags.NONE);
				int winx = keyfile.get_integer (window.name, "PosX");
				int winy = keyfile.get_integer (window.name, "PosY");
				int width = keyfile.get_integer (window.name, "Width");
				int height = keyfile.get_integer (window.name, "Height");
				int last_page = keyfile.get_integer (window.name, "LastTab");
				bool above = keyfile.get_boolean (window.name, "Above");
				bool sticky = keyfile.get_boolean (window.name, "Sticky");
				double opacity = 1 - keyfile.get_integer (window.name, "Transparency") / 100;
				bool visible = keyfile.get_boolean (window.name, "Visible");

				window.move (winx, winy);
				window.resize (width, height);
				window.set_current_page (last_page);
				window.above = above;
				window.sticky = sticky;
				window.opacity = opacity;
				if (visible)
					window.show ();
			}
			catch (GLib.Error e) {
				warning ("%s: %s", config_file, e.message);
				window.show ();
			}
		}

		/**
		 * save_windows_configuration:
		 *
		 * Save window configuration inside rc file.
		 * TODO save font descriptions
		 */
		public void save_windows_configuration () {
			var keyfile = new GLib.KeyFile ();
			try {
				foreach (var win in this.window_list) {
					int winx, winy, width, height;
					win.get_geometry (out winx, out winy, out width, out height);
					int last_page = win.get_current_page ();
					int transparency = (int)((1 - win.opacity) * 100);
					bool visible = (bool)(win.get_flags () & Gtk.WidgetFlags.VISIBLE);

					keyfile.set_integer (win.name, "PosX", winx);
					keyfile.set_integer (win.name, "PosY", winy);
					keyfile.set_integer (win.name, "Width", width);
					keyfile.set_integer (win.name, "Height", height);
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
			}
		}

		/**
		 * save_notes:
		 *
		 * Save the contents of every existing notes.
		 */
		private void save_notes () {
			foreach (var win in this.window_list) {
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
			var dialog = new Gtk.Dialog.with_buttons ("Rename group", window,
					Gtk.DialogFlags.DESTROY_WITH_PARENT|Gtk.DialogFlags.NO_SEPARATOR,
					Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OK, Gtk.ResponseType.OK);
			dialog.set_default_response (Gtk.ResponseType.OK);
			dialog.resizable = false;
			dialog.icon_name = Gtk.STOCK_EDIT;
			dialog.border_width = 4;
			dialog.vbox.border_width = 6;

			var entry = new Gtk.Entry ();
			entry.text = window.name;
			entry.activates_default = true;
			dialog.vbox.add (entry);
			dialog.vbox.show_all ();

			int res = dialog.run ();
			dialog.hide ();
			if (res == Gtk.ResponseType.OK) {
				weak string name = entry.text;
				if (window_name_exists (name)) {
					var error_dialog = new Gtk.MessageDialog (window, Gtk.DialogFlags.DESTROY_WITH_PARENT,
						Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "The name %s is already in use", name);
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
			var dialog = new Gtk.MessageDialog (window, Gtk.DialogFlags.DESTROY_WITH_PARENT,
				Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, "Are you sure you want to delete this group?");
			int res = dialog.run ();
			dialog.destroy ();
			if (res != Gtk.ResponseType.YES)
				return;

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

			this.window_list.remove (window);
			window.destroy ();

			if (this.window_list.length () >= 1) {
				foreach (var win in this.window_list) {
					win.set_window_list (this.window_list);
				}
			}
			else {
				create_window ();
			}
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
					Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "The name \"%s\" is invalid.", name);
				error_dialog.format_secondary_markup ("The invalid characters are restricted to: <tt>*|/\\:\"&lt;&gt;?</tt>");
				error_dialog.run ();
				error_dialog.destroy ();
			}
			return res;
		}

	}

}

static int main (string[] args) {
	Gtk.init (ref args);
	var app = new Xnp.Application ();
	Gtk.main ();
	app.unref ();
	return 0;
}

