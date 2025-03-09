libnotes_util_sources = [
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
notes_util_vapidir = meson.current_build_dir()

libnotes_util = static_library(
  'notes-util',
  libnotes_util_sources,
  include_directories: [
    include_directories('..'),
  ],
  vala_args: [
    '--pkg', 'config',
    '--vapidir', config_vapidir,
  ],
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

libnotes_util_dep = declare_dependency(
  link_with: libnotes_util,
  include_directories: [
    include_directories('.'),
  ],
)
