-- @desc: 	cross_craft-下注
local function setUnlockIcon(isLocked, item, params)
	item:removeChildByName("_lock_res_")
	if not isLocked then
		return
	end
	local size = item:size()
	local defaultPos = cc.p(size.width * 0.5, size.height * 0.5)
	params = params or {}
	local res = ccui.ImageView:create(params.res or "common/btn/btn_lock1.png")
		:xy(params.pos or defaultPos)
		:scale(params.scale or 1)
		:addTo(item, params.zOrder or 10, "_lock_res_")
	return res
end

local ViewBase = cc.load("mvc").ViewBase
local CrossCraftBetView = class("CrossCraftBetView", ViewBase)
CrossCraftBetView.RESOURCE_FILENAME = "cross_craft_bet.json"
CrossCraftBetView.RESOURCE_BINDING = {
	["betPanel"] = "betPanel",
	["noBetPanel"] = "noBetPanel",
	["betPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")}
		},
	},
	["betPanel.betItem"] = "betItem",
	["betPanel.list"] = {
		varname = "betList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("betDatas"),
				canBet = bindHelper.self("canBet"),
				dataOrderCmp = function (a, b)
					if b.fighting_point and a.fighting_point then
						return b.fighting_point < a.fighting_point
					else
						return b.role.point < a.role.point
					end
				end,
				item = bindHelper.self("betItem"),
				asyncPreload = 5,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local imgBg = node:get("imgBg")
					if v.betType == 1 then
						imgBg:texture("city/pvp/cross_craft/bet/bar_yz"..(k % 2)..".png")
					else
						imgBg:texture("city/pvp/cross_craft/bet/bar_yz"..((v.rank+1) % 2)..".png")
					end
					--预选赛可查看玩家信息
					if v.betType == 1 then
						imgBg:setTouchEnabled(true)
						imgBg:onClick(functools.partial(list.clickHead, k, v.role))
					else
						imgBg:setTouchEnabled(false)
					end

					local childs = node:multiget(
						"trainerIcon", "txtName", "txtLv",
						"txtNormal", "imgNormal", "txtHigh", "imgHigh",
						"btnNormal", "btnHigh", "imgBets")

					--头像
					bind.extend(list, childs.trainerIcon, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId =  v.role.logo,
							level = false,
							vip = false,
							frameId =  v.role.frame,
							onNode = function(node)
								node:xy(96, 100)
									:z(6)
									:scale(0.8)
							end,
						}
					})
					childs.txtName:text( v.role.name)
					childs.txtLv:text( v.role.level)

					local server =  gGameModel.cross_craft:read("servers")
					bind.touch(list, childs.btnNormal, {methods = {ended = functools.partial(list.clickBet, server[1], v.role.id or v.role.role_db_id, "gold")}})
					cache.setShader(childs.btnNormal, false, list.canBet:read() and "normal" or "hsl_gray")
					text.addEffect(childs.btnNormal:getChildByName("txtNode"), {glow = {color = ui.COLORS.GLOW.WHITE}})

					bind.touch(list, childs.btnHigh, {methods = {ended = functools.partial(list.clickBet, server[1], v.role.id or v.role.role_db_id, "coin8")}})
					cache.setShader(childs.btnHigh, false, list.canBet:read() and "normal" or "hsl_gray")
					text.addEffect(childs.btnHigh:getChildByName("txtNode"), {glow = {color = ui.COLORS.GLOW.WHITE}})
					--已下注信息
					local betNumData = {
						[1] = {gold = csv.cross.craft.base[1].preBetGold, coin8 = csv.cross.craft.base[1].preBetCoin},
						[2] = {gold = csv.cross.craft.base[1].top4BetGold, coin8 = csv.cross.craft.base[1].top4BetCoin},
						[3] = {gold = csv.cross.craft.base[1].championBetGold, coin8 = csv.cross.craft.base[1].championBetCoin},
					}
					if list.checkPreResult() == true and v.betType == 1 then
						nodetools.invoke(node, {"btnNormal","btnHigh","txtNormal","txtHigh","imgNormal","imgHigh", "imgBets","imgBet","txtBet"}, "hide")
					elseif v.coinType then
						nodetools.invoke(node, {"imgBets","imgBet","txtBet"}, "show")
						if v.coinType == "gold" then
							node:get("imgBet"):texture("common/icon/icon_gold.png")
							node:get("txtBet"):text(mathEasy.getShortNumber(betNumData[v.betType].gold, 2))
						else
							node:get("imgBet"):texture("common/icon/icon_kfsydhdb1.png")
							node:get("txtBet"):text(mathEasy.getShortNumber(betNumData[v.betType].coin8, 2))
						end
						nodetools.invoke(node, {"btnNormal","btnHigh","txtNormal","txtHigh","imgNormal","imgHigh"}, "hide")
					else
						nodetools.invoke(node, {"imgBets","imgBet","txtBet"}, "hide")
						nodetools.invoke(node, {"btnNormal","btnHigh","txtNormal","txtHigh","imgNormal","imgHigh"}, "show")
					end
					childs.txtNormal:text(mathEasy.getShortNumber(betNumData[v.betType].gold, 2))
					childs.txtHigh:text(mathEasy.getShortNumber(betNumData[v.betType].coin8, 2))

					if v.betType == 1 then
						node:get("top4Panel"):hide()
						node:get("championPanel"):hide()
						if list.checkPreResult() == true then
							--预选赛结果
							local panel = node:get("preResultPanel"):show()
							node:get("prePanel"):hide()

							if k <=3 then
								local iconPath = {"icon_jp.png", "icon_yp.png","icon_tp.png"}
								panel:get("txtRank"):hide()
								panel:get("imgRank"):show()
									:texture("city/rank/"..iconPath[k])
							else
								panel:get("txtRank"):show()
									:text(k)
								panel:get("imgRank"):hide()
							end
							node:get("trainerIcon"):x(420)
							node:get("txtName"):xy(533, 94)
							node:get("txtLv"):hide()
							node:get("txtNode"):hide()
							panel:get("txtPoint"):text(v.role.point or "--") --积分
							panel:get("txtFight"):text(v.role.fighting_point or v.fighting_point) 	-- 战力
							panel:get("txtLv"):text(v.role.level)			--等级
						else
							node:get("preResultPanel"):hide()
							node:get("trainerIcon"):x(106)
							node:get("txtName"):y(94)
							node:get("txtNode"):hide()
							node:get("txtLv"):hide()
							local panel = node:get("prePanel"):show()
							node:get("top4Panel"):hide()
							node:get("championPanel"):hide()
							panel:get("txtFight"):text(v.fighting_point) 	-- 战力
							panel:get("txtLv"):text(v.role.level)			--等级
						end
					elseif v.betType == 2 then
						node:get("preResultPanel"):hide()
						node:get("prePanel"):hide()
						local panel = node:get("top4Panel"):show()
						node:get("trainerIcon"):x(126)
						node:get("txtName"):xy(264, 127)
						node:get("championPanel"):hide()
						panel:get("txtFight"):text(v.fighting_point) 	-- 战力
						panel:get("txtServer"):text(getServerArea(v.role.game_key, true))			-- 区服
					else
						node:get("preResultPanel"):hide()
						node:get("prePanel"):hide()
						node:get("top4Panel"):hide()
						node:get("trainerIcon"):x(126)
						node:get("txtName"):xy(264, 127)
						local panel = node:get("championPanel"):show()
						local textGold = panel:get("txtNormal")
						local textCoin8 = panel:get("txtHigh")
						local imgGold = panel:get("imgNormal")
						local imgCoin8 = panel:get("imgHigh")
						panel:get("txtFight"):text(v.fighting_point) 	-- 战力
						panel:get("txtServer"):text(getServerArea(v.role.game_key, true))			-- 区服
						textGold:text(mathEasy.getPreciseDecimal(v.gold_rate, 2, false)) 		-- 金币赔率
						textCoin8:text(mathEasy.getPreciseDecimal(v.coin_rate, 2, false)) 		-- 货币赔率
						if v.coinType then
							if v.coinType == "gold" then
								imgCoin8:hide()
								textCoin8:hide()
								imgGold:show():x(1201)
								textGold:show():x(1201)
							else
								imgGold:hide()
								textGold:hide()
								imgCoin8:show():x(1201)
								textCoin8:show():x(1201)
							end
							nodetools.invoke(node, {"btnNormal","btnHigh","txtNormal","txtHigh","imgNormal","imgHigh"}, "hide")
						else
							imgGold:show():x(1152)
							textGold:show():x(1152)
							imgCoin8:show():x(1261)
							textCoin8:show():x(1261)
						end
					end
				end,
			},
			handlers = {
				clickHead = bindHelper.self("onHeadClick"),
				clickBet = bindHelper.self("onClickBet"),
				checkPreResult = bindHelper.self("checkPreResult"),
			},
		},
	},
	["leftPanel.tabItem"] = "tabItem",
	["leftPanel.tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				betType = bindHelper.self("betType"),
				item = bindHelper.self("tabItem"),
				-- itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
						panel:get("txt2"):text(v.subName)
					end
					adapt.setTextScaleWithWidth(panel:get("txt"), v.name, 300)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k, v)}})

					setUnlockIcon(v.isLocked and not v.select, normal, {pos = cc.p(290, 120)})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabItemClick"),
			},
		},
	},
	["leftBottomPanel.text1"] = {
		binds = {
			event = "effect",
			data = {outline={color = ui.COLORS.OUTLINE.DEFAULT,size = 3}}
		}
	},
	["leftBottomPanel.text2"] = {
		varname = "textTime",
		binds = {
			event = "effect",
			data = {outline={color = ui.COLORS.OUTLINE.DEFAULT,size = 3}}
		}
	},
	["leftBottomPanel.text3"] = {
		binds = {
			event = "effect",
			data = {outline={color = ui.COLORS.OUTLINE.DEFAULT,size = 3}}
		}
	},
	["betPanel.textJC"] = {
		varname = "textJC",
		binds = {
			event = "effect",
			data = {outline={color = cc.c4b(36, 71, 179, 255),size = 3}}
		}
	},
	["betPanel.rolePanel1"] = {
		varname = "rolePanel1",
		binds = {
			event = "visible",
			idler = bindHelper.self("betType"),
			method = function(val)
				return val ~= 3
			end,
		},
	},
	["betPanel.rolePanel1.txtName"] = {
		binds = {
			event = "effect",
			data = {outline={color = ui.COLORS.OUTLINE.DEFAULT,size = 3}}
		},
	},
	["betPanel.rolePanel1.txtLv"] = {
		binds = {
			event = "effect",
			data = {outline={color = ui.COLORS.OUTLINE.DEFAULT,size = 3}}
		},
	},
	["betPanel.rolePanel2"] = {
		varname = "rolePanel2",
	},
	["betPanel.rolePanel2.txtName"] = {
		binds = {
			event = "effect",
			data = {outline={color = ui.COLORS.OUTLINE.DEFAULT,size = 3}}
		},
	},
	["betPanel.rolePanel2.txtLv"] = {
		binds = {
			event = "effect",
			data = {outline={color = ui.COLORS.OUTLINE.DEFAULT,size = 3}}
		},
	},
	["betPanel.rolePanel3"] = {
		varname = "rolePanel3",
		binds = {
			event = "visible",
			idler = bindHelper.self("betType"),
			method = function(val)
				return val ~= 3
			end,
		},
	},
	["betPanel.rolePanel3.txtName"] = {
		binds = {
			event = "effect",
			data = {outline={color = ui.COLORS.OUTLINE.DEFAULT,size = 3}}
		},
	},
	["betPanel.rolePanel3.txtLv"] = {
		binds = {
			event = "effect",
			data = {outline={color = ui.COLORS.OUTLINE.DEFAULT,size = 3}}
		},
	},

}

-- 是否出预选结果
function CrossCraftBetView:checkPreResult()
	local round = self.round:read()
	if round == "closed" then
		return true
	end
	local currentIndex = 0
	local top64Index = 0
	for k, v in ipairs(game.CROSS_CRAFT_ROUNDS) do
		if v == round then
			currentIndex = k
		elseif v == "top64" then
			top64Index = k
		end
	end
	-- top64的时候出预选赛结果
	return currentIndex >= top64Index
end

--是否出 4强 冠军结果
function CrossCraftBetView:checkFinalResult()
	local round = self.round:read()
	return round == "closed"
end

--是否可以预选下注
function CrossCraftBetView:checkCanPreBet()
	local round = self.round:read()
	return round == "signup"
end

-- 是否可以4强 冠军下注
function CrossCraftBetView:checkCanFinalBet()
	--第二天的10点后的半场时间可以下注 （10点前被lock了 不做判断）
	local round = self.round:read()
	return round == "halftime"
end

--头像
function CrossCraftBetView:initRoleData(roleData,panel)
	if roleData then
		panel:get("txtName"):text(roleData.role.name)
		panel:get("txtLv"):text("Lv" .. roleData.role.level)
		local imgBets = panel:get("imgBets")
		imgBets:ignoreContentAdaptWithSize(true)
		local failed = false
		if self.betType:read() == 1  then
			if self:checkPreResult() == false then --未出预选赛结果
				imgBets:texture("city/pvp/cross_craft/txt/txt_yxz.png")
			else
				if roleData.success == false then
					imgBets:texture("city/pvp/cross_craft/txt/txt_jcsb.png")
					failed = true
				elseif roleData.success == true then
					imgBets:texture("city/pvp/cross_craft/txt/txt_jccg.png")
				end
			end
		elseif self.betType:read() == 2  then
			if self:checkFinalResult() == false then --未出决赛四强结果
				imgBets:texture("city/pvp/cross_craft/txt/txt_yxz.png")
			else
				if roleData.success == false then
					imgBets:texture("city/pvp/cross_craft/txt/txt_jcsb.png")
					failed = true
				elseif roleData.success == true then
					imgBets:texture("city/pvp/cross_craft/txt/txt_jccg.png")
				end
			end
		elseif self.betType:read() == 3 then
			if self:checkFinalResult() == false then --未出决赛四强结果
				imgBets:texture("city/pvp/cross_craft/txt/txt_yxz.png")
			else
				local data = gGameModel.cross_craft:read("last_top8_plays").final.champion
				local champion = data.result == "win" and data.role1 or data.role2
				if champion.role_db_id ~= roleData.role.role_db_id then
					imgBets:texture("city/pvp/cross_craft/txt/txt_jcsb.png")
					failed = true
				else
					imgBets:texture("city/pvp/cross_craft/txt/txt_jccg.png")
				end
			end
		end
		bind.extend(self, panel:get("trainerIcon"), {
			class = "role_logo",
			props = {
				logoId =  roleData.role.logo,
				level = false,
				vip = false,
				frameId =  roleData.role.frame,
				onNode = function(node)
					node:xy(96, 100)
						:z(6)
					if failed then
						local grayState = cc.c3b(128, 128, 128)
						local logo = node:get("logoClipping"):get("logo")
						logo:color(grayState)
					end
				end,
			}
		})
	else
		panel:get("txtName"):text("")
		panel:get("txtLv"):text("")
		local imgBets = panel:get("imgBets")
		imgBets:ignoreContentAdaptWithSize(true)
		if self.betType:read() == 1  then
			if self:checkCanPreBet() == false then --可预选下注
				imgBets:texture("city/pvp/cross_craft/txt/txt_wxz.png")
			else
				imgBets:texture("city/pvp/cross_craft/txt/txt_ddxz.png"):show()
			end
		else
			if self:checkCanFinalBet() == false then--可决赛下注
				imgBets:texture("city/pvp/cross_craft/txt/txt_wxz.png")
			else
				imgBets:texture("city/pvp/cross_craft/txt/txt_ddxz.png"):show()
			end
		end
		bind.extend(self, panel:get("trainerIcon"), {
			class = "role_logo",
			props = {
				logoId = gGameModel.role:getIdler("logo"),
				frameId = gGameModel.role:getIdler("frame"),
				level = false,
				vip = false,
				onNode =function(panel)
					panel:x(96)
					panel:removeChildByName("frameSpine")
					panel:get("frame")
						:texture("city/pvp/craft/mainschedule/panel_head_blue.png")
						:show()
					panel:get("logoClipping"):get("logo")
						:hide()
					ccui.ImageView:create("city/pvp/cross_craft/txt/txt_wh.png")
						:alignCenter(panel:size())
						:addTo(panel, 3)
				end,
			},
		})
	end
end

-- 已下注信息
function CrossCraftBetView:initBettedRole(data)
	local success = true
	if self.betType:read() == 2 or self.betType:read() == 1 then
		for i = 1, 3 do
			local panel = self["rolePanel"..i]:show()
			local roleData = data[i]
			self:initRoleData(roleData,panel)
			if roleData == nil or roleData.success == false  then
				success = false
			end
		end
		-- 额外奖励
		local showed = userDefault.getForeverLocalKey("crossCraftHasShowed"..self.betType:read(), 0)
		if success and showed == 0 and self.round:read() == "closed" then
			gGameUI:stackUI("city.pvp.cross_craft.extra_award", nil, {clickClose = true},{type = self.betType:read(),roleData = data})
			userDefault.setForeverLocalKey("crossCraftHasShowed"..self.betType:read(), 1)
		end
	else
		local panel = self["rolePanel2"]:show()
		local roleData = data[1]
		self:initRoleData(roleData,panel)
	end
end

function CrossCraftBetView:onCreate(data)
	widget.addAnimationByKey(self:getResourceNode(), "kuafushiying/bj.skel", "recordBg", "effect_loop", 0)
		:scale(2)
		:alignCenter(display.sizeInView)
	gGameUI.topuiManager:createView("cross_craft", self, {onClose = self:createHandler("onClose")}):init({title = gLanguageCsv.bet, subTitle = "BET"})
	local imgBg = self.betPanel:get("imgBg")
	local size = imgBg:size()
	widget.addAnimation(imgBg, "kuafushiying/yazhubj.skel", "effect_loop", 0)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(size.width/2, 1045)
		:scale(2)

	self:initData(data[1], data[2])
	self:addTabListClipping()
	self:initModel()

	--押注数据
	self.betDatas = idlers.newWithMap({})
	--左侧标签栏
	local tabDatas ={
		[1] = {name = gLanguageCsv.preBet, subName = "Preliminary", isLocked = false, select = false,strJc = gLanguageCsv.preBetTips},
		[2] = {name = gLanguageCsv.fourBet, subName = "Top 4", isLocked = false, select = false, strJc = gLanguageCsv.fourBetTips},
		[3] = {name = gLanguageCsv.champtionBet, subName = "Champion", isLocked = false, select = false, strJc = gLanguageCsv.champtionBetTips},
	}
	self.tabDatas = idlers.newWithMap(tabDatas)
	--现在选择的押注类型
	self.betType = idler.new(1)
	idlereasy.any({self.betType, self.round},function(_,betType, round)
		--下注按钮状态
		local canBet = false
		if round == "closed" or round == "prepare" or round == "prepare2" then
			canBet = false
		else
			if betType == 1  then
				if round == "signup"  then
					canBet = #self.data.bettedData[betType] < 3
				end
			elseif betType == 2 then
				if round == "halftime"  then
					canBet = #self.data.bettedData[betType] < 3
				end
			else
				if round == "halftime"  then
					canBet = #self.data.bettedData[betType] < 1
				end
			end
		end
		self.canBet:set(canBet)

		--4强 冠军竞猜 解锁状态
		--第二天十点之后解锁
		local todayDate = tonumber(time.getTodayStrInClock(10))
		if round == "signup" or round == "prepare" or string.find(round,"pre1") or string.find(round,"pre2") then
			self.tabDatas:atproxy(2).isLocked = true
			self.tabDatas:atproxy(3).isLocked = true
		elseif round == "halftime" then
			self.tabDatas:atproxy(2).isLocked = false
			self.tabDatas:atproxy(3).isLocked = false
		end
		self:initBettedRole(self.data.bettedData[betType])
	end)

	self.round:addListener(function(val, oldval)
		--final到closed 重新请求 betinfo
		if (val == "closed" and oldval == "final3_lock") or (val == "top64" and oldval == "pre34_lock") then
			gGameApp:requestServer("/game/cross/craft/bet/info",function (tb1)
				self:initData(tb1.view, nil)
				self:initBettedRole(self.data.bettedData[self.betType:read()])
			end)
		end
	end)
	self.betType:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		local showIndex = 0
		if val == 1 and self:checkPreResult() then
			showIndex = 0
		else
			showIndex = val
		end
		for i = 0, 3 do
			local panel = self.betPanel:get("imgBg"):get("panel"..i)
			panel:setVisible(showIndex == i)
		end
		local path = {[1] = "txt_yxjc.png",[2] = "txt_4qjc.png", [3] ="txt_gjjc.png"}
		self.betPanel:get("imgBg"):get("imgJC"):texture("city/pvp/cross_craft/txt/"..path[val])
		self.betDatas:update(self.data.canBetData[val])
		self.textJC:text(tabDatas[val].strJc)
		if matchLanguage({"en"}) then
			self.textJC:height(85)
			self.textJC:ignoreContentAdaptWithSize(false)
			self.textJC:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
		end

		if val == 1 and self:checkPreResult() then
			self.textJC:text(gLanguageCsv.crossCraftPreResult)
		end
		if val == 1 then
			self.textTime:text(gLanguageCsv.battleFirstDay)
		else
			self.textTime:text(gLanguageCsv.battleSecondDay)
		end
	end)
	-- 倒计时解锁time
	local round = self.round:read()
	if self.round:read() ~= "closed" then
		local delta = time.getNumTimestamp(self.craftDate) + (24 + 10)* 3600 - time.getTime()
		if delta >= 0 then
			performWithDelay(self,function()
				self.tabDatas:atproxy(2).isLocked = false
				self.tabDatas:atproxy(3).isLocked = false
			end,delta)
		end
	end
	if self.round:read() ~= "closed" then
		for i = 1, 3 do
			userDefault.setForeverLocalKey("crossCraftHasShowed"..i, 0)
		end
	end
end

function CrossCraftBetView:initData(tb1,tb2)
	if tb2 ~= nil then
		self.rankData = tb2.rank
	else
		self.rankData = self.rankData or {}
	end

	local data = {
		bettedData = {[1] = {}, [2] = {}, [3] = {}},
		canBetData = {[1] = {}, [2] = {}, [3] = {}}
	}

	--已经下注信息
	for k, v in ipairs(tb1.pre_bet) do
		table.insert(data.bettedData[1],v)
	end

	for k, v in ipairs(tb1.top4_bet) do
		table.insert(data.bettedData[2],v)
	end
	if tb1.mychampion_bet[2] ~= "" then
		data.bettedData[3][1] = {role = {role_db_id = tb1.mychampion_bet[1]}, coin = tb1.mychampion_bet[2]}
	end

	--可下注信息
	for k, v in pairs(self.rankData) do
		v.betType = 1
		table.insert(data.canBetData[1],v)
	end
	for k, v in pairs(tb1.champion_bet) do
		v.betType = 2
		table.insert(data.canBetData[2],v)
		local v3 = clone(v)
		v3.betType = 3
		table.insert(data.canBetData[3],v3)
	end

	for i = 1, 3 do
		for k1,  v1 in pairs(data.bettedData[i]) do
			for k2, v2 in pairs(data.canBetData[i]) do
				if (v1.role.role_db_id == v2.role.id) or (v1.role.role_db_id == v2.role.role_db_id) then
					data.canBetData[i][k2].coinType = v1.coin
					if i == 3 then
						data.bettedData[3][k1].role = v2.role
					end
					break
				end
			end
		end
	end
	self.data = data
end

function CrossCraftBetView:initModel()
	self.round =  gGameModel.cross_craft:getIdler("round")
	self.gold = gGameModel.role:getIdler("gold")
	self.coin8 = gGameModel.role:getIdler("coin8")
	self.canBet = idler.new(false)
	self.craftDate = gGameModel.cross_craft:read("date")
end
-- 点击头像
function CrossCraftBetView:onHeadClick(list, k, v, event)
	local id = v.role_db_id or v.id
	if gGameModel.role:read("id") == id then return end
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
	local personData = {
		role = {
			level = v.level,
			id = id,
			vip = v.vip_level,
			name = v.name,
			logo = v.logo,
			frame = v.frame,
		}
	}
	gGameUI:stackUI("city.chat.personal_info", nil, {
		clickClose = true,
		dispatchNodes = list,
	}, pos, personData, {speical = "rank", target = list.item:get("imgBg"), disableTouch = true})
end

function CrossCraftBetView:onClickBet(list, server,id, type)
	local betType = self.betType:read()
	local round = self.round:read()
	--下注时间 次数检测
	if round == "closed" then
		gGameUI:showTip(gLanguageCsv.craftCanNotBet)
		return
	end

	local isLocked = self.tabDatas:atproxy(betType).isLocked
	if betType == 1  then
		if round == "signup" then
			if #self.data.bettedData[betType] >= 3 then
				gGameUI:showTip(gLanguageCsv.betTimesUseUp)
				return
			end
		else
			gGameUI:showTip(gLanguageCsv.craftCanNotBet)
			return
		end
	elseif betType == 2 then
		local today = time.getNowDate()
		local todayDate = tonumber(today.year..today.month..today.day)
		if round == "halftime" and not isLocked then
			if #self.data.bettedData[betType] >= 3 then
				gGameUI:showTip(gLanguageCsv.betTimesUseUp)
				return
			end
		else
			gGameUI:showTip(gLanguageCsv.craftCanNotBet)
			return
		end
	else
		local today = time.getNowDate()
		local todayDate = tonumber(today.year..today.month..today.day)
		if round == "halftime" and not isLocked then
			if #self.data.bettedData[betType] >= 1 then
				gGameUI:showTip(gLanguageCsv.betTimesUseUp)
				return
			end
		else
			gGameUI:showTip(gLanguageCsv.craftCanNotBet)
			return
		end
	end
	--下注货币检测
	local data = {
		[1]= {gold = "preBetGold",coin = "preBetCoin"},
		[2]= {gold = "top4BetGold",coin = "top4BetCoin"},
		[3]= {gold = "championBetGold",coin = "championBetCoin"}}
	if type == "gold" then
		if self.gold:read() < csv.cross.craft.base[1][data[betType].gold] then
			uiEasy.showDialog("gold")
			return
		end
	else
		if self.coin8:read() < csv.cross.craft.base[1][data[betType].coin] then
			uiEasy.showDialog("coin8")
			return
		end
	end
	-- 四强 冠军相同提示
	local same = false
	if self.betType:read() == 2  then
		for k2, v2 in pairs(self.data.bettedData[3]) do
			if (id == v2.role.id) or (id == v2.role.role_db_id) then
				same = true
			end
		end
	elseif self.betType:read() == 3 then
		for k2, v2 in pairs(self.data.bettedData[2]) do
			if (id == v2.role.id) or (id == v2.role.role_db_id) then
				same = true
			end
		end
	end
	if same == true then
		gGameUI:showTip(gLanguageCsv.fourBetSameAsChampion)
		return
	end
	--提示
	if self.betType:read() == 2 or  self.betType:read() == 3 then
		local selectKey = "crossCraftBetTips"..self.craftDate
		local state = userDefault.getForeverLocalKey(selectKey, "first")
		if state == "first" or state == "true" then
			gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = gLanguageCsv.fourBetSameAsChampionTips, btnType = 2, selectKey = selectKey, cb = function ()
				self:requsetBet(server,id, type)
			end})
		else
			self:requsetBet(server,id, type)
		end
	else
		self:requsetBet(server,id, type)
	end
end

function CrossCraftBetView:requsetBet(server,id, type)
	local betType = self.betType:read()
	gGameApp:requestServer("/game/cross/craft/bet", function (data)
		--清空已有的 已下注信息
		self.data.bettedData[1] = {}
		self.data.bettedData[2] = {}
		self.data.bettedData[3] = {}
		for k, v in ipairs(data.view.pre_bet) do
			table.insert(self.data.bettedData[1],v)
		end
		for k, v in ipairs(data.view.top4_bet) do
			table.insert(self.data.bettedData[2],v)
		end
		if data.view.mychampion_bet[2] ~= "" then
			self.data.bettedData[3][1] = {role = {role_db_id = data.view.mychampion_bet[1]}, coin = data.view.mychampion_bet[2]}
		end


		for i = 1, 3 do
			for k1,  v1 in pairs(self.data.bettedData[i]) do
				for k2, v2 in pairs(self.data.canBetData[i]) do
					if (v1.role.role_db_id == v2.role.id) or (v1.role.role_db_id == v2.role.role_db_id) then
						self.data.canBetData[i][k2].coinType = v1.coin
						if i == 3 then
							self.data.bettedData[3][k1].role = v2.role
						end
						break
					end
				end
			end
		end


		if betType == 1 or betType == 2 then
			self.canBet:set(#self.data.bettedData[betType] < 3)
		else
			self.canBet:set(#self.data.bettedData[betType] < 1)
		end
		dataEasy.tryCallFunc(self.betList, "updatePreloadCenterIndexAdaptFirst")
		self.betDatas:update(clone(self.data.canBetData[betType]))
		self:initBettedRole(self.data.bettedData[betType])

	end, self.betType:read(),server, id, type)
end

function CrossCraftBetView:onTabItemClick(list, index, v)
	if v.isLocked then
		gGameUI:showTip(gLanguageCsv.crossCraftBetTip)
		return
	end
	dataEasy.tryCallFunc(self.betList, "setItemAction", {isAction = true})
	self.betType:set(index)
end

function CrossCraftBetView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function CrossCraftBetView:getRuleContext(view)
	local c = adaptContext
	local tb = {
		[1]= {title = 138, start = 80001, _end = 80100},
		[2]= {title = 139, start = 81001, _end = 81100},
		[3]= {title = 140, start = 82001, _end = 82100},
	}
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(tb[self.betType:read()].title),
		c.noteText(tb[self.betType:read()].start, tb[self.betType:read()]._end),
	}
	return context
end

-- 页签 list 裁剪处理
function CrossCraftBetView:addTabListClipping()
	local list = self.betList
	list:retain()
	list:removeFromParent()
	local size = list:size()
	local mask = ccui.Scale9Sprite:create()
	mask:initWithFile(cc.rect(48, 0, size.width, size.height), "city/pvp/cross_craft/bet/img_zz.png")
	mask:size(size)
		:anchorPoint(0, 0)
		:xy(list:xy())
	cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.1)
		:add(list)
		:addTo(self.betPanel, list:z())
	list:release()
end
return CrossCraftBetView
