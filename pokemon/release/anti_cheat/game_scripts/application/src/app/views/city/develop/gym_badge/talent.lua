-- @Date:   2020-08-3
-- @Desc: 徽章天赋界面
local ViewBase = cc.load("mvc").ViewBase
local gymBadgeTalentView = class("gymBadgeTalentView", ViewBase)

--控制连线
local LINETABLE = {
	{1, 2, 3, 4, 5, 6, 7, 8},
	{8},
	{7, 8},
	{5, 6, 7, 8},
	{4, 5, 6, 7, 8},
	{3, 4, 5, 6, 7, 8},
}

local effectTable = {
	[4]	= {effectName  = "huo_effect", loopName = "huo_loop", xy = cc.p(799, 535), scale = 2, pointX = 0.6, pointY = 0.5},
	[5]	= {effectName  = "long_effect", loopName = "long_loop", xy = cc.p(1000, 435), scale = 2, pointX = 0.4, pointY = 0.7},
	[2]	= {effectName  = "shui_effect", loopName = "shui_loop",  xy = cc.p(650, 420), scale = 2, pointX = 0.6, pointY = 0.6},
	[1]	= {effectName  = "yan_effect", loopName = "yan_loop",  xy = cc.p(775, 300), scale = 2, pointX = 0.4, pointY = 0.6},
	[3]	= {effectName  = "cao_effect", loopName = "cao_loop",  xy = cc.p(755, 680), scale = 2, pointX = 0.5, pointY = 0.3},
	[6]	= {effectName  = "e_effect", loopName = "e_loop",  xy = cc.p(870, 450), scale = 2, pointX = 0.4, pointY = 0.5},
	[8]	= {effectName  = "yao_effect", loopName = "yao_loop",  xy = cc.p(620, 600), scale = 2, pointX = 0.6, pointY = 0.4},
	[7]	= {effectName  = "du_effect", loopName = "du_loop",  xy = cc.p(930, 680), scale = 2, pointX = 0, pointY = 0},
}

local BALLPOSITION = {
	{x = 110, y = 60, scale = 2, scaleBattom = 1.5},
	{x = 88, y = 48, scale = 1.6, scaleBattom = 1.2},
	{x = 75, y = 43, scale = 1.2, scaleBattom = 1},
	{x = 75, y = 43, scale = 1.2, scaleBattom = 1},
	{x = 88, y = 48, scale = 1.6, scaleBattom = 1.2},
	{x = 109, y = 60, scale = 2, scaleBattom = 1.5},
}

gymBadgeTalentView.RESOURCE_FILENAME = "gym_badge_talent.json"
gymBadgeTalentView.RESOURCE_BINDING = {
	["leftPanel"] = "leftPanel",
	["leftPanel.top"] = "leftTop",
	["leftPanel.top.badge"] = "badgeIcon",
	["leftPanel.top.name"] = "badgeName",
	["leftPanel.top.item"] = "natureItem",
	["leftPanel.top.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("natureData"),
				item = bindHelper.self("natureItem"),
				onItem = function(list, node, k, v)
					node:get("icon"):texture(ui.ATTR_ICON[v])
				end,
			},
			handlers = {
			},
		},
	},
	["leftPanel.top.talentBottom1"] = "talentBottom1",
	["leftPanel.top.talentBottom2"] = "talentBottom2",
	["leftPanel.top.talentBottom3"] = "talentBottom3",
	["leftPanel.top.talentBottom4"] = "talentBottom4",
	["leftPanel.top.talentBottom5"] = "talentBottom5",
	["leftPanel.top.talentBottom6"] = "talentBottom6",
	["leftPanel.top.nameBg1"] = "nameBg1",
	["leftPanel.top.nameBg2"] = "nameBg2",
	["leftPanel.top.nameBg3"] = "nameBg3",
	["leftPanel.top.nameBg4"] = "nameBg4",
	["leftPanel.top.nameBg5"] = "nameBg5",
	["leftPanel.top.nameBg6"] = "nameBg6",
	["leftPanel.top.left"] = {
		varname = "leftBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onLeftBtn")}
		},
	},
	["leftPanel.top.right"] = {
		varname = "rightBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRightBtn")}
		},
	},
	["leftPanel.top.awakeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAwake")}
		},
	},
	["leftPanel.middle"] = "leftMiddle",
	["leftPanel.middle.item"] = "leftItem",
	["leftPanel.middle.list"] = {
		varname = "guardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("guardTeam"),
				item = bindHelper.self("leftItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon")
					if v.icon then
						childs.icon:texture(v.icon)
					else
						childs.icon:hide()
					end
				end,
				asyncPreload = 6,
			},
		},
	},
	["leftPanel.middle.btn"] = {
		varname = "setBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSet")}
		},
	},
	["leftPanel.bottomPanel"] = "leftBottom",
	["leftPanel.bottomPanel.item"] = "bottomItem",
	["leftPanel.bottomPanel.subList"] = "subList",
	["leftPanel.bottomPanel.list"] = {
		varname = "bottomList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("natureAddData"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("bottomItem"),
				columnSize = 2,
				onCell = function(list, node, k, v)
					node:get("txt1"):text(getLanguageAttr(v.id))
					node:get("num1"):text("+"..v.num)
					if v.icon then
						node:get("icon"):texture(v.icon)
						adapt.oneLinePos(node:get("icon"), node:get("txt1"), cc.p(15, 0), "left")
						adapt.oneLinePos(node:get("txt1"), node:get("num1"), cc.p(15, 0), "left")
					else
						node:get("icon"):hide()
						adapt.oneLinePos(node:get("txt1"), node:get("num1"), cc.p(5, 0), "left")
					end
				end,
			},
			handlers = {
			},
		},
	},
	["rightPanel"] = "rightPanel",
	["rightPanel.top"] = "rightTop",
	["rightPanel.top.item"] = "rightTalentItem",
	["rightPanel.top.list"] = {
		varname = "talentList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rightTalent"),
				item = bindHelper.self("rightTalentItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("txt1", "txt2", "txt3", "maxIcon", "icon")
					if v.name == "Lv." then
						childs.txt1:text(v.name..v.num)
						childs.txt2:text(v.name..v.num1)
					else
						childs.txt1:text(v.name.."+"..v.num)
						childs.txt2:text(v.name.."+"..v.num1)
					end
					if v.isMax then
						childs.maxIcon:show()
						childs.icon:hide()
						childs.txt2:hide()
					else
						childs.maxIcon:hide()
						childs.icon:show()
						childs.txt2:show()
					end
					adapt.oneLinePos(childs.txt1, {childs.icon, childs.txt2}, cc.p(50, 0), "left")
					adapt.oneLinePos(childs.txt1, childs.maxIcon, cc.p(50, 0), "left")
				end,
			},
			handlers = {
			},
		},
	},
	["rightPanel.bottom"] = "rightBottom",
	["rightPanel.bottom.btnPanel"] = "btnPanel",
	["rightPanel.bottom.btnPanel.btn.title"] = "title",
	["rightPanel.bottom.btnPanel.fastUpgradePanel.checkBox"] = "checkBox",
	["rightPanel.bottom.btnPanel.fastUpgradePanel"] = {
		varname = "fastUpgradePanel",
		binds = {
			event = "click",
			method = bindHelper.self("onFastUpgradeClick")
		},
	},
	["rightPanel.bottom.costPanel"] = "costPanel",
	["rightPanel.bottom.costPanel.item"] = "costItem",
	["rightPanel.bottom.costPanel.list"] = {
		varname = "costList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("talentItem"),
				item = bindHelper.self("costItem"),
				onItem = function(list, node, k, v)
					local showAddBtn = false
					if v.targetNum then
						showAddBtn = (v.num < (v.targetNum or 0))
					end
					node:get("btnAdd"):visible(showAddBtn)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							grayState = showAddBtn and 1 or 0,
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
				onAfterBuild = function(list)
					list:setClippingEnabled(false)
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["rightPanel.bottom.btnPanel.btn"] = {
		varname = "lightBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSetLight")}
		},
	},
}

--传入徽章id
function gymBadgeTalentView:onCreate(params)
	self.badgeNumb = idler.new(params.badgeNumb)
	self.isView = params.isView
	self:initModel()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.badgeTalent, subTitle = "GYMBADGESPIRIT"})

	--点亮所需要的消耗品
	self.talentItem = idlers.new()
	--守护精灵
	self.guardTeam = idlers.new()
	--徽章属性
	self.natureData = idlers.new()
	--徽章属性加成
	self.natureAddData = idlers.new()
	--单个天赋属性加成
	self.rightTalent = idlers.new()
	self.nodeNum = idler.new(1)
	self.myNum = idler.new(1)
	self.canAwake = false
	self.isLightMax = false
	--判断是否是点亮过后的状态
	self.isLightIn = false
	--是否是选择快速升级
	self.checkBoxState = idler.new(false)
	self.checkBox:setSelectedState(self.checkBoxState:read())
	if not dataEasy.isUnlock(gUnlockCsv.badgeOneKey) then
		self.fastUpgradePanel:setVisible(false)
	else
		self.fastUpgradePanel:setVisible(true)
	end

	local function getItem(nodeNum, myNum, badgeNumb, talents, items)
		local csvBadge = csv.gym_badge.badge
		local csvTalent = csv.gym_badge.talent
		local csvTalentCost = csv.gym_badge.talent_cost
		local talentTab = csvBadge[badgeNumb].talentIDs
		local talentItem = {}
		local gold = 0
		local times = 1
		local flag = 2
		local talent =  {}
		local needGold ,needItem = 0, {}
		for i = 1, 6 do
			table.insert(talent, {talentTab[(nodeNum + i - 2) % 6 + 1], talents[talentTab[(nodeNum + i - 2) % 6 + 1]] or 0})
		end
		for tk, tv in pairs(talent) do
			local k, v = tv[1] , tv[2]
			local costSeqID = csvTalent[k].costSeqID
			local item = csvTalentCost[v]["cost"..costSeqID]
			if flag == 1 then
				break
			end
			for k, v in ipairs(dataEasy.getItemData(item)) do
				if flag == 2 then
					if v.key ~= "rmb" and v.key ~= "gold" then
						if (items[v.key] or 0) < v.num then
							flag = -1
						end
					else
						if v.num > self.gold:read() then
							flag = -1
						end
					end
				end
				if v.key ~= "rmb" and v.key ~= "gold" then
					local index = 0
					for key, val in ipairs(talentItem) do
						if v.key == val.key then
							if v.num + val.targetNum > (items[v.key] or 0) and flag ~= -1 or csv.gym_badge.badge[badgeNumb].talentMaxLevel <= tv[2] then
								flag = 1
								break
							end
							val.targetNum = v.num + val.targetNum
							times = times + 1
							break
						end
						index = index + 1
					end
					if index == #talentItem then
						table.insert(talentItem, {key = v.key, num = items[v.key] or 0, targetNum = v.num})
					end
				else
					if gold + v.num > self.gold:read() and flag ~= -1 or csv.gym_badge.badge[badgeNumb].talentMaxLevel <= tv[2]  then
						flag = 1
						break
					end
					gold = gold + v.num
				end
			end
			if flag == 2 then
				flag = 0
			end
			if flag ~= 1 then
				needGold = gold
				needItem = talentItem
			end
		end
		return needGold, needItem, times
	end
	local csvBadge = csv.gym_badge.badge
	local csvTalent = csv.gym_badge.talent
	local csvTalentCost = csv.gym_badge.talent_cost
	local csvGuard = csv.gym_badge.guard
	idlereasy.any({self.badges, self.badgeNumb}, function(_, badges, badgeNumb)
		local nodeNum = 1
		local badgesData = badges and badges[badgeNumb] or {}
		local talents = badgesData.talents or {}
		local guards = badgesData.guards or {}
		local awake = badgesData.awake or 0
		local awakeTalentNum = csvBadge[badgeNumb].preTalentLevel[awake + 1] or 999
		local talentTab = csvBadge[badgeNumb].talentIDs
		local guardTab = csvBadge[badgeNumb].guardIDs
		local talentLen = 0
		--是否可以觉醒
		self.isLightMax = false
		if talents[talentTab[6]] then
			--是否天赋点亮到最高
			if talents[talentTab[6]] >= csvBadge[badgeNumb].talentMaxLevel then
				self.isLightMax = true
			end
			if awakeTalentNum <= talents[talentTab[6]] and awake < csvBadge[badgeNumb].awakeMaxLevel then
				self.canAwake = true
				widget.addAnimationByKey(self.leftTop:get("bg"), "daoguanhuizhang/huizhang_tianfu.skel", "spine4", "diquan_loop", 0)
					:alignCenter(self.leftTop:get("bg"):size())
					:xy(500, 100)
					:scale(1)
			else
				self.leftTop:get("bg"):removeAllChildren()
				self.canAwake = false
				for k = 1, 8 do
					self.leftTop:get("line"..k):show()
				end
			end
		else
			self.leftTop:get("bg"):removeAllChildren()
		end
		self.rightTop:get("icon"):texture(csvBadge[badgeNumb].showIcon3)
		widget.addAnimation(self.rightTop:get("icon"), "effect/shipinfaguang.skel", "effect_loop", 20):scale(0.4)
	 		:xy(-50, 0)
		--觉醒等级加成
		local awakeTalentAttr = awake ~= 0 and dataEasy.parsePercentStr(dataEasy.getAttrValueString(csvBadge[badgeNumb].attrType1, csvBadge[badgeNumb].awakeTalentAttrs[awake])) or 0
		--守护加成
		local guardTalentAttr = self:guardAllTalent(badgeNumb, guards)
		--天賦球的亮暗情况
		local tmp = 1
		--天赋球最低的等级
		local talentMin = talents[talentTab[6]] or 0
		-- table的形式存储加成数据
		local numTab = {
			[1] = 0,
			[7] = 0,
			[8] = 0,
			[9] = 0,
			[10] = 0,
			[13] = 0,
		}
		for k, v in ipairs(talentTab) do
			if talents[v] then
				talentLen = talentLen + 1
				local attrType1 = csvTalent[v].attrType1
				local attrType2 = csvTalent[v].attrType2
				if attrType1 then
					local num = dataEasy.getAttrValueString(attrType1, csvTalent[v].attrNum1[talents[v]]*((100 + awakeTalentAttr)/100)*((100 + guardTalentAttr)/100), 0)
					numTab[attrType1] =numTab[attrType1] + num
				end
				if attrType2 then
					local num = dataEasy.getAttrValueString(attrType2, csvTalent[v].attrNum2[talents[v]]*((100 + awakeTalentAttr)/100)*((100 + guardTalentAttr)/100), 0)
					numTab[attrType2] =numTab[attrType2] + num
				end
				if talents[v] > talentMin or self.isLightMax then
					self["talentBottom"..k]:get("num"):text(talents[v])
					self["talentBottom"..k]:get("battomIcon"):show()
					self["talentBottom"..k]:get("icon"):show()
					tmp = tmp + 1
				end
			end
			self["nameBg"..k]:get("txt"):text(csvTalent[v].name)
		end
		if talentLen == 0 then
			nodeNum = 1
		elseif talentLen < 6 then
			nodeNum = talentLen + 1
		else
			local pre = talents[talentTab[1]]
			for k, v in ipairs(talentTab) do
				if talents[v] ~= pre then
					nodeNum = k
					break
				end
			end
		end
		--能升级的天赋球
		self.nodeNum:set(nodeNum)
		--自己所查看的天賦球
		self.myNum:set(nodeNum)
		--控制底部圆圈线条的进度
		self:setProgress(nodeNum, talents)

		self:createSpine(tmp, talents, talentTab)

		adapt.oneLineCenterPos(cc.p(110, 25), {self.talentBottom1:get("txt"), self.talentBottom1:get("num")}, cc.p(0, 0))
		adapt.oneLineCenterPos(cc.p(90, 20), {self.talentBottom2:get("txt"), self.talentBottom2:get("num")}, cc.p(0, 0))
		adapt.oneLineCenterPos(cc.p(75, 20), {self.talentBottom3:get("txt"), self.talentBottom3:get("num")}, cc.p(0, 0))
		adapt.oneLineCenterPos(cc.p(75, 20), {self.talentBottom4:get("txt"), self.talentBottom4:get("num")}, cc.p(0, 0))
		adapt.oneLineCenterPos(cc.p(90, 20), {self.talentBottom5:get("txt"), self.talentBottom5:get("num")}, cc.p(0, 0))
		adapt.oneLineCenterPos(cc.p(110, 25), {self.talentBottom6:get("txt"), self.talentBottom6:get("num")}, cc.p(0, 0))
		local tmpCardDatas = {}
		for k, v in ipairs(guardTab) do
			local icon
			if guards[v] then
				local cards = gGameModel.cards:find(guards[v])
				if cards then
					local unitcsv = dataEasy.getUnitCsv(cards:read("card_id"),cards:read("skin_id"))
					icon = unitcsv.iconSimple
				end
				table.insert(tmpCardDatas, {icon = icon})
			end
		end
		local initPosition = matchLanguage{"en"} and 450 or 400
		self.setBtn:x(initPosition + #tmpCardDatas*160)
		self.guardTeam:update(tmpCardDatas)
		self:createNatureAddData(numTab, awake, csvBadge, badgeNumb)

		adapt.oneLineCenterPos(cc.p(900, 719), {self.badgeName, self.list}, cc.p(10, 0))
		self.list:y(self.list:y() - 40)
		self.isLightIn = false
	end)
	idlereasy.when(self.badgeNumb, function(_, badgeNumb)
		local talentTab = csvBadge[badgeNumb].talentIDs
		self.natureData:update(csvBadge[badgeNumb].nature)
		local preBadgeNumb = badgeNumb - 1 > 0 and badgeNumb - 1 or nil
		local nextBadgeNumb = badgeNumb + 1 <= 8 and badgeNumb + 1 or nil

		self.leftTop:removeChildByName("badgeSpine")
		local spine = widget.addAnimationByKey(self.leftTop, "daoguanhuizhang/dghz.skel", "badgeSpine", effectTable[badgeNumb].loopName, 100)
			:xy(830, 450)
			:scale(1.3)
		self.badgeIcon:onTouch(functools.partial(self.onAwake, self, badgeNumb))
		for k, v in ipairs(talentTab) do
			self["talentBottom"..k]:get("icon"):texture(csvBadge[badgeNumb].showIcon3)
		end
		self.leftBtn:visible(badgeNumb ~= 1)
		self.rightBtn:visible(badgeNumb ~= 8)
	end)
	--自己所查看的天賦球
	for i = 1, 6 do
		bind.touch(self, self["talentBottom"..i], {methods = {ended = function()
			self:onMyNodeClick(i)
		end}})
	end
	idlereasy.any({self.items, self.nodeNum, self.myNum, self.gold, self.badgeNumb, self.badges, self.checkBoxState}, function(_, items, nodeNum, myNum, gold, badgeNumb, badges, checkBoxState)
		local talentItem = {}
		local gold = 0
		local badgesData = badges and badges[badgeNumb] or {}
		local talents = badgesData.talents or {}
		local guards = badgesData.guards or {}
		local awake = badgesData.awake or 0
		local talentTab = csvBadge[badgeNumb].talentIDs
		local childs = nodetools.multiget(self.rightTop, "name", "txt1", "txt2", "num1", "num2", "num3", "num4", "num5", "num6","txt3", "txt4","txt5", "txt6", "icon3")
		local talentLv = talents[talentTab[myNum]] or 0
		local talentMyNum = csvBadge[badgeNumb].talentIDs[myNum]
		local talentNodeNum = csvBadge[badgeNumb].talentIDs[nodeNum]
		local costSeqID = csvTalent[talentNodeNum].costSeqID
		local item = csvTalentCost[talentLv]["cost"..costSeqID]
		local attrType1 = csvTalent[talentMyNum].attrType1
		local attrType2 = csvTalent[talentMyNum].attrType2
		local attrNum1 = csvTalent[talentMyNum].attrNum1
		local attrNum2 = csvTalent[talentMyNum].attrNum2

		--左右按钮的情况 以及底部特效
		self:setBtnState(badgeNumb, myNum, talentTab)
		childs.name:text(csvTalent[talentMyNum].name)
		--右边天赋界面加成情况
		local rightTalent = {}
		local isMax = false
		if talents[talentTab[myNum]] and talents[talentTab[myNum]] >= csvBadge[badgeNumb].talentMaxLevel then
			isMax = true
			self.rightBottom:hide()
			self.rightPanel:get("maxBg"):show()
		else
			self.rightBottom:show()
			self.rightPanel:get("maxBg"):hide()
		end
		table.insert(rightTalent, {num = talentLv, num1 = talentLv + 1, isMax = isMax, name = "Lv."})

		--觉醒等级加成
		local awakeTalentAttr = awake ~= 0 and dataEasy.parsePercentStr(dataEasy.getAttrValueString(csvBadge[badgeNumb].attrType1, csvBadge[badgeNumb].awakeTalentAttrs[awake])) or 0
		--守护加成
		local guardTalentAttr = self:guardAllTalent(badgeNumb, guards)
		if attrType1 then
			local num3 = attrNum1[talentLv] or 0
			local finalNum3 = dataEasy.getAttrValueString(attrType1, math.floor(num3*((100 + awakeTalentAttr)/100)*((100 + guardTalentAttr)/100)))
			local num3NextLv = attrNum1 and attrNum1[talentLv + 1] or 0
			local finalNum3NextLv = dataEasy.getAttrValueString(attrType1, math.floor(num3NextLv*((100 + awakeTalentAttr)/100)*((100 + guardTalentAttr)/100)))
			table.insert(rightTalent, {num = finalNum3, num1 = finalNum3NextLv, isMax = isMax, name = getLanguageAttr(attrType1)})
		end
		if attrType2 then
			local num4 = attrNum2[talentLv] or 0
			local finalNum4 = dataEasy.getAttrValueString(attrType1, math.floor(num4*((100 + awakeTalentAttr)/100)*((100 + guardTalentAttr)/100)))
			local num4NextLv = attrNum2[talentLv + 1] or 0
			local finalNum4NextLv = dataEasy.getAttrValueString(attrType1, math.floor(num4NextLv*((100 + awakeTalentAttr)/100)*((100 + guardTalentAttr)/100)))
			table.insert(rightTalent, {num = finalNum4, num1 = finalNum4NextLv, isMax = isMax, name = getLanguageAttr(attrType2)})
		end
		self.rightTalent:update(rightTalent)
		if not checkBoxState then
			for k, v in ipairs(dataEasy.getItemData(item)) do
				if v.key ~= "rmb" and v.key ~= "gold" then
					table.insert(talentItem, {key = v.key, num = items[v.key] or 0, targetNum = v.num})
				end
			end
			gold = item.gold
			self.title:text(gLanguageCsv.lightUp)
		else
			self.times = 6
			gold, talentItem, self.times = getItem(nodeNum, myNum, badgeNumb, talents, items)
			self.title:text(gLanguageCsv.lightUp .. self.times .. gLanguageCsv.times)
		end
		self.item = talentItem
		local itemNum = #talentItem
		self.costList:size(200 * itemNum, 200)
		self.talentItem:update(talentItem)
		-- self.cost = item.rmb
		self.costGold = gold
		if myNum == nodeNum then
			self.lightBtn:setTouchEnabled(true)
			if self.costGold > 0 then
				self.btnPanel:get("text"):show()
				self.btnPanel:get("text"):text(self.costGold)
				local color = gold < self.costGold and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.DEFAULT
				text.addEffect(self.btnPanel:get("text"), {color=color})
				self.btnPanel:get("text1"):show()
				self.btnPanel:get("icon"):show()
				self.costPanel:visible(#talentItem > 0)
				adapt.oneLineCenterPos(cc.p(163, 214), {self.btnPanel:get("text1"), self.btnPanel:get("text"), self.btnPanel:get("icon")}, cc.p(15, 0))
			end
			cache.setShader(self.lightBtn, false, "normal")
		else
			cache.setShader(self.lightBtn, false, "hsl_gray")
		end
	end)
end

function gymBadgeTalentView:setBtnState(badgeNumb, myNum, talentTab)
	if badgeNumb ~= 1 then
		if not self:getNextNum(badgeNumb,"left") then
			cache.setShader(self.leftBtn, false, "hsl_gray")
		else
			cache.setShader(self.leftBtn, false, "normal")
		end
	else
		cache.setShader(self.leftBtn, false, "normal")
	end
	if badgeNumb ~= 8 then
		if not self:getNextNum(badgeNumb,"right") then
			cache.setShader(self.rightBtn, false, "hsl_gray")
		else
			cache.setShader(self.rightBtn, false, "normal")
		end
	else
		cache.setShader(self.rightBtn, false, "normal")
	end
	-- 底部特效
	widget.addAnimationByKey(self["talentBottom"..myNum], "daoguanhuizhang/huizhang_tianfu.skel", "spine5", "xuanzhong_loop", 10)
		:xy(BALLPOSITION[myNum].x, BALLPOSITION[myNum].y)
		:scale(BALLPOSITION[myNum].scaleBattom)
	for k, v in ipairs(talentTab) do
		if k ~= myNum then
			if self["talentBottom"..k]:getChildByName("spine5") then
				self["talentBottom"..k]:removeChildByName("spine5")
			end
		end
	end
end

function gymBadgeTalentView:createSpine(tmp, talents, talentTab)
	for k = tmp, 6 do
		self["talentBottom"..k]:get("icon"):hide()
		if self["talentBottom"..k]:getChildByName("spine") then
			self["talentBottom"..k]:removeChildByName("spine")
		end
		widget.addAnimationByKey(self["talentBottom"..k], "daoguanhuizhang/huizhang_tianfu.skel", "spine", "hui_loop", 2)
			:xy(BALLPOSITION[k].x, BALLPOSITION[k].y)
			:scale(BALLPOSITION[k].scale)
		self["talentBottom"..k]:get("num"):text(talents[talentTab[k]] or 0)
	end
end

function gymBadgeTalentView:createNatureAddData(numTab, awake, csvBadge, badgeNumb)
	local natureAddData = {}
	for key, val in pairs(numTab) do
		if val > 0 then
			local index = game.ATTRDEF_TABLE[key]
			local icon = ui.ATTR_LOGO[index]
			table.insert(natureAddData, {id = key, num = math.floor(val), icon = icon})
		end
	end
	if awake > 0 then
		local attrType1 = csvBadge[badgeNumb].attrType1
		local attrType2 = csvBadge[badgeNumb].attrType2
		if attrType1 then
			local num = csvBadge[badgeNumb].attrNum1[awake] or 0
			local finalNum = dataEasy.getAttrValueString(attrType1, num)
			if num > 0 then
				table.insert(natureAddData, {id = attrType1, num = finalNum})
			end
		end
		if attrType2 then
			local num = csvBadge[badgeNumb].attrNum2[awake] or 0
			local finalNum = dataEasy.getAttrValueString(attrType2, num)
			if num > 0 then
				table.insert(natureAddData, {id = attrType2, num = finalNum})
			end
		end
		self.badgeName:text(csvBadge[badgeNumb].name.."+"..awake)
	else
		self.badgeName:text(csvBadge[badgeNumb].name)
	end
	table.sort(natureAddData, function(a, b)
		return a.id < b.id
	end)
	if itertools.isempty(natureAddData) then
		self.leftBottom:get("txt"):text(gLanguageCsv.noAttributeBonusNow)
		self.leftBottom:get("txt"):show()
	else
		self.leftBottom:get("txt"):hide()
	end
	self.natureAddData:update(natureAddData)
end

function gymBadgeTalentView:initModel()
	self.badges = gGameModel.role:getIdler("badges")
	self.items = gGameModel.role:getIdler("items")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.gold = gGameModel.role:getIdler("gold")
	self.level = gGameModel.role:getIdler("level")
end

function gymBadgeTalentView:onAwake(badgeNumb, event)
	if type(badgeNumb) == "number" then
		if not self.leftTop:getChildByName("badgeSpine") then
			return
		end
		if event.name == "began" then
			self.leftTop:getChildByName("badgeSpine"):scale(1.2)
		elseif event.name == "ended" then
			self.leftTop:getChildByName("badgeSpine"):scale(1.3)
			gGameUI:stackUI("city.develop.gym_badge.badge_awake", nil, nil, badgeNumb)
		elseif event.name == "cancelled" then
			self.leftTop:getChildByName("badgeSpine"):scale(1.3)
		end
	else
		gGameUI:stackUI("city.develop.gym_badge.badge_awake", nil, nil, self.badgeNumb:read())
	end
end

function gymBadgeTalentView:onMyNodeClick(myNum)
	self.myNum:set(myNum)
end

function gymBadgeTalentView:onSet()
	gGameUI:stackUI("city.develop.gym_badge.guard", nil, {full = true}, self.badgeNumb:read())
end

function gymBadgeTalentView:onSetLight()
	local times = self.checkBoxState:read() == true and self.times or 1
	if self.myNum:read() ~= self.nodeNum:read() then
		gGameUI:showTip(gLanguageCsv.setPrevLightFirst)
		return
	end
	if self.costGold and self.gold:read() < self.costGold then
		uiEasy.showDialog("gold", nil, {dialog = true})
		return
	end
	for _, v in ipairs(self.item) do
		if v.targetNum > v.num then
			gGameUI:showTip(gLanguageCsv.branchItemsNotEnough)
			return
		end
	end
	local talentTab = csv.gym_badge.badge[self.badgeNumb:read()].talentIDs
	if not self.isLightMax then
		local showOver = {false}
		for i = 1, times do
			local nodeNum = (self.nodeNum:read() + i - 2) % 6 + 1
			performWithDelay(self["talentBottom"..nodeNum], function()
				if nodeNum == 1 then
					for k, v in ipairs(talentTab) do
						self["talentBottom"..k]:get("icon"):hide()
						local spine2 = self["talentBottom"..k]:getChildByName("spine2")
						if spine2 then
							self["talentBottom"..k]:removeChildByName("spine2")
						end
						if not self["talentBottom" .. k]:getChildByName("spine") then
							widget.addAnimationByKey(self["talentBottom"..k], "daoguanhuizhang/huizhang_tianfu.skel", "spine", "hui_loop", 2)
								  :xy(BALLPOSITION[k].x, BALLPOSITION[k].y)
								  :scale(BALLPOSITION[k].scale)
						end
					end
				end
				local spine2 = self["talentBottom"..nodeNum]:getChildByName("spine2")
				if not spine2 then
					widget.addAnimationByKey(self["talentBottom"..nodeNum], "daoguanhuizhang/huizhang_tianfu.skel", "spine2", "dianliang_effect", 2)
						  :xy(BALLPOSITION[nodeNum].x, BALLPOSITION[nodeNum].y)
						  :scale(BALLPOSITION[nodeNum].scale)
				else
					spine2:show():play("dianliang_effect")
				end
			end, 0.1 * i)
		end
		gGameApp:requestServerCustom("/game/badge/talent/level/up")
			:params(self.badgeNumb:read(), times)
			:onResponse(function (tb)
				for _, child in pairs(self.talentList:getChildren()) do
					local spine = child:get("spine")
					if not spine then
						local spine = widget.addAnimationByKey(child, "effect/shuzisaoguang.skel", "spine", "effect", 122)
								:xy(child:get("icon"):xy())
								:scale(0.5)
					else
						spine:play("effect")
					end
				end

				local spine = self.rightTop:get("upEffect")
				if spine then
					spine:play("fangguang2")
				else
					spine = widget.addAnimationByKey(self.rightTop, "koudai_gonghuixunlian/gonghuixunlian.skel", "upEffect", "fangguang2", 10000)
					spine:xy(self.rightTop:get("icon"):x(), self.rightTop:get("icon"):y() - 80)
					spine:scale(0.8)
				end
				local delayTime = self.times  and 0.7 or 0.5
				performWithDelay(self, function()
					showOver[1] = true
				end, delayTime)
				end)
			:wait(showOver)
			:doit(function ()
			--for i = 1, times do
			--	local nodeNum = (self.nodeNum:read() + i - 2) % 6 + 1
			--	self["talentBottom"..nodeNum]:removeChildByName("spine2")
			--end
			end)
			self.isLightIn = true
	else
		gGameUI:showTip(gLanguageCsv.lightAlreadyMax)
	end
end

function gymBadgeTalentView:onItemClick(list, panel, k, v)
	gGameUI:stackUI("common.gain_way", nil, nil, v.key, nil, v.targetNum)
end

function gymBadgeTalentView:setProgress(nodeNum, talents)
	for k = 1, 8 do
		self.leftTop:get("line"..k):hide()
	end
	if nodeNum == 1 and not self.isLightIn and not self.isLightMax then
		return
	end
	for _, v in pairs(LINETABLE[nodeNum]) do
		-- if self.canAwake == false then
		self.leftTop:get("line"..v):show()
		-- end
	end
	if nodeNum == 1 and not self.isLightMax then
		self:enableSchedule():schedule(function()
			for k = 1, 8 do
				self.leftTop:get("line"..k):hide()
			end
		end, 99999, 0.5)
	end
end

function gymBadgeTalentView:onLeftBtn()
	local nextBadgeNumb = self:getNextNum(self.badgeNumb:read(), "left")
	if nextBadgeNumb then
		self.badgeNumb:set(nextBadgeNumb)
	else
		self:showUnlockTips(self.badgeNumb:read() - 1)
	end
end

function gymBadgeTalentView:onRightBtn()
	local nextBadgeNumb = self:getNextNum(self.badgeNumb:read(), "right")
	if nextBadgeNumb then
		self.badgeNumb:set(nextBadgeNumb)
	else
		self:showUnlockTips(self.badgeNumb:read() + 1)
	end
end

function gymBadgeTalentView:showUnlockTips(badgeNumb)
	local csvBadge = csv.gym_badge.badge
	local preBadgeType = csvBadge[badgeNumb].preBadgeType
	if preBadgeType == 1 then
		gGameUI:showTip(gLanguageCsv.noOpenPleaseToGymView3)
	else
		gGameUI:showTip(gLanguageCsv.noOpenPleaseToGymView4)
	end
end

function gymBadgeTalentView:getNextNum(badgeNumb, direction)
	if direction == "left" then
		badgeNumb = badgeNumb - 1
		if badgeNumb <= 0 then
			return nil
		end
	else
		badgeNumb = badgeNumb + 1
		if badgeNumb > 8 then
			return nil
		end
	end
	local csvBadge = csv.gym_badge.badge
	local preBadgeID = csvBadge[badgeNumb].preBadgeID
	if preBadgeID then
		local badgesData = self.badges:read() and self.badges:read()[preBadgeID] or {}
		if csvBadge[badgeNumb].preBadgeType == 1 then
			local awake = badgesData.awake or 0
			if csvBadge[badgeNumb].preLevel > awake then
				return self:getNextNum(badgeNumb, direction)
			else
				return badgeNumb
			end
		else
			local index = csv.gym_badge.badge[preBadgeID].talentIDs[6]
			local talents = badgesData.talents
			local talent = talents and talents[index] or 0
			if talent < csvBadge[badgeNumb].preLevel then
				return self:getNextNum(badgeNumb, direction)
			else
				return badgeNumb
			end
		end
	else
		return badgeNumb
	end
end

function gymBadgeTalentView:guardAllTalent(badgeNumb, guard)
	local allGuardsNum = 0
	local csvBadge = csv.gym_badge.badge
	local guardTab = csvBadge[badgeNumb].guardIDs
	local badgesData = self.badges:read() and self.badges:read()[self.badgeNumb:read()] or {}
	local guards = badgesData.guards or {}
	if not itertools.isempty(guards) then
		for k, v in ipairs(guardTab) do
			if guards[v] then
				local card = gGameModel.cards:find(guards[v])
				local guardNum = 0
				local cardId = card:read("card_id")
				local advance = card:read("advance")
				local star = card:read("star")
				local cardCsv = csv.cards[cardId]
				local unitCsv = csv.unit[cardCsv.unitID]
				local rarityNum = "0%"
				local starNum = "0%"
				local advanceNum = "0%"
				local sameNum = "0%"
				local nvalue = "0%"
				local isSame = false
				if itertools.include(csv.gym_badge.badge[badgeNumb].nature, unitCsv.natureType) then
					isSame = true
				end
				if itertools.include(csv.gym_badge.badge[badgeNumb].nature, unitCsv.natureType2) then
					isSame = true
				end
				local tNvalue = card:read("nvalue")
				local nvalueSum = 0
				for k, v in pairs(tNvalue) do
					nvalueSum = nvalueSum + v
				end

				for k, v in ipairs(csv.gym_badge.guard_effect) do
					if k == unitCsv.rarity then
						rarityNum = v.rarityAttr
						starNum = v.starAttrs[star]
						advanceNum = v.advanceAttrs[advance]
						if isSame then
							sameNum = v.rarityAttr
						end
						local max = 0
						for kk, vv in orderCsvPairs(v.nvalueAttrs) do
							if nvalueSum >= kk and kk >= max then
								max = kk
								nvalue = vv
							end
						end
					end
				end
				guardNum = dataEasy.parsePercentStr(rarityNum) + dataEasy.parsePercentStr(starNum) + dataEasy.parsePercentStr(advanceNum) + dataEasy.parsePercentStr(sameNum) +dataEasy.parsePercentStr(nvalue)
				allGuardsNum = allGuardsNum + guardNum
			end
		end
	end
	return allGuardsNum
end

function gymBadgeTalentView:onFastUpgradeClick()
	self.checkBoxState:set(not self.checkBoxState:read())
	self.checkBox:setSelectedState(self.checkBoxState:read())
end

function gymBadgeTalentView:onClose()
	gGameApp:requestServer("/game/badge/refresh")
	self.isView:set(true, true)
	ViewBase.onClose(self)
end


return gymBadgeTalentView