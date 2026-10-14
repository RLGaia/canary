local savingEvent = 0

local save = TalkAction("/save")

function save.onSay(player, words, param)
	-- create log
	logCommand(player, words, param)

	if isNumber(param) then
		stopEvent(savingEvent)
		local delay = tonumber(param) * 60 * 1000
		savingEvent = addEvent(function()
			saveServer()
			SaveHirelings()
		end, delay, delay)
	else
		saveServer()
		SaveHirelings()
		player:sendTextMessage(MESSAGE_ADMINISTRATOR, "Server has been saved.")
	end
	return true
end

-- FAMILY: every character may save (only Rodrigo and his father play here).
save:setDescription("- save the server now, or /save 5 to save in 5 minutes")
save:separator(" ")
save:groupType("normal")
save:register()
