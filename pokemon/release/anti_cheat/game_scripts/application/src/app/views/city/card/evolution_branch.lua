-- @Date:   2018-12-21
-- @Desc:
-- @Last Modified time: 2019-05-10

local zawakeTools = require "app.views.city.zawake.tools"

local function setBranchData(data,currId)
	local showData1 = {}
	local showData2 = {}
	local csvCards = csv.cards[currId]
	local currDevelop = csvCards.develop
	for i,v in ipairs(data) do
		local branchSize = itertools.size(v.branch)
		if branchSize > 1 then
			showData1 = v.branch
			table.sort(showData1, function(a,b)
				return a.develop < b.develop
			end )
			if data[i + 1] then
				showData2 = data[i + 1].branch
				for i,v in pairs(showData1) do
					if not showData2[i] then
						showData2[i] = {}
					end
					showData2[i].develop = v.develop
				end
				table.sort(showData2, function(a,b)
					return a.develop < b.develop
				end)
			end
			break
		end
	end

	if itertools.size(showData2) > 0 then
		for k,v in ipairs(showData1) do
			v.curr = false
		end
		for k,v in ipairs(showData2) do
			if v.unitID == currId then
				v.curr = true
			else
				v.curr = false
			end
		end
	end
	return showData1, showData2
end

local function getShowData2Size(showData)
	local cnt = 0
	for k,v in showData:pairs() do
		local data = v:proxy()
		if data.unitID then
			cnt = cnt +1
		end
	end
	return cnt
end



local CardEvolutionBranchView = class("CardEvolutionBranchView", Dialog)
CardEvolutionBranchView.RESOURCE_FILENAME = "card_evolution_branch.json"
CardEvolutionBranchView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["btnPanel"] = "btnPanel",
	["btnPanel.btnBranch"] = {
		varname = "btnBranch",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSwitch")}
		}
	},
	["btnPanel1"] = "btnPanel1",
	["btnPanel1.btnBranch"] = {
		varname = "btnBranch1",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSwitchChange")}
		}
	},
	["btnPanel.btnBranch.title"] = "branchTxt",
	["btnPanel.text"] = "specialText",
	["spritePanel"] = "spritePanel",
	["item1"] = "item1",
	["item2"] = "item2",
	["branchPanel"] = "branchPanel",
	["branchPanel.list1"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData1"),
				item = bindHelper.self("item1"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("select")
					childs.select:visible(v.curr==true)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							cardId = v.id,
							onNode = function(node)
								node:xy(10,10)
							end,
							onNodeClick = functools.partial(list.clickCell, k, v)
						},
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onSelectClick"),
			},
		}
	},
	["branchPanel.list2"] = {
		varname = "list2",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData2"),
				item = bindHelper.self("item2"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("select")
					childs.select:visible(v.curr==true)
					if v.id then
						bind.extend(list, node, {
							class = "card_icon",
							props = {
								cardId = v.id,
								onNode = function(node)
									node:xy(0,12)
								end,
								onNodeClick = functools.partial(list.clickCell, k, v)
							},
						})
					end
				end
			},
			handlers = {
				clickCell = bindHelper.self("onList2SelectClick"),
			},
		}
	},
	["branchPanel.img1"] = "img1",
	["branchPanel.img2"] = "img2",
	["line12"] = "line12",
	["line13"] = "line13",
	["line122"] = "line122",
	["line133"] = "line133",
	["costPanel"] = "costPanel",
	["costPanel.text"] = "costText",
	["costPanel.item"] = "costItem",
	["costPanel.list"] = {
		varname = "costList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("developItem"),
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
}

function CardEvolutionBranchView:onCreate(params)
	self.costPanel:hide()
	self.params = params
	local develop, data, branch, selectDbId, oldCurrBranch= params()
	self.oldCurrBranch = oldCurrBranch
	self.selectDbId = selectDbId
	self.data = data

	self.branch = idler.new(branch)
	self.cost = 0
	self:initModel()
	local developType = csv.cards[self.cardId].developType
	local developData = {}
	local developItem = {}
	self.developItem = idlers.new()
	self.iconItem = {}

	local showData1, showData2 = setBranchData(data,self.cardId)
	self.showData1 = idlers.newWithMap(showData1)
	self.showData2 = idlers.newWithMap(showData2)

	local cardCfg = csv.cards[self.cardId]
	self:switchSpriteSpine(cardCfg)
	self.isData2Branch = self.showData2:size() > 0

	local ischangeSwitch = false
	for k, v in ipairs(showData1) do
		if v.id == self.cardId then
			self.btnPanel:hide() --选择此分支
			self.btnPanel1:show() -- 当前分支
			ischangeSwitch = true
			break
		end
		self.btnPanel1:hide()
		self.btnPanel:show()
	end

	for k,v in ipairs(showData2) do
		if v.id == self.cardId then
			self.btnPanel:hide()
			self.btnPanel1:show()
			ischangeSwitch = true
			break
		end
		self.btnPanel1:hide()
		self.btnPanel:show()
	end

	if ischangeSwitch == true then
		local csvBranch = csv.cards_branch_cost
		for k, v in orderCsvPairs(csvBranch) do
			if v.developType == developType then
				local tmp = 0
				for _, _ in csvPairs(v.cost) do
					tmp = tmp + 1
				end
				tmp = math.min(self.switchTimes, tmp)
				self.cost = v.cost[tmp].rmb or 0
				developData = dataEasy.getItemData(v.cost[tmp])
			end
		end
	end
	local costListX = self.costList:x()
	local costTextX = self.costText:x()
	idlereasy.when(self.items, function(_, items)
		for k, v in ipairs(developData) do
			if v.key ~= "rmb" and v.key ~= "gold" then
				table.insert(developItem, {key = v.key, num = items[v.key] or 0, targetNum = v.num})
			end
		end
		if developData.gold then
			table.insert(developItem, {key = "gold", num = developData.gold})
		end
		local itemNum = #developItem
		self.costList:size(200 * itemNum, 200)
		self.costList:x(costListX - 200 * (itemNum - 1))
		self.costText:x(costTextX - 200 * (itemNum - 1))
		self.item = developItem
		self.developItem:update(developItem)
	end)
	local showTab1 = branch
	local showTab2 = branch
	local i = 0
	for k,v in self.showData1:pairs() do
		local data = v:proxy()
		i = i + 1
		if data.curr == true then
			showTab1 = i
			break
		end
	end
	self.showTab1 = idler.new(showTab1)
	self.showTab2 = idler.new(showTab2)
	local num = self.showData1:size()
	local name = "line1".. (self.showData2:size() == 0 and num or num..self.showData2:size())
	if self.showData2:size() == 0 then
		self.showTab1:addListener(function (val, oldval, idler)
			self.btnBranch:setTouchEnabled(val ~= 0)
			self.specialText:visible(val == 0)
			cache.setShader(self.btnBranch, false, val ~= 0 and "normal" or "hsl_gray")
			if val ~= 0 then
				if showData1[val].id == self.cardId then
					self.btnBranch1:setTouchEnabled(false)
					self.btnPanel1:get("text"):hide()
					self.btnPanel1:get("text1"):hide()
					self.btnPanel1:get("icon"):hide()
					self.costPanel:hide()
					self.btnBranch1:get("title"):text(gLanguageCsv.nowBranch)
					cache.setShader(self.btnBranch1, false, "hsl_gray")
				else
					self.btnBranch1:setTouchEnabled(true)
					if self.cost > 0 then
						self.btnPanel1:get("text"):show()
						self.btnPanel1:get("text"):text(self.cost)
						self.btnPanel1:get("text1"):show()
						self.btnPanel1:get("icon"):show()
					end
					self.costPanel:visible(#self.item > 0)
					self.btnBranch1:get("title"):text(gLanguageCsv.chanceBranch)
					cache.setShader(self.btnBranch1, false, "normal")
				end
			end
			if val ~= 0 then
				text.addEffect(self.branchTxt, {glow = {color = ui.COLORS.GLOW.WHITE}, color = ui.COLORS.NORMAL.WHITE})
			else
				text.deleteAllEffect(self.branchTxt)
				text.addEffect(self.branchTxt, {color = ui.COLORS.DISABLED.WHITE})
			end
			if oldval ~= 0 then
				self.showData1:atproxy(oldval).curr = false
				self[name]:get("red"..oldval):hide()
			end
			if val ~= 0 then
				local showData1 = self.showData1:atproxy(val)
				showData1.curr = true
				self[name]:get("red"..val):show()
				self:switchSpriteSpine(showData1)
				self.branch:set(showData1.currRealBranch)
			end
		end)
	else
		self.showTab2:addListener(function (val, oldval, idler)
			self.btnBranch:setTouchEnabled(val ~= 0)
			self.specialText:visible(val == 0)
			cache.setShader(self.btnBranch, false, val ~= 0 and "normal" or "hsl_gray")
			if val ~= 0 then
				if showData2[val].id == self.cardId then
					self.btnBranch1:setTouchEnabled(false)
					self.btnPanel1:get("text"):hide()
					self.btnPanel1:get("text1"):hide()
					self.btnPanel1:get("icon"):hide()
					self.costPanel:hide()
					self.btnBranch1:get("title"):text(gLanguageCsv.nowBranch)
					cache.setShader(self.btnBranch1, false, "hsl_gray")
				else
					self.btnBranch1:setTouchEnabled(true)
					if self.cost > 0 then
						self.btnPanel1:get("text"):show()
						self.btnPanel1:get("text"):text(self.cost)
						self.btnPanel1:get("text1"):show()
						self.btnPanel1:get("icon"):show()
					end
					self.costPanel:visible(#self.item > 0)
					self.btnBranch1:get("title"):text(gLanguageCsv.chanceBranch)
					cache.setShader(self.btnBranch1, false, "normal")
				end
			end
			if val ~= 0 then
				text.addEffect(self.branchTxt, {glow = {color = ui.COLORS.GLOW.WHITE}, color = ui.COLORS.NORMAL.WHITE})
			else
				text.deleteAllEffect(self.branchTxt)
				text.addEffect(self.branchTxt, {color = ui.COLORS.DISABLED.WHITE})
			end
			if oldval ~= 0 then
				self.showData2:atproxy(oldval).curr = false
				self[name]:get("red"..oldval):hide()
			end
			if val ~= 0 then
				local showData2 = self.showData2:atproxy(val)
				showData2.curr = true
				self[name]:get("red"..val):show()
				self:switchSpriteSpine(showData2)
				self.branch:set(showData2.currRealBranch)
			end
		end)
	end
	-- 连线
	self:setLine(name)
	--获得上一个形态
	local oldCardId = 1
	local cardMarkID = csv.cards[self.cardId].cardMarkID
	for k, v in orderCsvPairs(csv.cards) do
		if matchLanguage(v.languages) and v.cardMarkID == cardMarkID and v.develop <= develop then
			if v.branch == 0 then
				if oldCardId < k then
					oldCardId = k
				end
			end
		end
	end
	-- 精灵头像
	local posX = self.showData2:size() == 0 and 178 or 28
	bind.extend(self, self.branchPanel, {
		class = "card_icon",
		props = {
			cardId = ischangeSwitch and oldCardId or self.cardId,
			onNode = function(node)
				node:xy(cc.p(posX, 250))
			end,
		},
	})
	--消耗通用
	idlereasy.when(self.rmb, function(_, rmb)
		local color = rmb < self.cost and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.DEFAULT
		text.addEffect(self.btnPanel1:get("text"), {color=color})
	end)
	-- 精灵底座
	self:setBottomSpine()
	Dialog.onCreate(self)
end

function CardEvolutionBranchView:initModel()
	local card = gGameModel.cards:find(self.selectDbId)
	self.cardId = card:read("card_id")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.switchTimes = card:read("branch_switch_times") + 1
	self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
end
-- 精灵底座
function CardEvolutionBranchView:setBottomSpine()
	local size = self.spritePanel:size()
	local eff1 = CSprite.new("effect/jinhuajiemian.skel")
	eff1:xy(size.width / 2 - 40, size.height / 4 - 15)
	eff1:play("effect_down2_loop")
	eff1:addTo(self.spritePanel, 4, "effect1")
	local eff2 = CSprite.new("effect/jinhuajiemian.skel")
	eff2:xy(size.width / 2 - 40, size.height / 4 - 15)
	eff2:play("effect_up_loop")
	eff2:addTo(self.spritePanel, 7, "effect2")
end
-- 设置连线
function CardEvolutionBranchView:setLine(name)
	local listSize2 = cc.size(215,422)
	local imgSize2 = cc.size(214,432)
	local listSize3 = cc.size(215,646)
	local imgSize3 = cc.size(214,658)
	local listY2 = 136
	local listY3 = 21
	local imgY = 345
	if self.showData2:size() == 0 then
		self.list2:hide()
		if self.showData1:size() == 2 then
			self.list1:xy(533,listY2)
			self.list1:size(listSize2)
			self.img1:xy(642,imgY)
			self.img1:size(imgSize2)
		else
			self.list1:size(listSize3)
			self.list1:xy(533,listY3)
			self.img1:xy(645,imgY)
			self.img1:size(imgSize3)
		end
		self.img1:show()
		self.img2:hide()
	else
		if self.showData1:size() == 2 then
			self.list1:xy(364,listY2)
			self.list1:size(listSize2)
			self.list2:xy(710,listY2)

			self.list2:size(listSize2)
			self.img1:size(imgSize2)
			self.img1:xy(472,imgY)
		else
			self.list1:xy(364,listY3)
			self.list1:size(listSize3)
			self.list2:xy(710,listY3)
			self.list2:size(listSize3)
			self.img1:xy(472,imgY)
			self.img1:size(imgSize3)
		end
		self.img1:hide()
		self.img2:visible(getShowData2Size(self.showData2) > 1)
	end
	self[name]:show()
	local i = 0
	for k,v in self.showData2:pairs() do
		local data = v:proxy()
		i = i + 1
		if data.id == nil then
			self[name]:get("red" .. i, "line6"):hide()
			self[name]:get("white" .. i):hide()
		end
	end
end
-- 左侧面板
function CardEvolutionBranchView:switchSpriteSpine(v)
	self.markID = v.cardMarkID
	local unit = csv.unit[v.unitID]
	local size = self.spritePanel:size()
	local childs = self.spritePanel:multiget("name", "attr2", "rarity", "attr1", "cardImg", "bottom")
	childs.bottom:visible(false)
	childs.cardImg:removeAllChildren()
	local sprite2 = widget.addAnimation(childs.cardImg, unit.unitRes, "standby_loop")
	local size = childs.cardImg:size()
	sprite2:xy(size.width / 2, size.height / 7)
		:scale(unit.scale)
	sprite2:setSkin(unit.skin)
	childs.name:text(unit.name)
	childs.name:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	childs.attr2:visible(unit.natureType2 ~= nil)
	if unit.natureType2 then
		childs.attr2:texture(ui.ATTR_ICON[unit.natureType2])
	end
	childs.rarity:texture(ui.RARITY_ICON[unit.rarity])
	childs.attr1:texture(ui.ATTR_ICON[unit.natureType])
	if unit.natureType2 then
		adapt.oneLineCenterPos(cc.p(290, 80), {childs.rarity, childs.name, childs.attr1, childs.attr2}, cc.p(8, 0))
	else
		adapt.oneLineCenterPos(cc.p(290, 80), {childs.rarity, childs.name, childs.attr1}, cc.p(8, 0))
	end
end
-- 确定选择分支
function CardEvolutionBranchView:onSwitch()
	userDefault.setForeverLocalKey("evolutionBranch", {[self.cardId] = self.branch:read()})
	self.params(self.branch:read())
	self:onClose()
end
--分支切换
function CardEvolutionBranchView:onSwitchChange()
	if self.rmb:read() < self.cost then
		uiEasy.showDialog("rmb", nil, {dialog = true})
		return
	end
	for _, v in ipairs(self.item) do
		if v.key == "gold" then
			if v.num > self.gold:read() then
				gGameUI:showTip(gLanguageCsv.goldNotEnough)
				return
			end
		else
			if v.targetNum > v.num then
				gGameUI:showTip(gLanguageCsv.branchItemsNotEnough)
				return
			end
		end
	end
	local function costCb()
		local content = "#C0x5b545b#"..string.format(gLanguageCsv.onSwitchChange1, self.cost)
		if self.cost == 0 then
			content ="#C0x5b545b#"..gLanguageCsv.onSwitchChange2
		end
		gGameUI:showDialog({content = content, cb = function()
			gGameApp:requestServer("/game/card/switch/branch", function(tb)
				if not itertools.isempty(tb.view) then
					gGameUI:showGainDisplay(tb.view)
				end
			end, self.selectDbId, self.branch:read())
			self.oldCurrBranch:set(self.branch:read())
			gGameUI:showTip(gLanguageCsv.succeedSwitchChange)
			self:onClose()
		end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
	end

	local zawakeID = csv.cards[self.cardId].zawakeID
	local zawakeStage, zawakeLevel = zawakeTools.getMaxStageLevel(zawakeID)
	if zawakeStage then
		local name = csv.cards[self.cardId].name
		local stageStr = gLanguageCsv['symbolRome' .. zawakeStage]
		local tip = string.format(gLanguageCsv.zawakeBranchTip, name, stageStr)
		gGameUI:showDialog({content = tip, cb = costCb, btnType = 2, isRich = true})
	else
		costCb()
	end
end
-- 选择分支
function CardEvolutionBranchView:onSelectClick(list, k, v)
	local cards = csv.cards
	local data = self.showData1:atproxy(k)
	if csv.cards[data.id].develop < csv.cards[self.cardId].develop then
		gGameUI:showTip(gLanguageCsv.canNotSwitchChange)
		return
	else
		self.showTab1:set(k)
	end
end

function CardEvolutionBranchView:onList2SelectClick(list,k,v)
	local cards = csv.cards
	local data = self.showData2:atproxy(k)
	if csv.cards[data.id].develop < csv.cards[self.cardId].develop then
		gGameUI:showTip(gLanguageCsv.canNotSwitchChange)
		return
	else
		self.showTab2:set(k)
	end
end

function CardEvolutionBranchView:onItemClick(list, panel, k, v)
	gGameUI:stackUI("common.gain_way", nil, nil, v.key, nil, v.targetNum)
end

return CardEvolutionBranchView