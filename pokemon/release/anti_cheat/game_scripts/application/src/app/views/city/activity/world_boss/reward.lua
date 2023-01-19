-- @desc: 	world_boss-排行榜
-- @date:   2020-05-07

local WorldBossRewardView = class("WorldBossRewardView", Dialog)
WorldBossRewardView.RESOURCE_FILENAME = "activity_world_boss_reward.json"
WorldBossRewardView.RESOURCE_BINDING = {
	["leftPanel.tabItem"] = "tabItem",
	["leftPanel.tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
					end
					adapt.setAutoText(panel:get("txt"), v.name)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["panel"] = "panel",
	["panel.rankItem"] = "rankItem",
	["panel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("rankItem"),
				itemAction = {isAction = true, alwaysShow = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgBg", "rankIcon", "list", "txtRank")
					childs.rankIcon:hide()
					childs.txtRank:hide()
					if k <= 3 then
						childs.rankIcon:show():texture("activity/world_boss/img_rank" .. k .. ".png")
					else
						local left = v.preRank
						local right = v.cfg.rank
						local str = left <  right and (left.."-"..right) or right
						childs.txtRank:show():text(str)
					end
					uiEasy.createItemsToList(list, childs.list, v.cfg.award, {margin = 40, scale = 0.9})
				end,
				asyncPreload = 5,
			},
		},
	},
}

function WorldBossRewardView:onCreate(activityID)
	local yyCfg = csv.yunying.yyhuodong[activityID]
	local baseCfg
	for _, v in orderCsvPairs(csv.world_boss.base) do
		if v.huodongID == yyCfg.huodongID then
			baseCfg = v
			break
		end
	end
	local roleRankAward = {}
	local rankCsv = csv.world_boss.role_rank_award
	for k, v in orderCsvPairs(rankCsv) do
		if v.huodongID == yyCfg.huodongID then
			table.insert(roleRankAward, {cfg = v, csvId = k, preRank = rankCsv[k-1] and rankCsv[k-1].rank + 1 or 1})
		end
	end
	local unionRankAward = {}
	local rankCsv = csv.world_boss.union_rank_award
	for k, v in orderCsvPairs(rankCsv) do
		if v.huodongID == yyCfg.huodongID then
			table.insert(unionRankAward, {cfg = v, csvId = k, preRank = rankCsv[k-1]and rankCsv[k-1].rank + 1 or 1})
		end
	end

	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.role},
		[2] = {name = gLanguageCsv.guild},
	})
	self.showTab = idler.new(1)
	self.datas = idlers.new()
	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		self.datas:update(val == 1 and roleRankAward or unionRankAward)
	end)

	Dialog.onCreate(self)
end

function WorldBossRewardView:onTabClick(list, index)
	self.showTab:set(index)
end

return WorldBossRewardView