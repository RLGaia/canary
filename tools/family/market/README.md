# Family market prices

Ours (Gaia Family server), 2026-10-18. Builds the price table used by
`data/scripts/family/market_bot.lua`, the hidden "Family Market" character
that keeps anonymous buy and sell offers on the in-game market.

- `fetch.py OUT_DIR [N]`: downloads the market values of the N real Tibia
  worlds with the newest data (default 12) from the TibiaMarket API
  (`https://api.tibiamarket.top`, no token, one request every few seconds).
- `build.py OUT_DIR` (from the repository root): writes
  `data/scripts/family/market_bot_data.lua` and `report.md`.

Per item the client can trade on the market (appearances.dat market flag,
traded under its own id): the real price is the median over the worlds of
each world's month average (middle of average buy and average sell). Without
real data the NPC prices are used (ours, else Tibia's from appearances.dat).
Our gold NPC shops (not the Imbuement Assistant, whose sales are off) give the highest price an NPC pays and the lowest it
charges, so the startup script keeps the offers clear of gold loops.
Currencies and tokens (gold, platinum, crystal coins, Tibia Coins, silver and
gold tokens) are left out.

First run (2026-10-18, worlds Antica, Bravoria, Monza, Xyla, Bona, Descubra,
Quidera, Honbra, Ourobra, Rasteibra, Talera, Nevia): 4,782 market items,
4,184 with a real price, 242 with an NPC price, 353 without any price (no
offers). At startup: 4,372 buy offers and 2,389 sell offers (after the NPC creature product sales were switched off the same day).

To refresh prices later: `python3 tools/family/market/fetch.py /tmp/worlds`
then `python3 tools/family/market/build.py /tmp/worlds` and restart the server.
