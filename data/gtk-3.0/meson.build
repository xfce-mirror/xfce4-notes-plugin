gtk_css = configure_file(
  configuration: {
    'sysconfdir': get_option('prefix') / get_option('sysconfdir'),
  },
  input: 'gtk.css.in',
  output: 'gtk.css',
  install: true,
  install_dir: pkgdatadir / 'gtk-3.0',
)
