-- @date 2021-5-8
-- @desc 学习芯片工具类 （通用方法）

local MAXQUALITY = 6

local ChipTools = {}

-- @desc 是否装备在精灵上
function ChipTools.isDress(dbId)
	if dbId then
		local dbData = gGameModel.chips:find(dbId)
		if dbData and dbData:read("card_db_id") then
			return true
		end
	end
	return false
end

-- 判断芯片是否在方案中
function ChipTools.isChipPlan(dbIds)
	if type(dbIds) ~= "table" then
		dbIds = {dbIds}
	end
	local chipPanel = {}
	local plans = gGameModel.role:read("chip_plans")
	for _, data in pairs(plans) do
		for _, key in pairs(data.chips or {}) do
			chipPanel[key] = true
		end
	end
	for _, dbid in pairs(dbIds) do
		if chipPanel[dbid] then
			return true
		end
	end

	return false
end
-- @desc 获得套装的图标，激活2件套未激活4件套的显示一半的图标
-- @param data
-- 	{
-- 		{2, quality, isActive}, -- 2件套的品质，是否激活
-- 		{4, quality, isActive}, -- 4件套的品质，是否激活
-- 	}
function ChipTools.getSuitRes(suitId, data)
	local res = gChipSuitCsv[suitId][2][2].suitIcon
	if data and data[1][3] and not data[2][3] then
		res = string.gsub(res, "0.png", "1.png")
	end
	return res
end

-- 副属性和主属性汇总，同类型相加
function ChipTools.setAttrCollect(map1, map2)
	for index = 1, table.maxn(map2) do
		if map2[index] then
			map1[index] = map1[index] or {}
			for key, val in pairs(map2[index]) do
				map1[index][key] =  dataEasy.attrAddition(map1[index][key], val)
			end
		end
	end

	return map1
end

-- @desc 属性累加会有固定值和百分比同时存在 1、固定值，2百分比
-- @param count 获取属性值 count 表示副属性的强化等级
-- 配置检测， 一条副属性上多条属性合并成一条
function ChipTools.setAttrAddition(data, cfg, count, isArray, params)
	local arrayKey = nil
	for index = 1, math.huge do
		local key = cfg[string.format("attrType%d", index)]
		if key and key ~= 0 then
			local val = cfg[string.format("attrNum%d", index)]
			if count then
				val = val[count + 1]
			end
			local str = dataEasy.getAttrValueString(key, val)
			local hasPercent = string.find(str, "%%")
			local idx = hasPercent and 2 or 1
			if isArray then
				if not ChipTools.ignoreAttr(key) then
					if arrayKey then
						errorInWindows("配置异常，csv.chip.chips[%d] 副属性不能显示 %s(%s), %s(%s)", params.chipId, game.ATTRDEF_TABLE[arrayKey], arrayKey, game.ATTRDEF_TABLE[key], key)
					else
						if count then
							arrayKey = key
						end
						local t = clone(params or {})
						t.key = key
						t.val = str
						table.insert(data, t)
					end
				end
			else
				data[idx][key] = dataEasy.attrAddition(data[idx][key], str)
			end
		else
			break
		end
	end
	return data
end

-- @desc 获取芯片的属性值
-- @param dbId chip的dbId
-- @return 前面map主属性，副属性数量, 按配置顺序显示
-- 		{{key = 7, val = 20}, {key = 7, val = 30}, {key = 8, val = 100}, {key = 7, val = 2%}}, {},
function ChipTools.getAttrByChipId(id)
	local cfg = csv.chip.chips[id]
	local firstAttrs = {}
	local secondAttrs = {}

	local attrID = cfg.mainAttr
	if attrID and attrID ~= 0 then
		ChipTools.setAttrAddition(firstAttrs, gChipMainAttrCsv[attrID][1], nil, true)
	end

	local secondAttrCount = cfg.startNum + cfg.acquiredLimit
	-- 副属性显示 ????  ??
	for i = 1, cfg.startNum do
		table.insert(secondAttrs, {name = gLanguageCsv.randomAttributes, val = gLanguageCsv.chipDetailInfo01 })
	end

	for i = 1, cfg.acquiredLimit do
		table.insert(secondAttrs, {name = gLanguageCsv.randomAttributes,
			val = string.format(gLanguageCsv.nLvUnlock, cfg.acquiredLevels[i])})
	end

	return firstAttrs, secondAttrs
end

-- @desc 获取芯片的属性值
-- @param dbId chip的dbId
-- @return 前面map主属性，后面map副属性
--     isArray false {{[7] = 50, [8] = 100}, {[7] = 2%}}, {{}, {}},
--     isArray true {{key = 7, val = 20}, {key = 7, val = 30}, {key = 8, val = 100}, {key = 7, val = 2%}}, {},
function ChipTools.getAttr(dbId, level, isArray, emptyShow)
	local chip = gGameModel.chips:find(dbId):read("chip_id", "level", "now")
	local level = level or chip.level
	local cfg = csv.chip.chips[chip.chip_id]
	local firstAttrs = isArray and {} or {{}, {}}
	local secondAttrs = isArray and {} or {{}, {}}

	--获取主属性
	local attrID = cfg.mainAttr
	if attrID and attrID ~= 0 then
		ChipTools.setAttrAddition(firstAttrs, gChipMainAttrCsv[attrID][level], nil, isArray)
	end

	--获取副属性
	-- data的属性分别是 属性库ID，洗练次数，强化次数
	local now = chip.now or {}
	for _, data in ipairs(now) do
		ChipTools.setAttrAddition(secondAttrs, csv.chip.libs[data[1]], data[3], isArray, {chipId = chip.chip_id, now = data})
	end

	if isArray and emptyShow then
		-- 副属性显示 ????  ??
		local secondAttrLeftCount = cfg.startNum + cfg.acquiredLimit - itertools.size(now)
		for i = 1, secondAttrLeftCount do
			table.insert(secondAttrs, {name = gLanguageCsv.randomAttributes,
				val = string.format(gLanguageCsv.nLvUnlock, cfg.acquiredLevels[cfg.acquiredLimit - secondAttrLeftCount + i])})
		end
	end

	return firstAttrs, secondAttrs
end

-- @desc 获取精灵装备芯片的属性值
-- @params data cardDBID or chipPlan
function ChipTools.getAttrs(data)
	local firstAttrs = {{}, {}}
	local secondAttrs = {{}, {}}
	local cardChips = data
	if type(data) ~= "table" then
		local card = gGameModel.cards:find(data)
		cardChips = card:read("chip")
	end

	-- 获取符文属性，并且同类相加
	for _, chipID in pairs(cardChips) do
		local firstTemp, secondTemp = ChipTools.getAttr(chipID)
		ChipTools.setAttrCollect(firstAttrs, firstTemp)
		ChipTools.setAttrCollect(secondAttrs, secondTemp)
	end

	return firstAttrs, secondAttrs
end

function ChipTools.getComplateSuitAttrByCard(data)
	local list = {}
	local datas = ChipTools.getSuitAttrByCard(data)
	for suitID , data in pairs(datas) do
		table.insert(list, {suitId = suitID, data = {data[1], data[2]}})
		if data[3] then
			table.insert(list, {suitId = suitID, data = {data[3], {4, MAXQUALITY, false}}})
		end
	end
	return list
end

-- @desc 获取精灵芯片的套装属性
-- 	检测精灵套装属性，返回所有激活的套装属性  （激活时返回激活品质，没激活返回最高品质）
-- @params data cardDBID or chipPlan
-- @return
-- 	suit[suitID] = {
-- 		{2, quality, isActive}, -- 2件套的品质，是否激活
-- 		{4, quality, isActive}, -- 4件套的品质，是否激活
-- 	}
function ChipTools.getSuitAttrByCard(data)
	local suit = {}
	local qualityList = {}
	local cardChips = data
	if type(data) ~= "table" then
		local card = gGameModel.cards:find(data)
		cardChips = card:read("chip")
	end
	local qualityList = {}
	local posToSuits = {}
	local posToQulity = {}
	for index, dbid in pairs(cardChips) do
		local chipID = gGameModel.chips:find(dbid):read("chip_id")
		local chipCfg = csv.chip.chips[chipID]
		local suitID = chipCfg.suitID
		local quality = chipCfg.quality
		qualityList[suitID] = qualityList[suitID] or {}

		-- 设置精灵穿戴涉及到的套装属性，品质最大
		if suit[suitID] == nil then
			suit[suitID] = {{2, MAXQUALITY, false}, {4, MAXQUALITY, false}}
		end
		qualityList[suitID][quality] = qualityList[suitID][quality] or 0
		qualityList[suitID][quality] = qualityList[suitID][quality] + 1
		posToQulity[chipCfg.pos] = {quality = quality, isSelect = false, suitID = suitID}
	end

	-- 根据套装列表，查找可能存在的套装属性，如果激活，使用激活的品质
	local findPos = function(quality, num, suitID)
		for index = 1, 2 do
			for pos, data in pairs(posToQulity) do
				if quality <= data.quality and not data.isSelect and data.suitID == suitID then
					posToSuits[pos] = num
					data.isSelect = true
					break
				end
			end
		end
	end

	local loopQulity = MAXQUALITY
	for suitID, list in pairs(qualityList) do
		local num = 0
		for quality = MAXQUALITY, 1, -1 do
			num = num + (list[quality] or 0)
			if num >= 2 and suit[suitID][1][3] == false then
				suit[suitID][1] = {2, quality, true}
				findPos(quality,1, suitID)
			end
			if num >= 4 and suit[suitID][2][3] == false then
				suit[suitID][2] = {4, quality, true}
				findPos(quality, 2, suitID)
			end

			if num == 6  then
				suit[suitID][3] = {2, quality, true}
				findPos(quality, 3, suitID)
				break
			end
		end
		--如果该套装没有激活，删除设定数据
		if num < 2 then
			suit[suitID] = nil
		end
	end
	return suit, posToSuits
end
--  @desc 检测当前芯片ID的套装属性激活状态  （激活时返回激活品质，没激活返回所选chipDBID品质）
-- 	返回当前芯片的所属套装属性 （返回所选chipDBID品质）
function ChipTools.getSuitAttrByChip(chipDBID)
	local chip = gGameModel.chips:find(chipDBID)
	local cardDBID = chip:read("card_db_id")
	local chipID = chip:read("chip_id")
	local chipCfg = csv.chip.chips[chipID]
	local quality = chipCfg.quality
	if not cardDBID then
		return {{2, quality, false}, {4, quality, false}}
	end

	local suitID = chipCfg.suitID
	local suit, posToSuits = ChipTools.getSuitAttrByCard(cardDBID)
	local data = suit[suitID]
	local backData = {{2, quality, false}, {4, quality, false}}
	if not data or not posToSuits[chipCfg.pos] then
		return backData
	end

	for _, v in pairs(data) do
		if v[3] == false then
			v[2] = quality
		end
	end

	local count = math.floor((posToSuits[chipCfg.pos] - 1)/2)*2+1
	backData[1] = data[count] or backData[1]
	backData[2] = data[count+1] or backData[2]

	return backData
end

-- @desc 将 {2, quality, isActive} 转换为显示字符串
function ChipTools.getSuitAttrStr(suitId, data)
	local suitNum, quality, isActive = unpack(data)
	local suitCfg = gChipSuitCsv[suitId][quality][suitNum]
	local str = isActive and "#C0xFF5B545B#" or "#C0xFFB7B09E#"
	local formatStr = suitNum < 4 and gLanguageCsv.chipNSuitAttr or gLanguageCsv.chipNSuitAttrEffect
	str = string.format("#L10##F40#%s%s #L0#", str, string.format(formatStr, suitNum, gLanguageCsv[ui.QUALITY_COLOR_TEXT[quality]]))
	if suitCfg.skillID ~= 0 then
		str = str .. " "
		local describe = csv.skill[suitCfg.skillID].describe
		if not isActive then
			-- 未激活时去掉技能描述中富文本配置
			local t = string.split(describe, "#")
			for i, v in ipairs(t) do
				if i % 2 == 1 then
					str = str .. v
				end
			end
		else
			str = str .. describe
		end
	else
		for i = 1, math.huge do
			local key = suitCfg["attrType" .. i]
			if key and key ~= 0 then
				local val = dataEasy.getAttrValueString(key, suitCfg["attrNum" .. i])
				if isActive then
					str = string.format("%s %s #C0xFF5C9970#+%s#C0xFF5B545B#", str, getLanguageAttr(key), val)
				else
					str = string.format("%s %s +%s", str, getLanguageAttr(key), val)
				end
			else
				break
			end
		end
	end
	return str
end


-- @desc 精灵芯片共鸣
-- @params data cardDBID or chipPlan
-- @return {id1, id2, ...} 返回 csv.chip.resonance 表格的索引ID
function ChipTools.getResonanceAttr(data)
	local RESONANCE_QUALITY = 1
	local RESONANCE_LEVEL = 2
	local result = {}

	local cardChips = data
	if type(data) ~= "table" then
		local card = gGameModel.cards:find(data)
		cardChips = card:read("chip")
	end

	local conditions = {
		[1] = {
			getVal = function(dbid)
				local chipID = gGameModel.chips:find(dbid):read("chip_id")
				local chipCfg = csv.chip.chips[chipID]
				return chipCfg.quality
			end,
			func = function(map, count, condition)
				local num = 0
				for k, v in pairs(map) do
					if k >= condition then
						num = num + v
					end
				end
				return num >= count
			end,
		},
		[2] = {
			getVal = function(dbid)
				return gGameModel.chips:find(dbid):read("level")
			end,
			func = function(map, count, condition)
				local num = 0
				for k, v in pairs(map) do
					if k >= condition then
						num = num + v
					end
				end
				return num >= count
			end,
		},
	}
	-- 属性共鸣检测
	for _type, groupData in pairs(gChipResonanceCsv) do
		if conditions[_type] then
			local qualityMap = {}
			for _, dbid in pairs(cardChips) do
				local val = conditions[_type].getVal(dbid)
				qualityMap[val] = (qualityMap[val] or 0) + 1
			end
			for _, data in pairs(groupData) do
				for _, v in ipairs(data) do
					if conditions[_type].func(qualityMap, v.param[1], v.param[2]) then
						table.insert(result, {v.id, v.groupID})
						break
					end
				end
			end
		end
	end
	return result
end

-- @desc 忽略特攻，特防； 合并显示为双攻，双防
function ChipTools.ignoreAttr(key)
	return itertools.include({game.ATTRDEF_ENUM_TABLE.specialDamage, game.ATTRDEF_ENUM_TABLE.specialDefence, game.ATTRDEF_ENUM_TABLE.specialDefenceIgnore}, key)
end
function ChipTools.getAttrName(key)
	if key == game.ATTRDEF_ENUM_TABLE.damage then
		return gLanguageCsv.attrDoubleAttack
	end
	if key == game.ATTRDEF_ENUM_TABLE.defence then
		return gLanguageCsv.attrDoubleDefence
	end
	if key == game.ATTRDEF_ENUM_TABLE.defenceIgnore then
		return gLanguageCsv.attrDoubleDefenceIgnore
	end

	if key == 0 then
		return gLanguageCsv.basicAttribute
	end
	return getLanguageAttr(key)
end


function ChipTools.getBaseAttr(list)
	local attrs = {}
	local result = {}
	for _, id in pairs(game.ONESELF_NATURE_ENUM_TABLE) do
		attrs[id] = 0
	end

	for _, data in ipairs(list) do
		if attrs[data.key] == 0 then
			attrs[data.key] = data.val
		else
			table.insert(result, data)
		end
	end

	local count = -1
	local sign = true
	for index, val in pairs(attrs) do
		if count == -1 then
			count = val
		elseif count ~= val or count == 0 then
			sign = false
			break
		end
	end

	if sign then
		table.insert(result, {key = 0, val = count, base = true})
		return result
	end
	return list
end

-- @desc 获得属性值，主要用于排序
function ChipTools.getAttrsValue(dbIds)
	if type(dbIds) ~= "table" then
		dbIds = {dbIds}
	end
	local firstAttrs, secondAttrs = ChipTools.getAttrs(dbIds)
	ChipTools.setAttrCollect(firstAttrs, secondAttrs)
	return firstAttrs
end

-- #desc 方案属性与当前精灵装备的芯片属性对比
-- @return {[1] = {key = t}, [2] = {key = t}} 1 固定值, 2 百分比, t = {左侧值, 右侧值, 对比数值(界面显示颜色等), 对比显示值}
--[[{
	[1] = {
		[key2] = {"----", +12", 12, "+12"},
		[key3] = {"+111", "+111", 0, "----"},
	},
	[2] = {
		[key1] = {"+3%", "+2%", 1, "+1%"},
		[key2] = {"+5%", "----", -5, "-5%"},
	},
}--]]
local function getAttrSubtractionData(data1, data2, hasPercent)
	if not data1 and not data2 then
		return
	end
	local val1 = data1
	local val2 = data2
	if not data1 then
		data1 = "- - - -"
		val1 = hasPercent and "0%" or "0"
	end
	if not data2 then
		data2 = "- - - -"
		val2 = hasPercent and "0%" or "0"
	end
	val1 = tonumber(hasPercent and string.sub(val1, 1, #val1 - 1) or val1)
	val2 = tonumber(hasPercent and string.sub(val2, 1, #val2 - 1) or val2)
	if val1 > 0 then
		data1 = "+" .. data1
	end
	if val2 > 0 then
		data2 = "+" .. data2
	end

	local val = val1 - val2
	local str = "- - - -"
	if val > 0 then
		str = "+" .. val
	elseif val < 0 then
		str = val
	end
	if hasPercent then
		str = str .. "%"
	end
	return {data1, data2, val, str}
end
function ChipTools.getAttrsValueCmp(dbIds1, dbIds2)
	local t1 = ChipTools.getAttrsValue(dbIds1)
	local t2 = ChipTools.getAttrsValue(dbIds2)
	local ret = {{}, {}}
	for i = 1, 2 do
		if t1[i] then
			for key, data1 in pairs(t1[i]) do
				local data2 = t2[i] and t2[i][key]
				ret[i][key] = getAttrSubtractionData(data1, data2, i == 2)
			end
		end
		if t2[i] then
			for key, data2 in pairs(t2[i]) do
				local data1 = t1[i] and t1[i][key]
				if not data1 then
					ret[i][key] = getAttrSubtractionData(data1, data2, i == 2)
				end
			end
		end
	end
	return ret
end

-- @desc 根据方案获取当前方案装备的精灵
function ChipTools.getCardDBID(plan)
	if itertools.size(plan) == 0 then
		return
	end
	local cards = gGameModel.role:read("cards")
	for _, v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardChips = card:read("chip")
		if itertools.size(cardChips) > 0 then
			if itertools.equal(cardChips, plan) then
				return v
			end
		end
	end
end

return ChipTools