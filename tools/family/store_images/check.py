"""Check (and fill) the Store pictures the game client downloads.

Ours (Gaia Family server). Run from the repository root:

    pip install lupa                      # once: runs the catalog's Lua
    python3 tools/family/store_images/check.py            # report only
    python3 tools/family/store_images/check.py --pack DIR # copy missing ones

The client draws items, mounts and outfits itself; everything else in the
Store (category icons, home banners, and offers such as beds, blessings,
Premium Time, boosts, hireling services) is a PNG it downloads from
coinImagesURL (family/config.family.lua), as <url>64/<offer image>,
<url>13/<category icon> and <url><banner path>. Those files live in
family/store-images/. DIR is the "store" folder of the opentibiabr image pack
(https://docs.opentibiabr.com/opentibiabr/downloads/website-applications).
Exit code 1 when a picture is still missing.
"""
import os
import shutil
import sys

from lupa import LuaRuntime, lua_type

ROOT = os.getcwd()
OUT = os.path.join(ROOT, "family", "store-images")

lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().CORE_DIRECTORY = os.path.join(ROOT, "data")
lua.execute("""
  GameStore = dofile(CORE_DIRECTORY .. "/libs/gamestore/constants.lua")
  logger = { error = print, warn = print, info = print }
  configKeys = setmetatable({}, { __index = function(_, k) return k end })
  configManager = { getNumber = function() return 0 end, getBoolean = function() return true end,
    getString = function() return "" end, getFloat = function() return 1 end }
  local stub
  stub = setmetatable({}, { __index = function() return stub end, __call = function() return 0 end,
    __add = function() return 0 end, __concat = function() return "" end })
  setmetatable(_G, { __index = function() return stub end })
  CATALOG = dofile(CORE_DIRECTORY .. "/modules/scripts/gamestore/catalog/init.lua")
  -- the home banners are set in gamestore.lua, which needs the whole server; read them as text
  local f = io.open(CORE_DIRECTORY .. "/modules/scripts/gamestore/gamestore.lua")
  local src = f:read("*a")
  f:close()
  BANNERS = {}
  local list = src:match("HomeBanners%s*=%s*{.-images%s*=%s*(%b{})")
  for name in (list or ""):gmatch('"([^"]+)"') do BANNERS[#BANNERS + 1] = name end
""")


def values(t):
    if t is None:
        return []
    return list(t.values()) if lua_type(t) == "table" else [t]


ot = dict(lua.eval("GameStore.OfferTypes").items())
drawn_by_client = {ot[k] for k in (
    "OFFER_TYPE_ITEM", "OFFER_TYPE_STACKABLE", "OFFER_TYPE_HOUSE", "OFFER_TYPE_CHARGES",
    "OFFER_TYPE_ITEM_UNIQUE", "OFFER_TYPE_OUTFIT", "OFFER_TYPE_OUTFIT_ADDON",
    "OFFER_TYPE_MOUNT", "OFFER_TYPE_HIRELING")}

needed = {}  # path under store-images -> where it is used
for cat in values(lua.globals().CATALOG):
    for icon in values(cat.icons):
        needed.setdefault("13/" + icon, "category " + cat.name)
    for offer in values(cat.offers):
        if (offer.type or 0) in drawn_by_client:
            continue
        icons = values(offer.icons)
        if not icons:
            print("NO IMAGE NAME  %s / %s" % (cat.name, offer.name))
            continue
        needed.setdefault("64/" + icons[0], "%s / %s" % (cat.name, offer.name))
for banner in values(lua.globals().BANNERS):
    needed.setdefault(banner, "home banner")

pack = sys.argv[sys.argv.index("--pack") + 1] if "--pack" in sys.argv else None
missing = 0
for path, use in sorted(needed.items()):
    target = os.path.join(OUT, path)
    if os.path.isfile(target):
        continue
    source = pack and os.path.join(pack, path)
    if source and os.path.isfile(source):
        os.makedirs(os.path.dirname(target), exist_ok=True)
        shutil.copyfile(source, target)
        print("copied   %s (%s)" % (path, use))
    else:
        missing += 1
        print("MISSING  %s (%s)" % (path, use))

extra = []
for base, _, files in os.walk(OUT):
    for f in files:
        rel = os.path.relpath(os.path.join(base, f), OUT).replace(os.sep, "/")
        if rel.endswith(".png") and rel not in needed:
            extra.append(rel)
print("%d pictures needed, %d missing, %d not used any more%s" % (
    len(needed), missing, len(extra), (": " + ", ".join(sorted(extra))) if extra else ""))
sys.exit(1 if missing else 0)
