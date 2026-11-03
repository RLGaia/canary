local commands = TalkAction("!commands")

function commands.onSay(player, words, param)
	-- FAMILY: explanations and examples, !commands <name> (data/scripts/family/commands_help.lua).
	if Family and Family.commandsHelp and Family.showCommands then
		return Family.showCommands(player, param)
	end

	local allTalkActions = Game.getTalkActions()
	local playerGroupId = player:getGroup():getId()

	local text = "Available commands:\n\n"

	for _, talkaction in pairs(allTalkActions) do
		if talkaction:getGroupType() ~= 0 then
			if talkaction:getGroupType() <= playerGroupId then
				text = text .. talkaction:getName()

				description = talkaction:getDescription()

				if description ~= "" then
					text = text .. " " .. talkaction:getDescription()
				end

				text = text .. "\n\n"
			end
		end
	end

	player:showTextDialog(639, text)

	return true
end

commands:setDescription("[Usage]: !commands to see each command with its description")
commands:separator(" ") -- FAMILY: so "!commands deposit" reaches the script
commands:groupType("normal")
commands:register()
