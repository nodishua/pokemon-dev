-- @date:   2020-07-16
-- @desc:   跨服竞技场七日信息

local CrossArenaSevenInfoView = class("CrossArenaSevenInfoView", cc.load("mvc").ViewBase)

CrossArenaSevenInfoView.RESOURCE_FILENAME = "cross_arena_info.json"
CrossArenaSevenInfoView.RESOURCE_BINDING = {
	["sevenPanel"] = "sevenPanel",
	["sevenPanel.txt"] = "txt",
	["sevenPanel.textNode"] = "textNode",
	["sevenPanel.textTime"] = {
		varname = "textTime",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
}

function CrossArenaSevenInfoView:onCreate()
	self:initModel()

	local endTime = time.getNumTimestamp(self.date:read()) + 6 * 24 * 60 * 60 + 22 * 60 * 60
	local t = time.getDate(endTime)
	self.textNode:text(string.format(gLanguageCsv.sevenNode, tonumber(t.month), tonumber(t.day)))

	local function setLabel()
		if endTime - time.getTime() >= 0 then
			local remainTime = time.getCutDown(endTime - time.getTime())
			self.textTime:text(remainTime.str)
		else
			self.textTime:text(gLanguageCsv.sevenEnd)
			local positionX = matchLanguage({"en"}) and (self.textTime:x() - 90) or (self.textTime:x() - 40)
			self.textTime:x(positionX)
			self.txt:hide()
			return false
		end
		return true
	end

	setLabel()
	self:enableSchedule()
	self:schedule(function(dt)
		if not setLabel() then
			return false
		end
	end, 1, 0)
end

function CrossArenaSevenInfoView:initModel()
	self.date = gGameModel.cross_arena:getIdler("date")
end

return CrossArenaSevenInfoView