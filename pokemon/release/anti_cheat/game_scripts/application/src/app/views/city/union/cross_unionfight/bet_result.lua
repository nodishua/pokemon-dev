-- @date:   2021-09-15
-- @desc:   1.竞猜获得奖励界面

local BetResultView = class("BetResultView", cc.load("mvc").ViewBase)

BetResultView.RESOURCE_FILENAME = "cross_union_fight_bet_result.json"
BetResultView.RESOURCE_BINDING = {
	["winPanel"] = "winPanel",
	["losePanel"] = "losePanel",
	["winPanel.imgBG"] = "imgBG",
	["winPanel.unionItem"] = "unionItem",
	["winPanel.imgText"] = "imgText",
	["winPanel.unionList"] = {
		varname = "unionList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("unionData"),
				item = bindHelper.self("unionItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "name")
					childs.name:text(v.union_name)
					childs.icon:texture(csv.union.union_logo[v.union_logo].icon)
				end,
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
			},
		},
	},
	["winPanel.item"] = "item",
	["winPanel.list"] = "list",
	["losePanel.txt"] = "loseTxt",
	["losePanel.list"] = "loseList",
}

BetResultView.RESOURCE_STYLES = {
	blackLayer = true,
	clickClose = true,
}

function BetResultView:onCreate(param, types)
	local data = types and param[5] or param
	self.loseList:setScrollBarEnabled(false)
    local pnode = self:getResourceNode()
	self.allBetSuccess = false
	local unions = {}
	local award = {}
	-- 初赛决赛奖励计算
	if types ~= 5 then
		for i, v in pairs(data) do
			if v.success then
				unions[i] = v
				award[i] = csv.cross.union_fight.base[1].preBetWinAward
			else
				award[i] = csv.cross.union_fight.base[1].preBetFailAward
			end
		end
	else
		if data.success then
			unions[types] = data
			award[types] = csv.cross.union_fight.base[1].top4BetWinAward
		else
			award[types] = csv.cross.union_fight.base[1].top4BetFailAward
		end
		local index = 0
		for i, v in pairs(param) do
			if v.success then
				index = index + 1
			end
		end
		-- 全猜中
		if index == 5 then
			self.allBetSuccess = true
			award[6] = csv.cross.union_fight.base[1].extraAward
		end
	end

	local awardData = {}
	for _, cfg in pairs(award) do
		for key, val in csvMapPairs(cfg) do
			awardData[key] = awardData[key] and awardData[key] + val or val
		end
	end
	self.awardData = {}
	for k, v in pairs(awardData) do
		table.insert(self.awardData, {key = k, val = v})
	end

	--竞猜成功or失败
	if itertools.size(unions) == 0 then
		-- 失败
		self.winPanel:hide()
		self.losePanel:show()
		--判断初赛决赛
		if types <= 4 then
			self.loseTxt:text(gLanguageCsv.losePreBet)
		else
			self.loseTxt:text(gLanguageCsv.loseFinalBet)
		end
		self:initAward(self.loseList)
	else
		self.winPanel:show()
		self.losePanel:hide()
		self.imgText:visible(types < 5)
		widget.addAnimation(pnode, "kuafushiying/jccg.skel", "effect_loop", 10)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(pnode:width()/2, pnode:height() - 280)
		:scale(2)
		self:initAward(self.list)
		self.imgText:show()
	end
	self.unionData = idlers.newWithMap(unions)
end

function BetResultView:initAward(list)
	bind.extend(self, list, {
		class = "listview",
		props = {
			data = self.awardData,
			item = self.item,
			margin = itertools.size(self.awardData) > 4 and 0 or 80,
			onItem = function(list, node, k, v)
				bind.extend(list, node, {
					class = "icon_key",
					props = {
						data = {
							key = v.key,
							num = v.val,
						},
						onNode = function(panel)
							panel:y(160)
							local name = dataEasy.getCfgByKey(v.key).name
							adapt.setTextScaleWithWidth(node:get("txtName"), name, panel:width() + 80)
						end,
					},
				})
			end,
			onAfterBuild = function (list)
				list:setItemAlignCenter()
			end
		}
	})
	self.list:setScrollBarEnabled(false)
end

return BetResultView