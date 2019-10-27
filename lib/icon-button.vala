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

const double M_PI = 3.14159265358979323846;

namespace Xnp {

	public abstract class IconButton : Gtk.EventBox {

		protected bool active = false;

		public signal void clicked ();

		construct {
			((Gtk.Widget)this).name = "notes-icon-button";
			set_visible_window (false);
			set_above_child (true);
			set_size_request (22, 22);

			enter_notify_event.connect (on_enter_notify_event);
			leave_notify_event.connect (on_leave_notify_event);
			button_release_event.connect (on_button_release_event);
		}

		protected abstract void draw_icon (Cairo.Context cr, int width, int height);

		protected void set_widget_source_color (Cairo.Context cr) {
			var style_context = get_style_context ();

			if (sensitive && active) {
				Gdk.cairo_set_source_rgba (cr, style_context.get_color (Gtk.StateFlags.PRELIGHT));
			}
			else if (sensitive && !active)
				Gdk.cairo_set_source_rgba (cr, style_context.get_color (Gtk.StateFlags.NORMAL));
			else if (!sensitive)
				Gdk.cairo_set_source_rgba (cr, style_context.get_color (Gtk.StateFlags.INSENSITIVE));
		}

		public override void add (Gtk.Widget widget) {
			warning ("This object doesn't allow packing child widgets.");
		}

		public override bool draw (Cairo.Context cr) {
			int width = get_allocated_width ();
			int height = get_allocated_height ();
			var style_context = get_style_context ();

			style_context.save ();
			style_context.add_class (Gtk.STYLE_CLASS_BUTTON);
			style_context.render_frame (cr, 0, 0, width, height);
			style_context.render_background (cr, 0, 0, width, height);
			style_context.restore ();

			cr.save ();
			cr.translate (2, 2);
			draw_icon (cr, width - 4, height - 4);
			cr.restore ();

			return false;
		}

		private bool on_enter_notify_event (Gdk.EventCrossing event) {
			active = true;
			get_window ().invalidate_rect (null, false);
			return false;
		}

		private bool on_leave_notify_event (Gdk.EventCrossing event) {
			active = false;
			get_window ().invalidate_rect (null, false);
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
		LEFT_ARROW,
		RIGHT_ARROW,
		REFRESH,
	}

	public class TitleBarButton : IconButton {

		public TitleBarButtonType icon_type { default = TitleBarButtonType.EMPTY; get; construct set; }

		public TitleBarButton (TitleBarButtonType icon_type) {
			Object (icon_type: icon_type);
		}

		protected override void draw_icon (Cairo.Context cr, int width, int height) {
			switch (icon_type) {
				case TitleBarButtonType.CLOSE:
					draw_close_button (cr, width, height);
					break;
				case TitleBarButtonType.LEFT_ARROW:
					draw_left_arrow_button (cr, width, height);
					break;
				case TitleBarButtonType.RIGHT_ARROW:
					draw_right_arrow_button (cr, width, height);
					break;
				case TitleBarButtonType.REFRESH:
					draw_refresh_button (cr, width, height);
					break;
				default:
					break;
			}
		}

		private void draw_left_arrow_button (Cairo.Context cr, int width, int height) {
			int border = 4;
			int x1 = border;
			int x2 = width - border;
			int y1 = border;
			int y2 = height - border;
			if (x2 <= x1 || y2 <= y1) {
				return;
			}

			cr.set_line_cap (Cairo.LineCap.ROUND);

			for (int i = 0; i < 2; i++) {
				if (i == 0) {
					cr.set_source_rgba (1, 1, 1, active ? 0.4 : 0.2);
					cr.set_line_width (4);
				}
				else {
					set_widget_source_color (cr);
					cr.set_line_width (2.66);
				}
				cr.move_to (x1, height / 2);
				cr.line_to (x2, height / 2);
				cr.move_to (width / 2, y1);
				cr.line_to (x1, height / 2);
				cr.line_to (width / 2, y2);
				cr.stroke ();
			}
		}

		private void draw_right_arrow_button (Cairo.Context cr, int width, int height) {
			int border = 4;
			int x1 = border;
			int x2 = width - border;
			int y1 = border;
			int y2 = height - border;
			if (x2 <= x1 || y2 <= y1) {
				return;
			}

			cr.set_line_cap (Cairo.LineCap.ROUND);

			for (int i = 0; i < 2; i++) {
				if (i == 0) {
					cr.set_source_rgba (1, 1, 1, active ? 0.4 : 0.2);
					cr.set_line_width (4);
				}
				else {
					set_widget_source_color (cr);
					cr.set_line_width (2.66);
				}
				cr.move_to (x1, height / 2);
				cr.line_to (x2, height / 2);
				cr.move_to (width / 2, y1);
				cr.line_to (x2, height / 2);
				cr.line_to (width / 2, y2);
				cr.stroke ();
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

			for (int i = 0; i < 2; i++) {
				if (i == 0) {
					cr.set_source_rgba (1, 1, 1, active ? 0.4 : 0.2);
					cr.set_line_width (4);
				}
				else {
					set_widget_source_color (cr);
					cr.set_line_width (2.66);
				}
				cr.move_to (x1, y1);
				cr.line_to (x2, y2);
				cr.move_to (x2, y1);
				cr.line_to (x1, y2);
				cr.stroke ();
			}
		}

		private void draw_refresh_button (Cairo.Context cr, int width, int height) {
			int border = 6;
			int x1 = border;
			int x2 = width - border;
			int y1 = border;
			int y2 = height - border;
			if (x2 <= x1 || y2 <= y1) {
				return;
			}

			cr.set_line_cap (Cairo.LineCap.ROUND);

			for (int j = 0; j < 2; j++) {
				for (int i = 0; i < 2; i++) {
					if (i == 0) {
						cr.set_source_rgba (1, 1, 1, active ? 0.4 : 0.2);
						cr.set_line_width (4);
					}
					else {
						set_widget_source_color (cr);
						cr.set_line_width (2.44);
					}
					cr.save ();
					cr.translate (x1 + (x2 - x1) / 2, y1 + (y2 - y1) / 2);
					if (j == 0) {
						cr.rotate (-M_PI / 16.0);
					}
					else {
						cr.rotate ((15.0 * M_PI) / 16.0);
					}
					cr.arc (0, 0, x2 - x1, (5.0 * M_PI) / 16.0, M_PI);
					var r = (x2 - x1) / 2.0;
					cr.line_to (-r * 2.0, (3.0 * r) / 2.0);
					cr.move_to (-r * 2.0, 0.0);
					cr.line_to (-r, r / 2.0);
					cr.stroke ();
					cr.restore ();
				}
			}
		}
	}

}
