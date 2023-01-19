-- @date:   2019-10-12
-- @desc:   随机塔-选择事件

local ViewBase = cc.load("mvc").ViewBase
local RandomTowerSelectEventView = class("RandomTowerSelectEventView", ViewBase)

RandomTowerSelectEventView.RESOURCE_FILENAME = "random_tower_select_event.json"
RandomTowerSelectEventView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["item"] = "item",
	["list"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("eventDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("textOrder", "textDesc")
					childs.textOrder:text(k)
					childs.textDesc:text(v.name)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["textTitle"] = "textTitle",
}

function RandomTowerSelectEventView:onCreate(boardID, cb, eventId)
	self.cb = cb
	self.boardID = boardID
	self:initModel()
	if eventId then
		self.type = "jump"
		self.eventId = eventId
	else
		self.type = "common"
		self.eventId = self.roomInfo:read().event[boardID]
	end

	local cfg = csv.random_tower.event[self.eventId]
	self.textTitle:text(cfg.desc)
	if matchLanguage({"kr", "en"}) then
		self.textTitle:x(display.sizeInView.width/2)
    	adapt.setTextAdaptWithSize(self.textTitle, {size = cc.size(1900, 150)})
	end
	local eventDatas = {}
	for i=1,3 do
		local name = cfg["choice"..i]
		if cfg["choice"..i] ~= "" then
			table.insert(eventDatas, {
				key = i,
				name = name
			})
		end
	end
	self.eventDatas = eventDatas
end

function RandomTowerSelectEventView:initModel()
	self.roomInfo = gGameModel.random_tower:getIdler("room_info")
end

function RandomTowerSelectEventView:onItemClick(event, k, v)
	if self.type == "jump" then
		local showOver = {false}
		gGameApp:requestServerCustom("/game/random_tower/jump/event")
			:params(self.boardID, "choice"..v.key)
			:onResponse(function (tb)
				showOver[1] = true
			end)
			:wait(showOver)
			:doit(function(tb)
				local eventId = self.eventId
				ViewBase.onClose(self)
				gGameUI:stackUI("city.adventure.random_tower.event_reward", nil, {clickClose = true}, {
					eventId = eventId,
					tb = tb,
					choiceID = v.key,
					cb = function() end
				})
			end)
	else
		local showOver = {false}
		gGameApp:requestServerCustom("/game/random_tower/event/choose")
			:params("choice"..v.key)
			:onResponse(function (tb)
				showOver[1] = true
			end)
			:wait(showOver)
			:doit(function(tb)
				local eventId = self.eventId
				local cb = self.cb
				ViewBase.onClose(self)
				gGameUI:stackUI("city.adventure.random_tower.event_reward", nil, {clickClose = true}, {
					eventId = eventId,
					tb = tb,
					choiceID = v.key,
					cb = cb
				})
			end)
	end
end
return RandomTowerSelectEventView
