-- @date:   2020-07-06
-- @desc:   自动钓鱼界面


local ViewBase = cc.load("mvc").ViewBase
local AutoFishingView = class("AutoFishingView", ViewBase)

AutoFishingView.RESOURCE_FILENAME = "fishing_auto.json"
AutoFishingView.RESOURCE_BINDING = {
	["fish"] = "autoFish",
	["btnCancel"] = "btnCancel",
	["btnFinish"] = "btnFinish",
	["fish.item"] = "fishItem",
	["fish.list"] = {
		varname = "fishList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("autoFishCfg"),
				item = bindHelper.self("fishItem"),
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						event = "extend",
						class = "fish_icon",
						props = {
							data = {
								key = k,
								num = v,
							},
							onNode = function(node)
								node:xy(10, 10)
							end,
							onNodeClick = true,
						},
					})
				end,
			},
		},
	},
	["award.item"] = "awardItem",
	["award.list"] = {
		varname = "awardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("autoAwardCfg"),
				item = bindHelper.self("awardItem"),
				onItem = function(list, node, k, v)
					if v.key == "id" then
						local unitID = csv.cards[v.val].unitID
						local star = csv.cards[v.val].star
						local rarity = csv.unit[unitID].rarity
						bind.extend(list, node, {
							class = "card_icon",
							props = {
								unitId = unitID,
								rarity = rarity,
								star = star,
							},
						})
						bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, node, k, v)}})
					else
						bind.extend(list, node, {
							class = "icon_key",
							props = {
								data = {
									key = v.key,
									num = v.val,
								}
							},
						})
					end
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onitemClick"),
			},
		},
	},
}

function AutoFishingView:onCreate(idx, cb)
	self:initModel()

	self.autoFishCfg = idlertable.new({})
	self.autoAwardCfg = idlers.newWithMap({})

	self:enableSchedule()
	local time = gCommonConfigCsv.fishingAutoDuration + 1
	self:schedule(function()-- 需要刷新main接口才能得到鱼的新数据
		gGameApp:requestServer("/game/fishing/main")
	end, time, 0, 6)

	idlereasy.any({self.autoStopped, self.autoAward, self.autoWinCounter, self.autoFailCounter}, function(_,autoStopped,autoAward,autoWinCounter,autoFailCounter)
		local autoAwardCfg = {}

		self.autoFish:get("txt2"):text(autoWinCounter + autoFailCounter)
		self.autoFish:get("txt4"):text(autoWinCounter)
		self.autoFish:get("txt6"):text(autoFailCounter)
		adapt.oneLinePos(self.autoFish:get("txt1"), {self.autoFish:get("txt2"), self.autoFish:get("txt3"), self.autoFish:get("txt4"), self.autoFish:get("txt5"), self.autoFish:get("txt6"), self.autoFish:get("txt7")}, cc.p(5, 0), "left")

		if autoAward.fish ~= nil then
			self.autoFishCfg:set(autoAward.fish)
		end
		if autoAward.type1 then
			for k,v in pairs(autoAward.type1) do
				table.insert(autoAwardCfg, {
					key = k,
					val = v,
				})
			end
		end
		if autoAward.type2 then
			for k,v in pairs(autoAward.type2) do
				table.insert(autoAwardCfg, {
					key = k,
					val = v,
				})
			end
		end
		if autoAward.cards then
			for k,v in pairs(autoAward.cards) do
				table.insert(autoAwardCfg, {
					key = "id",
					val = v.id,
				})
			end
		end
		self.autoAwardCfg:update(autoAwardCfg)
	end)

	bind.touch(self, self.btnCancel, {methods = {ended = function()
		self:enableSchedule():unSchedule(6)
		self:onClose()
	end}})
	bind.touch(self, self.btnFinish, {methods = {ended = function()
		gGameApp:requestServer("/game/fishing/auto/end", function(tb)
			ViewBase.onClose(self)
			if cb then
				cb()
			end
		end)
	end}})
end

-- 精灵详情
function AutoFishingView:onitemClick(list, node, idx, id)
	gGameUI:showItemDetail(node, {key = "card", num = id.val})
end

function AutoFishingView:initModel()
	self.autoStopped = gGameModel.fishing:getIdler("auto_stopped")
	self.autoAward = gGameModel.fishing:getIdler("auto_award")
	self.autoWinCounter = gGameModel.fishing:getIdler("auto_win_counter")
	self.autoFailCounter = gGameModel.fishing:getIdler("auto_fail_counter")
end

return AutoFishingView