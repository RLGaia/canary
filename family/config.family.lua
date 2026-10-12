-- Family server overrides
--
-- start-server.ps1 builds config.lua as:
--   config.lua.dist (upstream defaults, untouched)
--   + this file (family gameplay/server choices, committed to Git)
--   + machine settings generated from family\local.env (IP, DB password)
-- Later assignments win, so anything set here overrides config.lua.dist.
-- Edit THIS file, never config.lua (it is regenerated on every start).

-- Upstream regenerates docs/lua-api on every start when this is true, which
-- would leave tracked files modified in Git. We don't need the API docs.
generateLuaApiDocs = false

ownerName = "Gaia Family"
location = "South America"

-- Phase 5 (duo tuning) settings will go here: rates, PvP, premium, etc.
