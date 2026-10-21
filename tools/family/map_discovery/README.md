# Map discovery data (Gaia Family server)

Ours, not upstream. These tools build `data/scripts/lib/family_map_discovery_data.lua`,
the data behind the Cyclopedia map discovery (`data/scripts/family/map_discovery.lua`).
Run them again only when the map or the game client changes.

You need the client's `assets` folder (the one with `map-*.dat` and the `subarea-*.bmp.lzma`
files), Python 3 and a server you can start for a minute (a test copy is best).

1. Get `extra/points-of-interest/markers.json` from https://github.com/tibiamaps/tibia-map-data
   (MIT licence), then export the subarea shapes, the NPC positions and the real spots:

   ```
   python3 tools/family/map_discovery/export_masks.py <client>/assets masks.lua data-otservbr-global/world/otservbr-npc.xml markers.json
   ```

2. Copy `poi_generator.lua` to `data/scripts/`, start the server from its folder and wait
   for `[PoiGenerator] wrote poi_candidates.lua` in the log (about 40 seconds), then stop it
   and delete `data/scripts/poi_generator.lua`.

3. Build the data file:

   ```
   python3 tools/family/map_discovery/build_data.py <client>/assets poi_candidates.lua data/scripts/lib/family_map_discovery_data.lua .
   ```

4. Delete `masks.lua` and `poi_candidates.lua`.

## What the data is

- Areas and subareas: ids and names from the client's `map-*.dat` (protobuf `tibia.protobuf.map.Map`:
  `areas`, `npcs`, `resource_files`). Only subareas with a shape file (`subarea-*.bmp.lzma`,
  drawn on the surface map) can be selected in the client, so only those are used.
- A subarea is its shape on every floor (the shapes never overlap; real Tibia points of
  interest are found from floor 0 to 15 inside them).
- Points of interest: `poi_generator.lua` walks the map from every temple, following stairs,
  holes, ladders, rope spots, sewer grates and teleports to the exact square the server
  sends a player to, and ordinary doors; never houses (`Tile:getHouse()`: Canary v3.6.1 has
  no `TILESTATE_HOUSE`), locked doors or doors with an action or unique id. NPC squares and
  every `Position(...)` in the NPC scripts (boat destinations, quest teleports) are extra
  starts, used only when they lead to at least 100 new squares (so the squares behind a shop
  counter are left out). Fixed on 2026-10-21 after a point was found inside a Stonehome house. The real spots players mapped in Tibia
  (TibiaMaps.io flag markers) are kept when that tile, or one within 2 squares on the same
  floor, can be walked to on our map (about 85% of them). Up to 16 evenly spread reachable
  tiles on any floor are generated too, and `build_data.py` adds them only while a subarea
  has fewer than 16 real spots. Stray pieces of a subarea shape (under 15% of its biggest
  piece) get no generated points.

- Where each subarea is (`grid`): 4 x 4 square blocks, each given to the subarea that owns
  most of it, as rows of runs. Used to know which subarea a character is in (any floor).
- Creatures (`creatures`): per subarea, the monsters of `otservbr-monster.xml` spawning inside
  its shape (0 = common; 1 = rare, 5 or fewer spawns on the whole map) and the monsters of the
  raids (`data-otservbr-global/raids` and `scripts/raids`) that appear there (2).

## Client protocol (15.11), as found in the client

- Client to server `0xDB` (CYCLOPEDIA MAP ACTION): byte action. `0` = reset/start discovering
  a subarea, followed by u16 subarea id. `1` = donate, followed by u16 area id and u32 gold.
- Server to client `0xDD` (CYCLOPEDIA MAP DATA), byte type, then:
  - `0` minimap marker: position, byte icon, string description (what Canary already sends).
  - `1` area progress: u16 count, each u16 area id, byte state (0 none, 1 = NPCs shown,
    2 = passages shown, 3 = complete), byte percent (0-100; more than 100 = not explorable);
    then u16 count of discovered subarea ids (u16 each); then u16 count of subarea ids that
    can be started (u16 each; enables "Start Discovering").
  - `2` active raid: position, byte 0 = add / 1 = remove. `3`/`4` raid soon in an area /
    subarea: u16 id, byte (we send 1 to show, 0 to clear).
  - `5` points of interest: u16 subarea id, byte points needed, byte count, each position and
    byte type (0 = not reached, 1 = reached). The client counts the reached ones.
  - `6` passage: position, byte count, u16 each. `7` subarea creatures: byte count, each u16
    subarea, byte count, each u16 race id, bool known in the Bestiary (false = silhouette),
    byte occurrence (0 common, 1 rare, 2 raids/events). `8`: u16, bool.
  - `9` donations: u64, byte count, each u16 area, bool, u64. `10` current area: u16.
