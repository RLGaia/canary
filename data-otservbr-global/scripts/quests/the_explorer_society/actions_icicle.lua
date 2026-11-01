-- FAMILY: the QuestLine checks go through FamilyExplorer (lib/others/family_explorer_society.lua):
-- with Family.explorerSocietyParallel the missions of a rank run side by side, so the QuestLine
-- no longer follows each step (2026-11-01).
local explorerSocietyIcicle = Action()
function explorerSocietyIcicle.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.itemid == 4994 and player:getStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheIceDelivery) == 6 and FamilyExplorer.atQuestLine(player, 6) then
		player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheIceDelivery, 7)
		FamilyExplorer.setQuestLine(player, 7)
		player:addItem(4837, 1)
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	end
	return true
end

explorerSocietyIcicle:id(4872)
explorerSocietyIcicle:register()
