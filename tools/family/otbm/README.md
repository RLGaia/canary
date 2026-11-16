# Map helpers (Gaia Family server)

Small readers for `data-otservbr-global/world/otservbr.otbm` (184 MB), used to
check quests against the map: is the chest there, what is in it, which unique
or action id does it have. Read-only; they never change the map (overlay.py, tiles.py and continuum_room.py only write separate files). Run them with
`python3 -I` from the repository root. A full-map scan takes about a minute.

| Script | Arguments | Prints |
|---|---|---|
| `region.py` | `<map> x0,y0,x1,y1,z` | every square of a rectangle on one floor: ground, flags, items with attributes (4 = action id, 5 = unique id, 15 = count) |
| `contents.py` | `<map> "<uid,...>" ["x:y:z,..."]` | the nested contents of items with those unique ids, or of everything on those squares |
| `find.py` | `<map> x0,y0,x1,y1 "<item id,...>"` | every item with those ids inside a box, all floors, with the containers it is in |
| `overlay.py` | `<map> <out.otbm> <flags> x,y,z ...` | writes a small custom map (`data-otservbr-global/world/custom/`) that copies those squares from the main map with extra tile flags (1 = protection zone, 4 = no-PvP, 8 = no-logout); Canary loads custom maps at startup before spawns. Used for the Grimvale dock |
| `tiles.py` | `<out.otbm> <squares.json>` (or `tiles.write()` from Python) | writes a small custom map with new squares the main map does not have: ground (optionally with an action id), items, tile flags |
| `continuum_room.py` | none | builds `world/custom/family-continuum.otbm`, Eclesius' crack in the space-time continuum (The Scatterbrained Sorcerer, Mission 3) |
| `attr.py` | `<map> "<uid/aid,...>" ["<item id,...>"]` | items with those unique/action ids, or with those item ids (whole map) |

Item names: look the ids up in `data/items/items.xml`. Spawns are not in the
map; they are in `world/otservbr-monster.xml` and `world/otservbr-npc.xml`.
