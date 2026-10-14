-- Gaia Family server: !house, a short guide to houses (2026-10-13).
-- Ours, not upstream. The rules are in family/config.family.lua and
-- data/scripts/lib/family_houses.lua.

local HELP_ITEM = 2821 -- book shown as the dialog icon

local function formatGold(value)
	local text = tostring(math.floor(value))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

local function guide(player)
	local own = {}
	for _, house in ipairs(Game.getHouses()) do
		if house:getOwnerGuid() == player:getGuid() then
			local town = house:getTown()
			own[#own + 1] = string.format("  %s (%s)", house:getName(), town and town:getName() or "?")
		end
	end
	local lines = {
		"HOUSES ON THE GAIA FAMILY SERVER",
		"",
		"Pay once: no rent, never lost, no level, no limit.",
		"Guildhalls too, no guild needed.",
		"",
		"BUY IN CYCLOPEDIA",
		"Cyclopedia > Houses > town > house > Bid.",
		"You pay the price shown as rent, once. The bid itself",
		"comes back unless someone else bid on the same house.",
		"The house is yours at the next server start.",
		"",
		"BUY AT ONCE",
		"Stand in front of the house door, face it and say",
		"  !buyhouse",
		"Same price as in Cyclopedia.",
		"",
		"COMMANDS",
		"  !house       this guide",
		"  !buyhouse    buy the house whose door you face",
		"  !leavehouse  inside your house: give it up",
		"               (free at the next server start, no refund)",
		"  !sellhouse Name  inside your house: pass it to a",
		"               player next to you (trade window)",
		"",
		"SPELLS INSIDE YOUR HOUSE",
		"  aleta sio    guest list (who may enter)",
		"  aleta som    subowner list (who may also invite)",
		"  aleta grav   door list (face a door first)",
		"  alana sio    kick someone out (alana sio \"Name)",
		"",
		"Tip: invite the other player as subowner so you both",
		"can use beds, doors and furniture.",
		"",
		"Other: !commands lists every command, !serverinfo shows",
		"your experience and skill rates.",
	}
	if #own > 0 then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "YOUR HOUSES"
		for _, line in ipairs(own) do
			lines[#lines + 1] = line
		end
	end
	return table.concat(lines, "\n")
end

local houseHelp = TalkAction("!house", "!houses")

function houseHelp.onSay(player, words, param)
	player:showTextDialog(HELP_ITEM, guide(player))
	return true
end

houseHelp:setDescription("- how to buy a house, house commands and spells")
houseHelp:groupType("normal")
houseHelp:register()
