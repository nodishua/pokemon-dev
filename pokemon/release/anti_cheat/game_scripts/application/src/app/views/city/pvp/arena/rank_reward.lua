-- @date:   2019-02-26
-- @desc:   竞技场-排名奖励

local ArenaRankRewardView = class("ArenaRankRewardView", Dialog)

ArenaRankRewardView.RESOURCE_FILENAME = "arena_rank_reward.json"
ArenaRankRewardView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["title.textTitle1"] = "textTitle1",
	["title.textTitle2"] = "textTitle2",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				margin = 12,
				data = bindHelper.self("rankDatas"),
				item = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("textRank", "textCost", "btnGet", "imgIcon", "list")
					childs.textRank:text(v.rank)
					local btnTitle
					if v.pointNum ~= 0 then
						btnTitle = (v.canReceive == 0) and gLanguageCsv.hasChange or gLanguageCsv.spaceExchange
						childs.textCost:text(v.pointNum)
						childs.btnGet:y(node:size().height/3)
					else
						btnTitle = (v.canReceive == 0) and gLanguageCsv.received or gLanguageCsv.spaceReceive
						childs.btnGet:y(node:size().height/2)
						childs.imgIcon:y(node:size().height/2)
						childs.textCost:y(node:size().height/2)
						childs.imgIcon:hide()
						childs.textCost:hide()
					end
					if next(v.award) ~= nil then
						uiEasy.createItemsToList(list, childs.list, v.award, {scale = 0.9})
					end
					bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					--0已领取，1可领取, nil不能领取(由于排序nil赋值为0.5)
					local canClickReceive = v.canReceive == 1 and v.pointEnough
					local color = v.pointEnough and ui.COLORS.NORMAL.DEFAULT or cc.c4b(255,76,76,255)
					text.addEffect(childs.textCost, {color = color})
					childs.btnGet:setTouchEnabled(canClickReceive)
					cache.setShader(childs.btnGet, false, canClickReceive and "normal" or "hsl_gray")
					childs.btnGet:get("textNote"):text(btnTitle)
					if canClickReceive then
						text.addEffect(childs.btnGet:get("textNote"), {glow={color=ui.COLORS.GLOW.WHITE}})
					else
						text.deleteAllEffect(childs.btnGet:get("textNote"))
						text.addEffect(childs.btnGet:get("textNote"), {color = ui.COLORS.DISABLED.WHITE})
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onitemClick"),
			},
		},
	},
	["textNote"] = "textNote",
	["textRank"] = "textRank",
}

function ArenaRankRewardView:onCreate()
	self:initModel()
	self.rankDatas = idlers.new()
	idlereasy.when(self.rankAward, function(_, rankAward)
		local rankDatas = {}
		for k,v in csvPairs(csv.pwrank_award) do
			local pointId, pointNum = csvNext(v.cost)
			pointNum = pointNum or 0
			local pointEnough = true
			if pointNum > 0 then
				pointEnough = dataEasy.getNumByKey(pointId) >= pointNum
			end
			rankDatas[k] = {
				id = k,
				pointNum = pointNum,
				pointEnough = pointEnough,
				award = v.award,
				rank = v.needRank,
				canReceive = rankAward[k] or 0.5
			}
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.rankDatas:update(rankDatas)
	end)
	adapt.oneLinePos(self.textTitle1, self.textTitle2, nil, "left")
	idlereasy.when(self.record, function(_, record)
		self.textRank:text(record.rank_top)
		adapt.oneLinePos(self.textRank, self.textNote, cc.p(8, 0), "right")
	end)
	Dialog.onCreate(self)
end

function ArenaRankRewardView:initModel()
	self.rankAward = gGameModel.role:getIdler("pw_rank_award")
	self.record = gGameModel.arena:getIdler("record")
end

function ArenaRankRewardView:onSortCards(list)
	return function(a, b)
		if a.canReceive ~= b.canReceive then
			return a.canReceive > b.canReceive
		end
		return a.rank > b.rank
	end
end

function ArenaRankRewardView:onitemClick(list, k, v)
	local getFunc = function()
		gGameApp:requestServer("/game/pw/battle/rank/award",function (tb)
			local award = {}
			for k,v in csvMapPairs(v.award) do
				award[k] = v
			end
			gGameUI:showGainDisplay(award)
		end,v.id)
	end

	if v.pointNum > 0 then
		local params = {
			cb = getFunc,
			isRich = true,
			btnType = 2,
			content = string.format(gLanguageCsv.changeItems, v.pointNum),
			dialogParams = {clickClose = false},
		}
		gGameUI:showDialog(params)

		return
	end
	getFunc()
end

return ArenaRankRewardView
