-- @desc: 	craft-下注

local CraftBetView = class("CraftBetView", Dialog)
CraftBetView.RESOURCE_FILENAME = "craft_bet.json"
CraftBetView.RESOURCE_BINDING = {
	["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["betPanel"] = "betPanel",
	["noBetPanel"] = "noBetPanel",
	["betPanel.betItem"] = "betItem",
	["betPanel.list"] = {
		varname = "betList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("betData"),
				dataOrderCmp = function (a, b)
					return a.rank < b.rank
				end,
				item = bindHelper.self("betItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local role = v.role
					local childs = node:multiget("imgBg", "txtRank", "trainerIcon", "rankIcon", "txtName", "txtLv", "txtOdds", "txtFight", "txtNormal", "imgNormal", "txtHigh", "imgHigh", "btnNormal", "btnHigh", "txtBets", "imgBets")
					local props = {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = role.logo,
							level = false,
							vip = false,
							frameId = role.frame,
							onNode = function(node)
								node:xy(104, 95)
									:z(6)
									:scale(0.9)
							end,
						}
					}
					bind.extend(list, childs.trainerIcon, props)
					childs.txtName:text(role.name)
					childs.txtLv:text(role.level)
					childs.txtOdds:text(mathEasy.getPreciseDecimal(v.rate, 2)) -- 保留小数点后两位，去尾
					childs.txtFight:text(v.fighting_point) 	-- 战力
					childs.txtNormal:text(mathEasy.getShortNumber(gCommonConfigCsv.craftBetNormalGold, 2))
					childs.txtHigh:text(mathEasy.getShortNumber(gCommonConfigCsv.craftBetAdvanceGold, 2))
					local index = v.rank
					childs.txtRank:visible(index > 3)
					childs.txtRank:text(index)
					childs.rankIcon:visible(index < 4)
					if index <= 3 then
						childs.imgBg:texture("city/pvp/craft/dialog_icon/iten_"..index..".png")
						childs.rankIcon:texture("city/pvp/craft/img_xz"..index..".png")
					end
					childs.imgBg:setTouchEnabled(true)
					childs.imgBg:onClick(functools.partial(list.clickHead, k, role, index))
					bind.touch(list, childs.btnNormal, {methods = {ended = functools.partial(list.clickBet, role.role_db_id, gCommonConfigCsv.craftBetNormalGold)}})
					cache.setShader(childs.btnNormal, false, (itertools.size(v.craft_bets) == 0 and v.round == "signup") and "normal" or "hsl_gray")
					text.addEffect(childs.btnNormal:getChildByName("txtNode"), {glow = {color = ui.COLORS.GLOW.WHITE}})
					bind.touch(list, childs.btnHigh, {methods = {ended = functools.partial(list.clickBet, role.role_db_id, gCommonConfigCsv.craftBetAdvanceGold)}})
					cache.setShader(childs.btnHigh, false, (itertools.size(v.craft_bets) == 0 and v.round == "signup") and "normal" or "hsl_gray")
					text.addEffect(childs.btnHigh:getChildByName("txtNode"), {glow = {color = ui.COLORS.GLOW.WHITE}})

					local isBet = itertools.size(v.craft_bets) > 0 and role.role_db_id == v.craft_bets.rank1[1]
					childs.txtBets:visible(isBet)
					childs.imgBets:visible(isBet)
					childs.btnNormal:visible(not isBet)
					childs.btnHigh:visible(not isBet)
					childs.txtNormal:visible(not isBet)
					childs.txtHigh:visible(not isBet)
					childs.imgNormal:visible(not isBet)
					childs.imgHigh:visible(not isBet)
					if itertools.size(v.craft_bets) > 0 and role.role_db_id == v.craft_bets.rank1[1] then
						childs.txtBets:text(mathEasy.getShortNumber(v.craft_bets.rank1[2], 2))
					end
				end,
				asyncPreload = 10,
			},
			handlers = {
				clickHead = bindHelper.self("onHeadClick"),
				clickBet = bindHelper.self("onClickBet"),
			},
		},
	},
}

function CraftBetView:onCreate(data)
	self:initModel()
	local betData = {}
	for k,v in pairs(data) do
		v.round =  self.round:read()
		v.craft_bets = self.craft_bets:read()
		table.insert(betData, v)
	end
	self.betData = idlers.newWithMap(betData)

	local size = itertools.size(data)
	self.noBetPanel:visible(size == 0)
	self.betPanel:visible(size > 0)
	Dialog.onCreate(self)
end

function CraftBetView:initModel()
	local dailyRecord = gGameModel.daily_record
	local craftData = gGameModel.craft
	self.round = craftData:getIdler("round")
	self.craft_bets = dailyRecord:getIdler("craft_bets")
	self.gold = gGameModel.role:getIdler("gold")
	self.id = gGameModel.role:read("id")
end

function CraftBetView:onHeadClick(list, k, v, number, event)
	if self.id == v.role_db_id then return end
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
	local personData = {
		role = {
			level = v.level,
			id = v.role_db_id,
			vip = v.vip,
			name = v.name,
			logo = v.logo,
			frame = v.frame,
		}
	}
	gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, personData, {speical = "rank", target = list.item:get("imgBg")})
end

function CraftBetView:onClickBet( list, id, gold )
	-- 今日已下注
	if itertools.size(self.craft_bets:read()) > 0 then
		gGameUI:showTip(gLanguageCsv.craftBetAlready)
		return
	end

	-- 当前阶段无法下注
	if itertools.size(self.craft_bets:read()) == 0 and self.round:read() ~= "signup" then
		gGameUI:showTip(gLanguageCsv.craftBetCanNot)
		return
	end

	if self.gold:read() < gold then
		gGameUI:showTip(gLanguageCsv.craftBetGoldNone)
		return
	end

	gGameApp:requestServer("/game/craft/bet", function ()
		gGameApp:requestServer("/game/craft/bet/info",function (tb)
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

return CraftBetView
