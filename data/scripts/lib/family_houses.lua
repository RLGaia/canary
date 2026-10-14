-- Gaia Family server: house switches (2026-10-13). Ours, not upstream.
--
-- This file sits in data/scripts/lib so these values exist before the
-- talkactions in data/scripts/talkactions/player load (they read them when
-- deciding whether to register; each use is marked FAMILY:).
--
-- Houses are bought in Cyclopedia -> Houses or with !buyhouse; the prices and
-- the no-rent rules are in family/config.family.lua. In game, !house shows a
-- short guide (data/scripts/family/house_help.lua).

-- !buyhouse, !leavehouse and !sellhouse stay available while Cyclopedia
-- auctions are on. false = upstream (only without Cyclopedia auctions).
FAMILY_HOUSE_COMMANDS = true

-- !buyhouse works even if you already own a house. false = one per character.
FAMILY_UNLIMITED_HOUSES = true
