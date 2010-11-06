/*
 *  Notes - panel plugin for Xfce Desktop Environment
 *  Copyright (c) 2010  Mike Massonnet <mmassonnet@xfce.org>
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

	public abstract class IconButton : Gtk.EventBox {

		protected bool active = false;

		public signal void clicked ();

		construct {
			set_visible_window (false);
			set_above_child (true);
			set_size_request (22, 22);
			set_border_width (2);

			enter_notify_event.connect (on_enter_notify_event);
			leave_notify_event.connect (on_leave_notify_event);
			button_release_event.connect (on_button_release_event);
		}

		protected abstract void draw_icon (Cairo.Context cr, int width, int height);

		protected void set_widget_source_color (Cairo.Context cr) {
			if (sensitive && active)
				Gdk.cairo_set_source_color (cr, style.base[Gtk.StateType.NORMAL]);
			else if (sensitive && !active)
				Gdk.cairo_set_source_color (cr, style.fg[Gtk.StateType.INSENSITIVE]);
			else if (!sensitive)
				Gdk.cairo_set_source_color (cr, style.text[Gtk.StateType.INSENSITIVE]);
		}

		public override void add (Gtk.Widget widget) {
			warning ("This object doesn't allow packing child widgets.");
		}

		public override bool expose_event (Gdk.EventExpose event) {
			int width = allocation.width - (int)border_width * 2;
			int height = allocation.height - (int)border_width * 2;
			int x = allocation.width / 2 - width / 2 + allocation.x;
			int y = allocation.height / 2 - height / 2 + allocation.y;

			var cr = Gdk.cairo_create(window);
			cr.rectangle (x, y, width, height);
			cr.clip ();

			var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
			var cr_ = new Cairo.Context (surface);
			draw_icon (cr_, width, height);
			cr.set_source_surface (surface, x, y);
			cr.paint ();

			return false;
		}

		private bool on_enter_notify_event (Gdk.EventCrossing event) {
			active = true;
			window.invalidate_rect (null, false);
			return false;
		}

		private bool on_leave_notify_event (Gdk.EventCrossing event) {
			active = false;
			window.invalidate_rect (null, false);
			return false;
		}

		private bool on_button_release_event (Gdk.EventButton event) {
			if (event.button != 1)
				return false;

			int cur_x = (int)event.x;
			int cur_y = (int)event.y;
			int width, height;
			get_size_request (out width, out height);

			if (cur_x >= 0 && cur_x < width && cur_y >= 0 && cur_y < height)
				clicked ();

			return false;
		}

	}

	public enum TitleBarButtonType {
		EMPTY,
		CLOSE,
	}

	public class TitleBarButton : IconButton {

		public TitleBarButtonType icon_type { default = TitleBarButtonType.EMPTY; get; construct set; }

		public TitleBarButton (TitleBarButtonType icon_type) {
			Object (icon_type: icon_type);
		}

		private override void draw_icon (Cairo.Context cr, int width, int height) {
			switch (icon_type) {
				case TitleBarButtonType.CLOSE:
					draw_close_button (cr, width, height);
					break;
				default:
					break;
			}
		}

		private void draw_close_button (Cairo.Context cr, int width, int height) {
			int border = 4;
			int x1 = border;
			int x2 = width - border;
			int y1 = border;
			int y2 = height - border;
			if (x2 <= x1 || y2 <= y1) {
				return;
			}

			cr.set_line_cap (Cairo.LineCap.ROUND);

			cr.set_source_rgba (1, 1, 1, active ? 0.4 : 0.2);
			cr.set_line_width (4);
			cr.move_to (x1, y1);
			cr.line_to (x2, y2);
			cr.move_to (x2, y1);
			cr.line_to (x1, y2);

			cr.stroke ();

			set_widget_source_color (cr);
			cr.set_line_width (2.66);
			cr.move_to (x1, y1);
			cr.line_to (x2, y2);
			cr.move_to (x2, y1);
			cr.line_to (x1, y2);

			cr.stroke ();
		}

	}

}

