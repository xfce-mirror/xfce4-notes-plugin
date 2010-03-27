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
		Xfce.textdomain (Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALE_DIR);
		application = new Xnp.Application (save_location (true));

		button = Xfce.panel_create_button ();
		image = new Xfce.PanelImage.from_source ("xfce4-notes-plugin");
		button.add (image);
		button.clicked += () => { application.show_hide_notes (); };
		button.show_all ();
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

		set_x_selection ();

		size_changed += (p, size) => {
			button.set_size_request (size, size);
			return true;
		};
		save += () => { application.save_windows_configuration (); };
		free_data += () => {
			application.save_windows_configuration ();
			application.save_notes ();
		};
		configure_plugin += () => { application.open_settings_dialog (); };
		about += () => { application.open_about_dialog (); };
		destroy += () => { Gtk.main_quit (); };
	}

	/**
	 * set_x_selection:
	 *
	 * Set an X selection to listen to for the popup command.
	 */
	private bool set_x_selection () {
		invisible = new Gtk.Invisible ();
		if (!Xnp.Popup.set_x_selection (invisible)) {
			return false;
		}
		invisible.client_event += (w, event) => {
			if (Xnp.Popup.get_message_from_event (event) == "SHOW_HIDE") {
				application.show_hide_notes ();
				return true;
			}
			return false;
		};
		return true;
	}

}

[ModuleInit]
public Type xfce_panel_module_init (TypeModule module) {
	return typeof (NotesPlugin);
}

