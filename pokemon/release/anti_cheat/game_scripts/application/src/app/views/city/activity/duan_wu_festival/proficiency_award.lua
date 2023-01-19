--粽子奖励

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

ArenaPointRewardView.RESOURCE_FILENAME = "activity_duanwu_proficiency.json"
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
	["down.btnGet"] = {
		varname = "getBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onGetBtn()
			end)}
		},
	},
	["down.btnGet.textNote"] = {
		varname = "textNote",
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
}

function ArenaPointRewardView:onCreate(activityID)
	self.activityID = activityID
	self.item:visible(false)
	self.item1:visible(false)
	self:initModel()
	self.pointDatas = idlers.newWithMap({})
	local huodongID = csv.yunying.yyhuodong[activityID].huodongID
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local pointDatas = {}
		local canOneKeyReceive = false
		local canReceive = 0.5
		local num = 0
		if yyhuodongs[activityID] and yyhuodongs[activityID].info then
			num = yyhuodongs[activityID].info.counter
		end
		self.down:get("num"):text(num)
		for k,v in orderCsvPairs(csv.yunying.bao_zongzi_task) do
			if v.huodongID == huodongID then
				canReceive = 0.5
				if yyhuodongs[activityID] and yyhuodongs[activityID].stamps then
					if yyhuodongs[activityID].stamps[k] == 1 then
						canOneKeyReceive = true
					end
					canReceive = yyhuodongs[activityID].stamps[k]
					if canReceive ~= 0 and canReceive ~= 1 then
						canReceive = 0.5
					end
				end
				pointDatas[k] = {
					id = k,
					award = v.award,
					point = v.taskParam,
					canReceive = canReceive
				}
				dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
				self.pointDatas:update(pointDatas)
				setBtnState(self.getBtn, canOneKeyReceive)
			end
		end

	end)

	adapt.oneLinePos(self.textTitle1, self.textTitle2, nil, "left")
	Dialog.onCreate(self)
end

function ArenaPointRewardView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler('yyhuodongs')
end

function ArenaPointRewardView:onitemClick(list, k, v)
	gGameApp:requestServer("/game/yy/award/get",function (tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityID, v.id)
end

function ArenaPointRewardView:onGetBtn()
	gGameApp:requestServer("/game/yy/award/get/onekey",function (tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityID)
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
