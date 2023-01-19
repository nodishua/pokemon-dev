-- @date:   202020-11-26
-- @desc:   堆雪人活动_等级奖励

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
local ActivitySnowmanRewardView = class("ActivitySnowmanRewardView", Dialog)
ActivitySnowmanRewardView.RESOURCE_FILENAME = "activity_snowman_reward.json"
ActivitySnowmanRewardView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["title.textTitle1"] = "textTitle1",
	["title.textTitle2"] = "textTitle2",
	["down"] = "down",
	["down.btnGet"] = {
		varname = "getBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOneKey")}
		},
	},
	["down.btnGet.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["item"] = "item",
	["item1"] = "item1",
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
					childs.textScore:text(v.level)
					uiEasy.createItemsToList(list, childs.list, v.award, {scale = 0.9})
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
}

function ActivitySnowmanRewardView:onCreate(activityId)
	self:initModel()
	self.activityId = activityId
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID
	local pointDatas = {}
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yyData = self.yyhuodongs:read()[activityId] or {}
		self.yyData = yyData
		local param = yyData.stamps
		self.param = param
		local canOneKeyReceive = false
		for k,v in orderCsvPairs(csv.yunying.huodongcloth_level) do
			if v.huodongID == huodongID and next(v.award) ~= nil then
				if param[k] == 1 then
					canOneKeyReceive = true
				end
				pointDatas[k] = {
					id = k,
					award = v.award,
					level = v.level,
					canReceive = param[k] or 0.5
				}
			end
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.pointDatas:update(pointDatas)
		setBtnState(self.getBtn, canOneKeyReceive)
		adapt.oneLinePos(self.textTitle1, self.textTitle2, nil, "left")
	end)
	Dialog.onCreate(self)
end

function ActivitySnowmanRewardView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.pointDatas = idlers.new()
end

function ActivitySnowmanRewardView:onitemClick(list, k, v)
	self:onGetBtn(v.id)
end

function ActivitySnowmanRewardView:onGetBtn(csvId)
	gGameApp:requestServer("/game/yy/award/get",function (tb)
		self.pointDatas:atproxy(csvId).canReceive = 0
		gGameUI:showGainDisplay(tb)
	end,self.activityId,csvId)
end

function ActivitySnowmanRewardView:onOneKey()
	gGameApp:requestServer("/game/yy/award/get/onekey",function (tb)
		gGameUI:showGainDisplay(tb)
	end,self.activityId)
end

function ActivitySnowmanRewardView:onSortCards(list)
	return function(a, b)
		if a.canReceive ~= b.canReceive then
			return a.canReceive > b.canReceive
		end
		return a.id < b.id
	end
end

return ActivitySnowmanRewardView
