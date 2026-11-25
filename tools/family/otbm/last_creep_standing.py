# Gaia Family server: Kurik's challenge arena of Last Creep Standing (2026-11-25), missing on our map.
# Built from TibiaWiki EN ("Last Creep Standing/Spoiler": the creature/direction diagram, the screenshot
# of the chequered hall with Slime Puddles, the prize room picture) and TibiaWiki BR (the 8 statue
# directions). Floor 14 at 33050-33095, 32250-32295 is empty on our map. Sizes and distances are ours.
#
#   python3 -I tools/family/otbm/last_creep_standing.py
# writes data-otservbr-global/world/custom/family-last-creep-standing.otbm (+ side files; the
# -monster.xml has the Slime Puddles). Positions must match FamilyLastCreep
# (data-otservbr-global/lib/others/family_last_creep.lua).
import os, random, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tiles

Z = 14
FILL = 4427  # earth
MAGIC = list(range(12285, 12294))  # magic tiles (they change colour by themselves)
STONE = 419  # stone tile
FORCEFIELD = 1949
CHEST = 2472
CENTER = (33073, 32273)
HALL = (33064, 32264, 33082, 32282)  # interior
# direction -> (teleporter, dummy, dummy item)  (EN diagram; BR: Omruc = the pharaoh dummy)
DIRS = {
    'northwest': ((33066, 32266), (33065, 32265), 12047),  # pharaoh (Thalas)
    'north': ((33073, 32264), (33073, 32263), 12053),  # carniphila
    'northeast': ((33080, 32266), (33081, 32265), 12048),  # quara hydromancer
    'west': ((33064, 32273), (33063, 32273), 12051),  # nightstalker
    'east': ((33082, 32273), (33083, 32273), 12052),  # lost soul
    'southwest': ((33066, 32280), (33065, 32281), 12050),  # zombie
    'south': ((33073, 32282), (33073, 32283), 12049),  # mutated rat
    'southeast': ((33080, 32280), (33081, 32281), 12056),  # blightwalker
}
ORDER = ['northwest', 'north', 'northeast', 'west', 'east', 'southwest', 'south', 'southeast']
FIRST_TP_AID = 48809  # 48809-48816 in ORDER
WAIT = (33053, 32252, 33057, 32256)
PRIZE = (33088, 32252, 33092, 32258)
PRIZE_CHEST = (33090, 32252)
PRIZE_EXIT = (33090, 32258)
PRIZE_EXIT_AID = 48817
SLIMES = [(33068, 32270), (33078, 32270), (33068, 32276), (33078, 32276), (33075, 32267), (33071, 32279)]


def build(seed=21):
    rnd = random.Random(seed)
    out = {}

    def put(x, y, ground, items=()):
        out[(x, y)] = {'pos': (x, y, Z), 'ground': ground, 'items': list(items)}

    for x in range(33050, 33096):
        for y in range(32250, 32296):
            put(x, y, FILL)
    x1, y1, x2, y2 = HALL
    for x in range(x1, x2 + 1):
        for y in range(y1, y2 + 1):
            put(x, y, rnd.choice(MAGIC))
    for d in ORDER:
        tp, dummy, did = DIRS[d]
        aid = FIRST_TP_AID + ORDER.index(d)
        put(tp[0], tp[1], rnd.choice(MAGIC), [(FORCEFIELD, aid)])
        put(dummy[0], dummy[1], STONE, [did])
    for box in (WAIT, PRIZE):
        for x in range(box[0], box[2] + 1):
            for y in range(box[1], box[3] + 1):
                put(x, y, STONE)
    put(PRIZE_CHEST[0], PRIZE_CHEST[1], STONE, [CHEST])
    put(PRIZE_EXIT[0], PRIZE_EXIT[1], STONE, [(FORCEFIELD, PRIZE_EXIT_AID)])
    return list(out.values())


def monster_xml():
    lines = ['<?xml version="1.0"?>', '<monsters>']
    for x, y in SLIMES:
        lines.append('\t<monster centerx="%d" centery="%d" centerz="%d" radius="0">' % (x, y, Z))
        lines.append('\t\t<monster name="Slime Puddle" x="0" y="0" z="0" spawntime="60" />')
        lines.append('\t</monster>')
    lines.append('</monsters>')
    return '\n'.join(lines) + '\n'


if __name__ == '__main__':
    root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
    out = os.path.join(root, 'data-otservbr-global', 'world', 'custom', 'family-last-creep-standing.otbm')
    squares = build()
    tiles.write(out, squares, 'Gaia Family: Last Creep Standing arena')
    with open(out.replace('.otbm', '-monster.xml'), 'w') as f:
        f.write(monster_xml())
    print('wrote %s: %d squares' % (out, len(squares)))
