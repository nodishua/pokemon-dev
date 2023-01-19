-- @date:   2019-10-9 14:45:30
-- @desc:   限时PVP主赛程

local BattleMessages = require("app.views.city.pvp.craft.battle_messages"):getInstance()

local DELAY = 10

local TIMES = {
	prepare = 10 * 60, -- 赛前准备阶段总时长
	pre = 4 * 60, -- 小组赛单局总时长
	-- final = 5 * 60, -- 淘汰赛单局总时长
	preReady = 3 * 60, -- 小组赛单局准备时长
	fight = 60, -- 战斗时长 60s
}

local WINNUN2TEXT = {}
for i=3, 10 do
	WINNUN2TEXT[i] = gLanguageCsv["symbolNumber"..i]
end


-- 这里计算的是战报展示结束时间到展示场次开始时间的间隔，注意preN和preN_lock阶段的结束时间点不一样，需要区分计算(N为自然数1-10)
-- 小组赛单场总计四分钟，分为两个阶段：3分钟的备战阶段和1分钟的战斗阶段，战报信息在进入战斗阶段后刷新，所以战报的刷新时间点为每场战斗阶段的开始
local function getDelta(round)
	local delta = 0
	if string.find(round, "prepare") then
		delta = TIMES.prepare
	elseif string.find(round, "_lock") then -- lock阶段进入
		if string.find(round, "pre10") then -- 第十场lock阶段进入，间隔为第十场备战阶段开始，到第十场战斗阶段结束
			delta = TIMES.pre
		else
			delta = TIMES.pre + TIMES.preReady -- 1-9场lock阶段进入，间隔为本场备战阶段开始，到下场战斗阶段开始
		end
	else 									-- 准备阶段进入
		if round == "pre1" then 			-- 第一场准备阶段进入，间隔为第一场备战阶段开始，到第二场战斗阶段开始(这里有个小问题，第一场准备阶段打开这个界面后，round，在第一场战斗阶段开始并不会刷新，仍为pre1，直到第二场准备阶段开始才会刷新, 但第一场pre1和pre1_lock阶段计算的时间间隔是一样的，故不会影响时间间隔的计算)
			delta = TIMES.pre + TIMES.preReady
		else 								-- 2-10场准备阶段进入，间隔为本场准备阶段开始，到本场战斗阶段开始
			delta = TIMES.preReady
		end
	end

	return delta + 1
end

local TEXTS = {
	fail = gLanguageCsv.budi,
	win = {gLanguageCsv.wansheng ,gLanguageCsv.xiansheng, gLanguageCsv.zhansheng}
}

local CraftMainScheduleView = class("CraftMainScheduleView", cc.load("mvc").ViewBase)

CraftMainScheduleView.RESOURCE_FILENAME = "main_schedule.json"
CraftMainScheduleView.RESOURCE_BINDING = {
	["notOpen"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("notOpen"),
		},
	},
	["notOpen.textTime"] = {
		binds = {
			{
				event = "text",
				idler = bindHelper.self("showTime"),
				method = function(val)
					if not val then
						return
					end
					local tab = time.getCutDown(val)
					return tab.str
				end,
			},
			{
				event = "effect",
				data = {outline={color=ui.COLORS.WHITE}}
			},
		},
	},
	["notOpen.textNote"]= {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}}
		},

	},
	["open"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("notOpen"),
			method = function(val)
				return not val
			end,
		},

	},
	["open.textTitle"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("textTitle")

		},
	},
	["open.textNote1"] = "openTxt1",
	["open.textNote2"] = "openTxt2",
	["open.textNote3"] = "openTxt3",
	["open.textTime"] = {
		varname = "textTime",
		binds = {
			event = "text",
			idler = bindHelper.self("showTime"),
			method = function(val)
				if not val then
					return
				end
				local tab = time.getCutDown(val)
				return tab.str
			end,
		},
	},
	["item"] = "item",
	["open.list"] = {
		varname = "speList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showMsg"),
				item = bindHelper.self("item"),
				asyncPreload = 17,
				onItem = function(list, node, k, v)
					node:removeChildByName("rich")
					local str = "#C0x5C9970##F48#" .. v[2][2]
					if v[1] ~= "streak" then
						local txt = TEXTS[v[4]]
						local endStr = ""
						if type(txt) == "table" then
							str = str .. "#C0x5B545B##F48#" .. txt[math.random(1, #txt)]
							endStr = gLanguageCsv.chenggongjinji
						else
							str = str .. "#C0x5B545B##F48#" .. txt
							endStr = gLanguageCsv.yihanluobai
						end
						str = str .. "#C0x5C9970##F48#" .. v[3][2] .. ",#C0x5B545B##F48#" .. endStr..string.format(gLanguageCsv.craftMessageGotScroe, v[5][1])
					else
						local winNum = math.min(v[3], 8)
						local colorAndSize = ui.QUALITYCOLOR[winNum - 1] .. "#F48#"
						str =  str .. "#C0x5B545B##F48#" .. string.format(gLanguageCsv.isStreakWin, colorAndSize, WINNUN2TEXT[v[3]]) .. ","
						str = str .. gLanguageCsv["streakwin" .. winNum]
					end

					local rich = rich.createWithWidth(str, 40, nil, 2013)
						:anchorPoint(0, 0.5)
						:xy(115, node:height()/2)
					-- if rich:size().height > 50 then
					-- 	node:height(rich:size().height + 5)
					-- end
					rich:addTo(node, 2, "rich")
				end,
			},
		},
	},
}

function CraftMainScheduleView:onCreate()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.craft, subTitle = "INDIGO PLATEAU CONFERENCE"})
	self:initModel()
	self.showMsg = idlers.newWithMap(BattleMessages.get())
	self.notOpen = idler.new(false)
	self.textTitle = idler.new("")
	self.openTxt2:text("")
	self.showTime = idler.new(0)
	idlereasy.when(self.battleMessages, function(_, battleMessages)
		if itertools.size(battleMessages) > 0 then
			local msg = {}
			for i = #battleMessages, 1, -1 do
				local data = battleMessages[i]
				-- 有连胜
				if data[6] > 2 then
					local t = {}
					t[1] = "streak"
					t[2] = data[4] == "win" and data[2] or data[3]
					t[3] = data[6]
					table.insert(msg, t)
				end

				table.insert(msg, data)
				self.showMsg:update(msg)
			end
		else
			self.showMsg:update(BattleMessages.get())
		end
	end)
	self:enableSchedule()

	idlereasy.any({self.round, self.stateTime}, function(_, round, stateTime)
		local isFinal = string.find(round, "final")
		if isFinal then
			-- 关闭当前界面 打开八强赛界面
			self:onClose()
			gGameUI:stackUI("city.pvp.craft.mainschedule_eight", nil, {full = true})
			return
		end
		local d = getDelta(round)
		self.delta = stateTime + d - time.getTime() -- 当前场次结束的时间
		local notOpen = round == "prepare"
		self.notOpen:set(notOpen)
		self.speList:visible(not notOpen)
		local p1, p2 = string.find(round, "%d+")
		if p1 then
			local idx = string.sub(round, p1, p2)
			if not string.find(round, "_lock") then
				idx = math.max(idx - 1, 1)
			end
			self.textTitle:set(string.format(gLanguageCsv.perNum, idx))
			self.openTxt2:text(string.format(gLanguageCsv.perNumTitle, idx))
			adapt.oneLinePos(self.openTxt1, {self.openTxt2, self.openTxt3, self.textTime}, {cc.p(10,0), cc.p(10,0), cc.p(10,0)}, "left")
		end
	end)

	self:schedule(function()
		if string.find(self.round:read(), "final") then
			return false
		end
		self.delta = self.delta - 1
		if self.delta < 0 then
			self.delta = 1
			gGameApp:requestServer("/game/craft/battle/main")
		else
			self.showTime:set(self.delta)
		end
	end, 1, 0)
end

function CraftMainScheduleView:initModel()
	local craftData = gGameModel.craft
	self.round = craftData:getIdler("round")
	self.perRound = self.round:read()
	self.stateTime = craftData:getIdler("time")
	self.battleMessages = craftData:getIdler("battle_messages")
end

return CraftMainScheduleView