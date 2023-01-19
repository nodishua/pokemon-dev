-- @date:   2019-06-10
-- @desc:   公会副本奖励界面
local ViewBase = cc.load("mvc").ViewBase
local UnionGateRewardView = class("UnionGateRewardView", Dialog)

UnionGateRewardView.RESOURCE_FILENAME = "union_gate_reward.json"
UnionGateRewardView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rewardDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					node:get("title"):text(v.id.."-"..v.name)
					uiEasy.createItemsToList(list, node:get("list"), v.rewards, {scale = 0.8})
					bind.touch(list, node:get("btn"), {methods = {ended = functools.partial(list.itemClick, k, v)}})
				end,
				asyncPreload = 3,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["btn"] = {
		varname = "btn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRequest")}
		},
	}
}

function UnionGateRewardView:onCreate(gateDatas, cb)
	self.cb = cb
	self:initModel()
	self.rewardDatas = idlers.new()
	idlereasy.when(self.unionFbAward, function(_, unionFbAward)
		local tmpData = {}
		local currentMonth = dataEasy.getUnionFubenCurrentMonth()
		for csvId,gateData in ipairs(gateDatas) do
			--已通关
			local complete = self.unionFuben[csvId].first_time > 0
			--已领取
			local received = (unionFbAward[csvId] and unionFbAward[csvId][1] == currentMonth and unionFbAward[csvId][2] > 0)
			if 	complete and not received then
				local rewards = {}
				local csvFuben = csv.union.union_fuben[csvId]
				local rewardTyp = unionFbAward[csvId] and csvFuben.repeatAward or csvFuben.firstAward
				for key,num in csvMapPairs(rewardTyp) do
					table.insert(rewards, {key = key,num = num})
				end
				table.insert(tmpData,{
					id = csvId,
					rewards = rewards,
					name = csvFuben.name
				})
			end
		end
		table.sort(tmpData,function(a,b)
			return a.id < b.id
		end)
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.rewardDatas:update(tmpData)
	end)

	Dialog.onCreate(self)
end

function UnionGateRewardView:initModel()
	self.unionFbAward = gGameModel.role:getIdler("union_fb_award")
	self.unionFuben = gGameModel.union_fuben:read("states")
end

function UnionGateRewardView:onItemClick(list, k, v)
	local showOver = {false}
	gGameApp:requestServerCustom("/game/union/fuben/award")
		:params(v.id)
		:onResponse(function (tb)
			showOver[1] = true
		end)
		:wait(showOver)
		:doit(function (tb)
			if self.rewardDatas:size() == 0 then
				self:addCallbackOnExit(functools.partial(self.cb, tb))
				ViewBase.onClose(self)
			end
			gGameUI:showGainDisplay(tb)
		end)
end

function UnionGateRewardView:onRequest()
	gGameApp:requestServer("/game/union/fuben/award",function (tb)
		self:addCallbackOnExit(functools.partial(self.cb, tb))
		ViewBase.onClose(self)
	end)
end
return UnionGateRewardView