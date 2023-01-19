-- @date 2020-8-14
-- @desc 实时匹配奖励

local OnlineFightRewardView = class("OnlineFightRewardView", Dialog)

OnlineFightRewardView.RESOURCE_FILENAME = "online_fight_reward.json"
OnlineFightRewardView.RESOURCE_BINDING = {
	["topPanel.txtRank"] = "txtRank",
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
					panel:get("txt"):getVirtualRenderer():setLineSpacing(-5)
					adapt.setAutoText(panel:get("txt"), v.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["item"] = "item",
	["list1"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("data1"),
				item = bindHelper.self("item"),
				preloadCenter = bindHelper.self("preloadCenter1"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgBg", "imgRank", "txtRank", "list")
					childs.imgRank:hide()
					childs.txtRank:show():text(v.cfg.score[1] .. "-" .. (v.cfg.score[2] - 1))
					childs.imgBg:texture(v.isSelect and "city/pvp/online_fight/other/bg_list0.png" or "activity/world_boss/bg_list.png")
					uiEasy.createItemsToList(list, childs.list, v.cfg.award, {scale = 0.85, margin = 40})
				end,
			},
		},
	},
	["list2"] = {
		varname = "list2",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("data2"),
				item = bindHelper.self("item"),
				preloadCenter = bindHelper.self("preloadCenter2"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgBg", "imgRank", "txtRank", "list")
					if v.cfg.rankMax <= 3 then
						childs.imgRank:show():texture(ui.RANK_ICON[k])
						childs.txtRank:hide()
					else
						childs.imgRank:hide()
						childs.txtRank:show()
						if v.cfg.rankMax > v.lastRankMax + 1 then
							childs.txtRank:text((v.lastRankMax + 1) .. "-" .. v.cfg.rankMax)
						else
							childs.txtRank:text(v.cfg.rankMax)
						end
					end
					childs.imgBg:texture(v.isSelect and "city/pvp/online_fight/other/bg_list0.png" or "activity/world_boss/bg_list.png")
					uiEasy.createItemsToList(list, childs.list, v.cfg.award, {scale = 0.85, margin = 40})
				end,
			},
		},
	},
	["desc"] = "desc",
}

function OnlineFightRewardView:onCreate()
	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.onlineFightTab1},
		[2] = {name = gLanguageCsv.onlineFightTab2},
	})
	self.datas = {
		[1] = {txtRank = gLanguageCsv.score, desc = gLanguageCsv.onlineFightRewardDesc1, specialDesc = gLanguageCsv.onlineFightRewardSpecialDesc1},
		[2] = {txtRank = gLanguageCsv.ranking, desc = gLanguageCsv.onlineFightRewardDesc2},
	}
	for i = 1, 2 do
		self["data" .. i] = idlers.new()
		self["list" .. i]:hide()
		self["preloadCenter" .. i] = idler.new(0)

		local version = gGameModel.cross_online_fight:read("version")
		local t = {}
		local curPos = 0
		local isVaild = self:isVaildAward(i)
		if i == 1 then
			local unlimitedScore = gGameModel.cross_online_fight:read("unlimited_score") -- # 无限制积分
			local limitedScore = gGameModel.cross_online_fight:read("limited_score") -- # 公平赛积分
			local maxScore = math.max(unlimitedScore, limitedScore)
			for _, v in orderCsvPairs(csv.cross.online_fight.weekly_award) do
				if v.version == version then
					local isSelect = false
					if isVaild and v.score[1] <= maxScore and v.score[2] > maxScore then
						curPos = #t + 1
						isSelect = true
					end
					table.insert(t, {cfg = v, isSelect = isSelect})
				end
			end
		else
			local unlimitedRank = gGameModel.cross_online_fight:read("unlimited_rank") -- # 无限制排名
			local limitedRank = gGameModel.cross_online_fight:read("limited_rank") -- # 公平赛排名
			local maxRank
			if unlimitedRank == 0 then
				maxRank = limitedRank
			elseif limitedRank == 0 then
				maxRank = unlimitedRank
			else
				maxRank = math.min(unlimitedRank, limitedRank)
			end
			local lastRankMax = nil
			for _, v in orderCsvPairs(csv.cross.online_fight.final_award) do
				if v.version == version then
					local isSelect = false
					if isVaild and (v.rankMax == maxRank or (lastRankMax and lastRankMax + 1 <= maxRank and v.rankMax > maxRank)) then
						curPos = #t + 1
						isSelect = true
					end
					table.insert(t, {cfg = v, lastRankMax = lastRankMax, isSelect = isSelect})
					lastRankMax = v.rankMax
				end
			end
		end
		self["preloadCenter" .. i]:set(curPos)
		self["data" .. i]:update(t)
	end

	self.showTab = idler.new(1)
	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		self["list" .. oldval]:hide()
		self["list" .. val]:show()
		self.txtRank:text(self.datas[val].txtRank)
		self.desc:text(self.datas[val].desc)
		text.addEffect(self.desc, {color = ui.COLORS.NORMAL.DEFAULT})
		if not self:isVaildAward(val) then
			if val == 1 then
				self.desc:text(self.datas[val].specialDesc)
				text.addEffect(self.desc, {color = ui.COLORS.NORMAL.RED})
			end
		end
	end)

	Dialog.onCreate(self)
end

function OnlineFightRewardView:isVaildAward(index)
	local baseCfg = csv.cross.online_fight.base[1]
	if index == 1 then
		-- 本周需要至少参与3场战斗才可领取结算奖励
		local onlineFightInfo = gGameModel.role:read("cross_online_fight_info")
		local battleTimes = onlineFightInfo.weekly_battle_times or 0 -- # 本周战斗次数
		if battleTimes < baseCfg.weeklyAwardLeastTimes then
			return false
		end
	else
		local unlimitedRank = gGameModel.cross_online_fight:read("unlimited_rank") -- # 无限制排名
		local limitedRank = gGameModel.cross_online_fight:read("limited_rank") -- # 公平赛排名
		if unlimitedRank == 0 and limitedRank == 0 then
			return false
		end
	end
	return true
end

function OnlineFightRewardView:onTabClick(list, index)
	self.showTab:set(index)
end

return OnlineFightRewardView