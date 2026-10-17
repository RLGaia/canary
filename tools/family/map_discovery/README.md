# Map discovery data (Gaia Family server)

Ours, not upstream. These tools build `data/scripts/lib/family_map_discovery_data.lua`,
the data behind the Cyclopedia map discovery (`data/scripts/family/map_discovery.lua`).
Run them again only when the map or the game client changes.

You need the client's `assets` folder (the one with `map-*.dat` and the `subarea-*.bmp.lzma`
files), Python 3 and a server you can start for a minute (a test copy is best).

1. Export the subarea shapes and the NPC positions:

   ```
   python3 tools/family/map_discovery/export_masks.py <client>/assets masks.lua data-otservbr-global/world/otservbr-npc.xml
   ```

2. Copy `poi_generator.lua` to `data/scripts/`, start the server from its folder and wait
   for `[PoiGenerator] wrote poi_candidates.lua` in the log (about 40 seconds), then stop it
   and delete `data/scripts/poi_generator.lua`.

3. Build the data file:

   ```
   python3 tools/family/map_discovery/build_data.py <client>/assets poi_candidates.lua data/scripts/lib/family_map_discovery_data.lua
   ```

4. Delete `masks.lua` and `poi_candidates.lua`.

## What the data is

- Areas and subareas: ids and names from the client's `map-*.dat` (protobuf `tibia.protobuf.map.Map`:
  `areas`, `npcs`, `resource_files`). Only subareas with a shape file (`subarea-*.bmp.lzma`,
  surface only) can be selected in the client, so only those are used.
- Points of interest: `poi_generator.lua` walks the map from every temple and NPC (stairs,
  ladders, rope spots, sewer grates, ordinary doors and teleports are followed; houses and
  doors with an action or unique id are not), then picks up to 16 evenly spread reachable
  tiles inside each subarea, on the ground floor when possible, else the highest reachable
  floor, else underground. Stray pieces of a subarea shape (under 15% of its biggest piece)
  are ignored.

## Client protocol (15.11), as found in the client

- Client to server `0xDB` (CYCLOPEDIA MAP ACTION): byte action. `0` = reset/start discovering
  a subarea, followed by u16 subarea id. `1` = donate, followed by u16 area id and u32 gold.
- Server to client `0xDD` (CYCLOPEDIA MAP DATA), byte type, then:
  - `0` minimap marker: position, byte icon, string description (what Canary already sends).
  - `1` area progress: u16 count, each u16 area id, byte state (0 none, 1 = NPCs shown,
    2 = passages shown, 3 = complete), byte percent (0-100; more than 100 = not explorable);
    then u16 count of discovered subarea ids (u16 each); then u16 count of subarea ids that
    can be started (u16 each; enables "Start Discovering").
  - `2` active raid: position, byte. `3`/`4` imminent raid: u16 id, byte.
  - `5` points of interest: u16 subarea id, byte points needed, byte count, each position and
    byte type (0 = not reached, 1 = reached). The client counts the reached ones.
  - `6` passage: position, byte count, u16 each. `7` subarea monsters: byte count, each u16
    subarea, byte count, each u16 race, bool, byte. `8` monster: u16 race, bool.
  - `9` donations: u64, byte count, each u16 area, bool, u64. `10` current area: u16.
