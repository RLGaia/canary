-- Gaia Family server: monk equipment that could not be obtained (2026-10-17).
-- Ours, not upstream.
--
-- Canary has every monk item of Tibia, but some of them were never added to the
-- monsters, NPC shops and quest rewards that give them in Tibia (TibiaWiki,
-- checked 2026-10-17). This adds them at startup, without changing those files:
--
-- * Loot. Each item drops as often as an item of the same rarity of that
--   creature (for example the monk robe of a tarantula as often as its time ring).
-- * Weapon shops. The 20 weapon dealers of Tibia (Sam, Hardek,
--   Romella, Uzgod, Esrik...) sell and buy the pair of monk fists, nunchaku and
--   sais at Tibia's prices. The trader hireling has them too (hireling.lua).
-- * Cledwyn (Adventurers' Guild) also sells the leaf, energy and ice robes for
--   100 silver tokens, as he already did the magma robe.
-- * Bakragore's bag you covet can hold grand sanguine claws, as rarely as the
--   other grand sanguine weapons.
-- * Quest rewards. The Inquisition reward room gets a tenth chest (east corner)
--   with the merudri nanbando (actions_rewards.lua gives it), and the chest next
--   to the three reward stands of Wrath of the Emperor holds the merudri scale
--   mail. Both are put there at every start, as the map items are.
-- * The monk werewolf helmet: Maeryn (Grimvale) offers {monk}, then moonlight
--   crystals enchant the helmet (maeryn.lua, moonlight_crystals.lua).
--
-- Still not obtainable, because what gives them is not in our server: spirit
-- bind (the monk's Spirit Sphere of the Elemental Spheres quest), norcferatu
-- bonehood and fleshguards (the boss Vladrukh), the rending, draining and
-- siphoning inferniarch claws (Doomforging), genesis serenity armor and legs.
--
-- Switch: Family.monkGear (false = upstream).

Family = Family or {}
Family.monkGear = true

local LOOT = {
	["Tarantula"] = { { id = 50258, chance = 120 } }, -- monk robe (very rare, as the time ring)
	["Ratmiral Blackwhiskers"] = { { id = 50270, chance = 890 } }, -- bambus jo (as the jungle survivor legs)
	["Timira the Many-Headed"] = { { id = 50160, chance = 200 } }, -- naga katar (as the naga tanko)
	["Mitmah Vanguard"] = { { id = 50291, chance = 545 } }, -- iks footwraps (as the stoic iks robe)
	["The Duke of the Depths"] = { { id = 50290, chance = 3390 } }, -- gnomish footwraps (as the gnomish cuirass)
	["The Baron from Below"] = { { id = 50290, chance = 3390 } }, -- gnomish footwraps (as the gnome armor)
	["The Count of the Core"] = { { id = 50290, chance = 3390 } }, -- gnomish footwraps (as the gnome helmet)
}

local WEAPON_DEALERS = {
	"Shanar", "Memech", "Rowenna", "Habdel", "Willard", "Esrik", "Rock In A Hard Place",
	"Ulrik", "Uzgod", "Cedrik", "Brengus", "Flint", "Robert", "Gamel", "Sam", "Turvy",
	"Hardek", "Baltim", "Romella", "Morpel",
}
-- Wes the Blacksmith (Tibia's 22nd dealer) is not in our server.

Family.monkWeaponShop = {
	{ itemName = "pair of monk fists", clientId = 50181, buy = 270, sell = 90 },
	{ itemName = "nunchaku", clientId = 50182, buy = 405, sell = 135 },
	{ itemName = "sais", clientId = 50183, buy = 540, sell = 180 },
}

local SHOPS = {
	["Cledwyn"] = {
		{ itemName = "energy robe", clientId = 50279, buy = 100 },
		{ itemName = "ice robe", clientId = 50280, buy = 100 },
		{ itemName = "leaf robe", clientId = 50277, buy = 100 },
	},
}
for _, name in ipairs(WEAPON_DEALERS) do
	SHOPS[name] = Family.monkWeaponShop
end

local GRAND_SANGUINE_CLAWS = { id = 50158, name = "grand sanguine claws", weight = 0.00001 }

local INQUISITION_CHEST_ID = 2472
local WRATH_CHEST = Position(33074, 31169, 8) -- next to the reward stands
local MERUDRI_SCALE_MAIL = 50263

local function addShopItem(npcType, entry)
	local shop = Shop()
	shop:setId(entry.clientId)
	shop:setNameItem(entry.itemName)
	shop:setBuyPrice(entry.buy or 0)
	shop:setSellPrice(entry.sell or 0)
	return npcType:addShopItem(shop) == true
end

local startup = GlobalEvent("FamilyMonkGear")

function startup.onStartup()
	if not Family.monkGear then
		return true
	end
	local loot, shops, problems = 0, 0, {}

	for name, items in pairs(LOOT) do
		local mType = Game.getMonsterTypeByName(name)
		if mType then
			mType:createLoot(items)
			loot = loot + #items
		else
			problems[#problems + 1] = "monster " .. name
		end
	end

	for name, items in pairs(SHOPS) do
		local npcType = NpcType(name)
		if npcType then
			for _, entry in ipairs(items) do
				if addShopItem(npcType, entry) then
					shops = shops + 1
				else
					problems[#problems + 1] = "shop " .. name .. " " .. entry.itemName
				end
			end
		else
			problems[#problems + 1] = "npc " .. name
		end
	end

	local bags = RewardBagSystem and RewardBagSystem.rewardBags and RewardBagSystem.rewardBags[BAG_YOU_COVET]
	if bags then
		local present = false
		for _, reward in ipairs(bags) do
			present = present or reward.id == GRAND_SANGUINE_CLAWS.id
		end
		if not present then
			table.insert(bags, GRAND_SANGUINE_CLAWS)
		end
	else
		problems[#problems + 1] = "bag you covet"
	end

	-- InquisitionMonkChestPosition: the_inquisition_quest/actions_rewards.lua (32330,32248,9)
	local chestPosition = InquisitionMonkChestPosition
	local tile = chestPosition and Tile(chestPosition)
	if tile and not tile:getItemById(INQUISITION_CHEST_ID) then
		local chest = Game.createItem(INQUISITION_CHEST_ID, 1, chestPosition)
		if chest then
			chest:setActionId(IMMOVABLE_ACTION_ID)
		else
			problems[#problems + 1] = "inquisition chest"
		end
	end

	local wrathTile = Tile(WRATH_CHEST)
	local wrathChest = wrathTile and wrathTile:getItemById(INQUISITION_CHEST_ID)
	if wrathChest and wrathChest:isContainer() then
		if wrathChest:getItemCountById(MERUDRI_SCALE_MAIL) == 0 then
			wrathChest:addItem(MERUDRI_SCALE_MAIL, 1)
		end
	else
		problems[#problems + 1] = "wrath chest"
	end

	logger.info("[Family] monk gear: {} loot entries, {} shop entries{}", loot, shops, #problems > 0 and (", NOT FOUND: " .. table.concat(problems, ", ")) or "")
	return true
end

startup:register()
