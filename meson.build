project(
  'xfce4-notes-plugin',
  'vala', 'c',
  version: '1.11.2-dev',
  license: 'GPL-2.0-or-later',
  meson_version: '>= 0.54.0',
  default_options: [
    'c_std=gnu11',
    'buildtype=debugoptimized',
    'warning_level=2',
  ]
)

project_namespace = 'panel-plugins'
pkgdatadir = get_option('prefix') / get_option('datadir') / 'xfce4' / 'notes'
copyright_year = '2025'

vala = meson.get_compiler('vala')
cc = meson.get_compiler('c')
pkgconfig = import('pkgconfig')
gnome = import('gnome')
i18n = import('i18n')

dependency_versions = {
  'vala': '>= 0.46.0',
  'glib': '>= 2.50.0',
  'gtk': '>= 3.22.0',
  'xfce4': '>= 4.16.0',
  'gtksourceview': '>= 4.0.0',
}

if not vala.version().version_compare(dependency_versions['vala'])
  error('valac @0@ required!'.format(dependency_versions['vala']))
endif

glib = dependency('glib-2.0', version: dependency_versions['glib'])
gio = dependency('gio-2.0', version: dependency_versions['glib'])
gtk = dependency('gtk+-3.0', version: dependency_versions['gtk'])
libxfce4panel = dependency('libxfce4panel-2.0', version: dependency_versions['xfce4'])
libxfce4ui = dependency('libxfce4ui-2', version: dependency_versions['xfce4'])
libxfce4util = dependency('libxfce4util-1.0', version: dependency_versions['xfce4'])
xfconf = dependency('libxfconf-0', version: dependency_versions['xfce4'])
gtksourceview = dependency('gtksourceview-4', version: dependency_versions['gtksourceview'])

version_parts = meson.project_version().split('-dev')[0].split('.')
version_short = '@0@.@1@'.format(version_parts[0], version_parts[1])

extra_cflags = [
  '-DPACKAGE="@0@"'.format(meson.project_name()),
  '-DPACKAGE_NAME="@0@"'.format(meson.project_name()),
  '-DPACKAGE_VERSION="@0@"'.format(meson.project_version()),
  '-DVERSION="@0@"'.format(meson.project_version()),
  '-DVERSION_SHORT="@0@"'.format(version_short),
  '-DPACKAGE_STRING="@0@ @1@"'.format(meson.project_name(), meson.project_version()),
  '-DPACKAGE_DATADIR="@0@"'.format(pkgdatadir),
  '-DPKGDATADIR="@0@"'.format(pkgdatadir),
  '-DCOPYRIGHT_YEAR="@0@"'.format(copyright_year),
  '-DPACKAGE_LOCALE_DIR="@0@"'.format(get_option('prefix') / get_option('localedir')),
  '-DPACKAGE_URL="https://docs.xfce.org/@0@/@1@/start"'.format(project_namespace, meson.project_name()),
  '-DPACKAGE_BUGREPORT="https://gitlab.xfce.org/@0@/@1@/-/issues"'.format(project_namespace, meson.project_name()),
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-DPREFIX="@0@"'.format(get_option('prefix')),
  '-DBINDIR="@0@"'.format(get_option('prefix') / get_option('bindir')),
  '-DDATADIR="@0@"'.format(get_option('prefix') / get_option('datadir')),
  '-DDOCDIR="@0@"'.format(get_option('prefix') / 'doc' / meson.project_name()),
  '-DINCLUDEDIR="@0@"'.format(get_option('prefix') / get_option('includedir')),
  '-DLIBDIR="@0@"'.format(get_option('prefix') / get_option('libdir')),
  '-DLIBEXECDIR="@0@"'.format(get_option('prefix') / get_option('libexecdir')),
  '-DLOCALEDIR="@0@"'.format(get_option('prefix') / get_option('localedir')),
  '-DLOCALSTATEDIR="@0@"'.format(get_option('prefix') / get_option('localstatedir')),
  '-DSBINDIR="@0@"'.format(get_option('prefix') / get_option('sbindir')),
  '-DSYSCONFDIR="@0@"'.format(get_option('prefix') / get_option('sysconfdir')),
  '-DHAVE_XFCE_REVISION_H=1',
]

extra_valaflags = [
  '--enable-deprecated',
  '--define=MESON_BUILD',
]

# See https://github.com/mesonbuild/meson/pull/12597.
add_project_arguments('-w', language: 'c')

add_project_arguments(extra_cflags, language: 'c')
add_project_arguments(extra_valaflags, language: 'vala')

xfce_revision_h = vcs_tag(
  command: ['git', 'rev-parse', '--short', 'HEAD'],
  fallback: 'UNKNOWN',
  input: 'xfce-revision.h.in',
  output: 'xfce-revision.h',
  replace_string: '@REVISION@',
)

subdir('lib')
subdir('libc')
subdir('src')
subdir('data')
subdir('po')
