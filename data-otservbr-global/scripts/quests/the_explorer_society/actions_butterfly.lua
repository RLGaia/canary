-- FAMILY: the QuestLine checks go through FamilyExplorer (lib/others/family_explorer_society.lua):
-- with Family.explorerSocietyParallel the missions of a rank run side by side, so the QuestLine
-- no longer follows each step (2026-11-01).
local explorerSocietyButterfly = Action()
function explorerSocietyButterfly.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.itemid == 4992 and player:getStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheButterflyHunt) == 9 and FamilyExplorer.atQuestLine(player, 9) then
		player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheButterflyHunt, 10)
		FamilyExplorer.setQuestLine(player, 10)
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
		item:transform(4864)
		target:remove()
	elseif target.itemid == 4993 and player:getStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheButterflyHunt) == 12 and FamilyExplorer.atQuestLine(player, 12) then
		player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheButterflyHunt, 13)
		FamilyExplorer.setQuestLine(player, 13)
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
		item:transform(4865)
		target:remove()
	elseif target.itemid == 4991 and player:getStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheButterflyHunt) == 15 and FamilyExplorer.atQuestLine(player, 15) then
		player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheButterflyHunt, 16)
		FamilyExplorer.setQuestLine(player, 16)
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
		item:transform(4866)
		target:remove()
	end
	return true
end

explorerSocietyButterfly:id(4863)
explorerSocietyButterfly:register()
