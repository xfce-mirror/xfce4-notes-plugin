sizes = [22, 24, 32]
names = [
  'org.xfce.notes',
  'org.xfce.notes.tray',
  'org.xfce.panel.notes',
]
foreach size : sizes
  foreach name : names
    install_data(
      '@0@x@0@'.format(size) / '@0@.png'.format(name),
      install_dir: get_option('prefix') / get_option('datadir') / 'icons' / 'hicolor' / '@0@x@0@'.format(size) / 'apps',
    )
  endforeach
endforeach

names_16x16 = names + [
  'org.xfce.notes.menu',
  'org.xfce.notes.menu-active',
]
foreach name : names_16x16
  install_data(
    '16x16' / '@0@.png'.format(name),
    install_dir: get_option('prefix') / get_option('datadir') / 'icons' / 'hicolor' / '16x16' / 'apps',
  )
endforeach

names_scalable = names + [
  'org.xfce.notes.logo',
]
foreach name : names_scalable
  install_data(
    'scalable' / '@0@.svg'.format(name),
    install_dir: get_option('prefix') / get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps',
  )
endforeach
