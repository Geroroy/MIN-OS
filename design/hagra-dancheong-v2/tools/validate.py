#!/usr/bin/env python3
"""Validate handoff integrity; does not claim to execute QML or labwc."""
from pathlib import Path
import json, re, xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
tokens = json.loads((root / 'tokens.json').read_text())
theme = (root / 'qml/Theme.qml').read_text()
errors = []
for key, value in tokens['color'].items():
    if not re.fullmatch(r'#[0-9a-fA-F]{6}', value):
        errors.append('Invalid color: ' + key)
    if f'property color {key}: "{value}"' not in theme:
        errors.append('Theme color mismatch: ' + key)
for key, value in tokens['dimension'].items():
    if f'property int {key}: {value}' not in theme:
        errors.append('Theme dimension mismatch: ' + key)
for path in sorted((root / 'assets').glob('*.svg')):
    tree = ET.parse(path)
    if 'viewBox' not in tree.getroot().attrib:
        errors.append('Missing viewBox: ' + path.name)
    for elem in tree.iter():
        for attr, value in elem.attrib.items():
            if attr.endswith('href') and not value.startswith('#'):
                errors.append('External SVG asset: ' + path.name)
for path in (root / 'qml').glob('*.qml'):
    for rel in re.findall(r'"(\.\./assets/[^"+]+\.svg)"', path.read_text()):
        if not (path.parent / rel).exists():
            errors.append('Missing QML source: ' + rel)

def luminance(color):
    v = [int(color[i:i+2], 16)/255 for i in (1,3,5)]
    c = [x/12.92 if x <= .04045 else ((x+.055)/1.055)**2.4 for x in v]
    return sum(x*y for x,y in zip(c, (.2126,.7152,.0722)))

c = tokens['color']
for fg, bg in [('text','surface'),('textMuted','surface'),('titleText','titleActive'),
               ('titleInactiveText','titleInactive'),('text','selection'),('accentText','accent'),
               ('panelText','panel'),('sidebarText','sidebar'),('danger','surface')]:
    a,b = sorted([luminance(c[fg]),luminance(c[bg])])
    ratio = (b+.05)/(a+.05)
    print(f'{fg} on {bg}: {ratio:.2f}:1')
    if ratio < 4.5:
        errors.append('Insufficient contrast: ' + fg + '/' + bg)

required = ['CLAUDE_TASK.md','docs/DESIGN_SPEC.md','docs/INTEGRATION.md',
            'reference/dancheong-cranes.jpg','reference/dancheong-eaves.jpg','assets/wallpaper.png','asset-sheet.png']
for rel in required:
    if not (root / rel).is_file():
        errors.append('Missing deliverable: ' + rel)
if errors:
    raise SystemExit('\n'.join(errors))
print('PASS: tokens, SVG XML, literal QML asset paths, contrast, required files.')
print('NOT RUN: Qt execution, qmllint, labwc theme loading, OS build or boot.')
