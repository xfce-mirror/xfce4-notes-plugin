/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2009-2010  Mike Massonnet <mmassonnet@xfce.org>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
 */

using Config;
using Xfce;
using Gtk;

public class NotesPlugin : Xfce.PanelPlugin {

	private Gtk.Invisible invisible;
	private Gtk.Button button;
	private Xfce.PanelImage image;
	private Xnp.Application application;

	public NotesPlugin () {
		GLib.Object ();
	}

	public override void @construct () {
		Xfce.textdomain (Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALE_DIR, "UTF-8");
		application = new Xnp.Application (save_location (true));

		button = (Gtk.Button)Xfce.panel_create_button ();
		image = new Xfce.PanelImage.from_source ("xfce4-notes-plugin");
		button.add (image);
		button.clicked.connect (() => { application.show_hide_notes (); });
		button.show_all ();
		small = true;
		add (button);
		add_action_widget (button);
		set_tooltip_text (_("Notes"));
		menu_show_configure ();
		menu_show_about ();

		var mi = new Gtk.MenuItem.with_mnemonic (_("_Groups"));
		var menu = application.context_menu ();
		mi.set_submenu (menu);
		mi.show_all ();
		menu_insert_item (mi);

		size_changed.connect ((p, size) => {
			size = size / (int)nrows;
			button.set_size_request (size, size);
			return true;
		});
		save.connect (() => { application.save_windows_configuration (); });
		free_data.connect (() => {
			application.save_windows_configuration ();
			application.save_notes ();
		});
		configure_plugin.connect (() => { application.open_settings_dialog (); });
		about.connect (() => { application.open_about_dialog (); });
		destroy.connect (() => { Gtk.main_quit (); });
	}

}

[ModuleInit]
public Type xfce_panel_module_init (TypeModule module) {
	return typeof (NotesPlugin);
}

