# Gaia Family server: the two small Krailos caves our map lacks (Krailos Quest, 2026-11-22).
# Both "mud stain" holes are on our map (floor change down), but floor 8 below them is empty:
#   * the hyaena den below 33549,31662,7 (The Great Hunger: the sleeping hyaena; TibiaWiki EN
#     "go down this pitfall", BR screenshots Hyena1-3: a small sandy cave in red rock);
#   * A Runaway Goblin's hideout below 33528,31672,7 (Revolt of the Goblins; TibiaWiki BR
#     33526,31671,8 "Desça no local indicado", screenshot Rungoblin: the same kind of cave).
# Built with the ground Krailos' own caves use (dry floor, mountain rock, debris at the walls).
# The square under each hole is a "hole in the ceiling" (386) to climb back up with a rope.
#
#   python3 -I tools/family/otbm/krailos_caves.py
# writes data-otservbr-global/world/custom/family-krailos.otbm (+ side files; the -npc.xml spawns
# A Runaway Goblin and is written here too). Positions must match FamilyKrailos (HYAENA, RUNAWAY).
import os, random, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tiles

Z = 8
ROCK = 1128  # mountain (Krailos cave fill)
FLOOR = [22355, 22356, 22357]  # dry floor
ROPE = 386  # dirt floor, "There is a hole in the ceiling."
DEBRIS = [6475, 6476, 6479, 6481, 6482]
SLEEPING_HYAENA = 22664
MARGIN = 3

CAVES = [
    {  # the hyaena den
        'hole': (33549, 31662),
        'floor': [(x, y) for x in range(33546, 33554) for y in range(31660, 31666)
                  if (x, y) not in ((33546, 31660), (33553, 31660), (33546, 31665), (33553, 31665), (33547, 31665))],
        'items': {(33551, 31664): [SLEEPING_HYAENA]},
    },
    {  # A Runaway Goblin's hideout
        'hole': (33528, 31672),
        'floor': [(x, y) for x in range(33524, 33532) for y in range(31669, 31676)
                  if (x, y) not in ((33524, 31669), (33531, 31669), (33524, 31675), (33531, 31675), (33525, 31675))],
        'items': {},
    },
]
RUNAWAY = (33526, 31671, Z)


def build(seed=11):
    rnd = random.Random(seed)
    out = {}
    for cave in CAVES:
        room = set(cave['floor'])
        room.add(cave['hole'])
        xs = [p[0] for p in room]; ys = [p[1] for p in room]
        for y in range(min(ys) - MARGIN, max(ys) + MARGIN + 1):
            for x in range(min(xs) - MARGIN, max(xs) + MARGIN + 1):
                pos = (x, y, Z)
                if (x, y) not in room:
                    out.setdefault(pos, {'pos': pos, 'ground': ROCK, 'items': []})
                    continue
                items = list(cave['items'].get((x, y), []))
                wall = any((x + dx, y + dy) not in room for dx in (-1, 0, 1) for dy in (-1, 0, 1))
                if (x, y) == cave['hole']:
                    ground = ROPE
                else:
                    ground = rnd.choice(FLOOR)
                    if wall and not items and rnd.random() < 0.5:
                        items.append(rnd.choice(DEBRIS))
                out[pos] = {'pos': pos, 'ground': ground, 'items': items}
    return list(out.values())


NPC_XML = '''<?xml version="1.0"?>
<npcs>
	<npc centerx="%d" centery="%d" centerz="%d" radius="1">
		<npc name="A Runaway Goblin" x="0" y="0" z="%d" spawntime="60" />
	</npc>
</npcs>
''' % (RUNAWAY[0], RUNAWAY[1], RUNAWAY[2], RUNAWAY[2])

if __name__ == '__main__':
    root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
    out = os.path.join(root, 'data-otservbr-global', 'world', 'custom', 'family-krailos.otbm')
    squares = build()
    tiles.write(out, squares, 'Gaia Family: Krailos hyaena den and runaway goblin hideout')
    if '--with-goblin' in sys.argv:
        with open(out.replace('.otbm', '-npc.xml'), 'w') as f:
            f.write(NPC_XML)
    print('wrote %s: %d squares' % (out, len(squares)))
