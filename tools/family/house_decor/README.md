# House decoration

Ours (Gaia Family server), 2026-10-19. Plans the furniture that
`data/scripts/family/house_decor.lua` puts in every house without an owner.

1. Copy `dump.lua` to `data/scripts/`, start the server once, remove it. It
   writes `house_dump.txt` (every house with the tiles around it).
2. `python3 tools/family/house_decor/plan.py house_dump.txt` (from the
   repository root) writes `data/scripts/family/house_decor_data.lua` and
   `report.md`.
3. Restart the server.

Only needed again when the map's houses change or the catalogue in `plan.py`
is edited. The rules are at the top of `plan.py`; the catalogue (furniture
per town style, with the facing of every rotating piece checked against the
client's sprites) is below them.

First plan (2026-10-19): 982 houses, 321 of them rich, 17,201 pieces. Same
day, made more cluttered at Rodrigo's request (denser furniture, doors and
stairs keep only their 4 neighbours free, beds one way in, small things on
tables, furniture tops and 40-60% of the free floor): 991 houses, 43,978
pieces (43,874 placed on the test server; the save takes about 0.4 s).
