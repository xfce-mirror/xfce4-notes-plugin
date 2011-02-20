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

namespace Xnp {

	public class WindowMonitor : GLib.Object {

		public Xnp.Window window;
		private GLib.FileMonitor monitor;
		private uint monitor_timeout = 0;

		public signal void window_updated (Xnp.Window window);
		public signal void note_updated (string note_name);
		public signal void note_deleted (string note_name);
		public signal void note_created (string note_name);

		public WindowMonitor (Xnp.Window window, GLib.File file) {
			this.window = window;
			try {
				monitor = file.monitor_directory (GLib.FileMonitorFlags.NONE, null);
				monitor.set_rate_limit (1000);
				monitor.changed.connect (monitor_change_cb);
			}
			catch (Error e) {
				message ("Unable to create a directory monitor: %s", e.message);
			}
		}

		private void monitor_change_cb (File file, File? other_file, FileMonitorEvent event) {
			string note_name = file.get_basename ();
			switch (event) {
			case GLib.FileMonitorEvent.CHANGES_DONE_HINT:
				note_updated (note_name);
				window_updated_cb ();
				break;

			case GLib.FileMonitorEvent.DELETED:
				note_deleted (note_name);
				window_updated_cb ();
				break;

			case GLib.FileMonitorEvent.CREATED:
				// Don't send window-updated signal, as a CHANGES_DONE_HINT is emitted anyway
				note_created (note_name);
				break;
			}
		}

		private void window_updated_cb () {
			if (monitor_timeout != 0) {
				Source.remove (monitor_timeout);
			}
			monitor_timeout = Timeout.add_seconds (5, () => {
				window_updated (window);
				monitor_timeout = 0;
				return false;
			});
		}

	}

}
