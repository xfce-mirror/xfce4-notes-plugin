[CCode (cheader_filename = "libc/xfce-autostart.h")]
namespace Xfce.Autostart {
	public static void @set (string name, string exec, bool hidden);
	public static void set_full (string name, string exec, bool hidden, bool terminal, string? comment, string? icon);
}
