"""Build the price table for the family market character.

Ours (Gaia Family server). Run from the repository root:

    python3 tools/family/market/build.py WORLDS_DIR

WORLDS_DIR holds the files written by fetch.py. Writes
data/scripts/family/market_bot_data.lua and tools/family/market/report.md.

Per item (only items the client can trade on the market, under their own id):
- ref: real Tibia price, the median over the fetched worlds of each world's
  month average (middle of the average buy and average sell when both exist).
  Items with no real data fall back to the highest price an NPC pays, else
  the lowest price an NPC charges (ours first, then Tibia's from the client).
- pay / charge: highest price one of our NPCs pays for it / lowest price one
  of our NPCs sells it for (gold shops only), used at startup so the market
  never gives a gold loop with an NPC.
- npc: 1 when one of our NPCs sells it (it can then get a sell offer even if
  no creature drops it; drops are checked at startup from the creature files).
"""
import glob
import json
import os
import re
import statistics
import sys

ROOT = os.getcwd()
APPEARANCES = os.path.join(ROOT, "data/items/appearances.dat")
OUT_LUA = os.path.join(ROOT, "data/scripts/family/market_bot_data.lua")
OUT_REPORT = os.path.join(ROOT, "tools/family/market/report.md")

# Currencies and tokens: never traded by the market character.
EXCLUDED = {
    3031: "gold coin", 3035: "platinum coin", 3043: "crystal coin",
    22118: "tibia coins", 22516: "silver token", 22721: "gold token",
}
# Shop entries that are not paid in gold although the file has no npcConfig.currency.
NOT_GOLD = {"data/scripts/family/monk_gear.lua": {50277, 50279, 50280}}  # Cledwyn, silver tokens


def varint(b, i):
    r = s = 0
    while True:
        c = b[i]
        i += 1
        r |= (c & 0x7F) << s
        s += 7
        if c < 0x80:
            return r, i


def fields(b):
    i, n = 0, len(b)
    while i < n:
        k, i = varint(b, i)
        f, t = k >> 3, k & 7
        if t == 0:
            v, i = varint(b, i)
        elif t == 2:
            ln, i = varint(b, i)
            v = b[i:i + ln]
            i += ln
        elif t == 5:
            v = b[i:i + 4]
            i += 4
        elif t == 1:
            v = b[i:i + 8]
            i += 8
        else:
            raise ValueError("wire type %d" % t)
        yield f, t, v


def read_appearances():
    """Objects with market data: id -> {name, trade_as, npc: [(sale, buy, currency)]}."""
    out = {}
    for f, _, v in fields(open(APPEARANCES, "rb").read()):
        if f != 1:
            continue
        oid, name, market, npc = None, "", None, []
        for g, _, w in fields(v):
            if g == 1:
                oid = w
            elif g == 4:
                name = w.decode("utf-8", "replace")
            elif g == 3:
                for h, _, x in fields(w):
                    if h == 36:
                        market = {a: y for a, ta, y in fields(x) if ta == 0}
                    elif h == 40:
                        d = {a: y for a, ta, y in fields(x) if ta == 0}
                        npc.append((d.get(3, 0), d.get(4, 0), d.get(5, 0)))
        if oid is not None and market:
            out[oid] = {"name": name, "trade_as": market.get(2, oid), "npc": npc}
    return out


ENTRY = re.compile(r"\{[^{}]*?clientId\s*=\s*(\d+)[^{}]*\}")
NUM = {k: re.compile(r"\b" + k + r"\s*=\s*(\d+)") for k in ("buy", "sell")}


def read_npc_shops():
    """Our gold shops: id -> (highest price an NPC pays, lowest price an NPC charges)."""
    pay, charge = {}, {}
    files = glob.glob("data-otservbr-global/npc/**/*.lua", recursive=True)
    files += glob.glob("data/npc/**/*.lua", recursive=True)
    files += ["data/scripts/lib/shops.lua", "data/scripts/family/monk_gear.lua",
              "data-otservbr-global/scripts/lib/family_city_life_data.lua"]
    for f in files:
        if not os.path.exists(f):
            continue
        s = open(f, errors="replace").read()
        if re.search(r"npcConfig\.currency\s*=", s):
            continue
        if re.search(r"local FAMILY_SALES = false", s):
            continue  # shop switched off (Imbuement Assistant)
        skip = NOT_GOLD.get(f, set())
        for m in ENTRY.finditer(s):
            iid = int(m.group(1))
            if iid in skip:
                continue
            body = m.group(0)
            b = NUM["buy"].search(body)
            se = NUM["sell"].search(body)
            if se and int(se.group(1)) > 0:
                pay[iid] = max(pay.get(iid, 0), int(se.group(1)))
            if b and int(b.group(1)) > 0:
                charge[iid] = min(charge.get(iid, 1 << 62), int(b.group(1)))
    return pay, charge


def world_value(x):
    s, b = x.get("month_average_sell", -1), x.get("month_average_buy", -1)
    if s is None:
        s = -1
    if b is None:
        b = -1
    if s > 0 and b > 0:
        return (s + b) / 2
    if s > 0:
        return s
    if b > 0:
        return b
    return None


def main():
    wdir = sys.argv[1]
    worlds = sorted(p for p in glob.glob(os.path.join(wdir, "*.json")) if not p.endswith("worlds.json"))
    per_item = {}
    for p in worlds:
        for x in json.load(open(p)):
            v = world_value(x)
            if v:
                per_item.setdefault(x["id"], []).append(v)
    app = read_appearances()
    pay, charge = read_npc_shops()

    rows, report_rows = [], []
    counts = {"market items": 0, "real price": 0, "npc fallback": 0, "no price": 0, "excluded": 0}
    for iid in sorted(app):
        a = app[iid]
        if a["trade_as"] != iid:
            continue
        counts["market items"] += 1
        if iid in EXCLUDED:
            counts["excluded"] += 1
            continue
        vals = per_item.get(iid)
        src = "real"
        if vals:
            ref = statistics.median(vals)
            counts["real price"] += 1
        else:
            tibia_pay = max([buy for sale, buy, cur in a["npc"] if cur == 0] or [0])
            tibia_charge = min([sale for sale, buy, cur in a["npc"] if cur == 0 and sale > 0] or [0])
            ref = pay.get(iid) or tibia_pay or charge.get(iid) or tibia_charge
            src = "npc"
            if not ref:
                counts["no price"] += 1
                continue
            counts["npc fallback"] += 1
        ref = int(round(ref))
        if ref < 1:
            continue
        p = pay.get(iid, 0)
        c = charge.get(iid, 0)
        rows.append((iid, ref, p, c, 1 if c else 0, a["name"]))
        report_rows.append((a["name"], iid, ref, src, len(vals or []), p, c))

    with open(OUT_LUA, "w") as o:
        o.write("-- Generated by tools/family/market/build.py from TibiaMarket (real Tibia worlds) and our NPC shops.\n")
        o.write("-- Do not edit by hand. [id] = { ref, npcPays, npcCharges, npcSells } (gold).\n")
        o.write("return {\n")
        for iid, ref, p, c, n, name in rows:
            o.write("\t[%d] = { %d, %d, %d, %d }, -- %s\n" % (iid, ref, p, c, n, name.replace("\n", " ")))
        o.write("}\n")

    with open(OUT_REPORT, "w") as o:
        o.write("# Market price table\n\nGenerated by build.py. Worlds: %s.\n\n" % ", ".join(
            os.path.basename(p)[:-5] for p in worlds))
        o.write("Summary: " + ", ".join("%s %d" % kv for kv in counts.items()) + ".\n\n")
        o.write("ref = real price (median of the worlds' month averages) or NPC fallback; "
                "pays/charges = our NPCs. Offers at startup: buy ref x 0.9, sell ref x 1.1 "
                "(times Family.marketBot.priceScale), then kept clear of NPC prices.\n\n")
        o.write("| Item | Id | Ref | Source | Worlds | NPC pays | NPC charges |\n|---|---|---|---|---|---|---|\n")
        for name, iid, ref, src, nw, p, c in sorted(report_rows, key=lambda r: r[0].lower()):
            o.write("| %s | %d | %d | %s | %d | %s | %s |\n" % (name, iid, ref, src, nw, p or "", c or ""))
    print(counts, "rows", len(rows))


if __name__ == "__main__":
    main()
