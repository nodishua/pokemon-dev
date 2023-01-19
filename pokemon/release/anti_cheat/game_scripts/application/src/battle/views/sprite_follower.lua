globals.BattleFollowerSprite = class("BattleFollowerSprite", BattleSprite)

-- 更新 点击面板的位置
function BattleFollowerSprite:updHitPanel()
end

function BattleFollowerSprite:showHero(isShow, args)
	self.lifebar:setVisible(isShow and not args.hideLife)
	self:setVisible(isShow)
end
