--
-- 日常活动副本结算
--

local BattleEndDailyActivityView = class("BattleEndDailyActivityView", cc.load("mvc").ViewBase)

BattleEndDailyActivityView.RESOURCE_FILENAME = "battle_end_daily_activity.json"
BattleEndDailyActivityView.RESOURCE_BINDING = {
	["bkg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onPanelClick"),
		},
	},
	["awardsList"] = "awardsList",
	["cardItem"] = "awardsItem",
	["bkg.exitText"] = "exitText",
	["scoreText"] = "scoreText",
	["score"] = "score",
	["progressText"] = "progressText",
	["progressImg"] = "progressImg",
	["progress"] = "progress",
}

function BattleEndDailyActivityView:onCreate(sceneID, results)
	audio.playEffectWithWeekBGM("pve_win.mp3")
	self.results = results
	local pnode = self:getResourceNode()

	results = results or {}
	local serverData = results.serverData or {}
	local viewData = serverData.view or {}
	local dropInfo = viewData.award or viewData.drop or {}
	local damage = results.damage
	local maxHp = results.hpMax

	local sceneCfg = csv.scene_conf[sceneID]

	local textEffect = widget.addAnimation(pnode, "level/newzhandoushengli.skel", "effect", 100)
	textEffect:anchorPoint(cc.p(0.5,0.5))
		:xy(pnode:get("title"):getPosition())
		:addPlay("effect_loop")

	self.exitText:text(gLanguageCsv.click2Exit)
	pnode:get("pjText"):text(gLanguageCsv.battleEvaluation.. " :")
	-- 评价
	if results.socre then
		self.scoreText:text(gLanguageCsv.battleScore .. " :")
	else
		self.scoreText:text(gLanguageCsv.damageMade .. " :")
	end
	self.score:text(math.floor(results.socre or damage or 1))
	self.progressText:text(gLanguageCsv.battleProgress .. " :")

	local progress = results.percent
	if not progress then
		damage = damage or 0
		maxHp = maxHp or 1
		local dmgPer = damage * 100 / maxHp
		progress = (dmgPer - dmgPer % 0.01) --取两位小数
	end

	local widget = self.progressImg

	if damage or maxHp then
		widget:hide()
		self.progress:text(progress .. "%")
	else
		local rankNode = results.rankNode or 1
		local rankRes = {
			[1] = "city/adventure/win/txt_b.png",
			[2] = "city/adventure/win/txt_a.png",
			[3] = "city/adventure/win/txt_s.png",
			[4] = "city/adventure/win/txt_ss.png",
			[5] = "city/adventure/win/txt_sss.png",
		}

		local res = rankRes[rankNode]
		widget:loadTexture(res)
		if sceneCfg.gateType == game.GATE_TYPE.dailyGold then
			self.progress:text(progress .. "%")
		elseif sceneCfg.gateType == game.GATE_TYPE.dailyExp then
			local killNumber = sceneCfg.finishPoint.killNumber
			local percent = math.floor(progress/killNumber*100)
			self.progress:text(percent .. "%")
		end
	end
	adapt.oneLinePos(self.scoreText, self.score, cc.p(5,0))
	adapt.oneLinePos(self.progressText, {self.progressImg, self.progress}, cc.p(5,0))

	-- 奖励文字 getAwards
	pnode:get("awardsText"):text(gLanguageCsv.getAwards .. " :")
	if sceneCfg.gateType == game.GATE_TYPE.crossMineBoss then
		if viewData.score and viewData.score ~= 0 then
			local awardsText = pnode:get("awardsText")
			local mineGetText = cc.Label:createWithTTF("", ui.FONT_PATH, 47)
				:color(cc.c3b(91, 84, 91))
				:align(cc.p(0, 0.5), self.progressText:x(), awardsText:y())
				:addTo(pnode, 2, "mineGetText")
				:show()
				:text(gLanguageCsv.crossMineBossScore)
			local mineScoreText = cc.Label:createWithTTF("", ui.FONT_PATH, 50)
				:color(cc.c3b(238, 114, 14))
				:align(cc.p(0, 0.5), self.score:x(), awardsText:y())
				:addTo(pnode, 2, "mineScoreText")
				:show()
				:text("+" .. viewData.score)
			adapt.oneLinePos(mineGetText, mineScoreText, cc.p(16,0))
		end
	end

	local isDouble = dataEasy.isGateIdDoubleDrop(sceneID)

	if next(dropInfo) ~= nil then
		local tmpData = {}
		for k,v in pairs(dropInfo) do
			-- if type(k) == "string" then
			-- 	k = dataEasy.stringMapingID(k)
			-- end
			table.insert(tmpData, {key = k, num = v, isDouble = isDouble})
		end
		self:showItem(1, tmpData)
	end
end

function BattleEndDailyActivityView:showItem(index, data)
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
	self.awardsList:setItemsMargin(25)
	self.awardsList:pushBackCustomItem(item)
	self.awardsList:setScrollBarEnabled(false)
	transition.executeSequence(self.awardsList, true)
		:delay(0.25)
		:func(function()
			if index < csvSize(data) then
				self:showItem(index + 1, data)
			end
		end)
		:done()
end

function BattleEndDailyActivityView:onPanelClick()
	gGameUI:switchUI("city.view")
end

return BattleEndDailyActivityView

