# Gaia Family server: write a small "custom map" OTBM with new squares (squares the main map
# does not have). Canary loads every data-otservbr-global/world/custom/*.otbm at startup, after
# the main map and before any creature spawns. Companion of overlay.py, which copies squares
# that already exist.
#
# Use from Python:
#   import tiles
#   tiles.write(out_path, [{"pos": (x, y, z), "ground": id, "groundAid": aid or None,
#                           "items": [id, (id, aid), ...], "flags": 0}, ...], "description")
# or from the shell with a JSON list of the same squares ("pos" as [x, y, z]):
#   python3 -I tools/family/otbm/tiles.py <out.otbm> <squares.json>
# Writes <out>.otbm and the empty side files <out>-monster.xml, -npc.xml, -house.xml and
# -zones.xml next to it (the loader expects them).
import json, os, struct, sys

# root header copied from our main map (otservbr.otbm), as overlay.py does: OTBM version 4,
# map size 35143 x 34812, items version 4.4
ROOT_PROPS = struct.pack('<IHHII', 4, 35143, 34812, 4, 4)


def escape(bs):
    o = bytearray()
    for b in bs:
        if b in (0xFD, 0xFE, 0xFF):
            o.append(0xFD)
        o.append(b)
    return bytes(o)


def attr_str(code, s):
    s = s.encode()
    return bytes([code]) + struct.pack('<H', len(s)) + s


def item_node(item_id, aid=None):
    props = struct.pack('<H', item_id)
    if aid:
        props += bytes([4]) + struct.pack('<H', aid)  # OTBM_ATTR_ACTION_ID
    return b'\xfe\x06' + escape(props) + b'\xff'


def write(out, squares, description='Gaia Family custom map', root_props=ROOT_PROPS):
    base = os.path.splitext(os.path.basename(out))[0]
    o = bytearray(b'\x00\x00\x00\x00')
    o += b'\xfe\x00' + escape(root_props)
    mapdata = (attr_str(1, description) + attr_str(11, base + '-monster.xml') + attr_str(23, base + '-npc.xml') +
               attr_str(13, base + '-house.xml') + attr_str(24, base + '-zones.xml'))
    o += b'\xfe\x02' + escape(mapdata)
    by_area = {}
    for sq in squares:
        x, y, z = sq['pos']
        by_area.setdefault((x & ~0xFF, y & ~0xFF, z), []).append(sq)
    for (ax, ay, az), sqs in sorted(by_area.items()):
        o += b'\xfe\x04' + escape(struct.pack('<HHB', ax, ay, az))
        for sq in sorted(sqs, key=lambda s: (s['pos'][1], s['pos'][0])):
            x, y, z = sq['pos']
            props = bytes([x - ax, y - ay])
            if sq.get('flags'):
                props += bytes([3]) + struct.pack('<I', sq['flags'])  # OTBM_ATTR_TILE_FLAGS
            children = b''
            if sq.get('groundAid'):
                children += item_node(sq['ground'], sq['groundAid'])
            elif sq.get('ground'):
                props += bytes([9]) + struct.pack('<H', sq['ground'])  # OTBM_ATTR_ITEM (inline ground)
            for it in sq.get('items', []):
                children += item_node(*it) if isinstance(it, (list, tuple)) else item_node(it)
            o += b'\xfe\x05' + escape(props) + children + b'\xff'
        o += b'\xff'
    o += b'\xfe\x0c\xff'  # towns (none)
    o += b'\xfe\x0f\xff'  # waypoints (none)
    o += b'\xff'  # map data
    o += b'\xff'  # root
    with open(out, 'wb') as f:
        f.write(bytes(o))
    d = os.path.dirname(out) or '.'
    for suffix, body in (('monster', '<monsters />'), ('npc', '<npcs />'), ('house', '<houses />'), ('zones', '<zones />')):
        with open(os.path.join(d, '%s-%s.xml' % (base, suffix)), 'w') as f:
            f.write('<?xml version="1.0"?>\n%s\n' % body)
    return len(squares)


if __name__ == '__main__':
    out, spec = sys.argv[1], json.load(open(sys.argv[2]))
    for sq in spec:
        sq['pos'] = tuple(sq['pos'])
    print('wrote %s: %d squares' % (out, write(out, spec)))
