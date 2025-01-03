/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (c) 2024       Arthur Demchenkov <spinal.by@gmail.com>
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

	namespace FileUtils {

		public bool validate_text_file (File file) {
			bool result = false;

			try {
				unowned char *valid_end;
				uint8[] content = new uint8[4096];
				unowned string str = (string) content;
				var stream = file.read ();
				var length = stream.read (content);
				result = str.validate (length, out valid_end)
					|| (valid_end - (char *)content > length - 6);
			} catch (GLib.Error e) {
			}

			return result;
		}

		public bool path_exists (string path) {
			return GLib.FileUtils.test (path, FileTest.EXISTS);
		}

	}

}
