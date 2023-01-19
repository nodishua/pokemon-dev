-- @Date:   2020-08-3
-- @Desc: 徽章天赋觉醒界面
local ViewBase = cc.load("mvc").ViewBase
local gymBadgeTalentAwakeView = class("gymBadgeTalentAwakeView", ViewBase)

local effectTable = {
	[4] = {effectName  = "huo_effect", loopName = "huo_loop", xy = cc.p(310, 580), scale = 2, pointX = 0.6, pointY = 0.5},
	[5] = {effectName  = "long_effect", loopName = "long_loop", xy = cc.p(511, 490), scale = 2, pointX = 0.4, pointY = 0.7},
	[2] = {effectName  = "shui_effect", loopName = "shui_loop",  xy = cc.p(140, 450), scale = 2, pointX = 0.6, pointY = 0.6},
	[1] = {effectName  = "yan_effect", loopName = "yan_loop",  xy = cc.p(286, 350), scale = 2, pointX = 0.4, pointY = 0.6},
	[3] = {effectName  = "cao_effect", loopName = "cao_loop",  xy = cc.p(266, 735), scale = 2, pointX = 0.5, pointY = 0.3},
	[6] = {effectName  = "e_effect", loopName = "e_loop",  xy = cc.p(381, 500), scale = 2, pointX = 0.4, pointY = 0.5},
	[8] = {effectName  = "yao_effect", loopName = "yao_loop",  xy = cc.p(131, 620), scale = 2, pointX = 0.6, pointY = 0.4},
	[7] = {effectName  = "du_effect", loopName = "du_loop",  xy = cc.p(441, 700), scale = 2, pointX = 0, pointY = 0},
}

local attrDatas = {
	{name = gLanguageCsv.attrHp},
	{name = gLanguageCsv.attrDamage},
	{name = gLanguageCsv.attrSpecialDamage},
	{name = gLanguageCsv.attrDefence},
	{name = gLanguageCsv.attrSpecialDefence},
	{name = gLanguageCsv.attrSpeed},
}

gymBadgeTalentAwakeView.RESOURCE_FILENAME = "gym_badge_awake.json"
gymBadgeTalentAwakeView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["leftPanel"] = "leftPanel",
	["leftPanel.item"] = "leftItem",
	["leftPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("natureData"),
				item = bindHelper.self("leftItem"),
				onItem = function(list, node, k, v)
					node:get("icon"):texture(ui.ATTR_ICON[v])
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end,
			},
		},
	},
	["rightPanel"] = "rightPanel",
	["rightPanel.topPanel"] = "topPanel",
	["rightPanel.costPanel"] = "costPanel",
	["rightPanel.costPanel.item"] = "costItem",
	["rightPanel.btnPanel"] = "btnPanel",
	["rightPanel.costPanel.list"] = {
		varname = "costList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("costData"),
				item = bindHelper.self("costItem"),
				onItem = function(list, node, k, v)
					local showAddBtn = false
					if v.targetNum then
						showAddBtn = (v.num < (v.targetNum or 0))
					end
					node:get("btnAdd"):visible(showAddBtn)
					node:get("imgMask"):visible(showAddBtn)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
								targetNum = v.targetNum,
							},
							onNode = function(node)
								bind.click(list, node, {method = functools.partial(list.itemClick, node, k, v)})
							end,
						}
					})
				end,
				asyncPreload = 2,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["rightPanel.btnPanel.btn"] = {
		varname = "awakeBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAwakeBtn")}
		},
	},
}

function gymBadgeTalentAwakeView:onCreate(badgeNumb)
	self.badgeNumb = badgeNumb
	self:initModel()
	self.natureData = idlers.new()
	local csvBadge = csv.gym_badge.badge
	local costNum = csvBadge[badgeNumb].awakeCostSeqID
	self.natureData:update(csvBadge[badgeNumb].nature)
	self.leftPanel:get("name"):text(csvBadge[badgeNumb].name)
	self.costData = idlers.new()
	widget.addAnimationByKey(self.leftPanel, "daoguanhuizhang/dghz.skel", "spine"..badgeNumb, effectTable[badgeNumb].loopName, 100)
		:xy(cc.p(310, 480))
		:scale(1.3)

	local csvAwakeCost = csv.gym_badge.awake_cost
	idlereasy.any({self.items, self.badges}, function(_, items, badges)
		local badgesData = badges and badges[badgeNumb] or {}
		local talents = badgesData.talents or {}
		local guards = badgesData.guards or {}
		local awake = badgesData.awake or 0
		local item = csvAwakeCost[awake]["cost"..costNum]
		local costData = {}
		local awakeTalentAttrs = csvBadge[badgeNumb].awakeTalentAttrs
		--天赋的加成数
		local presentTalentNum = ""
		local nextTalentNum = ""
		if awake == 0 then
			presentTalentNum = 0
			nextTalentNum = awakeTalentAttrs[awake + 1]
			self.leftPanel:get("nameLv"):hide()
		else
			presentTalentNum = awakeTalentAttrs[awake]
			nextTalentNum = awakeTalentAttrs[awake+1] and awakeTalentAttrs[awake+1] or 0
			self.leftPanel:get("nameLv"):text("+"..awake)
			self.leftPanel:get("nameLv"):show()
		end
		--觉醒需要天赋需要达到的等级
		self.preTalentLevel = csvBadge[badgeNumb].preTalentLevel[awake+1] or 999
		--能否觉醒
		self.canAwake = 0
		for k, v in ipairs(dataEasy.getItemData(item)) do
			if v.key ~= "rmb" and v.key ~= "gold" then
				table.insert(costData, {key = v.key, num = items[v.key] or 0, targetNum = v.num})
			end
		end
		self.item = costData
		local itemNum = #costData
		self.costList:size(200 * itemNum, 200)
		self.costData:update(costData)
		self.costGold = item.gold
		self.btnPanel:get("text"):text(self.costGold)
		adapt.oneLineCenterPos(cc.p(163, 164), {self.btnPanel:get("text1"), self.btnPanel:get("text"), self.btnPanel:get("icon")}, cc.p(6, 0))
		local talentTab = csvBadge[badgeNumb].talentIDs
		for k, v in ipairs(talentTab) do
			if talents[v] and talents[v] >= self.preTalentLevel then
				self.canAwake = self.canAwake + 1
			end
		end
		if self.canAwake < 6 then
			self.btnPanel:get("txt"):show()
			self.btnPanel:get("txt"):text(string.format(gLanguageCsv.badgeNeedToUp, self.preTalentLevel))
			self.btnPanel:get("txt"):color(cc.c3b(248, 108, 70))
		else
			self.btnPanel:get("txt"):text(string.format(gLanguageCsv.badgeNeedToUp, self.preTalentLevel))
			self.btnPanel:get("txt"):color(ui.COLORS.NORMAL.GREEN)
		end
		self.costPanel:visible(#costData > 0)
		--当前效果
		local t = {}
		--天赋的加成数
		local str = string.format(gLanguageCsv.badgeAllTalentUp, presentTalentNum)
		table.insert(t, {str = str})
		local curEffStrs = self:getStrsByAwark(t, csvBadge, badgeNumb, awake)
		beauty.textScroll({
			list = self.topPanel:get("list1"),
			effect = {color=ui.COLORS.NORMAL.DEFAULT},
			strs = curEffStrs,
			isRich = true,
			margin = 20,
			align = "left",
		})

		if awake >= csvBadge[badgeNumb].awakeMaxLevel then
			self.costPanel:hide()
			self.btnPanel:hide()
			self.rightPanel:get("maxBg"):show()
			self.topPanel:get("title1"):hide()
			self.topPanel:get("list2"):hide()
		else
			--下一阶效果
			local t = {}
			local nextTalentNum = awakeTalentAttrs[awake + 1] or 0
			local str = string.format(gLanguageCsv.badgeAllTalentUp, nextTalentNum)
			table.insert(t, {str = str})
			local nextEffStrs = self:getStrsByAwark(t, csvBadge, badgeNumb, awake+1)
			self.nextEffStrs = nextEffStrs
			beauty.textScroll({
				list = self.topPanel:get("list2"),
				effect = {color=ui.COLORS.NORMAL.DEFAULT},
				strs = nextEffStrs,
				isRich = true,
				margin = 20,
				align = "left",
			})
		end
		adapt.oneLineCenterPos(cc.p(310, 100), {self.leftPanel:get("name"), self.leftPanel:get("nameLv")}, cc.p(6, 0))
		self.awake = awake
	end)
	Dialog.onCreate(self)
end

function gymBadgeTalentAwakeView:getStrsByAwark(t, csvBadge, badgeNumb, awake)
	for i= 1, math.huge do
		local attrType = csvBadge[badgeNumb]["attrType"..i]
		if not attrType then
			break
		end
		local arrtNum = csvBadge[badgeNumb]["attrNum"..i][awake]

		local presentCardNum = dataEasy.getAttrValueString(attrType, arrtNum or 0)
		local attrText = getLanguageAttr(attrType)
		local str = string.format(gLanguageCsv.badgeAllCardsUp, attrText, presentCardNum)
		table.insert(t, {str = str})

	end
	return t
end

function gymBadgeTalentAwakeView:initModel()
	self.badges = gGameModel.role:getIdler("badges")
	self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
end

function gymBadgeTalentAwakeView:onAwakeBtn()
	if self.canAwake < 6 then
		gGameUI:showTip(string.format(gLanguageCsv.needAllBadgeLight, self.preTalentLevel))
		return
	end
	if self.costGold and self.gold:read() < self.costGold then
		gGameUI:showTip(gLanguageCsv.awakeGoldNotEnough)
		return
	end
	for _, v in ipairs(self.item) do
		if v.targetNum > v.num then
			gGameUI:showTip(gLanguageCsv.awakeItemsNotEnough)
			return
		end
	end
	local awake = self.awake
	local nextEffStrs = self.nextEffStrs
	gGameApp:requestServer("/game/badge/awake", function()
		local spine = self.leftPanel:get("effect")
		if spine then
			spine:play("fangguang2")
		else
			spine = widget.addAnimationByKey(self.leftPanel, "koudai_gonghuixunlian/gonghuixunlian.skel", "effect", "fangguang2", 10000)
			spine:xy(310,400)
		end
		-- gGameUI:showTip(gLanguageCsv.awakeSucceed)
		gGameUI:stackUI("city.develop.gym_badge.awake_success", nil, {blackLayer = true, clickClose = true}, {awake = awake, nextEffStrs = nextEffStrs, badgeNumb = self.badgeNumb})
	end , self.badgeNumb)
end

function gymBadgeTalentAwakeView:onItemClick(list, panel, k, v)
	gGameUI:stackUI("common.gain_way", nil, nil, v.key, nil, v.targetNum)
end

return gymBadgeTalentAwakeView