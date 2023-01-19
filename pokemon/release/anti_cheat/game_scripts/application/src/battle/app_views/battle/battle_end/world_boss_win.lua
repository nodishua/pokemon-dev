--
-- 日常活动副本结算
--

local BattleEndWorldBossView = class("BattleEndWorldBossView", cc.load("mvc").ViewBase)

BattleEndWorldBossView.RESOURCE_FILENAME = "battle_end_world_boss_win.json"
BattleEndWorldBossView.RESOURCE_BINDING = {
	["bkg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onPanelClick"),
		},
	},
	["awardsList"] = "awardsList",
	["cardItem"] = "awardsItem",
	["bkg.exitText"] = "exitText",
	["awardBg"] = "awardBg",
	["awardBg.awardText"] = "awardText",
	["awardBg.awardNewImg"] = "awardNewImg",
	["awardBg.awardNewText"] = "awardNewText",
}

function BattleEndWorldBossView:onCreate(sceneID,results)
	audio.playEffectWithWeekBGM("pve_win.mp3")
	local pnode = self:getResourceNode()

	local textEffect = widget.addAnimation(pnode, "level/newzhandoushengli.skel", "effect2", 100)
	textEffect:anchorPoint(cc.p(0.5,0.5))
		:xy(pnode:get("title"):getPosition())
		:addPlay("effect2_loop")

	self.exitText:text(gLanguageCsv.click2Exit)
	self.awardText:setString(results.damage)

	self.awardsList:setItemsMargin(25)
	self.awardsList:setScrollBarEnabled(false)
	if next(results.award) ~= nil then
		local tmpData = {}
		for k,v in pairs(results.award) do
			table.insert(tmpData, {key = k, num = v})
		end
		self:showItem(1, tmpData)
	end

	self.awardNewImg:setVisible(results.isNewRecordDamage)
	self.awardNewText:setVisible(results.isNewRecordDamage)
	if results.isNewRecordDamage then
		self.awardNewText:setString(gLanguageCsv.worldBossDamageMaxTip)
	end
end

function BattleEndWorldBossView:showItem(index, data)
	local item = self.awardsItem:clone()
	item:show()
	local key = data[index].key
	local num = data[index].num
	local isDouble = data[index].isDouble
	local binds = {
		class = "icon_key",
		props = {
			data = {
				key = key,
				num = num,
			},
			isDouble = isDouble,
			onNode = function(node)
				local x,y = node:xy()
				node:xy(x, y+3)
				node:hide()
					:z(2)
				transition.executeSequence(node, true)
					:delay(0.5)
					:func(function()
						node:show()
					end)
					:done()
			end,
		},
	}
	bind.extend(self, item, binds)
	self.awardsList:pushBackCustomItem(item)
	transition.executeSequence(self.awardsList, true)
		:delay(0.25)
		:func(function()
			if index < csvSize(data) then
				self:showItem(index + 1, data)
			end
		end)
		:done()
end

function BattleEndWorldBossView:onPanelClick()
	gGameUI:switchUI("city.view")
end

return BattleEndWorldBossView

