# Gaia Family server: the small dworc cave of the Treasure Hunt Quest (missions 1-2), missing on our map.
# Floor 8 under the dig spot (32843,32774,7; 17 squares west of the giant tree carving at 32860,32774,7)
# is solid earth on our map. Built from TibiaWiki BR (Missoes 1-2: rope down, break the fence with a
# melee weapon, the pot in the north, the dice to the east, the teleporter, the remains of a pirate)
# and TibiaWiki EN (screenshots Th1 "voodoo doll in the pot", Dice Room "two dice, the teleporter, two
# dice, behind bars, levers on the west", Treasure Map Part 1 Location "the remains").
#
#   python3 -I tools/family/otbm/treasure_hunt_cave.py
# writes data-otservbr-global/world/custom/family-treasure-hunt.otbm (+ side files; the -monster.xml
# spawns the dworcs). Positions must match FamilyTreasureHunt (lib/others/family_treasure_hunt.lua).
import os, random, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tiles

Z = 8
FILL = 4427  # earth (what our map already has here)
FLOOR = [351, 352, 353, 354, 355]  # dirt floor
ROPE = 386  # dirt floor, "There is a hole in the ceiling."
DEBRIS = [6475, 6476, 6479, 6481, 6482]
FENCE = 2295  # wooden bars, "They already have some cracks and look rather fragile."
POT = 2003  # campfire (pot)
LEVER = 2772
DIE = 5792  # die showing 1 (5792-5797 = 1-6)
BARS = 2184  # bars, north-south line
FORCEFIELD = 1949
REMAINS = 9180
WEB = 182
BONES = [3115, 3116]

HOLE = (32843, 32774)
FENCE_POS = (32847, 32775)
POT_POS = (32853, 32769)
LEVERS = [(32859, 32772), (32859, 32773), (32859, 32777), (32859, 32778)]  # north to south
DICE = [(32862, 32772), (32862, 32773), (32862, 32777), (32862, 32778)]
GATE = (32861, 32775)  # the code teleporter
GATE_AID = 48789
ARRIVAL = (32867, 32772)
EXIT = (32867, 32775)  # back to the main cave
EXIT_AID = 48790
REMAINS_POS = (32871, 32771)


def rooms():
    entrance = {(x, y) for x in range(32841, 32846) for y in range(32772, 32778)}
    entrance -= {(32841, 32772), (32845, 32772), (32841, 32777), (32845, 32777)}
    corridor = {(32846, 32775), (32847, 32775), (32848, 32775), (32858, 32775), (32859, 32775)}
    main = {(x, y) for x in range(32848, 32859) for y in range(32767, 32783)
            if ((x - 32853) / 4.6) ** 2 + ((y - 32774.5) / 6.6) ** 2 <= 1}
    dice_walk = {(32860, y) for y in range(32771, 32780)} | set(LEVERS)
    dice_back = {(32862, y) for y in range(32771, 32780)} | {GATE}
    remains = {(x, y) for x in range(32866, 32874) for y in range(32768, 32777)}
    remains -= {(32866, 32768), (32873, 32768), (32866, 32776), (32873, 32776), (32873, 32775), (32872, 32776)}
    return entrance | corridor | main | dice_walk | dice_back | remains


def build(seed=18):
    rnd = random.Random(seed)
    room = rooms()
    special = {HOLE: [], FENCE_POS: [FENCE], POT_POS: [POT], GATE: [(FORCEFIELD, GATE_AID)],
               EXIT: [(FORCEFIELD, EXIT_AID)], REMAINS_POS: [REMAINS]}
    for p in LEVERS:
        special[p] = [LEVER]
    for p in DICE:
        special[p] = [DIE]
    for y in range(32771, 32780):
        if (32861, y) != GATE:
            special[(32861, y)] = [BARS]
    decor = {(32870, 32771): [WEB], (32872, 32769): [BONES[0]], (32868, 32770): [BONES[1]],
             (32850, 32770): [WEB], (32856, 32780): [BONES[0]]}
    out = {}
    xs = [p[0] for p in room]; ys = [p[1] for p in room]
    for y in range(min(ys) - 2, max(ys) + 3):
        for x in range(min(xs) - 2, max(xs) + 3):
            pos = (x, y, Z)
            if (x, y) not in room and (x, y) not in special:
                out[pos] = {'pos': pos, 'ground': FILL, 'items': []}
                continue
            if (x, y) == HOLE:
                out[pos] = {'pos': pos, 'ground': ROPE, 'items': []}
                continue
            items = list(special.get((x, y), decor.get((x, y), [])))
            wall = any((x + dx, y + dy) not in room for dx in (-1, 0, 1) for dy in (-1, 0, 1))
            if wall and not items and (x, y) not in special and x < 32859 and rnd.random() < 0.45:
                items.append(rnd.choice(DEBRIS))
            out[pos] = {'pos': pos, 'ground': rnd.choice(FLOOR), 'items': items}
    return list(out.values())


MONSTER_XML = '''<?xml version="1.0"?>
<monsters>
	<monster centerx="32853" centery="32775" centerz="8" radius="3">
		<monster name="Dworc Voodoomaster" x="-2" y="-3" z="0" spawntime="90" />
		<monster name="Dworc Voodoomaster" x="2" y="3" z="0" spawntime="90" />
		<monster name="Dworc Fleshhunter" x="2" y="-3" z="0" spawntime="90" />
		<monster name="Dworc Fleshhunter" x="-2" y="3" z="0" spawntime="90" />
		<monster name="Dworc Venomsniper" x="0" y="0" z="0" spawntime="90" />
	</monster>
	<monster centerx="32843" centery="32775" centerz="8" radius="1">
		<monster name="Dworc Fleshhunter" x="1" y="1" z="0" spawntime="90" />
	</monster>
</monsters>
'''

if __name__ == '__main__':
    root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
    out = os.path.join(root, 'data-otservbr-global', 'world', 'custom', 'family-treasure-hunt.otbm')
    squares = build()
    tiles.write(out, squares, 'Gaia Family: Treasure Hunt Quest dworc cave')
    with open(out.replace('.otbm', '-monster.xml'), 'w') as f:
        f.write(MONSTER_XML)
    print('wrote %s: %d squares' % (out, len(squares)))
