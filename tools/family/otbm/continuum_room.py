# Gaia Family server: the "small crack in the space-time continuum" under Eclesius' house
# (The Scatterbrained Sorcerer Quest, Mission 3). Our map does not have it and neither wiki
# gives its position, so it is built from the three TibiaWiki EN screenshots
# ("Scatterbrained Sorcerer - Mission 3 - Lever 1/2/3.png"): a T-shaped cave room in the void,
# electric sparks over the upper part where the dwarf, the elf and the result appear, a row of
# three levers below them and a corridor where Eclesius waits.
#
#   python3 -I tools/family/otbm/continuum_room.py
# writes data-otservbr-global/world/custom/family-continuum.otbm (+ empty side files).
# Positions must match FS.scenePlaces in data-otservbr-global/scripts/family/scatterbrained_sorcerer.lua.
import os, random, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tiles

CX, CY, Z = 32290, 32290, 14  # the middle lever; floor 14 is empty there (checked with region.py)
VOID, VOID_AID = 7747, 42517  # void (Dream Realm look); the aid makes stepping on it fail (Lua)
FLOOR = [351, 352, 352, 353]  # cave earth (mostly cracked, as in the screenshots)
SPARKS = [5068, 5069, 5070]  # electric sparks (walkable)
# brown earth edge pieces: north, east, south, west edge and the four outer diagonal corners
EDGE = {'n': 4656, 'e': 4657, 's': 4658, 'w': 4659}
INNER = {'nw': 4660, 'ne': 4661, 'sw': 4662, 'se': 4663}  # small inner corners
MARGIN = 9  # void around the room, so the whole game window shows it


def floor_squares():
    sq = set()
    for dx in range(-4, 5):
        for dy in range(-3, 1):
            sq.add((dx, dy))  # upper part: sparks (rows -3..-1) and the lever row (0)
    for dx in range(-2, 3):
        for dy in range(1, 7):
            sq.add((dx, dy))  # corridor
    return sq


def build(seed=7):
    rnd = random.Random(seed)
    room = floor_squares()
    xs = [d[0] for d in room]; ys = [d[1] for d in room]
    out = []
    for dy in range(min(ys) - MARGIN, max(ys) + MARGIN + 1):
        for dx in range(min(xs) - MARGIN, max(xs) + MARGIN + 1):
            pos = (CX + dx, CY + dy, Z)
            if (dx, dy) not in room:
                out.append({'pos': pos, 'ground': VOID, 'groundAid': VOID_AID})
                continue
            items = []
            open_ = lambda ox, oy: (dx + ox, dy + oy) in room
            if not open_(0, -1): items.append(EDGE['n'])
            if not open_(1, 0): items.append(EDGE['e'])
            if not open_(0, 1): items.append(EDGE['s'])
            if not open_(-1, 0): items.append(EDGE['w'])
            # inner corners where the corridor meets the upper part
            if open_(0, -1) and open_(-1, 0) and not open_(-1, -1): items.append(INNER['nw'])
            if open_(0, -1) and open_(1, 0) and not open_(1, -1): items.append(INNER['ne'])
            if open_(0, 1) and open_(-1, 0) and not open_(-1, 1): items.append(INNER['sw'])
            if open_(0, 1) and open_(1, 0) and not open_(1, 1): items.append(INNER['se'])
            if dy <= -1 and rnd.random() < 0.8:
                items.append(rnd.choice(SPARKS))
            out.append({'pos': pos, 'ground': rnd.choice(FLOOR), 'items': items})
    return out


if __name__ == '__main__':
    root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
    out = os.path.join(root, 'data-otservbr-global', 'world', 'custom', 'family-continuum.otbm')
    squares = build()
    tiles.write(out, squares, 'Gaia Family: Eclesius\' crack in the space-time continuum')
    print('wrote %s: %d squares (%d floor)' % (out, len(squares), len(floor_squares())))
