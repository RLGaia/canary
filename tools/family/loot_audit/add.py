"""Add TibiaWiki (BR) loot lists to wiki_loot.json.

Input on stdin, one block per creature:

### Creature Name | https://www.tibiawiki.com.br/wiki/Creature_Name
Item Name|0-110|Comum
...
HP|1000
EXP|700

A block with the single line NOLOOT records a creature without loot;
NOTFOUND or NOTCREATURE records a page that is not usable.
"""
import json
import os
import sys
import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "wiki_loot.json")

data = json.load(open(DATA)) if os.path.exists(DATA) else {}
today = datetime.date.today().isoformat()
name = None
added = []
for raw in sys.stdin.read().splitlines():
    line = raw.strip().strip("`").strip()
    if not line:
        continue
    if line.startswith("###"):
        head = line[3:].strip()
        title, _, url = head.partition("|")
        name = title.strip()
        data[name] = {"url": url.strip(), "date": today, "loot": [], "status": "ok"}
        added.append(name)
        continue
    if name is None:
        continue
    entry = data[name]
    upper = line.upper()
    if upper in ("NOLOOT", "NOTFOUND", "NOTCREATURE"):
        entry["status"] = upper.lower()
        continue
    parts = [p.strip() for p in line.split("|")]
    if parts[0].upper() == "HP" and len(parts) > 1:
        entry["hp"] = parts[1]
        continue
    if parts[0].upper() == "EXP" and len(parts) > 1:
        entry["exp"] = parts[1]
        continue
    if len(parts) >= 3 and parts[0]:
        entry["loot"].append({"item": parts[0], "qty": parts[1], "rarity": parts[2]})
json.dump(data, open(DATA, "w"), indent=1, ensure_ascii=False, sort_keys=True)
print("added", len(added), "total", len(data))
