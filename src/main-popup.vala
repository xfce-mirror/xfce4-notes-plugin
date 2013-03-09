/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (C) 2006-2013  Mike Massonnet <mmassonnet@xfce.org>
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

static int main (string[] args) {
	Gtk.init (ref args);
	var app = new GLib.Application ("org.xfce.Notes", 0);
	try {
		app.register ();
	} catch (GLib.Error e) {
		warning ("Unable to register: %s", e.message);
		return -1;
	}
	if (!app.get_is_remote ()) {
		// We are the primary instance, in that case start xfce4-notes
		try {
			message ("xfce4-notes isn't currently running, trying to start it...");
			GLib.Process.spawn_command_line_async ("xfce4-notes");
		} catch (GLib.Error e) {
			critical ("%s", e.message);
			return -1;
		}
	} else {
		// Send an activate signal which is used to show/hide the notes
		app.activate ();
	}
	return 0;
}
