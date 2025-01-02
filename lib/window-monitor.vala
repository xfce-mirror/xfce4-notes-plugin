/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (c) 2009-2010  Mike Massonnet <mmassonnet@xfce.org>
 *  Copyright (c) 2024-2025  Arthur Demchenkov <spinal.by@gmail.com>
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

		private GLib.FileMonitor monitor;
		private uint src_timeout = 0;
		private uint src_events = 0;
		private uint src_idle = 0;
		private bool skip = false;

		public signal void window_updated ();
		public signal void note_updated (string note_name);
		public signal void note_deleted (string note_name);
		public signal void note_created (string note_name);
		public signal void note_renamed (string note_name, string new_name);

		struct FileEvent {
			File file;
			File other_file;
			FileMonitorEvent event;
			public FileEvent(File? file, File? other_file, FileMonitorEvent event) {
				this.file = file;
				this.other_file = other_file;
				this.event = event;
			}
		}

		private FileEvent[] events = {};

		public WindowMonitor (GLib.File path) {
			try {
				monitor = path.monitor_directory (GLib.FileMonitorFlags.WATCH_MOVES, null);
				monitor.set_rate_limit (1000);
				monitor.changed.connect (monitor_change_cb);
			}
			catch (Error e) {
				message ("Unable to create a directory monitor: %s", e.message);
			}
		}

		~WindowMonitor () {
			if (src_timeout != 0)
				Source.remove (src_timeout);
			if (src_events != 0)
				Source.remove (src_events);
			if (src_idle != 0)
				Source.remove (src_idle);
		}

		private void monitor_change_cb (File file, File? other_file, FileMonitorEvent event) {
			if (skip) return;

			events += FileEvent(file, other_file, event);

			if (src_events == 0) {
				src_events = Idle.add (() => {
					process_events ();
					src_events = 0;
					this.events = new FileEvent[0];
					return Source.REMOVE;
				});
			}
		}

		private void process_events () {
			foreach (FileEvent ev in events) {
				string note_name = ev.file.get_basename ();
				switch (ev.event) {
					case CHANGES_DONE_HINT:
						this.note_updated (note_name);
						window_updated_cb ();
						break;

					case DELETED:
					case MOVED_OUT:
						this.note_deleted (note_name);
						break;

					case CREATED:
					case MOVED_IN:
						// Don't send window-updated signal, as a CHANGES_DONE_HINT is emitted anyway
						this.note_created (note_name);
						break;

					case RENAMED:
						this.note_renamed (note_name, ev.other_file.get_basename ());
						break;

					default:
						break;
				}
			}
		}

		/* Temporarily disable monitoring while we make internal changes */
		public void internal_change () {
			if (skip == false) {
				skip = true;
				src_idle = Idle.add (() => {
					skip = false;
					src_idle = 0;
					return Source.REMOVE;
				});
			}
		}

		private void window_updated_cb () {
			if (src_timeout != 0) {
				Source.remove (src_timeout);
			}
			src_timeout = Timeout.add_seconds (1, () => {
				this.window_updated ();
				src_timeout = 0;
				return Source.REMOVE;
			});
		}

	}

}
