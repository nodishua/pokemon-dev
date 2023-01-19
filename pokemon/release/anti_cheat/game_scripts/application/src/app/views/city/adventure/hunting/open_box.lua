-- @date:   2021-05-10
-- @desc:   狩猎地带-打开宝箱


local TITLE = {
	"baoxiangzi_loop",
	"haohuabaoxiangzi_loop"
}
local BOX = {
	"baoxiang_loop",
	"haohuabaoxiang_loop"
}
local OPEN_BOX = {
	"baoxiangkaixiang",
	"haohuabaoxiangkaixiang"
}

local function setEffect(parent, effectName, spineName, offy)
	local spineName = not spineName and "random_tower/baox.skel" or spineName
	local offy = offy or 0
	local effect = parent:get("effect")
	if not effect then
		widget.addAnimationByKey(parent, spineName, "effect", effectName, 0)
			:xy(parent:width()/2, parent:height()/2 - offy)
			:scale(2)
	else
		effect:play(effectName)
	end
end

local ViewBase = cc.load("mvc").ViewBase
local HuntingOpenBoxView = class("HuntingOpenBoxView", ViewBase)

HuntingOpenBoxView.RESOURCE_FILENAME = "hunting_open_box.json"
HuntingOpenBoxView.RESOURCE_BINDING = {
	["btnNext"] = {
		varname = "btnNext",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnNext")},
		},
	},
	["btnOpen"] = {
		varname = "btnOpen",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnOpen")},
		},
	},
	["textFree"] = "textFree",
	["textNote"] = "textNote",
	["textCost"] = "textCost",
	["imgCost"] = "imgCost",
	["textOpenTimes"] = "textOpenTimes",
	["titlePos"] = "titlePos",
	["boxPos"] = "boxPos"
}

function HuntingOpenBoxView:onCreate(route, node, cb)
	self.cb = cb
	self.route = route
	self.node = node
	self:initModel()
	self.boxLimit = csv.cross.hunting.base[route].boxOpenLimit
	setEffect(self.titlePos, "haohuabaoxiangzi_loop", "random_tower/baox.skel", 770)
	setEffect(self.boxPos, "haohuabaoxiang_loop", "random_tower/baox.skel", 240)
	idlereasy.any({self.boxInfo, self.rmb}, function(_, boxInfo, rmb)
		local count = boxInfo[self.route].box_open_count or 0
		local routeCfg = csv.cross.hunting.route
		local costIndex = math.min(count + 1, self.boxLimit)
		if boxInfo[self.route].node ~= node then
			count = self.boxLimit
		end
		--开启次数
		local timesColor = "#C0xAEE97E#"
		if count >= self.boxLimit then
			timesColor = "#C0xECB72A#"
		end
		uiEasy.setBtnShader(self.btnNext, self.btnNext:get("textNote"), count ~= 0 and 1 or 2)
		self.textOpenTimes:text(""):removeAllChildren()
		local subTimes = self.boxLimit - count
		rich.createByStr(string.format(gLanguageCsv.canOpenTimes, timesColor..subTimes.."#C0xFFFCED#", self.boxLimit), 36)
			:anchorPoint(0.5, 0.5)
			:addTo(self.textOpenTimes, 6)

		--砖石花费
		local costCfg = gCostCsv["hunting_box_cost"]
		self.rmbCost = costCfg[math.min(math.max(costIndex - 1, 1), table.length(costCfg))]
		self.textCost:text(self.rmbCost)
		local coinColor = ui.COLORS.NORMAL.ALERT_YELLOW
		if rmb >= self.rmbCost then
			coinColor = ui.COLORS.NORMAL.WHITE
		end
		self.textFree:visible(costIndex == 1 and routeCfg[boxInfo[self.route].node].type == 2)
		itertools.invoke({self.textNote, self.textCost, self.imgCost}, (costIndex == 1 or count == self.boxLimit) and "hide" or "show")
		text.addEffect(self.textCost, {color = coinColor})
		adapt.oneLineCenterPos(cc.p(self.btnOpen:x(), self.textCost:y()), {self.textNote, self.textCost, self.imgCost}, cc.p(15, 0))
	end)
end

function HuntingOpenBoxView:initModel()
	self.boxInfo = gGameModel.hunting:getIdler("hunting_route")
	self.rmb = gGameModel.role:getIdler("rmb")
end
--打开宝箱
function HuntingOpenBoxView:onBtnOpen()
	--防止多次点击
	local count = self.boxInfo:read()[self.route].box_open_count
	if self.rmbCost > self.rmb:read() and count and count > 0 then
		uiEasy.showDialog("rmb")
		return
	end
	local function cb()
		local showOver = {false}
		gGameApp:requestServerCustom("/game/hunting/box/open")
			:params(self.route, self.node)
			:onResponse(function(tb)
				setEffect(self.boxPos, "haohuabaoxiangkaixiang", "random_tower/baox.skel", 240)
				performWithDelay(self.boxPos, function()
					showOver[1] = true
					gGameUI:showGainDisplay(tb, {
						cb = function()
							--最后一次开启后 自动关闭界面
							if (count and count >= self.boxLimit - 1) or not self.boxInfo:read() then
								self:onClose()
								return
							end
							setEffect(self.boxPos, "haohuabaoxiang_loop", "random_tower/baox.skel", 240)
						end
					})
				end, 1)
			end)
			:wait(showOver)
			:doit(function (tb)
			end)
	end
	if count and count > 0 then
		dataEasy.sureUsingDiamonds(cb, self.rmbCost)
	else
		cb()
	end
end
function HuntingOpenBoxView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end
--跳过
function HuntingOpenBoxView:onBtnNext()
	gGameApp:requestServer("/game/hunting/next",function (tb)
		self:onClose()
	end, self.route)
end
return HuntingOpenBoxView
