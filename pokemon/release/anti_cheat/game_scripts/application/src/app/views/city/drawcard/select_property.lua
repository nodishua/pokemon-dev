-- @date 2021-6-24
-- @desc 属性选择

local SelectPropertyView = class("SelectPropertyDialog", Dialog)

local freeStr = gLanguageCsv.selfChooseFree
local costStr = gLanguageCsv.selfChooseCost
local totalLeftTimes = gCommonConfigCsv.drawCardUpChangeLimit

local PADDING_WIDTH = 0
local function initItem(node, v)
	for i = 1,5 do
		node:get("icon"..i):hide()
		node:get("circle.img"..i):hide()
	end
	node:get("select"):visible(v.select)

	local function showItem(iconLocation, resLocation)
		node:get("icon"..iconLocation):texture(ui.SKILL_ICON[v.cfg.attrs[resLocation]]):show()
		node:get("circle.img"..iconLocation):texture(ui.SKILL_TEXT_ICON[v.cfg.attrs[resLocation]]):show()
	end

	if table.getn(v.cfg.attrs) == 1 then
		showItem(1, 1)
	elseif table.getn(v.cfg.attrs) == 2 then
		showItem(2, 1)
		showItem(3, 2)
	elseif table.getn(v.cfg.attrs) == 3 then
		showItem(1, 1)
		showItem(4, 2)
		showItem(5, 3)
	end
end

SelectPropertyView.RESOURCE_FILENAME = "drawcard_property_choose.json"
SelectPropertyView.RESOURCE_BINDING = {
	["subList"] = "subList",
	["btnSwitch"] = {
		varname = "btnSwitch",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSwitch")}
		},
	},
	["barBg.text1"] = {
		varname = "specifiTip1",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(241, 62, 87, 255), size = 4}}
		}
	},
	["barBg.text2"] = {
		varname = "specifiTip2",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(241, 62, 87, 255), size = 4}}
		}
	},
	["tipPanel"] = "tipPanel",
	["leftTimes"] = "leftTimes",
	["item"] = "item",
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("showDatas"),
				columnSize = bindHelper.self("midColumnSize"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				leftPadding =0,
				topPadding = 0,
				xMargin = 94,
				yMargin = 0,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					initItem(node,v)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell,node, k, v)}})
				end,
			},
			handlers = {
					clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["previewPanel"] = "previewPanel",
	["previewPanel.list"] = {
		varname = "prelist",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("previewDatas"),
				columnSize = bindHelper.self("previewMidColumnSize"),
				item = bindHelper.self("subList2"),
				cell = bindHelper.self("icon"),
				leftPadding = PADDING_WIDTH,
				topPadding = PADDING_WIDTH,
				xMargin = 50,
				yMargin = 5,
				asyncPreload = 6,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
				end,
			},
		},
	},
	["subList2"] = "subList2",
	["icon"] = "icon",

}

function SelectPropertyView:onCreate(id)
	self.midColumnSize = 2
	self.previewMidColumnSize = 3
	self.showDatas = idlers.new()
	self.previewDatas = idlers.new()
	self.cards = {}
	self.select = id > 0 and id or 1
	self.lastSelect = self.select
	self.currentCost = 0
	self:initModel(self.select)

	self.changeTimes = gGameModel.daily_record:getIdler("draw_card_up_change_times")

	idlereasy.when(self.changeTimes, function(_, changeTimes)
		local costCfg = gCostCsv.draw_card_up_change_cost
		local changeTimes = changeTimes or 0
		local costNum = costCfg[changeTimes + 1] or 100
		self.currentCost = costNum
		local leftTimes
		if (totalLeftTimes - changeTimes) > 0 then
			leftTimes  = totalLeftTimes - changeTimes
		else
			leftTimes = 0
		end
		if leftTimes > 0 then
			self.btnSwitch:setTouchEnabled(true)
			if costNum > 0 then
				self.tipPanel:get("textfree"):hide()
				self.tipPanel:get("cost"):text(costStr..costNum):show()
				self.tipPanel:get("diamond"):show()
			else
				self.tipPanel:get("textfree"):text(freeStr):show()
				self.tipPanel:get("cost"):hide()
				self.tipPanel:get("diamond"):hide()
			end
		else
			self.tipPanel:get("textfree"):hide()
			self.tipPanel:get("cost"):hide()
			self.tipPanel:get("diamond"):hide()
			self.btnSwitch:setTouchEnabled(false)
			cache.setShader(self.btnSwitch, false, "hsl_gray")
		end
		self.leftTimes:get("num"):text(leftTimes .."/"..totalLeftTimes)
	end)
end

function SelectPropertyView:initModel(selectNum)
	local data = {}
	for k,v in csvMapPairs(csv.draw_card_up_group) do
		table.insert(data, {id = k, cfg = v, select = selectNum == k})
	end

	table.sort(data,function (a, b)
		return a.id < b.id
	end)
	self.showDatas:update(data)
end

function SelectPropertyView:onItemClick(list, node, k, v)
	self.select = v.id
	if gGameUI.itemDetailView then
		gGameUI.itemDetailView:onClose()
	end
	local name = "city.drawcard.select_property_detail"
	local canvasDir = "vertical"
	local childsName = {"previewPanel"}
	local dir = v.id % 2 == 0 and "right" or "left"
	local view = tip.create(name, nil, {relativeNode = node, canvasDir = canvasDir, childsName = childsName, dir = dir}, v.cfg.cards)
	view:onNodeEvent("exit", functools.partial(gGameUI.unModal, gGameUI, view))
	gGameUI:doModal(view)
	gGameUI.itemDetailView = view
	self:initModel(v.id)
end

function SelectPropertyView:onSwitch()
	if self.lastSelect ==  self.select then
		gGameUI:showTip(gLanguageCsv.sameAttributeSwitch)
		return
	end
	if gGameModel.role:read("rmb") < self.currentCost then
		uiEasy.showDialog("rmb")
		return
	end
	local function request()
			gGameApp:requestServer("/game/lottery/card/up/choose", function(tb)
			self:onClose()
		end, self.select)
	end

	if self.currentCost > 0 then
		gGameUI:showDialog{ content = string.format(gLanguageCsv.costDiamondToSwitch,self.currentCost),
							cb = function ()
								request()
							end,
							btnType = 2,
							clearFast = true,
							dialogParams = {clickClose = false},
							isRich = true
						}
	else
		request()
	end
end


return SelectPropertyView