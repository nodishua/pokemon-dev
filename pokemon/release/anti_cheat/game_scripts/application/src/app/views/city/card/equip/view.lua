-- @desc: 卡牌羁绊

local CardEquipView = class("CardEquipView", cc.load("mvc").ViewBase)

local function createForeverAnim(x, y)
	return cc.RepeatForever:create(
		cc.Sequence:create(
			cc.DelayTime:create(0.1),
			cc.MoveTo:create(0.3, cc.p(x, y + 10)),
			cc.DelayTime:create(0.1),
			cc.MoveTo:create(0.3, cc.p(x, y))
		)
	)
end


local getItemShowDetail =
{
	"showStrengthenItem",
	"showStarItem",
	"showAwakeItem",
	"showSignetItem",
}

CardEquipView.RESOURCE_FILENAME = "card_equip.json"
CardEquipView.RESOURCE_BINDING = {
	["item"] = "item",
	["panel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("equipDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						event = "extend",
						class = "equip_icon",
						props = {
							data = v,
							selected = v.isSel,
							onNode = function(panel)
								panel:setTouchEnabled(false)
								local arrow = panel:get("imgArrow")
								arrow:visible(v.state == true)
								if not v.originY then
									v.originX, v.originY = arrow:xy()
								end
								if v.action then
									arrow:stopAction(v.action)
									v.action = nil
								end
								if v.state then
									v.action = createForeverAnim(v.originX, v.originY)
									arrow:runAction(v.action)
								end
								panel:xy(10, 10)
							end,
						}
					})
					bind.touch(list, node, {methods = {ended = function()
						return list.clickCell(k, v)
					end}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onEquipClick"),
			},
		},
	},
	["panel.icon"] = "icon",
	["panel.name"] = "panelName",
	["panel"] = "panel",
}

function CardEquipView:onCreate(dbHandler)
	-- 适配处理，界面相对中间块和右边块的中心
	adapt.centerWithScreen(nil, "right", nil, {
		{self.panel, "pos", "center"},
	})
	if not dbHandler then
		dbHandler = function()
			local cards = gGameModel.role:read("cards")
			return cards[1], idler.new(1), idler.new(1), idler.new(2)
		end
	end
	self.selectDbId, self.selectIndex, self.tabKey, self.state = dbHandler()
	self:initModel()

	self.equipDatas = idlers.newWithMap({})

	idlereasy.any({self.equips, self.tabKey, self.state, self.items, self.level}, function (_, val, tabKey, state, items, level)
		self.equipDatas:update(clone(val))
		self.equipDatas:atproxy(self.selectIndex:read()).isSel = true

		if state == 2 then
			for i = 1, self.equipDatas:size() do
				local proxy = self.equipDatas:atproxy(i)
				local cfg = csv.equips[proxy.equip_id]
				if self[getItemShowDetail[tabKey]] then
					self[getItemShowDetail[tabKey]](self, cfg, proxy)
				end
			end
		end

		self.selectIndex:notify()
	end):anonyOnly(self)


	self.selectIndex:addListener(function (val, oldval)
		local oldEquip = self.equipDatas:atproxy(oldval)
		if oldEquip then
			oldEquip.isSel = false
		end

		local currData = self.equipDatas:atproxy(val)
		if currData == nil then
			return
		end

		local cfg = csv.equips[currData.equip_id]
		local baseName, icon
		if currData.awake ~= 0  then
			baseName = cfg.name1..gLanguageCsv["symbolRome"..currData.awake]
			icon = cfg.icon2
		else
			baseName = cfg.name0
			icon = cfg.icon
		end
		local quality, numStr = dataEasy.getQuality(currData.advance)
		text.addEffect(self.panelName, {color= quality == 1 and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.QUALITY[quality]})
		baseName = baseName .. numStr
		self.panelName:text(baseName)
		self.icon:texture(icon)

		currData.isSel = true
	end)

end

function CardEquipView:initModel()
	idlereasy.when(self.selectDbId,function (_, selectDbId)
		local card = gGameModel.cards:find(selectDbId)
		self.equips = idlereasy.assign(card:getIdler("equips"), self.equips)
		self.selectIndex:notify()
	end)
	self.items = gGameModel.role:getIdler("items")
	self.level = gGameModel.role:getIdler("level")
end

function CardEquipView:showStarItem(cfg, proxy)
	local isNotStarMax = proxy.star ~= cfg.starMax
	local isEnoughItem = true
	for key,v in csvMapPairs(csv.base_attribute.equip_star[proxy.star]["costItemMap"..cfg.starSeqID]) do
		if key ~= "gold" then
			local hasNum = dataEasy.getNumByKey(key)
			if hasNum < v then
				isEnoughItem = false
				break
			end
		end
	end
	proxy.state = isEnoughItem and isNotStarMax
	if proxy.star == cfg.starMax and dataEasy.isUnlock(gUnlockCsv.equipAbility) then
		local ability = proxy.ability or 0
		local isEnoughAblityItem = true
		local isNoteAbilityMax = ability ~= cfg.abilityMax
		for key,v in csvMapPairs(csv.base_attribute.equip_ability[ability]["costItemMap"..cfg.abilitySeqID]) do
			local hasNum = dataEasy.getNumByKey(key)
			if hasNum < v then
				isEnoughAblityItem = false
				break
			end
		end
		proxy.state = isEnoughAblityItem and isNoteAbilityMax
	end
end

function CardEquipView:showStrengthenItem(cfg, proxy)
	local level = self.level:read()
	local currLevelLimit = cfg.strengthMax[proxy.advance]
	local maxLevel = cfg.strengthMax[csvSize(cfg.strengthMax)]
	if proxy.level < currLevelLimit then
		proxy.state = true
	else
		local isEnoughItem = true
		for k,v in csvMapPairs(gEquipAdvanceCsv[proxy.equip_id][proxy.advance]["costItemMap"]) do
			local hasNum = dataEasy.getNumByKey(k)
			if v > hasNum and isEnoughItem then
				isEnoughItem = false
				break
			end
		end
		local currRoleLimitLevel = cfg.roleLevelMax[proxy.advance]
		local isEnoughLevel = level >= currRoleLimitLevel
		proxy.state = isEnoughLevel and isEnoughItem
	end
end

function CardEquipView:showAwakeItem(cfg, proxy)
	local awake = proxy.awake or 0
	local isEnoughItem = true
	local isNotAwakeMax = awake ~= cfg.awakeMax
	for key,v in csvMapPairs(csv.base_attribute.equip_awake[awake]["costItemMap"..cfg.awakeSeqID]) do
		local hasNum = dataEasy.getNumByKey(key)
		if hasNum < v then
			isEnoughItem = false
			break
		end
	end
	proxy.state = isEnoughItem and isNotAwakeMax
	if awake == cfg.awakeMax and dataEasy.isUnlock(gUnlockCsv.equipAwakeAbility) then
		local ability = proxy.awake_ability or 0
		local isEnoughAblityItem = true
		local isNoteAbilityMax = ability ~= cfg.awakeAbilityMax
		for key,v in csvMapPairs(csv.base_attribute.equip_awake_ability[ability]["costItemMap"..cfg.awakeAbilitySeqID]) do
			local hasNum = dataEasy.getNumByKey(key)
			if hasNum < v then
				isEnoughAblityItem = false
				break
			end
		end
		proxy.state = isEnoughAblityItem and isNoteAbilityMax
	end
end

function CardEquipView:showSignetItem(cfg, proxy)
	local isEnoughItem = true
	local isNotSignetMax = proxy.signet ~= cfg.signetStrengthMax[table.getn(cfg.signetStrengthMax)]
	if isNotSignetMax then
		for key,v in csvMapPairs(csv.base_attribute.equip_signet[proxy.signet]["costItemMap"..cfg.signetStrengthSeqID]) do
			local hasNum = dataEasy.getNumByKey(key)
			if hasNum < v then
				isEnoughItem = false
				break
			end
		end
	end

	local isNotSignetAdvanceMax = proxy.signet_advance ~= cfg.signetAdvanceMax
	if isNotSignetAdvanceMax and proxy.signet == (proxy.signet_advance + 1) * 5 then
		for i,v in csvPairs(csv.base_attribute.equip_signet_advance) do
			if v.advanceIndex == cfg.advanceIndex and v.advanceLevel == proxy.signet_advance + 1 then
				for key,value in csvMapPairs(csv.base_attribute.equip_signet_advance_cost[proxy.signet_advance]["costItemMap"..v.advanceSeqID]) do
					local hasNum = dataEasy.getNumByKey(key)
					if hasNum < value then
						isEnoughItem = false
						break
					end
				end
			end
		end
	end
	proxy.state = isEnoughItem and isNotSignetAdvanceMax
end


function CardEquipView:onEquipClick(list, k, v)
	self.selectIndex:set(k)
end

-- @desc:计算饰品相关属性值
-- @data:当前饰品的数据
-- @index:属性的索引值
-- @showType:{star, advance, strengthen} 类型
-- @targetData: 目标饰品的数据（如果为空，则默认根据showType进行下一阶段的属性值计算）
-- @return:[attr, currval, nextval]属性类型， 当前值， 目标值
function CardEquipView.getAttrNum(data, index, showType, targetData)
	local cfg = csv.equips[data.equip_id]
	local attrStar = cfg["attrStarC"..index]
	-- 有效性判断，超过范围直接return
	if not attrStar  then
		return 0
	end

	local currStar = data.star + 1
	local currAdvance = data.advance
	local currLevel = data.level
	local currAwake = data.awake or 0
	local currAbility = data.ability or 0
	local currSignet = data.signet or 0
	local currAwakeAbility = data.awake_ability or 0
	targetData = targetData or {}

	local nextStar = currStar
	local nextAbility = currAbility
	local nextAdvance = currAdvance
	local nextLevel = currLevel
	local nextSignet = currSignet
	local attrStar = cfg["attrStarC"..index]
	local attrNum = cfg["attrNum"..index]
	local attrStarNum = cfg["attrStarNum"..index]
	local attrAdvanceNum = cfg["attrAdvanceNum"..index]
	local awakeAttrNum = cfg["awakeAttrNum"..index]
	local abilityAttr = cfg["abilityAttr"]
	local signetAttr = cfg["signetAttrNum"..index]
	local awakeAbilityNum = cfg["awakeAbilityAttrNum"..index]

	-- 判断下方，数据判断应该下放到各个模块中区
	-- if not attrStar or not attrNum or not attrStarNum or not attrAdvanceNum or not awakeAttrNum or not abilityAttr or not signetAttr or not awakeAbilityNum then
	-- 	return 0
	-- end
	local attr = cfg["attrType"..index]
	local currVal = attrStar[currStar] * (attrNum[currAdvance] + attrStarNum[currStar] + attrAdvanceNum[currAdvance] * currLevel)
	local nextVal

	local getVal = {
		star = function()
			nextStar = targetData.star or currStar + 1
			if data.star == cfg.starMax then
				nextVal = 0
			end

			return currVal, nextVal
		end,

		ability = function()
			if currAbility ~= cfg.abilityMax then
				nextVal = currVal * (100 + tonumber(string.sub(cfg.abilityAttr[currAbility + 1], 1, -2))) / 100
			else
				nextVal = 0
			end
			if currAbility > 0 then
				currVal = currVal * (100 + tonumber(string.sub(cfg.abilityAttr[currAbility], 1, -2))) / 100
			end
			return currVal, nextVal
		end,

		advance = function()
			nextLevel = targetData.level or currLevel
			nextAdvance = targetData.advance or currAdvance + 1
			if data.advance == cfg.advanceMax then
				nextVal = 0
			end
			return currVal, nextVal
		end,

		strengthen = function()
			nextLevel = targetData.level or currLevel + 1
			if data.level == cfg.strengthMax[csvSize(cfg.strengthMax)] then
				nextVal = 0
			end
			return currVal, nextVal
		end,

		awake = function()
			attr = cfg["awakeAttrType"..index] 		-- 觉醒属性做了单独配置
			currVal, nextVal = dataEasy.getAttrValueAndNextValue(attr, awakeAttrNum[currAwake] or 0, awakeAttrNum[currAwake + 1])
			return currVal, nextVal
		end,

		signet = function()
			attr = cfg["signetAttrType"..index] 		-- 刻印属性做了单独配置
			currVal, nextVal = dataEasy.getAttrValueAndNextValue(attr, signetAttr[currSignet] or 0, signetAttr[currSignet + 1])
			return currVal, nextVal
		end,

		awakeAbility = function()
			attr = cfg["awakeAbilityAttrType"..index]	-- 觉醒潜能属性做了单独配置
			currVal, nextVal = dataEasy.getAttrValueAndNextValue(attr, awakeAbilityNum[currAwakeAbility] or 0, awakeAbilityNum[currAwakeAbility + 1])
			return currVal, nextVal
		end,
	}

	if getVal[showType] then
		currVal, nextVal = getVal[showType]()
	end

	if not nextVal then
		nextVal = attrStar[nextStar] * (attrNum[nextAdvance] + attrStarNum[nextStar] + attrAdvanceNum[nextAdvance] * (nextLevel))
	end
	return attr, currVal, nextVal
end

return CardEquipView