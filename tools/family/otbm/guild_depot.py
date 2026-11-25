# Gaia Family server: two depot lockers in the Adventurers' Guild (asked by Rodrigo's father,
# 2026-11-24). Tibia has no depot there (TibiaWiki EN "Adventurers' Guild": reward shrine, NPCs,
# no depot); this is a family choice, not a wiki fix.
#
# The lockers stand in the reward shrine room (floor 6, south of the main hall), against its south
# timber wall, one on each side of the shrine (32200,32306,6), leaving the squares around the shrine
# free. A locker needs its town number (OTBM depot id) from the map: Lua cannot give one to an item
# made at startup, and a locker without it does not open the market. We give Thais (8); on our
# server every locker shows the same depot boxes, inbox and stash whatever the town.
#
#   python3 -I tools/family/otbm/guild_depot.py
# writes data-otservbr-global/world/custom/family-guild-depot.otbm (+ empty side files). The squares
# replace the main map's squares: same ground (8308) and protection zone as there.
#
# In front of each locker (one square north) lies a glowing switch, as in every Tibia depot (the
# Thais depot uses 10145). Stepping on it turns on the stash and the market menus
# (data/scripts/movements/special_tiles.lua); without it the lockers opened, but the stash and the
# market's "show in market" did not work (Rodrigo, 2026-11-25).
# Switch: Family.guildDepot in data-otservbr-global/scripts/family/guild_depot.lua (false removes them).
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tiles

LOCKER_SOUTH_WALL = 3497  # the locker that stands against a south wall (as in the Thais depot)
THAIS = 8
GROUND = 8308  # what our map has on both squares
PZ = 1
SQUARES = [(32198, 32306, 6), (32202, 32306, 6)]  # keep in step with guild_depot.lua
GLOWING_SWITCH = 10145
SWITCHES = [(32198, 32305, 6), (32202, 32305, 6)]  # one north of each locker; keep in step with guild_depot.lua

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
OUT = os.path.join(ROOT, 'data-otservbr-global', 'world', 'custom', 'family-guild-depot.otbm')

if __name__ == '__main__':
    squares = [{'pos': pos, 'ground': GROUND, 'flags': PZ,
                'items': [{'id': LOCKER_SOUTH_WALL, 'depot': THAIS}]} for pos in SQUARES]
    squares += [{'pos': pos, 'ground': GLOWING_SWITCH, 'flags': PZ} for pos in SWITCHES]
    print('wrote %s: %d squares' % (OUT, tiles.write(OUT, squares, 'Gaia Family: Adventurers\' Guild depot')))
