-- @Date:   2019-02-18
-- @Desc:
-- @Last Modified time: 2019-05-29
local helper = require "easy.bind.helper"
local redHintHelper = require "app.easy.bind.helper.red_hint"
local redHintHelperTags = require "app.easy.bind.helper.red_hint_tags"
local redHint = class("redHint", cc.load("mvc").ViewBase)

local childName = "_redHint_"
local sprName = "spr"
local textName = "txt"
local RES_NAME = {
	normal = "common/icon/logo_redhint.png",
	num = "common/icon/logo_redhint_num.png",
	new = "other/gain_sprite/txt_new.png"
}

redHint.defaultProps = {
	-- type
	showType = "normal",
	-- bool or idler tab切换的标志，只有为true的时候后续的listenData的func的值才有效，否则false隐藏
	state = true,
	-- {idlertable, idler, ...} or nil,
	listenData = nil,
	-- needNum
	num = nil,
	-- funcTag or onlyTag
	specialTag = nil,
	-- redHintHelper`s function or this or other
	func = nil,
	onNode = nil,
}


local function always_true()
	return true
end

function redHint:bindAllCardsByDbid(dbId, f)
	if dbId == nil then
		return
	end

	local data = dbId
	if helper.isIdler(data) then
		data = data:read()
	end

	local card = gGameModel.cards:find(data)
	if not card then return end
	local midlers = card:getIdler()
	midlers:addListener(function(msg, idlers)
		f()
	end)
end

function redHint:setNum(num)
	local panel = self:getChildByName(childName)
	local txt = panel:get(textName)
	txt:text(num)
	local spr = panel:get(sprName)
	spr:size(txt:size().width + 51, spr:size().height)
end

function redHint:createPanel()
	local spr
	local txtLevel
	if self.showType ~= "num" then
		spr = cc.Sprite:create(RES_NAME[self.showType])
	else
		spr = ccui.Scale9Sprite:create()
		spr:initWithFile(cc.rect(28, 30, 13, 7), RES_NAME[self.showType])
		spr:size(cc.size(69, 69))
		txtLevel = label.create(self.num or 0, {fontSize = 45, color = ui.COLORS.NORMAL.WHITE})
			:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
	end

	local panel = ccui.Layout:create()
		:size(spr:size())
		:alignCenter(self:size())
		:scale(1)
		:addTo(self, 9999, "_redHint_")
		:xy(self:size().width, self:size().height)

	spr:addTo(panel, 1, "spr")
	if txtLevel then
		txtLevel:addTo(panel, 1, "txt")
	end
	return panel
end

function redHint:bindIdlers(k, v, tag, specialTag)
	if k == "unlockKey" then
		k = k..v
		v = dataEasy.getListenUnlock(v)
		if not self.unlockKeys[specialTag] then self.unlockKeys[specialTag] = {} end
		self.unlockKeys[specialTag][k] = true
	elseif k == "selectDbId" then
		self:bindAllCardsByDbid(v, function( ... )
			if self.datas then
				self.datas:modify(function(datas)
					return true, datas
				end)
			end
		end)
	end

	-- specialTag / node.string / key
	tag = string.format("%s/%s/%s", tag or "", self.selfID, tostring(k))
	helper.callOrWhen(v, function(val)
		if self.datas then
			self.datas:modify(function(datas)
				local changed = datas[k] ~= val
				changed = changed or (lua_type(val) == "table")
				datas[k] = val
				return changed, datas
			end)
		end
	end, self, tag)
end

function redHint:initExtend()
	local panel = self:getChildByName(childName)
	if not panel then
		panel = self:createPanel()
		panel:hide()
	end

	-- destroy old idler
	if self.datas then
		self.datas:destroy()
	end

	self.selfID = tostring(self)
	self.datas = idlereasy.new({})

	if self.showType == "num" then
		helper.callOrWhen(self.num, function(num)
			self:setNum(num)
		end, self, string.format("%s/num", self.selfID))
	end

	helper.callOrWhen(self.state, function(state)
		self.datas:modify(function(datas)
			local changed = datas.state ~= state
			datas.state = state
			return changed, datas
		end)
	end, self, string.format("%s/state", self.selfID))

	self.unlockKeys = {}
	local t = helper.props(self.parent_, self, self.listenData) or {}
	for k, v in pairs(t) do
		self:bindIdlers(k, v)
	end

	if type(self.specialTag) ~= "table" then
		self.specialTag = {self.specialTag}
	end

	for _, specialTag in pairs(self.specialTag) do
		local t = redHintHelperTags[specialTag] or {}
		for k, v in pairs(t) do
			self:bindIdlers(k, redHintHelperTags[k] or v, nil, specialTag)
		end
	end

	-- if not possible forever, ignore idlereasy.when(self.datas) for card red_hint
	-- TODO: may be some view need listening when battle_cards changed
	if redHintHelper[self.specialTag] and redHintHelper.mustInBattleCards[self.specialTag] then
		local dbid = redHintHelper.getCardDBID(self.datas:read())
		if not redHintHelper.isCardInBattleCards(dbid) then
			return panel:hide()
		end
	end

	local count = 0
	idlereasy.when(self.datas, function(_, datas)
		count = count + 1
		performWithDelay(self, function()
			if count <= 0 then return end
			count = 0
			local func = self.func or function(datas)
				local b = false
				if not next(self.specialTag) then
					b = always_true()
				else
					for _, specialTag in pairs(self.specialTag) do
						local f = redHintHelper[specialTag] or always_true
						local d = f(datas)
						local keys = self.unlockKeys[specialTag] or {}
						for key, _ in pairs(keys) do
							d = d and datas[key]
						end
						b = b or d
					end
				end

				return b
			end

			local boolOrNum = func(datas)

			if self.showType == "num" then
				self:setNum(boolOrNum)
				panel:visible(datas.state and boolOrNum > 0)
			else
				panel:visible(datas.state and boolOrNum)
			end
		end, 0)
	end)

	if self.onNode then
		self.onNode(panel)
	end
	return self
end

return redHint