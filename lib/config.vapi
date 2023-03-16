[CCode (cprefix = "", cheader_filename = "config.h")]
namespace Config {
	[CCode (cname = "GETTEXT_PACKAGE")]
	public const string GETTEXT_PACKAGE;
	[CCode (cname = "PACKAGE_LOCALE_DIR")]
	public const string PACKAGE_LOCALE_DIR;
	[CCode (cname = "PACKAGE")]
	public const string PACKAGE;
	[CCode (cname = "PACKAGE_BUGREPORT")]
	public const string PACKAGE_BUGREPORT;
	[CCode (cname = "PACKAGE_NAME")]
	public const string PACKAGE_NAME;
	[CCode (cname = "PACKAGE_STRING")]
	public const string PACKAGE_STRING;
	[CCode (cname = "PACKAGE_TARNAME")]
	public const string PACKAGE_TARNAME;
	[CCode (cname = "PACKAGE_VERSION")]
	public const string PACKAGE_VERSION;
	[CCode (cname = "PKGDATADIR")]
	public const string PKGDATADIR;
}
