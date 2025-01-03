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
		private uint src_external = 0;
		private uint src_internal = 0;
		private bool skip = false;

		public signal void note_updated (string note_name);
		public signal void note_deleted (string note_name);
		public signal void note_created (string note_name);
		public signal void note_renamed (string note_name, string new_name);
		public signal bool note_exists (File file);

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
		private FileEvent dummy = FileEvent(File.new_for_path (""), null, -1);
		private const GLib.FileMonitorEvent CREATED = GLib.FileMonitorEvent.CREATED;
		private const GLib.FileMonitorEvent CHANGES_DONE_HINT = GLib.FileMonitorEvent.CHANGES_DONE_HINT;

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
			if (src_external != 0)
				Source.remove (src_external);
			if (src_internal != 0)
				Source.remove (src_internal);
		}

		private void monitor_change_cb (File file, File? other_file, FileMonitorEvent event) {
			if (skip) return;

			events += FileEvent(file, other_file, event);

			if (src_external != 0) {
				Source.remove (src_external);
			}

			src_external = Timeout.add (150, () => {
				optimize_events ();
				process_events ();
				src_external = 0;
				this.events = new FileEvent[0];
				return Source.REMOVE;
			});
		}

		private void process_events () {
			foreach (FileEvent ev in events) {
				string note_name = ev.file.get_basename ();
				switch (ev.event) {
					case CHANGES_DONE_HINT:
						this.note_updated (note_name);
						break;

					case DELETED:
					case MOVED_OUT:
						this.note_deleted (note_name);
						break;

					case CREATED:
					case MOVED_IN:
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
			if (src_internal != 0)
				Source.remove (src_internal);

			skip = true;
			src_internal = Timeout.add (150, () => {
				skip = false;
				src_internal = 0;
				return Source.REMOVE;
			});
		}

		/*
		 * There are four kind of events:
		 * 1) CREATED, MOVED_IN
		 * 2) DELETED, MOVED_OUT
		 * 3) CHANGES_DONE_HINT
		 * 4) RENAMED
		 *
		 * Optimizations we do:
		 * CREATED + DELETED => drop
		 * CREATED + CHANGES_DONE_HINT => CREATED
		 * CREATED + RENAMED (to new) => CREATED
		 * CREATED + RENAMED (to existing) => CHANGES_DONE_HINT
		 * DELETED + CREATED => CHANGES_DONE_HINT
		 * DELETED + RENAMED (to existing) => CHANGES_DONE_HINT
		 * CHANGES_DONE_HINT + DELETED => DELETED
		 * CHANGES_DONE_HINT + CHANGES_DONE_HINT => CHANGES_DONE_HINT
		 * CHANGES_DONE_HINT + RENAMED (to new) => RENAMED + CHANGES_DONE_HINT
		 * CHANGES_DONE_HINT + RENAMED (to existing) => RENAMED + CHANGES_DONE_HINT
		 * RENAMED (existing to existing) => DELETED + CHANGES_DONE_HINT
		 * RENAMED (new      to existing) => CHANGES_DONE_HINT
		 * RENAMED (to new) + CREATED => CREATED + CHANGES_DONE_HINT
		 * RENAMED (to new) + DELETED => DELETED
		 * RENAMED (to new) + CHANGES_DONE_HINT => nothing to change
		 * RENAMED (to new) + RENAMED (to new) => RENAMED (to new)
		 * RENAMED (new to new) + RENAMED (to existing) => CHANGES_DONE_HINT
		 * RENAMED (existing to new) + RENAMED (to existing) => RENAMED (existing to existing)
		 * UNKNOWN_EVENT => drop
		 */
		private void optimize_events () {
			for (int i = 0; i < events.length; i++) {
				switch (events[i].event) {
					case CREATED:
					case MOVED_IN:
					case CHANGES_DONE_HINT:
						optimize_event_created (i);
						break;

					case DELETED:
					case MOVED_OUT:
						optimize_event_deleted (i);
						break;

					case RENAMED:
						optimize_event_renamed (i);
						break;

					default:
						events[i] = dummy;
						break;
				}
			}

			/* Remove dummy events from the queue */
			FileEvent[] new_events = {};
			foreach (FileEvent ev in events) {
				if (ev != dummy)
					new_events += ev;
			}
			this.events = new_events;
		}

		/* Optimize file creation/modification events */
		private void optimize_event_created (int n) {
			var file = events[n].file;

			events[n].event = note_exists (file) ? CHANGES_DONE_HINT : CREATED;

			for (int i = n + 1; i < events.length; i++) {
				if (! file.equal (events[i].file)) continue;
				switch (events[i].event) {
					case DELETED:
					case MOVED_OUT:
						// CREATED + DELETED => drop
						// CHANGES_DONE_HINT + DELETED => DELETED
						if (events[n].event == CREATED) events[i] = dummy;
						events[n] = dummy;
						return;

					case CHANGES_DONE_HINT:
						// CREATED + CHANGES_DONE_HINT => CREATED
						// CHANGES_DONE_HINT + CHANGES_DONE_HINT => CHANGES_DONE_HINT
						events[i] = events[n];
						events[n] = dummy;
						n = i;
						break;

					case RENAMED:
						// CREATED + RENAMED (to existing) => CHANGES_DONE_HINT
						// CREATED + RENAMED (to new) => CREATED
						// CHANGES_DONE_HINT + RENAMED (to existing) => RENAMED + CHANGES_DONE_HINT
						// CHANGES_DONE_HINT + RENAMED (to new) => RENAMED + CHANGES_DONE_HINT
						var other_file = events[i].other_file;
						if (events[n].event == CREATED) {
							events[n] = dummy;
							events[i].event = this.note_exists (other_file) ? CHANGES_DONE_HINT : CREATED;
						} else {
							events[n] = events[i];
							events[i].event = CHANGES_DONE_HINT;
						}
						events[i].file = other_file;
						events[i].other_file = null;
						return;

					default:
						break;
				}
			}
		}

		/* Optimize file deletion events */
		private void optimize_event_deleted (int n) {
			var file = events[n].file;

			if (! this.note_exists (file)) return;

			for (int i = n + 1; i < events.length; i++) {
				var file_equal = file.equal (events[i].file);
				var other_file = events[i].other_file;
				var other_file_equal = other_file != null && file.equal (other_file);
				if (! file_equal && ! other_file_equal)
					continue;
				switch (events[i].event) {
					case CREATED:
					case MOVED_IN:
						// DELETED + CREATED => CHANGES_DONE_HINT
						events[n] = dummy;
						events[i].event = CHANGES_DONE_HINT;
						return;

					case RENAMED:
						// DELETED + RENAMED (to existing) => CHANGES_DONE_HINT
						events[n] = dummy;
						events[i].event = CHANGES_DONE_HINT;
						events[i].file  = file;
						events[i].other_file = null;
						return;

					default:
						break;
				}
			}
		}

		/* Optimize file renaming events */
		private void optimize_event_renamed (int n) {
			var file = events[n].file;
			var other_file = events[n].other_file;

			// RENAMED (existing to existing) => DELETED + CHANGES_DONE_HINT
			// RENAMED (new      to existing) => CHANGES_DONE_HINT
			if (this.note_exists (other_file)) {
				if (this.note_exists (file)) {
					events[n].event = DELETED;
					events += FileEvent (other_file, null, CHANGES_DONE_HINT);
					optimize_event_deleted (n);
				} else {
					events[n].event = CHANGES_DONE_HINT;
					events[n].file  = other_file;
					optimize_event_created (n);
				}
				return;
			}

			for (int i = n + 1; i < events.length; i++) {
				if (! file.equal (events[i].file) && ! other_file.equal (events[i].file))
					continue;

				switch (events[i].event) {
					case CREATED:
					case MOVED_IN:
						// RENAMED (to new) + CREATED => CREATED + CHANGES_DONE_HINT
						events[n].event = CREATED;
						events[n].file  = other_file;
						events[n].other_file = null;
						events[i].event = CHANGES_DONE_HINT;
						optimize_event_created (n);
						return;

					case DELETED:
					case MOVED_OUT:
						// RENAMED (to new) + DELETED => DELETED
						events[n].event = DELETED;
						events[n].other_file = null;
						events[i] = events[n];
						events[n] = dummy;
						return;

					case CHANGES_DONE_HINT:
						// RENAMED (to new) + CHANGES_DONE_HINT => nothing to change
						return;

					case RENAMED:
						// RENAMED (existing to new) + RENAMED (to existing) => RENAMED (existing to existing)
						// RENAMED (new to new) + RENAMED (to existing) => CHANGES_DONE_HINT
						// RENAMED (to new) + RENAMED (to new) => RENAMED (to new)
						if (this.note_exists (events[i].other_file)) {
							if (this.note_exists (file)) {
								events[n] = dummy;
								events[i].file = file;
							} else {
								events[n] = dummy;
								events[i].event = CHANGES_DONE_HINT;
								events[i].file  = events[i].other_file;
								events[i].other_file = null;
							}
						} else {
							events[n].other_file = events[i].other_file;
							events[i] = events[n];
							events[n] = dummy;
						}
						return;

					default:
						break;
				}
			}
		}

	}

}
