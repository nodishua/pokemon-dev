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

ArenaPointRewardView.RESOURCE_FILENAME = "arena_point_reward.json"
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
	["down.btnGet"] = {
		varname = "getBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onGetBtn(-1)
			end)}
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

function ArenaPointRewardView:onCreate()
	self.downTextNote:hide()
	local x, y = self.downTextNote:xy()
	local richText = rich.createWithWidth(gLanguageCsv.rankPointRule, 30, nil, 1250)
			:addTo(self.down, 10)
			:anchorPoint(cc.p(0, 0.5))
			:xy(x - 13, y)
			:formatText()
	self:initModel()
	self.pointDatas = idlers.new()
	idlereasy.when(self.resultPointAward, function(_, resultPointAward)
		local pointDatas = {}
		local canOneKeyReceive = false
		for k,v in csvPairs(csv.pwpoint_award) do
			if resultPointAward[k] == 1 then
				canOneKeyReceive = true
			end
			pointDatas[k] = {
				id = k,
				award = v.award,
				point = v.needPoint,
				canReceive = resultPointAward[k] or 0.5
			}
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.pointDatas:update(pointDatas)
		setBtnState(self.getBtn, canOneKeyReceive)
	end)

	adapt.oneLinePos(self.textTitle1, self.textTitle2, nil, "left")
	Dialog.onCreate(self)
end

function ArenaPointRewardView:initModel()
	self.resultPointAward = gGameModel.daily_record:getIdler("result_point_award")
	self.resultPoint = gGameModel.daily_record:getIdler("pvp_result_point")
end

function ArenaPointRewardView:onitemClick(list, k, v)
	self:onGetBtn(v.id)
end

function ArenaPointRewardView:onGetBtn(csvId)
	gGameApp:requestServer("/game/pw/battle/point/award",function (tb)
		gGameUI:showGainDisplay(tb)
	end,csvId)
end

function ArenaPointRewardView:onSortCards(list)
	return function(a, b)
		if a.canReceive ~= b.canReceive then
			return a.canReceive > b.canReceive
		end
		return a.id > b.id
	end
end

return ArenaPointRewardView
