namespace Xnp {
	public class ThemeGtkrc {
		[CCode (cname = "update_gtkrc", cheader_filename = "theme-gtkrc.h")]
		public static void update_gtkrc (Gdk.Color color);
	}
}

