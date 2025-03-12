libcnotes_sources = [
  'xfce-autostart.c',
  'xfce-autostart.h',
]

xfce_autostart_vapidir = meson.current_source_dir()

libcnotes = static_library(
  'cnotes',
  libcnotes_sources,
  dependencies: [
    gio,
    glib,
    libxfce4util,
  ],
  install: false,
)

libcnotes_dep = declare_dependency(
  link_with: libcnotes,
  include_directories: [
    include_directories('.'),
  ],
)
