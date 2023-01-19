

local TYPE = {
	--星级
	STAR = 1,
	--觉醒
	AWAKE = 2
}

local ViewBase = cc.load("mvc").ViewBase
local CardSignetOneKeyView = class("CardSignetOneKeyView", Dialog)

CardSignetOneKeyView.RESOURCE_FILENAME = "card_equip_fast_strengthen.json"
CardSignetOneKeyView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["top.cashNum"] = "cashNum",
	["top.cashIcon"] = "cashIcon",
	["top.nameMax"] = "nameMax",
	["top.name"] = "cardName",
	["top.subBtn"] = {
		varname = "subBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["top.addBtn"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
	["breakBtn"] = {
		varname = "breakBtn",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onOneKeyAdvanceClick")}
			},
			{
				event = "visible",
				idler = bindHelper.self("signetBreak")
			},
		},
	},
	["sureBtn"] = {
		varname = "sureBtn",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onOneKeyAdvanceClick")}
			},
			{
				event = "visible",
				idler = bindHelper.self("signetSelect")
			},
		},
	},
	["cancelBtn"] = {
		varname = "cancelBtn",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onClose")}
			},
			{
				event = "visible",
				idler = bindHelper.self("signetSelect")
			},
		},
	},
	["cancelBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["sureBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["card"] = {
		binds = {
			event = "extend",
			class = "equip_icon",
			props = {
				data = bindHelper.self("equipData"),
				selected = false,
				onNode = function(panel)
					panel:setTouchEnabled(false)
					panel:get("imgArrow"):hide()
				end,
			},
		}
	},
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemData"),
				columnSize = 6,
				dataOrderCmpGen = bindHelper.self("onSortRank", true),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				onCell = function(list, node, k, v)
					local size = node:size()
					local binds = {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = v.num,
								targetNum = v.targetNum
							},
							grayState = v.num < v.targetNum and 1 or 0,
							onNode = function(node)
								node:setTouchEnabled(false)
								local size = node:size()
								local addIcon = node:get("addIcon")
								if v.targetNum > v.num then
									if not addIcon then
										ccui.ImageView:create("common/btn/btn_add_icon.png")
											:xy(size.width/2, size.height/2)
											:addTo(node, 600, "addIcon")
									else
										addIcon:show()
									end
								else
									if addIcon then
										addIcon:hide()
									end
								end
							end,
						},
					}
					bind.extend(list, node, binds)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
				asyncPreload = 12,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		}
	},
	["titleTxt1"] = "titleTxt1",
	["titleTxt2"] = "titleTxt2",
	["title"] = "title",
}

function CardSignetOneKeyView:initModel()
	idlereasy.when(self.selectDbId,function (_, selectDbId)
		local card = gGameModel.cards:find(selectDbId)
		self.equips = idlereasy.assign(card:getIdler("equips"), self.equips)
		self.fight = idlereasy.assign(card:getIdler("fighting_point"), self.fight)
	end)
	self.roleLv = gGameModel.role:getIdler("level")
	self.gold = gGameModel.role:read("gold")
end

function CardSignetOneKeyView:onCreate(selectDbId, equipId, cb)
	self.selectDbId = idler.new(selectDbId)
	self.cb = cb
	self.signetBreak = idler.new(false)
	self.signetSelect = idler.new(true)
	self:enableSchedule()
	self:initModel()
	self.titleTxt1:text(gLanguageCsv.oneKey)
	self.titleTxt2:text(gLanguageCsv.signet)
	self.title:text(gLanguageCsv.oneKeySignet)

	local cfg = csv.equips[equipId]
	self.equipData = self.equips:read()[cfg.part]
	-- 设置名字
	local baseName = cfg.name0
	if self.equipData.awake ~= 0  then
		baseName = cfg.name1..gLanguageCsv["symbolRome"..self.equipData.awake]
	end
	local quality, numStr = dataEasy.getQuality(self.equipData.advance)
	text.addEffect(self.cardName, {color= quality == 1 and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.QUALITY[quality]})
	baseName = baseName .. numStr
	self.cardName:text(baseName)

	-- 当前版本最大等级
	local currLevelLimit = cfg.signetStrengthMax[cfg.signetAdvanceMax]
	self.currLevelLen = cfg.signetAdvanceMax
	local advance = self.equipData.signet_advance or 0
	local equipId = self.equipData.equip_id
	local level = self.equipData.signet or 0
	self.level = level
	self.advance = advance
	self.upgradeLv = level + 1
	self.leftQuality = ""

	-- 默认选择满足条件的最大等级
	local maxLv = self:upLevelMax(currLevelLimit, cfg)
	-- 整理数据根据，拿到突破和显示等级
	local varLv = level
	local advanceLv = advance
	local shwoLv = level%5

	for i=1, math.huge do
		if varLv % 5 ~= 0 then
			varLv = varLv + 1
			shwoLv = varLv % 5 == 0 and 5 or varLv % 5
		elseif shwoLv == 0 then
			varLv = varLv + 1
			shwoLv = 1
		else
			advanceLv = advanceLv + 1
			shwoLv = 0
		end
		if varLv >= maxLv then
			if maxLv == currLevelLimit and shwoLv == 4 then
				shwoLv = 5
			end
			break
		end
	end
	self.advanceLv = advanceLv
	self.shwoLv = shwoLv
	self.varLv = varLv
	self.upMaxLv = maxLv
	self.upMinLv = level + 1

	self.selectLv = idler.new(maxLv)
	self.itemData = idlertable.new({})
	idlereasy.when(self.selectLv, function(_, selectLv)
		self.upgradeLv = self.advanceLv * 5 + self.shwoLv
		self.advanceId = self.advanceLv
		local roleGood = self:updataShowAward(cfg)

		-- 是否满足add/sub
		if self.upgradeLv <= maxLv then
			self.isEnoughGoldStrengthen = dataEasy.getNumByKey("gold") >= roleGood
			local rightQuality = self:updataAttribute(cfg.advanceIndex)

			self.nameMax:text(rightQuality.." "..self.shwoLv..gLanguageCsv.signetLevel)
			self.rightQuality = rightQuality.." "..self.shwoLv..gLanguageCsv.signetLevel
			self.cashNum:text(roleGood)
			local coinColor = self.isEnoughGoldStrengthen and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.RED
			text.addEffect(self.cashNum, {color = coinColor})
			adapt.oneLinePos(self.cashNum, self.cashIcon, cc.p(12, 0))

			cache.setShader(self.addBtn, false, (self.upgradeLv >= self.upMaxLv) and "hsl_gray" or  "normal")
			self.addBtn:setTouchEnabled(self.upgradeLv < self.upMaxLv)
			-- 强化的时候回穿插突破，所以要在当前等级减去满足突破的次数和已经突破的次数
			local subSign1, subSign2 = false, false
			if self.upgradeLv >= self.upMinLv and self.advanceLv >= self.advance then
				subSign1 = true
				subSign2 = true
			end
			if self.upgradeLv == self.upMinLv and self.advanceLv == self.advance then
				subSign2 = false
			end
			cache.setShader(self.subBtn, false, not subSign2 and "hsl_gray" or  "normal")
			self.subBtn:setTouchEnabled(subSign1)
		else
			gGameUI:showTip(gLanguageCsv.equipNotEnoughSignetItems)
		end
	end)

	Dialog.onCreate(self)
end

--计算最大可以提升的等级
function CardSignetOneKeyView:upLevelMax(currLevelLimit, cfg)
	local signetLevel, signetAdvance = true, true
	local dataItems = {}
	local maxLv = self.level
	local whetherAdvance = self.advance * 5 ~= self.level

	-- 整理突破数据
	local advanceData = {}
	for i, var in ipairs(cfg.signetStrengthMax) do
		advanceData[var] = var
	end

	for i = self.level, currLevelLimit do
		if not signetLevel or not signetAdvance then
			break
		end
		if i < currLevelLimit then
			for key, num in csvMapPairs(csv.base_attribute.equip_signet[i]["costItemMap"..cfg.signetStrengthSeqID]) do
				if key ~= "gold" then
					dataItems[key] = dataItems[key] or {targetNum = 0}
					local addNum = dataItems[key].targetNum + num
					if dataEasy.getNumByKey(key) < addNum then
						signetLevel = false
						break
					end
					dataItems[key].targetNum = addNum
				end
			end
		end
		if whetherAdvance then
			if advanceData[i] then
				local advanceId = math.floor(i / 6)
				for key,num in csvMapPairs(csv.base_attribute.equip_signet_advance_cost[advanceId]["costItemMap"..cfg.advanceIndex]) do
					if key ~= "gold" then
						dataItems[key] = dataItems[key] or {targetNum = 0}
						local addNum = dataItems[key].targetNum + num
						if dataEasy.getNumByKey(key) < addNum then
							signetAdvance = false
							break
						end
						dataItems[key].targetNum = addNum
					end
				end
			end
		else
			whetherAdvance = true
		end
		maxLv = i
	end
	return maxLv
end

-- 刷新当前等级对应消耗
function CardSignetOneKeyView:updataShowAward(cfg)
	local roleGood = 0
	local needItems = {}
	self.signetAdvanceData = {}
	for i = self.level, self.upgradeLv -1 do
		for key, num in csvMapPairs(csv.base_attribute.equip_signet[i]["costItemMap"..cfg.signetStrengthSeqID]) do
			if key ~= "gold" then
				needItems[key] = needItems[key] or {id = key, num = dataEasy.getNumByKey(key), targetNum = 0, orderKey = 1}
				local addNum = needItems[key].targetNum + num
				if dataEasy.getNumByKey(key) < addNum then
					needItems[key].orderKey = 2
					break
				end
				needItems[key].targetNum = addNum
			else
				roleGood = roleGood + num
			end
		end
		--加成
		for j=1,math.huge do
			local signetAttr = cfg["signetAttrType" .. j]
			if not signetAttr or signetAttr == 0 then
				break
			end
			local attrTypeStr = game.ATTRDEF_TABLE[signetAttr]
			local str = "attr" .. string.caption(attrTypeStr)
			local num, nextNum = dataEasy.getAttrValueAndNextValue(signetAttr, cfg["signetAttrNum"..j][i] or 0, cfg["signetAttrNum"..j][i+1] or 0)
			if not self.signetAdvanceData[j] then
				self.signetAdvanceData[j] = {num1 = num, num2 = nextNum}
			else
				self.signetAdvanceData[j].num2 = self.signetAdvanceData[j].num2 + (nextNum - num)
			end
		end
	end
	for i, var in ipairs(cfg.signetStrengthMax) do
		if i-1 >= self.advance and i-1 < self.advanceId then
			for key,num in csvMapPairs(csv.base_attribute.equip_signet_advance_cost[i-1]["costItemMap"..cfg.advanceIndex]) do
				if key ~= "gold" then
					needItems[key] = needItems[key] or {id = key, num = dataEasy.getNumByKey(key), targetNum = 0, orderKey = 1}
					local addNum = needItems[key].targetNum + num
					if dataEasy.getNumByKey(key) < addNum then
						needItems[key].orderKey = 2
						signetAdvance = false
						break
					end
					needItems[key].targetNum = addNum
				else
					roleGood = roleGood + num
				end
			end
		end
	end
	self.itemData:set(needItems)
	return roleGood
end

--刷新当前等级对应的属性等信息
function CardSignetOneKeyView:updataAttribute(advanceIndexCfg)
	local rightQuality = ""
	for i,v in csvPairs(csv.base_attribute.equip_signet_advance) do
		if v.advanceIndex == advanceIndexCfg and v.advanceLevel == self.advanceLv then
			rightQuality = v.advanceName
			local detail = {}
			for j=1,math.huge do
				local signetAttr = v["attrType"..j]
				if not signetAttr or signetAttr == 0 then
					break
				end
				local attrTypeStr = game.ATTRDEF_TABLE[signetAttr]
				local str = "attr".. string.caption(attrTypeStr)
				table.insert(detail,{
					name = gLanguageCsv[str],
					num = dataEasy.getAttrValueString(signetAttr, v["attrNum"..j])
				})
			end
			local strAttr = ""
			for i=1,#detail do
				strAttr = strAttr..detail[i].name.."+"..detail[i].num.."  "
			end

			local scene = ""
			if v.sceneType then
				for k,val in csvMapPairs(v.sceneType) do
					local num = val
					local text = game.SCENE_TYPE_STRING_TABLE[num]
					scene = scene..gLanguageCsv[text]
					if k < table.getn(v.sceneType) then
						scene = scene..gLanguageCsv.signetAnd
					end
				end
			end
			local str = string.format(gLanguageCsv.signetBeiDong,v.advanceLevel,scene)
			strAttr = str..strAttr
			self.strAttr = strAttr
		end
		--一键前的advance数据
		local roleLv = self.level - self.advance * 5
		if v.advanceIndex == advanceIndexCfg and v.advanceLevel == self.advance then
			self.leftQuality = v.advanceName.." "..roleLv..gLanguageCsv.signetLevel
		end

		--需要饰品两星
		if v.advanceLimitType then
			if v.advanceLimitType == TYPE.STAR then
				if self.equipData.star < v.advanceLimitNum then
					self.limitTip = string.format(gLanguageCsv.needEquipStar, v.advanceLimitNum)
				end
			elseif  v.advanceLimitType == TYPE.AWAKE then
				if self.equipData.awake <v.advanceLimitNum then
					self.limitTip = gLanguageCsv.needEquipAwake..gLanguageCsv["symbolRome"..v.advanceLimitNum]
				end
			end
		else
			self.limitTip = 0
		end
	end
	return rightQuality
end


function CardSignetOneKeyView:onChangeNum(node, event, step)
	local isHas = false
	if event.name == "click" then
		self:unScheduleAll()
		isHas = true
		self:onIncreaseNum(step)

	elseif event.name == "began" then
		isHas = true
		self:schedule(function()
			self:onIncreaseNum(step)
		end, 0.05, 0, 1)

	elseif event.name == "ended" or event.name == "cancelled" then
		self:unScheduleAll()
		if not isHas then
			self:onIncreaseNum(step)
		end
	end
end

function CardSignetOneKeyView:onIncreaseNum(step)
	local selectLv = self.selectLv:read()
	if step > 0 then
		local num = self.advanceLv*5 + self.shwoLv
		if (self.upMaxLv == num) or (self.shwoLv == 5 and self.advanceLv == self.currLevelLen - 1) then
			--达到配置的最大等级是只能在外面突破，其余可以在一键里突破
			self:unScheduleAll()
		else
			if self.shwoLv == 4 then
				self.shwoLv = self.shwoLv + 1
			elseif self.shwoLv == 5 then
				self.advanceLv = self.advanceLv + 1
				self.shwoLv = 0
			else
				self.shwoLv = self.shwoLv + 1
			end
		end
	else
		local num = self.advanceLv*5 + self.shwoLv
		if num <= self.level + 1 and self.advanceLv <= self.advance then
			self:unScheduleAll()
		else
			if self.shwoLv == 1 then
				self.shwoLv = 0
			elseif self.shwoLv == 0 then
				self.advanceLv = self.advanceLv - 1
				self.shwoLv = 5
			else
				self.shwoLv = self.shwoLv - 1
			end
		end
	end
	-- +1只做刷新使用
	self.selectLv:set(selectLv + 1)
end

function CardSignetOneKeyView:onOneKeyAdvanceClick()
	if not self.isEnoughGoldStrengthen then
		gGameUI:showTip(gLanguageCsv.strengthGoldNotEnough)
		return
	end
	local fight = self.fight:read()
	local data = self.equipData
	local cfg = csv.equips[data.equip_id]
	local signet = data.signet or 0
	local signetAdvance = data.signet_advance or 0
	local isHas = true
	local cb = function()
		self:addCallbackOnExit(functools.partial(self.cb, 1))
		Dialog.onClose(self)
	end

	local showOver = {false}
	local textBD = matchLanguage({"kr"}) and self.strAttr or string.sub(self.strAttr,10)
	gGameApp:requestServerCustom("/game/equip/signet")
		:params(self.selectDbId, cfg.part, self.upgradeLv, true, self.advanceId)
		:onResponse(function (tb)
			if signetAdvance < self.advanceId then
				isHas = false
				idlereasy.do_(function (equips)
					gGameUI:stackUI("city.card.equip.success", nil, {blackLayer = true}, {
						leftItem = data,
						rightItem = equips[cfg.part],
						type = "signetAdvance",
						fight = fight,
						cardDbid = self.selectDbId:read(),
						leftQuality = self.leftQuality,
						rightQuality = self.rightQuality,
						textBD = textBD,
						limitTip = self.limitTip or 0,
						isMax = self.advanceId >= cfg.signetAdvanceMax,
						signetAdvanceData = self.signetAdvanceData,
						cb = cb,
					})
					showOver[1] = true
				end, self.equips)
			else
				showOver[1] = true
			end
			end)
		:wait(showOver)
		:doit(function()
			if isHas and signetAdvance >= self.advanceId then
				gGameUI:showTip(gLanguageCsv.signetOk)
				cb()
			end
		end)
end

function CardSignetOneKeyView:onItemClick(list, k, v)
	gGameUI:stackUI("common.gain_way", nil, nil, v.id, self:createHandler("refreshUI"), v.num)
end
function CardSignetOneKeyView:refreshUI()
	self.selectLv:notify()
end
--排序
function CardSignetOneKeyView:onSortRank(list)
	return function(a, b)
		return a.orderKey > b.orderKey
	end
end
return CardSignetOneKeyView
