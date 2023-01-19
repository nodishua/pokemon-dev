-- @desc:   限时PVP我的赛程

local BattleMessages = require("app.views.city.pvp.craft.battle_messages"):getInstance()

local CHANGE2BATTLEDELTA = -1
local DELAY = 10
local MINLV = csv.unlock[gUnlockCsv.craft].startLevel

local TIMES = {
	prepare = 10 * 60,
	-- prepare = 3 * 60,
	pre = 4 * 60,
	-- pre = 62,
	final = 5 * 60,
}

local function getDelta(round)
	local delta = 0
	if string.find(round, "prepare") then
		delta = TIMES.prepare
	elseif string.find(round, "pre") then
		delta = TIMES.pre
	elseif string.find(round, "final") then
		delta = TIMES.final
	end

	return delta + 1
end

local stringfind = string.find
local function isInBattle(round)
	return stringfind(round, "_lock") ~= nil
end

local function isClosed(round)
	return round == "over" or round == "closed"
end

local function adaptResPost(list, childrens, weight, children) -- 简化重复部分
	for _,name in ipairs(childrens) do
		local x = list.item:get(name):x()
		children[name]:x(x + list.deltaWidth / weight - 10)
	end
end

local function onInitItem(list, node, k, v)
	local nodeSizesize = node:size()
	node:size(nodeSizesize.width + list.deltaWidth, nodeSizesize.height)
	local bgSize = node:get("imgBg"):size()
	-- 1188是图片的宽度 *2 是因为scale是2
	node:get("imgBg"):size(1188 + list.deltaWidth / 2, bgSize.height)
	node:get("imgBg"):x((1188 * 2 + list.deltaWidth) / 2 + 20)

	list:enableSchedule()
	list:unSchedule(k)
	node:removeChildByName("_leftIcon")
	node:removeChildByName("_rightIcon")

	local children = node:multiget("imgResultL", "imgResultR", "imgIconL", "imgIconR", "imgHeroL", "imgHeroR",
		"textLvLeft", "textLvRight", "textNameLeft", "textNameRight", "textNoteLeft", "textNoteRight", "textFightPointL",
		"textFightPointR", "btnShowInfoL", "btnShowInfoR", "imgTitle", "imgBox", "btnReplay", "textTimeNote", "textTime",
		"leftIconEight1", "leftIconEight2", "leftIconEight3", "rightIconEight1", "rightIconEight2", "rightIconEight3", "imgTimeBg", "textLK")
	if v.round == "out" then
		local x, y = (1188 * 2 + list.deltaWidth) / 2, 115 / 2
		node:get("imgBg"):texture("city/pvp/craft/myschedule/bg_wdsc.png")
		node:size(cc.size(nodeSizesize.width + list.deltaWidth, 115))
		node:get("imgBg"):size(1188 + list.deltaWidth / 2, 57)
		node:get("imgBg"):xy(x, y)
		itertools.invoke(children, "hide")
		node:get("textResult"):text(v.str)
		node:get("textResult"):xy(x, y)
		node:get("textResult"):show()
		return
	end
	cache.setShader(children.imgHeroR, false, "normal")
	cache.setShader(children.imgHeroL, false, "normal")
	local rightChildren = {"imgResultR", "imgIconR", "imgHeroR", "textLvRight", "textNameRight", "textNoteRight",
		"textFightPointR","btnShowInfoR", "rightIconEight1", "rightIconEight2", "rightIconEight3"}
	local centerChildren = {"imgBox", "imgTitle", "btnReplay", "textTimeNote", "textTime"}

	adaptResPost(list, rightChildren ,1, children)
	adaptResPost(list, centerChildren ,2, children)
	
	-- 标题
	children.imgTitle:hide()
	if v.path then
		children.imgTitle:texture(v.path)
		children.imgTitle:show()
	end

	children.textFightPointL:text(v.fighting_point)
	children.textNameLeft:text(list.roleName)
	children.textLvLeft:text("lv" .. list.level)
	text.addEffect(children.textLvLeft, {outline = {color = cc.c4b(153, 46, 82, 255)}})
	text.addEffect(children.textNameLeft, {outline = {color = cc.c4b(153, 46, 82, 255)}})
	text.addEffect(children.textNoteLeft, {outline = {color = cc.c4b(153, 46, 82, 255)}})
	text.addEffect(children.textFightPointL, {outline = {color = cc.c4b(153, 46, 82, 255)}})
	text.addEffect(children.textLvRight, {outline = {color = cc.c4b(31, 92, 153, 255)}})
	text.addEffect(children.textNameRight, {outline = {color = cc.c4b(31, 92, 153, 255)}})
	text.addEffect(children.textNoteRight, {outline = {color = cc.c4b(31, 92, 153, 255)}})
	text.addEffect(children.textFightPointR, {outline = {color = cc.c4b(31, 92, 153, 255)}})
	text.addEffect(children.textLK, {outline = {color = cc.c4b(31, 92, 153, 255)}})

	local csvTab = gRoleFigureCsv
	local unitTab = csv.unit
	local cardsTab = csv.cards

	local cfg = csvTab[list.figure]
	local x, y = children.imgIconL:xy()
	local sp = cc.Sprite:create(cfg.res)
		:anchorPoint(0.5, 1)
		:xy(x, y)
		:scale(0.8)
		:addTo(node, 2, "_leftIcon")

	local size = sp:size()
	local rect = cc.rect(0 ,0, size.width, 166 * 2 / 0.8 - 11)
	sp:setTextureRect(rect)
	children.imgIconL:hide()

	local vsPath = "city/pvp/craft/vs.png"
	local isFinal = string.find(v.round, "final") ~= nil
	children.imgHeroL:visible(not isFinal)
	children.imgHeroR:visible(not isFinal)
	for i=1,3 do
		children["leftIconEight" .. i]:visible(isFinal)
		children["rightIconEight" .. i]:visible(isFinal)
	end

	-- 把对手换成sprite类型
	local x, y = children.imgIconR:xy()
	children.imgIconR:hide()

	local function createEnemy(path)
		path = path or "config/big_role/show/img_role_15@.png"
		local sp = cc.Sprite:create(path)
		:anchorPoint(0.5, 1)
		:xy(x, y)
		:scale(0.8)
		:addTo(node, 2, "_rightIcon")

		local size = sp:size()
		local rect = cc.rect(0 ,0, size.width, 166 * 2 / 0.8 - 11)
		sp:setTextureRect(rect)

		return sp
	end

	local function setEnemyInfo()
		children.textFightPointR:text(v.enemy.fighting_point)
		children.textLvRight:text("lv" .. math.max(MINLV, v.enemy.level))
		children.textNameRight:text(v.enemy.name)
	end
	local function setNotEnemy()
		children.textLvRight:text("???")
		children.textNameRight:text(gLanguageCsv.whoIsMe)
	end
	local hasEnemy = not itertools.isempty(v.enemy)
	children.textFightPointR:visible(hasEnemy)
	children.textNoteRight:visible(hasEnemy)
	children.btnShowInfoR:visible(hasEnemy)
	children.textLK:visible(not hasEnemy)
	children.textLK:x(children.rightIconEight2:x())
	if list.round:read() == "prepare" then
		children.textLK:hide()
	end
	if not isFinal then
		local unitId = dataEasy.getUnitId(v.cards[1][2],v.cards[1][3])
		local res = unitTab[unitId].cardIcon2
		children.imgHeroL:texture(res)
		if hasEnemy then
			setEnemyInfo()  -- 上下两个抽离 imgHeroR
			unitId = dataEasy.getUnitId(v.enemy.cards[1][2],v.enemy.cards[1][3])
			res = unitTab[unitId].cardIcon2
			children.imgHeroR:setColor(cc.c3b(255, 255, 255))
			children.imgHeroR:setOpacity(255)
			children.imgHeroR:texture(res)
			createEnemy(csvTab[v.enemy.figure].res)

		else
			setNotEnemy()
			children.imgHeroR:texture("config/portrait/jinglingtouxiang1/img_658_jhrw@.png")
			children.imgHeroR:setColor(cc.c3b(0, 0, 0))
			children.imgHeroR:setOpacity(125)
			local sp = createEnemy()
			sp:setColor(cc.c3b(0, 0, 0))
			sp:setOpacity(125)
		end
	else
		vsPath = "city/pvp/craft/icon_pk.png"
		for i,v in ipairs(v.cards) do

			local unit = dataEasy.getUnitCsv(v[2], v[3])
			local path = unit.iconSimple
			children["leftIconEight" .. i]:texture(path)
		end
		if not itertools.isempty(v.enemy) then
			setEnemyInfo()
			createEnemy(csvTab[v.enemy.figure].res)
			for i,v in ipairs(v.enemy.cards) do

				local unit = dataEasy.getUnitCsv(v[2], v[3])
				local path = unit.iconSimple

				children["rightIconEight" .. i]:setColor(cc.c3b(255, 255, 255))
				children["rightIconEight" .. i]:setOpacity(255)
				children["rightIconEight" .. i]:texture(path)
			end
		else
			setNotEnemy()
			for i=1,3 do
				children["rightIconEight" .. i]:setColor(cc.c3b(0, 0, 0))
				children["rightIconEight" .. i]:setOpacity(125)
			end
			local sp = createEnemy()
			sp:setColor(cc.c3b(0, 0, 0))
			sp:setOpacity(125)
		end
	end

	text.addEffect(children.textTimeNote, {outline = {color = cc.c4b(242, 48, 81, 255)}})
	text.addEffect(children.textTime, {outline = {color = cc.c4b(46, 77, 229, 255)}})

	-- 有结果就显示
	children.imgResultL:hide()
	children.imgResultR:hide()
	local boxPath = "city/pvp/craft/icon_box_vs1.png"
	if v.result then
		local resultL, resultR = "city/pvp/craft/icon_lose.png", "city/pvp/craft/icon_win.png"
		local shaderTarget = isFinal and "leftIconEight" or children.imgHeroL
		if v.result == "win" then
			resultL, resultR = resultR, resultL
			shaderTarget = isFinal and "rightIconEight" or children.imgHeroR
			boxPath = "city/pvp/craft/icon_box_vs2.png"
		end
		children.imgResultL:texture(resultL)
		children.imgResultR:texture(resultR)
		children.imgResultL:show()
		children.imgResultR:show()
		if isFinal then
			for i=1,3 do
				cache.setShader(children[shaderTarget .. i], false, "hsl_gray_white")
			end
		else
			cache.setShader(shaderTarget, false, "hsl_gray_white")
		end
	end

	--是否是当前场次的比赛 是的话不显示回放和宝箱
	local showResult = true
	local p1, p2 = string.find(list.round:read(), "^pre%d+")
	local p3, p4 = string.find(list.round:read(), "^final%d+")
	if not p1 and not p3 and not list.isRecord:read() then
		showResult = false
	elseif p1 then
		showResult = not (string.sub(list.round:read(), p1, p2) == v.round)
	elseif p3 then
		showResult = not (string.sub(list.round:read(), p3, p4) == v.round)
	end
	children.btnReplay:visible(hasEnemy and showResult)
	children.textTimeNote:visible(not showResult)
	children.textTime:visible(not showResult)
	children.imgTimeBg:visible(not showResult)
	if showResult then
		children.imgBox:texture(boxPath)
		children.imgBox:scale(2.12)
	else
		local timeNoteStr = gLanguageCsv.stateReady
		if list.round:read() == "prepare" then
			timeNoteStr = gLanguageCsv.countTime
		elseif string.find(list.round:read(), "_lock") then
			timeNoteStr = gLanguageCsv.stateFighting
		end
		children.textTimeNote:text(timeNoteStr)
		children.imgBox:texture(vsPath)
		children.imgBox:scale(1)
		local t = getDelta(v.round)

		local lastRequestTime = 0
		local function requestMain()
			-- 异常卡秒，连续请求间隔 DELAY
			if time.getTime() - lastRequestTime > DELAY then
				lastRequestTime = time.getTime()
				gGameApp:requestServer("/game/craft/battle/main")
				return true
			end
		end
		local function setLabel(delta)
			local mainRound = list.round:read()
			-- 备赛状态 减去60s （减去战斗时间）
			if delta > 60 and mainRound ~= "prepare" then
				delta = delta - 60
				children.textTimeNote:text(gLanguageCsv.stateReady)
			elseif delta <= 60 and mainRound ~= "prepare" then
				children.textTimeNote:text(gLanguageCsv.stateFighting)
			end
			local tab = time.getCutDown(delta)
			children.textTime:text(tab.min_sec_clock)
		end
		local delta = v.showTime + t - time.getTime()
		setLabel(delta)
		list:schedule(function()
			local delta = v.showTime + t - time.getTime()
			local mainRound = list.round:read()
			-- 请求之后list.round 会改变 这边来判断是否要退出schedule
			-- 如果是从 备战改为战斗 那么 v.round 回事 list.round的子集
			if v.round ~= mainRound and not string.find(mainRound, v.round) then
				return false
			end
			-- 倒计时结束后 请求下main更新下数据 然后吧delta改成10 不然请求太频繁
			if delta < 0 then
				if requestMain() then
					return false
				end
			else
				setLabel(delta)
			end
		end, 1, 0, k)
	end

	local isPre = string.find(v.round, "pre")  -- 判断是小组赛还是淘汰赛，用于查看参赛阵容
	local state = 1
	if not isPre then
		state = 2
	end

	bind.touch(list, children.btnReplay, {methods = {ended = functools.partial(list.clickCell, k, v)}})
	bind.click(list, children.btnShowInfoL, {method = functools.partial(list.showMyInfo, k, v, state, string.find(list.round:read(), "_lock"))})
	bind.click(list, children.btnShowInfoR, {method = functools.partial(list.showEnemyInfo, k, v, state, string.find(list.round:read(), "_lock"))})
end

local ViewBase = cc.load("mvc").ViewBase
local CraftMyScheduleView = class("CraftMyScheduleView", ViewBase)

CraftMyScheduleView.RESOURCE_FILENAME = "craft_schedule.json"
CraftMyScheduleView.RESOURCE_BINDING = {
	["item"] = "item",
	["slider"] = "slider",
	["roleItem"] = "roleItem",
	["topLeftPanel.textNote1"] = "textNote1",
	["topLeftPanel.textContent"] = {
		varname = "textContent",
		binds = {
			event = "text",
			idler = bindHelper.self("winAndloseNum"),
		},
	},
	["topLeftPanel.textNote2"] = "textNote2",
	["topLeftPanel.textNum"] = {
		varname = "textNum",
		binds = {
			event = "text",
			idler = bindHelper.self("pointNum"),
		},
	},
	["list"] = {
		varname = "speList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("fightDatas"),
				item = bindHelper.self("item"),
				sliderBg = bindHelper.self("slider"),
				level = bindHelper.self("level"),
				roleName = bindHelper.self("roleName"),
				figure = bindHelper.self("figure"),
				roleItem = bindHelper.self("roleItem"),
				round = bindHelper.self("round"),
				isRecord = bindHelper.self("isRecord"),
				deltaWidth = bindHelper.self("deltaWidth"),
				asyncPreload = 4,
				backupCached = false,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					onInitItem(list, node, k, v)
				end,
				onBeforeBuild = function(list)
					if list.sliderBg:visible() then
						local listSize = list:size()
						local listX, listY = list:xy()
						local size = list.sliderBg:size()
						list.sliderBg:x(listX + listSize.width - size.width)
						local x, y = list.sliderBg:xy()
						list.sliderBg:show()
						list:setScrollBarEnabled(true)
						list:setScrollBarColor(cc.c3b(241, 59, 84))
						list:setScrollBarOpacity(255)
						list:setScrollBarAutoHideEnabled(false)
						list:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x, (listSize.height - size.height) / 2 + 5))
						list:setScrollBarWidth(size.width)
						list:refreshView()
					else
						list:setScrollBarEnabled(false)
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onReplay"),
				showMyInfo = bindHelper.self("onShowMyInfo"),
				showEnemyInfo = bindHelper.self("onShowEnemyInfo"),
				replayRecord = bindHelper.self("onItemPlayRecord"),
			},
		},
	},
	["btnMainSchedule"] = {
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("isRecord"),
				method = function(val)
					return not val
				end,
			},
			{
				event = "touch",
				methods = {ended = bindHelper.self("onMainSchedule")},
			},
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
	["btns.btnRankReward"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnReward")},
		},
	},
	["btns.btnRecord"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlayRecord")},
		},
	},
	["btns.btnShop"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnShop")},
		},
	},
	["btns.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRule")},
		},
	},
	["btns.btnRule.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["btns.btnRankReward.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["btns.btnRecord.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["btns.btnBet.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["btns.btnShop.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["leftDown"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isRecord")
		},
	},
	["leftDown.btnMainSchedule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onMainSchedule")}
		},
	},
	["leftDown.btnMySchedule"] = {
		binds = {
			event = "touch",
			idler = bindHelper.self("onMySchedule")
		},
	},
	["leftDown.btnMySchedule.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
}

function CraftMyScheduleView:onCreate(isRecord)
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.craft, subTitle = "INDIGO PLATEAU CONFERENCE"})

	local first = true

	self.deltaWidth = adapt.centerWithScreen("left", "right", nil,{
		{self.speList, "pos","left"},
		{self.speList, "width"},
	})
	self.isRecord = idler.new(isRecord)

	self:initModel()
	self.rounds = {}
	self.fightDatas = idlers.newWithMap({})
	self.winAndloseNum = idler.new(string.format(gLanguageCsv.winAndLoseNum, 0, 0))
	self.pointNum = idler.new(self.info:read().point)

	-- 初始化设置计数，idler同一帧多个触发时序问题，以最后一个为准
	local count = -1
	idlereasy.any({self.history, self.vsinfo, self.curTime, self.round, self.info}, function(_, history, vsinfo, curTime, round, info)
		local function dothing()
			if not isRecord and (round == "over" or round == "closed") then
				gGameUI:goBackInStackUI("city.adventure.pvp")
				gGameUI:stackUI("city.pvp.craft.view", nil, {full = true})
				return
			end
			self.rounds = {}
			local fightDatas = {}
			-- 若积分0 并且第一个history时间超过1天则清空history
			if info.point == 0 and history[1] and (time.getTime() - history[1].time > 24 * 3600) then
				history = {}
			end
			local len = #history
			local count = 0
			for i=len, 1, -1 do
				local data = clone(history[i])
				table.insert(self.rounds, data.round)
				data.path = self:getTitleRes(data.round)
				data.showTime = curTime
				table.insert(fightDatas, data)
				count = count + 1
			end
			local margin = self.speList:getItemsMargin()
			local itemHeight = self.item:size().height
			local height = count * itemHeight + (count - 1) * margin

			if not isRecord then
				local isBattle = isInBattle(round)
				local isClose = isClosed(round)
				-- 还没有匹配到对手 或者 匹配到对手 但是在history中还没有
				local curStatrStr = round
				if isBattle then
					local tab = string.split(round, "_")
					curStatrStr = tab[1]
				end
				if not isClose and self.isSignup and not info.isout and not itertools.include(self.rounds, curStatrStr) then
					local str = string.format("craft, info.isout(%s), round(%s), vsinfo.round(%s), history(len:%d)\nhistory:last(%s)\nvsinfo(%s)", tostring(info.isout), round, tostring(vsinfo.round), len, dumps(history[len]), dumps(vsinfo))
					-- print(str)
					-- 轮空不显示
					if not itertools.isempty(vsinfo.round) then
						assertInWindows(round == vsinfo.round, str)
					end
					local t = {}
					t.figure = info.figure
					t.showTime = curTime
					local cards, fightPoint = self:getCardsByRound()
					t.cards = cards
					t.fighting_point = fightPoint
					t.round = curStatrStr
					t.enemy = vsinfo
					t.path = self:getTitleRes(curStatrStr)
					table.insert(fightDatas, 1, t)
					height = height + margin + itemHeight
				end
				-- 历史回顾 不需要出局的提示
				-- history里面没数据 并且没报名
				if not self.isSignup or info.isout then
					local str = string.format(gLanguageCsv.craftIsOver, (info.win or 0), math.min(info.round or 0, 13) - (info.win or 0))
					if not self.isSignup then
						str = gLanguageCsv.noSignupCantBattle
						-- 没有报名需要客户端吧history数据清理掉
						fightDatas = {}
						-- 没有报名的玩家首次进入，自动弹出小组赛/淘汰赛界面
						if first then
							first = false
							self:onMainSchedule()
						end
					end
					table.insert(fightDatas, 1, {round = "out", str = str})
					height = height + margin + 115
				end
				if info.isout then
					self:enableSchedule()
					self:unSchedule(1010)
					local delta = getDelta(round)
					delta = curTime + delta - time.getTime()
					if delta < 0 then
						delta = DELAY
					end
					self:schedule(function()
						delta = delta - 1
						if delta <= 0 then
							delta = DELAY
							gGameApp:requestServer("/game/craft/battle/main")
						end
					end, 1, 0, 1010)
				end
			-- history 里面有数据就显示
			elseif len == 0 and not self.isSignup then
				-- 没有报名需要客户端吧history数据清理掉
				fightDatas = {}
				table.insert(fightDatas, 1, {round = "out", str = gLanguageCsv.notSignupCantShowBattleReport})
				height = height + margin + 115
			end
			self.slider:visible(height > self.speList:size().height)
			self.fightDatas:update(fightDatas)
			self.winAndloseNum:set(string.format(gLanguageCsv.winAndLoseNum, (info.win or 0), math.min(info.round or 0, 13) - (info.win or 0)))
			self.pointNum:set(info.point)
		end
		if count < 0 then
			count = 0
			dothing()
			return
		end
		count = count + 1
		performWithDelay(self, function()
			count = count - 1
			if count > 0 then return end
			dothing()
		end, 0)
	end)
	if matchLanguage({"en"}) then
		adapt.oneLinePos(self.textNote2,self.textNum, cc.p(6, 0), "left")
	end
end

function CraftMyScheduleView:initModel()
	self.roleId = gGameModel.role:read('id')
	self.craft_record_db_id = gGameModel.role:read('craft_record_db_id')
	self.level = gGameModel.role:read('level')
	self.roleName = gGameModel.role:read("name")
	self.figure = gGameModel.role:read("figure")
	local craftData = gGameModel.craft
	self.round = craftData:getIdler("round")
	self.curTime = craftData:getIdler("time")
	self.history = craftData:getIdler("history")
	self.top8 = craftData:getIdler("top8_plays")
	self.info = craftData:getIdler("info")
	self.cardAttrs = self.info:read().card_attrs
	-- 是否报名
	self.isSignup = gGameModel.daily_record:read("craft_sign_up")
	self.vsinfo = craftData:getIdler("vsinfo")
end

function CraftMyScheduleView:getCardsByRound()
	local round = self.round:read()
	local pos1, pos2 = string.find(round, "^pre%d+")
	local pos3, pos4 = string.find(round, "^final%d+")
	local data = {}
	local fightPoint = 0
	if pos1 or round == "prepare" then
		local num = 1
		if pos1 then
			num = string.sub(round, pos1 + 3, pos2)
		end
		local dbId = self.info:read().cards[tonumber(num)]
		if dbId then
			local card = self.cardAttrs[dbId]
			local cardId = card.card_id
			local skinId = card.skin_id
			local t = {dbId,cardId,skinId}
			table.insert(data, t)
			fightPoint = card.fighting_point
		end
	elseif pos3 then
		local num = string.sub(round, pos3 + 5, pos4)
		local endPos = tonumber(num) * 3
		local stratPos = endPos - 2
		for i=stratPos,endPos do
			local dbId = self.info:read().cards[i]
			if dbId then
				local card = self.cardAttrs[dbId]
				local cardId = card.card_id
				local skinId = card.skin_id
				local t = {dbId,cardId,skinId}
				table.insert(data, t)
				fightPoint = fightPoint + card.fighting_point
			end
		end
	end

	return data, fightPoint
end

function CraftMyScheduleView:getTitleRes(round)
	round = round or self.round:read()
	local pos1, pos2 = string.find(round, "^pre%d+")
	if pos1 or round == "prepare" then
		local str = 1
		if pos1 then
			str = string.sub(round, pos1 + 3, pos2)
		end
		return "city/pvp/craft/myschedule/txt_yxs" .. str .. ".png"
	end
	if round == "final1" then
		return "city/pvp/craft/myschedule/txt_sqs1.png"
	elseif round == "final2" then
		return "city/pvp/craft/myschedule/txt_bjs1.png"
	elseif round == "final3" then
		local history = self.history:read()[12]
		if not history then
			return
		end
		local result = history.result
		local path = "city/pvp/craft/myschedule/txt_jjs.png"
		if result == "win" then
			path = "city/pvp/craft/myschedule/txt_gjs1.png"
		end

		return path
	end

	return nil
end

function CraftMyScheduleView:onEnterEmbattle(list, k, v)
	if not self.isSignup then
		gGameUI:showTip(gLanguageCsv.notSignUp)
		return
	end
	if self.info:read().isout then
		gGameUI:showTip(gLanguageCsv.isOutCantEnterEmbattle)
		return
	end
	gGameUI:stackUI("city.pvp.craft.embattle", nil, {full = true}, self.isRecord:read(), k)
end

function CraftMyScheduleView:onMainSchedule()
	local round = self.round:read()
	local isPre = string.find(round, "pre")
	if isPre then
		gGameUI:stackUI("city.pvp.craft.mainschedule", nil, {full = true})
	elseif not gGameUI:goBackInStackUI("city.pvp.craft.mainschedule_eight") then
		gGameUI:stackUI("city.pvp.craft.mainschedule_eight", nil, {full = true}, self.isRecord:read())
	end
end

function CraftMyScheduleView:onShowEnemyInfo( list, k, v, state )
	gGameApp:requestServer("/game/craft/battle/enemy/get",function (tb)
		gGameUI:stackUI("city.pvp.craft.enemy_embattle", nil, nil, tb.view, state)
	end, v.enemy.role_db_id, v.enemy.record_db_id)
end

function CraftMyScheduleView:onShowMyInfo( list, k, v, state )
	gGameApp:requestServer("/game/craft/battle/enemy/get",function (tb)
		gGameUI:stackUI("city.pvp.craft.enemy_embattle", nil, nil, tb.view, state)
	end, self.roleId, self.craft_record_db_id)
end

function CraftMyScheduleView:onBtnBet()
	gGameApp:requestServer("/game/craft/bet/info",function (tb)
		gGameUI:stackUI("city.pvp.craft.bet", nil, nil, tb.view)
	end)
end

function CraftMyScheduleView:onBtnReward()
	gGameApp:requestServer("/game/rank",function (tb)
		gGameUI:stackUI("city.pvp.craft.rank", nil, nil, tb.view)
	end, "craft", 0, 50)
end

function CraftMyScheduleView:onPlayRecord()
	gGameUI:showTip(gLanguageCsv.craftRankGaming)
end

function CraftMyScheduleView:onReplay(list, k, v)
	local interface = "/game/craft/playrecord/get"
	gGameModel:playRecordBattle(v.prid, nil, interface, 2, self.roleId)
end

function CraftMyScheduleView:onBtnShop()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/fixshop/get", function(tb)
			gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.CRAFT_SHOP)
		end)
	end
end

function CraftMyScheduleView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function CraftMyScheduleView:getRuleContext(view)
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

function CraftMyScheduleView:onClose()
	if self.isRecord:read() and gGameUI:goBackInStackUI("city.pvp.craft.view") then
		return
	end
	ViewBase.onClose(self)
end

return CraftMyScheduleView