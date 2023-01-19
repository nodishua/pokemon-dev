local ViewBase = cc.load("mvc").ViewBase
local ExploreDetailView = class("ExploreDetailView", Dialog)
local ExplorerTools = require "app.views.city.develop.explorer.tools"
ExploreDetailView.RESOURCE_FILENAME = "explore_detail_view.json"
ExploreDetailView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["title1"] = "title1",
	["pos"] = "pos",
	["name"] = "nodeName",
	["right"] = "rightName",
	["left"] = "leftName",
	["arrow"] = "arrow",
	["leftList"] = "leftList",
	["rightList"] = "rightList",
	["item1"] = "item1",
	["bottomList"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("upgradeData"),
				dataOrderCmp = dataEasy.sortItemCmp,
				margin = 20,
				padding = 20,
				item = bindHelper.self("item1"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("add", "mask")
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = v.num,
								targetNum = v.targetNum
							},
							grayState = v.targetNum > v.num and 3 or 0,
							onNode = function (node)
								if v.targetNum > v.num then
									bind.click(list, node, {method =  functools.partial(list.clickCell, k, v)})
								end
							end
						},
					})
					childs.mask:hide()
					childs.add:visible(v.targetNum > v.num)
				end,
				onAfterBuild = function(list)
					list:setClippingEnabled(false)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemMaskClick"),
			},
		},
	},
	["activeTip"] = "activeTip",
	["btn"] = {
		varname = "btn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnClick")}
		}
	},
	["btn.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},

}

function ExploreDetailView:onCreate(dbHandler)
	self:initModel()
	self.detailSendParams = dbHandler
	self.data = dbHandler()
	self.minLevel = ExplorerTools.getMinComponentLevel(self.data.components)
	self.nodeName:text(self.data.cfg.name)
	text.addEffect(self.nodeName, {color = ui.COLORS.QUALITY[self.data.cfg.quality]})

	if self.data.advance == 0 then
		self.title1:text(gLanguageCsv.active)
		self.leftName:text(gLanguageCsv.notActivatedTip)
		self.rightName:text("+1")
		text.addEffect(self.leftName, {color = ui.COLORS.NORMAL.GRAY})
		self.activeTip:visible(self.minLevel == 0)
		self.btn:get("title"):text(gLanguageCsv.spaceActive)
		self.activeTip:text(gLanguageCsv.collectAllComponentsCanActive)
	else
		text.addEffect(self.leftName, {color = ui.COLORS.NORMAL.DEFAULT})
		self.leftName:text("+"..self.data.advance)
		self.leftName:setFontSize(60)
		self.rightName:text("+"..self.data.advance + 1)
		self.btn:get("title"):text(gLanguageCsv.spaceAdvance)
		local isShow = false
		if self.data.advance >= self.minLevel then
			self.activeTip:text(string.format(gLanguageCsv.allComponentsNeedLevelCondition, self.data.advance + 1))
			isShow = true
		end
		self.activeTip:visible(isShow)
		self.title1:text(gLanguageCsv.talentAdvance)
	end
	adapt.setTextAdaptWithSize(self.activeTip, {size = cc.size(550, 200), vertical = "center", horizontal = "center", margin = -8})
	if matchLanguage({"cn", "tw"}) then
		adapt.oneLinePos(self.nodeName, {self.leftName, self.arrow, self.rightName}, {cc.p(10, 0)})
	else
		self.nodeName:y(self.nodeName:y() + 60)
		self.leftName:x(self.nodeName:x())
		adapt.oneLinePos(self.leftName, {self.arrow, self.rightName}, {cc.p(10, 0)})
	end

	if string.find(self.data.cfg.res, "skel") then
		local spine = widget.addAnimationByKey(self.pos, self.data.cfg.res, "explorer", "effect_loop", 1011)
		spine:xy(300, 100)
			:scale(2)
	else
		local imgBG = ccui.ImageView:create(self.data.cfg.res)
			:alignCenter(self.pos:size())
			:addTo(self.pos, 1)
	end
	ExplorerTools.effectShow(self.leftList, self.rightList, self.data)
	local t = {}
	self.isCanUp = true
	for k, v in csvMapPairs(csv.explorer.explorer_advance[self.data.advance + 1]["costItemMap"..self.data.cfg.advanceCostSeq]) do
		table.insert(t, {id = k, targetNum = v, num = dataEasy.getNumByKey(k)})
		if self.isCanUp then
			self.isCanUp = dataEasy.getNumByKey(k) >= v
		end
	end
	self.upgradeData = idlertable.new(t)
	Dialog.onCreate(self)
end

function ExploreDetailView:initModel()
	self.items = gGameModel.role:getIdler("items")
	self.coin4 = gGameModel.role:getIdler("coin4")
end


function ExploreDetailView:sendParams()
	return self.data
end

function ExploreDetailView:onBtnClick()
	if self.data.advance >= self.minLevel then
		gGameUI:showTip(gLanguageCsv.oneOrMoreNotReachCondition)
		return
	end
	if not self.isCanUp then
		gGameUI:showTip(gLanguageCsv.inadequateProps)
		return
	end

	gGameApp:requestServer("/game/explorer/advance",function (tb)
		local detailSendParams = self.detailSendParams()
		ViewBase.onClose(self)
		gGameUI:stackUI("city.develop.explorer.success", nil, nil, detailSendParams)
	end, self.data.id)
end

function ExploreDetailView:onItemMaskClick(list, k, v)
	gGameUI:stackUI("common.gain_way", nil, {dialog = true}, v.id, nil, v.targetNum)
end

return ExploreDetailView
