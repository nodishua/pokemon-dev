-- @date:   2019-02-26
-- @desc:   竞技场-积分奖励

local function setBtnState(btn, state)
	btn:setTouchEnabled(state)
	cache.setShader(btn, false, state and "normal" or "hsl_gray")
	if state then
		text.addEffect(btn:get("textNote"), {glow={color=ui.COLORS.GLOW.WHITE}})
	else
		text.deleteAllEffect(btn:get("textNote"))
		text.addEffect(btn:get("textNote"), {color = ui.COLORS.DISABLED.WHITE})
	end
end

local ArenaPointRewardView = class("ArenaPointRewardView", Dialog)

ArenaPointRewardView.RESOURCE_FILENAME = "horse_race_point_reward.json"
ArenaPointRewardView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["title.textTitle1"] = "textTitle1",
	["title.textTitle2"] = "textTitle2",
	["down"] = "down",
	["down.textNote"] = "downTextNote",
	["down.textPoint"] = "textPoint",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("pointDatas"),
				item = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("textScore", "btnGet", "icon", "list")
					childs.textScore:text(v.point)
					if next(v.award) ~= nil then
						uiEasy.createItemsToList(list, childs.list, v.award, {scale = 0.9})
					end
					bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					--0已领取，1可领取, nil不能领取(由于排序nil赋值为0.5)
					childs.btnGet:get("textNote"):text((v.canReceive == 0) and gLanguageCsv.received or gLanguageCsv.spaceReceive)
					setBtnState(childs.btnGet, v.canReceive == 1)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onitemClick"),
			},
		},
	},
	["down.textScore"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("resultPoint")
		}
	},
	-- ["txtPos"] = "txtPos"
}

function ArenaPointRewardView:onCreate(activityId)
	self.activityId = activityId
	self:initModel()
	self.pointDatas = idlers.new()
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yyData = yyhuodongs[activityId]
		local resultPointAward = yyData.horse_race.point_award or {}
		local resultPoint = yyData.horse_race.point or 0
		local pointDatas = {}
		local canOneKeyReceive = false
		for k,v in csvPairs(csv.yunying.horse_race_point_award) do
			if resultPointAward[k] == 1 then
				canOneKeyReceive = true
			end
			pointDatas[k] = {
				id = k,
				award = v.award,
				point = v.point,
				canReceive = resultPointAward[k] or 0.5
			}
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.pointDatas:update(pointDatas)
		self.textPoint:text(string.format(gLanguageCsv.horseRacePoint, resultPoint))
	end)

	adapt.oneLinePos(self.textTitle1, self.textTitle2, nil, "left")
	Dialog.onCreate(self)
end

function ArenaPointRewardView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ArenaPointRewardView:onitemClick(list, k, v)
	self:onGetBtn(v.id)
end

function ArenaPointRewardView:onGetBtn(csvId)
	gGameApp:requestServer("/game/yy/horse/race/point/award",function (tb)
		gGameUI:showGainDisplay(tb)
	end,self.activityId,csvId)
end

function ArenaPointRewardView:onSortCards(list)
	return function(a, b)
		if a.canReceive ~= b.canReceive then
			return a.canReceive > b.canReceive
		end
		return a.id < b.id
	end
end

return ArenaPointRewardView
