"""Classify every walkable ground of the map into a terrain (Gaia Family server).

Input:  the server's appearances.dat (ground flag, friction, minimap colour),
        data/items/items.xml (names) and a usage count of grounds on the map
        (ground_usage.tsv: id, tiles, tiles on the surface; made by the dump
        described in README.md).
Output: data/scripts/family/mount_terrain_data.lua (ground id -> terrain).

Terrains: water, swamp, desert, snow, volcanic, wild (grass, forest, jungle,
open dirt and rock), town (roads, floors, buildings). "Underground" is not a
ground: the server treats wild and town ground below sea level (floor 8 and
deeper) as caves. Overrides at the bottom fix grounds checked by eye.
"""
import os, re, sys, collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
APP = os.path.join(ROOT, 'data', 'items', 'appearances.dat')
XML = os.path.join(ROOT, 'data', 'items', 'items.xml')
OUT = os.path.join(ROOT, 'data', 'scripts', 'family', 'mount_terrain_data.lua')


def varint(b, i):
    r = s = 0
    while True:
        c = b[i]; i += 1; r |= (c & 0x7F) << s; s += 7
        if c < 0x80:
            return r, i


def fields(b):
    i, n = 0, len(b)
    while i < n:
        k, i = varint(b, i); f, t = k >> 3, k & 7
        if t == 0:
            v, i = varint(b, i)
        elif t == 2:
            ln, i = varint(b, i); v = b[i:i + ln]; i += ln
        elif t == 5:
            v = b[i:i + 4]; i += 4
        elif t == 1:
            v = b[i:i + 8]; i += 8
        else:
            raise ValueError(t)
        yield f, t, v


def grounds():
    """id -> (friction, minimap colour) for every ground ("bank") object."""
    out = {}
    for f, t, v in fields(open(APP, 'rb').read()):
        if f != 1:
            continue
        oid = None; fr = None; col = None
        for g, tg, w in fields(v):
            if g == 1:
                oid = w
            elif g == 3:
                for h, th, x in fields(w):
                    if h == 1:
                        fr = 0
                        for a, ta, y in fields(x):
                            if a == 1:
                                fr = y
                    elif h == 30:
                        for a, ta, y in fields(x):
                            if a == 1:
                                col = y
        if oid is not None and fr is not None:
            out[oid] = (fr, col)
    return out


def names():
    out = {}
    for m in re.finditer(r'<item\s+(?:id="(\d+)"|fromid="(\d+)"\s+toid="(\d+)")[^>]*?name="([^"]*)"', open(XML, encoding='utf-8').read()):
        if m.group(1):
            out[int(m.group(1))] = m.group(4).lower()
        else:
            for i in range(int(m.group(2)), int(m.group(3)) + 1):
                out[i] = m.group(4).lower()
    return out


KEYWORDS = [  # first match wins
    ('town', ['roof', 'terracotta']),
    ('swamp', ['swamp', 'mud', 'muddy', 'bog', 'marsh', 'slime', 'lily pads', 'moor', 'tar', 'quagmire']),
    ('water', ['shallow water', 'ocean floor', 'sea floor', 'seabed', 'brook', 'stream', 'river', 'flooded', 'water', 'coral']),
    ('snow', ['snow', 'ice', 'frozen', 'frost', 'glacier', 'winterberries']),
    ('volcanic', ['lava', 'burnt', 'ash', 'scorch', 'magma', 'charred', 'volcan', 'cinder', 'ember', 'molten', 'sulphur']),
    ('desert', ['sand', 'dry floor', 'dune', 'salt']),
    ('wild', ['grass', 'moss', 'forest', 'jungle', 'leaves', 'flowers', 'soil', 'meadow', 'earth', 'dirt', 'gravel', 'rock', 'mould', 'mold', 'fungus', 'hive', 'mushroom', 'reed', 'branches']),
    ('town', ['floor', 'tile', 'marble', 'board', 'plank', 'parquet', 'carpet', 'cobble', 'path', 'road', 'pavement', 'brick', 'bridge', 'stairs', 'ramp', 'trapdoor', 'ladder']),
]
NOT_DESERT = ['sandstone', 'sandy tile']   # city floors of the desert towns

COLOURS = {  # minimap colour -> terrain, for grounds without a telling name
    24: 'wild', 12: 'wild', 140: 'swamp', 207: 'desert', 215: 'snow', 179: 'snow',
    51: 'water', 192: 'volcanic', 121: 'wild', 114: 'wild', 86: 'wild', 129: 'town',
    210: 'town', 186: 'town', 0: 'town', None: 'town',
}

# Checked by eye on rendered samples (see README.md): id -> terrain.
OVERRIDES = {
    24605: 'wild',   # grass drawn like a floor (minimap grey), around 33602,31022
}


def classify(gid, fr, col, name):
    if gid in OVERRIDES:
        return OVERRIDES[gid], 'override'
    if fr >= 250 and fr < 300:
        return 'water', 'friction'          # walking under water
    for terrain, words in KEYWORDS:
        for w in words:
            if re.search(r'\b' + re.escape(w), name):
                if terrain == 'desert' and any(n in name for n in NOT_DESERT):
                    continue
                return terrain, 'name:' + w
    return COLOURS.get(col, 'town'), 'colour:%s' % col


def near(gid, col, name):
    """Terrain an unwalkable ground lends to the land around it, or None."""
    def has(*words):
        return any(re.search(r'\b' + w, name) for w in words)
    if col == 140 or has('swamp', 'bog', 'tar'):
        return 'swamp'
    if col == 192 or has('lava', 'sulphur', 'magma'):
        return 'volcanic'
    if col == 51 or (has('water') and not has('ice')):
        return 'water'
    return None


def main():
    g = grounds()
    nm = names()
    usage = {}
    path = os.path.join(HERE, 'ground_usage.tsv')
    if os.path.exists(path):
        for l in open(path):
            p = l.split()
            usage[int(p[0])] = (int(p[1]), int(p[2]))
    result = {}
    why = {}
    nearby = {}
    for gid, (fr, col) in sorted(g.items()):
        if fr <= 1:          # not walkable
            t = near(gid, col, nm.get(gid, ''))
            if t:
                nearby[gid] = t
            continue
        t, reason = classify(gid, fr, col, nm.get(gid, ''))
        result[gid] = t
        why[gid] = reason
    if '--report' in sys.argv:
        stat = collections.Counter()
        for gid, t in result.items():
            stat[t] += usage.get(gid, (0, 0))[0]
        print(stat)
        for gid, t in sorted(result.items(), key=lambda kv: -usage.get(kv[0], (0, 0))[0]):
            print(gid, t, why[gid], usage.get(gid, (0, 0)), g[gid], nm.get(gid, ''), sep='\t')
        return result
    def section(f, title, mapping):
        by = collections.defaultdict(list)
        for gid, t in mapping.items():
            by[t].append(gid)
        f.write('\t%s = {\n' % title)
        for t in sorted(by):
            ids = sorted(by[t])
            f.write('\t\t%s = {\n' % t)
            for i in range(0, len(ids), 16):
                f.write('\t\t\t' + ', '.join(str(x) for x in ids[i:i + 16]) + ',\n')
            f.write('\t\t},\n')
        f.write('\t},\n')
        return {t: len(v) for t, v in by.items()}

    with open(OUT, 'w') as f:
        f.write('-- Generated by tools/family/mount_terrain/classify.py. Do not edit by hand.\n')
        f.write('-- ground: walkable ground item id -> terrain.\n')
        f.write('-- near: unwalkable ground (sea, swamp water, lava) -> terrain it lends to the land\n')
        f.write('-- around it (data/scripts/family/mount_terrain.lua decides how far).\n')
        f.write('return {\n')
        a = section(f, 'ground', result)
        b = section(f, 'near', nearby)
        f.write('}\n')
    print('wrote', OUT, a, b)
    return result


if __name__ == '__main__':
    main()
