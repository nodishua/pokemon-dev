local GET_TYPE = {
	GOTTEN = 0, 	--已领取
	CAN_GOTTEN = 1, --可领取
	CAN_NOT_GOTTEN = 2, --未完成
}

local function setBtnState(btn, state)
	btn:setTouchEnabled(state)
	cache.setShader(btn, false, state and "normal" or "hsl_gray")
	if state then
		text.addEffect(btn:get("txt"), {glow={color=ui.COLORS.GLOW.WHITE}})
	else
		text.deleteAllEffect(btn:get("txt"))
		text.addEffect(btn:get("txt"), {color = ui.COLORS.DISABLED.WHITE})
	end
end

local SnowBallRewardView = class("SnowBallRewardView", Dialog)

SnowBallRewardView.RESOURCE_FILENAME = "snow_ball_reward.json"
SnowBallRewardView.RESOURCE_BINDING = {
	["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["leftPanel.tabItem"] = "tabItem",
	["leftPanel.tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				showTab = bindHelper.self("showTab"),
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
					if v.redHint then
						bind.extend(list, node, {
							class = "red_hint",
							props = {
								state = list.showTab:read() ~= k,
								specialTag = v.redHint,
								listenData = {
									id = v.id,
								},
								onNode = function (red)
									red:xy(node:width() - 10, node:height() - 5)
								end
							},
						})
					end
					panel:get("txt"):text(v.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["rewardPanel1"] = "rewardPanel1",
	["rewardPanel1.btnAllGet"] = {
		varname = "getBtn1",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				gGameApp:requestServer("/game/yy/award/get",function (tb)
					gGameUI:showGainDisplay(tb)
				end, view.activityId, -1)
			end)}
		},
	},
	["rewardPanel1.btnAllGet.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["rewardPanel1.rankItem"] = "rankItem1",
	["rewardPanel1.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 5,
				days = bindHelper.self("days"),
				data = bindHelper.self("pointDatas1"),
				item = bindHelper.self("rankItem1"),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("txtRank", "btnGet", "list")
					childs.txtRank:text(v.num)
					if next(v.award) ~= nil then
						uiEasy.createItemsToList(list, childs.list, v.award, {scale = 0.9, margin = 20})
					end
					bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, v.csvId)}})
					--0已领取，1可领取
					childs.btnGet:get("txt"):text((v.get == GET_TYPE.GOTTEN) and gLanguageCsv.received or gLanguageCsv.spaceReceive)
					setBtnState(childs.btnGet, v.get == GET_TYPE.CAN_GOTTEN)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onGetBtn"),
			},
		},
	},
	["rewardPanel2"] = "rewardPanel2",
	["rewardPanel2.rankItem"] = "rankItem2",
	["rewardPanel2.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 5,
				points = bindHelper.self("points"),
				data = bindHelper.self("pointDatas2"),
				item = bindHelper.self("rankItem2"),
				itemAction = {isAction = true},
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				onItem = function(list, node, k, v)
					local childs = node:multiget("txtRank", "btnGet", "list")
					childs.txtRank:text(v.num)
					if next(v.award) ~= nil then
						uiEasy.createItemsToList(list, childs.list, v.award, {scale = 0.9, margin = 20})
					end
					bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, v.csvId)}})
					--0已领取，1可领取
					childs.btnGet:get("txt"):text((v.get == GET_TYPE.GOTTEN) and gLanguageCsv.received or gLanguageCsv.spaceReceive)
					setBtnState(childs.btnGet, v.get == GET_TYPE.CAN_GOTTEN)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onGetBtn"),
			},
		},
	},
	["rewardPanel2.btnAllGet"] = {
		varname = "getBtn2",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				gGameApp:requestServer("/game/yy/award/get",function (tb)
					gGameUI:showGainDisplay(tb)
				end, view.activityId, -2)
			end)}
		},
	},
	["rewardPanel2.btnAllGet.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
}

function SnowBallRewardView:onCreate(id)
	self.activityId = id
	self.rewardPanel1:show()
	self.rewardPanel2:hide()
	self:initModel()

	self.showTab = idler.new(1)
	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		if self["rewardPanel"..oldval] then
			self["rewardPanel"..oldval]:hide()
		end
		self["rewardPanel"..val]:show()
	end)
	Dialog.onCreate(self)
end

function SnowBallRewardView:initModel()
	self.pointDatas1 = idlers.new()
	self.pointDatas2 = idlers.new()
	self.days = idler.new(0)
	self.point = idler.new(0)
	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.snowBallGameSignin, redHint = "snowballDailyCheck",id = self.activityId},
		[2] = {name = gLanguageCsv.snowBallGameScoreAward, redHint = "snowballAwarding",id = self.activityId},
	})

	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yydata = yyhuodongs[self.activityId] or {}
		self.point:set(yydata.info.total_point)
		self.days:set(yydata.info.days)
		local data1 = {}
		local data2 = {}
		local btnAllGetState1 = false
		local btnAllGetState2 = false
		local yyCfg = csv.yunying.yyhuodong[self.activityId]
		local huodongID = yyCfg.huodongID
		for i, v in csvPairs(csv.yunying.snowball_award) do
			if v.huodongID == huodongID then
				local data = table.shallowcopy(v)
				data.csvId = i
				local stamps = yydata.stamps or {}
				data.get = stamps[i]
				if data.get == 1 and v.type == 1 then
					btnAllGetState1 = true
				elseif data.get == 1 and v.type == 2 then
					btnAllGetState2 = true
				end
				if v.type == 1 then
					table.insert(data1, data)
				else
					table.insert(data2, data)
				end
			end
		end
		self.pointDatas1:update(data1)
		self.pointDatas2:update(data2)
		setBtnState(self.getBtn1, btnAllGetState1)
		setBtnState(self.getBtn2, btnAllGetState2)
		local textNote1 = self.rewardPanel2:get("textNote1")
		local textNote2 = self.rewardPanel2:get("textNote2")
		local textScore = self.rewardPanel2:get("textScore"):text(yydata.info.total_point)
		adapt.oneLinePos(textNote1,{textScore,textNote2}, nil, "left")
	end)
end

function SnowBallRewardView:onTabClick(list, index)
	self.showTab:set(index)
end

function SnowBallRewardView:onGetBtn(list, csvId)
	gGameApp:requestServer("/game/yy/award/get",function (tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, csvId)
end

function SnowBallRewardView:onSortCards(list)
	return function(a, b)
		local va = a.get or 0.5
		local vb = b.get or 0.5
		if va ~= vb then
			return va > vb
		end
		return a.csvId < b.csvId
	end
end


return SnowBallRewardView
