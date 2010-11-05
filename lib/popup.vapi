[CCode (cheader_filename = "popup.h")]
namespace Xnp.Popup {
	[CCode (cname = "popup_set_x_selection")]
	public static bool set_x_selection (Gtk.Widget widget);
	[CCode (cname = "popup_get_message_from_event")]
	public static unowned string? get_message_from_event (Gdk.EventClient event);
}
