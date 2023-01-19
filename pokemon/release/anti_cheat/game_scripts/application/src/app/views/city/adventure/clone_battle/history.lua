-- @date:   2019-9-23
-- @desc:   变更记录

local ViewBase = cc.load("mvc").ViewBase
local HistoryView = class("HistoryView", Dialog)

HistoryView.RESOURCE_FILENAME = "clone_battle_history.json"
HistoryView.RESOURCE_BINDING = {
	["showPanel.list"] = "list",
	["title"] = "title",
	["showPanel.item"] = "item",
	["allPanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
}

local TIP = {
	[1] = gLanguageCsv.cloneBattleRecord1, 	--该房间被创建
	[2] = gLanguageCsv.cloneBattleRecord2,	--%s加入房间
	[3] = gLanguageCsv.cloneBattleRecord3,	--%s完成本场挑战
	[4] = gLanguageCsv.cloneBattleRecord4,	--%s被请出出房间
	[5] = gLanguageCsv.cloneBattleRecord5,	--%s发起投票是否将%s请出
	[6] = gLanguageCsv.cloneBattleRecord6,	--因投票失败，玩家%s仍然留在房间
	[7] = gLanguageCsv.cloneBattleRecord7,  --因%s完成一次战斗，%s不被踢出
}

function HistoryView:onCreate(parms)
	--从变更中退出来之后刷新红点
	-- parms.refreshNumber:set(1)
	Dialog.onCreate(self)
	local index = gGameModel.forever_dispatch:getIdlerOrigin("cloneBattleLookHistory"):read()
	gGameModel.forever_dispatch:getIdlerOrigin("cloneBattleLookHistory"):set(index + 1)
	self.list:setScrollBarEnabled(false)
	self.list:setItemsMargin(0)
	local history = parms.historyTab or {}
	--从变更中退出来之后刷新红点
	self.refreshNumber = parms.refreshNumber
	userDefault.setForeverLocalKey("cloneBattleHistory", history, {new = true})

	local dateRecord = {}
	for i, v in ipairs(history) do
		local t = time.getDate(v.time)
		local str = string.formatex(gLanguageCsv.timeMonthDay, {month = t.month, day = t.day})
		dateRecord[str] = dateRecord[str] or {}
		table.insert(dateRecord[str],v)
	end

	for date, data in pairs(dateRecord) do
		local item = self.item:clone()
		local richText = rich.createByStr("#Pfont/youmi1.ttf##C0x5B545B#" .. date, 40)
			:addTo(item)
			:anchorPoint(0,0.5)
			:xy(10,32)
			:height(45)
		self.list:pushBackCustomItem(item)
		local str1 = ""
		for i, v in ipairs(data) do
			local item = self.item:clone()
			local t = time.getDate(v.time)
			local time = "#C0xB2ABB2##Pfont/youmi1.ttf#" ..string.format("%02d:%02d", t.hour, t.min)
			local str = string.formatex("#C0x5B545B#"..TIP[v.type], {name = "#C0x5FC355#".. v.name .."#C0x5B545B#"})

			local richTime= rich.createByStr(time, 40)
				:addTo(item)
				:anchorPoint(0,1)
				:xy(160,32)

			local richText = rich.createWithWidth(str, 40, nil, 730)
				:addTo(item)
				:anchorPoint(0,1)
				:xy(280,32)
			local height = richText:height()
			item:height(height)
			richTime:xy(160,height)
			richText:xy(280,height)
			self.list:pushBackCustomItem(item)
		end
	end
	self.list:jumpToBottom()
end

return HistoryView