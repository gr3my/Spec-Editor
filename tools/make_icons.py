#!/usr/bin/env python3
"""Build mod/se_icons_data.h: embed icons/*.png as byte arrays for the palette.

The editor draws one small icon per placeable class (se_render.cpp LoadIcons decodes
them once with WIC). Entry names are the lookup keys: IconTexture() tries the item
name, then "aa_se_" + name without its "LE_" prefix, so keep icon filenames aligned
with your catalogue (tools/make_catalogue.py).

    python SpecEditor/tools/make_icons.py

Reads icons/*.png (sorted by filename), writes mod/se_icons_data.h with k0..kN byte
arrays plus the {name, data, size} table the C++ iterates. Only the Python standard
library is used.
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ICONS = os.path.join(HERE, '..', 'icons')
OUT = os.path.join(HERE, '..', 'mod', 'se_icons_data.h')


def main() -> None:
    files = sorted(f for f in os.listdir(ICONS) if f.lower().endswith('.png'))
    if not files:
        raise SystemExit('no .png files in ' + ICONS)
    arrays = []
    rows = []
    for i, fn in enumerate(files):
        with open(os.path.join(ICONS, fn), 'rb') as fh:
            data = fh.read()
        arrays.append('static const unsigned char k%d[] = {%s};'
                      % (i, ','.join(str(b) for b in data)))
        rows.append('    { "%s", k%d, %d },' % (os.path.splitext(fn)[0], i, len(data)))
    body = ('// Placeholder palette art (see icons/README.md). Built by tools/make_icons.py\n'
            '// from icons/*.png -- entry names are the IconTexture() lookup keys, so keep\n'
            '// icon filenames aligned with your catalogue. Do not edit by hand.\n'
            '#pragma once\n'
            'namespace se { namespace icons {\n'
            + '\n'.join(arrays) + '\n'
            + 'struct Embedded { const char* name; const unsigned char* data; unsigned size; };\n'
            + 'static const Embedded kAll[] = {\n'
            + '\n'.join(rows) + '\n'
            + '};\n'
            + 'static const int kCount = %d;\n} }\n' % len(files))
    with open(OUT, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(body)
    print('wrote', OUT, len(files), 'icons')


if __name__ == '__main__':
    main()
