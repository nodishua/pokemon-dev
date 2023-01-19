-- @Date: 2018-10-30
-- @Desc: 来源获得途径界面

local ViewBase = cc.load("mvc").ViewBase
local GainWayView = class("GainWayView", Dialog)

local WAY_BTNTITLE = {
	--扫荡
	gLanguageCsv.mopUp,
	--前往
	gLanguageCsv.leaveFor,
	--未开启
	gLanguageCsv.notOpen,
}

local WAY_TYPE = {
	--扫荡
	MOPUP = 1,
	--前往
	LEAVEFOR = 2,
	--未开启
	NOTOPEN = 3
}

local SHOP_UNLOCK_KEY = game.SHOP_UNLOCK_KEY

GainWayView.WAY_TITLE = {
	normal = gLanguageCsv.getplay, -- 获取来源
	shop = {
		gLanguageCsv.spaceHandpick,
		gLanguageCsv.spaceGuild,
		gLanguageCsv.spaceFragment,
		gLanguageCsv.spacePvp,
		gLanguageCsv.explorer,
		gLanguageCsv.randomTower,
		gLanguageCsv.craft,
		gLanguageCsv.equipShop,
		gLanguageCsv.unionCombet,
		gLanguageCsv.crossCraft,
		gLanguageCsv.crossArena,
		gLanguageCsv.fishing,
		gLanguageCsv.onlineFight,
		gLanguageCsv.skin,
		gLanguageCsv.crossMine,
		gLanguageCsv.huntingArea,
	},
	activity = gLanguageCsv.activity, -- 活动面板(分页签)
	gate = gLanguageCsv.mainline, -- 关卡界面（精确到章节）
	endlessTower = gLanguageCsv.endlessTower, -- 冒险之路
	dispatchTask = gLanguageCsv.dispatch, -- 派遣
	randomTower = gLanguageCsv.randomTower, -- 以太乐园
	explorerDraw = gLanguageCsv.explorerDraw, -- 探险器寻宝
	cloneBattle = gLanguageCsv.clone, -- 元素挑战
	craft = gLanguageCsv.craft, -- 石英大会
	task = gLanguageCsv.task, --任务
	talent = gLanguageCsv.talent, -- 天赋
	fishing = gLanguageCsv.angling, -- 钓鱼
	gymChallenge = gLanguageCsv.gymChallenge,  -- 道馆挑战
	drawCard = {
		diamond = gLanguageCsv.diamondDraw,
		limit = gLanguageCsv.drawLimit,
		gold = gLanguageCsv.goldDraw,
		equip = gLanguageCsv.drawEquip,
		diamondup = gLanguageCsv.diamondUpDrawCard,
	},
	activityGate = {
		gold = gLanguageCsv.GoldTranscript,
		exp = gLanguageCsv.expTranscript,
		frag = gLanguageCsv.FragmentTranscript,
		gift = gLanguageCsv.GiftTranscript,
	},

	gemDraw = gLanguageCsv.drawGemTitle,
	megaStone = gLanguageCsv.everydayTransform,
	keyStone = gLanguageCsv.everydayTransform,
	zawakeFragExclusive = gLanguageCsv.zawakeFragExchange,
	zawakeFragCurrency = gLanguageCsv.zawakeFragExchange,
}
local ADVENTURE_TITLE = {
	endlessTower = gLanguageCsv.adventure, -- 冒险之路
	dispatchTask = gLanguageCsv.adventure, -- 派遣
	randomTower = gLanguageCsv.adventure, -- 以太乐园
	cloneBattle = gLanguageCsv.adventure, -- 元素挑战
	activityGate = gLanguageCsv.adventure, -- 活动副本
	fishing = gLanguageCsv.adventure, -- 钓鱼
	gym = gLanguageCsv.gymChallenge -- 道馆挑战
}

local ZAWAKE_TITLE = {
	zawakeFragExclusive = gLanguageCsv.zawake,
	zawakeFragCurrency = gLanguageCsv.zawake,
}

local SWEEP_TIMES = {{1, 10, 50}, {1, 3}, {1, 3, 10, 50}}
local SWEEP_TIMES_KEY = {"sweepSelected", "sweepSelectedHard", "sweepSelectedNomalAndHard"}

GainWayView.RESOURCE_FILENAME = "common_gain_way.json"
GainWayView.RESOURCE_BINDING = {
	["bg.emptyBg"] = "emptyBg",
	["bg.emptyTxt"] = "emptyTxt",
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["cardName"] = "cardNameText",
	["num1"] = {
		varname = "num1",
		binds = {
			{
				event = "effect",
				data = {color=ui.COLORS.NORMAL.DEFAULT}
			},
		}
	},
	["num"] = {
		varname = "num",
		binds = {
			{
				event = "effect",
				data = {color=ui.COLORS.NORMAL.DEFAULT}
			},{
				event = "text",
				idler = bindHelper.self("cardNum"),
			}
		}
	},
	["numTxt"] = {
		binds = {
			event = "effect",
			data = {color=ui.COLORS.NORMAL.DEFAULT}
		}
	},
	["item"] = "wayItem",
	["list"] = {
		varname = "wayList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("wayDatas"),
				item = bindHelper.self("wayItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local btnTitle = node:get("btn", "btnTitle")
					local childs = node:multiget("title", "txt", "btn", "list")
					if matchLanguage({"cn","tw"}) then
						local length = #v.title / 3
						if length == 2 then
							text.addEffect(childs.title, {size = 80})
						elseif length == 3 then
							text.addEffect(childs.title, {size = 60})
						elseif length == 4 or length == 5 then
							text.addEffect(childs.title, {size = 40})
						end
					end
					if matchLanguage({"en"}) then
						local length = math.floor(#v.title / 3)
						if length == 3 then
							text.addEffect(childs.title, {size = 45})
						elseif length == 4 then
							text.addEffect(childs.title, {size = 38})
						elseif length == 5 then
							text.addEffect(childs.title, {size = 34})
						elseif length > 5 then
							text.addEffect(childs.title, {size = 30})
						end
					end
					childs.title:text(v.title)
					btnTitle:text(v.btnTitle)
					childs.txt:text(v.txt)
					adapt.setTextAdaptWithSize(childs.txt, {size = cc.size(300, 200), vertical = "center", horizontal = "left"})

					if v.typ == WAY_TYPE.LEAVEFOR then
						node:get("btn"):loadTextureNormal("common/btn/btn_leave.png")
					else
						node:get("btn"):loadTextureNormal("common/btn/btn_normal.png")
					end
					if v.typ == WAY_TYPE.LEAVEFOR or v.typ == WAY_TYPE.MOPUP then
						cache.setShader(childs.btn, false, "normal")
						text.addEffect(btnTitle, {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
					else
						cache.setShader(childs.btn, false, "hsl_gray")
						text.deleteAllEffect(btnTitle)
						text.addEffect(btnTitle, {color = ui.COLORS.DISABLED.WHITE})
					end
					uiEasy.createItemsToList(list, childs.list, v.dropIds, {scale = 1, margin = 25})
					bind.touch(list, childs.btn, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					childs.list:setTouchEnabled(false)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onWayItemClick"),
			},
		},
	},
	["selectPanel"] = {
		varname = "selectPanel",
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				data = bindHelper.self("waySelectDatas"),
				locked = bindHelper.self("locked"),
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				showSelected = bindHelper.self("sweepSelected"),
				width = 300,
				onNode = function(node)
					node:xy(-1100, -500):z(20)
				end,
			},
		}
	},
	["cardImg"] = {
		binds = {
			event = "extend",
			class = "icon_key",
			props = {
				data = bindHelper.self("keyData"),
			},
		}
	},
	["title"] = "title",
	["title1"] = "title1",
}

function GainWayView:onCreate(key, cb, targetNum)
	self:initModel()
	self.cb = cb
	self.key = key
	self.targetNum = targetNum

	self:initTopInfo()
	self.wayItem:get("list"):setScrollBarEnabled(false)
	self.selectPanel:visible(false)

	self.sectionCsv = self:getSectionCsv()

	-- 1是普通关卡
	self.chapterType = 1
	self.wayDatas = {}
	local info = {}
	self.title:text(gLanguageCsv.specialGet)
	self.title1:text(gLanguageCsv.specialWay)
	self:initWayDatas(info)
	self:initEmpty()
	if itertools.size(info) > 1 then
		self.chapterType = 3
    else
        self.chapterType = next(info) or 1
	end

	local sweepTimes = SWEEP_TIMES[self.chapterType]
	self:initWaySelectDatas(sweepTimes)

	dataEasy.fixSaoDangLocalKey(SWEEP_TIMES_KEY[self.chapterType], sweepTimes)
	self.sweepSelected = userDefault.getForeverLocalKey(SWEEP_TIMES_KEY[self.chapterType], 1)
	local idx = math.min(#sweepTimes, self.sweepSelected)
	self.mopUpNum = sweepTimes[idx]
	self:initSweepLocked(sweepTimes)
	Dialog.onCreate(self)
end

function GainWayView:initTopInfo()
	self.keyData = {key = self.key}
	uiEasy.setIconName(self.key, nil, {node = self.cardNameText})
	text.deleteAllEffect(self.cardNameText)
	idlereasy.when(dataEasy.getListenNumByKey(self.key), function(_, val)
		self:setNum(val)
	end)
end

function GainWayView:isShowTargetNum()
	local targetNum = tonumber(self.targetNum)
	if targetNum then
		return tonumber(self.targetNum) > 1
	else
		return false
	end
end

function GainWayView:initWayDatas(info)
	local key = self.key
	local cfg = dataEasy.getCfgByKey(key)
	for i = 1, math.huge do
		if not cfg["produceGate"..i] or cfg["produceGate"..i] == "" then
			break
		end
		local arr = string.split(cfg["produceGate"..i], "-")
		local typ = WAY_TYPE.NOTOPEN
		local titleKey = arr[1]
		local gateId
		local describe = ""
		local dropIds = {}
		local title = gLanguageCsv[titleKey] or ""
		-- 冒险相关统一显示冒险
		if ADVENTURE_TITLE[titleKey] then
			title = ADVENTURE_TITLE[titleKey]
		end
		if ZAWAKE_TITLE[titleKey] then
			title = ZAWAKE_TITLE[titleKey]
		end
		--长度为1是关卡
		if #arr == 1 and tonumber(arr[1]) then
			gateId = tonumber(arr[1])
			describe, typ = self:getGateDescribe(gateId)
			titleKey = "gate"
			local gateStar = self.gateStar:read()
            local _type, chapterId, _, _title = dataEasy.getChapterInfoByGateID(gateId)
            title = _title
			if self:checkCanSweep(gateId) then
				typ = WAY_TYPE.MOPUP
				self.selectPanel:visible(true)
				info[_type] = true
			end

			local secenInfo = csv.scene_conf[gateId] or {}
			for k,v in csvMapPairs(secenInfo.dropIds or {}) do
				table.insert(dropIds, {key = k, num = v})
			end
			self.chapterType = _type
		else
			local titles = self.WAY_TITLE[titleKey]
			if type(titles) == "table" and arr[2] then
				describe = titles[tonumber(arr[2]) or arr[2]] or ""
			else
				local str = titles
				if type(titles) == "table" or titles == nil then
					str = gLanguageCsv[titleKey]
				end
				describe = string.format(gLanguageCsv.acquiringWay, str)
			end
			typ = WAY_TYPE.LEAVEFOR
			if titleKey == "shop" then
				local shopId = tonumber(arr[2]) or 1
				local unlockKey = SHOP_UNLOCK_KEY[shopId].unlockKey
				if unlockKey and (not dataEasy.isUnlock(unlockKey) or (SHOP_UNLOCK_KEY[shopId].mustHaveUion == true and not self.unionId:read()))then
					--商店未开放
					typ = WAY_TYPE.NOTOPEN
				end
			end
		end
		if self:canShow(arr) then
			table.insert(self.wayDatas, {
				title = title,
				btnTitle = WAY_BTNTITLE[typ],
				produceGate = cfg["produceGate"..i],
				typ = typ,
				txt = describe,
				gateId = gateId,
				dropIds = dropIds,
				id = cfg.id,
				targetNum = self.targetNum,
			})
		end
	end
end

function GainWayView:initWaySelectDatas(sweepTimes)
	local waySelectDatas = {}
	for i=1, #sweepTimes do
		table.insert(waySelectDatas, string.format(gLanguageCsv.sweepManyTimes, sweepTimes[i]))
	end
	self.waySelectDatas:set(waySelectDatas)
end

function GainWayView:initEmpty()
	local cfg = dataEasy.getCfgByKey(self.key)
	local isShowTip = #self.wayDatas == 0
	self.emptyTxt:visible(isShowTip)
	self.emptyBg:visible(isShowTip)
	self.emptyTxt:text(cfg.produceDesc or "")
	self.emptyBg:scale((self.emptyTxt:width() + 100) / self.emptyBg:width())
end

function GainWayView:initSweepLocked(sweepTimes)
	idlereasy.when(self.vipLevel, function(_, vipLevel)
		local sweepNum = gVipCsv[vipLevel].saodangCountOpen		--vip扫荡次数
		local privilegeSweepTimes = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.GateSaoDangTimes)--特权扫荡次数
		local state = 0
		for k = 2, #sweepTimes do
			if privilegeSweepTimes < sweepTimes[k] and sweepNum < sweepTimes[k] then
				state = k
			end
		end
		self.locked:set(state)
	end)
end

function GainWayView:getSectionCsv( )
	local sectionCsv = {}
	for k,v in csvPairs(csv.world_map) do
		local data = {}
		data.cfg = v
	 	if data.cfg.chapterType then
	 		if not sectionCsv[data.cfg.chapterType] then
	 			sectionCsv[data.cfg.chapterType] = {}
	 		end
	 		data.sortIndex = k
	 		table.insert(sectionCsv[data.cfg.chapterType], data)
	 	end
	end
	for k,v in pairs(sectionCsv) do
		table.sort(v,function(a,b)
			return a.sortIndex < b.sortIndex
		end)
	end
	return sectionCsv
end

function GainWayView:canShow(arr)
	local canShow = true
	if #arr == 1 and tonumber(arr[1]) then
		--长度为1是关卡
		local gateId = tonumber(arr[1])
		local _type, chapterId = dataEasy.getChapterInfoByGateID(gateId)
		if chapterId ~= 0 then
			local gateCsv = self.sectionCsv[_type][chapterId]
			canShow = (gateCsv ~= nil)
		end
	elseif arr[1] == "shop" then
		local shopId = tonumber(arr[2]) or 1
		local unlockKey = SHOP_UNLOCK_KEY[shopId].unlockKey
		if unlockKey and not dataEasy.isUnlock(unlockKey) then
			canShow = false
		end
		-- 多语言筛选后的商店中没有该内容道具
		if not gShopGainMap[self.key] then
			canShow = false
		end
	end
	-- 抽卡预览里没有的不显示
	if arr[1] == "drawCard" then
		if not gDrawPreviewMap[self.key] then
			canShow = false
		end
	end
	return canShow
end

function GainWayView:getGateDescribe(gateId)
	local _type, chapterId, id, title = dataEasy.getChapterInfoByGateID(gateId)
	local typ = WAY_TYPE.NOTOPEN
	local describe = ""
	if chapterId == 0 then
		typ = WAY_TYPE.LEAVEFOR
		if _type == 1 then
			describe = string.format("%s%s", gLanguageCsv.gateStory, gLanguageCsv.gate)
        else
            describe = string.format("%s%s", gLanguageCsv.gateDifficult, gLanguageCsv.gate)
		end
	else
		local gateCsv = self.sectionCsv[_type][chapterId]
		if gateCsv then
			describe = gateCsv.cfg.name
			typ = WAY_TYPE.LEAVEFOR
			if id ~= 0 then
				describe = describe .." "..chapterId.."-"..id
				typ = WAY_TYPE.NOTOPEN
			end
		end
	end
	return describe, typ
end

function GainWayView:getOtherDescribe(chapterId, _type)
	return true
end

function GainWayView:checkCanSweep(gateId)
	local gateStar = self.gateStar:read()
	return gateStar[gateId] and gateStar[gateId].star == 3
end

function GainWayView:initModel()
	self.gateStar = gGameModel.role:getIdler("gate_star") -- 星星数量
	self.roleLv = gGameModel.role:getIdler("level")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.stamina = gGameModel.role:getIdler("stamina")
	self.buyHerogateTimes = gGameModel.daily_record:getIdler("buy_herogate_times")
	self.gateTimes = gGameModel.daily_record:getIdler("gate_times")
	self.unionId = gGameModel.role:getIdler("union_db_id")
	self.locked = idler.new(0)
	self.waySelectDatas = idlertable.new()
end

function GainWayView:setNum(num)
	self.num:text(num)
	if not self:isShowTargetNum() then
		self.num1:hide()
		return
	end

	self.num1:text("/" .. self.targetNum):show()
	adapt.oneLinePos(self.num, self.num1)
	local color = ui.COLORS.NORMAL.RED
	if num >= self.targetNum then
		color = ui.COLORS.NORMAL.FRIEND_GREEN
	end
	text.addEffect(self.num, {color = color})
end

function GainWayView:onWayItemClick(list, k, v)
	if v.typ == WAY_TYPE.LEAVEFOR then
		local isMegaConversion = csv.card_mega_convert[v.id]
		local isZawakeConversion = dataEasy.isZawakeFragment(self.key)
		print_r(v)
		if isMegaConversion then
			local data = {}
			data.id = v.id
			data.num = v.targetNum
			jumpEasy.jumpTo(v.produceGate, data)
		elseif isZawakeConversion then
			local params = {
				fragID = self.key,
				needNum = v.targetNum,
			}
			jumpEasy.jumpTo(v.produceGate, params)
		else
			jumpEasy.jumpTo(v.produceGate)
		end
	elseif v.typ == WAY_TYPE.MOPUP then
		self.gateId = v.gateId
		self:onSweepBtn()
	end
end

function GainWayView:onTimesBtnClick(surplusTimes)
	local buyTimeMax = gVipCsv[gGameModel.role:read("vip_level")].buyHeroGateTimes
	local buyHerogateTimes = self.buyHerogateTimes:read()
	if (buyHerogateTimes[self.gateId] or 0) >= buyTimeMax then
		gGameUI:showTip(gLanguageCsv.herogateBuyMax)
		return
	end
	if surplusTimes > 0 then
		gGameUI:showTip(gLanguageCsv.haveChallengeTimesUnused)
		return
	end
	local strs = {
		"#C0x5b545b#"..string.format(gLanguageCsv.resetNumberEliteLevels1,gCostCsv.herogate_buy_cost[(buyHerogateTimes[self.gateId] or 0) + 1]),
		"#C0x5b545b#"..string.format(gLanguageCsv.resetNumberEliteLevels2,buyHerogateTimes[self.gateId] or 0,buyTimeMax)
	}
	gGameUI:showDialog({content = strs, cb = function()
		gGameApp:requestServer("/game/role/hero_gate/buy",function()
			gGameUI:showTip(gLanguageCsv.resetSuccess)
		end, self.gateId)
	end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
end

function GainWayView:checkSweep()
	local staminaCost = csv.scene_conf[self.gateId].staminaCost
	local curStamina = dataEasy.getStamina()
	if curStamina < staminaCost then
		gGameUI:stackUI("common.gain_stamina")
		return false
	end
	self.curMopUpNum = math.min(self.mopUpNum, math.floor(curStamina / staminaCost))	-- 本次可扫荡最大次数

	local sceneCsv = csv.scene_conf[self.gateId]
	local surplusTimes = sceneCsv.dayChallengeMax
	if self.gateTimes:read()[self.gateId] then
		surplusTimes = surplusTimes - self.gateTimes:read()[self.gateId]
	end
	-- 今天的重置次数
	local buyHerogateTimes = self.buyHerogateTimes:read()[self.gateId] or 0
	local state, paramMaps, count = dataEasy.isDoubleHuodong("heroGateTimes")
	if state then
		for i, paramMap in pairs(paramMaps) do
			local addTimes = paramMap["count"]
			if addTimes and addTimes > 0 then
				if  buyHerogateTimes == 0 then
					surplusTimes = surplusTimes + addTimes
				end
			end
		end
	end
	if surplusTimes and surplusTimes <= 0 then
		self:onTimesBtnClick(surplusTimes)
		return false
	end

	return true
end

function GainWayView:onSweepBtn()
	if not self:checkSweep() then
		return
	end

	local gateId = self.gateId
	local oldRoleLv = self.roleLv:read()
	local oldCapture = gGameModel.capture:read("limit_sprites")
	gGameApp:requestServer("/game/saodang",function (tb)
		local items = tb.view.result
		table.insert(items, {exp=0, items=tb.view.extra, isExtra=true})
		gGameUI:stackUI("city.gate.sweep", nil, nil, {
			sweepData = items,
			oldRoleLv = oldRoleLv,
			cb = self:createHandler("onSweepBtn"),
			checkCb = self:createHandler("checkSweep"),
			hasExtra = true,
			from = "gainWay",
			targetNum = self.targetNum,
			targetId = self.key,
			oldCapture = oldCapture,
			gateId = gateId,
			curMopUpNum = self.curMopUpNum,
			isDouble = dataEasy.isGateIdDoubleDrop(gateId),
			catchup = tb.view.catchup
		})
	end, gateId, self.curMopUpNum, self.key, self.targetNum and (self.targetNum - dataEasy.getNumByKey(self.key)))
	return true
end

function GainWayView:onSortMenusBtnClick(panel, node, k, v)
	local tab = SWEEP_TIMES[self.chapterType]
	local state = dataEasy.getSaoDangState(tab[k])
	if not state.canSaoDang then
		gGameUI:showTip(state.tip)
		return
	end
	self.mopUpNum = tab[k]
	userDefault.setForeverLocalKey(SWEEP_TIMES_KEY[self.chapterType], k)
end

function GainWayView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return GainWayView