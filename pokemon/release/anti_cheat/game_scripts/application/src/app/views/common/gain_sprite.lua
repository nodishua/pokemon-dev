-- @date: 2019-01-03
-- @desc: 通用恭喜获得展示英雄界面

local ViewBase = cc.load("mvc").ViewBase
local GainSpriteView = class("GainSpriteView", ViewBase)
GainSpriteView.RESOURCE_FILENAME = "common_gain_sprite.json"
GainSpriteView.RESOURCE_BINDING = {
	["btnJump"] = {
		varname = "btnJump",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onJump")},
		},
	},
	["left"] = {
		varname = "leftPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowPanel")
		},
	},
	["down"] = {
		varname = "downPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowPanel")
		},
	},
	["left.nature"] = "nature",
	["left.skillContent"] = "skillContent",
	["left.skillName"] = "skillName",
	["left.icon"] = "icon",
	["left.skillAttr"] = "skillAttr",
	["down.rarity"] = "rarity",
	["cardImg"] = {
		varname = "cardImg",
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowPanel")
		},
	},
	["down.attr1"] = "attr1",
	["down.attr2"] = "attr2",
	["down.name"] = "txtName",
	["attrInfo"] = {
		varname = "attrInfo",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("isShowPanel")
			},
			{
				event = "extend",
				class = "draw_attr",
				props = {
					nvalue = bindHelper.self("nvalue"),
					type = "big",
					offsetPos = {
						{x = -100, y = -100},
						{x = 10, y = -160},
						{x = 10, y = -260},
						{x = -100, y = -320},
						{x = matchLanguage({"kr", "en"}) and -265 or -210, y = -260},
						{x = matchLanguage({"kr", "en"}) and -265 or -210, y = -160},
					},
					offset = {x = 230, y = 250},
					lock = false,
					onNode = function (panel)
						panel:xy(240, 170)
					end
				}
			},
		},
	},
	["effect"] = {
		varname = "effect",
		binds =	{
			event = "click",
			method = bindHelper.self("onClose"),
		},
	},
	["down.bottomPanel"] = "bottomPanel",
	["down.bottomPanel.cardName"] = "cardName",
	["down.bottomPanel.cardNote"] = "cardNote",
	["down.bottomPanel.pos"] = "pos",
	["left.new"] = "new",
	["titlePanel"] = "titlePanel",
}

function GainSpriteView:onCreate(data, hadSprite, showBtn, cb)
	local panel = ccui.Layout:create()
		:addTo(self:getResourceNode(), 100, "mask")
		:setAnchorPoint(cc.p(0.5, 0.5))
		:size(cc.size(display.maxWidth, display.height))
		:alignCenter(self:getResourceNode():size())
		:setTouchEnabled(true)
		:show()
	self.panel = panel
	audio.playEffectWithWeekBGM("card_gain.mp3")
	self.isShowPanel = idler.new(false)
	local bgEffect = widget.addAnimation(self.effect, "effect/huodexinjinglingbg.skel", "effect", 1)
		:alignCenter(self.effect:size())
		:scale(2)

	performWithDelay(self.effect, function()
		bgEffect:play("effect_loop")
		self.leftPanel:scaleX(0)
		self.downPanel:scaleX(0)
		self.attrInfo:scale(0)
		self.isShowPanel:set(true)
		transition.executeSequence(self.leftPanel)
			:scaleXTo(0.5, 1.1)
			:scaleXTo(0.1, 1)
			:done()
		transition.executeSequence(self.downPanel)
			:scaleXTo(0.5, 1.1)
			:scaleXTo(0.1, 1)
			:done()
		transition.executeSequence(self.attrInfo)
			:scaleTo(0.5, 1.1)
			:scaleTo(0.1, 1)
			:done()

		local pnode = self:getResourceNode()
		local spine1 = widget.addAnimation(pnode, "effect/huodexinjingling.skel", "effect", 103)
		spine1:align(cc.p(0.5,1.0), self.titlePanel:xy())
			:scale(1.2)
		spine1:addPlay("effect_loop")

		local size = self.cardImg:size()
		widget.addAnimation(self.cardImg, "effect/jinglingchuxian.skel", "effect", 6)
			:xy(size.width / 2, size.height * 0.05)

	end, 20 / 30)
	hadSprite = hadSprite or {}
	if cb then
		self.cb = cb
	end
	local card = gGameModel.cards:find(data.dbid or data.db_id)
	local cardData = card:read("card_id", "character", "nvalue", "name", "advance")
	self.nature:text(csv.character[cardData.character].name)
	local cardCfg = csv.cards[cardData.card_id]
	local unitCfg = csv.unit[cardCfg.unitID]
	local skillList = unitCfg.skillList
	local skillCfg =  csv.skill[skillList[itertools.size(skillList)]]
	-- self.skillContent:text(skillCfg.simDesc)
	self.skillContent:hide()
	local list = beauty.textScroll({
		size = self.skillContent:size(),
		strs = skillCfg.simDesc,
	})
	list:xy(self.skillContent:box())
		:z(self.skillContent:z())
		:addTo(self.skillContent:parent())

	self.skillName:text(skillCfg.skillName)
	self.icon:texture(ui.SKILL_ICON[skillCfg.skillNatureType])
	self.skillAttr:texture(ui.SKILL_TEXT_ICON[skillCfg.skillNatureType])
	self.rarity:texture(ui.RARITY_ICON[unitCfg.rarity])
	local size = self.cardImg:size()
	local cardSprite = widget.addAnimation(self.cardImg, unitCfg.unitRes, "standby_loop", 5)
		:xy(size.width / 2, size.height * 0.05)
		:scale(unitCfg.scaleU * 3)
	cardSprite:setSkin(unitCfg.skin)
	widget.addAnimationByKey(self.cardImg, "effect/jinhuajiemian.skel", "top" ,"effect_down2_loop", 4)
		:xy(size.width / 2, -50)
		:scale(1.2)
	widget.addAnimationByKey(self.cardImg, "effect/jinhuajiemian.skel", "down" ,"effect_up_loop", 6)
		:xy(size.width / 2, -50)
		:scale(1.2)

	uiEasy.setIconName("card", cardData.card_id, {node = self.txtName, name = cardData.name, advance = cardData.advance, space = true})
	self.attr2:visible(unitCfg.natureType2 ~= nil)
	if unitCfg.natureType2 then
		self.attr2:texture(ui.ATTR_ICON[unitCfg.natureType2])
	end
	self.attr1:texture(ui.ATTR_ICON[unitCfg.natureType])
	self.nvalue = cardData.nvalue
	data.new = data.new or data.first
	if data.new and not hadSprite[cardData.card_id] then
		hadSprite[cardData.card_id] = true
		self.cardName:text(csv.cards[cardData.card_id].name)
		adapt.oneLineCenterPos(cc.p(self.pos:xy()), {self.cardName, self.cardNote}, cc.p(10, 0))
	else
		self.bottomPanel:hide()
		self.new:hide()
	end
	adapt.oneLinePos(self.txtName, self.rarity, cc.p(8,0), "right")
	adapt.oneLinePos(self.txtName, {self.attr1, self.attr2}, cc.p(8,0))
	performWithDelay(self, function ()
		self.panel:hide()
	end, 1)
	self.btnJump:visible(false)
	performWithDelay(self, function ()
		local isJumpSpriteView = userDefault.getForeverLocalKey("isJumpSpriteView", false)
		local val = showBtn
		if showBtn == nil then
			val = not isJumpSpriteView
		end
		self.btnJump:visible(val)
	end, 0.9)

	if matchLanguage(cardCfg.languages) == false then
		errorInWindows("配置可获取到整卡 %s, 但 csv.cards (%s) 未开放", cardData.card_id, LOCAL_LANGUAGE)
	end
end

function GainSpriteView:onJump()
	userDefault.setForeverLocalKey("isJumpSpriteView", true)
	self:onClose()
end

function GainSpriteView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return GainSpriteView
