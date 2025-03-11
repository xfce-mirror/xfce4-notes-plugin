libnotes_sources = [
  'application.vala',
  'file-utils.vala',
  'hypertextview.vala',
  'icon-button.vala',
  'note.vala',
  'theme-gtkcss.vala',
  'theme.vala',
  'window-monitor.vala',
  'window.vala',
  xfce_revision_h,
]

config_vapidir = meson.current_source_dir()

libnotes = static_library(
  'notes',
  libnotes_sources,
  include_directories: [
    include_directories('..'),
  ],
  vala_args: [
    '--pkg', 'config',
    '--vapidir', config_vapidir,
  ],
  vala_header: 'libnotes.h',
  vala_vapi: 'libnotes.vapi',
  dependencies: [
    gio,
    glib,
    gtk,
    gtksourceview,
    libxfce4panel,
    libxfce4ui,
    libxfce4util,
    xfconf,
  ],
  install: false,
)

libnotes_dep = declare_dependency(
  link_with: libnotes,
  include_directories: [
    include_directories('.'),
  ],
)
