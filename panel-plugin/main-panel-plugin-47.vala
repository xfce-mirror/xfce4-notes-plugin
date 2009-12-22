/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2009  Mike Massonnet <mmassonnet@xfce.org>
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
	private weak Xfce.PanelPlugin panel_plugin;
	private Xnp.Application application;

	public NotesPlugin () {
		GLib.Object ();
		debug ("constructor");
	}

	public override void @construct () {
		panel_plugin = this;

		Xfce.textdomain (Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALE_DIR);
		application = new Xnp.Application (panel_plugin.save_location (true));

		button = Xfce.panel_create_button ();
		image = new Xfce.PanelImage.from_source ("xfce4-notes-plugin");
		button.add (image);
		button.clicked += () => { application.show_hide_notes (); };
		button.show_all ();
		panel_plugin.add (button);
		panel_plugin.add_action_widget (button);
		panel_plugin.set_tooltip_text (_("Notes"));
		panel_plugin.menu_show_configure ();
		panel_plugin.menu_show_about ();

		var mi = new Gtk.MenuItem.with_mnemonic (_("_Go"));
		var menu = application.context_menu ();
		mi.set_submenu (menu);
		mi.show_all ();
		panel_plugin.menu_insert_item (mi);

		set_x_selection ();

		panel_plugin.size_changed += (p, size) => {
			button.set_size_request (size, size);
			return true;
		};
		panel_plugin.save += () => {
			application.save_windows_configuration ();
		};
		panel_plugin.free_data += () => {
			application.save_windows_configuration ();
			application.save_notes ();
		};
		panel_plugin.configure_plugin += () => {
			application.open_settings_dialog ();
		};
		panel_plugin.about += () => {
			application.open_about_dialog ();
		};
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

