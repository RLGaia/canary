"""List the quest items the family market may sell (2026-10-25).

Ours (Gaia Family server). Asked by Rodrigo: the market had only buy offers
for quest items; now they get sell offers too, priced like every other item
(see data/scripts/family/market_bot.lua). Run from the repository root:

    python3 -I tools/family/market/quest_items.py data-otservbr-global/world/otservbr.otbm

Writes data/scripts/family/market_bot_quest_data.lua and
tools/family/market/quest_items.md.

A quest item is a market item (an id in market_bot_data.lua) that quest
content on this server hands out or asks for:
- the contents of the map's quest chests (action id 2000 and the special
  quest-chest action ids of quest_system1.lua);
- the reward tables of startup/tables/chest.lua;
- literal ids in addItem / addItemEx(Game.createItem(...)) calls and in
  itemId/id/item/reward = <id> fields of quest scripts, quest NPCs and our
  quest scripts.
Sources that are not quests are left out (surprise bags, baking, skinning,
fishing, mount taming, crafting, the soul pit, event and token traders, the
Tibiadrome shop), and so are the single ids listed in NOT_QUEST, reviewed by
hand. Event items (winter event, raid token souvenirs) stay buy only.
"""
import glob
import os
import re
import struct
import sys

ROOT = os.getcwd()
DATA = os.path.join(ROOT, "data/scripts/family/market_bot_data.lua")
OUT_LUA = os.path.join(ROOT, "data/scripts/family/market_bot_quest_data.lua")
OUT_MD = os.path.join(ROOT, "tools/family/market/quest_items.md")

# Action ids of quest chests that hand out their own map contents (quest_system1.lua).
CHEST_ACTION_IDS = {2000, 51400, 51715, 51716, 51717}

SCRIPT_DIRS = [
    "data-otservbr-global/scripts/quests", "data-otservbr-global/scripts/actions",
    "data-otservbr-global/scripts/creaturescripts", "data-otservbr-global/scripts/movements",
    "data-otservbr-global/scripts/lib", "data-otservbr-global/scripts/family",
    "data-otservbr-global/lib", "data-otservbr-global/npc", "data/scripts/family",
]
PATTERNS = [
    re.compile(r"addItem\s*\(\s*(\d{3,5})\b"),
    re.compile(r"addItemEx\s*\(\s*Game\.createItem\s*\(\s*(\d{3,5})\b"),
    re.compile(r"\b(?:itemId|itemid|itemID|item_id|item|id|reward|rewardId)\s*=\s*(\d{3,5})\b"),
]
# Files whose items are not quest items.
NOT_QUEST_FILES = {
    "random_items.lua": "surprise bags and boxes",
    "baking.lua": "baking",
    "skinning.lua": "skinning and dusting corpses",
    "fishing.lua": "fishing",
    "mechanical_fishing.lua": "fishing",
    "mounts.lua": "mount taming",
    "create_sugar_oat.lua": "crafting (mount taming item)",
    "falcon_shield.lua": "crafting from creature loot",
    "soul_prism.lua": "soul pit",
    "ruprecht.lua": "winter event trader",
    "santa_claus.lua": "winter event",
    "jorge.lua": "raid token souvenirs",
    "lorenzo.lua": "Tibiadrome shop",
    "sandra.lua": "vial deposit (lottery tickets)",
    "pemaret.lua": "trophy service",
    "swolt.lua": "rice exchange",
    "market_bot.lua": "the market itself",
    "market_bot_data.lua": "the market itself",
    "market_bot_quest_data.lua": "the market itself",
    "monk_gear.lua": "creature loot and shops",
    "loot_updates_data.lua": "creature loot",
    "loot_updates.lua": "creature loot",
    "house_decor_data.lua": "house furniture",
    "boss_coins.lua": "creature loot",
}
# Single ids found in quest-ish files that are not quest items (reviewed 2026-10-25).
NOT_QUEST = {
    6278: "cake (baked from dough on fruit)",
    16251: "golem wrench (mount taming item)",
    17858: "leech (dug up; mount taming item)",
    21507: "pinch of crystal dust (grinder crafting)",
    5905: "vampire dust (from vampire corpses, only asked for by an NPC)",
}


def map_chest_contents(path):
    data = open(path, "rb").read()
    n, i = len(data), 4
    sizes = {4: 2, 5: 2, 9: 2, 10: 2, 12: 1, 14: 1, 15: 1, 16: 4, 17: 1, 18: 4, 20: 4, 21: 4, 22: 2, 8: 5}

    def props(j):
        out = bytearray()
        while j < n:
            b = data[j]
            if b == 0xFD:
                out.append(data[j + 1])
                j += 2
            elif b in (0xFE, 0xFF):
                break
            else:
                out.append(b)
                j += 1
        return bytes(out), j

    def action_id(p):
        k = 2
        while k < len(p):
            a = p[k]
            k += 1
            if a in (6, 7, 19):
                k += 2 + struct.unpack_from("<H", p, k)[0]
            elif a in sizes:
                if a == 4:
                    return int.from_bytes(p[k:k + 2], "little")
                k += sizes[a]
            else:
                break
        return None

    stack, found = [], set()
    while i < n:
        b = data[i]
        if b == 0xFE:
            t = data[i + 1]
            p, j = props(i + 2)
            entry = None
            if t == 6 and len(p) >= 2:
                iid = struct.unpack_from("<H", p, 0)[0]
                if any(stack):
                    found.add(iid)
                entry = action_id(p) in CHEST_ACTION_IDS
            stack.append(entry)
            i = j
        elif b == 0xFF:
            stack.pop()
            i += 1
        else:
            i += 1
    return found


def balanced(s, j):
    depth = 0
    for k in range(j, len(s)):
        if s[k] == "{":
            depth += 1
        elif s[k] == "}":
            depth -= 1
            if depth == 0:
                return s[j:k + 1]
    return s[j:]


def main():
    market = {}
    for m in re.finditer(r"\[(\d+)\] = \{ \d+, \d+, \d+, \d+ \}, -- (.*)", open(DATA).read()):
        market[int(m.group(1))] = m.group(2)

    sources = {}

    def note(iid, src):
        if iid in market:
            sources.setdefault(iid, set()).add(src)

    for iid in map_chest_contents(sys.argv[1]):
        note(iid, "map quest chest")
    s = open("data-otservbr-global/startup/tables/chest.lua").read()
    for m in re.finditer(r"\breward\s*=\s*\{", s):
        for t in re.finditer(r"\{\s*(\d+)\s*(?:,\s*\d+\s*)?\}", balanced(s, m.end() - 1)):
            note(int(t.group(1)), "chest table")
    for d in SCRIPT_DIRS:
        for f in glob.glob(d + "/**/*.lua", recursive=True):
            base = os.path.basename(f)
            if base in NOT_QUEST_FILES:
                continue
            txt = open(f, errors="replace").read()
            for p in PATTERNS:
                for m in p.finditer(txt):
                    note(int(m.group(1)), base)
    for iid in NOT_QUEST:
        sources.pop(iid, None)

    with open(OUT_LUA, "w") as o:
        o.write("-- Generated by tools/family/market/quest_items.py. Do not edit by hand.\n")
        o.write("-- Market items handed out or asked for by quest content: they get sell offers too.\n")
        o.write("return {\n")
        for iid in sorted(sources):
            o.write("\t[%d] = true, -- %s\n" % (iid, market[iid]))
        o.write("}\n")
    with open(OUT_MD, "w") as o:
        o.write("# Quest items on the family market\n\nGenerated by quest_items.py: %d market items. "
                "Items a creature drops or an NPC sells already had sell offers; the others get one now.\n\n"
                % len(sources))
        o.write("| Item | Id | Found in |\n|---|---|---|\n")
        for iid in sorted(sources, key=lambda x: market[x].lower()):
            o.write("| %s | %d | %s |\n" % (market[iid], iid, ", ".join(sorted(sources[iid]))[:120]))
        o.write("\nLeft out on purpose: " + "; ".join(
            "%s (%s)" % (k, v) for k, v in sorted(NOT_QUEST_FILES.items())) + ". Single ids: " +
            "; ".join(v for _, v in sorted(NOT_QUEST.items())) + ".\n")
    print(len(sources), "quest items")


if __name__ == "__main__":
    main()
