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

static Xnp.Application application;
static Gtk.Invisible invisible;
static Gtk.StatusIcon status_icon;
static Gtk.Menu context_menu;

static void build_plugin () {
	Xfce.textdomain (Config.GETTEXT_PACKAGE, Config.PACKAGE_LOCALE_DIR, "UTF-8");
	var save_location = Xfce.resource_save_location (Xfce.ResourceType.CONFIG, "xfce4/xfce4-notes.rc", true);
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
	status_icon.activate.connect (() => { application.show_hide_notes (); });
	context_menu = build_context_menu ();
	status_icon.popup_menu.connect (() => {
		context_menu.popup (null, null, status_icon.position_menu, 0, Gtk.get_current_event_time ());
	});
}

static Gtk.Menu build_context_menu () {
	var menu = new Gtk.Menu ();

	var mi = new Gtk.MenuItem.with_mnemonic (_("_Groups"));
	var menu_go = application.context_menu ();
	mi.set_submenu (menu_go);
	menu.append (mi);

	mi = new Gtk.SeparatorMenuItem ();
	menu.append (mi);

	mi = new Gtk.MenuItem.with_mnemonic (_("_Properties"));
	mi.activate.connect (() => { application.open_settings_dialog (); });
	menu.append (mi);

	mi = new Gtk.MenuItem.with_mnemonic (_("_About"));
	mi.activate.connect (() => { application.open_about_dialog (); });
	menu.append (mi);

	mi = new Gtk.SeparatorMenuItem ();
	menu.append (mi);

	mi = new Gtk.MenuItem.with_mnemonic (_("_Remove"));
	mi.activate.connect (() => {
		application.save_notes ();
		Xfce.Autostart.@set ("xfce4-notes-autostart", "xfce4-notes", true);
		Gtk.main_quit ();
	});
	menu.append (mi);

	menu.show_all ();

	return menu;
}

static int main (string[] args) {
	Gtk.init (ref args);
	Gtk.Application app = new Gtk.Application ("org.xfce.Notes", 0);

	try {
		app.register ();
	} catch (GLib.Error e) {
		warning ("Application cannot be registered: %s", e.message);
	}

	if (app.get_is_remote ()) {
		app.activate ();
		return 0;
	}

	app.activate.connect (() => {
		application.show_hide_notes ();
	});

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
