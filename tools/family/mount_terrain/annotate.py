"""Write each mount's terrains into its name in data/XML/mounts.xml.

The outfit window shows mount names, so "Water Buffalo (Swamp/Water)" tells
the player the home and related terrain (data/scripts/family/mount_terrain.lua).
Reads the table Family.mountTerrainMounts from that script. Safe to run again:
an old note is replaced. --strip puts the original names back.
"""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
LUA = os.path.join(ROOT, 'data', 'scripts', 'family', 'mount_terrain.lua')
XML = os.path.join(ROOT, 'data', 'XML', 'mounts.xml')

LABEL = {'water': 'Water', 'swamp': 'Swamp', 'desert': 'Desert', 'snow': 'Snow', 'volcanic': 'Volcanic',
         'wild': 'Wild', 'caves': 'Caves', 'town': 'Town', 'sky': 'Sky'}
NOTE = re.compile(r' \((?:%s)(?:/(?:%s))?\)$' % ('|'.join(LABEL.values()), '|'.join(LABEL.values())))
COMMENT = ('\t<!-- FAMILY: mount names carry their terrains, e.g. "(Swamp/Water)" = faster in swamps (home)\n'
           '\t     and water (related). Written by tools/family/mount_terrain/annotate.py from\n'
           '\t     data/scripts/family/mount_terrain.lua. -->\n')


def table():
    out = {}
    for m in re.finditer(r'\[(\d+)\] = (?:"(sky)"|\{ "(\w+)", "(\w+)" \})', open(LUA).read()):
        mid = int(m.group(1))
        out[mid] = ['sky'] if m.group(2) else [m.group(3), m.group(4)]
    return out


def main():
    strip = '--strip' in sys.argv
    t = table()
    s = open(XML, encoding='utf-8').read()
    seen = set()

    def repl(m):
        mid = int(m.group(2))
        name = NOTE.sub('', m.group(3))
        if not strip:
            if mid not in t:
                raise SystemExit('mount %d (%s) has no terrain in mount_terrain.lua' % (mid, name))
            seen.add(mid)
            name = '%s (%s)' % (name, '/'.join(LABEL[x] for x in t[mid]))
        return m.group(1) + name + m.group(4)

    s = re.sub(r'(<mount id="(\d+)" clientid="\d+" name=")([^"]*)(")', repl, s)
    s = s.replace(COMMENT, '')
    if not strip:
        s = s.replace('<mounts>\n', '<mounts>\n' + COMMENT, 1)
        missing = set(t) - seen
        if missing:
            raise SystemExit('ids in mount_terrain.lua but not in mounts.xml: %s' % sorted(missing))
    open(XML, 'w', encoding='utf-8').write(s)
    print('mounts.xml:', 'stripped' if strip else '%d names annotated' % len(seen))


if __name__ == '__main__':
    main()
