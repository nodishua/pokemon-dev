-- @date:   2019-1-15
-- @desc:   图鉴图片界面
-- @modify: 2019-7-27 18:15:04

local attrColor ={
	normal = "#C0xFFC6B6AC#",
	fire = "#C0xFFF76A6B#",
	water = "#C0xFF8DB9FC#",
	grass = "#C0xFF87DC87#",
	electricity = "#C0xFFE5CC3B#",
	ice = "#C0xFF6BDBEC#",
	combat = "#C0xFFF98562#",
	poison = "#C0xFFAE7EDE#",
	ground = "#C0xFFB8B7B1#",
	fly = "#C0xFF85CEFC#",
	super = "#C0xFFE76FD7#",
	worm = "#C0xFFC4D138#",
	rock = "#C0xFFBE9E6A#",
	ghost = "#C0xFF788797#",
	dragon = "#C0xFFABA2FF#",
	evil = "#C0xFFAF8B85#",
	steel = "#C0xFFA5B8BE#",
	fairy = "#C0xFFF96494#",
}

local function onInitItem(list, node, k, v)
	node:get("progressBar"):removeChildByName("changtiao")
	node:get("topView"):visible(false)
	local targetType = v.cfg.targetType
	local natureStr = ""
	local color = ""
	if targetType == 2 then
		natureStr = gLanguageCsv[game.NATURE_TABLE[v.cfg.targetArg2]] .. gLanguageCsv.xi
		color = ui.ATTRCOLOR[game.NATURE_TABLE[v.cfg.targetArg2]]
	end

	node:removeChildByName("richText1")
	rich.createByStr(string.format(gLanguageCsv.handbookBreakTitle, "#C0xFF5B545B#", v.cfg.targetArg, color, natureStr, "#C0xFF5B545B#"), 50)
		:anchorPoint(0, 0.5)
		:xy(57, 180)
		:name("richText1")
		:addTo(node, 3)

	local hasNum = list.hasNum:read()
	if targetType == 2 then
		hasNum = 0
		for cardId,_ in pairs(list.cards:read()) do
			local cardInfo = csv.cards[cardId]
			local unitInfo = csv.unit[cardInfo.unitID]
			if (v.cfg.targetArg2 == unitInfo.natureType) or
				(unitInfo.natureType2 and v.cfg.targetArg2 == unitInfo.natureType2) then
				hasNum = hasNum + 1
			end
		end
	end
	local numStr = string.format("%d/%d", hasNum, v.cfg.targetArg)
	node:get("textNum"):text(numStr)

	local percent = hasNum / v.cfg.targetArg * 100
	percent = math.min(percent, 100)
	percent = math.max(percent, 0)
	node:get("progressBar"):setPercent(percent)
	node:removeChildByName("richText2")
	rich.createByStr(v.cfg.desc, 40)
		:anchorPoint(0, 0.5)
		:xy(57, 100)
		:name("richText2")
		:addTo(node, 3)
	local canBreakd = (hasNum >= v.cfg.targetArg)
	local btn = node:get("btnBreak")
	local imgFlag = node:get("imgFlag")
	cache.setShader(btn, false, "normal")
	cache.setShader(btn:get("textNote"), false, "normal")
	if v.state == 0 then -- 已领取
		imgFlag:visible(true)
		btn:visible(false)
	elseif v.state == 1 then -- 可领取
		imgFlag:visible(false)
		btn:visible(true)
		text.addEffect(btn:get("textNote"), {glow={color=ui.COLORS.GLOW.WHITE}})
		widget.addAnimationByKey(node:get("progressBar"), "shengjichangtiao/changtiao.skel", 'changtiao', "effect_loop", 99)
			:anchorPoint(cc.p(0.5,0.5))
			:xy(node:get("imgProBar"):width()/2, node:get("imgProBar"):height()/2)
	else
		imgFlag:visible(false)
		btn:visible(true)
		cache.setShader(btn, false, "hsl_gray")
		cache.setShader(btn:get("textNote"), false, "hsl_gray")
		text.deleteEffect(btn:get("textNote"), {"glow"})
	end
end

local HandbookBreakView = class("HandbookBreakView", Dialog)

HandbookBreakView.RESOURCE_FILENAME = "handbook_break.json"
HandbookBreakView.RESOURCE_BINDING = {
	["panel.title.btnClose"] = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["panel.listview"] = {
		varname = "breakList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("breakDatas"),
				item = bindHelper.self("item"),
				hasNum = bindHelper.self("hasNum"),
				cards = bindHelper.self("cards"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					onInitItem(list, node, k, v)
					bind.touch(list, node:get("btnBreak"), {methods = {ended = functools.partial(list.clickItem, k, v, node)}})
				end,
				asyncPreload = 4,
			},
			handlers = {
				clickItem = bindHelper.self("onBreak"),
			},
		},
	},
	["btnItem"] = "btnItem",
	["panel.tabPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("btnsData"),
				item = bindHelper.self("btnItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local textNode = node:get("textNote")
					node:get("btnClick"):visible(v.state)
					node:get("btnNormal"):visible(not v.state)
					node:get("frameBG"):visible(v.state and v.attrNatureType > 0)
					textNode:text(v.text)
					adapt.setTextScaleWithWidth(textNode, nil, 150)
					if v.state then
						text.addEffect(textNode, {color = ui.COLORS.NORMAL.WHITE})
					else
						text.addEffect(textNode, {color = ui.COLORS.NORMAL.DEFAULT})
					end
					if v.attrNatureType > 0 then
						node:get("imgIcon"):texture(ui.SKILL_ICON[v.attrNatureType])
					else
						node:get("imgIcon"):texture("city/main/icon_tj@.png")
						node:get("imgIcon"):scale(1)
					end
					bind.touch(list, node:get("btnNormal"), {methods = {ended = functools.partial(list.clickItem, k, v)}})

					local showProps = {
						class = "red_hint",
						props = {
							state = v.red_hint,
						}
					}
					bind.extend(list, node, showProps)
				end,
			},
			handlers = {
				clickItem = bindHelper.self("onChangeView"),
			},
		},
	},
}

function HandbookBreakView:onCreate()
	self:initModel()
	self.curSelBtn = 1
	local btnsData = {				-- 左侧标签页数据
		{
			text = gLanguageCsv.overView,
			state = true,
			attrNatureType = 0,
			red_hint = false,
		},
		{
			text = gLanguageCsv.normal,
			state = false,
			attrNatureType = 1,
			red_hint = false,
		},
		{
			text = gLanguageCsv.fire,
			state = false,
			attrNatureType = 2,
			red_hint = false,
		},
		{
			text = gLanguageCsv.water,
			state = false,
			attrNatureType = 3,
			red_hint = false,
		},
		{
			text = gLanguageCsv.grass,
			state = false,
			attrNatureType = 4,
			red_hint = false,
		},
		{
			text = gLanguageCsv.electricity,
			state = false,
			attrNatureType = 5,
			red_hint = false,
		},
		{
			text = gLanguageCsv.ice,
			state = false,
			attrNatureType = 6,
			red_hint = false,
		},
		{
			text = gLanguageCsv.combat,
			state = false,
			attrNatureType = 7,
			red_hint = false,
		},
		{
			text = gLanguageCsv.poison,
			state = false,
			attrNatureType = 8,
			red_hint = false,
		},
		{
			text = gLanguageCsv.ground,
			state = false,
			attrNatureType = 9,
			red_hint = false,
		},
		{
			text = gLanguageCsv.fly,
			state = false,
			attrNatureType = 10,
			red_hint = false,
		},
		{
			text = gLanguageCsv.super,
			state = false,
			attrNatureType = 11,
			red_hint = false,
		},
		{
			text = gLanguageCsv.worm,
			state = false,
			attrNatureType = 12,
			red_hint = false,
		},
		{
			text = gLanguageCsv.rock,
			state = false,
			attrNatureType = 13,
			red_hint = false,
		},
		{
			text = gLanguageCsv.ghost,
			state = false,
			attrNatureType = 14,
			red_hint = false,
		},
		{
			text = gLanguageCsv.dragon,
			state = false,
			attrNatureType = 15,
			red_hint = false,
		},
		{
			text = gLanguageCsv.evil,
			state = false,
			attrNatureType = 16,
			red_hint = false,
		},
		{
			text = gLanguageCsv.steel,
			state = false,
			attrNatureType = 17,
			red_hint = false,
		},
		{
			text = gLanguageCsv.fairy,
			state = false,
			attrNatureType = 18,
			red_hint = false,
		},
	}
	self.btnsData = idlers.newWithMap(btnsData)
	self.hasNum = idler.new(itertools.size(self.cards:read()))
	self.breakDatas = idlers.newWithMap({})
	self:refreshIdlersMap()
	self:refreshTabRedHint()

	Dialog.onCreate(self)
end

function HandbookBreakView:initModel()
	self.cards = gGameModel.role:getIdler("pokedex")--卡牌
	self.pokedexAdvance = gGameModel.role:getIdler("pokedex_advance")
end

function HandbookBreakView:refreshIdlersMap()
	local breakDatas = {}
	local curAttrNatureType = self.btnsData:atproxy(self.curSelBtn).attrNatureType
	local stateTab = self.pokedexAdvance:read()
	for k,v in orderCsvPairs(csv.pokedex_advance) do
		local targetArg2 = v.targetArg2 or 0
		if matchLanguage(v.languages) and curAttrNatureType == targetArg2 then
			local data = {}
			data.cfg = v
			data.state = stateTab[k] or 0.5 -- 方便排序
			data.csvId = k
			table.insert(breakDatas, data)

		end
	end

	table.sort(breakDatas, function(a, b)
		if a.state ~= b.state then
			return a.state > b.state
		end

		return a.csvId < b.csvId
	end)
	dataEasy.tryCallFunc(self.breakList, "updatePreloadCenterIndex")
	self.breakDatas:update(breakDatas)
	self.breakList:jumpToTop()
end

-- @desc tab页红点刷新
function HandbookBreakView:refreshTabRedHint()
	local stateTab = self.pokedexAdvance:read()
	for k,v in self.btnsData:pairs() do
		self.btnsData:atproxy(k).red_hint = false
		local curAttrNatureType = self.btnsData:atproxy(k).attrNatureType
		for g,h in orderCsvPairs(csv.pokedex_advance) do
			local targetArg2 = h.targetArg2 or 0
			local state = stateTab[g] or 0.5
			if matchLanguage(h.languages) and curAttrNatureType == targetArg2 and state == 1 then
				self.btnsData:atproxy(k).red_hint = true
				break
			end
		end
	end
end

function HandbookBreakView:onBreak(list, k, v, item)
	if v.state ~= 1 then
		return
	end
	gGameApp:requestServer("/game/role/pokedex_advance", function(tb)
		item:get("topView"):visible(true)
		local effect = widget.addAnimationByKey(item:get("progressBar"), "shengjichangtiao/changtiao.skel", 'changtiao', "effect_loop", 99)
		effect:play("effect")
		performWithDelay(self, function()
			self:refreshIdlersMap()
			self:refreshTabRedHint(self.btnsData:atproxy(self.curSelBtn).attrNatureType)
			gGameUI:showTip(gLanguageCsv.breakSuccess)
		end, 25/30)
	end, v.csvId)
end

function HandbookBreakView:onChangeView(node, idx, val)
	self.btnsData:atproxy(self.curSelBtn).state = false
	self.btnsData:atproxy(idx).state = true
	self.curSelBtn = idx
	self:refreshIdlersMap()
end

return HandbookBreakView