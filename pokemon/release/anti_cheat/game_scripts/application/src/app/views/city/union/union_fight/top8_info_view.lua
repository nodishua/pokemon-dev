-- @date:   2020-02-25
-- @desc:   公会战界面

local unionTools = require "app.views.city.union.tools"
local UnionFightFightListDialog = class("UnionFightFightListDialog", Dialog)

UnionFightFightListDialog.RESOURCE_FILENAME = "union_fight_fight_list.json"
UnionFightFightListDialog.RESOURCE_BINDING = {
	["bg"] = "bg",
	["text"] = "text",
	["btnClose"] = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["lines.line1"] = "line1",
	["lines.line2"] = "line2",
	["lines.line3"] = "line3",
	["lines.line4"] = "line4",
	["lines.line5"] = "line5",
	["lines.line6"] = "line6",
	["lines.line7"] = "line7",
	["lines.line8"] = "line8",
	["lines.line18"] = "line18",
	["lines.line27"] = "line27",
	["lines.line36"] = "line36",
	["lines.line45"] = "line45",
	["icons.icon1"] = "icon1",
	["icons.icon2"] = "icon2",
	["icons.icon3"] = "icon3",
	["icons.icon4"] = "icon4",
	["icons.icon5"] = "icon5",
	["icons.icon6"] = "icon6",
	["icons.icon7"] = "icon7",
	["icons.icon8"] = "icon8",
	["icons.icon18"] = "icon18",
	["icons.icon27"] = "icon27",
	["icons.icon36"] = "icon36",
	["icons.icon45"] = "icon45",
	["icons.icon1845"] = "icon1845",
	["icons.icon2736"] = "icon2736",
	["iconBg"] = "iconBg",
	["icons.icon1.self.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(130, 45, 19, 255)}},
		},
	},
	["icons.icon2.self.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(130, 45, 19, 255)}},
		},
	},
	["icons.icon3.self.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(130, 45, 19, 255)}},
		},
	},
	["icons.icon4.self.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(130, 45, 19, 255)}},
		},
	},
	["icons.icon5.self.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(130, 45, 19, 255)}},
		},
	},
	["icons.icon6.self.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(130, 45, 19, 255)}},
		},
	},
	["icons.icon7.self.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(130, 45, 19, 255)}},
		},
	},
	["icons.icon8.self.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(130, 45, 19, 255)}},
		},
	},
}

local Pos2Key = {
	[18] = "group-a1",
	[27] = "group-b1",
	[36] = "group-b2",
	[45] = "group-a2",
	[1845] = "group-a3",
	[2736] = "group-b3",
	[-18452736] = "third",
	[18452736] = "champion",
}

local PosOther = {
	[1] = 8,
	[2] = 7,
	[3] = 6,
	[4] = 5,
	[5] = 4,
	[6] = 3,
	[7] = 2,
	[8] = 1,
	[18] = 45,
	[27] = 36,
	[36] = 27,
	[45] = 18,
	[1845] = 2736,
	[2736] = 1845,
}

local function halfString(pos)
	local len = string.len(pos)
	if len > 1 then
		local half = len / 2
		return string.sub(pos, 1, half), string.sub(pos, half+1, len)
	end
end

function UnionFightFightListDialog:onCreate(isView, btnShow, dialogHandler)
	self.unionId = gGameModel.role:read("union_db_id")
	self.dialogHandler = dialogHandler
	local data = gGameModel.union_fight:read("top8_vs_info") or {}
	self.data = data

	local dataOf8 = {}
	local dataOf4 = {}
	local dataOf2 = {}
	local winnerTb = {}
	local finalWinner = nil
	for pos, v in pairs(data) do
		local t = {
			pos = tostring(pos),
			id = v[1],
			name = v[2],
			icon = v[3],
			level = v[4],
			maxNum = v[5],
			num = v[6],
		}
		if pos < 10 and pos > 0 then
			table.insert(dataOf8, t)
		elseif pos < 100 and pos > 0 then
			table.insert(dataOf4, t)
		elseif pos < 10000 and pos > 0 then
			table.insert(dataOf2, t)
		elseif pos > 0 then
			finalWinner = t
			local l, r = halfString(tostring(pos))
			winnerTb[l] = t.id
			winnerTb[r] = t.id
		end
	end

	for pos, _ in pairs(PosOther) do
		local icon = self["icon"..pos]
		icon:get("???"):hide()
	end
	local function setIcons(data)
		for _, v in pairs(data) do
			local pos = v.pos
			local icon = self["icon"..pos]
			local win = winnerTb[pos] == v.id
			icon:get("win"):visible(win)
			icon:get("icon"):texture(gUnionLogoCsv[v.icon]):show()
			icon:get("name"):text(v.name):show()
			icon:get("text"):text(v.num.."/"..v.maxNum):show()
			icon:get("bg"):show()
			icon:setOpacity(255 * 0.7)

			if self.unionId == v.id and icon:get("self") then
				icon:get("self"):show()
			end

			local l, r = halfString(pos)
			if l and r then
				winnerTb[l] = v.id
				winnerTb[r] = v.id
			end

			local line = self["line"..pos]
			if line then
				line:get("img"):visible(win)
			end

			local btn = icon:get("btn")
			if btnShow and btn then
				btn:show()
				bind.touch(self, btn, {methods = {ended = self:createHandler("onBtnClick", pos, v.id)}})
			end

			-- 对手无数据
			local otherPos = PosOther[tonumber(pos)]
			if otherPos and not self.data[otherPos] then
				local icon = self["icon"..otherPos]
				icon:get("???"):show()
				icon:get("bg"):show()
				icon:get("name"):text(gLanguageCsv.curRoundNoEnemy):show()
				if matchLanguage({"kr"}) then
					icon:get("name"):setFontSize(27)
				end
			end
		end
	end

	setIcons(dataOf2)
	setIcons(dataOf4)
	setIcons(dataOf8)

	if finalWinner then
		self:playChampionAni(finalWinner, btnShow)
	end

	-- TODO: Dialog类却没有调用父类onCreate会有问题，临时先Dialog那边进行保护
	if isView then
		self.btnClose:hide()
		self.bg:hide()
		local node = self:getResourceNode()
		node:scale(0.7)
		local round = gGameModel.union_fight:read("round")
		local wday = self:getWDay()
		self.text:visible(wday ~= 7 and round ~= "over")
	else
		Dialog.onCreate(self, {clickClose = true})
	end
end

function UnionFightFightListDialog:getWDay()
	local wday = time.getNowDate().wday -- 星期
	wday = wday == 1 and 7 or wday - 1
	return wday
end

function UnionFightFightListDialog:onBtnClick(pos, winnerId)
	local key = Pos2Key[tonumber(pos)]
	gGameApp:requestServer("/game/union/fight/top8/round/results", function(tb)
		local data = gGameModel.union_fight:read("round_results")[key] or {}
		local round = next(data)
		if not round then
			gGameUI:showTip(gLanguageCsv.notStartBattle)
			return
		end
		local l, r = halfString(pos)
		local left = self.data[tonumber(l)]
		local right = self.data[tonumber(r)]
		local unions = {
			left = {
				id = left[1],
				name = left[2],
				icon = left[3],
				level = left[4],
				isWin = winnerId == left[1],
			},
			right = {
				id = right[1],
				name = right[2],
				icon = right[3],
				level = right[4],
				isWin = winnerId == right[1],
			},
		}
		self.dialogHandler("city.union.union_fight.fighting_list.js", data, unions, true)
	end, key)
end

function UnionFightFightListDialog:playChampionAni(finalWinner, btnShow)
	local delay = 50 / 60
	local spinePath = "union_fight/ghz_touxiang.skel"
	local node = self:getResourceNode()
	node = self.iconBg
	local size = node:size()
	local ani = widget.addAnimationByKey(node, spinePath, "main_ani", "effect", 8)
		:addPlay("effect_loop")
		:xy(size.width / 2, size.height / 2)
		:scale(2)

	if btnShow then
		local btnPanel = self.iconBg:get("btnPanel"):visible(btnShow)
		local rotateR = -1 -- 1就是逆时针 -1是顺时针
		btnPanel:scale(0)
		transition.executeSpawn(btnPanel)
			:scaleTo(delay, 1)
			:rotateBy(delay, 360 * rotateR)
			:done()
		bind.touch(self, btnPanel:get("btn"), {methods = {ended = self:createHandler("onBtnClick", finalWinner.pos, finalWinner.id)}})
	end
	self.iconBg:get("winner.icon"):texture(gUnionLogoCsv[finalWinner.icon])
	self.iconBg:get("winner.name"):text(finalWinner.name)
	self.iconBg:get("winner.text"):text(finalWinner.num.."/"..finalWinner.maxNum)
	self.iconBg:get("???"):hide()
	self.iconBg:get("iconBg"):hide() -- 隐藏原本的icon背景板 此背景板被spine代替
	performWithDelay(self, function()
		self.iconBg:get("winner"):show()
	end, delay)
end

return UnionFightFightListDialog