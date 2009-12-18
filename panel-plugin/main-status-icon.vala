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

static Xnp.Application application;
static Gtk.Invisible invisible;
static Gtk.StatusIcon status_icon;
static Gtk.Menu context_menu;

static void build_plugin () {
	Xfce.textdomain (Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALE_DIR);
	var save_location = Xfce.Resource.save_location (Xfce.ResourceType.CONFIG, "xfce4/xfce4-notes.rc", true);
	application = new Xnp.Application (save_location);
	status_icon = new Gtk.StatusIcon.from_icon_name ("xfce4-notes-plugin");
	status_icon.set_tooltip_text (_("Notes"));
	Timeout.add_seconds (60, () => {
			if (!status_icon.is_embedded ()) {
				warning ("Status Icon is not embedded");
				Gtk.main_quit ();
			}
			return false;
		});
	status_icon.activate += () => { application.show_hide_notes (); };
	context_menu = build_context_menu ();
	status_icon.popup_menu += () => {
		context_menu.popup (null, null, status_icon.position_menu, 0, Gtk.get_current_event_time ());
	};
	set_x_selection ();
}

static Gtk.Menu build_context_menu () {
	var menu = new Gtk.Menu ();

	var mi = new Gtk.MenuItem.with_mnemonic (_("_Go"));
	var menu_go = application.context_menu ();
	mi.set_submenu (menu_go);
	menu.append (mi);

	mi = new Gtk.SeparatorMenuItem ();
	menu.append (mi);

	mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_PROPERTIES, null);
	mi.activate += () => { application.open_settings_dialog (); };
	menu.append (mi);

	mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_ABOUT, null);
	mi.activate += () => { application.open_about_dialog (); };
	menu.append (mi);

	mi = new Gtk.SeparatorMenuItem ();
	menu.append (mi);

	mi = new Gtk.ImageMenuItem.from_stock (Gtk.STOCK_REMOVE, null);
	mi.activate += () => {
		Xfce.Autostart.@set ("xfce4-notes-autostart", "xfce4-notes", true);
		Gtk.main_quit ();
	};
	menu.append (mi);

	menu.show_all ();

	return menu;
}

static bool set_x_selection () {
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

static int main (string[] args) {
	Gtk.init (ref args);
	Unique.App app = new Unique.App ("org.xfce.Notes", null);
	if (app.is_running) {
		if (app.send_message (Unique.Command.ACTIVATE, null) == Unique.Response.OK) {
			app = null;
			return 0;
		}
	}
	app.message_received += (command, message_data, time_) => {
		if (command != Unique.Command.ACTIVATE) {
			return Unique.Response.PASSTHROUGH;
		}
		return Unique.Response.OK;
	};
	GLib.Environment.set_application_name (_("Notes"));
	build_plugin ();
	Xfce.Autostart.@set ("xfce4-notes-autostart", "xfce4-notes", false);
	Gtk.main ();
	application = null;
	invisible = null;
	status_icon = null;
	context_menu = null;
	return 0;
}
