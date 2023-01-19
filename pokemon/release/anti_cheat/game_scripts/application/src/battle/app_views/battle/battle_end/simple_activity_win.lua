--
--  战斗胜利界面 -- 通用的界面
--

local SimpleActivityWinView = class("SimpleActivityWinView", cc.load("mvc").ViewBase)

SimpleActivityWinView.RESOURCE_FILENAME = "battle_end_frags_win.json"
SimpleActivityWinView.RESOURCE_BINDING = {
	["awardsList"] = "awardsList",
	["cardItem.card"] = "awardsItem",
	["bkg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onQuitClick"),
		},
	},
}

function SimpleActivityWinView:playEndEffect()
	local pnode = self:getResourceNode()
	-- 结算特效
	local textEffect = CSprite.new("level/jiesuanshengli.skel")		-- 文字部分特效
	textEffect:addTo(pnode, 100)
	textEffect:setAnchorPoint(cc.p(0.5,1.0))
	textEffect:setPosition(pnode:get("title"):getPosition())
	textEffect:visible(true)
	-- 播放结算特效
	textEffect:play("jiesuan_shenglizi")
	textEffect:addPlay("jiesuan_shenglizi_loop")
	textEffect:retain()

	local bgEffect = CSprite.new("level/jiesuanshengli.skel")		-- 底部特效
	bgEffect:addTo(pnode, 99)
	bgEffect:setAnchorPoint(cc.p(0.5,1.0))
	bgEffect:setPosition(pnode:get("title"):getPosition())
	bgEffect:visible(true)
	-- 播放结算特效
	bgEffect:play("jiesuan_shenglitu")
	bgEffect:addPlay("jiesuan_shenglitu_loop")
	bgEffect:retain()
end

-- results: 放数据的
function SimpleActivityWinView:onCreate(sceneID, data, results)
	audio.playEffectWithWeekBGM("gate_win.mp3")
	self.data = data
	self.results = results
	self.sceneID = sceneID
	local pnode = self:getResourceNode()

	local preData = data.preData or {}
	local roleInfo = preData.roleInfo or {}
	local cardsInfo = preData.cardsInfo or {}
	local dropInfo = results.serverData.view.drop or {}
	local awardInfo = results.serverData.view.award or {}
	local showItemInfo = {}
	for k,v in pairs(dropInfo) do
		showItemInfo[k] = v
	end
	for k,v in pairs(awardInfo) do
		if not showItemInfo[k] then
			showItemInfo[k] = v
		else
			showItemInfo[k] =showItemInfo[k] + v
		end
	end
	local sceneCfg = csv.scene_conf[sceneID]

	-- 等级 roleLevel
	pnode:get("levelText"):text(gLanguageCsv.roleLevel  .. " :")
	-- 等级数字
	local newLevel = gGameModel.role:read("level")
	pnode:get("level"):text(newLevel or 1)
	-- 经验条
	local fullExp = csv.base_attribute.role_level[roleInfo.level].levelExp or 10
	local hasExp = roleInfo.level_exp or 1
	local addExp = sceneCfg.roleExp	or 1				-- 读表的
	local newExp = hasExp + addExp
	local progressTime = 1.1

	local setProgress = function (startPos, endPos, cb)
		pnode:get("expBar.expNew"):setPercent(startPos)
		transition.executeSequence(pnode:get("expBar.expNew"))
	 		:progressTo(progressTime, endPos)
	 		:func(function ()
	 			if cb then
	 				cb()
	 			end
	 		end)
	 		:done()
	end

	local function checkLevelUp(newExp, fullExp)
		local moreExp = newExp - fullExp
		if moreExp >= 0 then		-- 升级了(有可能升级多个等级)
			progressTime = 0.5
		 	setProgress(math.floor(hasExp/fullExp*100), 100, function ()
				local nextLevel = (roleInfo.level or 1) + 1
				fullExp = csv.base_attribute.role_level[nextLevel].levelExp or 10
				pnode:get("expBar.expNew"):setPercent(0)
				hasExp = 0
				checkLevelUp(moreExp, fullExp)
		 	end)
		else
		 	setProgress(math.floor(hasExp/fullExp*100), math.floor(newExp/fullExp*100))
		end
	end

	pnode:get("exp"):text("+" .. addExp)
	checkLevelUp(newExp, fullExp)

	-- 结算特效
	self:playEndEffect()

	if results.flag == "gym" then
		pnode:get("expText"):hide()
		pnode:get("cardsList"):hide()
		local baseY = pnode:get("bkg"):y()
		pnode:get("awardsText"):y(baseY - 64)
		self.awardsList:y(baseY - 228)
	else
		-- 卡牌的经验值文字  exps
		pnode:get("expText"):text(gLanguageCsv.exps .. " :")
		local getCardExpInfo = function (cardData, addExp)
			local roleOutInfo = data.roleOut[cardData.id]
			local card = gGameModel.cards:find(cardData.cardId or roleOutInfo.cardId)
			local hasExp = card:read("level_exp")
			local fullExp = card:read("next_level_exp")
			local isLevelUp = fullExp < (hasExp + addExp)
			local levelCount = 0
			if isLevelUp then
				local newExp = hasExp + addExp
				local unitCsv = csv.unit[cardData.unitId]
				local cardCsv = csv.cards[unitCsv.cardID]
				local levelExpID = cardCsv.levelExpID
				while fullExp < newExp do
					levelCount = levelCount + 1
					newExp = newExp - fullExp	-- 升级后 剩余经验值
					if cardData.level + levelCount >= 100 then break end -- 等级上线100级
					-- 按配表重新查找经验上限
					fullExp = csv.base_attribute.card_level[cardData.level + levelCount]["levelExp"..levelExpID]
				end
			end

			return isLevelUp, levelCount
		end
		-- list
		local cardsList = pnode:get("cardsList")
		cardsList:setScrollBarEnabled(false)
		cardsList:setItemsMargin(25)
		for _, cardData in ipairs(cardsInfo) do
			local isLevelUp, levelCount = getCardExpInfo(cardData, sceneCfg.cardExp)
			local item = pnode:get("cardItem"):clone()
			local card = item:get("card")
			bind.extend(self, card, {
				class = "card_icon",
				props = {
					unitId = cardData.unitId,
					advance = cardData.advance,
					star = cardData.star,
					rarity = csv.unit[cardData.unitId].rarity,
					levelProps = {
						data = cardData.level + levelCount,
					},
					onNode = function(panel)
						-- panel:xy(21, 20)
					end,
				}
			})
			item:get("exp"):text("EXP+" .. sceneCfg.cardExp)
			item:get("levelUp"):visible(isLevelUp)
			cardsList:pushBackCustomItem(item)
		end
	end

	-- 奖励文字 getAwards
	pnode:get("awardsText"):text(gLanguageCsv.getAwards  .. " :")
	local tmpData = {}
	for k,v in pairs(showItemInfo) do
		table.insert(tmpData, {key = k, num = v})
	end
	if next(tmpData) then
		self:showItem(1, tmpData)
	end

	gGameUI:disableTouchDispatch(nil, false)
	transition.executeSequence(self)
		:delay(0.25)
		:func(function()
			if newLevel - roleInfo.level > 0 then
				gGameUI:stackUI("common.upgrade_notice", nil, nil, roleInfo.level)
			end
			gGameUI:disableTouchDispatch(nil, true)
		end)
		:done()
end

function SimpleActivityWinView:showItem(index, data)
	local item = self.awardsItem:clone()
	item:show()
	local key = data[index].key
	local num = data[index].num
	local binds = {
		class = "icon_key",
		props = {
			data = {
				key = key,
				num = num,
			},
			isDouble = dataEasy.isGateIdDoubleDrop(self.sceneID),
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
	transition.executeSequence(self.awardsList)
		:delay(0.1)
		:func(function()
			if index < table.length(data) then
				self:showItem(index + 1, data)
			end
		end)
		:done()
end

function SimpleActivityWinView:onQuitClick()
	gGameUI:switchUI("city.view")
end

return SimpleActivityWinView

