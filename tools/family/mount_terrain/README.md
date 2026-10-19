# Mount terrain (Gaia Family server)

Tools behind `data/scripts/family/mount_terrain.lua`: every mount is faster on
its own terrain (+30% home, +15% related, flying mounts +30% under the open sky).
See the "Mount terrain" row in `FAMILY.md` for the rules as players see them.

## Files

| File | What it does |
|---|---|
| `classify.py` | Sorts every ground of `data/items/appearances.dat` into a terrain and writes `data/scripts/family/mount_terrain_data.lua` |
| `annotate.py` | Writes each mount's terrains into its name in `data/XML/mounts.xml` ("Water Buffalo (Swamp/Water)") from the table in `mount_terrain.lua`; `--strip` restores the original names |
| `ground_usage.tsv` | How often each ground id appears on the map (id, squares, squares on floors 0-7), counted from `world/otservbr.otbm` on 2026-10-19. Only used by `classify.py --report` to sort the report by use |

Run from the repository root:

```sh
python3 tools/family/mount_terrain/classify.py            # rewrite mount_terrain_data.lua
python3 tools/family/mount_terrain/classify.py --report   # terrain per ground, most used first
python3 tools/family/mount_terrain/annotate.py            # after changing the mount table
```

## How grounds are sorted

Only the first item of a square counts (the ground). For walkable grounds
(friction above 1 in the appearances), first match wins:

1. `OVERRIDES` in `classify.py` (grounds checked by eye).
2. Friction 250: walking under water (sea floor) = water.
3. Words in the item name (items.xml), in this order: roof/terracotta = town,
   swamp words (mud, slime, bog, lily pads, tar...), water words (shallow water,
   sea floor, brook...), snow and ice, volcanic (lava, burnt, ash, sulphur...),
   desert (sand, dry floor, salt; not sandstone city floors), wild (grass, moss,
   forest, jungle, dirt, earth, rock, gravel...), town (floor, tile, pavement,
   planks, bridges, stairs...).
4. Minimap colour of the ground: green = wild, light green = swamp, yellow
   sand = desert, white and ice blue = snow, blue = water, orange = volcanic,
   brown and dark grey = wild, grey = town.

Unwalkable grounds that colour the land around them go to the `near` list:
swamp water (minimap light green, "swamp", "bog", "tar"), lava ("lava",
"sulphur", orange) and the sea and lakes (blue, "water"). The script counts
a square as that terrain too when one of them is within
`Family.mountTerrain.nearRadius` squares (2) on the same floor.

"Caves" is not a ground: the script turns wild and town ground on floor 8 and
deeper into caves. Water, swamp, desert, snow and volcanic ground stay what
they are underground (sandy tombs are desert, lava caves volcanic).

"Open sky" (flying mounts): a square on floors 0-7 with no object at all on
the same x, y on any higher floor (roofs are often walls or roof pieces, not
ground).

Checked on 2026-10-19 with rendered samples of the most used grounds of each
terrain and a server test on 18 map positions (every terrain above and below
ground, a swamp edge, a sea coast, a house under its roof).
