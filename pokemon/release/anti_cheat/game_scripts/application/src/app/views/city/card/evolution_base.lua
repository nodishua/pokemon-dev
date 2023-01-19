-- @Date:   2018-12-20
-- @Desc:
-- @Last Modified time: 2019-08-29

local function commonCardShow(childs, v)
	local unit = csv.unit[v.unitID]
	local size = childs.cardImg:size()
	childs.cardImg:removeAllChildren()
	local sprite2 = widget.addAnimation(childs.cardImg, unit.unitRes, "standby_loop")
	sprite2:xy(size.width / 2, size.height / 7)
		:scale(unit.scale)
	sprite2:setSkin(unit.skin)
	childs.name:text(unit.name)
		:show()
		:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	childs.attr2:visible(unit.natureType2 ~= nil)
	if unit.natureType2 then
		childs.attr2:texture(ui.ATTR_ICON[unit.natureType2])
	end
	itertools.invoke({childs.rarity, childs.attr1},"show")
	childs.rarity:texture(ui.RARITY_ICON[unit.rarity])
	childs.attr1:texture(ui.ATTR_ICON[unit.natureType])
	if unit.natureType2 then
		adapt.oneLineCenterPos(cc.p(290, 80), {childs.rarity, childs.name, childs.attr1, childs.attr2}, cc.p(8, 0))
	else
		adapt.oneLineCenterPos(cc.p(290, 80), {childs.rarity, childs.name, childs.attr1}, cc.p(8, 0))
	end
end

-- @desc:下一阶段出现分支(出现球的情况)
-- @node:节点
local function nextBranchsIsNotOnlyShow(node, tag)
	local cardImg = node:get("cardImg")
	ccui.ImageView:create("city/card/evolution/img_unknown@.png")
		:align(cc.p(0.5, 0.5), cardImg:x() - 35, cardImg:y() * 0.55)
		:addTo(cardImg, 2, "ball")
	node:get("btnSelect"):visible(false)
	node:get("btnChanceShape"):visible(false)
	nodetools.invoke(node, {"attr2","attr1","rarity", "name"}, "hide")
	if tag then
		node:get("name"):text(gLanguageCsv.appearBranch):show()
		node:get("name"):setTextColor(ui.COLORS.NORMAL.RED)
		node:get("name"):x(node:get("name"):x()+30)
	end
end

-- local function createForeverAnim(childs)
-- 	return cc.RepeatForever:create(
-- 		cc.Sequence:create(
-- 			cc.DelayTime:create(0.1),
-- 			cc.ScaleTo:create(0.3, 1.1, 1.1),
-- 			cc.DelayTime:create(0.1),
-- 			cc.ScaleTo:create(0.3, 1.0, 1.0)
-- 		)
-- 	)
-- end

local function getBranchData(v)
	local data = v
	local branchSize = itertools.size(v.branch)
	if v.branch[v.currBranch] then
		data = v.branch[v.currBranch]
	end
	return data
end
-- @desc:下一阶段正常卡牌（1.有分支可选，2.无分支可选）
-- @childs: 特殊子节点
-- @v:当前值
-- @branch: 本地存储的假分支
local function nextBranchsIsOnlyShow(childs, v)
	local data = getBranchData(v)
	if childs.cardImg:get("ball") then
		childs.cardImg:get("ball"):hide()
	end
	commonCardShow(childs, data)
end

local ViewBase = cc.load("mvc").ViewBase
local CardEvolutionBaseView = class("CardEvolutionBaseView", Dialog)
CardEvolutionBaseView.RESOURCE_FILENAME = "card_evolution.json"
CardEvolutionBaseView.RESOURCE_BINDING = {
	["effect"] = {
		varname = "effect",
		binds = {
			event = "visible",
			idler = bindHelper.self("showEffect"),
		},
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData"),
				item = bindHelper.self("item"),
				margin = bindHelper.self("listMargin"),
				padding = bindHelper.self("listPadding"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("btnSelect", "next", "cardImg", "name", "attr1",
						"attr2","rarity", "curr", "bottom", "btnSelection", "btnChangeShape", "btnChanceShape")
					for i=1,3 do
						node:removeChildByName("effect" .. i)
					end
					local isNowState = v.develop == v.currDevelop
					bind.touch(list, childs.btnSelect, {methods = {ended = functools.partial(list.clickSelect, k)}})
					bind.touch(list, childs.btnSelection, {methods = {ended = functools.partial(list.clickSelection, k)}})
					bind.touch(list, childs.btnChangeShape, {methods = {ended = functools.partial(list.clickChangeShape, k)}})
					bind.touch(list, childs.btnChanceShape, {methods = {ended = functools.partial(list.clickChangeShape, k)}})
					childs.curr:visible(false)
					local size = node:size()
					local eff1 = CSprite.new("effect/jinhuajiemian.skel")
					eff1:xy(size.width / 2 - 40, size.height / 4 - 15)
					eff1:play("effect_down2_loop")
					eff1:addTo(node, 4, "effect1")
					eff1:visible(isNowState)

					local eff2 = CSprite.new("effect/jinhuajiemian.skel")
					eff2:xy(size.width / 2 - 40, size.height / 4 - 15)
					eff2:play("effect_down_loop")
					eff2:addTo(node, 5, "effect2")
					eff2:visible(isNowState)

					local eff3 = CSprite.new("effect/jinhuajiemian.skel")
					eff3:xy(size.width / 2 - 40, size.height / 4 - 15)
					eff3:play("effect_up_loop")
					eff3:addTo(node, 7, "effect3")
					eff3:visible(isNowState)

					childs.bottom:visible(not isNowState)
					if v.develop <= v.currDevelop then
						if childs.cardImg:get("ball") then
							childs.cardImg:get("ball"):hide()
						end
						if v.currDevelop == v.maxDevelop then
							if v.isBranch and v.cardSwitchBranch and v.develop == v.maxDevelop
								and itertools.size(v.branch) > 1 then
								if v.branchType == 1 then
									childs.btnSelection:show()
								elseif v.branchType == 2 then
									childs.btnChangeShape:show()
								end
							else
								childs.btnSelection:hide()
								childs.btnChangeShape:hide()
							end
						else
							if v.isBranch and v.cardSwitchBranch and itertools.size(v.branch) > 1 then
								if v.branchType == 1 then
									childs.btnSelection:show()
								elseif v.branchType == 2 then
									childs.btnChangeShape:show()
								end
							else
								childs.btnSelection:hide()
								childs.btnChangeShape:hide()
							end
						end
						commonCardShow(childs, getBranchData(v))
						childs.btnSelect:hide()
						childs.btnChanceShape:hide()
					else
						local branchSize = itertools.size(v.branch)
						childs.btnSelect:visible(branchSize > 1 and v.isBranchPoint and v.branchType == 1)
						childs.btnChanceShape:visible(branchSize > 1 and v.isBranchPoint and v.branchType == 2)
						if not v.branch[v.currBranch] and branchSize > 1 then
							nextBranchsIsNotOnlyShow(node)
						else
							nextBranchsIsOnlyShow(childs, v)
						end
					end
					childs.next:visible(k ~= 1)
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
					local count = list:getChildrenCount()
					if count > 3 then
						list:jumpToPercentHorizontal(80)
					end
				end,
			},
			handlers = {
				clickSelect = bindHelper.self("onSelectBranch"),
				clickSelection = bindHelper.self("onChangeBranch"),
				clickChangeShape = bindHelper.self("onChangeShape"),
			},
		},
	},
	["bottomPanel"] = "bottomPanel",
	["item1"] = "item1",
	["bottomPanel.list"] = {
		varname = "bottomList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showSmallData"),
				item = bindHelper.self("item1"),
				margin = 20,
				onItem = function(list, node, k, v)
					local hasNum = dataEasy.getNumByKey(v.id)
					local binds = {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = hasNum,
								targetNum = v.num,
							},
							noListener = true,
							grayState = hasNum >= v.num and 1 or 0,
						},
					}
					bind.extend(list, node, binds)
					node.panel:setTouchEnabled(false)
					nodetools.invoke(node, {"mask","add"},"visible", v.num>hasNum)
					bind.touch(node, node, {methods = {ended = function ()
						gGameUI:stackUI("common.gain_way", nil, nil, v.id, nil, v.num)
					end}})
				end
			},
		},
	},
	["bottomPanel.num"] = {
		varname = "cost",
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.DEFAULT}
		},
	},
	["bottomPanel.txt1"] = "txt1",
	["bottomPanel.txt2"] = "txt2",
	["bottomPanel.txt3"] = "txt3",
	["bottomPanel.txtNot1"] = "txtNot1",
	["bottomPanel.txtNot2"] = "txtNot2",
	["bottomPanel.icon"] = "bottomIcon",
	["branchPanel"] = "branchPanel",
	["branchPanel.btnBranch"] = {
		varname = "btnBranch",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSelectBranch")}
		}
	},
	["lastTxt"] = "lastTxt",
	["bottomPanel.btnEvolution"] = {
		varname = "btnEvolution",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEvolution")}
		}
	},
	["bottomPanel.btnEvolution.title"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
}

function CardEvolutionBaseView:onCreate(selectDbId)
	self.update = idler.new(false)
	self.selectDbId = selectDbId
	self:initModel()
	self.cardSwitchBranch = dataEasy.isUnlock(gUnlockCsv.cardSwitchBranch)
	self.canClick = true
	self.showEffect = idler.new(false)
	local originX = self.list:x()
	self.showSmallData = idlertable.new({})
	local xPos = {
		originX + 680,
		originX + 350,
		originX,
	}

	-- 进化链数据
	self.showData = idlertable.new()
	-- 当前进化阶段
	self.currDevelop = idler.new()
	-- 当前选中分支 0没选择
	local data = userDefault.getForeverLocalKey("evolutionBranch", {})
	local csvCards = csv.cards[self.cardId:read()]
	local currBranch = csvCards.branch
	if currBranch == 0 and data[self.cardId:read()] then
		currBranch = data[self.cardId:read()]
	end
	self.currBranch = idler.new(currBranch)
	self:setDevelopData()
	-- 最大进化状态
	self.maxDevelop = #self.mainData
	-- 标记原本的分支
	self.oldCurrBranch = currBranch

	idlereasy.when(self.update, function(_,updade)
		self:initModel()
	end)

	idlereasy.when(self.cardId, function(_,cardId)
		self:setDevelopData()
		self.maxDevelop = #self.mainData
		self.oldCurrBranch = currBranch
		local currBranch = csv.cards[self.cardId:read()].branch
		self.currBranch:set(currBranch, true)
	end)

	idlereasy.when(self.currBranch, function(obj, currBranch)
		local cardId = self.cardId:read()
		local csvCards = csv.cards[cardId]
		local currMarkID = csvCards.cardMarkID
		local currDevelop = csvCards.develop
		self.currDevelop:set(csvCards.develop)
		local t = {}
		-- 分叉点
		local isBranchPoint = false
		for i,v in ipairs(self.mainData) do
			local branchSize = itertools.size(v.branch)
			-- 如果选择的分支没有数据 说明没有改进化状态
			if currBranch ~= 0 and not v.branch[currBranch] and branchSize ~= 0 then
				break
			end
			if v.develop > self.maxDevelop then
				self.maxDevelop = v.develop
			end
			if v.branch[currBranch] and v.branch[currBranch].develop > self.maxDevelop then
				self.maxDevelop = v.branch[currBranch].develop
			end
			v.isBranchPoint = false
			if branchSize > 1 and not isBranchPoint then
				isBranchPoint = true
				v.isBranchPoint = true
				if currBranch ~= 0 and v.branch[currBranch].id == cardId then
					if self.oldCurrBranch ~= 0 then
						uiEasy.showConfirmNature(v.branch[self.oldCurrBranch].id, v.branch[currBranch].id)
						self.oldCurrBranch = currBranch
					end
				end
			end
			v.currDevelop = currDevelop
			v.currBranch = currBranch
			self.branchType = v.branchType
			table.insert(t, v)
		end
		table.sort(t, function(a,b)
			return a.develop < b.develop
		end)
		self.developPos = 1
		for i,v in ipairs(t) do
			if cardId == v.id then
				self.developPos = i
			end
			for k,v in pairs(v.branch) do
				if cardId == v.id then
					self.developPos = i
				end
			end
		end
		self.showData:set(t, true)
		local developLength = #t
		self.listPadding  = developLength <= 1 and 120 or 0
		if currBranch ~= 0 then
			self.list:setTouchEnabled(developLength > 3)
			-- self.list:x(xPos[developLength <= 3 and developLength or 3])
			self.listMargin = developLength <= 3 and 2 or -12
		else
			self.list:setTouchEnabled(developLength > 3)
			-- self.list:x(xPos[developLength <= 3 and developLength or 3])
			self.listMargin = developLength <= 3 and 2 or -12
		end
		self:bottomPanelRefresh(currBranch, currDevelop)
	end)
	Dialog.onCreate(self)
end

function CardEvolutionBaseView:initModel()
	local card = gGameModel.cards:find(self.selectDbId)
	self.attrs = card:getIdler("attrs")
	self.oldFight = card:getIdler("fighting_point")
	self.cardId = card:getIdler("card_id")
	self.star = card:getIdler("star")
	self.advance = card:getIdler("advance")
	self.level = card:getIdler("level")
	-- self.cards = gGameModel.role:getIdler("cards")
	-- self.cardId = idlereasy.assign(card:getIdler("card_id"), self.cardId)
end

-- function CardEvolutionBaseView:onCleanup()
-- 	self._selectDbId = self.selectDbId:read()
-- 	ViewBase.onCleanup(self)
-- end

function CardEvolutionBaseView:setDevelopData()
	local csvCards = csv.cards[self.cardId:read()]
	local currMarkID = csvCards.cardMarkID
	-- 以markId为key保存可以超进化的卡牌
	self.cardMaskData = {}
	-- 主干数据
	self.mainData = {}
	-- 分支数据
	self.branchData = {}
	local maxDevelop = 0
	for i,v in orderCsvPairs(csv.cards) do
		if matchLanguage(v.languages) and v.canDevelop and v.cardMarkID == currMarkID then
			if v.develop > maxDevelop then
				maxDevelop = v.develop
			end
		end
	end

	for i,v in orderCsvPairs(csv.cards) do
		if matchLanguage(v.languages) and v.canDevelop and v.cardMarkID == currMarkID then
			if not self.cardMaskData[v.cardMarkID] then
				self.cardMaskData[v.cardMarkID] = {}
			end
			table.insert(self.cardMaskData[v.cardMarkID], i)
			if not self.branchData[v.branch] then
				self.branchData[v.branch] = {}
			end
			local isBranch = false
			if v.branch ~= 0 then
				isBranch = true
			end
			table.insert(self.branchData[v.branch], {
				currDevelop = v.develop,
				currRealBranch = v.branch,
				currBranch = 0,
				id = i,
				unitID = v.unitID,
				cardMarkID = v.cardMarkID,
				-- cfg = v,
				develop = v.develop,
				isBranchPoint = false,
				branch = {},
				megaIndex = v.megaIndex,
				isBranch = isBranch,
				cardSwitchBranch = self.cardSwitchBranch,
				branchType = v.branchType,
				maxDevelop = maxDevelop,
			})
		end
	end
	local branchLength = 0
	local branchData = {}
	for i,v in pairs(self.branchData) do
		if i ~= 0 and #v > branchLength then
			branchLength = #v
			branchData = v
		end
	end
	table.sort(branchData, function(a,b)
		return a.develop < b.develop
	end)
	self.mainData = self.branchData[0] or {}
	for i=1,branchLength do
		local mainData = branchData[i]
		for branch,v in pairs(self.branchData) do
			table.sort(v, function(a,b)
				return a.develop < b.develop
			end)
			if branch ~= 0 and v[i] then
				mainData.branch[v[i].currRealBranch] = v[i]
			end
		end
		table.insert(self.mainData, mainData)
	end

	--如果没有超进化把它从数据删除，可以让他进入超进化屋，否则让他存在，显示达到进化最大状态
	local dataKey = {}
	local cardShow = false
	local megaIndex = csv.cards[self.cardId:read()].megaIndex > 0 and true or false
	for k,v in pairs(self.mainData) do
		if v.megaIndex == 0 then
			table.insert(dataKey, v)
		else
			cardShow = true
		end
	end
	--如果是该卡牌没有超进化，那么过滤掉超进化卡牌(这里的超进化卡牌可能通过markid获得)
	if not megaIndex and cardShow then
		self.mainData = dataKey
	end
end

function CardEvolutionBaseView:bottomPanelRefresh(branch, develop)
	local star = self.star:read()
	local level = self.level:read()
	local advance = self.advance:read()
	local id
	local nextData = self.showData:proxy()[self.developPos + 1]
	--初始状态
	if nextData then
		id = getBranchData(nextData).id
	end
	local base = csv.base_attribute.develop_level[id]
	if self.maxDevelop > develop and base then
		local index = 0
		local t = {}
		for k, v in csvMapPairs(base.cost) do
			if k ~= "gold" then
				table.insert(t, {id = k, num = v})
			end
		end
		self.showSmallData:set(t, true)
		self.strs = {}
		local function insertStrs(strs, params)
			if params.base ~= 0 then
				local str
				if not params.special then
					if not params.color then
						local t = {}
						local needAdvance = params.base
						local starNum = needAdvance > 6 and 6 or needAdvance
						for i=1,starNum do
							local starIdx = needAdvance - 6
							if i <= starIdx then
								table.insert(t, "#Icommon/icon/icon_star_z.png-50-50#")
							else
								table.insert(t, "#Icommon/icon/icon_star.png-50-50#")
							end
						end
						str = params.str .. table.concat(t, "")
					else
						str = string.format(params.str, params.color, params.state, params.base)
					end
				else
					local quailty, str1 = dataEasy.getQuality(params.base, false)
					str = string.format(params.str, ui.QUALITYCOLOR[quailty], gLanguageCsv[ui.QUALITY_COLOR_TEXT[quailty]], str1)
				end
				table.insert(strs, {str = str, state = params.state >= params.base and 1 or 0, tip = params.tip})
			end
		end
		local color = "#C0x60C456#"
		if level < base.needLevel then
			color = "#C0xF76B45#"
		end
		if base.needLevel ~= 0 then
			insertStrs(self.strs,{str = gLanguageCsv.cardLevelArrive, state = level,base = base.needLevel,
				tip = gLanguageCsv.spriteEvolutionLevelNotEnough, color = color})
		end
		if base.needStar ~= 0 then
			insertStrs(self.strs,{str = gLanguageCsv.cardStarArrive, state = star, base = base.needStar,
				tip = gLanguageCsv.spriteEvolutionStarNotEnough})
		end
		if base.needAdvance ~= 0 then
			insertStrs(self.strs,{special = true, str = gLanguageCsv.cardAdvanceArrive, state = advance,
				base = base.needAdvance, tip = gLanguageCsv.spriteEvolutionAdvanceNotEnough})
		end
		table.sort(self.strs, function (a, b)
			return a.state < b.state
		end)
		for i=1,2 do
			self["txt"..i]:visible(false)
			self["txtNot"..i]:visible(false)
			self.bottomPanel:removeChildByName("richText" .. i)
		end
		for i = 1, math.min(#self.strs, 2) do
			local x, y = self["txt"..i]:xy()
			local content = "#C0x5B545B#" .. i.."."..self.strs[i].str
			local endStr = " #Icity/card/evolution/logo_tick1.png#"
			if self.strs[i].state ~= 1 then
				endStr = "#C0xF76B45#" .. gLanguageCsv.notFinished
			end
			content = content .. endStr
			local richText = rich.createWithWidth(content, 40, nil, 1100)
				:anchorPoint(0, 0.5)
				:xy(x, y)
				:addTo(self.bottomPanel, 10, "richText" .. i)
		end
		if base.cost.gold and base.cost.gold ~= 0 then
			self.cost:text(base.cost.gold)
			self.cost:show()
			self.bottomIcon:show()
			self.txt3:show()
			adapt.oneLineCenterPos(cc.p(self.btnEvolution:x(), self.btnEvolution:y() + 90), {self.txt3, self.cost, self.bottomIcon}, cc.p(10, 0))
			idlereasy.when(gGameModel.role:getIdler('gold'), function(_, gold)
				self.enoughGold = gold >= base.cost.gold
				self.cost:setTextColor(self.enoughGold and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.RED)
			end):anonyOnly(self, 'gold')
		else
			self.cost:hide()
			self.bottomIcon:hide()
			self.txt3:hide()
		end
	end

	self:bottomPanelBranchRefresh(branch, develop, nextData)
end

function CardEvolutionBaseView:bottomPanelBranchRefresh(branch, develop, nextData)
	-- 选中分支有数据 或分支数小于等于1 则不需要选择分支
	local alreadySelectBranch = nextData and (nextData.branch[branch] ~= nil or itertools.size(nextData.branch) <= 1)
	self.bottomPanel:visible(develop ~= self.maxDevelop and alreadySelectBranch)
	self.branchPanel:visible(develop ~= self.maxDevelop and not alreadySelectBranch)
	if self.branchType == 2 then
		self.branchPanel:get("txt"):text(gLanguageCsv.succeedChanceChangeShapeText)
		adapt.setTextScaleWithWidth(self.btnBranch:get("title"), gLanguageCsv.shapeLookText,300)
	end
	self.cardMega = false
	local mageSele = false
	local markId = csv.cards[self.cardId:read()].cardMarkID
	for _, id in pairs(self.cardMaskData[markId]) do
		if csv.cards[id].megaIndex > 0 then
			mageSele = true
		end
	end

	--该卡牌是否超进化
	local megaIndexs = csv.cards[self.cardId:read()].megaIndex == 0
	--如果超级进化unlock打开并且满足条件就显示超级进化入口(已经进化过的不能进入)
	--第一个判断是达到当前状态的最高，但是没有进入超进化(有超进化入口)
	--第二个判断是已经超进化过了
	--第三个就是没有超进化也没有达到前卡牌的最大状态
	if mageSele and develop == self.maxDevelop and dataEasy.isUnlock(gUnlockCsv.mega) and megaIndexs then
		self.branchPanel:visible(true)
		self.branchPanel:get("txt"):visible(false)
		adapt.setTextScaleWithWidth(self.btnBranch:get("title"), gLanguageCsv.megaHouse, 300)
		self.cardMega = true
		self.lastTxt:visible(false)
	elseif develop == self.maxDevelop then
		self.lastTxt:visible(true)
		self.branchPanel:get("txt"):visible(true)
	else
		self.lastTxt:visible(false)
	end
end

function CardEvolutionBaseView:onSelectBranch()
	if not self.cardMega then
		if self.branchType == 1 then
			gGameUI:stackUI("city.card.evolution_branch",nil, nil, self:createHandler("sendParams"))
		else
			gGameUI:stackUI("city.card.evolution_change_shape",nil, nil, self:createHandler("sendParams"))
		end
	else
		gGameUI:stackUI("city.card.mega.view",nil, {full = true}, self.cardId:read(),self:createHandler("updateDbid"))
	end
end

function CardEvolutionBaseView:onChangeBranch()
	gGameUI:stackUI("city.card.evolution_branch",nil, nil, self:createHandler("sendParams"))
end

function CardEvolutionBaseView:onChangeShape()
	gGameUI:stackUI("city.card.evolution_change_shape",nil, nil, self:createHandler("sendParams"))
end

function CardEvolutionBaseView:playAction(callback)
	self.showEffect:set(true)
	local effect1 = self.effect:getChildByName("effect1")
	if not effect1 then
		effect1 = widget.addAnimationByKey(self.effect, "effect/jinhua.skel", "effect1", "effect_down", 1)
			:scale(2)
			:alignCenter(self.effect:size())
	end
	effect1:play("effect_down")

	local effect2 = self.effect:getChildByName("effect2")CSprite.new("effect/jinhua.skel")
	if not effect2 then
		effect2 = widget.addAnimationByKey(self.effect, "effect/jinhua.skel", "effect2", "effect_up", 3)
			:scale(2)
			:alignCenter(self.effect:size())
	end
	effect2:play("effect_up")
	local developPos = self.developPos
	local before = self.showData:proxy()[self.developPos - 1]
	local data = getBranchData(before)
	local unit = csv.unit[data.unitID]
	self.effect:removeChildByName("roleSpine")
	local role1 = widget.addAnimationByKey(self.effect, unit.unitRes, "roleSpine", "standby_loop", 2)
		:alignCenter(self.effect:size())
		:y(380)
		:scale(unit.scale)
	role1:setSkin(unit.skin)
	role1:setCascadeOpacityEnabled(true)
	performWithDelay(self.effect, function()
		transition.fadeOut(role1, {time = 5/30})
	end, 29 / 30)

	performWithDelay(self.effect, function()
		self.effect:removeChildByName("roleSpine")
		local now = self.showData:proxy()[self.developPos]
		local data = getBranchData(now)
		local unit = csv.unit[data.unitID]
		local role2 = widget.addAnimationByKey(self.effect, unit.unitRes, "roleSpine", "standby_loop", 2)
			:alignCenter(self.effect:size())
			:y(380)
			:scale(unit.scale)
		role2:setSkin(unit.skin)
	end, 258 / 30)

	performWithDelay(self.effect, function()
		self.showEffect:set(false)
		if callback then
			callback()
		end
	end, 345 / 30)
end

function CardEvolutionBaseView:onEvolution()
	if not self.canClick then
		return
	end
	local cardOld = self.cardId:read()
	for i,v in ipairs(self.strs) do
		if v.state == 0 then
			gGameUI:showTip(v.tip)
			return
		end
	end
	if not self.enoughGold then
		uiEasy.showDialog('gold')
		return
	end
	self.canClick = false
	local showOver = {false}
	local nextData = self.showData:proxy()[self.developPos + 1]
	local branch = nextData.currRealBranch
	if nextData.branch[self.currBranch:read()] then
		branch = nextData.branch[self.currBranch:read()].currRealBranch
	end
	local oldFight = self.oldFight:read()
	--这里不clone的话 成功界面前后属性一样
	local attrs = clone(self.attrs:read())
	gGameApp:requestServerCustom("/game/card/develop")
		:params(self.selectDbId, branch)
		:delay(0.1)
		:doit(function()
			audio.playEffectWithWeekBGM("evolution.mp3")
			self:playAction(function()
				self.canClick = true
				gGameUI:stackUI("city.card.common_success", nil, {blackLayer = true},
					self.selectDbId,
					oldFight,
					{cardOld = cardOld, attrs = attrs}
				)
			end)
		end)
end

function CardEvolutionBaseView:sendParams(branch)
	if branch then
		self.currBranch:set(branch)
	end
	return self.currDevelop:read(), self.mainData, self.currBranch:read(), self.selectDbId, self.currBranch
end

function CardEvolutionBaseView:updateDbid()
	self.update:set(not self.update:read())
end
return CardEvolutionBaseView