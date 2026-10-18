# Loot audit against TibiaWiki

Ours (Gaia Family server), started 2026-10-18. Compares every creature's loot
in `data-otservbr-global/monster` with TibiaWiki (BR) and adds what is
missing, without editing the creature files.

- `wiki_loot.json`: loot lists read from TibiaWiki BR, one entry per creature
  (item, quantity, rarity, page, date). Filled in batches with `add.py`.
- `add.py`: reads blocks from stdin (format in the file) into `wiki_loot.json`.
- `compare.py ITEMS FLAGS`: compares and writes `report.md` and
  `data/scripts/family/loot_updates_data.lua`. `ITEMS` is a dump of the
  server's items (id, name, plural, stackable; made by a test server) and
  `FLAGS` the client's appearance flags per item (18 = can be picked up);
  neither is committed.
- `report.md`: per creature, the items added, the items only our files have
  (kept) and TibiaWiki names that matched no item.

Rules: event and raid drops are ignored; items already in our files keep their
chances; added items get a chance by TibiaWiki rarity (always 100%, common 33%,
uncommon 10%, semi-rare 2.8%, rare 0.9%, very rare 0.2%) and TibiaWiki's
highest quantity. Names are matched with plurals and accents removed; a name
used by several items uses the one other creatures drop, else the first one
that can be picked up.

Left out on purpose: items TibiaWiki marks with an asterisk (the item's own
page does not list the creature, "Loot Divergente"; the Stone Skin Amulet on
most undeads is one), drops listed without a rarity (several boss pages), and
pages whose list looked wrong when read (copied from another creature). Those
creatures are listed in `skipped.txt` and can be read again later.
For bosses with a reward chest the quantities of stackable items are not
taken (one of each), since the pages mix totals and single drops.

Done 2026-10-18 for every folder except raids, event creatures and
nostalgia: 910 creatures compared, 996 items added to 332 creatures (summary
line of `report.md`). Not compared: `skipped.txt`.
