-- @Date:   2018-12-21
-- @Desc:
-- @Last Modified time: 2019-05-10

local function setBranchData(data)
	local showData1 = {}
	local showData2 = {}
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
	return showData1, showData2
end

local CardEvolutionChangeShapeView = class("CardEvolutionChangeShapeView", Dialog)
CardEvolutionChangeShapeView.RESOURCE_FILENAME = "card_change_shape.json"
CardEvolutionChangeShapeView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["changeBtn"] = {
		varname = "changeBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSwitchChange")}
		}
	},
	["txt"] = "txt",
	["txtNum"] = "txtNum",
	["icon"] = "icon",
	["item"] = "item1",
	["item1"] = "item2",
	["nowIcon"] = "nowIcon1",
	["nowIcon1"] = "nowIcon2",
	["title1"] = "title1",
}

function CardEvolutionChangeShapeView:onCreate(params)
	self.params = params
	local develop, data, branch, selectDbId, oldCurrBranch= params()
	self.oldCurrBranch = oldCurrBranch
	self.selectDbId = selectDbId
	--想要切换到的分支
	self.changeBranch = branch == 2 and 1 or 2
	self.cost = 0
	self.branch = branch == 0 and 1 or branch
	self.nowBranch = 1
	self:initModel()
	userDefault.setForeverLocalKey("evolutionBranch", {[self.cardId:read()] = self.branch})
	self.params(self.branch)
	local csvCards = csv.cards
	local developType = csvCards[self.cardId:read()].developType
	local developData = {}
	local showData1, showData2 = setBranchData(data)
	local cardCfg = csvCards[showData1[self.branch].id]
	local cardCfg1 = csvCards[showData1[self.changeBranch].id]
	self.develop = develop
	self.nextDevelop = cardCfg.develop
	if self.develop ~= self.nextDevelop then
		cardCfg = csvCards[showData1[1].id]
		cardCfg1 = csvCards[showData1[2].id]
		self.nowBranch = self.branch
		self.title1:text(gLanguageCsv.qualityExchangeFragmentTitle3)
	end
	self:switchSpriteSpine(cardCfg, 1)
	self:switchSpriteSpine(cardCfg1, 2)
	--开始时的cardId
	local oldCardId = self.cardId:read()

	idlereasy.any({self.switchTimes, self.oldCurrBranch, self.cardId}, function (_, switchTimes, oldCurrBranch, cardId)
		if cardId ~= oldCardId then
			oldCardId = cardId
			gGameUI:showTip(gLanguageCsv.succeedSwitchChangeShape)
			self.nowBranch = self.nowBranch == 1 and 2 or 1
			self.oldCurrBranch:set(self.changeBranch)
			self.changeBranch = self.changeBranch == 1 and 2 or 1
		end

		if self.nowBranch == 1 then
			self.nowIcon1:show()
			self.nowIcon2:hide()
			self.item1:get("bottomShow"):show()
			self.item1:get("bottomHide"):hide()
			self.item2:get("bottomHide"):show()
			self.item2:get("bottomShow"):hide()
		else
			self.nowIcon2:show()
			self.nowIcon1:hide()
			self.item2:get("bottomShow"):show()
			self.item2:get("bottomHide"):hide()
			self.item1:get("bottomHide"):show()
			self.item1:get("bottomShow"):hide()
		end
		local csvBranch = csv.cards_branch_cost
		for k, v in orderCsvPairs(csvBranch) do
			if v.developType == developType then
				local tmp = 0
				for _, _ in csvPairs(v.cost) do
					tmp = tmp + 1
				end
				tmp = math.min(switchTimes + 1, tmp)
				self.cost = v.cost[tmp].rmb or 0
				developData = dataEasy.getItemData(v.cost[tmp])
			end
		end
		self.txtNum:text(self.cost)
		if self.cost == 0 or self.develop ~= self.nextDevelop then
			self.cost = 0
			self.txt:hide()
			self.txtNum:hide()
			self.icon:hide()
		else
			self.txt:show()
			self.txtNum:show()
			self.icon:show()
		end
		adapt.oneLineCenterPos(cc.p(1285 + display.uiOrigin.x, 536), {self.txt, self.txtNum, self.icon}, cc.p(15, 0))
	end)

	--消耗通用
	idlereasy.when(self.rmb, function(_, rmb)
		local color = rmb < self.cost and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.DEFAULT
		text.addEffect(self.txtNum, {color=color})
	end)
	-- 精灵底座
	-- self:setBottomSpine()
	self:iconFloat(self.nowIcon1)
	self:iconFloat(self.nowIcon2)
	Dialog.onCreate(self)
end

function CardEvolutionChangeShapeView:initModel()
	local card = gGameModel.cards:find(self.selectDbId)
	self.cardId = card:getIdler("card_id")
	self.switchTimes = card:getIdler("branch_switch_times")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
end

function CardEvolutionChangeShapeView:iconFloat(node)
	local x, y = node:xy() --822, 1020
	local rangeHighY = y + 10
	local rangeLowY = y - 10
	local space = 0.2
	self:enableSchedule():schedule(function()
		y = y + space
		if y >= 1030 then
			space = -0.2
		elseif y <= 1010 then
			space = 0.2
		end
		node:y(y)
	end, 1/60, 0, "controlIconFloat"..x)
end

-- 精灵底座
function CardEvolutionChangeShapeView:setBottomSpine()
	local size = self.item:size()
	local eff1 = CSprite.new("effect/jinhuajiemian.skel")
	eff1:xy(size.width / 2 - 40, size.height / 4 - 15)
	eff1:play("effect_down2_loop")
	eff1:addTo(self.item, 4, "effect1")
	local eff2 = CSprite.new("effect/jinhuajiemian.skel")
	eff2:xy(size.width / 2 - 40, size.height / 4 - 15)
	eff2:play("effect_up_loop")
	eff2:addTo(self.item, 7, "effect2")
end

-- 左侧面板
function CardEvolutionChangeShapeView:switchSpriteSpine(v, index)
	self.markID = v.cardMarkID
	local unit = csv.unit[v.unitID]
	local item = self["item"..index]

	local size = item:size()

	local childs = item:multiget("name", "attr2", "rarity", "attr1", "cardImg")
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
		adapt.oneLineCenterPos(cc.p(290, 75), {childs.rarity, childs.name, childs.attr1, childs.attr2}, cc.p(8, 0))
	else
		adapt.oneLineCenterPos(cc.p(290, 75), {childs.rarity, childs.name, childs.attr1}, cc.p(8, 0))
	end
end

--分支切换
function CardEvolutionChangeShapeView:onSwitchChange()
	if self.rmb:read() < self.cost then
		uiEasy.showDialog("rmb", nil, {dialog = true})
		return
	end
	local content = "#C0x5b545b#"..string.format(gLanguageCsv.onSwitchChangeShape, self.cost)
	if self.cost == 0 then
		content ="#C0x5b545b#"..gLanguageCsv.onSwitchChangeShape1
	end
	if self.develop == self.nextDevelop then
		gGameUI:showDialog({content = content, cb = function()
			gGameApp:requestServer("/game/card/switch/branch", function(tb)
				if not itertools.isempty(tb.view) then
					gGameUI:showGainDisplay(tb.view)
				end
			end, self.selectDbId, self.changeBranch)
		end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
	else
		userDefault.setForeverLocalKey("evolutionBranch", {[self.cardId:read()] = self.changeBranch})
		self.nowBranch = self.nowBranch == 1 and 2 or 1
		self.params(self.changeBranch)
		gGameUI:showTip(gLanguageCsv.succeedChanceChangeShape)
		self.changeBranch = self.changeBranch == 1 and 2 or 1
	end
end

return CardEvolutionChangeShapeView