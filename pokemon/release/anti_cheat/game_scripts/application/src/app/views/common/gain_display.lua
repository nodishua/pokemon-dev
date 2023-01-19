-- @date: 2018-10-18
-- @desc: 通用恭喜获得展示界面

local insert = table.insert
local LINE_NUM = 8 -- 一行显示的数量
local PANELWIDTH = 0

local function createSpine(parent, key, action, zOrder)
	return widget.addAnimationByKey(parent, "effect/jiesuanjiemian.skel", key, action, zOrder)
		:xy(96, 145)
end

local ViewBase = cc.load("mvc").ViewBase
local GainDisplayView = class("GainDisplayView", ViewBase)
GainDisplayView.RESOURCE_FILENAME = "common_gain_display.json"
GainDisplayView.RESOURCE_BINDING = {
	["imgBG"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose")
		},
	},
	["list"] = "list",
	["innerList"] = "innerList",
	["item"] = "item",
	["textNote"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("canClose")
		}
	}
}

GainDisplayView.RESOURCE_STYLES = {
	backGlass = true,
}

-- @param data {{"gold", 1}, {"rmb", 1}, {"gold", 2}} or csvData {key = num}
-- @param params {raw, cb}
-- raw:是服务器原始过来的数据, 缺省nil为服务器数据
function GainDisplayView:onCreate(data, params)
	audio.playEffectWithWeekBGM("item_gain.mp3")
	params = params or {}
	if data.view then
		if data.view.regainD then
			for k, v in pairs(data.view.regainD) do
				gGameUI:showTip(string.format(gLanguageCsv.regainOnlyItem, uiEasy.setIconName(k, v)))
			end
			data.view.regainD = {}
		end
	else
		if data.regainD then
			for k, v in pairs(data.regainD) do
				gGameUI:showTip(string.format(gLanguageCsv.regainOnlyItem, uiEasy.setIconName(k, v)))
			end
			data.regainD = {}
		end
	end
	self.canClose = idler.new(true)
	self.cb = params.cb
	self.hadSprite = {}
	self.isDouble = params.isDouble -- 奖励双倍
	if params.tips then self:showTips(params.tips) end
	if not self.isDouble then
		self.onlyGoldDouble = params.onlyGoldDouble -- 仅金币双倍
	end
	if params.raw == false then
		self.data = dataEasy.getItemData(data)
	else
		self.data, self.isFull, self.isHaveTip = dataEasy.mergeRawDate(data)
	end
	if #self.data == 0 then
		self:hide()
		performWithDelay(self, handler(self, "onClose"), 0)
		return
	end

	self.canClose:set(false)
	idlereasy.if_(self.canClose, function()
		if #self.data > LINE_NUM * 2 then
			self.list:setTouchEnabled(true)
		end
	end)
	self.intervalTime = 0.25

	self.list:setScrollBarEnabled(false)
	self.innerList:setScrollBarEnabled(false)
	self.list:setTouchEnabled(false)
	self.innerList:setTouchEnabled(false)
	local listSize = self.list:size()
	local subListSize = self.innerList:size()
	local itemSize = self.item:size()
	local num = #self.data
	self.hasMoreCard = false
	self.isFirstShow = true
	local count = 0
	for _,v in pairs(self.data) do
		if v.specialFlag == "card" then
			count = count + 1
		end
		if count > 1 then
			self.hasMoreCard = true
			break
		end
	end
	if num <= LINE_NUM then
		local margin = self.innerList:getItemsMargin()
		-- (PANELWIDTH + margin) / 2 减去前面填充部分 因为视觉上中心点是item
		local x = self.list:x() + (listSize.width - itemSize.width * num - num * margin - PANELWIDTH) / 2 - (PANELWIDTH + margin) / 2
		local y = self.list:y() - 200
		self.list:xy(x , y)

	elseif num <= LINE_NUM * 2 then
		self.list:setTouchEnabled(false)
		local y = self.list:y() - 100
		self.list:y(y)
	end

	self:showItem(1)

	-- 恭喜获得特效
	local pnode = self:getResourceNode()
	widget.addAnimationByKey(pnode, "effect/gongxihuode.skel", 'gongxihuode', "effect", 10)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(pnode:width()/2, pnode:height() - 300)
		:addPlay("effect_loop")
end

function GainDisplayView:onClose()
	if self.canClose:read() then
		self:addCallbackOnExit(self.cb)
		ViewBase.onClose(self)
	else
		self.intervalTime = 0
	end
end

function GainDisplayView:showTips(data)
	local x, y = data.position.x, data.position.y
	local anchorX, anchorY = data.anchorPoint.x, data.anchorPoint.y
	rich.createByStr(data.str, data.foneSize)
		:xy(x, y)
		:anchorPoint(anchorX, anchorY)
		:addTo(self, 5)
end

function GainDisplayView:showItem(index)
	if index > #self.data then
		performWithDelay(self, function()	-- 道具加载特效时长
			self.canClose:set(true)
			userDefault.setForeverLocalKey("isJumpSpriteView", false)
		end, 12/30)
		return
	end
	if index % LINE_NUM == 1 then
		-- 尾部
		if self.curSubList then
			local panel = ccui.Layout:create():size(PANELWIDTH, 245)
			-- panel:setBackGroundColorType(1)
			-- panel:setBackGroundColor(cc.c3b(200, 0, 0))
			-- panel:setBackGroundColorOpacity(100)
			self.curSubList:pushBackCustomItem(panel)
		end
		self.curSubList = self.innerList:clone()
		self.curSubList:show()
		self.list:pushBackCustomItem(self.curSubList)
			:refreshView()
			:scrollToBottom(0.3, true)
		local panel = ccui.Layout:create():size(PANELWIDTH, 245)
		-- panel:setBackGroundColorType(1)
		-- panel:setBackGroundColor(cc.c3b(200, 0, 0))
		-- panel:setBackGroundColorOpacity(100)
		self.curSubList:pushBackCustomItem(panel)
	end
	if index == 1 and self.isHaveTip then
		gGameUI:showTip(gLanguageCsv.autoDecompose)
		performWithDelay(self, function (val)
			self:showDetaiItem(index)
		end, 1)
	else
		self:showDetaiItem(index)
	end

end

function GainDisplayView:showDetaiItem(index)
	local data = self.data[index]
	if data.specialFlag == "card" then
		local cardId = gGameModel.cards:find(data.dbid):read("card_id")
		local cfg = csv.cards[cardId]
		local rarity = csv.unit[cfg.unitID].rarity
		local isJumpSpriteView = userDefault.getForeverLocalKey("isJumpSpriteView", false)
		if not isJumpSpriteView or rarity >= gCommonConfigCsv.showCardRarityMin or (data.new and not self.hadSprite[cardId]) then
			local isShowBtn = nil
			if self.isFirstShow and self.hasMoreCard then
				isShowBtn = true
				self.isFirstShow = false
			elseif self.isFirstShow and not self.hasMoreCard then
				isShowBtn = false
			end
			gGameUI:stackUI("common.gain_sprite", {
				cb = self:createHandler("handlerShowItem", index, data),
			}, {full = true}, data, self.hadSprite, isShowBtn)
		else
			self:handlerShowItem(index, data)
		end
	else
		local sign, skinData = dataEasy.isSkinByKey(data.key)
		if sign then
			gGameUI:stackUI("city.card.skin.award", {
				cb = self:createHandler("handlerShowItem", index, data),
			}, {full = true},skinData.skinID,skinData.days)
		else
			self:handlerShowItem(index, data)
		end
	end
end

function GainDisplayView:handlerShowItem(index, data)
	local item = self.item:clone()
	item:show()
	local size = item:size()
	local key = data.key
	local num = data.num
	local isExtra = data.specialKey == "extra"
	local isDouble = self.isDouble
	if not isDouble and key == "gold" then
		isDouble = self.onlyGoldDouble
	end
	bind.extend(self, item, {
		class = "icon_key",
		props = {
			data = {
				key = key,
				num = num,
				dbId = data.dbId,
			},
			effect = "gain",
			isExtra = isExtra,
			isDouble = isDouble,
			onNode = function(node)
				node:xy(size.width/2, size.height/2 + 20)
					:hide()
					:z(3)
					:scale(1.25)
				transition.executeSequence(node, true)
					:delay(0.5)
					:func(function()
						node:show()
					end)
					:done()
			end,
		},
	})
	local quality = 1
	if string.find(key, "star_skill_points_%d+") then
		local markId = tonumber(string.sub(key, string.find(key, "%d+")))
		local cardCfg = csv.cards[markId]
		quality = csv.fragments[cardCfg.fragID].quality

	elseif key ~= "card" then
		quality = dataEasy.getCfgByKey(key).quality
	end
	widget.addAnimationByKey(item, "effect/jiesuanjiemian.skel", "djhd_hou", "djhd_hou"..quality, 2)
		:xy(size.width/2, size.height/2 + 20)
		:scale(1.25)
	widget.addAnimationByKey(item, "effect/jiesuanjiemian.skel", "djhd", "djhd"..quality, 4)
		:xy(size.width/2, size.height/2 + 20)
		:scale(1.25)

	local name, effect = uiEasy.setIconName(key, num)
	beauty.singleTextLimitWord(name, {fontSize = 40}, {width =  240})
		:xy(size.width/2, 20)
		:addTo(item, 10)
	self.curSubList:pushBackCustomItem(item)
	audio.playEffectWithWeekBGM("iconpopup.mp3")
	transition.executeSequence(self.list, true)
		:delay(self.intervalTime)
		:func(function()
			self:showItem(index + 1)
		end)
		:done()
	if index == #self.data and self.isFull then
		gGameUI:showDialog{content = gLanguageCsv.cardBagHaveBeenFull}
	end
end

return GainDisplayView
