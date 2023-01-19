-- @date:   2019-10-24
-- @desc:   随机塔-事件奖励

local ViewBase = cc.load("mvc").ViewBase
local RandomTowerEventRewardView = class("RandomTowerEventRewardView", ViewBase)

RandomTowerEventRewardView.RESOURCE_FILENAME = "random_tower_event_reward.json"
RandomTowerEventRewardView.RESOURCE_BINDING = {
	["item"] = "item",
	["list"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("eventDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("itemPanel", "textName")
					local cfg = csv.items[dataEasy.stringMapingID(v.key)]
					childs.textName:text(cfg.name)
					local isDouble = false
					if v.key == "gold" then -- 随机塔的金币双倍活动
						isDouble = dataEasy.isDoubleHuodong("randomGold")
					end
					local binds = {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
							isDouble = isDouble,
						},
					}
					bind.extend(list, childs.itemPanel, binds)
				end,
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
			},
		},
	},
	["textTitle"] = "textTitle",
	["pos"] = "pos",
}

function RandomTowerEventRewardView:onCreate(params)
	self.cb = params.cb
	local cfg = csv.random_tower.event[params.eventId]
	local data = dataEasy.mergeRawDate(params.tb.view.items or {})
	if params.tb.view.points then
		table.insert(data, {key = 417, num = params.tb.view.points})
	end
	local posY = #data > 0 and 180 or 0
	--默认选则第一个
	local choiceID = params.choiceID or 1
	local str = cfg["resultDesc"..choiceID]
	local richText = rich.createByStr(str, 50)
	richText:formatText()
	if richText:size().width > 1400 then
		richText = rich.createWithWidth(str, 50, nil, 1400)
	end
	richText:anchorPoint(cc.p(0.5, 0.5))
		:addTo(self.pos)
		:xy(0, posY)
	self.textTitle:text(cfg.name)

	self.eventDatas = data
end

function RandomTowerEventRewardView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end
return RandomTowerEventRewardView
