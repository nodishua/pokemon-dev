-- @desc:   限时PVP主赛程八强赛

local CHANGE2BATTLE = 10
local DELAY = 10
local ALLTIMES = 5 * 60

local TIMES = {
	prepare = 10 * 60,
	pre = 4 * 60,
	final = 5 * 60,
}

-- over:除了final之外的所有状态
local PROGRESS = {
	ready = 1,
	fighting = 2,
	over = 3,
}

local PAGESTATES = {
	"group-a1",
	"group-b1",
	"third",
	"champion",
}

local SHOWRESULTSTATES = {
	"signup",
	"prepare",
	"over",
	"closed"
}

local stringfind = string.find
local function isInBattle(round)
	return stringfind(round, "_lock") ~= nil
end

local function getDelta(round)
	local delta = 0
	if string.find(round, "prepare") then
		delta = TIMES.prepare
	elseif string.find(round, "pre") then
		delta = TIMES.pre
	elseif string.find(round, "final") then
		delta = TIMES.final
	end

	return delta
end

local ViewBase = cc.load("mvc").ViewBase
local CraftMainScheduleEightView = class("CraftMainScheduleEightView", ViewBase)

CraftMainScheduleEightView.RESOURCE_FILENAME = "main_schedule_eight.json"
CraftMainScheduleEightView.RESOURCE_BINDING = {
	["pageBtns.btnGroupA.textNote"] = "textNote1",
	["pageBtns.btnGroupB.textNote"] = "textNote2",
	["pageBtns.btnThird.textNote"] = "textNote3",
	["pageBtns.btnChampion.textNote"] = "textNote4",
	["pageBtns.btnGroupA"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onChangePage(1)
			end)},
		},
	},
	["pageBtns.btnGroupB"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onChangePage(2)
			end)},
		},
	},
	["pageBtns.btnThird"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onChangePage(3)
			end)},
		},
	},
	["pageBtns.btnChampion"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onChangePage(4)
			end)},
		},
	},

	["pageBtns.btnGroupA.imgBg"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("curPageIdx"),
			method = function(val)
				return val == 1
			end,
		},
	},
	["pageBtns.btnGroupB.imgBg"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("curPageIdx"),
			method = function(val)
				return val == 2
			end,
		},
	},
	["pageBtns.btnThird.imgBg"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("curPageIdx"),
			method = function(val)
				return val == 3
			end,
		},
	},
	["pageBtns.btnChampion.imgBg"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("curPageIdx"),
			method = function(val)
				return val == 4
			end,
		},
	},
	["group"] = {
		varname = "group",
		binds = {
			event = "visible",
			idler = bindHelper.self("curPageIdx"),
			method = function(val)
				return val < 3
			end,
		},
	},
	["oneToFour"] = {
		varname = "oneToFour",
		binds = {
			event = "visible",
			idler = bindHelper.self("curPageIdx"),
			method = function(val)
				return val > 2
			end,
		},
	},
	["oneToFour.play1"] = "play1",
	["oneToFour.play2"] = "play2",
	["oneToFour.imgVs"] = "imgVs",
	["group.imgTitle"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("curPageIdx"),
			method = function(val)
				local path = "city/pvp/craft/mainschedule/txt_azs.png"
				if val == 2 then
					path = "city/pvp/craft/mainschedule/txt_bzs.png"
				end

				return path
			end,
		},
	},
	["oneToFour.imgTitle"] = {
		varname = "imgTitle",
		binds = {
			event = "texture",
			idler = bindHelper.self("curPageIdx"),
			method = function(val)
				local path = "city/pvp/craft/mainschedule/txt_jjs.png"
				if val == 4 then
					path = "city/pvp/craft/mainschedule/txt_gjs.png"
				end

				return path
			end,
		},
	},
	["inBattle"] = "inBattle",
	["inBattle.textStateNote"] = {
		varname = "textStateNote",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(242, 48, 81, 255)}}
		},
	},
	["inBattle.textTime"] = {
		varname = "inBattleTextTime",
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(46, 77, 229, 255)}}
			},
			{
				event = "text",
				idler = bindHelper.self("deltaTime"),
				method = function(val)
					local tab = time.getCutDown(val)
					return tab.str
				end,
			},
		},
	},
	["group.team1.btnReplay.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["group.team2.btnReplay.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["group.team3.btnReplay.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["oneToFour.btnReplay.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["btnMyTeam"] = {
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("isRecord"),
				method = function(val)
					if val == nil then
						val = false
					end

					return not val
				end,
			},
			{
				event = "touch",
				methods = {ended = bindHelper.self("onEnterEmbattle")},
			},
		},
	},
	["btns"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isRecord"),
			method = function(val)
				if val == nil then
					val = false
				end

				return not val
			end,
		},
	},
	["btns.btnBet"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnBet")},
		},
	},
	["btns.btnBet.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["btns.btnRankReward"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnReward")},
		},
	},
	["btns.btnRankReward.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["btns.btnRecord"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlayRecord")},
		},
	},
	["btns.btnRecord.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["btns.btnShop"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnShop")},
		},
	},
	["btns.btnShop.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["btns.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRule")},
		},
	},
	["btns.btnRule.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["leftDown"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isRecord")
		},
	},
	["leftDown.btnMySchedule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEnterMySchedule")},
		},
	},
	["leftDown.btnMainSchedule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEnterMainSchedule")},
		},
	},
	["leftDown.btnMainSchedule.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["lightEfc"] = "lightEfc",
}

function CraftMainScheduleEightView:onCreate(isRecord)
	self.isRecord = idler.new(isRecord)
	self:initModel()

	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.craft, subTitle = "INDIGO PLATEAU CONFERENCE"})

	local pageIdx = isRecord == true and 4 or 1
	if string.find(self.round:read(), "final3") ~= nil then
		pageIdx = 3
	end
	local effectName = pageIdx < 3 and "xiaozusai_loop" or "juesai_loop"
	local lightEft = widget.addAnimationByKey(self.lightEfc, "shiyingdahui/shiyingdahui.skel", "lightBg", effectName)
		:scale(2)
		:xy(100, 100)
	self.curPageIdx = idler.new(pageIdx)
	self.refresh = idler.new(false)
	idlereasy.any({self.round, self.curPageIdx, self.top8, self.curTime, self.refresh}, function(_, round, curPageIdx, top8, curTime)
		if not isRecord and (round == "over" or round == "closed") then
			return
		end
		self.oneToFour:removeChildByName("guanjunEft")
		for i=1,4 do
			text.deleteAllEffect(self["textNote" .. i])
			local color = cc.c4b(241, 59, 84, 255)
			if i == curPageIdx then
				color = cc.c4b(245, 252, 237, 255)
				text.addEffect(self["textNote" .. i], {glow = {color = ui.COLORS.GLOW.WHITE}})
			end
			text.addEffect(self["textNote" .. i], {color = color})
		end
		local isGroup = curPageIdx < 3
		local isFinal3 = string.find(round, "final3") ~= nil
		local effectName = "xiaozusai_loop"
		if isGroup then
			effectName = "xiaozusai_loop"
			local datas = {}
			self.inBattle:visible(not isRecord and not isFinal3)
			local s = curPageIdx == 1 and "a" or "b"
			local key = "group-" .. s
			local t = {}
			for i=1,3 do
				local data = top8[key .. i]
				if data then
					datas[i] = data
					-- 左右已经决出胜负直接自己构造第三租数据去显示
					if i < 3 and self:canShowResult(data.result, i) then
						t["role" .. i] = data.result == "win" and clone(data.role1) or clone(data.role2)
						datas[3] = t
					end
				end
			end
			self:setGroupPlayerInfo(datas)
		else
			local isPage3 = curPageIdx == 3
			self.play1:visible(isPage3)
			self.play2:visible(isPage3)
			self.imgVs:visible()
			self.imgTitle:visible()
			effectName = "juesai_loop"
			self.inBattle:visible(not isRecord and isFinal3)
			local key = PAGESTATES[curPageIdx]
			local data = top8[key]
			if data then
				self:setFourPlayerInfo(data)
			end
		end
		lightEft:play(effectName)
		lightEft:visible(curPageIdx <= 3)
		if curPageIdx == 4 then
			local onceEfc = widget.addAnimationByKey(self.oneToFour, "shiyingdahui/shiyingdahui.skel", "guanjunEft", "juesai", 1)
				:scale(2)
				:xy(1170, 473)
			onceEfc:setSpriteEventHandler(function(event, eventArgs)
				performWithDelay(self.oneToFour, function()
					self.oneToFour:removeChildByName("guanjunEft")
					self.play1:show()
					self.play2:show()
					self.imgVs:show()
					self.imgTitle:show()
					lightEft:show()
				end, 1/60)
			end, sp.EventType.ANIMATION_COMPLETE)
		end
		if isInBattle(round) then
			CHANGE2BATTLE = - 1
		end
		self.delta = curTime + ALLTIMES - time.getTime()
		if self.delta < 0 then
			self.delta = DELAY
		end
	end)

	self.deltaTime = idler.new(0)
	self:enableSchedule()
	self:schedule(function()
		local round = self.round:read()
		if round == "over" or round == "closed" then
			return false
		end
		self.delta = self.delta - 1
		if self.delta < 0 then
			self.delta = DELAY
			gGameApp:requestServer("/game/craft/battle/main", function()
				if self.refresh then
					self.refresh:set(not self.refresh:read(), true)
				end
			end)
		else
			local showDelta = self.delta
			-- 备赛状态 减去60s （减去战斗时间）
			if self.delta > 60 then
				showDelta = showDelta - 60
				self.textStateNote:text(gLanguageCsv.stateReady)
			-- 战斗时间下 round还不是战斗状态 并且可以发送请求 就请求一次改变round
			elseif self.delta <= 60 and not isInBattle(round) then
				self.textStateNote:text(gLanguageCsv.stateFighting)
				if CHANGE2BATTLE < 0 then
					-- 防止连续发送请求
					CHANGE2BATTLE = 10
					gGameApp:requestServer("/game/craft/battle/main", function()
						if self.refresh then
							self.refresh:set(not self.refresh:read(), true)
						end
					end)
				else
					CHANGE2BATTLE = CHANGE2BATTLE - 1
				end
			elseif self.delta <= 60 then
				self.textStateNote:text(gLanguageCsv.stateFighting)
			end
			self.deltaTime:set(showDelta)
		end
	end, 1, 0)
	if matchLanguage({"en"}) then
		adapt.oneLineCenterPos(cc.p(60, -16), {self.textStateNote, self.inBattleTextTime}, cc.p(6, 0))
	end
end

function CraftMainScheduleEightView:initModel()
	local craftData = gGameModel.craft
	self.roleId = gGameModel.role:read('id')
	self.round = craftData:getIdler("round")
	self.perRound = self.round:read()
	self.curTime = craftData:getIdler("time")
	self.top8 = craftData:getIdler("top8_plays")
	if self.isRecord:read() then
		self.top8 = craftData:getIdler("yesterday_top8_plays")
	end
	self.info = craftData:read("info")
	-- 是否报名
	self.isSignup = gGameModel.daily_record:read("craft_sign_up")
end

-- groupIdx:小组赛的场次
function CraftMainScheduleEightView:canShowResult(result, groupIdx)
	if not result or string.len(result) == 0 then
		return false
	end
	local round = self.round:read()
	local curPageIdx = self.curPageIdx:read()
	if (string.find(round, "final2") and curPageIdx < 3 and groupIdx < 3) or
		(string.find(round, "final3") and curPageIdx < 3) or itertools.include(SHOWRESULTSTATES, round) then

		return true
	end

	return false
end

function CraftMainScheduleEightView:setGroupPlayerInfo(datas)
	local count = 0
	local isShowWinner = false
	local panel = self.group
	panel:stopAllActions()
	panel:removeChildByName("cloneNode")
	panel:removeChildByName("touxiang")
	panel:get("team3"):removeChildByName("progrressBar")
	panel:get("team1"):removeChildByName("progrressBar2")
	panel:get("team2"):removeChildByName("progrressBar3")
	for i,v in ipairs(datas) do
		count = count + 1
		local teamPanel = panel:get("team" .. i)
		local canShowResult = self:canShowResult(v.result, i)
		local paths = {}
		if canShowResult then
			paths[1] = v.result == "win" and "city/pvp/craft/icon_win.png" or "city/pvp/craft/icon_lose.png"
			paths[2] = v.result == "win" and "city/pvp/craft/icon_lose.png" or "city/pvp/craft/icon_win.png"
		end
		teamPanel:get("btnReplay"):visible(canShowResult)
		teamPanel:get("win"):hide()
		teamPanel:get("fail"):hide()
		local delayTime = 0
		if i == 3 then
			if not canShowResult then
				delayTime = 0.7
				local scaleY = datas[1].result == "win" and 2 or -2
				widget.addAnimationByKey(panel:get("team1"), "shiyingdahui/jdt.skel", "progrressBar2", "effect_2", 2)
					:scaleX(2)
					:scaleY(scaleY)
					:xy(cc.p(1148, 464))
				local scaleY = datas[2].result == "win" and 2 or -2
				widget.addAnimationByKey(panel:get("team2"), "shiyingdahui/jdt.skel", "progrressBar3", "effect_2", 2)
					:scaleX(-2)
					:scaleY(scaleY)
					:xy(cc.p(-736, 464))
				for j=1,2 do
					local p = teamPanel:get("play" .. j)
					local children = p:getChildren()
					for _,child in ipairs(children) do
						child:hide()
					end
					p:getChildByName("imgBg"):show()
					p:getChildByName("null"):show()
				end
			else
				panel:get("team1"):get(datas[1].result):show()
				panel:get("team2"):get(datas[2].result):show()
			end
		end
		performWithDelay(self.group, function()
			for j=1,2 do
				local player = teamPanel:get("play" .. j)
				player:get("null"):hide()
				local roleInfo = v["role" .. j]
				player:get("textLv"):text("Lv" .. roleInfo.level)
				text.addEffect(player:get("textLv"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}})
				player:get("textName"):text(roleInfo.name)
				player:get("textFightPoint"):text(roleInfo.display.fighting_point)
				player:get("textLv"):show()
				player:get("textName"):show()
				player:get("textFightPoint"):show()
				player:get("textNote"):show()
				bind.extend(self, player,{
					class = "role_logo",
					props = {
						logoId = roleInfo.logo,
						frameId = roleInfo.frame,
						level = false,
						vip = false,
						onNode =function(panel)
							if roleInfo.frame ~= 1 then
								return
							end
							local img = panel:getChildByName("frame")
							local path = "config/portrait/frame/box_head_default.png"
							if i == 2 or (i == 3 and j == 2) then
								path = "city/pvp/craft/mainschedule/panel_head_blue.png"
							end
							img:texture(path)
						end,
					},
				})
				player:get("imgResult"):visible(canShowResult)
				if canShowResult then
					player:get("imgResult"):texture(paths[j])
					if self.isRecord:read() then
						teamPanel:get(v.result):show()
					end
					bind.click(self, teamPanel:get("btnReplay"), {method = function()
						self:onReplay(v)
					end})
				end
				bind.click(self, player, {method = function()
					self:onShowTeamInfo(roleInfo)
				end})
			end
		end, delayTime)

		if i == 3 and canShowResult then
			isShowWinner = true
			local data = v.result == "win" and v.role1 or v.role2
			local winner = panel:get("winner")
			winner:get("null"):hide()
			winner:get("imgResult"):hide()
			winner:get("textLv"):text("Lv" .. data.level)
			text.addEffect(winner:get("textLv"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}})
			winner:get("textName"):text(data.name)
			winner:get("textFightPoint"):text(data.display.fighting_point)
			winner:get("textLv"):show()
			winner:get("textName"):show()
			winner:get("textNote"):show()
			winner:get("textFightPoint"):show()
			bind.extend(self, winner, {
				class = "role_logo",
				props = {
					logoId = data.logo,
					frameId = data.frame,
					level = false,
					vip = false,
					onNode = function(panel)
						panel:scale(1.15)
						if data.frame ~= 1 then
							return
						end
						panel:getChildByName("frame"):texture("city/pvp/craft/mainschedule/box_head_purple.png")
					end,
				},
			})

			bind.click(self, winner, {method = function()
				self:onShowTeamInfo(data)
			end})
			if self.isRecord:read() then
				break
			end
			local scale = 2
			if v.result == "fail" then
				scale = -2
			end
			widget.addAnimationByKey(panel:get("team3"), "shiyingdahui/jdt.skel", "progrressBar", "effect_1", 2)
				:scale(scale)
				:xy(cc.p(640, 212))

			local children = winner:getChildren()
			for _,child in ipairs(children) do
				child:hide()
			end
			winner:get("null"):show()
			winner:get("imgBg"):show()
			local node = panel:get("winner"):clone()
			children = node:getChildren()
			for _,child in ipairs(children) do
				child:hide()
			end
			node:xy(winner:xy())
			node:addTo(panel, 1000, "cloneNode")
			node:show()
			bind.extend(self, node, {
				class = "role_logo",
				props = {
					logoId = data.logo,
					frameId = data.frame,
					level = false,
					vip = false,
					onNode = function(panel)
						if data.frame ~= 1 then
							return
						end
						panel:getChildByName("frame"):texture("city/pvp/craft/mainschedule/box_head_purple.png")
					end,
				},
			})
			local sprite = widget.addAnimationByKey(panel, "shiyingdahui/xzs_touxiang.skel", "touxiang", "xiaozusai_touxiang", 100)
				:scale(2)
				:xy(winner:xy())

			performWithDelay(self.group, function()
				panel:getChildByName("cloneNode"):stopAllActions()
				performWithDelay(self.group, function()
					panel:removeChildByName("cloneNode")
					panel:removeChildByName("touxiang")
					local children = winner:getChildren()
					for _,child in ipairs(children) do
						child:show()
					end
					winner:get("null"):hide()
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
						:scaleX(scaleX * 1.15)
						:scaleY(scaleY * 1.15)
						:xy(bxy.x * sx + posx, bxy.y * sy + posy)
				end)
			))
			node:runAction(action)
		end
	end

	for i=count + 1,3 do
		local team = panel:get("team" .. i)
		team:get("play1.imgResult"):hide()
		team:get("play1.textLv"):hide()
		team:get("play1.textName"):hide()
		team:get("play1.textNote"):hide()
		team:get("play1.textFightPoint"):hide()
		team:get("play1.null"):show()
		team:get("play2.imgResult"):hide()
		team:get("play2.textLv"):hide()
		team:get("play2.textName"):hide()
		team:get("play2.textNote"):hide()
		team:get("play2.textFightPoint"):hide()
		team:get("play2.null"):show()
		team:get("btnReplay"):hide()
		team:get("win"):hide()
		team:get("fail"):hide()
	end

	if not isShowWinner then
		self.group:get("winner.imgResult"):hide()
		self.group:get("winner.textLv"):hide()
		self.group:get("winner.textName"):hide()
		self.group:get("winner.textNote"):hide()
		self.group:get("winner.textFightPoint"):hide()
		self.group:get("winner.null"):show()
	end
end

function CraftMainScheduleEightView:setFourPlayerInfo(data)
	if not data then
		return
	end
	local roleFigure = gRoleFigureCsv
	local cardsCfg = csv.cards
	local unitCfg = csv.unit

	local panel = self.oneToFour
	local canShowResult = self:canShowResult(data.result)
	local paths = {}
	panel:get("btnReplay"):visible(canShowResult)
	if canShowResult then
		paths[1] = data.result == "win" and "city/pvp/craft/icon_win.png" or "city/pvp/craft/icon_lose.png"
		paths[2] = data.result == "win" and "city/pvp/craft/icon_lose.png" or "city/pvp/craft/icon_win.png"
		bind.click(self, panel:get("btnReplay"), {method = function()
			self:onReplay(data)
		end})
	end
	for i=1,2 do
		local roleInfo = data["role" .. i]
		local player = panel:get("play" .. i)
		player:removeChildByName("card")
		player:removeChildByName("figure")
		player:get("textName"):text(roleInfo.name)
		player:get("textFightPoint"):text(roleInfo.display.fighting_point)
		player:get("textLv"):text("Lv" .. roleInfo.level)
		local cardID = roleInfo.display.top_card
		local skinID = roleInfo.display.skin_id
		local unit = dataEasy.getUnitCsv(cardID, skinID)
		local figureCfg = roleFigure[roleInfo.figure]
		local size = player:size()
		local cardSprite = widget.addAnimationByKey(player, unit.unitRes, "card", "standby_loop", 2)
			:xy(size.width / 2 + 100, size.height / 5 - 15)
			:scale(unit.scale * 1.4)
		cardSprite:setSkin(unit.skin)

		if string.len(figureCfg.resSpine or "") > 0 then
			widget.addAnimationByKey(player, figureCfg.resSpine, "figure", "standby_loop1", 2)
				:xy(size.width / 2 - 100, size.height / 5 - 15)
				:scale(figureCfg.scale)
		end
		bind.extend(self, player, {
			event = "extend",
			class = "role_title",
			props = {
				data = roleInfo.title,
				onNode = function(panel)
					panel:xy(size.width / 2, size.height - 100)
					panel:scale(1.2)
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

function CraftMainScheduleEightView:onChangePage(pageIdx)
	if not self.isRecord:read() and pageIdx > 2 and string.find(self.round:read(), "final3") == nil then
		gGameUI:showTip(gLanguageCsv.notStartFighting)
		return
	end
	self.group:stopAllActions()
	self.curPageIdx:set(pageIdx)
end

function CraftMainScheduleEightView:onShowTeamInfo(datas)
	gGameApp:requestServer("/game/craft/battle/enemy/get",function (tb)
		gGameUI:stackUI("city.pvp.craft.enemy_embattle", nil, nil, tb.view, 2, self.delta < 0)
	end, datas.role_db_id, datas.record_db_id)
end

function CraftMainScheduleEightView:onReplay(info)
	local interface = "/game/craft/playrecord/get"
	gGameModel:playRecordBattle(info.play_id, nil, interface, 2, self.roleId)
end

function CraftMainScheduleEightView:onEnterEmbattle()
	if not self.isSignup then
		gGameUI:showTip(gLanguageCsv.notSignUp)
		return
	end
	if self.info.isout then
		gGameUI:showTip(gLanguageCsv.isOutCantEnterEmbattle)
		return
	end
	gGameUI:stackUI("city.pvp.craft.embattle", nil, {full = true})
end

function CraftMainScheduleEightView:onClose()
	ViewBase.onClose(self)
end

function CraftMainScheduleEightView:onBtnBet()
	gGameApp:requestServer("/game/craft/bet/info",function (tb)
		gGameUI:stackUI("city.pvp.craft.bet", nil, nil, tb.view)
	end)
end

function CraftMainScheduleEightView:onBtnReward()
	gGameApp:requestServer("/game/rank",function (tb)
		gGameUI:stackUI("city.pvp.craft.rank", nil, nil, tb.view)
	end, "craft", 0, 50)
end


function CraftMainScheduleEightView:onBtnShop()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/fixshop/get", function(tb)
			gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.CRAFT_SHOP)
		end)
	end
end

function CraftMainScheduleEightView:onPlayRecord()
	gGameUI:showTip(gLanguageCsv.craftRankGaming)
end

function CraftMainScheduleEightView:onBtnRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function CraftMainScheduleEightView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(112),
		c.noteText(39001, 39010),
		c.noteText(113),
		c.noteText(40001, 40005),
		c.noteText(114),
		c.noteText(41001, 41004),
		c.noteText(115),
		c.noteText(42001, 42004),
	}
	return context
end

function CraftMainScheduleEightView:onEnterMySchedule()
	gGameUI:stackUI("city.pvp.craft.myschedule", nil, {full = true}, true)
end

function CraftMainScheduleEightView:onEnterMainSchedule()

end

return CraftMainScheduleEightView