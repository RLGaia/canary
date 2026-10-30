# Gaia Family server: build a small "custom map" OTBM that overlays chosen
# squares of the main map with extra tile flags (e.g. protection zone).
# Canary loads every data-otservbr-global/world/custom/*.otbm at startup,
# after the main map and before any creature spawns; a square in it replaces
# the main map's square, so the squares are copied byte for byte from the
# main map (ground, items and their attributes) and only the flags change.
#
# Usage (from the repository root):
#   python3 -I tools/family/otbm/overlay.py <main.otbm> <out.otbm> <flags> x,y,z [x,y,z ...]
#   flags: bits to add (1 = protection zone, 4 = no-PvP, 8 = no-logout, 16 = PvP zone)
# Writes <out>.otbm and the empty side files <out>-monster.xml, -npc.xml,
# -house.xml and -zones.xml next to it (the loader expects them).
import sys, struct, os

main, out, addflags = sys.argv[1], sys.argv[2], int(sys.argv[3])
want = set(tuple(map(int, a.split(','))) for a in sys.argv[4:])
data = open(main, 'rb').read()
n = len(data)

def unescape(j):
    """props of a node starting at j (after the type byte) -> (bytes, index of next FE/FF)"""
    buf = bytearray()
    while j < n:
        b = data[j]
        if b == 0xFD:
            buf.append(data[j + 1]); j += 2
        elif b in (0xFE, 0xFF):
            break
        else:
            buf.append(b); j += 1
    return bytes(buf), j

def escape(bs):
    o = bytearray()
    for b in bs:
        if b in (0xFD, 0xFE, 0xFF):
            o.append(0xFD)
        o.append(b)
    return bytes(o)

def node_end(j):
    """j points at an FE; return index just after its matching FF"""
    depth = 0
    while j < n:
        b = data[j]
        if b == 0xFD:
            j += 2; continue
        if b == 0xFE:
            depth += 1
        elif b == 0xFF:
            depth -= 1
            if depth == 0:
                return j + 1
        j += 1
    raise ValueError('unterminated node')

# root header: FE 00 + props (version, width, height, items major/minor)
assert data[4] == 0xFE and data[5] == 0x00
root_props, j = unescape(6)

found = {}
area = (0, 0, 0)
i = j
while i < n:
    b = data[i]
    if b == 0xFD:
        i += 2; continue
    if b == 0xFE:
        t = data[i + 1]
        props, k = unescape(i + 2)
        if t == 4 and len(props) >= 5:
            area = struct.unpack_from('<HHB', props, 0)
        elif t in (5, 14) and len(props) >= 2:
            pos = (area[0] + props[0], area[1] + props[1], area[2])
            if pos in want:
                end = node_end(i)
                children = data[k:end - 1]  # raw child nodes (items), already escaped
                p = bytearray(props)
                off = 2 + (4 if t == 14 else 0)  # x, y (+ house id)
                if off < len(p) and p[off] == 3:
                    fl = struct.unpack_from('<I', p, off + 1)[0] | addflags
                    struct.pack_into('<I', p, off + 1, fl)
                else:
                    p[off:off] = bytes([3]) + struct.pack('<I', addflags)
                found[pos] = (t, bytes(p), children)
                i = end
                continue
        i = k
        continue
    i += 1

missing = want - set(found)
if missing:
    sys.exit('squares not found in the main map: %s' % sorted(missing))

base = os.path.splitext(os.path.basename(out))[0]
def attr_str(code, s):
    s = s.encode()
    return bytes([code]) + struct.pack('<H', len(s)) + s

o = bytearray(b'\x00\x00\x00\x00')
o += b'\xfe\x00' + escape(root_props)
mapdata = (attr_str(1, 'Gaia Family overlay: ' + base) + attr_str(11, base + '-monster.xml') +
           attr_str(23, base + '-npc.xml') + attr_str(13, base + '-house.xml') + attr_str(24, base + '-zones.xml'))
o += b'\xfe\x02' + escape(mapdata)
by_area = {}
for (x, y, z), v in found.items():
    by_area.setdefault((x & ~0xFF, y & ~0xFF, z), []).append(((x, y, z), v))
for (ax, ay, az), tiles in sorted(by_area.items()):
    o += b'\xfe\x04' + escape(struct.pack('<HHB', ax, ay, az))
    for (x, y, z), (t, props, children) in sorted(tiles):
        p = bytearray(props)
        p[0], p[1] = x - ax, y - ay
        o += b'\xfe' + bytes([t]) + escape(bytes(p)) + children + b'\xff'
    o += b'\xff'
o += b'\xfe\x0c\xff'  # towns (none)
o += b'\xfe\x0f\xff'  # waypoints (none)
o += b'\xff'  # map data
o += b'\xff'  # root
open(out, 'wb').write(bytes(o))
d = os.path.dirname(out)
for suffix, body in (('monster', '<monsters />'), ('npc', '<npcs />'), ('house', '<houses />'), ('zones', '<zones />')):
    with open(os.path.join(d, '%s-%s.xml' % (base, suffix)), 'w') as f:
        f.write('<?xml version="1.0"?>\n%s\n' % body)
print('wrote %s: %d squares, flags +%d' % (out, len(found), addflags))
