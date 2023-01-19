--
--  远征战斗胜利界面
--

local HuntingWinView = class("HuntingWinView", cc.load("mvc").ViewBase)

HuntingWinView.RESOURCE_FILENAME = "battle_end_hunting_win.json"
HuntingWinView.RESOURCE_BINDING = {
	["awardsList"] = "awardsList",
	["awardsItem"] = "awardsItem",
	["bkg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onQuitClick"),
		},
	}
}

function HuntingWinView:playEndEffect()
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
function HuntingWinView:onCreate(battleView, sceneID, data, results)
	audio.playEffectWithWeekBGM("gate_win.mp3")
    self.data = data
	self.results = results
    self.sceneID = sceneID
	local pnode = self:getResourceNode()


	-- 结算特效
	self:playEndEffect()

	self:showCardStateInfo()

	-- 奖励文字 getAwards
	local awardsText = pnode:get("awardsText")
	awardsText:text(gLanguageCsv.getAwards  .. ":")

	local dropInfo = results.serverData.drop or {}
	local tmpData = dataEasy.mergeRawDate(dropInfo)
	if next(tmpData) then
		self:showItem(1, tmpData)
	else
		local x, y = awardsText:xy()
		awardsText:xy(x + 325, y)
		awardsText:text(gLanguageCsv.passAwardsAlreadyToplimit)
		self.awardsList:hide()
	end
end

function HuntingWinView:showItem(index, data)
	local item = self.awardsItem:clone()
	item:show()
	local key = data[index].key
	local num = data[index].num
	local dbId = data[index].dbId
	local binds = {
		class = "icon_key",
		props = {
			data = {
				key = key,
				num = num,
				dbId = dbId
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

-- 卡牌显示相关
function HuntingWinView:showCardStateInfo()
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

function HuntingWinView:onQuitClick()
	gGameUI:switchUI("city.view")
end

return HuntingWinView