import json

with open('game js/assets.json', 'r', encoding='utf-8') as f:
    m = json.load(f)

lines = []
lines.append('// GENERATED from game js/assets.json (key -> image basename).')
lines.append('// Do not edit by hand.')
lines.append('')
lines.append('const Map<String, String> assetManifest = {')
for k, v in m.items():
    base = v.split('/')[-1]
    if base.endswith('.webp'):
        base = base[:-5]
    lines.append('  "%s": "%s",' % (k, base))
lines.append('};')

with open('lib/game/asset_manifest.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines) + '\n')

print('wrote', len(m), 'entries')
