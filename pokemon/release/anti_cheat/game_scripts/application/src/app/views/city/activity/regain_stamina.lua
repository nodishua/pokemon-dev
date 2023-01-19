-- @date 2019-01-11
-- @desc
local NAME = {
	gLanguageCsv.breakfast,
	gLanguageCsv.launch,
	gLanguageCsv.dinner,
	gLanguageCsv.supper
}
-- 可吃，不可吃，吃过了，可补领
local STATE = {
	CAN_EAT = 1,
	NOT_EAT = 2,
	ATE = 3,
	AGAIN_EAT = 4,
}

local ActivityRegainStaminaView = class("ActivityRegainStaminaView", cc.load("mvc").ViewBase)

ActivityRegainStaminaView.RESOURCE_FILENAME = "activity_regain_stamina.json"
ActivityRegainStaminaView.RESOURCE_BINDING = {
	["title"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.RED}},
		},
	},
	["item"] = "item",
	["list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				dataOrderCmp = function(a, b)
					return a.cfg.beginTime < b.cfg.beginTime
				end,
				onItem = function(list, node, id, v)
					local cfg = v.cfg
					local idx = list:getIdx(id)
					local childs = nodetools.multiget(node, "contentBg", "timeTxt", "btnAte", "img", "againPanel")
					local beginHour, beginMin = time.getHourAndMin(cfg.beginTime, true)
					local endHour = beginHour + cfg.openDuration
					local endMin = beginMin
					childs.timeTxt:text(string.format("%s%d:%02d-%d:%02d", NAME[idx], beginHour, beginMin, endHour, endMin))
					childs.img:texture("activity/regain_stamina/img_plate" .. idx .. "@.png")
					text.addEffect(childs.btnAte:get("label"), {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})

					nodetools.invoke(node, {"btnAte", "againPanel", "ate", "imgSelect", "contentBg", "timeTxt"}, "hide")
					bind.touch(list, childs.btnAte, {methods = {ended = functools.partial(list.clickCell, k, v)}})

					local content = childs.contentBg:get("content")
					if content:get("emm") then
						content:removeAllChildren()
					end
					if v.state == STATE.CAN_EAT then
						nodetools.invoke(node, {"btnAte", "timeTxt", "imgSelect", "contentBg"}, "show")
						childs.btnAte:get("label"):text(gLanguageCsv.spaceEat)
						if v.privilege ~= 0 then
							content:text("")
							local str = string.format(gLanguageCsv.privilegeCurrTimeEat, cfg.paramMap.stamina, v.privilege)
							local rich = rich.createWithWidth(str, 40, nil, 400)
							rich:addTo(content, 10, "emm")
								:align(cc.p(0, 1), 0, 115)
						else
							content:text(string.format(gLanguageCsv.currTimeEat, cfg.paramMap.stamina))
						end
					elseif v.state == STATE.NOT_EAT then
						nodetools.invoke(node, {"timeTxt", "contentBg"}, "show")
						content:text(gLanguageCsv.notCurrTimeEat)

					elseif v.state == STATE.ATE then
						nodetools.invoke(node, {"ate"}, "show")
						childs.img:texture("activity/regain_stamina/img_empty.png")
					else
						nodetools.invoke(node, {"btnAte", "againPanel", "contentBg"}, "show")
						childs.btnAte:get("label"):text(gLanguageCsv.spaceAgainEat)
						childs.againPanel:get("cost"):text(v.costRmb)
						adapt.oneLineCenterPos(cc.p(100, 25), {childs.againPanel:get("cost"), childs.againPanel:get("img")}, cc.p(15, 0))
						if v.privilege ~= 0 then
							content:text("")
							local str = string.format(gLanguageCsv.privilegePastTimeEat, cfg.paramMap.stamina, v.privilege)
							local rich = rich.createWithWidth(str, 40, nil, 400)
							rich:addTo(content, 10, "emm")
								:align(cc.p(0, 1), 0, 133)
						else
							content:text(string.format(gLanguageCsv.pastTimeEat, v.cfg.paramMap.stamina))
						end

					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBtnClick"),
			},
		},
	},
}

function ActivityRegainStaminaView:onCreate(activityId)
	self:initModel()
	self.costRmb = csv.yunying.yyhuodong[activityId].paramMap.rmb
	self.activityId = activityId

	local datas = {}
	local datasId = {}

	for id, v in orderCsvPairs(csv.yunying.yyhuodong) do
		if v.type == game.YYHUODONG_TYPE_ENUM_TABLE.dinnerTime and matchLanguage(v.languages) then
			local state = STATE.CAN_EAT
			local data = {
				id = id,
				cfg = v,
				costRmb = self.costRmb,
			}
			table.insert(datas, data)
			table.insert(datasId, id)
		end
	end
	self.datas = idlers.newWithMap(datas)

	idlereasy.any({self.yyhuodongs, self.yyOpen, self.trainerSkills}, function (_, yyhuodongs, yyOpen, skills)
		local privilege = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.StaminaGain)
		for i = 1, 4 do
			local yydata = yyhuodongs[datasId[i]] or {}
			self.datas:at(i):modify(function(data)
				data.lastday = yydata.lastday
				data.privilege = privilege[i] or 0
				data.state = self:getState(data)
				return true, data
			end, true)
		end
	end)
	self:enableSchedule():schedule(function ()
		local hour = time.getNowDate().hour
		local min = time.getNowDate().min
		local sec = time.getNowDate().sec
		for i,v in ipairs(datas) do
			local beginHour, beginMin = time.getHourAndMin(v.cfg.beginTime, true)
			local endHour, endMin = time.getHourAndMin(v.cfg.beginTime + v.cfg.openDuration * 100, true)
			endHour = endHour == 24 and 0 or endHour
			if ((hour == beginHour and beginMin == min) or (hour == endHour and endMin == min)) and 5 == sec then
				gGameApp:requestServer("/game/yy/active/get")
			end
		end
	end, 1, 0, "refresh")
end

function ActivityRegainStaminaView:initModel()
	self.yyOpen = gGameModel.role:getIdler("yy_open")
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.createTime = gGameModel.role:read("created_time")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.trainerSkills = gGameModel.role:getIdler("trainer_skills")
end


function ActivityRegainStaminaView:getState(data)
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local hour, min = time.getHourAndMin(yyCfg.beginTime, true)
	local refreshT = {hour = hour, min = min}
	if data.lastday then
		if tostring(data.lastday) == time.getTodayStrInClock(hour, min) then
			return STATE.ATE
		end
	end
	local cfg = data.cfg
	local beginHour, beginMin = time.getHourAndMin(cfg.beginTime, true)
	local beginKey = time.getCmpKey({hour = beginHour, min = beginMin}, refreshT)
	local endKey = time.getCmpKey({hour = beginHour + cfg.openDuration, min = beginMin}, refreshT)
	local nowKey = time.getCmpKey(time.getNowDate(), refreshT)
	if nowKey < beginKey then
		return STATE.NOT_EAT
	end
	if nowKey >= beginKey and nowKey < endKey then
		return STATE.CAN_EAT
	end
	return STATE.AGAIN_EAT
end

function ActivityRegainStaminaView:onBtnClick(list, k, v)
	if v.state == STATE.CAN_EAT then
		gGameApp:requestServer("/game/yy/award/get",function (tb)
			gGameUI:showGainDisplay(tb)
		end, v.id)

	elseif v.state == STATE.AGAIN_EAT then
		if self.rmb:read() < self.costRmb then
			uiEasy.showDialog("rmb")
		else
			gGameUI:showDialog({title = "", content = string.format(gLanguageCsv.staminaAaginGet, v.costRmb), cb = function()
				gGameApp:requestServer("/game/yy/award/get",function (tb)
					gGameUI:showGainDisplay(tb)
				end, v.id)
			end, btnType = 2, isRich = true, clearFast = true})
		end
	end
end

return ActivityRegainStaminaView
