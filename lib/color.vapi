[CCode (cprefix = "", lower_case_prefix = "", cheader_filename = "color.h")]
namespace Xnp.Color {
	[CCode (cname = "color_set_background")]
	public static void set_background (string color);
	[CCode (cname = "__gdk_color_constrast")]
	public static void contrast (Gdk.Color color, double contrast);
}
