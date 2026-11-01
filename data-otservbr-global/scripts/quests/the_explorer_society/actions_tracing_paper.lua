-- FAMILY: the QuestLine checks go through FamilyExplorer (lib/others/family_explorer_society.lua):
-- with Family.explorerSocietyParallel the missions of a rank run side by side, so the QuestLine
-- no longer follows each step (2026-11-01).
local explorerSocietyPaper = Action()
function explorerSocietyPaper.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.itemid == 2199 and target.uid == 3010 and player:getStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheRuneWritings) == 42 and FamilyExplorer.atQuestLine(player, 42) then
		player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheRuneWritings, 43)
		FamilyExplorer.setQuestLine(player, 43)
		item:transform(4843)
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	end
	return true
end

explorerSocietyPaper:id(4842)
explorerSocietyPaper:register()
