-- @date:   2019-10-12
-- @desc:   随机塔-打开宝箱


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

local randomTowerTools = require "app.views.city.adventure.random_tower.tools"
local ViewBase = cc.load("mvc").ViewBase
local RandomTowerOpenBoxView = class("RandomTowerOpenBoxView", ViewBase)

RandomTowerOpenBoxView.RESOURCE_FILENAME = "random_tower_open_box.json"
RandomTowerOpenBoxView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
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

function RandomTowerOpenBoxView:onCreate(boardID, cb)
	self.boardID = boardID
	self.cb = cb
	self:initModel()
	local cfg = csv.random_tower.board[boardID]
	-- 开启宝箱次数限制 加上1次免费次数
	self.boxLimit = gCommonConfigCsv["randomTowerBoxLimit"..cfg.boxType] + 1
	self.boxType = cfg.boxType
	randomTowerTools.setEffect(self.titlePos, TITLE[cfg.boxType], "random_tower/baoxiang.skel", 770)
	randomTowerTools.setEffect(self.boxPos, BOX[cfg.boxType], "random_tower/baoxiang.skel", 240)
	idlereasy.any({self.roomInfo, self.rmb}, function(_, roomInfo, rmb)
		local count = roomInfo.count or 0
		--没有boardId说明领完了
		if not roomInfo.board_id then
			count = self.boxLimit
		end
		local costIndex = math.min(count + 1, self.boxLimit)
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
		local costCfg = gCostCsv["random_tower_box_cost"..cfg.boxType]
		self.rmbCost = costCfg[math.min(costIndex, table.length(costCfg))]
		self.textCost:text(self.rmbCost)
		local coinColor = ui.COLORS.NORMAL.ALERT_YELLOW
		if rmb >= self.rmbCost then
			coinColor = ui.COLORS.NORMAL.WHITE
		end
		self.textFree:visible(costIndex == 1 and cfg.boxType == 2)
		itertools.invoke({self.textNote, self.textCost, self.imgCost}, (costIndex == 1 or count == self.boxLimit) and "hide" or "show")
		text.addEffect(self.textCost, {color = coinColor})
		adapt.oneLineCenterPos(cc.p(self.btnOpen:x(), self.textCost:y()), {self.textNote, self.textCost, self.imgCost}, cc.p(15, 0))
	end)
end

function RandomTowerOpenBoxView:initModel()
	self.roomInfo = gGameModel.random_tower:getIdler("room_info")
	self.rmb = gGameModel.role:getIdler("rmb")

end
--打开宝箱
function RandomTowerOpenBoxView:onBtnOpen()
	--防止多次点击
	if self.notClick == true then
		return
	end
	local count = self.roomInfo:read().count
	if self.rmbCost > self.rmb:read() and count and count > 0 then
		uiEasy.showDialog("rmb")
		return
	end
	local function cb()
		self.notClick = true
		gGameApp:requestServer("/game/random_tower/box/open",function (tb)
			randomTowerTools.setEffect(self.boxPos, OPEN_BOX[self.boxType], "random_tower/baoxiang.skel", 240)
			performWithDelay(self.boxPos, function()
				gGameUI:showGainDisplay(tb, {
				onlyGoldDouble = dataEasy.isDoubleHuodong("randomGold"),
				cb = function()
					self.notClick = false
					--最后一次开启后 自动关闭界面
					if (count and count >= self.boxLimit - 1) or not self.roomInfo:read().board_id then
						self:addCallbackOnExit(self.cb)
						ViewBase.onClose(self)
						return
					end
					randomTowerTools.setEffect(self.boxPos, BOX[self.boxType], "random_tower/baoxiang.skel", 240)
				end})
			end, 1)
		end)
	end
	if count and count > 0 then
		dataEasy.sureUsingDiamonds(cb, self.rmbCost)
	else
		cb()
	end
end
function RandomTowerOpenBoxView:onClose()
	if self.notClick == true then
		return
	end
	ViewBase.onClose(self)
end
--跳过
function RandomTowerOpenBoxView:onBtnNext()
	if self.notClick == true then
		return
	end
	gGameApp:requestServer("/game/random_tower/next",function (tb)
		self:addCallbackOnExit(self.cb)
		ViewBase.onClose(self)
	end)
end
return RandomTowerOpenBoxView
