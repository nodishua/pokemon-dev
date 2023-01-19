-- @date 2020-8-31
-- @desc 训练家重聚 相逢有时

-- 礼包类型(1重聚礼包;2相逢有时)
local STATE_TYPE_GIFT =
{
	gift = 1,
	reunion = 2,
}

-- 未领取 (不可领取)，可领取，已领取
local STATE_TYPE = {
	noReach = 0,
	canReceive = 1,
	received = 2,
}

-- 回归玩家-1，老玩家-2
local STATE_ROLE_TYPE = {
	reunion = 1,
	senior = 2,
}

local viewName = {
	["bindPlayer"] = "city.activity.reunion.bind_player",
	["task"] = "city.activity.reunion.task",
}

local ReunionReunionView = class("ReunionReunionView", cc.load("mvc").ViewBase)

ReunionReunionView.RESOURCE_FILENAME = "reunion_reunion_base.json"
ReunionReunionView.RESOURCE_BINDING = {
}

function ReunionReunionView:onCreate(yyID, param)
	local cfg = csv.yunying.yyhuodong[yyID]
	self:initModel()
	local bindInfo = param.bindInfo
	local reunionRecord = param.reunionRecord
	self.role_type = self.reunion.role_type
	self.view = {}

	for k, v in csvPairs(csv.yunying.reunion_gift) do
		if v.huodongID == cfg.huodongID and v.type == STATE_TYPE_GIFT.reunion and v.target == self.role_type then
			self.csvID = k
		end
	end

	local name = "bindPlayer"
	--绑定礼包已领取，或者是老玩家
	if (self.role_type == STATE_ROLE_TYPE.reunion and self.reunion.gift.bind and self.csvID and self.reunion.gift.bind[1] == self.csvID and self.reunion.gift.bind[2] == STATE_TYPE.received)
		or self.role_type == STATE_ROLE_TYPE.senior then
		name = "task"
	end

	self.showViewName:addListener(function(val, oldval)
		if oldval and self.view[oldval] then
			self.view[oldval]:hide()
		end
		if val then
			local params = {bindInfo = bindInfo, reunionRecord = reunionRecord}
			if val == "bindPlayer" then
				params = {goPanelClick = self.goPanelClick, bindInfo = bindInfo}
			end
			if not self.view[val] then
				self.view[val] = gGameUI:createView(viewName[val], self):init(yyID, params)
			else
				self.view[val]:show()
			end
		end
	end)

	self.goPanelClick:addListener(function(val, oldval)
		if val == 1 then
			self.showViewName:set("task")
		end
	end)
	self.showViewName:set(name)
end

function ReunionReunionView:initModel()
	self.reunion = gGameModel.role:read("reunion")
	self.goPanelClick = idler.new(0)
	self.showViewName = idler.new()
end

return ReunionReunionView