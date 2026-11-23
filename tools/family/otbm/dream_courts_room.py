# Gaia Family server: The Dream Courts, the chest room behind Andrew Lyze's magic portal (ours: our map
# has no such room; TibiaWiki EN/BR only say the charged compass on the magic portal sends you to a
# small room with a brass-shod chest and a blue magic forcefield back to Andrew).
# Writes data-otservbr-global/world/custom/family-dream-courts.otbm (a 5x5 room in an empty part of
# floor 11, 32642-32646, 32740-32744). Run from the repository root:
#   python3 -I tools/family/otbm/dream_courts_room.py
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tiles

GROUND = 15043  # mossy floor, as in the carnivor cave below Andrew
CHEST = 23740  # brass-shod chest
FIELD, FIELD_AID = 1949, 48787  # magic forcefield, MoveEvent in scripts/family/dream_courts.lua
GEODE = 14967  # crystal geode (decoration)
squares = []
for x in range(32642, 32647):
    for y in range(32740, 32745):
        items = []
        if (x, y) == (32644, 32740):
            items.append(CHEST)
        elif (x, y) == (32644, 32744):
            items.append((FIELD, FIELD_AID))
        elif (x, y) in ((32642, 32740), (32646, 32740)):
            items.append(GEODE)
        squares.append({"pos": (x, y, 11), "ground": GROUND, "items": items, "flags": 1})
out = os.path.join("data-otservbr-global", "world", "custom", "family-dream-courts.otbm")
print("wrote %s: %d squares" % (out, tiles.write(out, squares, "Gaia Family: The Dream Courts chest room")))
