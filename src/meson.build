popup_notes_sources = [
  'main-popup.vala',
]

popup_notes = executable(
  'xfce4-popup-notes',
  popup_notes_sources,
  c_args: ['-w'],
  dependencies: [
    glib,
    gtk,
  ],
  install: true,
  install_dir: get_option('prefix') / get_option('bindir'),
)

notes_settings_sources = [
  'defines.h',
  'main-settings-dialog.c',
]

settings = executable(
  'xfce4-notes-settings',
  notes_settings_sources,
  dependencies: [
    glib,
    gtk,
    libxfce4ui,
    libxfce4util,
    xfconf,
  ],
  install: true,
  install_dir: get_option('prefix') / get_option('bindir'),
)

plugin_sources = [
  'main-panel-plugin.vala',
]

plugin_install_subdir = 'xfce4' / 'panel' / 'plugins'

plugin_lib = shared_module(
  'notes',
  plugin_sources,
  gnu_symbol_visibility: 'hidden',
  vala_args: [
    '--vapidir', config_vapidir,
    '--vapidir', xfce_autostart_vapidir,
    '--pkg', 'config',
    '--pkg', 'xfce-autostart',
  ],
  c_args: [
    '-DG_LOG_DOMAIN="@0@"'.format('xfce4-notes-plugin'),
    '-w',
  ],
  include_directories: [
    include_directories('..'),
  ],
  dependencies: [
    gio,
    glib,
    gtk,
    gtksourceview,
    libcnotes_dep,
    libnotes_dep,
    libxfce4panel,
    libxfce4ui,
    libxfce4util,
    xfconf,
  ],
  install: true,
  install_dir: get_option('prefix') / get_option('libdir') / plugin_install_subdir,
)

status_icon_sources = [
  'main-status-icon.vala',
]

status_icon = executable(
  'xfce4-notes',
  status_icon_sources,
  vala_args: [
    '--vapidir', config_vapidir,
    '--vapidir', xfce_autostart_vapidir,
    '--pkg', 'config',
    '--pkg', 'xfce-autostart',
  ],
  c_args: [
    '-DG_LOG_DOMAIN="@0@"'.format('xfce4-notes-plugin'),
    '-w',
  ],
  include_directories: [
    include_directories('..'),
  ],
  dependencies: [
    gio,
    glib,
    gtk,
    gtksourceview,
    libcnotes_dep,
    libnotes_dep,
    libxfce4panel,
    libxfce4ui,
    libxfce4util,
    xfconf,
  ],
  install: true,
  install_dir: get_option('prefix') / get_option('bindir'),
)

i18n.merge_file(
  input: 'xfce4-notes-plugin.desktop.in',
  output: 'xfce4-notes-plugin.desktop',
  po_dir: '..' / 'po',
  type: 'desktop',
  install: true,
  install_dir: get_option('prefix') / get_option('datadir') / plugin_install_subdir,
)

i18n.merge_file(
  input: 'xfce4-notes.desktop.in',
  output: 'xfce4-notes.desktop',
  po_dir: '..' / 'po',
  type: 'desktop',
  install: true,
  install_dir: get_option('prefix') / get_option('datadir') / 'applications',
)

i18n.merge_file(
  input: 'xfce4-notes-autostart.desktop.in',
  output: 'xfce4-notes-autostart.desktop',
  po_dir: '..' / 'po',
  type: 'desktop',
  install: true,
  install_dir: get_option('prefix') / get_option('sysconfdir') / 'xdg' / 'autostart',
)
