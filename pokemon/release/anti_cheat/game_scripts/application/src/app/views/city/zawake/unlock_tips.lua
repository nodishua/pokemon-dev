-- @date:   2021-04-19
-- @desc:   z觉醒阶段解锁条件界面

-- local zawakeTools = require "app.views.city.zawake.tools"
local MINHEIGHT = 380
local MAXHEIGHT = 900

local ViewBase = cc.load("mvc").ViewBase
local ZawakeUnlockTipsView = class("ZawakeUnlockTipsView", ViewBase)
ZawakeUnlockTipsView.RESOURCE_FILENAME = "zawake_unlock_tips.json"
ZawakeUnlockTipsView.RESOURCE_BINDING = {
	["closePanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["item"] = "item",
	["panel"] = "panel",
	["panel.bg"] = "bg",
	["panel.title"] = "title",
	["panel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("listDatas"),
				listHeight = bindHelper.self("listHeight"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local rich = rich.createWithWidth(v, 42, nil, 920)
						:anchorPoint(0, 0.5)
						:x(0)
						:addTo(node)
					local height = rich:size().height + 6
					node:height(math.ceil(height/72) * 72)
					rich:y(node:height()/2)
					list.listHeight:set(list.listHeight:read() + node:height())
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
}

function ZawakeUnlockTipsView:onCreate(params)
	local datas = params.labelDatas
	local align = params.align or "center"
	local stageID = params.stageID
	local pos = params.pos
	local panelWidth = self.panel:width()
	local maxPosX = display.sizeInViewRect.width - panelWidth
	local posX = math.min(display.sizeInViewRect.width/2 - panelWidth/2, maxPosX)
	if align == "right" then
		posX = maxPosX - 1000
	elseif align == "left" then
		posX = maxPosX - 700
	end
	if pos then
		if align == "right" then
			posX = pos.x
		elseif align == "left" then
			posX = pos.x - panelWidth
		end
	end

	self.panel:x(posX)
	self.listHeight = idler.new(0)
	self.listDatas = idlers.newWithMap(datas)
	self.title:text(string.format(params.title or gLanguageCsv.zawakeStageAwake, gLanguageCsv['symbolRome'..stageID]))
end

function ZawakeUnlockTipsView:onAfterBuild()
	local height = cc.clampf(self.listHeight:read(), MINHEIGHT, MAXHEIGHT)
	self.list:height(height)
	self.bg:height(height + 170)
	self.title:y(height + 80)
	self.panel:y((1440 - 180 - height)/2)
end

return ZawakeUnlockTipsView