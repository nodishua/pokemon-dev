-- @date:   2020-12-23
-- @desc:   精灵问答主界面

local function randomTable(_table, _num)
    local _result = {}
    local _index = 1
    local _num = _num or #_table
    while #_table ~= 0 do
        local ran = math.random(0, #_table)
        if _table[ran] ~= nil then
            _result[_index] = _table[ran]
            table.remove(_table,ran)
            _index = _index + 1
            if _index > _num then
                break
            end
        end
    end
    return _result
end

local function getAllGrade(data)
	local grade = 0
	local qaType = csv.union_qa.qa_type
	local qaBase = csv.union_qa.qa_base
	for k, v in ipairs(data) do
		grade = grade + qaType[v.type].score * qaBase[k].multiple
	end
	return grade
end

local PROTABLE = {
	NORMAL = 1,
	MEDIUM = 2,
	DIFFICULT = 3,
	SEEPICTURE = 4,
	GAME = 5,
}

local ANSWERTABLE = {"A", "B", "C", "D"}

local CHOOSETABLE = {
	NONE = 0,
	TRUE = 1,
	FAIL = 2,
}

local DTTABLE = {
	MESS = 0.4,
	MOSAIC = 1,
	BLINK = 0.3,
}

local BAGSTATE = {
	GOLD = 0.1,
	RMB = 0.25,
	ALL = 0.5,
}

local resTable1 = {
	{res = "config/big_hero/standby/img_250_fw@.png",x = 195, y = 440},
	{res = "config/big_hero/standby/img_250_fw@.png",x = 595, y = 440},
	{res = "config/big_hero/standby/img_250_fw@.png",x = 1000, y = 440},
	{res = "config/big_hero/standby/img_250_fw@.png",x = 1405, y = 440},
	{res = "config/big_hero/standby/img_250_fw@.png",x = 195, y = 130},
	{res = "config/big_hero/standby/img_250_fw@.png",x = 595, y = 130},
	{res = "config/big_hero/standby/img_250_fw@.png",x = 1000, y = 130},
	{res = "config/big_hero/standby/img_250_fw@.png",x = 1405, y = 130},
}

local showWidth = 250

-- local mosaicNum = {3, 9, 18, 30, 100}

local ViewBase = cc.load("mvc").ViewBase
local UnionAnswerProblemView = class("UnionAnswerProblemView", ViewBase)

UnionAnswerProblemView.RESOURCE_FILENAME = "union_answer_problem.json"
UnionAnswerProblemView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["topPanel"] = "topPanel",
	["topPanel.textNum"] = "textNum",
	["topPanel.textNum1"] = "textNum1",
	["topPanel.time"] = "timeText",
	["bottomPanel"] = "bottomPanel",
	["bottomPanel.text"] = "bottomPanelText",
	["bottomPanel.bagPanel"] = "bagPanel",
	["bottomPanel.sureBtn"] = {
		varname = "sureBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("submitAnswer")},
		},
	},
	["panel1"] = "panel1",
	["panel1.item"] = "item1",
	["panel1.list"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("answerData1"),
				item = bindHelper.self("item1"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "bg", "name")
					childs.bg:get("txt"):text(ANSWERTABLE[k])
					adapt.setTextScaleWithWidth(childs.name,v.name, 1250)
					if v.state == CHOOSETABLE.NONE then
						childs.icon:hide()
					elseif v.state == CHOOSETABLE.TRUE then
						childs.icon:show()
					else
						childs.icon:texture("city/union/answer/logo_cw.png")
					end
					if v.fontType == 1 then
						childs.name:setColor(cc.c3b(255, 230, 64))
						childs.bg:texture("city/card/gem/btn_yq_h.png")
						text.addEffect(childs.bg:get("txt"), {color = ui.COLORS.NORMAL.WHITE})
					else
						childs.name:setColor(cc.c3b(255, 252, 237))
						childs.bg:texture("city/card/gem/btn_yq_b.png")
						text.addEffect(childs.bg:get("txt"), {color = ui.COLORS.NORMAL.RED})
					end
					node:setTouchEnabled(v.canTouch)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["panel1.title"] = "title1",
	["panel2"] = "panel2",
	["panel2.item"] = "item2",
	["panel2.list"] = {
		varname = "list2",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("answerData2"),
				item = bindHelper.self("item2"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "bg", "name")
					childs.bg:get("txt"):text(ANSWERTABLE[k])
					childs.name:text(csv.unit[v.name].name)
					if v.state == CHOOSETABLE.NONE then
						childs.icon:hide()
					elseif v.state == CHOOSETABLE.TRUE then
						childs.icon:show()
					else
						childs.icon:texture("city/union/answer/logo_cw.png")
					end
					if v.fontType == 1 then
						childs.name:setColor(cc.c3b(255, 230, 64))
						childs.bg:texture("city/card/gem/btn_yq_h.png")
						text.addEffect(childs.bg:get("txt"), {color = ui.COLORS.NORMAL.WHITE})
					else
						childs.name:setColor(cc.c3b(255, 252, 237))
						childs.bg:texture("city/card/gem/btn_yq_b.png")
						text.addEffect(childs.bg:get("txt"), {color = ui.COLORS.NORMAL.RED})
					end
					node:setTouchEnabled(v.canTouch)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["panel2.title"] = "title2",
	["panel3"] = "panel3",
	["panel3.item"] = "item3",
	["panel3.list"] = {
		varname = "list3",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("answerData3"),
				item = bindHelper.self("item3"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "bg", "iconBg")
					childs.bg:get("txt"):text(ANSWERTABLE[k])
					childs.iconBg:get("icon"):texture(csv.unit[v.name].show)
					local num = math.min(1, 300/childs.iconBg:get("icon"):size().height)
					childs.iconBg:get("icon"):scale(num*0.5)
					if v.state == CHOOSETABLE.NONE then
						childs.icon:hide()
					elseif v.state == CHOOSETABLE.TRUE then
						childs.icon:show()
					else
						childs.icon:texture("city/union/answer/logo_cw.png")
					end
					if v.fontType == 1 then
						childs.bg:texture("city/card/gem/btn_yq_h.png")
						text.addEffect(childs.bg:get("txt"), {color = ui.COLORS.NORMAL.WHITE})
					else
						childs.bg:texture("city/card/gem/btn_yq_b.png")
						text.addEffect(childs.bg:get("txt"), {color = ui.COLORS.NORMAL.RED})
					end
					node:setTouchEnabled(v.canTouch)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["panel3.title"] = "title3",
	["panel3.cardPanel"] = "cardPanel",
	["panel3.text"] = "seeTip",
	["panel4"] = "panel4",
	["panelBg"] = "panelBg",
	["endPanel"] = "endPanel",
}

function UnionAnswerProblemView:onCreate(parms)
	self.topUI = gGameUI.topuiManager:createView("union_answer", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.pokemonAnswer, subTitle = "POKEMONANSWER"})
	self:enableSchedule()

	local problemData, roleData, unionData, myRoleData, myUnionData= parms()
	self.problemData = problemData.questions
	self.roleData = roleData
	self.unionData = unionData
	self.myRoleData = myRoleData
	self.myUnionData = myUnionData
	self:initModel()
	local qaImg = csv.unit
	local qaType = csv.union_qa.qa_type
	local qaBase = csv.union_qa.qa_base
	--是否已经进入小游戏界面
	self.inGame = false
	--是否有看过小游戏的规则
	local titleStr = ""
	self.allGrade = getAllGrade(self.problemData)

	local function showStr(str, panel, y)
		local y = y or 0
		panel:removeAllChildren()
		rich.createWithWidth(str, 50, nil, 1237)
		:addTo(panel, 10)
		:anchorPoint(cc.p(0, 0.5))
		:xy(0, y)
		:formatText()
	end
	idlereasy.any({self.problemIndex, self.choice, self.tabNum}, function (_, problemIndex, choice, tabNum)
		local answerData = {}
		self.sureBtn:hide()
		local data = self.problemData[problemIndex]
		if data then
			if data.type <= PROTABLE.DIFFICULT then
				self.panel1:show()
				self.panel2:hide()
				self.panel3:hide()
				if #data.question <= 60 then
					self.panel1:get("title"):x(221)
				else
					self.panel1:get("title"):x(47)
				end
				if qaBase[problemIndex].multiple == 1 then
					titleStr = problemIndex.."."..data.question.."   ".."("..qaType[data.type].score..gLanguageCsv.gradeText..")"
				else
					titleStr = problemIndex.."."..data.question.."   ".."("..qaType[data.type].score..gLanguageCsv.gradeText..")".."#C0xFFE640#".." ("..gLanguageCsv.score.."x"..qaBase[problemIndex].multiple..")"
				end
				showStr(titleStr, self.panel1:get("title"), 25)
				answerData = {
					{state = 0, id = data.questionID, name = data.choices[1], canTouch = true, fontType = 0},
					{state = 0, id = data.questionID, name = data.choices[2], canTouch = true, fontType = 0},
					{state = 0, id = data.questionID, name = data.choices[3], canTouch = true, fontType = 0},
					{state = 0, id = data.questionID, name = data.choices[4], canTouch = true, fontType = 0}
				}
				if tabNum ~= 0 then
					answerData[tabNum].fontType = 1
					self.sureBtn:show()
				end
				self.answerData1:update(answerData)
				if self.inGame == false then
					self:initCountDown(data)
					self.inGame = true
				end
				self.list1:setTouchEnabled(true)
			elseif data.type == PROTABLE.SEEPICTURE then
				self.panel1:hide()
				self.panel2:show()
				self.panel3:hide()
				if qaBase[problemIndex].multiple == 1 then
					titleStr = problemIndex.."."..gLanguageCsv.pokemonAnswerQuestion2.."   ".."("..qaType[data.type].score..gLanguageCsv.gradeText..")"
				else
					titleStr = problemIndex.."."..gLanguageCsv.pokemonAnswerQuestion2.."   ".."("..qaType[data.type].score..gLanguageCsv.gradeText..")".."#C0xFFE640#".." ("..gLanguageCsv.score.."x"..qaBase[problemIndex].multiple..")"
				end
				showStr(titleStr, self.panel2:get("title"))
				self.picture = qaImg[data.question].show
				self.panel2:get("iconBg.icon"):texture(qaImg[data.question].show)
				local program = cc.GLProgram:create('shader/ver_shader.vsh', "shader/color.fsh")
				program:link()
				program:updateUniforms()
				local state = cc.GLProgramState:getOrCreateWithGLProgram(program)
				state:setUniformVec3("color", cc.vec3(50/255, 71/255, 62/255, 1))
				self.panel2:get("iconBg.icon"):setGLProgramState(state)
				answerData = {
					{state = 0, name = data.choices[1], canTouch = true, fontType = 0},
					{state = 0, name = data.choices[2], canTouch = true, fontType = 0},
					{state = 0, name = data.choices[3], canTouch = true, fontType = 0},
					{state = 0, name = data.choices[4], canTouch = true, fontType = 0}
				}
				if tabNum ~= 0 then
					answerData[tabNum].fontType = 1
					self.sureBtn:show()
				end
				self.answerData2:update(answerData)
				if self.inGame == false then
					self:initCountDown(data)
					self.inGame = true
				end
				self.list2:setTouchEnabled(true)
			else
				self.panel1:hide()
				self.panel2:hide()
				self.panel3:show()
				self.list3:setTouchEnabled(true)
				local qagame1 = csv.union_qa.qa_game1[data.gameID]
				if qaBase[problemIndex].multiple == 1 then
					titleStr = problemIndex.."."..gLanguageCsv.pokemonAnswerQuestion3.."   ".."("..qaType[data.type].score..gLanguageCsv.gradeText..")"
				else
					titleStr = problemIndex.."."..gLanguageCsv.pokemonAnswerQuestion3.."   ".."("..qaType[data.type].score..gLanguageCsv.gradeText..")".."#C0xFFE640#".." ("..gLanguageCsv.score.."x"..qaBase[problemIndex].multiple..")"
				end
				showStr(titleStr, self.panel3:get("title"))
				for i = 1, qagame1.displayNum do
					resTable1[i].res = qaImg[data.display[i]].show
				end
				for i = 1, qagame1.choiceNum do
					if i == tabNum then
						table.insert(answerData, {state = 0, name = data.choices[i], canTouch = true, fontType = 1})
						self.sureBtn:show()
					else
						table.insert(answerData, {state = 0, name = data.choices[i], canTouch = true, fontType = 0})
					end
				end
				self.answerData3:update(answerData)
			end
		else
			self.onClose(true)
		end
	end)

	idlereasy.when(self.times, function (_, times)
		if times == 0 then
			self:submitAnswer()
		end
	end)

	local num = #(self.problemData)
	idlereasy.when(self.problemIndex, function (_, problemIndex)
		self.bottomPanelText:text(problemIndex.."/"..num)
	end)
end

function UnionAnswerProblemView:initModel()
	self.problemIndex = idler.new(0)
	self.choice = idler.new(0)
	self.tabNum = idler.new(0)
	self.times = idler.new(15)
	self.counTtime = 0
	--获得的分数
	self.myGrade = 0
	self:getGrade()
	--三个小游戏的答案
	self.answerData1 = idlers.new({})
	self.answerData2 = idlers.new({})
	self.answerData3 = idlers.new({})
	self.isQuit = false
	self.needEraser = false
	self:startAnswer()
	self.rightNum = 0
	self.bagSpineState = 0
	-- 碎片复原计数
	self.messIndex = 0
	-- 马赛克复原横竖
	self.mosaicSizeX = 3
	self.mosaicSizeY = 3
	--奖励数据
	self.giftData = {}
	self.bagSpine = widget.addAnimationByKey(self.bagPanel, "union_answer/beibao.skel", "effect", "effect_loop", 999)
		:xy(-860, 650)
		:scale(2)

	-- 通过计时器获得延迟的时间
	self.timeScale = 1
	-- self:initTimeScale()
end

function UnionAnswerProblemView:startAnswer()
	self.problemIndex:set(self.problemIndex:read() + 1)
	self.tabNum:set(0)
	gGameApp:requestServer("/game/union/qa/answer/start",function(tb)
	end, self.problemIndex:read())
end

--进入小游戏前展示规则界面
function UnionAnswerProblemView:showGameRule()
	local gameRule = userDefault.getForeverLocalKey("gameRule", false)
	local data = self.problemData[self.problemIndex:read() + 1]
	local function showGame()
		if not self.isEnding then
			gGameApp:requestServer("/game/union/qa/answer/start",function(tb)
			end, self.problemIndex:read())
			self:showPanel(data)
		end
	end
	if gameRule == false then
		self.panel3:hide()
		self.panel4:show()
		self.isEraser = true
		performWithDelay(self.panel4, function()
			self.isEraser = false
			self.panel4:hide()
			self.panel3:show()
			self.problemIndex:set(self.problemIndex:read() + 1)
			self.tabNum:set(0)
			if self.inGame == true then
				showGame()
			else
				self:seeTime(data)
			end
			userDefault.setForeverLocalKey("gameRule", true)
		end, 5/self.timeScale)
	else
		self.problemIndex:set(self.problemIndex:read() + 1)
		self.tabNum:set(0)
		if self.inGame == true then
			showGame()
		else
			self:seeTime(data)
		end
	end
end

function UnionAnswerProblemView:submitAnswer()
	local problemIndex = self.problemIndex:read()
	if self.lastProblemIndex == problemIndex then
		return
	end
	self.lastProblemIndex = problemIndex
	-- self:unSchedule("countdownLess")
	self.topPanel:unscheduleUpdate()
	self.inGame = false
	gGameApp:requestServer("/game/union/qa/answer/submit",function(tb)
		self:showAnswer()
		self.sureBtn:hide()
		self:getGrade(tb.view)
	end, problemIndex, self.tabNum:read())
end

function UnionAnswerProblemView:onTabClick(list, k, v)
	self.tabNum:set(k)
end

function UnionAnswerProblemView:showAnswer()
	self.isShowAnswer = true
	local answerData = {}
	local problemData = self.problemData[self.problemIndex:read()]
	for i = 1, #problemData.choices do
		if i == problemData.answer then
			if i == self.tabNum:read() then
				table.insert(answerData, {state = 1, name = problemData.choices[i], canTouch = false, fontType = 1})
				self.rightNum = self.rightNum + 1
			else
				table.insert(answerData, {state = 1, name = problemData.choices[i], canTouch = false, fontType = 0})
			end
		else
			if i == self.tabNum:read() then
				table.insert(answerData, {state = 2, name = problemData.choices[i], canTouch = false, fontType = 1})
			else
				table.insert(answerData, {state = 0, name = problemData.choices[i], canTouch = false, fontType = 0})
			end
		end
	end
	local panel
	if problemData.type <= PROTABLE.DIFFICULT then
		self.answerData1:update(answerData)
		self.list1:setTouchEnabled(false)
		panel = self.panel1
		self:endShow(panel)
	elseif problemData.type == PROTABLE.SEEPICTURE then
		self.answerData2:update(answerData)
		self.list2:setTouchEnabled(false)
		local qaImg = csv.unit
		local data = self.problemData[self.problemIndex:read()]
		cache.setShader(self.panel2:get("iconBg.icon"), false, "normal")
		panel = self.panel2
		self:endShow(panel)
	else
		self.answerData3:update(answerData)
		panel = self.panel3
		self.list3:setTouchEnabled(false)
		self:endGame(panel)
		-- self:endShow(panel)
	end
end

function UnionAnswerProblemView:endShow(panel)
	if self.isQuit == false then
		self.isEraser = true
		performWithDelay(self.panel4, function()
			self:openEraser(panel)
		end, 2/self.timeScale)
	else
		self.needEraser = true
	end
end

function UnionAnswerProblemView:getGrade(view)
	if not view then
		self.textNum:text(0)
		return
	end
	local myGrade = self.myGrade
	self.myGrade = self.myGrade + view.result.score
	if view.result.score > 0 then
		uiEasy.storageTo({targetPos = cc.p(2300 + display.uiOrigin.x, 240)})
		if self.myGrade >= self.allGrade * BAGSTATE.GOLD and self.myGrade <= self.allGrade * BAGSTATE.RMB and self.bagSpineState == 0 then
			self.bagSpine:play("effect1")
			self.bagSpine:addPlay("effect1_loop")
			self.bagSpineState = 1
		elseif self.myGrade >= self.allGrade * BAGSTATE.RMB and self.myGrade <= self.allGrade * BAGSTATE.ALL and self.bagSpineState <= 1 then
			self.bagSpine:play("effect2")
			self.bagSpine:addPlay("effect2_loop")
			self.bagSpineState = 2
		elseif self.myGrade >= self.allGrade * BAGSTATE.ALL and self.bagSpineState <= 2 then
			self.bagSpine:play("effect3")
			self.bagSpine:addPlay("effect3_loop")
			self.bagSpineState = 3
		end
	end
	uiEasy.digitRollAction(self.textNum, myGrade, self.myGrade, nil, self.timeScale, self.textNum1)
	self.textNum1:show()
	self.textNum1:text('+'..view.result.score)
end

--玩哪个小游戏
function UnionAnswerProblemView:showPanel(data)
	if self.inGame == true then
		return
	end
	if data.gameID == 1 then
		self:gameMess()
	elseif data.gameID == 2 then
		self:mosaic()
	else
		self:blink()
	end
	self:initCountDown(data)
	self.inGame = true
	self.sureBtn:setTouchEnabled(true)
end

-- 倒计时动画
function UnionAnswerProblemView:seeTime(data)
	self.sureBtn:setTouchEnabled(false)
	if self.countSchedule then
		return
	end
	for i = 1, 8 do
		self.panel3:get("cardBg"..i):hide()
	end
	local index = 0
	local opacity = 250
	local fontSize = 160
	--记录变化的时刻，透明度和大小都复原
	local preNum = 0
	self.seeTip:scheduleUpdate(function(detal)
		if self.timeScale > 1 then
			index = index + 1*self.timeScale
		else
			index = index + 1
		end
		local num = math.modf(index/60)
		if num == 1 then
			self.seeTip:text(3)
			opacity = opacity - 3
			fontSize = fontSize + 2
			self.seeTip:setFontSize(fontSize)
			self.seeTip:setOpacity(opacity)
			preNum = num
		elseif num == 2 then
			if preNum ~= num then
				preNum = num
				opacity = 250
				fontSize = 160
			end
			self.seeTip:text(2)
			opacity = opacity - 3
			fontSize = fontSize + 2
			self.seeTip:setFontSize(fontSize)
			self.seeTip:setOpacity(opacity)
		elseif num == 3 then
			if preNum ~= num then
				preNum = num
				opacity = 250
				fontSize = 160
			end
			self.seeTip:text(1)
			opacity = opacity - 3
			fontSize = fontSize + 2
			self.seeTip:setFontSize(fontSize)
			self.seeTip:setOpacity(opacity)
		elseif num >= 4 then
			self.seeTip:hide()
			for i = 1, 8 do
				self.panel3:get("cardBg"..i):show()
			end
			self.seeTip:unscheduleUpdate()
			if not self.isEnding then
				gGameApp:requestServer("/game/union/qa/answer/start",function(tb)
				end, self.problemIndex:read())
				self:showPanel(data)
			end
			self.countSchedule = nil
		end
	end)
end

-- 倒计时
function UnionAnswerProblemView:initCountDown(data, dt)
	local dt = dt or 0
	self.counTtime = csv.union_qa.qa_type[data.type].limitTime - dt
	local timeCount = time.getTime() + self.counTtime - 1
	self.times:set(15)
	self.topPanel:scheduleUpdate(function(detal)
		self.counTtime = timeCount - time.getTime()
		-- self.timeText:text(self.counTtime)
		if self.counTtime < 0 then
			self.times:set(0)
			self.topPanel:unscheduleUpdate()
		else
			self.timeText:text(self.counTtime)
		end
	end)
end

--没使用
function UnionAnswerProblemView:initTimeScale()
	local preTime = os.time()
	local disDetal = 0
	self.bg:scheduleUpdate(function(detal)
		disDetal = disDetal + detal
		if  disDetal >= 1 then
			local nowTime = os.time()
			local disTime = (nowTime - preTime) == 0 and 1 or (nowTime - preTime)
			self.timeScale = disTime/disDetal
			preTime = nowTime
			disDetal = 0
		end
		-- local nowTime = os.time()
		-- self.timeScale = (nowTime - preTime)/disDetal
		-- preTime = nowTime
	end)
end

--碎片复原
function UnionAnswerProblemView:gameMess()
	local imgTable = {}
	self.cardPanel:removeAllChildren()
	local multiple = 2
	local distanceX = resTable1[2].x - resTable1[1].x
	local distanceY = resTable1[1].y - resTable1[5].y
	for k, v in ipairs(resTable1) do
		local res = v.res
		for i = 0, multiple*multiple - 1 do
			local res = v.res
			local index = (i + k) % 8
			local tmp1,tmp2 = math.modf(index/4)
			local x = resTable1[5].x - v.x + tmp2*4*distanceX
			local y = resTable1[5].y - v.y + tmp1*distanceY
			local imgBg1 = cc.Sprite:create(res)
				:xy(v.x, v.y)
				-- :size({height = 250, width = 250})
			if imgBg1:size().height > showWidth then
				imgBg1:size({height = showWidth, width = showWidth*imgBg1:size().width/imgBg1:size().height})
			end
			local size = imgBg1:size()
			local mask = ccui.Scale9Sprite:create()
			mask:initWithFile(cc.rect(0, 0, 0, 0), "city/union/answer/box_character2.png")
			mask:size(size)
				:xy(imgBg1:xy())
				if i == 0 then
					mask:anchorPoint(1, 0)
				elseif i == 1 then
					mask:anchorPoint(1, 1)
				elseif i == 2 then
					mask:anchorPoint(0, 0)
				else
					mask:anchorPoint(0, 1)
				end
			local imgBg = cc.ClippingNode:create(mask)
				:setAlphaThreshold(0.1)
				:add(imgBg1)
				:addTo(self.cardPanel, 3)
				:xy(x, y)
			table.insert(imgTable,{imgBg = imgBg, x = v.x, y = v.y})
		end
	end
	self.imgList = randomTable(imgTable)
	-- self.messIndex = 0
	self:messSchedule(DTTABLE.MESS)
end

function UnionAnswerProblemView:messSchedule(dt)
	self.panel3:unscheduleUpdate()
	local count = 0
	self.panel3:scheduleUpdate(function(detal)
		-- if self.timeScale > 1 then
		-- 	count = count + 0.017*self.timeScale
		-- else
		-- 	count = count + 0.017
		-- end
		count = count + 0.017
		if count > dt then
			self.messIndex = self.messIndex + 1
			if self.messIndex > #self.imgList then
				self:endShow(self.panel3)
				self.panel3:unscheduleUpdate()
				self.isEnding = false
			end
			if self.imgList[self.messIndex] then
				self.imgList[self.messIndex].imgBg:xy(0, 0)
			end
			count = 0
		end
	end)
end

--马赛克复原
function UnionAnswerProblemView:mosaic()
	self.cardPanel:removeAllChildren()
	local mosaicTable = {}
	for k, v in ipairs(resTable1) do
		local imgBg = cc.Sprite:create(v.res)
			:addTo(self.cardPanel, 3)
			:xy(v.x, v.y)
		if imgBg:size().height > showWidth then
			imgBg:size({height = showWidth, width = showWidth*imgBg:size().width/imgBg:size().height})
		end
		table.insert(mosaicTable, imgBg)
	end
	local program = cc.GLProgram:createWithFilenames('shader/ver_shader.vsh', "shader/mosaic_shader.fsh")
	program:link()
	program:updateUniforms()
	self.mosaicState = cc.GLProgramState:getOrCreateWithGLProgram(program)
	table.insert(mosaicTable, imgBg)
	self.mosaicTable = mosaicTable
	-- self.mosaicSizeX = 3
	-- self.mosaicSizeY = 3

	self.mosaicNum = 2
	self:mosaicSchedule(DTTABLE.MOSAIC)
end

function UnionAnswerProblemView:mosaicSchedule(dt)
	self.panel3:unscheduleUpdate()
	local count = dt
	self.panel3:scheduleUpdate(function(detal)
		-- if self.timeScale > 1 then
		-- 	count = count + 0.017*self.timeScale
		-- else
		-- 	count = count + 0.017
		-- end
		count = count + 0.017
		if count > dt then
			self.mosaicSizeX = self.mosaicSizeX + self.mosaicNum
			self.mosaicSizeY = self.mosaicSizeY + self.mosaicNum
			self.mosaicState:setUniformFloat("mosaicSizeX", self.mosaicSizeX)
			self.mosaicState:setUniformFloat("mosaicSizeY", self.mosaicSizeY)
			for k, v in ipairs(self.mosaicTable) do
				if self.mosaicSizeX > 1 then
					v:setGLProgramState(self.mosaicState)
				end
			end
			if self.mosaicSizeX >= 33 then
				self.mosaicState:setUniformFloat("mosaicSizeX", 300)
				self.mosaicState:setUniformFloat("mosaicSizeY", 300)
				self:endShow(self.panel3)
				self.panel3:unscheduleUpdate()
				self.isEnding = false
			end
			count = 0
		end
	end)
end

function UnionAnswerProblemView:endGame()
	if self.isEnding then
		return
	end
	self.isEnding = true
	local data = self.problemData[self.problemIndex:read()]
	if data.gameID then
		if data.gameID == 1 then
			self:messSchedule(DTTABLE.MESS/4)
		elseif data.gameID == 2 then
			self:mosaicSchedule(DTTABLE.MOSAIC/4)
		else
			if self.blinkIndex <= self.blinkTimes then
				self.blinkIndex = self.blinkTimes - 1
			end
			self:blinkSchedule(DTTABLE.BLINK)
		end
	else
		self:endShow(self.panel3)
		self.isEnding = false
	end
end

--闪现复原
function UnionAnswerProblemView:blink()
	self.cardPanel:removeAllChildren()
	local blinkTable = {}
	for k, v in ipairs(resTable1) do
		local imgBg1 = cc.Sprite:create(v.res)
				:addTo(self.cardPanel, 3)
				:xy(v.x, v.y)
				-- :size({height = 250, width = 250})
		imgBg1:hide()
		if imgBg1:size().height > showWidth then
			imgBg1:size({height = showWidth, width = showWidth*imgBg1:size().width/imgBg1:size().height})
		end
		table.insert(blinkTable, imgBg1)
	end
	self.blinkTable = randomTable(blinkTable)
	self.blinkIndex = 0
	self.blinkTimes = 40
	self:blinkSchedule(DTTABLE.BLINK)
end

function UnionAnswerProblemView:blinkSchedule(dt)
	self.panel3:unscheduleUpdate()
	local count = 0
	self.panel3:scheduleUpdate(function(detal)
		-- if self.timeScale > 1 then
		-- 	count = count + 0.017*self.timeScale
		-- else
		-- 	count = count + 0.017
		-- end
		count = count + 0.017
		if count > dt then
			self.blinkIndex = self.blinkIndex + 1
			if self.blinkIndex >= self.blinkTimes then
				if self.blinkIndex == self.blinkTimes then
					for k, v in ipairs(self.blinkTable) do
						v:hide()
					end
				end
				if self.blinkIndex <= self.blinkTimes + #self.blinkTable - 1 then
					self.blinkTable[self.blinkIndex - self.blinkTimes + 1]:show()
				else
					self:endShow(self.panel3)
					self.panel3:unscheduleUpdate()
					self.isEnding = false
				end
			else
				if self.blinkIndex <= #self.blinkTable then
					for k, v in ipairs(self.blinkTable) do
						if k == self.blinkIndex then
							v:show()
						else
							v:hide()
						end
					end
				else
					local a = math.random(#self.blinkTable)
					for k, v in ipairs(self.blinkTable) do
						if k == a then
							v:show()
						else
							v:hide()
						end
					end
				end
			end
			count = 0
		end
	end)
end

function UnionAnswerProblemView:openEraser(panel)
	self.textNum1:hide()
	local panel = panel
	local img = self.panelBg
	local size = img:size()
	local distance = size.width - display.uiOrigin.x
	local lbl = cc.utils:captureNodeSprite(gGameUI.uiRoot, cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565, 1, display.uiOrigin.x, 0)
		:addTo(img, 100)
	lbl:x(lbl:x() - display.uiOrigin.x)

	panel:hide()

	local program = cc.GLProgram:create('shader/ver_shader.vsh', 'shader/eraser2.fsh')
	program:link()
	program:updateUniforms()
	local state = cc.GLProgramState:getOrCreateWithGLProgram(program)

	local size = img:size()
	local bgRender = cc.RenderTexture:create(size.width, size.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444)

	local eNode = cc.Node:create()
	eNode:addTo(img):scale(0.5)
	local eRender = cc.RenderTexture:create(size.width/2, size.height/2, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444)
		:addTo(eNode)
		:setAutoDraw(true)
		:x(-size.width - display.uiOrigin.x)
	-- lbl to sprite
	bgRender:hide()
	bgRender:begin()
	lbl:visit()
	bgRender:endToLua()
	bgRender:drawOnce(true)

	lbl:hide()

	local bgSpr = bgRender:getSprite()
	bgSpr:removeFromParent()
	bgSpr:addTo(img)
	bgSpr:getTexture():setAlphaTexture(eRender:getSprite():getTexture())
	bgSpr:setGLProgramState(state)

	-- 显示板擦
	local eraser = cc.Sprite:create("city/union/answer/guangyun.png")
	eraser:addTo(eRender):scale(1):xy(distance, -size.height/2)

	-- CSprite:setTimeScale(2)
	local delta = 0.2/self.timeScale
	eraser:runAction(cc.Sequence:create(
		cc.MoveTo:create(delta, cc.p(1.5*size.width/4+distance, size.height)),
		cc.MoveTo:create(delta, cc.p(0.5*size.width/4+distance, -size.height/2)),

		cc.MoveTo:create(delta, cc.p(2.5*size.width/4+distance, size.height)),
		cc.MoveTo:create(delta, cc.p(1.5*size.width/4+distance, -size.height/2)),

		cc.MoveTo:create(delta, cc.p(3.5*size.width/4+distance, size.height)),
		cc.MoveTo:create(delta, cc.p(2.5*size.width/4+distance, -size.height/2)),

		cc.MoveTo:create(delta, cc.p(size.width+distance, size.height)),
		cc.CallFunc:create(function()
			self.panelBg:removeAllChildren()
			if gGameUI.scene:getChildByName("answerGift") then
				gGameUI.scene:getChildByName("answerGift"):removeSelf()
			end
			self.isEraser = false
			if #(self.problemData) > self.problemIndex:read() then
				if self.problemData[self.problemIndex:read() + 1].type ~= PROTABLE.GAME then
					self:startAnswer()
				else
					self:showGameRule()
				end
			else
				self:onClose(true)
			end
		end)
	))
end

function UnionAnswerProblemView:onClose(data)
	if self.endData then
		-- self.bagSpine:removeSelf()
		ViewBase.onClose(self)
		return
	end
	--如果正在擦黑板时无法点击退出
	if self.isEraser then
		return
	end
	if data == true then
		self:showEnd()
	else
		self.isQuit = true
		local content = "#C0x5b545b#"..string.format(gLanguageCsv.unionAnswerQuitText, self.myGrade)
		gGameUI:stackUI("city.union.answer.tips", nil, nil, {content = content, cb = function()
			self:showEnd()
		end, closeCb = function()
			self.isQuit = false
			if self.needEraser == true then
				local panel
				if self.problemData[self.problemIndex:read()].type <= PROTABLE.DIFFICULT then
					panel = self.panel1
				elseif self.problemData[self.problemIndex:read()].type == PROTABLE.SEEPICTURE then
					panel = self.panel2
				else
					panel = self.panel3
				end
				self:openEraser(panel)
				self.needEraser = false
			end
		end, time = self.counTtime})
	end
end

function UnionAnswerProblemView:showEnd()
	self.isEraser = true
	self.endPanel:show()
	self.panel1:hide()
	self.panel2:hide()
	self.panel3:hide()
	self.sureBtn:hide()
	self.endPanel:get("text1"):text(string.format(gLanguageCsv.unionAnswerEndText1, self.rightNum, self.myGrade))
	self.endPanel:get("text2"):text("x"..self.rightNum)
	self.bagPanel:xy(241, 400)
	self.topPanel:unscheduleUpdate()
	self.seeTip:unscheduleUpdate()
	gGameApp:requestServer("/game/union/qa/settle",function(tb)
		self.giftData = tb
	end)
	self.bagPanel:onClick(functools.partial(self.getGift, self))
	self.topUI:hide()
end

function UnionAnswerProblemView:getGift()
	self.isEraser = false
	self.endData = true
	local giftData = self.giftData
	if giftData.view.ranks then
		self.roleData:update(giftData.view.ranks.role_ranks)
		self.unionData:update(giftData.view.ranks.union_ranks)
		self.myRoleData:update(giftData.view.ranks.my_rank)
		self.myUnionData:update(giftData.view.ranks.my_union_rank)
	end
	if giftData.view.result then
		ViewBase.onClose(self)
		if not itertools.isempty(giftData.view.result) then
			gGameUI:showGainDisplay(giftData)
		else
			gGameUI:showTip(gLanguageCsv.unionAnswerNoGift)
		end
	end
end

return UnionAnswerProblemView
