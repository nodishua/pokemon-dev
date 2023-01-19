local BCAdapt = require("app.views.city.activity.brave_challenge.adapt")
local GET_TYPE = {
	GOTTEN = 0, 	--已领取
	CAN_GOTTEN = 1, --可领取
	CAN_NOT_GOTTEN = 2, --未完成
}
local BraveChallengeAchvView = class("BraveChallengeAchvView", Dialog)

BraveChallengeAchvView.RESOURCE_FILENAME = "activity_brave_challenge_achievement.json"
BraveChallengeAchvView.RESOURCE_BINDING = {
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
									activityId = v.id,
									sign = v.sign,
									type = v.type,
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
	["rankItem"] = "rankItem",
	["rewardPanel1.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 5,
				data = bindHelper.self("achvDatas1"),
				item = bindHelper.self("rankItem"),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("achvDesc", "btnGet", "list", "got")
					childs.achvDesc:text(v.desc)
					if next(v.award) ~= nil then
						uiEasy.createItemsToList(list, childs.list, v.award, {scale = 0.8})
					end
					childs.list:setScrollBarEnabled(false)
					bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, v.csvId)}})
					-- 0已领取，1可领取
					childs.got:visible(v.get == GET_TYPE.GOTTEN)
					childs.btnGet:visible(v.get ~= GET_TYPE.GOTTEN)
					childs.btnGet:get("txt"):text((v.get == GET_TYPE.GOTTEN) and gLanguageCsv.received or gLanguageCsv.spaceReceive)
					if v.get ~= GET_TYPE.GOTTEN and v.get ~= GET_TYPE.CAN_GOTTEN and v.achType == 1 then
						if v.targetType == 3 then
							childs.btnGet:get("txt"):text("0/1")
						else
							childs.btnGet:get("txt"):text(v.progress .. "/" .. v.targetArg1)
						end
					end
					uiEasy.setBtnShader(childs.btnGet, childs.btnGet:get("txt"), v.get)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onGetBtn"),
			},
		},
	},
}

function BraveChallengeAchvView:onCreate(id, info)
	self:initModel()
	self.baseInfo = info
	self.activityId = id
	self.showTab = idler.new(1)
	self.achvDatas1 = idlers.new()
	self.achvDatas2 = idlers.new()

	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.achievement, redHint = "braveChallengeAch",id = self.activityId, type = 1, sign = BCAdapt.typ},
		[2] = {name = gLanguageCsv.specialAchievement, redHint = "braveChallengeAch",id = self.activityId, type = 2, sign = BCAdapt.typ},
	})

	local sign = BCAdapt.typ == game.BRAVE_CHALLENGE_TYPE.anniversary
	self.idler = sign and self.yyhuodongs or self.commonBCData

	idlereasy.when(self.idler, function(_, idler)
		local yyData = idler or {}
		if sign then
			yyData = idler[self.activityId] or {}
		end

		local times = yyData.valsums or {}
		local data1 = {}
		local data2 = {}

		for i, v in orderCsvPairs(csv.brave_challenge.achievement) do
			if v.groupID == self.baseInfo.achiSeqID then
				local data = table.shallowcopy(v)
				data.csvId = i
				local stamps = yyData.stamps or {}
				data.get = stamps[i]
				data.progress = times[i] or 0
				data.achType = v.type
				if v.type == 1 then
					table.insert(data1, data)
				else
					table.insert(data2, data)
				end
			end
		end
		self.datas = {[1] = data1, [2] = data2}
		self.achvDatas1:update(self.datas[self.showTab:read()])
	end)

	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		self.achvDatas1:update(self.datas[val])
	end)

	self.rewardPanel1:show()

	Dialog.onCreate(self)
end

function BraveChallengeAchvView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.commonBCData = gGameModel.role:getIdler("normal_brave_challenge")
end

function BraveChallengeAchvView:onTabClick(list, index)
	self.showTab:set(index)
end

function BraveChallengeAchvView:onGetBtn(list, csvId)
	gGameApp:requestServer(BCAdapt.url("award"),function (tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, csvId)
end

function BraveChallengeAchvView:onSortCards(list)
	return function(a, b)
		local va = a.get or 0.5
		local vb = b.get or 0.5
		if va ~= vb then
			return va > vb
		end
		return a.csvId < b.csvId
	end
end

return BraveChallengeAchvView