"""Download real Tibia market values from the TibiaMarket API (api.tibiamarket.top).

Ours (Gaia Family server). No token is needed; the API limits requests per
address, so worlds are fetched one at a time with a pause.

    python3 fetch.py OUT_DIR [N]

Saves the N worlds with the newest data (default 12) as OUT_DIR/<World>.json
and the world list as OUT_DIR/worlds.json.
"""
import json
import os
import sys
import time
import urllib.request

API = "https://api.tibiamarket.top"


def get(path):
    for attempt in range(4):
        try:
            with urllib.request.urlopen(API + path, timeout=120) as r:
                return json.load(r)
        except Exception as e:  # rate limit or network: wait and retry
            print("retry", path, e, file=sys.stderr)
            time.sleep(10 * (attempt + 1))
    raise SystemExit("failed: " + path)


def main():
    out = sys.argv[1]
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 12
    os.makedirs(out, exist_ok=True)
    worlds = get("/world_data")
    worlds.sort(key=lambda w: w.get("last_update") or "", reverse=True)
    json.dump(worlds, open(os.path.join(out, "worlds.json"), "w"))
    for w in worlds[:n]:
        data = get("/market_values?server=" + w["name"] + "&limit=10000")
        json.dump(data, open(os.path.join(out, w["name"] + ".json"), "w"))
        print(w["name"], (w.get("last_update") or "")[:10], len(data))
        time.sleep(3)


if __name__ == "__main__":
    main()
