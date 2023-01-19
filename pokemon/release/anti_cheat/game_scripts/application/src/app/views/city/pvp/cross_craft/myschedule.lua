-- @desc:   跨服PVP我的赛程

local CrossCraftMainView = require "app.views.city.pvp.cross_craft.view"

local strfind = string.find

local function isInBattle(round)
	return strfind(round, "_lock") ~= nil
end

local function isClosed(round)
	return round == "over" or round == "closed"
end

local function adaptResPost(list, childrens, data, children)
	for _,name in ipairs(childrens) do
		local x = list.item:get("fight"):get(name):x()
		children[name]:x(x + data)
	end
end

local function onInitItem(list, node, k, v)
	local nodeSizesize = list.item:size()
	local itemHeight = 415
	if v.round == "time" then
		itemHeight = 260
	elseif v.round == "out" then
		itemHeight = 120
	elseif not v.paths then
		itemHeight = 349
	end
	node:size(nodeSizesize.width + list.deltaWidth, itemHeight)
	node:get("ended"):size(nodeSizesize.width + list.deltaWidth, itemHeight)
	node:get("time"):size(nodeSizesize.width + list.deltaWidth, itemHeight)
	node:get("fight"):size(nodeSizesize.width + list.deltaWidth, itemHeight)

	node:get("time"):xy((nodeSizesize.width + list.deltaWidth) / 2, itemHeight / 2)
	node:get("fight"):xy((nodeSizesize.width + list.deltaWidth) / 2, itemHeight / 2)
	node:get("ended"):xy((nodeSizesize.width + list.deltaWidth) / 2, itemHeight / 2)

	node:get("time"):visible(v.round == "time")
	node:get("fight"):visible(v.round ~= "out" and v.round ~= "time")
	node:get("ended"):visible(v.round == "out")
	node:get("fight.title"):visible(v.paths ~= nil)

	local bgSize = node:get("fight.imgBg"):size()
	-- 1207是图片的宽度 *2 是因为scale是2
	node:get("fight.imgBg"):size(1207 + list.deltaWidth / 2, bgSize.height)
	node:get("fight.imgBg"):x((1207 * 2 + list.deltaWidth) / 2)

	list:enableSchedule()
	list:unSchedule(k)
	node:get("fight"):removeChildByName("_leftIcon")
	node:get("fight"):removeChildByName("_rightIcon")

	local children = node:get("fight"):multiget("imgResultL", "imgResultR", "imgIconL", "imgIconR", "infoL", "infoR",
		"imgTitle", "imgBox", "btnReplay", "textNote", "textTime","imgLeftIcon1", "imgLeftIcon2", "imgLeftIcon3",
		"imgRightIcon1", "imgRightIcon2", "imgRightIcon3", "title")
	local roundStatus = {
		["out"] = function()
			local x, y = (1206 * 2 + list.deltaWidth) / 2, 120 / 2
			node:get("ended.imgBg"):size(1206 + list.deltaWidth / 2, 76)
			node:get("ended.imgBg"):xy(node:get("ended"):size().width / 2, y)
			node:get("ended.textTip"):text(v.str)
			node:get("ended.textTip"):xy(x, y)
			return
		end,
		["time"] = function()
			local centerChildren = {"textNote", "imgBg", "textTime"}
			for _,name in ipairs(centerChildren) do
				local x = list.item:get("time"):get(name):x()
				node:get("time"):get(name):x(x + list.deltaWidth / 2 + 15)
			end
			text.addEffect(node:get("time.textNote"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
			text.addEffect(node:get("time.textTime"), {outline = {color = ui.COLORS.OUTLINE.WHITE}})
			local mainRound = list.round:read()
			local delta = CrossCraftMainView.getNextStateTime(mainRound == "halftime" and "prepare2" or nil, true)
			node:get("time.textTime"):text(time.getCutDown(delta).str)
			list:schedule(function()
				local mainRound = list.round:read()
				-- 请求之后list.round 会改变 这边来判断是否要退出schedule
				if v.useRound ~= mainRound then
					return false
				end
				delta = CrossCraftMainView.getNextStateTime(mainRound == "halftime" and "prepare2" or nil, true)
				node:get("time.textTime"):text(time.getCutDown(delta).str)
			end, 1, 0, k)

			return
		end
	}
	if roundStatus[v.round] then
		roundStatus[v.round]()
		return
	end


	local rightChildren = {"imgResultR", "imgIconR", "infoR", "imgRightIcon1", "imgRightIcon2", "imgRightIcon3"}

	local centerChildren = {"imgBox", "imgTitle", "btnReplay", "textNote", "textTime", "title"}

	adaptResPost(list, rightChildren,  list.deltaWidth + 25, children)
	adaptResPost(list, centerChildren,  list.deltaWidth / 2 + 15, children)

	-- 标题
	children.imgTitle:hide()
	if v.path then
		children.imgTitle:texture(v.path)
		children.imgTitle:show()
	end

	if v.paths then
		children.title:get("imgTitle1"):hide()
		children.title:get("imgTitle2"):hide()
		local nodes = {}
		for i,v in ipairs(v.paths) do
			local node = children.title:get("imgTitle" .. i)
			node:texture(v)
			table.insert(nodes, node)
			node:show()
		end
		adapt.oneLineCenterPos(cc.p(250,33), nodes, cc.p(5, 0))
	end

	children.infoL:get("textFightPoint"):text(v.fighting_point)
	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
	local str = getServerArea(gameKey, true)
	children.infoL:get("textNameAndSer"):text(string.format("%s %s", list.roleName, str))
	children.infoL:get("textLv"):text("lv" .. list.level)
	text.addEffect(children.infoL:get("textLv"), {outline = {color = cc.c4b(153, 46, 82, 255)}})
	text.addEffect(children.infoL:get("textNameAndSer"), {outline = {color = cc.c4b(153, 46, 82, 255)}})
	text.addEffect(children.infoL:get("textNote"), {outline = {color = cc.c4b(153, 46, 82, 255)}})
	text.addEffect(children.infoL:get("textFightPoint"), {outline = {color = cc.c4b(153, 46, 82, 255)}})

	text.addEffect(children.infoR:get("textLv"), {outline = {color = cc.c4b(31, 92, 153, 255)}})
	text.addEffect(children.infoR:get("textNameAndSer"), {outline = {color = cc.c4b(31, 92, 153, 255)}})
	text.addEffect(children.infoR:get("textNote"), {outline = {color = cc.c4b(31, 92, 153, 255)}})
	text.addEffect(children.infoR:get("textFightPoint"), {outline = {color = cc.c4b(31, 92, 153, 255)}})
	text.addEffect(children.infoR:get("textLK"), {outline = {color = cc.c4b(31, 92, 153, 255)}})

	local csvTab = gRoleFigureCsv

	local cfg = csvTab[list.figure]
	local x, y = children.imgIconL:xy()
	local sp = cc.Sprite:create(cfg.res)
		:anchorPoint(0.5, 1)
		:xy(x, y)
		:scale(0.8)
		:addTo(node:get("fight"), 2, "_leftIcon")

	local size = sp:size()
	local rect = cc.rect(0 ,0, size.width, 166 * 2 / 0.8 - 11)
	sp:setTextureRect(rect)
	children.imgIconL:hide()


	-- 把对手换成sprite类型
	local x, y = children.imgIconR:xy()
	children.imgIconR:hide()

	local function createEnemy(path)
		path = path or "config/big_role/show/img_role_15@.png"
		local sp = cc.Sprite:create(path)
		:anchorPoint(0.5, 1)
		:xy(x, y)
		:scale(0.8)
		:addTo(node:get("fight"), 2, "_rightIcon")
		local size = sp:size()
		local rect = cc.rect(0 ,0, size.width, 166 * 2 / 0.8 - 11)
		sp:setTextureRect(rect)

		return sp
	end

	local function setEnemyInfo()
		children.infoR:get("textFightPoint"):text(v.enemy.fighting_point)
		children.infoR:get("textLv"):text("lv" .. v.enemy.level)
		local str = getServerArea(v.enemy.game_key, true)
		children.infoR:get("textNameAndSer"):text(string.format("%s %s", str, v.enemy.name))
	end
	local function setNotEnemy()
		children.infoR:get("textLv"):text("???")
		children.infoR:get("textNameAndSer"):text(gLanguageCsv.whoIsMe)
	end
	local hasEnemy = not itertools.isempty(v.enemy)
	children.infoR:get("textFightPoint"):visible(hasEnemy)
	children.infoR:get("textNote"):visible(hasEnemy)
	children.infoR:get("btnShowInfo"):visible(hasEnemy)
	children.infoR:get("textLK"):visible(not hasEnemy)
	local round = list.round:read()
	if round == "prepare" or round == "prepare2" then
		children.infoR:get("textLK"):hide()
	end

	local vsPath = "city/pvp/craft/icon_pk.png"
	for i,v in ipairs(v.cards) do
		local unit = dataEasy.getUnitCsv(v[2], v[3])
		local path = unit.iconSimple
		children["imgLeftIcon" .. i]:texture(path)
	end
	if hasEnemy then
		setEnemyInfo()
		createEnemy(csvTab[v.enemy.figure].res)
		for i,v in ipairs(v.enemy.cards) do
			local unit = dataEasy.getUnitCsv(v[2], v[3])
			local path = unit.iconSimple
			children["imgRightIcon" .. i]:setColor(cc.c3b(255, 255, 255))
			children["imgRightIcon" .. i]:setOpacity(255)
			children["imgRightIcon" .. i]:texture(path)
		end
	else
		setNotEnemy()
		for i=1,3 do
			children["imgRightIcon" .. i]:setColor(cc.c3b(0, 0, 0))
			children["imgRightIcon" .. i]:setOpacity(125)
		end
		local sp = createEnemy()
		sp:setColor(cc.c3b(0, 0, 0))
		sp:setOpacity(125)
	end

	text.addEffect(children.textNote, {outline = {size = 3, color = cc.c4b(34, 15, 52, 255)}})
	text.addEffect(children.textTime, {outline = {size = 3, color = cc.c4b(34, 15, 52, 255)}})

	children.imgResultL:hide()
	children.imgResultR:hide()

	--是否是当前场次的比赛 是的话不显示回放和宝箱
	local showResult = true
	local mainRound = list.round:read()
	local lockPos = strfind(mainRound, "_lock$")
	if lockPos then
		mainRound = string.sub(mainRound, 1, lockPos - 1)
	end
	local hash = arraytools.hash(game.CROSS_CRAFT_ROUNDS, true)
	if not list.isRecord:read() then
		showResult = hash[mainRound] > hash[v.round]
	end

	children.btnReplay:visible(showResult and hasEnemy)
	children.textNote:visible(not showResult and not strfind(v.round, "prepare"))
	children.textTime:visible(not showResult and not strfind(v.round, "prepare"))
	if showResult then
		local boxPath = "config/item/icon_lmdh2.png"
		if v.result then
			local resultL, resultR = "city/pvp/craft/icon_lose.png", "city/pvp/craft/icon_win.png"
			local shaderTarget = "imgLeftIcon"
			if v.result == "win" then
				resultL, resultR = resultR, resultL
				shaderTarget = "imgRightIcon"
				boxPath = "config/item/icon_lmdh1.png"
			end
			children.imgResultL:texture(resultL)
			children.imgResultR:texture(resultR)
			children.imgResultL:show()
			children.imgResultR:show()
			for i=1,3 do
				cache.setShader(children[shaderTarget .. i], false, "hsl_gray_white")
			end
		end
		children.imgBox:texture(boxPath)
		children.imgBox:scale(2)
	elseif not strfind(v.round, "prepare") then
		children.imgBox:hide()

		-- 请求之后 如果round没有变 并且已经超过一场战斗的时间 默认为10s
		local delta = CrossCraftMainView.getNextStateTime(nil, true)
		local tab = time.getCutDown(delta)
		children.textNote:text("")
		local spine = widget.addAnimationByKey(node:get("fight"), "kuafushiying/vs.skel", "vsSpine", "effect_loop", 3)
			:scale(2)
		local spineRound = nil
		local function setLabel(round)
			local isBattle = isInBattle(round)
			local str = gLanguageCsv.stateReady
			if isBattle then
				str = gLanguageCsv.stateFighting
			end
			children.textNote:text(str .. ":")
			local tab = time.getCutDown(delta)
			children.textTime:text(tab.min_sec_clock)
			if spineRound ~= round then
				spineRound = round

				local spineName = "effect_loop"
				local offy = -15
				if isInBattle(round) then
					spineName = "effect_loop2"
					offy = -40
				end
				local px, py = children.imgBox:xy()
				spine:xy(px, py + offy):play(spineName)
			end
		end
		setLabel(list.round:read())
		list:schedule(function()
			delta = CrossCraftMainView.getNextStateTime(nil, true)
			local mainRound = list.round:read()
			local round = mainRound
			local lockPos = strfind(round, "_lock$")
			if lockPos then
				round = string.sub(round, 1, lockPos - 1)
			end
			-- 请求之后list.round 会改变 这边来判断是否要退出schedule
			if v.round ~= mainRound and v.round ~= round then
				return false
			end
			setLabel(list.round:read())
		end, 1, 0, k)
	else
		children.imgBox:hide()
		local px, py = children.imgBox:xy()
		widget.addAnimationByKey(node:get("fight"), "kuafushiying/vs.skel", "vsSpine", "effect_loop", 3)
			:scale(2)
			:xy(px, py - 15)
	end
	adapt.oneLineCenterPos(cc.p(700, 50), {children.infoL:get("textNote"),children.infoL:get("textFightPoint")}, cc.p(10, 0))
	adapt.oneLineCenterPos(cc.p(250, 50), {children.infoR:get("textNote"),children.infoR:get("textFightPoint")}, cc.p(10, 0))

	bind.touch(list, children.btnReplay, {methods = {ended = functools.partial(list.clickCell, k, v)}})
	bind.click(list, children.infoL, {method = functools.partial(list.showMyInfo, k, v)})
	if not itertools.isempty(v.enemy) then
		bind.click(list, children.infoR, {method = functools.partial(list.showEnemyInfo, k, v)})
	end
end

local ViewBase = cc.load("mvc").ViewBase
local CrossCraftMainScheduleView = class("CrossCraftMainScheduleView", ViewBase)

CrossCraftMainScheduleView.RESOURCE_FILENAME = "cross_craft_myschedule.json"
CrossCraftMainScheduleView.RESOURCE_BINDING = {
	["recordBg"] = {
		varname = "recordBg",
		binds = {
			event = "visible",
			idler = bindHelper.self("isRecord"),
		},
	},
	["info"] = "infoPanel",
	["item"] = "item",
	["slider"] = "slider",
	["info.textNote1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["info.textNote2"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["info.textVal1"] = {
		varname = "textVal1",
		binds = {
			{
				event = "text",
				idler = bindHelper.self("winAndloseNum"),
			},
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
			},
		},
	},
	["info.textVal2"] = {
		varname = "textVal2",
		binds = {
			{
				event = "text",
				idler = bindHelper.self("pointNum"),
			},
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
			},
		},
	},
	["listview"] = {
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
				round = bindHelper.self("round"),
				isRecord = bindHelper.self("isRecord"),
				deltaWidth = bindHelper.self("deltaWidth"),
				info = bindHelper.self("info"),
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
}

local function needTitle(round, mainRound)
	local p1, p2 = strfind(round, "^pre[1-4]")
	local p3, p4 = strfind(round, "^top%d+")
	local p5, p6 = strfind(round, "^final%d+")
	local curType, nextType
	if p1 then
		return strfind(mainRound, round) or string.sub(round, p2 + 1, p2 + 1) == "4"
	elseif p3 and string.sub(round, p3 + 3, p4) == "16" then
		return strfind(mainRound, round) or true
	elseif p5 and string.sub(round, p5 + 5, p6) == "3" then
		return strfind(mainRound, round) or true
	end

	return false
end

function CrossCraftMainScheduleView:onCreate(isRecord)
	if isRecord then
		gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
			:init({title = gLanguageCsv.crossCraft, subTitle = "CROSS - INDIGO PLATEAU CONFERENCE"})
	end
	self.deltaWidth = adapt.centerWithScreen("left", "right", nil,{
		{self.speList, "pos","left"},
		{self.speList, "width"},
		{self.infoPanel, "pos", "left"}
	})
	self.isRecord = idler.new(isRecord)

	widget.addAnimationByKey(self.recordBg, "kuafushiying/bj.skel", "recordBg", "effect_loop", 1)
		:scale(2)
		:alignCenter(self.recordBg:size())

	self:initModel()
	self.rounds = {}
	self.titleTypeCache = {}
	self.fightDatas = idlers.newWithMap({})
	self.winAndloseNum = idler.new(string.format(gLanguageCsv.winAndLoseNum, 0, 0))
	self.pointNum = idler.new(0)
	-- 初始化设置计数，idler同一帧多个触发时序问题，以最后一个为准
	local count = -1
	idlereasy.any({self.history, self.vsinfo, self.curTime, self.round, self.info, self.infoCards, self.cardAttrs}, function(_, history, vsinfo, curTime, round, info)
		local function dothing()
			if not isRecord and (round == "over" or round == "closed") then
				return
			end
			local margin = self.speList:getItemsMargin()
			local height = 0
			-- 第二天的准备时间是个特例需要特殊处理
			self.rounds = {"halftime"}
			self.titleTypeCache = {}
			local fightDatas = {}
			local len = #history
			local count = 0
			local winCount, failCount, allPointNum = 0, 0, 0
			for i=len, 1, -1 do
				count = count + 1
				local data = clone(history[i])
				table.insert(self.rounds, data.round)
				data.path = self:getTitleRes(data.round)
				data.showTime = curTime
				if needTitle(data.round, round) then
					local paths = self:getItemTitle(data.round)
					data.paths = paths
				end
				table.insert(fightDatas, data)
				local h = 415
				if not paths then
					h = 349
				end
				height = height + h
				if data.result == "win" then
					winCount = winCount + 1
				elseif data.result == "fail" then
					failCount = failCount + 1
				end
				allPointNum = allPointNum + data.point
			end
			height = height + (count - 1) * margin
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
					local t = {}
					t.figure = info.figure
					t.showTime = curTime
					local cards, fightPoint = self:getCardsByRound()
					t.cards = cards
					t.fighting_point = fightPoint
					t.round = round
					t.enemy = vsinfo
					t.path = self:getTitleRes(curStatrStr)
					local paths = self:getItemTitle(curStatrStr)
					t.paths = paths

					table.insert(fightDatas, 1, t)
					local h = 415
					if not paths then
						h = 349
					end
					height = height + margin + h
				end
				-- 准备界面倒计时
				if round == "prepare" then
					table.insert(fightDatas, {showTime = curTime, round = "time", useRound = round})
				end
				-- 中场休息倒计时
				if (self.isSignup and not info.isout) and (round == "halftime" or round == "prepare2") then
					table.insert(fightDatas, 1, {showTime = curTime, round = "time", useRound = round})
					local str = string.format(gLanguageCsv.crossCrafthalfTimeTip, winCount, failCount, allPointNum)
					table.insert(fightDatas, 1, {round = "out", str = str})
					height = height + 2 * margin + 260 + 120
				end
				-- 历史回顾 不需要出局的提示
				-- history里面没数据 并且没报名
				if (len == 0 and not self.isSignup) or info.isout then
					local str = string.format(gLanguageCsv.crossCraftOutTip, winCount, failCount)
					if not self.isSignup then
						str = gLanguageCsv.noSignupCantBattle
						-- 没有报名需要客户端吧history数据清理掉
						fightDatas = {}
					end
					table.insert(fightDatas, 1, {round = "out", str = str})
					height = height + margin + 120
				end
			end
			self.slider:visible(height > self.speList:size().height)
			self.fightDatas:update(fightDatas)
			self.winAndloseNum:set(string.format(gLanguageCsv.winAndLoseNum, winCount, failCount))
			self.textVal1:text(self.winAndloseNum:read())
			self.pointNum:set(allPointNum)
			self.textVal2:text(self.pointNum:read())
			adapt.oneLinePos(self.infoPanel:get("textNote1"), {self.infoPanel:get("textVal1"),self.infoPanel:get("textNote2"),self.infoPanel:get("textVal2")}, {cc.p(5, 0),cc.p(50, 0),cc.p(5, 0)})
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
end

function CrossCraftMainScheduleView:initModel()
	self.roleId = gGameModel.role:read('id')
	self.level = gGameModel.role:read('level')
	self.roleName = gGameModel.role:read("name")
	self.figure = gGameModel.role:read("figure")

	local craftData = gGameModel.cross_craft
	self.round = craftData:getIdler("round")
	self.curTime = craftData:getIdler("time")
	self.history = craftData:getIdler("history")
	self.info = craftData:getIdler("info")
	self.servers = craftData:getIdler("servers")
	self.infoCards = craftData:getIdler("cards")
	self.cardAttrs = craftData:getIdler("card_attrs")
	self.vsinfo = craftData:getIdler("vsinfo")

	-- self.round = idler.new("prepare2")

	-- 是否报名
	self.isSignup = CrossCraftMainView.isSigned()
end

function CrossCraftMainScheduleView:getCardsByRound()
	local round = self.round:read()
	local pos1, pos2 = strfind(round, "^pre%d+")
	local pos5, pos6 = strfind(round, "^top%d+")
	local pos3, pos4 = strfind(round, "^final%d+")
	local data = {}
	local fightPoint = 0
	if pos1 or pos5 or pos3 or (round == "prepare" or round == "prepare2") then
		local num = 1
		if pos1 then
			num = tonumber(string.sub(round, pos1 + 3, pos2)) % 10
		elseif pos5 then
			local v = string.sub(round, pos5 + 3, pos6)
			local t = {["64"] = 1, ["32"] = 2, ["16"] = 3}
			num = t[v]
		elseif pos3 then
			num = tonumber(string.sub(round, pos3 + 5, pos4))
		end
		for i=num * 3 - 2,num * 3 do
			local dbId = self.infoCards:read()[i]
			if dbId then
				local card = self.cardAttrs:read()[dbId]
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

function CrossCraftMainScheduleView:getItemTitle(round)
	round = round or self.round:read()
	local pos1, pos2 = strfind(round, "^pre%d+")
	if pos1 or strfind(round, "prepare") then
		local paths = {"city/pvp/cross_craft/txt/txt_yxs.png"}
		local num = 11
		if round == "prepare2" then
			num = 31
		elseif pos1 then
			num = tonumber(string.sub(round, pos1 + 3, pos2))
		end
		paths[2] = "city/pvp/cross_craft/txt/txt_d" .. math.floor(num / 10) .. "l.png"

		return paths
	end

	if strfind(round, "^top%d+") then
		return {"city/pvp/cross_craft/txt/txt_jjs.png"}
	elseif strfind(round, "^final%d+") then
		return {"city/pvp/cross_craft/txt/txt_dfs.png"}
	end

	return nil
end

function CrossCraftMainScheduleView:getTitleRes(round)
	round = round or self.round:read()
	local pos1, pos2 = strfind(round, "^pre%d+")
	if pos1 or strfind(round, "prepare") then
		local str = 1
		if pos1 then
			local num = tonumber(string.sub(round, pos1 + 3, pos2))
			str = num % 10
		end

		return "city/pvp/cross_craft/txt/txt_d" .. str .. "c.png"
	end

	local pos3, pos4 = strfind(round, "^top%d+")
	if pos3 then
		local num = tonumber(string.sub(round, pos3 + 3, pos4))
		num = num / 2

		return "city/pvp/cross_craft/txt/txt_" .. num .. "qs.png"
	end

	if round == "final1" then
		return "city/pvp/cross_craft/txt/txt_4qs.png"
	elseif round == "final2" then
		return "city/pvp/cross_craft/txt/txt_bjs.png"
	elseif round == "final3" then
		local history = self.history:read()[17]
		if not history then
			return
		end
		local result = history.result
		local path = "city/pvp/cross_craft/txt/txt_jjs0.png"
		if result == "win" then
			path = "city/pvp/cross_craft/txt/txt_gjs.png"
		end

		return path
	end

	return nil
end

function CrossCraftMainScheduleView:onReplay(list, k, v)
	local interface = "/game/cross/craft/playrecord/get"
	gGameModel:playRecordBattle(v.prid, v.cross_key, interface, 2, self.roleId)
end

function CrossCraftMainScheduleView:onShowEnemyInfo(list, k, v)
	gGameApp:requestServer("/game/cross/craft/battle/enemy/get", function(tb)
		gGameUI:stackUI("city.pvp.cross_craft.array_info", nil, nil, tb.view, v.round)
	end, v.enemy.game_key, v.enemy.role_db_id, v.enemy.record_db_id)
end

function CrossCraftMainScheduleView:onShowMyInfo(list, k, v)
	if self.round:read() == "closed" then
		local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
		local roleDbId = gGameModel.role:read('id')
		local recordDbId = gGameModel.role:read("cross_craft_record_db_id")
		gGameApp:requestServer("/game/cross/craft/battle/enemy/get", function(tb)
			gGameUI:stackUI("city.pvp.cross_craft.array_info", nil, nil, tb.view, v.round)
		end, gameKey, roleDbId, recordDbId)
	else
		gGameUI:stackUI("city.pvp.cross_craft.array_info", nil, nil, nil, v.round)
	end
end

return CrossCraftMainScheduleView