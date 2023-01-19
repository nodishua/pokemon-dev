-- @desc:   跨服限时PVP主赛程八强赛
local CrossCraftMainView = require "app.views.city.pvp.cross_craft.view"

local FROM = {
	-- 晋级赛
	promotion = 1,
	-- 巅峰赛
	topStage = 2
}

local BATTLESTATE = {
	ready = 1,
	fight = 2
}

local stringfind = string.find

local function onPromotionCallBack(panel, i, j)
	local img = panel:getChildByName("frame")
	local path = "config/portrait/frame/box_head_default.png"
	if i == 3 or i == 4 or i == 6 or (i == 7 and j == 2) then
		path = "city/pvp/craft/mainschedule/panel_head_blue.png"
	end
	img:texture(path)
end

local function onFinalCallBack(panel, i, j)
	local img = panel:getChildByName("frame")
	local path = "config/portrait/frame/box_head_default.png"
	if i == 2 or (i == 3 and j == 2) then
		path = "city/pvp/craft/mainschedule/panel_head_blue.png"
	end
	img:texture(path)
end

local function isInBattle(round)
	return stringfind(round, "_lock") ~= nil
end

local group = {"group-a1", "group-a2", "group-b1", "group-b2", "group-a3", "group-b3"}
local function getPromotionData(datas, pageIdx)
	local info = datas["t" .. pageIdx - 1]
	local t = {}
	for i,v in ipairs(group) do
		local d = info and info[v]
		if d then
			table.insert(t, d)
		end
	end

	if info and info.champion then
		table.insert(t, info.champion)
	end

	return t
end

local function getFinalData(datas, pageIdx)
	local info = datas.final
	local t = {}
	local s = pageIdx == 2 and "b" or "a"
	for i=1,3 do
		local d = info and info["group-" .. s .. i]
		if d then
			table.insert(t, d)
		end
	end

	return t
end

local function getTopStageData(datas, pageIdx)
	local info = datas.final
	if pageIdx == 3 then
		return info and info.third
	elseif pageIdx == 4 then
		return info and info.champion
	end
end

local ViewBase = cc.load("mvc").ViewBase
local CrossCraftMainScheduleFinalView = class("CrossCraftMainScheduleFinalView", ViewBase)

CrossCraftMainScheduleFinalView.RESOURCE_FILENAME = "cross_craft_mainschedule.json"
CrossCraftMainScheduleFinalView.RESOURCE_BINDING = {
	["recordBg"] = {
		varname = "recordBg",
		binds = {
			event = "visible",
			idler = bindHelper.self("isRecord")
		},
	},
	["bgPanel"] = "bgPanel",
	["item"] = "item",
	["item1"] = "item1",
	["view1.listview"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("listData1"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local path = "city/pvp/cross_craft/mainschedule/btn_b.png"
					if v.isSel then
						path = "city/pvp/cross_craft/mainschedule/btn_r.png"
					end
					node:get("imgBg"):texture(path)
					node:get("textNote"):text(v.str)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onChangePromotionPage"),
			},
		},
	},
	["view2.listview"] = {
		varname = "list2",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("listData2"),
				item = bindHelper.self("item1"),
				margin = 20,
				onItem = function(list, node, k, v)
					local path = "city/pvp/cross_craft/mainschedule/btn_b1.png"
					if v.isSel then
						path = "city/pvp/cross_craft/mainschedule/btn_r1.png"
					end
					node:get("imgBg"):texture(path)
					node:get("textNote"):text(v.str)
					adapt.setTextScaleWithWidth(node:get("textNote"), nil, 170)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onChangeTopStafePage"),
			},
		},
	},
	["view1"] = {
		varname = "view1",
		binds = {
			event = "visible",
			idler = bindHelper.self("isPromotion"),
		},
	},
	["view2"] = {
		varname = "view2",
		binds = {
			event = "visible",
			idler = bindHelper.self("isPromotion"),
			method = function(val)
				return not val
			end,
		},
	},
	["view2.half1"] = {
		varname = "half1",
		binds = {
			event = "visible",
			idler = bindHelper.self("curTopstagePageIdx"),
			method = function(val)
				return val < 3
			end,
		},
	},
	["view2.half2"] = {
		varname = "half2",
		binds = {
			event = "visible",
			idler = bindHelper.self("curTopstagePageIdx"),
			method = function(val)
				return val > 2
			end,
		},
	},
	["schedule"] = "inBattle",
	["view1.title.imgTitle2"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("titlePath"),
			method = function(val)
				local txt = string.lower(val)
				return "city/pvp/cross_craft/txt/txt_" .. txt .. ".png"
			end,
		},
	},
	["view2.half1.title.imgTitle"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("titleType"),
			method = function(val)
				local path = "city/pvp/cross_craft/txt/txt_xbsq.png"
				if val == 1 then
					path = "city/pvp/cross_craft/txt/txt_sbsq.png"
				end
				return path
			end,
		},
	},
	["schedule.textTime"] = {
		varname = "scheduleTime",
		binds = {
			event = "text",
			idler = bindHelper.self("deltaTime"),
			method = function(val)
				local tab = time.getCutDown(val)
				return tab.min_sec_clock
			end,
		},
	},
	["btnMySchedule"] = {
		varname = "btnMySchedule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEnterMySchedule")}
		},
	},
	["leftDown"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isRecord"),
		},
	},
	["leftDown.btnPromotion"] = {
		varname = "btnPromotion",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onChangePage(FROM.promotion)
			end)}
		},
	},
	["leftDown.btnFinal"] = {
		varname = "btnFinal",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onChangePage(FROM.topStage)
			end)}
		},
	},
	["leftDown.btnPromotion.textNote"] = "btnPromotionNote",
	["leftDown.btnFinal.textNote"] = "btnFinalNote",
}

function CrossCraftMainScheduleFinalView:onCreate(isRecord)
	if isRecord == nil then
		isRecord = false
	end
	self.isRecord = idler.new(isRecord)
	self:initModel()

	local listDatas1 = {
		{str = "A", isSel = false},
		{str = "B", isSel = false},
		{str = "C", isSel = false},
		{str = "D", isSel = false},
		{str = "E", isSel = false},
		{str = "F", isSel = false},
		{str = "G", isSel = false},
		{str = "H", isSel = false},
	}
	self.listData1 = idlers.newWithMap(listDatas1)

	local listDatas2 = {
		{str = gLanguageCsv.halfUpBattle, isSel = false},
		{str = gLanguageCsv.halfDownBattle, isSel = false},
		{str = gLanguageCsv.thirdBattle, isSel = false},
		{str = gLanguageCsv.champtionBattle, isSel = false},
	}
	self.listData2 = idlers.newWithMap(listDatas2)

	self.refresh = idler.new(false)
	self.titlePath = idler.new("A")
	self.titleType = idler.new(1)
	self.isPromotion = idler.new()
	local isShowBtn = false
	if isRecord then
		self:onChangePage(FROM.promotion)
		isShowBtn = not itertools.isempty(self.history)
		gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
			:init({title = gLanguageCsv.crossCraft, subTitle = "CROSS - INDIGO PLATEAU CONFERENCE"})
	else
		self.isPromotion:set(stringfind(self.round:read(), "top") ~= nil)
	end
	if self._isPromotion ~= nil then
		self:onChangePage(self._isPromotion and FROM.promotion)
	end

	self.btnMySchedule:visible(isShowBtn)
	self.curPromotionPageIdx = idler.new()
	self.curTopstagePageIdx = idler.new()
	local idx = 1
	if string.find(self.round:read(), "final3") ~= nil then
		idx = 3
	end
	self.curPromotionPageIdx:set(self._curPromotionPageIdx or idx)
	self.curTopstagePageIdx:set(self._curTopstagePageIdx or idx)

	self.curPromotionPageIdx:addListener(function(val, old)
		if self.listData1:atproxy(old) then
			self.listData1:atproxy(old).isSel= false
		end

		if self.listData1:atproxy(val) then
			self.listData1:atproxy(val).isSel= true
		end
	end)

	self.curTopstagePageIdx:addListener(function(val, old)
		if self.listData2:atproxy(old) then
			self.listData2:atproxy(old).isSel= false
		end

		if self.listData2:atproxy(val) then
			self.listData2:atproxy(val).isSel= true
		end
	end)

	widget.addAnimationByKey(self.recordBg, "kuafushiying/bj.skel", "recordBg", "effect_loop", 1)
		:scale(2)
		:alignCenter(self.recordBg:size())

	local bgSize = self.bgPanel:size()
	local spiBg1 = widget.addAnimationByKey(self.bgPanel, "kuafushiying/jb.skel", "bgSpine1", "effect_jj_loop", 2)
		:scale(2)
		:xy(bgSize.width / 2, bgSize.height / 2 + 50)
		:hide()
	local spiBg2 = widget.addAnimationByKey(self.bgPanel, "kuafushiying/jjbj.skel", "bgSpine2", "effect_loop", 1)
		:scale(2)
		:alignCenter(self.bgPanel:size())
		:hide()

	local size = self.inBattle:size()
	local stateSpine = widget.addAnimationByKey(self.inBattle, "kuafushiying/wz.skel", "stateSpine", "effect_bzz_loop", 1)
		:scale(1)
		:xy(size.width / 2 - 50, size.height / 2 - 110)

	self.deltaTime = idler.new(0)
	self:enableSchedule()
	local curState = BATTLESTATE.ready
	local setLabel = function()
		local isBattle = isInBattle(self.round:read())
		local actionName = "effect_bzz_loop"
		local color = cc.c4b(76, 255, 76, 255)
		local outLineColor = ui.COLORS.NORMAL.DEFAULT
		local state = 1
		if isBattle then
			color = cc.c4b(255, 255, 0, 255)
			actionName = "effect_zdz_loop"
			state = 2
		end
		if state ~= curState then
			curState = state
			stateSpine:play(actionName)
		end
		text.addEffect(self.scheduleTime, {color = color, outline = {color = outLineColor, size = 5}})
		self.deltaTime:set(self.delta)
		self.inBattle:get("imgBg"):visible(self.isPromotion:read() or (self.curTopstagePageIdx:read() <= 2))
	end
	if self.delta then
		setLabel()
	end

	local params = {self.round, self.curPromotionPageIdx, self.curTopstagePageIdx, self.top8, self.curTime, self.refresh}
	idlereasy.any(params, function(_, round, curPromotionPageIdx, curTopstagePageIdx, top8, curTime)
		if not isRecord and (round == "over" or round == "closed") then
			return
		end
		if not isRecord then
			local isPromotion = stringfind(round, "top") ~= nil
			self.isPromotion:set(isPromotion)
		end

		if not self.isPromotion:read() and curTopstagePageIdx > 2 then
			local actionName = "effect_jj_loop"
			if curTopstagePageIdx == 4 then
				actionName = "effect_gj_loop"
			end
			spiBg2:show()
			spiBg1:play(actionName)
			spiBg1:show()
			local data = getTopStageData(top8, curTopstagePageIdx)
			if data then
				self:initTopStageView(data)
			end
		else
			spiBg1:hide()
			spiBg2:play("effect_loop")
			spiBg2:show()
			local data
			if self.isPromotion:read() then
				data = getPromotionData(top8, curPromotionPageIdx)
			elseif  curTopstagePageIdx < 3 then
				data = getFinalData(top8, curTopstagePageIdx)
			end
			if data then
				self:initUI(data)
			end
		end
		local isFinal3 = stringfind(round, "^final3") ~= nil
		self.inBattle:visible(not isRecord and (not isFinal3 or curTopstagePageIdx > 2))
		if not isRecord then
			self.delta = CrossCraftMainView.getNextStateTime(nil, true)
			setLabel()
		end
	end)

	self:schedule(function()
		local round = self.round:read()
		if isRecord or round == "over" or round == "closed" then
			return false
		end
		self.delta = CrossCraftMainView.getNextStateTime(nil, true)
		setLabel()
	end, 1, 0)
end

function CrossCraftMainScheduleFinalView:initModel()
	self.roleId = gGameModel.role:read('id')
	local craftData = gGameModel.cross_craft
	self.round = craftData:getIdler("round")
	self.curTime = craftData:getIdler("time")
	self.top8 = craftData:getIdler("top8_plays")
	if self.isRecord:read() then
		self.top8 = craftData:getIdler("last_top8_plays")
	end
	self.history = craftData:read("history")
	-- 是否报名
	self.isSignup = CrossCraftMainView.isSigned()
end

function CrossCraftMainScheduleFinalView:onCleanup()
	self._isPromotion = self.isPromotion:read()
	self._curPromotionPageIdx = self.curPromotionPageIdx:read()
	self._curTopstagePageIdx = self.curTopstagePageIdx:read()
	ViewBase.onCleanup(self)
end

-- groupIdx:小组赛的场次
function CrossCraftMainScheduleFinalView:canShowResult(data, groupIdx)
	local round = self.round:read()
	if self.isRecord:read() or round == "closed" or round == "over" then
		return true
	end
	if not data.result or data.result == "" then
		return false
	end
	local result = false

	if stringfind(round, "final1") or stringfind(round, "top64") then
		return result
	elseif (stringfind(round, "top32") and groupIdx <= 4) or (stringfind(round, "top16") and groupIdx <= 6) or
		(stringfind(round, "final2") and groupIdx <= 2) then
		result = true
	elseif stringfind(round, "final3") then
		return self.curTopstagePageIdx:read() < 3
	end

	return result
end

function CrossCraftMainScheduleFinalView:initUI(datas)
	local isPromotion = self.isPromotion:read()
	local panel, maxNum = self.half1, 3
	if isPromotion then
		panel, maxNum = self.view1, 7
	end

	local count = 0
	local isShowWinner = false
	panel:stopAllActions()
	panel:removeChildByName("cloneNode")
	panel:removeChildByName("touxiang")
	for i,v in ipairs(datas) do
		count = count + 1
		local teamPanel = panel:get("team" .. i)
		teamPanel:removeChildByName("vsInfo")
		local canShowResult = self:canShowResult(v, i)
		local paths = {}
		if canShowResult then
			paths[1] = v.result == "win" and "city/pvp/craft/icon_win.png" or "city/pvp/craft/icon_lose.png"
			paths[2] = v.result == "win" and "city/pvp/craft/icon_lose.png" or "city/pvp/craft/icon_win.png"
		end
		teamPanel:get("btnReplay"):visible(canShowResult)
		teamPanel:get("win"):hide()
		teamPanel:get("fail"):hide()
		for j=1,2 do
			local player = teamPanel:get("item" .. j)
			player:get("normal"):hide()
			local roleInfo = v["role" .. j]
			player:get("textLv"):text("Lv" .. roleInfo.level)
			text.addEffect(player:get("textLv"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 2}})
			text.addEffect(player:get("textName"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 2}})
			player:get("textName"):text(roleInfo.name)
			player:get("textLv"):show()
			player:get("textName"):show()
			bind.extend(self, player:get("head"),{
				class = "role_logo",
				props = {
					logoId = roleInfo.logo,
					frameId = roleInfo.frame,
					level = false,
					vip = false,
					onNode = function(panel)
						if roleInfo.frame ~= 1 then
							return
						end
						if isPromotion then
							onPromotionCallBack(panel, i, j)
						else
							onFinalCallBack(panel, i, j)
						end
					end,
				},
			})
			player:get("imgFlag"):hide()
			if canShowResult then
				player:get("imgFlag"):texture(paths[j])
				player:get("imgFlag"):show()
				teamPanel:get(v.result):show()
				bind.click(self, teamPanel:get("btnReplay"), {method = function()
					self:onReplay(v)
				end})
			end
			bind.click(self, player:get("head"), {method = function()
				local round = self.round:read()
				if isPromotion and stringfind(round, "top") == nil then
					round = "top"
				end
				self:onShowTeamInfo(roleInfo, round)
			end})
		end

		teamPanel:get("imgFlag"):hide()
		if not canShowResult and isInBattle(self.round:read()) then
			local x, y = teamPanel:get("imgFlag"):xy()
			local dy = -40
			if not self.isPromotion:read() and self.curTopstagePageIdx:read() <= 2 and i == 3 then
				dy = 140
			end
			widget.addAnimationByKey(teamPanel, "kuafushiying/vs.skel", "vsInfo", "effect_loop2", 6)
				:scale(2)
				:xy(x, y + dy)
		end

		if i == maxNum and canShowResult then
			isShowWinner = true
			local data = v.result == "win" and v.role1 or v.role2
			local winner = panel:get("winner")
			winner:get("normal"):hide()
			winner:get("textLv"):text("Lv" .. data.level)
			text.addEffect(winner:get("textLv"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 2}})
			text.addEffect(winner:get("textName"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 2}})
			winner:get("textName"):text(data.name)
			winner:get("textLv"):show()
			winner:get("textName"):show()
			bind.extend(self, winner:get("head"), {
				class = "role_logo",
				props = {
					logoId = data.logo,
					frameId = data.frame,
					level = false,
					vip = false,
				},
			})
			bind.click(self, winner:get("head"), {method = function()
				self:onShowTeamInfo(data, isPromotion and "top" or "final")
			end})

			if self.isRecord:read() then
				break
			end

			local children = winner:getChildren()
			for _,child in ipairs(children) do
				child:hide()
			end
			winner:get("normal"):show()
			winner:get("imgNameBg"):show()
			winner:get("imgHeadBg"):show()
			local node = winner:clone()
			children = node:getChildren()
			for _,child in ipairs(children) do
				child:hide()
			end
			local pos = gGameUI:getConvertPos(winner:get("head"), panel)
			local x, y = pos.x, pos.y
			node:xy(x, y)
			node:addTo(panel, 1000, "cloneNode")
			node:show()
			node:get("head"):show()
			bind.extend(self, node:get("head"), {
				class = "role_logo",
				props = {
					logoId = data.logo,
					frameId = data.frame,
					level = false,
					vip = false,
					onNode = function(panel)
						panel:y(panel:y() - 20)
					end
				},
			})

			local sprite = widget.addAnimationByKey(panel, "shiyingdahui/xzs_touxiang.skel", "touxiang", "xiaozusai_touxiang", 100)
				:scale(2/1.2)
				:xy(x, y)
			-- sprite:setTimeScale(0.2)

			performWithDelay(panel, function()
				panel:get("cloneNode"):stopAllActions()
				performWithDelay(panel, function()
					panel:removeChildByName("cloneNode")
					panel:removeChildByName("touxiang")
					local children = winner:getChildren()
					for _,child in ipairs(children) do
						child:show()
					end
					winner:get("normal"):hide()
				end, 1/60)
			end, 1.75)

			local action = cc.RepeatForever:create(cc.Sequence:create(
				cc.CallFunc:create(function()
					local posx, posy = sprite:getPosition()
					local boneName = "node_move"
					local sx, sy = sprite:getScaleX(), sprite:getScaleY()
					local bxy = sprite:getBonePosition(boneName)
					local rotation = sprite:getBoneRotation(boneName)
					local scaleX = sprite:getBoneScaleX(boneName)
					local scaleY = sprite:getBoneScaleY(boneName)
					node:rotate(-rotation)
						:scaleX(scaleX)
						:scaleY(scaleY)
						:xy(bxy.x * sx + posx, bxy.y * sy + posy)
				end)
			))
			node:runAction(action)
		end
	end

	for i=count + 1,maxNum do
		local team = panel:get("team" .. i)
		team:get("item1.imgFlag"):hide()
		team:get("item1.textLv"):hide()
		team:get("item1.textName"):hide()
		team:get("item1.normal"):show()
		team:get("item2.imgFlag"):hide()
		team:get("item2.textLv"):hide()
		team:get("item2.textName"):hide()
		team:get("item2.normal"):show()
		team:get("btnReplay"):hide()
		team:get("imgFlag"):hide()
		team:get("win"):hide()
		team:get("fail"):hide()
		text.addEffect(team:get("item1.normal.textNote"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 2}})
	end

	if not isShowWinner then
		panel:get("winner.textLv"):hide()
		panel:get("winner.textName"):hide()
		panel:get("winner.normal"):show()
	end
end

function CrossCraftMainScheduleFinalView:initTopStageView(data)
	local roleFigure = gRoleFigureCsv
	local cardsCfg = csv.cards
	local unitCfg = csv.unit
	local panel = self.half2
	local canShowResult = self:canShowResult(data)
	local paths = {}
	panel:get("btnReplay"):visible(canShowResult)
	if canShowResult then
		paths[1] = data.result == "win" and "city/pvp/craft/icon_win.png" or "city/pvp/craft/icon_lose.png"
		paths[2] = data.result == "win" and "city/pvp/craft/icon_lose.png" or "city/pvp/craft/icon_win.png"
		bind.touch(self, panel:get("btnReplay"), {methods = {ended = function()
			self:onReplay(data)
		end}})
	end
	if not canShowResult and isInBattle(self.round:read()) then
		local x, y = panel:get("btnReplay"):xy()
		widget.addAnimationByKey(panel, "kuafushiying/vs.skel", "vsInfo", "effect_loop2", 6)
			:scale(2)
			:xy(x, y + 130)
	end
	for i=1,2 do
		local roleInfo = data["role" .. i]
		local player = panel:get("item" .. i)
		player:removeChildByName("card")
		player:removeChildByName("figure")
		player:get("info1.textName"):text(roleInfo.name)
		player:get("info1.textFightPoint"):text(roleInfo.display.fighting_point)
		local serName = string.format(gLanguageCsv.brackets, getServerArea(roleInfo.game_key, true))
		player:get("info1.textLvAndSer"):text("Lv" .. roleInfo.level .. " " .. serName)

		text.addEffect(player:get("info1.textName"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 2}})
		text.addEffect(player:get("info1.textFightPoint"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 2}})
		text.addEffect(player:get("info1.textLvAndSer"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 2}})
		text.addEffect(player:get("info1.textNote"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 2}})

		adapt.oneLinePos(player:get("info1.textName"), player:get("info1.imgVip"), cc.p(15, 0))
		adapt.oneLinePos(player:get("info1.textNote"), player:get("info1.textFightPoint"), cc.p(10, 0))

		local vipLv = roleInfo.vip
		player:get("info1.imgVip"):visible(vipLv > 0)
		if vipLv > 0 then
			local path = string.format("common/icon/vip/icon_vip%d.png", vipLv)
			player:get("info1.imgVip"):texture(path)
		end

		local dir = i==2 and -1 or 1
		local cardID = roleInfo.display.top_card
		local skinID = roleInfo.display.skin_id
		local unit = dataEasy.getUnitCsv(cardID, skinID)
		local figureCfg = roleFigure[roleInfo.figure]
		local size = player:size()
		local dx = i==2 and 200 or 0
		local cardSprite = widget.addAnimationByKey(player, unit.unitRes, "card", "standby_loop", 2)
			:xy(size.width / 2 + 100 - dx, size.height / 5 - 15)
			:scale(unit.scale * 1.6 * dir, unit.scale * 1.6)
		cardSprite:setSkin(unit.skin)

		if string.len(figureCfg.resSpine or "") > 0 then
			widget.addAnimationByKey(player, figureCfg.resSpine, "figure", "standby_loop1", 2)
				:xy(size.width / 2 - 100 + dx, size.height / 5 - 15)
				:scale(1.1 * dir, 1.1)
		end
		bind.extend(self, player, {
			event = "extend",
			class = "role_title",
			props = {
				data = roleInfo.title,
				onNode = function(panel)
					panel:xy(size.width / 2, size.height - 100)
					panel:scale(1.3)
					panel:z(3)
				end,
			},
		})
		player:get("imgResult"):visible(canShowResult)
		if canShowResult then
			player:get("imgResult"):texture(paths[i])
		end

		bind.click(self, player, {method = function()
			self:onShowTeamInfo(roleInfo)
		end})
	end
end

function CrossCraftMainScheduleFinalView:onChangePromotionPage(list, pageIdx)
	self.view1:stopAllActions()
	self.curPromotionPageIdx:set(pageIdx)
	self.titlePath:set(self.listData1:atproxy(pageIdx).str)
end

function CrossCraftMainScheduleFinalView:onChangeTopStafePage(list, pageIdx)
	if not self.isRecord:read() and not self.isPromotion:read() and
		stringfind(self.round:read(), "final3") == nil and pageIdx > 2 then

		gGameUI:showTip(gLanguageCsv.notStartFighting)
		return
	end
	self.half1:stopAllActions()
	self.curTopstagePageIdx:set(pageIdx)
	local battleType = math.min(pageIdx, 2)
	self.titleType:set(battleType)
end

function CrossCraftMainScheduleFinalView:onChangePage(_type)
	local isPromotion = _type == FROM.promotion
	self.isPromotion:set(isPromotion)
	self.btnPromotion:setTouchEnabled(not isPromotion)
	self.btnPromotion:setBright(not isPromotion)
	self.btnFinal:setTouchEnabled(isPromotion)
	self.btnFinal:setBright(isPromotion)
	local promotionColor, finalColor = ui.COLORS.NORMAL.RED, ui.COLORS.NORMAL.WHITE
	if isPromotion then
		promotionColor, finalColor = finalColor, promotionColor
	end
	text.addEffect(self.btnPromotionNote, {color = promotionColor})
	text.addEffect(self.btnFinalNote, {color = finalColor})
	self.refresh:set(not self.refresh:read())
end

function CrossCraftMainScheduleFinalView:onEnterMySchedule()
	gGameUI:stackUI("city/pvp/cross_craft/myschedule", nil, {full = true}, true)
end

function CrossCraftMainScheduleFinalView:onShowTeamInfo(datas, round)
	gGameApp:requestServer("/game/cross/craft/battle/enemy/get", function(tb)
		gGameUI:stackUI("city.pvp.cross_craft.array_info", nil, nil, tb.view, round)
	end, datas.game_key, datas.role_db_id, datas.record_db_id)
end

function CrossCraftMainScheduleFinalView:onReplay(info)
	local interface = "/game/cross/craft/playrecord/get"
	gGameModel:playRecordBattle(info.play_id, info.cross_key, interface, 2, self.roleId)
end

return CrossCraftMainScheduleFinalView