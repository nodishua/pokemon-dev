-- @date 2020-3-9
-- @desc 跨服石英大会战报
local CrossCraftView = require("app.views.city.pvp.cross_craft.view")

local WINNUN2TEXT = {}
for i=3, 10 do
	WINNUN2TEXT[i] = gLanguageCsv["symbolNumber"..i]
end
for i=11, 19 do
	WINNUN2TEXT[i] = gLanguageCsv.symbolNumber10 .. gLanguageCsv["symbolNumber"..(i-10)]
end

local TEXTS = {
	fail = gLanguageCsv.budi,
	win = {gLanguageCsv.wansheng ,gLanguageCsv.xiansheng, gLanguageCsv.zhansheng}
}

local TURN_DATA = {
	pre12 = {turn = 1, index = 1},
	pre13 = {turn = 1, index = 2},
	pre14 = {turn = 1, index = 3},
	pre21 = {turn = 1, index = 4},
	pre22 = {turn = 2, index = 1},
	pre23 = {turn = 2, index = 2},
	pre24 = {turn = 2, index = 3},
	pre31 = {turn = 2, index = 4},
	pre32 = {turn = 3, index = 1},
	pre33 = {turn = 3, index = 2},
	pre34 = {turn = 3, index = 3},
	top64 = {turn = 3, index = 4},
}

local function getTurnData(round)
	-- 状态持续到下一个prexx的状态
	local nextRound = nil
	for i, v in ipairs(game.CROSS_CRAFT_ROUNDS) do
		if v == round and not nextRound then
			nextRound = round
		end
		if nextRound and TURN_DATA[v] then
			nextRound = v
			break
		end
	end
	-- 第2天 halftime 倒计时显示开赛时间
	return CrossCraftView.getNextStateTime(round == "halftime" and "prepare2" or nextRound), TURN_DATA[nextRound].turn, TURN_DATA[nextRound].index
end

local BattleMessageView = class("BattleMessageView", cc.load("mvc").ViewBase)

BattleMessageView.RESOURCE_FILENAME = "cross_craft_battle_messages.json"
BattleMessageView.RESOURCE_BINDING = {
    ["item"] = "item",
	["list"] = {
		varname = "speList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showMsg"),
				item = bindHelper.self("item"),
				asyncPreload = 6,
				onItem = function(list, node, k, v)
					node:removeChildByName("rich")
					local name1 = v[2][2]
					local server1 = v[2][1][1]
					local str = "#C0x5C9970##F48##L10#" .. name1 ..string.format(gLanguageCsv.brackets, getServerArea(server1, true))
					if v[1] ~= "streak" then
					--普通
						local txt = TEXTS[v[4]]
						local endStr = ""
						if type(txt) == "table" then
							str = str .. "#C0x5B545B##F48#" .. txt[math.random(1, #txt)]
							endStr = gLanguageCsv.chenggongjinji
						else
							str = str .. "#C0x5B545B##F48#" .. txt
							endStr = gLanguageCsv.yihanluobai
						end
						local name2 = v[3][2]
						local server2 = v[3][1][1]
						str = str .. "#C0x5C9970##F48##L10#" .. name2 ..string.format(gLanguageCsv.brackets, getServerArea(server2, true)) .. "#C0x5B545B##F48#," .. endStr..string.format(gLanguageCsv.craftMessageGotScroe, v[5][1])
					else
					--连胜
						local winNum = math.min(v[3], 8)
						local colorAndSize = ui.QUALITYCOLOR[winNum - 1] .. "#F48#"
						str =  str .. "#C0x5B545B##F48#" .. string.format(gLanguageCsv.isStreakWin, colorAndSize, WINNUN2TEXT[v[3]]) .. ","
						str = str .. gLanguageCsv["streakwin" .. winNum]
					end

					local rich = rich.createWithWidth(str, 40, nil, 2013)
						:anchorPoint(0, 0.5)
						:xy(115, node:height()/2)
					rich:addTo(node, 2, "rich")
				end,
			},
		},
	},
	["textState"] = {
		varname = "textState",
		binds = {
			{
				event = "effect",
				data = {outline={color=cc.c3b(97, 89, 89)}}
			},
		},
	},
	["textTime"] = {
		varname = "textTime",
		binds = {
			{
				event = "text",
				idler = bindHelper.self("showTime"),
				method = function(val)
					if not val then
						return
					end
					return time.getCutDown(val).min_sec_clock
				end,
			},
			{
				event = "effect",
				data = {outline={color=cc.c3b(97, 89, 89)}}
			},
			{
				event = "visible",
				idler = bindHelper.self("round"),
				method = function(val)
					return val ~= "halftime"
				end,
			}
		},
	},
	["sessionPanel"] = "sessionPanel",
	["sessionPanel.textSession"] = {
		varname = "textSession",
		binds = {
			{
				event = "effect",
				data = {outline={color=cc.c3b(97, 89, 89)}}
			},
			{
				event = "text",
				idler = bindHelper.self("textTitle"),
			},
		}
	},
	["timePanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("round"),
			method = function(val)
				return val == "halftime"
			end,
		},
	},
	["timePanel.textTimeNote"] = {
		binds = {
			event = "effect",
			data = {outline={color=cc.c3b(97, 89, 89)}}
		},
	},
	["timePanel.textTime"] = {
		binds = {
			{
				event = "effect",
				data = {outline={color=cc.c3b(91, 84, 91)}}
			},
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

		},
	},
}

function BattleMessageView:onCreate()
	self.showMsg = idlers.newWithMap({})
	self:enableSchedule()
	self:initModel()
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
		end
	end)
	idlereasy.when(self.round, function(_, round)
		local notPre = string.find(round, "top") or string.find(round, "final") or round == "closed"
		if notPre then
			 --预选赛结束
			self:unSchedule(1)
			return
		end
		local delay, turn, index = getTurnData(round)
		if round ~= "halftime" then
			--预选赛时间
			self.speList:size(cc.size(2280,800))
			self.sessionPanel:y(395+720)
			local textTitle1 = gLanguageCsv.current..": ".. string.format(gLanguageCsv.perNumTitle, index)..'  '..gLanguageCsv.battleShowing
			self.textState:text(textTitle1)
			adapt.oneLinePos(self.textState, self.textTime, cc.p(10,0), "left")
		else
			--中场时间
			self.speList:size(cc.size(2280,550))
			self.sessionPanel:y(165+720)
			self.textState:text(gLanguageCsv.current..": "..gLanguageCsv.todayBattleOver)
		end
		local strSession = gLanguageCsv.crossCraftTurnAndIndex
		self.textTitle:set(string.format(strSession, turn, index))

		--倒计时
		self:unSchedule(1)
		self:schedule(function()
			if notPre or delay <= 0 then
				return false
			end
			delay = delay - 1
			self.showTime:set(delay)
		end, 1, 0, 1)
	end)
end

function BattleMessageView:initModel()
	local craftData = gGameModel.cross_craft
	self.round = craftData:getIdler("round")
	self.battleMessages = craftData:getIdler("battle_messages")

	self.showTime = idler.new(0) 	--倒计时
	self.textTitle = idler.new("")
	self.textTitle1 = idler.new("")
end

return BattleMessageView