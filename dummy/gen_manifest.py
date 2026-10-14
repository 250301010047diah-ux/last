import json, os

links = json.load(open('link.json'))
fj = set(json.load(open('link-json.json')).keys())

def fname(u):
    return os.path.basename(u.split('?')[0])

lines = []
lines.append('// GENERATED from link.json / link-json.json. Do not edit by hand.')
lines.append('class AssetEntry {')
lines.append('  final String image;')
lines.append('  final String? json;')
lines.append('  const AssetEntry({required this.image, this.json});')
lines.append('}')
lines.append('')
lines.append('const Map<String, AssetEntry> assetManifest = {')
for key, url in links.items():
    img = fname(url)
    if key in fj:
        json_val = "'%s.frames.json'" % img[:-5]
    else:
        json_val = 'null'
    lines.append("  %r: AssetEntry(image: %r, json: %s)," % (key, img, json_val))
lines.append('};')

out = '../lib/game/asset_manifest.dart'
with open(out, 'w') as f:
    f.write('\n'.join(lines))
print('wrote', out, 'entries', len(links))
