--
--  战斗胜利界面 -- 通用的界面
--

local BattleEndWinView = class("BattleEndWinView", cc.load("mvc").ViewBase)

BattleEndWinView.RESOURCE_FILENAME = "battle_end_win.json"
BattleEndWinView.RESOURCE_BINDING = {
	["backBtn.text"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["againBtn.text"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["dungeonsBtn.text"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["backBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBackBtnClick")}
		},
	},
	["againBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAgainBtnClick")}
		},
	},
	["dungeonsBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDungeonsBtnClick")}
		},
	},
	["awardsList"] = "awardsList",
	["cardItem.card"] = "awardsItem",
	["text2"] = "text2",
	["worldLvExp"] = "worldLvExp",
}

function BattleEndWinView:playEndEffect()
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
function BattleEndWinView:onCreate(battleView, results)
	audio.playEffectWithWeekBGM("gate_win.mp3")

	self.battleView = battleView
	self.data = battleView.data
	self.sceneID = battleView.sceneID
	self.results = results
	self.text2:ignoreContentAdaptWithSize(false)
	self.text2:setContentSize(cc.size(450,200))
	self.text2:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
	self.text2:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
	self.text2:getVirtualRenderer():setLineSpacing(-5)
	local pnode = self:getResourceNode()
	local btnTextTb = {
		backBtn = "back2City",
		againBtn = "playAgain",
		dungeonsBtn = "dungeonList",
	}
	for btnName, str in pairs(btnTextTb) do
		pnode:get(btnName .. ".text"):text(gLanguageCsv[str])
	end

	self:showPlayerExpInfo()

	-- 结算特效
	self:playEndEffect()

	self:showStarsInfo()

	self:showCardExpInfo()

	self:showItemInfo()

	performWithDelay(self, function()
		uiEasy.showMysteryShop()
		uiEasy.showActivityBoss()
	end, 0.5)
end

-- 玩家经验条显示相关
function BattleEndWinView:showPlayerExpInfo()
	local sceneID = self.sceneID
	local pnode = self:getResourceNode()
	local data = self.data
	local preData = data.preData or {}
	local roleInfo = preData.roleInfo or {}
	local sceneCfg = csv.scene_conf[sceneID]
	local serverDataView = self.results.serverData.view --
	-- 等级 roleLevel
	pnode:get("levelText"):text(gLanguageCsv.roleLevel  .. " :")
	-- 等级数字
	local newLevel = gGameModel.role:read("level")
	pnode:get("level"):text(newLevel or 1)

	-- 经验条
	local fullExp = csv.base_attribute.role_level[roleInfo.level].levelExp or 10
	local hasExp = roleInfo.level_exp or 1
	local addExp = sceneCfg.roleExp	or 1				-- 读表的
	--世界额外经验加成
	local worldExp = serverDataView.role.addExp - addExp
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

	--世界等级额外经验
	if worldExp == 0 then
		pnode:get("exp"):text("+" .. addExp)
		self.worldLvExp:hide()
	else
		adapt.oneLinePos(pnode:get("exp"):text("+" .. addExp), pnode:get("worldLvExp"):text("(+"..worldExp..")"), cc.p(10,0))
	end
	checkLevelUp(newExp, fullExp)
end

-- 星级条件相关信息
function BattleEndWinView:showStarsInfo()
	local pnode = self:getResourceNode()
	local results = self.results
 	-- 星级条件
	local conditionTb = results.conditionTb
	-- 获取条件达成的状态记录
	local gateStarTb = results.gateStarTb
	if conditionTb and gateStarTb then
		-- 设置条件文字
		for i=1, 3 do
			local idx, needNum = conditionTb[i][1], conditionTb[i][2]
			local cond = gateStarTb[i][1]
			local textNode = pnode:get("text" .. i)
			textNode:text(string.format(gLanguageCsv["starCondition" .. idx], needNum))
			-- -- 默认绿色的描边字
			text.addEffect(textNode, {color=ui.COLORS.NORMAL.LIGHT_GREEN})
			if not cond then
				text.addEffect(textNode, {color=cc.c4b(236, 183, 42, 255)})		-- 某种黄色
			end
			pnode:get("star" .. i .. ".achieve"):setVisible(cond)
		end
	end
end

-- 卡牌经验与升级 显示相关
function BattleEndWinView:showCardExpInfo()
	local newLevel = gGameModel.role:read("level")			-- 玩家当前等级
	local sceneID = self.sceneID
	local data = self.data
	local pnode = self:getResourceNode()
	local preData = data.preData or {}
	local cardsInfo = preData.cardsInfo or {}
	local sceneCfg = csv.scene_conf[sceneID]

	-- 卡牌的经验值文字  exps
	pnode:get("expText"):text(gLanguageCsv.exps .. " :")
	local getCardExpInfo = function (cardData, addExp)
		local roleOutInfo = data.roleOut[cardData.id]
		local card = gGameModel.cards:find(roleOutInfo.cardId)
		-- 注意 此处精灵已经升级完毕 next_level_exp 获得是当前等级 升至下一级所需经验
		local hasExp = card:read("level_exp")
		local fullExp = card:read("next_level_exp")
		local curLevel = card:read("level")
		return curLevel > cardData.level, curLevel, hasExp > fullExp
	end
	-- list
	local cardsList = pnode:get("cardsList")
	cardsList:setScrollBarEnabled(false)
	cardsList:setItemsMargin(25)
	for _, cardData in ipairs(cardsInfo) do
		local isLevelUp, curLevel, isExpFull = getCardExpInfo(cardData, sceneCfg.cardExp)
		local preLevel = cardData.level 			-- 精灵之前的等级（可能和现在的等级一样）
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
					data = curLevel,
				},
				onNode = function(panel)
					-- panel:xy(21, 20)
				end,
			}
		})
		if isExpFull then
			item:get("exp"):text(gLanguageCsv.experienceFull)
		else
			item:get("exp"):text("EXP+" .. sceneCfg.cardExp)
		end
		item:get("levelUp"):visible(isLevelUp)
		cardsList:pushBackCustomItem(item)
	end
end

-- 道具显示相关
function BattleEndWinView:showItemInfo()
	local pnode = self:getResourceNode()
	local data = self.data
	local preData = data.preData or {}
	local roleInfo = preData.roleInfo or {}
	local dropInfo = preData.drop or {}
	local newLevel = gGameModel.role:read("level")

	-- 奖励文字 getAwards
	pnode:get("awardsText"):text(gLanguageCsv.getAwards  .. " :")

	local tmpData = {}
	local isDouble = dataEasy.isGateIdDoubleDrop(self.sceneID)
	local insertTabel = function (tb, tbKey)
		for k,v in csvMapPairs(tb) do
			local t = {key = k, num = v, isDouble = isDouble}
			if tbKey then
				t[tbKey] = true
			end
			table.insert(tmpData, t)
		end
	end

	local serverDataView = self.results.serverData.view

	if serverDataView then
		-- 此处为噩梦难度副本
		local first = serverDataView.first or {}
		local star3 = serverDataView.star3 or {}
		insertTabel(first, "first")			-- 首通
		insertTabel(star3, "star3")			-- 三星
	end
	-- 此处为普通和困难副本
	insertTabel(dropInfo)

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

function BattleEndWinView:showItem(index, data)
	local function addResToItem(node, res)
		local size = node:size()
		local sp = cc.Sprite:create(res)
		:addTo(node, 999)
		:anchorPoint(1, 1)
		:xy(size.width, size.height)
	end

	local item = self.awardsItem:clone()
	item:show()
	local value = data[index]
	local binds = {
		class = "icon_key",
		props = {
			data = {
				key = value.key,
				num = value.num,
			},
			isDouble = value.isDouble,
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
				local res
				if value.first then
					addResToItem(node, "city/adventure/endless_tower/icon_st.png")
				elseif value.star3 then
					addResToItem(node, "city/gate/icon_sx.png")
				end
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

function BattleEndWinView:onBackBtnClick()
	gGameUI:cleanStash()
	gGameUI:switchUI("city.view")
end

function BattleEndWinView:onAgainBtnClick()
	local entrance = self.battleView.entrance
	entrance:restart()
	-- battleEntrance.battleRequest("/game/start_gate", self.data.sceneID):show()
end

function BattleEndWinView:onDungeonsBtnClick()
	gGameUI:switchUI("city.view")
end

return BattleEndWinView

