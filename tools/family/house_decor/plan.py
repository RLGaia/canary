"""Plan the decoration of every house (Gaia Family server, 2026-10-19).

Ours, not upstream. Run from the repository root:

    python3 tools/family/house_decor/plan.py DUMP

DUMP is the file written by tools/family/house_decor/dump.lua (copy it to
data/scripts/ for one server start). Writes
data/scripts/family/house_decor_data.lua (what goes where, per house) and
tools/family/house_decor/report.md.

Rules, per house and floor:
- Only house tiles that hold nothing but ground (and ground borders) get
  furniture; doors, stairs, ladders and holes keep their 8 neighbours free,
  beds keep their 4 neighbours free, and every walkable tile stays reachable
  from the door (checked after each blocking piece).
- Furniture follows the town (classic, elven, dwarven, nordic, desert,
  tropical, Yalahar). Pieces stand against walls facing into the room; a
  table gets chairs facing it; wall hangings go on walls with a hook that
  face the inside.
- About a third of the houses (more of the big ones) are "rich": more
  furniture, the luxury sets, trophies, statues and valuable equipment
  (prices from data/scripts/family/market_bot_data.lua) on tables and floors.
- Every house is planned from its own id, so it looks the same every time.
"""
import os
import random
import re
import sys
from collections import deque

ROOT = os.getcwd()
APPEARANCES = os.path.join(ROOT, "data/items/appearances.dat")
ITEMS_XML = os.path.join(ROOT, "data/items/items.xml")
MARKET = os.path.join(ROOT, "data/scripts/family/market_bot_data.lua")
OUT_LUA = os.path.join(ROOT, "data/scripts/family/house_decor_data.lua")
OUT_REPORT = os.path.join(ROOT, "tools/family/house_decor/report.md")

DIRS = ["N", "E", "S", "W"]
STEP = {"N": (0, -1), "E": (1, 0), "S": (0, 1), "W": (-1, 0)}
OPPOSITE = {"N": "S", "S": "N", "E": "W", "W": "E"}

# ---------------------------------------------------------------- catalogue
# Rotating pieces: (ids in the items.xml rotate order, facing of the first id).
# Rotation is always clockwise (N, E, S, W). Two-id pieces: first id lies
# along a north/south wall (front south), second along a west/east wall.
CHAIRS = {
    "wooden": ([2358, 2359, 2360, 2361], "N"),
    "comfy": ([28932, 28933, 28934, 28935], "N"),
    "kitchen": ([34292, 34293, 34294, 34295], "N"),
    "knightly": ([39419, 39420, 39421, 39422], "N"),
    "magnificent": ([23403, 23404, 23405, 23406], "N"),
    "grandiose": ([35915, 35916, 35917, 35918], "N"),
    "dwarven": ([31183, 31184, 31185, 31186], "N"),
    "hrodmiran": ([31691, 31692, 31693, 31694], "N"),
    "flower": ([39768, 39769, 39770, 39771], "N"),
    "leaf": ([37004, 37005, 37006, 37007], "N"),
    "blue traditional": ([32123, 32128, 32129, 32130], "E"),
    "green traditional": ([32131, 32132, 32133, 32134], "E"),
    "kraken": ([37174, 37175, 37176, 37177], "N"),
    "alchemistic": ([27662, 27661], "S2"),
    "ice": ([32778, 32779], "S2"),
}
TABLES = {
    "square": [2315], "small": [2319], "small round": [2316], "comfy": [28936, 28937],
    "kitchen": [34284, 34287], "kitchen flowers": [34285, 34288], "kitchen vase": [34286, 34289], "kitchen set": [34290, 34291],
    "knightly": [39423, 39424], "magnificent": [23417, 23418], "grandiose": [35913, 35914],
    "dwarven": [31191], "hrodmiran": [31679], "ice": [32777], "flower": [39772, 39773, 39774],
    "blue traditional": [32139], "green traditional": [32140], "bamboo": [2350, 2351],
    "kraken": [37178], "alchemistic": [27665, 27666],
}
# Pieces that stand against a wall, facing into the room.
STORAGE = {
    "dresser": ([2441, 2444, 2443, 2442], "S"), "drawers": ([2431, 2434, 2433, 2432], "S"),
    "large trunk": ([2483, 2486, 2484, 2485], "S"), "comfy chest": ([28938, 28940, 28941, 28939], "S"),
    "locker": ([2449, 2452, 2450, 2451], "S"), "bookcase": ([6367, 6370, 6369, 6368], "E"),
    "comfy cabinet": ([28942, 28943], "S2"), "cupboard": ([34276, 34277], "S2"),
    "knightly chest": ([39504, 39505, 39506, 39507], "S"), "knightly cabinet": ([39441, 39442], "S2"),
    "magnificent trunk": ([23427, 23428, 23429, 23430], "S"), "magnificent cabinet": ([23419, 23420], "S2"),
    "grandiose cupboard": ([35911, 35912], "S2"), "grandiose gilded chest": ([35923, 35924, 35925, 35926], "S"),
    "grandiose refined chest": ([35919, 35920, 35921, 35922], "S"),
    "dwarven chest": ([31187, 31189, 31190, 31188], "S"), "dwarven cabinet": ([31192, 31193], "S2"),
    "hrodmiran chest": ([31687, 31689, 31690, 31688], "S"), "hrodmiran cupboard": ([31705, 31706], "S2"),
    "hrodmiran weapons rack": ([26081, 26082], "S2"), "hrodmiran shield rack": ([26083, 26084], "S2"),
    "ice chest": ([32780, 32781, 32783, 32782], "S"), "ice cabinet": ([32775, 32776], "S2"),
    "flower chest": ([39777, 39778, 39779, 39780], "S"), "flower cabinet": ([39775, 39776], "S2"),
    "blue rack": ([32142, 32143], "S2"), "green rack": ([32144, 32145], "S2"),
    "bamboo drawer": ([2465, 2468, 2467, 2466], "S"),
    "kraken chest": ([37181, 37182, 37183, 37184], "S"), "kraken cabinet": ([37179, 37180], "S2"),
    "alchemistic cabinet": ([27663, 27664], "S2"), "alchemistic bookstand": ([27680, 27679], "S2"),
    "armor rack": ([6111, 6112], "S2"), "lizard weapon rack": ([10210, 10211], "S2"),
    "chest of abundance": ([28945, 28946], "S2"), "knightly candelabra": ([39498, 39499], "S2"),
    "blue candelabra": ([32161, 32162], "S2"), "green candelabra": ([32160, 32163], "S2"),
    "barrel and anchor lamp": ([31939, 31940], "S2"), "model ship lamp": ([31943, 31944], "S2"),
    "beer barrel": ([32148, 32149, 32150, 32151], "S"),
    "minotaur statue": ([2029, 2045, 2043, 2044], "S"), "goblin statue": ([2030, 2048, 2046, 2047], "S"),
    "dragon statue": ([10212, 10214, 10215, 10213], "S"),
}
# Single pieces without a front (plants, lamps, statues...): (ids, blocking)
STANDING = {
    "potted flower": [2985, 2987], "indoor plant": [2982], "globe": [2979], "harp": [2963],
    "birdcage": [2975, 2976], "large amphora": [2904], "barrel": [2519, 2523], "anvil": [3458],
    "djinn lamp": [42363, 42364, 42365, 42366], "crystal lamp": [31196], "demon statue": [34058],
    "golden demon skull": [31211], "alchemistic scales": [27683, 27684, 27685, 27686],
}
# Floor decorations nobody trips over.
FLOOR = {
    "blue cushion": [31222, 31219], "green cushion": [31221, 31218], "bamboo mat": [23455],
    "fur carpet": [24427], "incomprehensible riches": [28944],
}
# Small things on tables.
TABLETOP = {
    "lit table lamp": [2935], "gold cup": [32921], "silver cup": [32920], "bronze cup": [32919],
}
# Wall hangings (all with hook patterns, so they work on south and east walls).
WALL = {
    "picture": [2639, 2640, 2641], "tapestry": [2659, 2647, 2656, 2650, 2653, 2644, 2667],
    "kitchen": [34309, 34282], "cuckoo clock": [2664], "wall mirror": [2632, 2635],
    "trophy": [7393, 7399, 7396, 7400, 7397, 7394, 7401, 7398, 7395, 10244],
    "luxury tapestry": [23723, 23448, 23449, 23725, 8923, 9046, 10347, 23724],
    "deed": [32917, 32916], "grandiose": [35940, 35944], "knightly": [39502, 39497, 39447],
    "elven": [39801, 39799, 39802, 39800], "nordic": [20315], "nordic trophy": [7397, 7394, 7400],
    "desert": [12482, 12483, 36915, 36916, 34217], "sea": [42305, 31948, 42303, 31945, 5615, 902, 35582, 31951],
    "bamboo lamp": [32903], "metal lamp": [35162], "scales lamp": [42345], "honour": [14675, 14676, 14677, 14678],
    "painting": [28947, 28948, 27699, 27698, 42343], "majestic shield": [14766, 14767], "golden minotaur skull": [31209],
}

# Themes: what each kind of house gets. "rich" adds to the plain lists.
THEMES = {
    "classic": {
        "chairs": ["wooden", "comfy", "kitchen"], "tables": ["square", "small", "small round", "comfy", "kitchen", "kitchen flowers", "kitchen vase", "kitchen set"],
        "storage": ["dresser", "drawers", "large trunk", "comfy chest", "locker", "bookcase", "comfy cabinet", "cupboard"],
        "standing": ["potted flower", "indoor plant", "globe", "harp", "birdcage", "large amphora"],
        "floor": [], "tabletop": ["lit table lamp"], "wall": ["picture", "tapestry", "kitchen", "cuckoo clock", "wall mirror"],
        "rich_chairs": ["knightly", "magnificent", "grandiose"], "rich_tables": ["knightly", "magnificent", "grandiose"],
        "rich_storage": ["knightly chest", "knightly cabinet", "magnificent trunk", "magnificent cabinet", "grandiose cupboard", "grandiose gilded chest", "grandiose refined chest", "armor rack", "knightly candelabra", "minotaur statue", "dragon statue", "chest of abundance"],
        "rich_standing": ["demon statue", "golden demon skull", "crystal lamp"], "rich_floor": ["incomprehensible riches"],
        "rich_tabletop": ["gold cup", "silver cup", "bronze cup"],
        "rich_wall": ["trophy", "luxury tapestry", "deed", "grandiose", "knightly", "honour", "painting", "majestic shield", "golden minotaur skull"],
    },
    "elven": {
        "chairs": ["flower", "leaf"], "tables": ["flower", "small round"], "storage": ["flower chest", "flower cabinet", "bookcase", "drawers"],
        "standing": ["indoor plant", "potted flower", "harp", "birdcage"], "floor": [], "tabletop": ["lit table lamp"],
        "wall": ["elven", "picture", "tapestry"],
        "rich_chairs": ["flower", "grandiose"], "rich_tables": ["flower", "grandiose"], "rich_storage": ["flower cabinet", "grandiose cupboard", "grandiose refined chest"],
        "rich_standing": ["crystal lamp"], "rich_floor": [], "rich_tabletop": ["gold cup", "silver cup"],
        "rich_wall": ["luxury tapestry", "painting", "deed", "trophy"],
    },
    "dwarven": {
        "chairs": ["dwarven", "wooden"], "tables": ["dwarven", "square"], "storage": ["dwarven chest", "dwarven cabinet", "large trunk", "locker", "beer barrel"],
        "standing": ["barrel", "anvil"], "floor": [], "tabletop": ["lit table lamp"], "wall": ["metal lamp", "trophy", "picture"],
        "rich_chairs": ["dwarven", "knightly"], "rich_tables": ["dwarven", "knightly"], "rich_storage": ["knightly chest", "armor rack", "minotaur statue", "chest of abundance"],
        "rich_standing": ["golden demon skull", "demon statue"], "rich_floor": ["incomprehensible riches"], "rich_tabletop": ["gold cup", "silver cup", "bronze cup"],
        "rich_wall": ["trophy", "majestic shield", "honour", "deed", "golden minotaur skull"],
    },
    "nordic": {
        "chairs": ["hrodmiran", "wooden"], "tables": ["hrodmiran", "square"], "storage": ["hrodmiran chest", "hrodmiran cupboard", "hrodmiran weapons rack", "hrodmiran shield rack", "beer barrel", "large trunk"],
        "standing": ["barrel"], "floor": ["fur carpet"], "tabletop": ["lit table lamp"], "wall": ["nordic", "nordic trophy", "tapestry"],
        "rich_chairs": ["hrodmiran", "ice"], "rich_tables": ["hrodmiran", "ice"], "rich_storage": ["ice chest", "ice cabinet", "armor rack", "dragon statue"],
        "rich_standing": ["golden demon skull"], "rich_floor": ["fur carpet"], "rich_tabletop": ["gold cup", "silver cup"],
        "rich_wall": ["trophy", "luxury tapestry", "majestic shield", "honour"],
    },
    "desert": {
        "chairs": ["blue traditional", "green traditional"], "tables": ["blue traditional", "green traditional", "small round"],
        "storage": ["blue rack", "green rack", "drawers", "large trunk", "blue candelabra", "green candelabra"],
        "standing": ["large amphora", "potted flower", "djinn lamp"], "floor": ["blue cushion", "green cushion"], "tabletop": ["lit table lamp"],
        "wall": ["desert", "tapestry"],
        "rich_chairs": ["blue traditional", "magnificent"], "rich_tables": ["blue traditional", "magnificent"], "rich_storage": ["magnificent trunk", "magnificent cabinet", "chest of abundance"],
        "rich_standing": ["djinn lamp", "golden demon skull"], "rich_floor": ["incomprehensible riches"], "rich_tabletop": ["gold cup", "silver cup"],
        "rich_wall": ["desert", "luxury tapestry", "deed", "painting"],
    },
    "tropical": {
        "chairs": ["wooden", "kitchen"], "tables": ["bamboo", "square"], "storage": ["bamboo drawer", "large trunk", "barrel and anchor lamp", "model ship lamp", "drawers"],
        "standing": ["barrel", "potted flower", "indoor plant"], "floor": ["bamboo mat"], "tabletop": ["lit table lamp"],
        "wall": ["sea", "bamboo lamp", "picture"],
        "rich_chairs": ["kraken"], "rich_tables": ["kraken"], "rich_storage": ["kraken chest", "kraken cabinet", "chest of abundance"],
        "rich_standing": ["golden demon skull"], "rich_floor": ["incomprehensible riches"], "rich_tabletop": ["gold cup", "silver cup"],
        "rich_wall": ["sea", "trophy", "deed", "luxury tapestry"],
    },
    "yalahar": {
        "chairs": ["alchemistic", "wooden"], "tables": ["alchemistic", "square"], "storage": ["alchemistic cabinet", "alchemistic bookstand", "bookcase", "dresser"],
        "standing": ["alchemistic scales", "globe", "potted flower"], "floor": [], "tabletop": ["lit table lamp"], "wall": ["picture", "tapestry", "scales lamp"],
        "rich_chairs": ["grandiose", "magnificent"], "rich_tables": ["grandiose", "magnificent"], "rich_storage": ["grandiose cupboard", "magnificent cabinet", "dragon statue"],
        "rich_standing": ["crystal lamp", "golden demon skull"], "rich_floor": ["incomprehensible riches"], "rich_tabletop": ["gold cup", "silver cup"],
        "rich_wall": ["luxury tapestry", "painting", "deed", "trophy"],
    },
}
TOWN_THEME = {
    "Ab'Dendriel": "elven", "Kazordoon": "dwarven", "Farmine": "dwarven", "Svargrond": "nordic",
    "Ankrahmun": "desert", "Darashia": "desert", "Issavi": "desert",
    "Port Hope": "tropical", "Liberty Bay": "tropical", "Yalahar": "yalahar",
}
# Equipment categories of the client market (armors, boots, helmets, legs, shields, weapons).
VALUABLE_CATEGORIES = {1, 3, 7, 8, 13, 17, 18, 19, 20, 21}


# ---------------------------------------------------------------- data files
def varint(b, i):
    r = s = 0
    while True:
        c = b[i]
        i += 1
        r |= (c & 0x7F) << s
        s += 7
        if c < 0x80:
            return r, i


def fields(b):
    i, n = 0, len(b)
    while i < n:
        k, i = varint(b, i)
        f, t = k >> 3, k & 7
        if t == 0:
            v, i = varint(b, i)
        elif t == 2:
            ln, i = varint(b, i)
            v = b[i:i + ln]
            i += ln
        elif t == 5:
            v = b[i:i + 4]
            i += 4
        elif t == 1:
            v = b[i:i + 8]
            i += 8
        else:
            raise ValueError(t)
        yield f, t, v


def read_appearances():
    """id -> (set of flag numbers, hook direction 0/1 south/2 east, market category)."""
    out = {}
    for f, _, v in fields(open(APPEARANCES, "rb").read()):
        if f != 1:
            continue
        oid, flags, hook, cat = None, set(), 0, 0
        for g, _, w in fields(v):
            if g == 1:
                oid = w
            elif g == 3:
                for h, _, x in fields(w):
                    flags.add(h)
                    if h == 21:
                        for a, ta, y in fields(x):
                            if a == 1 and ta == 0:
                                hook = y
                    elif h == 36:
                        for a, ta, y in fields(x):
                            if a == 1 and ta == 0:
                                cat = y
        if oid is not None:
            out[oid] = (flags, hook, cat)
    return out


def read_items_xml():
    names, special = {}, set()
    xml = open(ITEMS_XML, errors="replace").read()
    for m in re.finditer(r'<item (?:id="(\d+)"|fromid="(\d+)" toid="(\d+)")([^>]*?)(/>|>(.*?)</item>)', xml, re.S):
        head, body = m.group(4), m.group(6) or ""
        nm = re.search(r'name="([^"]*)"', head)
        name = nm.group(1).lower() if nm else ""
        ids = [int(m.group(1))] if m.group(1) else range(int(m.group(2)), int(m.group(3)) + 1)
        attrs = dict(re.findall(r'key="([^"]+)" value="([^"]*)"', body))
        is_special = ("floorchange" in attrs or attrs.get("type") in ("door", "teleport", "bed", "magicfield", "trashholder", "mailbox", "depot")
                      or any(w in name for w in ("ladder", "stair", "ramp", "hole", "trapdoor", "door", "gate", "bed", "teleport", "portal", "grate", "sewer")))
        for i in ids:
            names[i] = name
            if is_special:
                special.add(i)
    return names, special


def read_valuables(app, names):
    vals = []
    if not os.path.exists(MARKET):
        return vals
    for line in open(MARKET):
        m = re.match(r"\s*\[(\d+)\] = \{ (\d+),", line)
        if not m:
            continue
        iid, ref = int(m.group(1)), int(m.group(2))
        flags, _, cat = app.get(iid, (set(), 0, 0))
        if cat in VALUABLE_CATEGORIES and 150000 <= ref <= 50000000 and 18 in flags and names.get(iid):
            vals.append(iid)
    return sorted(vals)


def read_dump(path):
    houses, cur = [], None
    for line in open(path):
        p = line.rstrip("\n").split("\t")
        if p[0] == "H":
            cur = {"id": int(p[1]), "name": p[2], "town": p[3], "tiles": {}, "all": {}, "doors": set(), "beds": set()}
            houses.append(cur)
        elif p[0] == "T":
            pos = (int(p[1]), int(p[2]), int(p[3]))
            ids = [int(x) for x in p[5].split(",") if x]
            cur["all"][pos] = ids
            if int(p[4]) == cur["id"]:
                cur["tiles"][pos] = ids
        elif p[0] == "D":
            cur["doors"].add(tuple(map(int, p[1:4])))
        elif p[0] == "B":
            cur["beds"].add(tuple(map(int, p[1:4])))
    return houses


# ---------------------------------------------------------------- planning
class Planner:
    def __init__(self, app, names, special, valuables):
        self.app, self.names, self.special, self.valuables = app, names, special, valuables

    def flags(self, iid):
        return self.app.get(iid, (set(), 0, 0))[0]

    def is_blocking(self, iid):
        f = self.flags(iid)
        return 13 in f or 16 in f

    def classify(self, ids):
        """kind: 'floor' (ground + borders only), 'walk' (walkable, has items), 'block', 'special', 'none'."""
        if not ids:
            return "none"
        ground = ids[0]
        if 1 not in self.flags(ground):
            return "block" if any(self.is_blocking(i) for i in ids) else "none"
        if any(i in self.special for i in ids):
            return "special"
        if self.is_blocking(ground) or any(self.is_blocking(i) for i in ids[1:]):
            return "block"
        rest = [i for i in ids[1:] if 2 not in self.flags(i)]
        return "floor" if not rest else "walk"

    def hook(self, ids):
        has_hang = any(20 in self.flags(i) for i in ids)
        for i in ids:
            h = self.app.get(i, (set(), 0, 0))[1]
            if h:
                return 0 if has_hang else h
        return 0

    def plan_house(self, h):
        rng = random.Random(h["id"] * 7919 + 17)
        theme = THEMES[TOWN_THEME.get(h["town"], "classic")]
        size = len(h["tiles"])
        rich = rng.random() < 0.18 + 0.32 * min(1.0, size / 150.0)
        placed = []
        for z in sorted({p[2] for p in h["tiles"]}):
            placed += self.plan_floor(h, z, theme, rich, rng)
        return rich, placed

    def pick(self, rng, theme, key, rich):
        pool = list(theme.get(key, []))
        if rich and theme.get("rich_" + key):
            pool = theme["rich_" + key] * 2 + pool  # luxury first, plain still possible
        return rng.choice(pool) if pool else None

    def plan_floor(self, h, z, theme, rich, rng):
        tiles = {p: ids for p, ids in h["tiles"].items() if p[2] == z}
        kind = {p: self.classify(ids) for p, ids in tiles.items()}
        walk = {p for p, k in kind.items() if k in ("floor", "walk", "special")}
        doors = {p for p in h["doors"] if p[2] == z}
        beds = {p for p in h["beds"] if p[2] == z} | {p for p, ids in tiles.items() if any("bed" in self.names.get(i, "") for i in ids)}
        walk |= {p for p in doors if p in tiles}

        reserved = set()
        for p in doors | {q for q, k in kind.items() if k == "special"}:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    reserved.add((p[0] + dx, p[1] + dy, z))
        for b in beds:
            for d in DIRS:
                reserved.add((b[0] + STEP[d][0], b[1] + STEP[d][1], z))
        free = {p for p, k in kind.items() if k == "floor" and p not in reserved and p not in beds}

        # seeds for reachability: walkable tiles next to doors or stairs
        seeds = set()
        for p in walk:
            if p in doors or kind.get(p) == "special":
                seeds.add(p)
        if not seeds and walk:
            seeds = {min(walk)}
        blocked = set()

        def reachable_ok(extra):
            nb = blocked | {extra}
            targets = walk - nb
            if not targets:
                return True
            start = [s for s in seeds if s not in nb]
            if not start:
                return False
            seen = set(start)
            q = deque(start)
            while q:
                x, y, _ = q.popleft()
                for d in DIRS:
                    n = (x + STEP[d][0], y + STEP[d][1], z)
                    if n in targets and n not in seen:
                        seen.add(n)
                        q.append(n)
            return targets <= seen

        def wall_side(p):
            """Directions in which p touches a wall or the outside (no walkable house tile)."""
            out = []
            for d in DIRS:
                n = (p[0] + STEP[d][0], p[1] + STEP[d][1], z)
                if n not in walk and n not in beds:
                    out.append(d)
            return out

        def rotated(ids_first, facing):
            ids, first = ids_first
            if first == "S2":
                return ids[0] if facing in ("S", "N") else ids[-1]
            k = (DIRS.index(facing) - DIRS.index(first)) % 4
            return ids[k % len(ids)]

        out = []
        nfree = len(free)
        if nfree == 0:
            return self.plan_walls(h, z, tiles, walk, theme, rich, rng, out)
        budget = max(1, int(nfree * (0.42 if rich else 0.32) + 0.5))

        # 1. table groups in open spots (not against walls when possible)
        groups = max(1, nfree // 18) if nfree >= 5 else 0
        candidates = sorted(free, key=lambda p: (len(wall_side(p)), rng.random()))
        for p in candidates:
            if groups <= 0 or budget <= 0:
                break
            if p not in free:
                continue
            nbrs = [d for d in DIRS if (p[0] + STEP[d][0], p[1] + STEP[d][1], z) in free]
            if len(nbrs) < 2 or not reachable_ok(p):
                continue
            tname = self.pick(rng, theme, "tables", rich)
            cname = self.pick(rng, theme, "chairs", rich)
            if not tname:
                continue
            table = rng.choice(TABLES[tname]) if len(TABLES[tname]) > 2 else TABLES[tname][rng.randrange(len(TABLES[tname]))]
            out.append((p, table))
            free.discard(p)
            blocked.add(p)
            budget -= 1
            groups -= 1
            # tabletop
            tt = self.pick(rng, theme, "tabletop", rich)
            if rich and self.valuables and rng.random() < 0.6:
                out.append((p, rng.choice(self.valuables)))
            elif tt and rng.random() < 0.5:
                out.append((p, rng.choice(TABLETOP[tt])))
            # chairs facing the table
            rng.shuffle(nbrs)
            for d in nbrs[: 2 if not rich else 3]:
                c = (p[0] + STEP[d][0], p[1] + STEP[d][1], z)
                if c in free and cname and reachable_ok(c):
                    out.append((c, rotated(CHAIRS[cname], OPPOSITE[d])))
                    free.discard(c)
                    blocked.add(c)
                    budget -= 1

        # 2. pieces against the walls
        walls = [p for p in free if wall_side(p)]
        rng.shuffle(walls)
        walls.sort(key=lambda p: 0 if ("N" in wall_side(p) or "W" in wall_side(p)) else 1)
        for p in walls:
            if budget <= 0:
                break
            if p not in free or not reachable_ok(p):
                continue
            sides = wall_side(p)
            back = "N" if "N" in sides else ("W" if "W" in sides else sides[0])
            facing = OPPOSITE[back]
            if rng.random() < 0.65:
                sname = self.pick(rng, theme, "storage", rich)
                if not sname:
                    continue
                iid = rotated(STORAGE[sname], facing)
            else:
                sname = self.pick(rng, theme, "standing", rich)
                if not sname:
                    continue
                iid = rng.choice(STANDING[sname])
            out.append((p, iid))
            free.discard(p)
            if self.is_blocking(iid):
                blocked.add(p)
            budget -= 1

        # 3. floor decorations and valuables (nothing blocks)
        floor_items = 1 if nfree >= 6 else 0
        spots = sorted(free, key=lambda p: rng.random())
        for p in spots:
            if floor_items <= 0:
                break
            fname = self.pick(rng, theme, "floor", rich)
            if fname == "incomprehensible riches" and rng.random() > 0.35:
                fname = None  # a pile of gold in some rich houses, not all
            if fname:
                out.append((p, rng.choice(FLOOR[fname])))
                free.discard(p)
                floor_items -= 1
        if rich and self.valuables:
            for p in [q for q in sorted(free, key=lambda q: rng.random()) if wall_side(q)][: 1 + nfree // 15]:
                out.append((p, rng.choice(self.valuables)))
                free.discard(p)

        return self.plan_walls(h, z, tiles, walk, theme, rich, rng, out)

    def plan_walls(self, h, z, tiles, walk, theme, rich, rng, out):
        share = 0.55 if rich else 0.3
        for p, ids in sorted(tiles.items()):
            hk = self.hook(ids)
            if not hk:
                continue
            inside = (p[0], p[1] + 1, z) if hk == 1 else (p[0] + 1, p[1], z)
            if inside not in walk or rng.random() > share:
                continue
            wname = self.pick(rng, theme, "wall", rich)
            if wname:
                out.append((p, rng.choice(WALL[wname])))
        return out


def main():
    dump = sys.argv[1]
    app = read_appearances()
    names, special = read_items_xml()
    valuables = read_valuables(app, names)
    planner = Planner(app, names, special, valuables)
    houses = read_dump(dump)
    total, rich_count, by_theme = 0, 0, {}
    lines = []
    for h in sorted(houses, key=lambda x: x["id"]):
        rich, placed = planner.plan_house(h)
        if not placed:
            continue
        total += len(placed)
        rich_count += 1 if rich else 0
        theme = TOWN_THEME.get(h["town"], "classic")
        by_theme[theme] = by_theme.get(theme, 0) + 1
        cells = ", ".join("{%d,%d,%d,%d}" % (p[0], p[1], p[2], iid) for p, iid in placed)
        lines.append("\t[%d] = { %s }, -- %s, %s%s" % (h["id"], cells, h["name"].replace("\n", " "), h["town"], ", rich" if rich else ""))
    with open(OUT_LUA, "w") as o:
        o.write("-- Generated by tools/family/house_decor/plan.py. Do not edit by hand.\n")
        o.write("-- [houseId] = { {x, y, z, itemId}, ... } in placement order (tables before what stands on them).\n")
        o.write("return {\n" + "\n".join(lines) + "\n}\n")
    with open(OUT_REPORT, "w") as o:
        o.write("# House decoration plan\n\nGenerated by plan.py.\n\n")
        o.write("Houses decorated: %d (rich: %d), items: %d, valuables available: %d.\n\n" % (len(lines), rich_count, total, len(valuables)))
        o.write("By theme: " + ", ".join("%s %d" % kv for kv in sorted(by_theme.items())) + ".\n")
    print("houses", len(lines), "rich", rich_count, "items", total, "valuables", len(valuables), by_theme)


if __name__ == "__main__":
    main()
