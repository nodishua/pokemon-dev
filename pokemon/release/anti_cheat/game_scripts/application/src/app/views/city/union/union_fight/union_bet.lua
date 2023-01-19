
--工会战押注
local UnionBetView = class("UnionBetView", Dialog)

local textureTab = {"city/union/union_fight/part3/icon_1.png", "city/union/union_fight/part3/icon_2.png", "city/union/union_fight/part3/icon_3.png"}

local getWDay = function()
	local wday = time.getNowDate().wday -- 星期
	wday = wday == 1 and 7 or wday - 1
	return wday
end

UnionBetView.RESOURCE_FILENAME = "union_bet.json"
UnionBetView.RESOURCE_BINDING = {
	["item"] = "item",
	["list"] = {
		varname = "betList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("betData"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				dataOrderCmp = function (a, b)
					return a.rank < b.rank
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("bg", "rank", "icon", "iconbg2", "rankTxt", "name", "jf", "pl", "txt", "icon1", "txt2", "icon2", "btnOk", "gold2", "gold","txt1","level")
					local union = v.union
					childs.icon:texture(csv.union.union_logo[union.logo].icon)
					childs.icon:scale(1.9)
					if v.rank <= 3 then
						childs.rank:texture(textureTab[v.rank])
						childs.rankTxt:hide()
					else
						childs.rank:hide()
						childs.rankTxt:text(v.rank)
						text.addEffect(childs.rankTxt, {outline={color=(cc.c4b(59, 51, 59, 255))}})
					end
					local bgOpacity = v.rank % 2 == 1 and 153 or 77
					childs.bg:setOpacity(bgOpacity)
					childs.iconbg2:setOpacity(178)
					childs.name:text(union.name)
					childs.jf:text(v.point)
					childs.pl:text(mathEasy.getPreciseDecimal(v.rate, 2))
					childs.level:text(union.level)
					childs.level:x(childs.level:x() - childs.level:width()/2)
					childs.txt1:x(childs.txt1:x() - childs.level:width()/2)
					text.addEffect(childs.level, {outline={color=(cc.c4b(108, 82, 49, 255))}})
					text.addEffect(childs.txt1, {outline={color=(cc.c4b(108, 82, 49, 255))}})
					text.addEffect(childs.txt, {outline={color=(cc.c4b(59, 51, 59, 255))}})
					text.addEffect(childs.txt2, {outline={color=(cc.c4b(59, 51, 59, 255))}})

					childs.bg:setTouchEnabled(false)
					bind.touch(list, childs.icon1, {methods = {ended = functools.partial(list.clickBet, union.union_id, gCommonConfigCsv.unionFightBetNormalGold)}})
					bind.touch(list, childs.icon2, {methods = {ended = functools.partial(list.clickBet, union.union_id, gCommonConfigCsv.unionFightBetAdvanceGold)}})
					--状态
					if itertools.size(v.craft_bets) ~= 0 or v.round ~= "signup" then
						childs.icon1:setOpacity(127)
						childs.icon2:setOpacity(127)
						childs.gold:setOpacity(127)
						childs.gold2:setOpacity(127)
						childs.txt:setOpacity(127)
						childs.txt2:setOpacity(127)
					end

					local commonTxt = mathEasy.getShortNumber(gCommonConfigCsv.unionFightBetNormalGold, 2)
					local advancedTxt = mathEasy.getShortNumber(gCommonConfigCsv.unionFightBetAdvanceGold, 2)
					childs.txt:text(commonTxt)
					childs.txt2:text(advancedTxt)
					--isBet1为ture则是普通下注，isBet2为ture则是高级下注
					local num
					local btnInfo = false
					if v.craft_bets.rank1 then
						if union.union_id == v.craft_bets.rank1[1] and v.craft_bets.rank1[2] == gCommonConfigCsv.unionFightBetNormalGold then
							btnInfo = true
							childs.txt:text(commonTxt)
							childs.txt:setOpacity(255)
							childs.gold:setOpacity(255)
						end
						if union.union_id == v.craft_bets.rank1[1] and v.craft_bets.rank1[2] == gCommonConfigCsv.unionFightBetAdvanceGold then
							btnInfo = true
							childs.txt:text(advancedTxt)
							childs.txt:setOpacity(255)
							childs.gold:setOpacity(255)
						end
					end
					childs.btnOk:visible(btnInfo)
					childs.icon1:visible(not btnInfo)
					childs.icon2:visible(not btnInfo)
					childs.txt2:visible(not btnInfo)
					childs.gold2:visible(not btnInfo)
				end,
				-- asyncPreload = 10,
			},
			handlers = {
				clickBet = bindHelper.self("onClickBet"),
			},
		},
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["up.rank"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		},
	},
	["up.union"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		},
	},
	["up.jf"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		},
	},
	["up.pl"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		},
	},
	["up.xz"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		},
	},
	["bg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("interceptFunc"),
		},
	},
}


function UnionBetView:onCreate(data)
	self:initModel()
	local betData = {}
	for k,v in pairs(data) do
		v.round = self.round:read()
		v.craft_bets = self.craft_bets:read()
		table.insert(betData, v)
	end

	self.betData = idlers.newWithMap(betData)
	Dialog.onCreate(self)
end

function UnionBetView:initModel()
	self.round = gGameModel.union_fight:getIdler("round") 				--查看状态
	self.craft_bets = gGameModel.daily_record:getIdler("union_fight_bets")	--查看自己押注
	self.gold = gGameModel.role:getIdler("gold")
	self.id = gGameModel.role:read("id")
	self.item:visible(false)
end

function UnionBetView:onClickBet(list, id, gold)
	-- 当前阶段无法下注
	local combat = gGameModel.union_fight:read("round")
	--战斗中无法押注
	if getWDay() == 6 and combat == "battle" then
		gGameUI:showTip(gLanguageCsv.unionBattleBegin)
		return
	end
	--未到决战时间不能押注
	if getWDay() ~= 6 or combat ~= "signup" then
		gGameUI:showTip(gLanguageCsv.union_bet)
		return
	end

	-- 今日已下注
	if itertools.size(self.craft_bets:read()) > 0 then
		gGameUI:showTip(gLanguageCsv.craftBetAlready)
		return
	end

	if self.gold:read() < gold then
		gGameUI:showTip(gLanguageCsv.craftBetGoldNone)
		return
	end

	gGameApp:requestServer("/game/union/fight/bet", function ()
		gGameApp:requestServer("/game/union/fight/bet/info",function (tb)
			local betData = {}
			for k,v in pairs(tb.view) do
				v.round =  self.round:read()
				v.craft_bets = self.craft_bets:read()
				table.insert(betData, v)
			end
			dataEasy.tryCallFunc(self.betList, "updatePreloadCenterIndex")
			self.betData:update(betData)
		end)
	end, id, gold)
end
function UnionBetView:interceptFunc( ... )
	-- body
end

return UnionBetView