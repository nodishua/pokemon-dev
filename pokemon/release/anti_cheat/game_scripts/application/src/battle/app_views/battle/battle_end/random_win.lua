--
--  随机塔战斗胜利界面
--

local BattleEndRandomWinView = class("BattleEndRandomWinView", cc.load("mvc").ViewBase)

BattleEndRandomWinView.RESOURCE_FILENAME = "battle_end_random_win.json"
BattleEndRandomWinView.RESOURCE_BINDING = {
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
	["bkg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onDungeonsBtnClick")
		},
	},
	["text2"] = "text2",
	["awardsList"] = "awardsList",
	["cardItem.card"] = "awardsItem",
}

function BattleEndRandomWinView:playEndEffect()
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
function BattleEndRandomWinView:onCreate(battleView, results)
	audio.playEffectWithWeekBGM("gate_win.mp3")

	self.battleView = battleView
	self.data = battleView.data
	self.sceneID = battleView.sceneID
	self.results = results

	if matchLanguage({"en"}) then
		self.text2:ignoreContentAdaptWithSize(false)
    	self.text2:setContentSize(cc.size(450,200))
    	self.text2:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    	self.text2:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    	self.text2:y(self.text2:y() - 22)
    end
	local pnode = self:getResourceNode()
	local btnTextTb = {
		backBtn = "back2City",
		againBtn = "playAgain",
		dungeonsBtn = "dungeonList",
	}
	for btnName, str in pairs(btnTextTb) do
		pnode:get(btnName .. ".text"):text(gLanguageCsv[str])
	end

	self:showPlayerScoreInfo()

	-- 结算特效
	self:playEndEffect()

	self:showStarsInfo()

	self:showCardStateInfo()

	self:showItemInfo()
end

-- 玩家积分显示相关
function BattleEndRandomWinView:showPlayerScoreInfo()
	local sceneID = self.sceneID
	local pnode = self:getResourceNode()
	local results = self.results
	local serverData = results.serverData or {}
	local point = serverData.point

	local str = point >= 0 and "+" or "-"
	local children = pnode:multiget("score", "levelTextNote", "levelTextExtre")
	children.score:text(str..tostring(point))
	adapt.oneLinePos(children.levelTextNote, {children.score, children.levelTextExtre}, cc.p(10,0))
end

-- 星级条件相关信息
function BattleEndRandomWinView:showStarsInfo()
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

-- 卡牌显示相关
function BattleEndRandomWinView:showCardStateInfo()
	local results = self.results
	local pnode = self:getResourceNode()
	local cardStates = results.cardStates or {}
	local roleOut = self.data.roleOut or {}

	local cardsList = pnode:get("cardsList")
	cardsList:setScrollBarEnabled(false)
	cardsList:setItemsMargin(25)
	for idx, cardData in pairs(roleOut) do
		if idx <= 6 then
			local item = pnode:get("cardItem"):clone()
			cardsList:pushBackCustomItem(item)
			bind.extend(self, item:get("card"), {
				class = "card_icon",
				props = {
					unitId = cardData.roleId,
					advance = cardData.advance,
					star = cardData.star,
					rarity = csv.unit[cardData.roleId].rarity,
				}
			})
			local tb = cardStates[cardData.cardId]
			if tb then
				item:get("hpBar"):setPercent(math.floor(tb[1] * 100))
				item:get("mpBar"):setPercent(math.floor(tb[2] * 100))
				item:get("mask"):visible(tb[1] <= 0)
			end
		end
	end
end

-- 道具显示相关
function BattleEndRandomWinView:showItemInfo()
	local pnode = self:getResourceNode()
	local results = self.results
	local serverData = results.serverData or {}
	local dropInfo = serverData.award or {}

	-- -- 奖励文字 getAwards
	-- pnode:get("awardsText"):text(gLanguageCsv.getAwards  .. " :")

	local tmpData = {}
	local insertTabel = function (tb)
		if next(tb) then
			for k,v in csvMapPairs(tb) do
				local t = {key = k, num = v}
				table.insert(tmpData, t)
			end
		end
	end

	if next(dropInfo) ~= nil then
		insertTabel(dropInfo)
	end

	-- 不显示奖励
	-- self:showItem(1, tmpData, 0)
end

function BattleEndRandomWinView:showItem(index, data)
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

-- 返回主城
function BattleEndRandomWinView:onBackBtnClick()
	gGameUI:switchUI("city.view")
end

-- 再战一次
function BattleEndRandomWinView:onAgainBtnClick()
	local entrance = self.battleView.entrance
	entrance:restart()
	-- battleEntrance.battleRequest("/game/start_gate", self.data.sceneID):show()
end

-- 返回关卡
function BattleEndRandomWinView:onDungeonsBtnClick()
	gGameUI:switchUI("city.view")
end

return BattleEndRandomWinView

