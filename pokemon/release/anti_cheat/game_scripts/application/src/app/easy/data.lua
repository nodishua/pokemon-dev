--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ui数据相关全局函数
--
local insert = table.insert

local dataEasy = {}
globals.dataEasy = dataEasy

-- @desc 'gold' -> 401
function dataEasy.stringMapingID(key)
	return game.ITEM_STRING_ENUM_TABLE[key] or key
end

function dataEasy.isFragment(id)
	if type(id) ~= "number" then
		return false
	end
	return id > game.EQUIP_CSVID_LIMIT and id <= game.FRAGMENT_CSVID_LIMIT
end

-- 精灵碎片
function dataEasy.isFragmentCard(id)
	if dataEasy.isFragment(id) then
		if csv.fragments[id] and csv.fragments[id].type == 1 then
			return true
		end
	end
	return false
end

function dataEasy.isHeldItem(id)
	if type(id) ~= "number" then
		return false
	end
	return id > game.FRAGMENT_CSVID_LIMIT and id <= game.HELD_ITEM_CSVID_LIMIT
end

function dataEasy.isGemItem(id)
	if type(id) ~= "number" then
		return false
	end
	return id > game.HELD_ITEM_CSVID_LIMIT and id <= game.GEM_CSVID_LIMIT
end

function dataEasy.isZawakeFragment(id)
	if type(id) ~= "number" then
		return false
	end
	return id > game.GEM_CSVID_LIMIT and id <= game.ZAWAKE_FRAGMENT_CSVID_LIMIT
end

function dataEasy.isChipItem(id)
	if type(id) ~= "number" then
		return false
	end
	return id > game.ZAWAKE_FRAGMENT_CSVID_LIMIT and id <= game.CHIP_CSVID_LIMIT
end

local csvItems = csv.items
local csvEquips = csv.equips
local csvFragments = csv.fragments
local csvHelditems = csv.held_item.items
local csvGem = csv.gem.gem
local csvZawakeFragments = csv.zawake.zawake_fragments
local csvChips = csv.chip.chips
-- @desc 根据id获取对应配表内容
function dataEasy.getCfgByKey(key)
	local id = dataEasy.stringMapingID(key)
	if not id or type(id) == "string" then
		printError("key(%s) was not in game.ITEM_STRING_ENUM_TABLE", key)
		return
	end
	local cfg = nil
	if id <= game.ITEM_CSVID_LIMIT then
		cfg = csvItems[id]

	elseif id <= game.EQUIP_CSVID_LIMIT then
		cfg = csvEquips[id]

	elseif id <= game.FRAGMENT_CSVID_LIMIT then
		cfg = csvFragments[id]

	elseif id <= game.HELD_ITEM_CSVID_LIMIT then
		cfg = csvHelditems[id]

	elseif id <= game.GEM_CSVID_LIMIT then
		cfg = csvGem[id]

	elseif id <= game.ZAWAKE_FRAGMENT_CSVID_LIMIT then
		cfg = csvZawakeFragments[id]

	elseif id <= game.CHIP_CSVID_LIMIT then
		cfg = csvChips[id]
	end
	if not cfg then
		printError("id(%d) was not in csv", id)
	end
	return cfg
end

-- @desc 获取资源，如金币道具 401 是一堆金币，而金币货币 "gold" 是一个金币
function dataEasy.getIconResByKey(key)
	return ui.COMMON_ICON[key] or dataEasy.getCfgByKey(key).icon
end

-- @desc 获得当前拥有的物品数量, 包括物品，碎片，货币
-- @param key id or gold, coin1, coin2
local specialRoleKey = {role_exp = "level_exp", vip_exp = "vip_sum", vip = "vip_level"}
function dataEasy.getNumByKey(key)
	local str = game.ITEM_STRING_TABLE[key]
	if str then
		printError("!!! error use item(%s), must use(%s)", key, str)
		return 0
	end
	if type(key) == "string" then
		if key == "gym_talent_point" then
			return gGameModel.role:read("gym_datas").gym_talent_point or 0 --道馆天赋数据节点不同 特殊处理
		else
			key = specialRoleKey[key] or key
			return gGameModel.role:read(key) or 0 -- contrib 公会经验不在role下面 做个or处理（不显示出来只保证不报错）
		end
	elseif type(key) ~= "number" then
		return 0

	elseif key <= game.EQUIP_CSVID_LIMIT then
		return gGameModel.role:read("items")[key] or 0

	elseif key <= game.FRAGMENT_CSVID_LIMIT then
		return gGameModel.role:read("frags")[key] or 0

	elseif key <= game.HELD_ITEM_CSVID_LIMIT then
		local count = 0
		local carry = gGameModel.role:read("held_items")
		for _, dbId in ipairs(carry) do
			local heldItem = gGameModel.held_items:find(dbId)
			if heldItem:read("held_item_id") == key then
				count = count + 1
			end
		end
		return count

	elseif key <= game.GEM_CSVID_LIMIT then
		local count = 0
		local gems = gGameModel.role:read('gems')
		for k, v in pairs(gems) do
			local gem = gGameModel.gems:find(v)
			if gem:read('gem_id') == key then
				count = count + 1
			end
		end
		return count

	elseif key <= game.ZAWAKE_FRAGMENT_CSVID_LIMIT then
		return gGameModel.role:read("zfrags")[key] or 0

	elseif key <= game.CHIP_CSVID_LIMIT then
		local count = 0
		local roleChips = gGameModel.role:read('chips')
		for k, v in pairs(roleChips) do
			local chip = gGameModel.chips:find(v)
			if chip:read('chip_id') == key then
				count = count + 1
			end
		end
		return count
	end
	return 0
end

-- @desc 获得当前拥有的物品数量, 包括物品，碎片，货币的idler
-- @param key id or gold, coin1, coin2
function dataEasy.getListenNumByKey(key)
	local str = game.ITEM_STRING_TABLE[key]
	if str then
		printError("!!! error use item(%s), must use(%s)", key, str)
		return idler.new(0)
	end
	if type(key) == "string" then
		key = specialRoleKey[key] or key
		return idlereasy.when(gGameModel.role:getIdler(key), function(_, val)
			return true, val or 0
		end)

	elseif type(key) ~= "number" then
		return idler.new(0)

	elseif key <= game.EQUIP_CSVID_LIMIT then
		return idlereasy.when(gGameModel.role:getIdler("items"), function(_, val)
			return true, val[key] or 0
		end)

	elseif key <= game.FRAGMENT_CSVID_LIMIT then
		return idlereasy.when(gGameModel.role:getIdler("frags"), function(_, val)
			return true, val[key] or 0
		end)
	elseif key <= game.ZAWAKE_FRAGMENT_CSVID_LIMIT then
		return idlereasy.when(gGameModel.role:getIdler("zfrags"), function(_, val)
			return true, val[key] or 0
		end)
	end
	return idler.new(0)
end

-- @desc advance 对应 quality 和 +x 标记
function dataEasy.getQuality(advance, space)
	local quality = 1
	for i, v in ipairs(game.QUALITY_TO_FITST_ADVANCE) do
		if advance < v then
			break
		end
		quality = i
	end
	local num = advance - game.QUALITY_TO_FITST_ADVANCE[quality]
	if num == 0 then
		return quality, ""
	end
	return quality, string.format("%s+%s", space and " " or "", num)
end

-- @desc 获取卡牌id和星级
function dataEasy.getCardIdAndStar(idOrTable)
	local cardId, star
	if type(idOrTable) == "table" then
		cardId = idOrTable.id
		star = idOrTable.star
	else
		cardId = idOrTable
	end
	if not star and not csv.cards[cardId] then
		printError("check cardId, %s was not exist in csv.cards", tostring(cardId))
	end
	star = star or csv.cards[cardId].star
	return cardId, star
end

-- @desc 服务器获取到的道具数据转换
function dataEasy.getRawTable(tb)
	local ret = {}
	local t = tb.view and (tb.view.result or tb.view) or tb
	local extra = tb.view and tb.view.extra or {}
	local specialData = {
		card = {}, -- 存到背包的整卡 "card", num(cardId)
		card2frag = {}, -- 整卡转换成碎片 fragId num cardId
		card2mail = {}, -- 整卡存放到邮件里 "card", num(cardId)
		item = {}, -- 道具, 同样道具多个显示，非合并 key, num
		heldItem = {}, -- 携带道具
	}
	local isHaveCard2Frag = false
	for k, v in pairs(t) do
		if k == "carddbIDs" then
			for _, data in ipairs(v) do
				local card = gGameModel.cards:find(data[1])
				local cardId = card:read("card_id")
				local star = card:read("star")
				insert(specialData.card, {key = "card", num = {id = cardId, star = star}, specialFlag = "card", dbid = data[1], new = data[2]})
			end

		elseif k == "card2fragL" then
			-- for _, data in ipairs(v) do
			-- 	insert(specialData.card2frag, {key = data[1], num = data[2], cardId = data[3], specialFlag = "card2frag"})
			-- end
			isHaveCard2Frag = true

		elseif k == "card2mailL" then
			for _, data in ipairs(v) do
				insert(specialData.card2mail, {key = "card", num = data, specialFlag = "card2mail"})
			end

		elseif k == "items" then
			for _, data in ipairs(v) do
				if not dataEasy.isChipItem(data[1]) then
					insert(specialData.item, {key = data[1], num = data[2]})
				end
			end

		elseif k == "star_skill_points" then
			for markId, num in pairs(v) do
				insert(ret, {key = k.."_"..markId, num = num})
			end

		elseif k == "chipdbIDs" then
			-- 芯片有随机副属性，要读对应 dbId 数据
			for _, dbId in ipairs(v) do
				local chip = gGameModel.chips:find(dbId)
				local chipId = chip:read("chip_id")
				insert(specialData.item, {key = chipId, num = 1, dbId = dbId})
			end

		elseif k == "ret" then
			-- 忽略服务器特殊返回值
			printWarn("invalid getRawTable %s", dumps(t))

		elseif type(v) == "number" then
			if not dataEasy.isChipItem(k) then
				insert(ret, {key = k, num = v})
			end

		elseif not itertools.include(game.SERVER_RAW_MODEL_KEY, k) then
			if type(v) == "table" then
				for id, num in pairs(v) do
					insert(ret, {key = id, num = num})
				end
			else
				insert(ret, {key = k, num = v})
			end
		end
	end
	local isFull = not itertools.isempty(t.card2mailL)
	return ret, specialData, isFull, isHaveCard2Frag, extra
end

-- @desc 组装合并服务器数据
function dataEasy.mergeRawDate(data)
	local ret, specialData, isFull, isHaveCard2Frag, extra = dataEasy.getRawTable(data)
	local flagOrder = {"card", "card2mail"}
	local t = {}
	for _, flag in ipairs(flagOrder) do
		for _, v in ipairs(specialData[flag]) do
			v.specialFlag = flag
			insert(t, v)
		end
	end
	local sortRet = {}
	local mergeRet = {}
	for _, v in ipairs(ret) do
		if type(v.num) == "number" then
			mergeRet[v.key] = mergeRet[v.key] or 0
			mergeRet[v.key] = mergeRet[v.key] + v.num
		end
	end
	for k, v in pairs(mergeRet) do
		table.insert(sortRet, {key = k, num = v})
	end
	table.sort(sortRet, dataEasy.sortItemCmp)

	-- specialData.item 按发来的顺序显示，不排序
	arraytools.merge_inplace(t, {specialData.item, sortRet})
	local newExtra = {}
	for k,v in pairs(extra) do
		if type(v) == "table" then
			for id, num in pairs(v) do
				table.insert(newExtra, {key = id, num = num, specialKey = "extra"})
			end
		else
			table.insert(newExtra, {key = k, num = v, specialKey = "extra"})
		end
	end
	if #newExtra > 0 then
		table.sort(newExtra, dataEasy.sortItemCmp)
		table.sort(newExtra, function (a, b)
			if a.specialKey ~= "extra" and b.specialKey == "extra" then
				return true
			end
			if a.specialKey == "extra" and b.specialKey ~= "extra" then
				return false
			end
			return false
		end)
		local newT = {}
		arraytools.merge_inplace(newT, {t, newExtra})
		t = newT
	end
	return t, isFull, isHaveCard2Frag
end

-- 自动识别配置数据 {key = num, __size = N} 或 组装数据 {{key="card", num=1}, {key=11, num=1}, ...} 或 组装数据 {{"gold", 1}, {"rmb", 1}, {"gold", 2}, ...}
-- 默认进行排序
function dataEasy.getItemData(data, noSort)
	local itemData = {}
	if itertools.isarray(data) then
		if data[1] and itertools.isarray(data[1]) then
			for _, v in ipairs(data) do
				table.insert(itemData, {key = v[1], num = v[2], decomposed = v[3] == 1})
			end
		else
			itemData = data
		end
	else
		for k, v in csvMapPairs(data) do
			if k == "cards" then
				for _, id in ipairs(v) do
					table.insert(itemData, {key = "card", num = id})
				end
			else
				table.insert(itemData, {key = k, num = v})
			end
		end
	end
	if not noSort then
		table.sort(itemData, dataEasy.sortItemCmp)
	end
	return itemData
end

local function getItemSortKey(a)
	-- 活跃度非货币，特殊显示在最前
	if a.key == 399 then
		return 1e6
	end
	local key = a.key
	local ret = 0
	local function add(v)
		ret = ret * 2 + (v and 1 or 0)
	end
	add(game.ITEM_EXP_HASH[key])
	add(key == "card")
	add(dataEasy.isFragment(key))
	add(game.ITEM_STRING_ENUM_TABLE[key])
	return ret
end

-- @desc 通用道具显示排序
function dataEasy.sortItemCmp(a, b)
	local ia = getItemSortKey(a)
	local ib = getItemSortKey(b)
	if ia ~= ib then
		return ia > ib
	end
	if a.key == "card" and b.key == "card" then
		local cardIdA = dataEasy.getCardIdAndStar(a.num)
		local cardIdB = dataEasy.getCardIdAndStar(b.num)
		return cardIdA < cardIdB
	end
	if string.find(a.key, "star_skill_points_%d+") and string.find(b.key, "star_skill_points_%d+") then
		local markIdA = tonumber(string.sub(a.key, string.find(a.key, "%d+")))
		local markIdB = tonumber(string.sub(b.key, string.find(b.key, "%d+")))
		return markIdA < markIdB
	end
	local cfgA ,cfgB
	if string.find(a.key, "star_skill_points_%d+") then
		return true
	else
		cfgA = dataEasy.getCfgByKey(a.key)
	end
	if string.find(b.key, "star_skill_points_%d+") then
		return false
	else
		cfgB = dataEasy.getCfgByKey(b.key)
	end

	if not cfgA or not cfgB then
		return false
	end
	if cfgA.quality ~= cfgB.quality then
		return cfgA.quality > cfgB.quality
	end
	return dataEasy.stringMapingID(a.key) < dataEasy.stringMapingID(b.key)
end

-- @desc 通用道具显示排序
function dataEasy.sortHelditemCmp(a, b)
	if a.cfg.quality ~= b.cfg.quality then
		return a.cfg.quality > b.cfg.quality
	end
	if a.isDress ~= b.isDress then
		return a.isDress
	end
	if a.isExc ~= b.isExc then
		return a.isExc
	end
	if a.csvId ~= b.csvId then
		return a.csvId < b.csvId
	end
	if a.advance ~= b.advance then
		return a.advance > b.advance
	end
	if a.lv ~= b.lv then
		return a.lv > b.lv
	end
	-- 有堆叠，数量少的显示前面
	return a.num < b.num
end

-- @desc 通用获得角色头像框
function dataEasy.getRoleLogoIcon(logoId)
	local cfg = gRoleLogoCsv[logoId]
	if cfg then
		return cfg.icon
	end
	return gRoleLogoCsv[1].icon
end

-- @desc 通用获得角色形象
function dataEasy.getRoleFigureIcon(figureId)
	local cfg = gRoleFigureCsv[figureId]
	if cfg then
		return cfg.res
	end
	return gRoleFigureCsv[1].res
end

-- @desc 通用获得角色框
function dataEasy.getRoleFrameIcon(frameId)
	local cfg = gRoleFrameCsv[frameId]
	if cfg then
		return cfg.icon
	end
	return gRoleFrameCsv[1].icon
end

-- @desc 显示属性百分比 500 -> 5%
function dataEasy.getBuffShow(str)
	if string.find(str, "%%") then
		return str
	else
		return (tonumber(str)/100) .. "%"
	end
end

-- @desc 显示属性根据类型和内容分别显示对应数值和百分比(无特殊说明默认使用这种方式显示属性)
function dataEasy.getAttrValueString(key, val)
	local hasPercent = string.find(val, "%%")
	if not hasPercent and not game.ATTRDEF_SHOW_NUMBER[key] then
		if not tonumber(val) then
			return tostring(val)
		end
		return (tonumber(val)/100) .. "%"
	end
	return tostring(val)
end

-- @desc 可以计算都带百分的属性相加 如 2% + 3% = 5%
function dataEasy.attrAddition(a, b)
	if not a then
		return b
	end
	local hasPercent = string.find(b, "%%")
	if not hasPercent then
		return a + b
	end
	return (string.sub(a, 1, #a - 1) + string.sub(b, 1, #b - 1)) .. "%"
end

-- @desc 可以计算都带百分的属性相加 如 5% - 3% = 2%
function dataEasy.attrSubtraction(a, b)
	if not a then
		return -b
	end
	local hasPercent = string.find(b, "%%")
	if not hasPercent then
		return a - b
	end
	return (string.sub(a, 1, #a - 1) - string.sub(b, 1, #b - 1)) .. "%"
end

--@desc 获得特权加成值
function dataEasy.getPrivilegeVal(privilegeType, targetType)
	local trainerLevel = gGameModel.role:read("trainer_level")
	local trainerSkills = gGameModel.role:read("trainer_skills")
	local isStaminaGain = privilegeType == game.PRIVILEGE_TYPE.StaminaGain
	local isBattleSkip = privilegeType == game.PRIVILEGE_TYPE.BattleSkip
	local isGateSaoDangTimes = privilegeType == game.PRIVILEGE_TYPE.GateSaoDangTimes

	if not dataEasy.isUnlock(gUnlockCsv.trainer) then
		if isStaminaGain then
			return {}
		elseif isBattleSkip then
			return false
		else
			return 0
		end
	end
	local data = {}
	local allNum = 0
	local saodangTimes = 0
	for i = 1, trainerLevel do
		local privilege, val = csvNext(csv.trainer.trainer_level[i].privilege)
		if privilege == privilegeType then
			if isStaminaGain then
				-- 早 中 晚 夜 宵
				for i=1,4 do
					data[i] = val
				end
			elseif isBattleSkip then
				data[val] = 1
			elseif isGateSaoDangTimes then
				saodangTimes = math.max(val, saodangTimes)
			else
				allNum = allNum + val
			end
		end
	end

	for k,v in pairs(trainerSkills) do
		local cfg = csv.trainer.skills[k]
		if cfg.type == privilegeType then
			if isStaminaGain then
				if v > 0 then  -- 服务器默认可能会给0, 所以这里需要判断大于0，才有特权加成
					data[cfg.arg] = (data[cfg.arg] or 0) + cfg.nums[v]
				end
			-- 跳过的话 数据里面只有一个值
			elseif isBattleSkip then
				data[cfg.nums[1]] = 1
			else
				table.insert(data, {cfg = cfg, id = k})
				local level = trainerSkills[k]
				local num = cfg.nums[level] or 0
				allNum = allNum + num
			end
		end
	end
	if isStaminaGain then
		return data
	end
	if isBattleSkip then
		return targetType and data[targetType] == 1
	end
	if isGateSaoDangTimes then
		return saodangTimes
	end

	return allNum
end

-- @desc 获得体力最大值
function dataEasy.getStaminaMax(level, trainerLevel)
	local max = gRoleLevelCsv[level].staminaMax
	local monthCardView = require "app.views.city.activity.month_card"
	local extra = monthCardView.getPrivilegeAddition("staminaExtraMax")
	if trainerLevel then
		extra = (extra or 0) + dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.StaminaMax)
	end
	max = max + (extra or 0)
	return max, extra
end

-- @desc 获取当前的体力值
function dataEasy.getStamina()
	local level = gGameModel.role:read("level")
	local stamina = gGameModel.role:read("stamina")
	local staminaLRT = gGameModel.role:read("stamina_last_recover_time")
	local trainerLevel = gGameModel.role:read("trainer_level")
	local max = dataEasy.getStaminaMax(level, trainerLevel)
	-- 服务器记录体力大于最大体力
	if stamina >= max then
		return stamina
	end
	-- 加上恢复的体力值大于最大体力时为最大体力
	local dt = math.max(time.getTime() - staminaLRT, 0)
	local curStamina = stamina + math.floor(dt/game.STAMINA_COLD_TIME)
	if curStamina >= max then
		return max
	end
	return curStamina
end

-- @desc 获得技能点最大值
function dataEasy.getSkillPointMax(roleLv)
	local max = csv.base_attribute.role_level[roleLv].skillPointMax
	local monthCardView = require "app.views.city.activity.month_card"
	local extra = monthCardView.getPrivilegeAddition("skillPointExtraMax")
	max = max + (extra or 0)
	return max, extra
end

-- @desc 1:不带百分号的 0:带百分号的
function dataEasy.parsePercentStr(str)
	local pos = string.find(str,'%%')
	local numType, val = game.NUM_TYPE.number, tonumber(str)
	if pos then
		numType = game.NUM_TYPE.percent
		val = string.sub(str, 1, pos - 1)
	end
	return tonumber(val), numType
end

function dataEasy.getPercentStr(num, numType, pow)
	pow = pow or 1
	local str = tostring(num * pow)
	if numType == game.NUM_TYPE.percent then
		str = str .. "%"
	end
	return str
end

-- @desc 服务器开启时间是否小于day
function dataEasy.serverOpenDaysLess(day)
	if not game.SERVER_OPENTIME then
		return true
	end
	local d = time.getDate(game.SERVER_OPENTIME)
	local openHour = d.hour
	d.hour = 0
	d.min = 0
	d.sec = 0
	local t = time.getTimeTable()
	local rawHour = t.hour
	t.hour = 0
	t.min = 0
	t.sec = 0
	local delta = time.getTimestamp(t) - time.getTimestamp(d)
	local oneday = 24 * 60 * 60
	local refreshHour = time.getRefreshHour()
	if openHour < refreshHour then
		delta = delta + oneday
	end
	if rawHour < refreshHour then
		delta = delta - oneday
	end
	if delta / oneday < (day - 1) then
		return true
	end
	return false
end

-- @desc 判断是否换公会
function dataEasy.isQuitUnionToday()
	local quitTime = gGameModel.role:read("union_quit_time")
	if quitTime == nil then
		return false
	end
	local time2 = time.getTimeTable()
	local time3 = time.getTimestamp({year = time2.year, month = time2.month,
		day = time2.day, hour = 5, min = 0, sec = 0})

	local currentTime = time.getTime()
	if currentTime < time3 then
		local time4 = time3 - 86400 -- 一天对应3600*24秒
		return quitTime > time4
	else
		return quitTime > time3
	end
end

-- @desc 判断是否今天加入公会
function dataEasy.isJoinUnionToday()
	local joinTime = gGameModel.role:read("union_join_time")
	local time2 = time.getTimeTable()
	local time3 = time.getTimestamp({year = time2.year, month = time2.month,
		day = time2.day, hour = 5, min = 0, sec = 0})

	local currentTime = time.getTime()
	if currentTime < time3 then
		local time4 = time3 - 86400 -- 一天对应3600*24秒
		return joinTime > time4
	else
		return joinTime > time3
	end
end

-- @desc 判断是否是新号公会建筑保护时间 true在保护期
function dataEasy.isUnionBuildProtectionTime()
	-- 角色创建时间
	local createdTime = gGameModel.role:read("created_time")
	-- 当前时间
	local currentTime = time.getTime()
	-- 创建时间的table
	local time2 = time.getDate(createdTime)
	-- 保护天数
	local protectionTime = gCommonConfigCsv.newbieUnionQuitProtectDays
	local time3 = time.getTimestamp({year = time2.year, month = time2.month,
		day = time2.day, hour = 5, min = 0, sec = 0})
	-- 5点前创建的
	if time2.hour < 5 then
		time3 = time3 - 3600 * 24
	end
	-- 当前时间小于保护期限，则在保护期
	return currentTime < (time3 + protectionTime * 3600 * 24)
end

-- @desc 不可以使用公会建筑
function dataEasy.notUseUnionBuild()
	return dataEasy.isQuitUnionToday() and dataEasy.isJoinUnionToday() and not dataEasy.isUnionBuildProtectionTime()
end

-- @desc 判断是否可领公会系统红包 true可领
function dataEasy.canSystemRedPacket()
	-- 退出公会时间
	local quitTime = gGameModel.role:read("union_quit_time")
	if quitTime == 0 then
		return true
	end
	local time1 = time.getDate(quitTime)
	local day = time1.hour < 19 and time1.day or (time1.day + 1)
	local time3 = time.getTimestamp({year = time1.year, month = time1.month,
		day = day, hour = 19, min = 0, sec = 0})
	return time.getTime() > time3
end

-- @desc 判断是否满足关卡条件
function dataEasy.isGateFinished(gateId)
	if not gateId or gateId == 0 then return true end
	local gateStar = gGameModel.role:read("gate_star") or {}
	if gateStar[gateId] and gateStar[gateId].star and gateStar[gateId].star > 0 then
		return true
	end
	return false
end

-- @desc 判断是否满足关卡条件
-- @desc 一个界面若多处调用需传入key，不然前面设置的idler会被覆盖导致监听失效
function dataEasy.getGateFinished(gateId)
	return idlereasy.when(gGameModel.role:getIdler("gate_star"), function()
		return true, dataEasy.isGateFinished(gateId)
	end)
end

-- @desc 判断是否显示
-- @param key gUnlockCsv[feature] nil:表示功能暂时不开放，不显示
function dataEasy.isShow(key)
	if type(key) == "string" then
		key = gUnlockCsv[key]
	end
	local cfg = csv.unlock[key]
	-- not such config, lock it
	if not cfg then
		return false
	end

	local roleLevel = gGameModel.role:read("level") or 0
	return roleLevel >= math.min(cfg.showLevel, cfg.startLevel)
end

-- @desc 判断是否显示
-- @param key gUnlockCsv[feature] nil:表示功能暂时不开放，不显示
function dataEasy.getListenShow(key, cb)
	if type(key) == "string" then
		key = gUnlockCsv[key]
	end
	local cfg = csv.unlock[key]
	-- not such config, lock it
	if not cfg then
		if cb then
			cb(false)
		end
		return idlereasy.assign(idler.new(false))
	end

	local flag = nil
	local roleLevel = gGameModel.role:getIdler("level")
	return idlereasy.when(roleLevel, function()
		local isShow = dataEasy.isShow(key)
		if cb and flag ~= isShow then
			flag = isShow
			cb(isShow)
		end
		return true, isShow
	end)
end

-- @desc 判断是否解锁
-- @param key gUnlockCsv[feature] nil:表示功能暂时不开放，为加锁或隐藏
function dataEasy.isUnlock(key)
	if type(key) == "string" then
		key = gUnlockCsv[key]
	end
	local cfg = csv.unlock[key]
	if not cfg then
		return false
	end
	if not dataEasy.isInServer(cfg.feature) then
		return false
	end
	local roleLevel = gGameModel.role:read("level") or 0
	local vipLevel = gGameModel.role:read("vip_level") or 0
	return roleLevel >= cfg.startLevel
		and vipLevel >= cfg.startVip
		and dataEasy.isGateFinished(cfg.startGate)
end

-- @desc 判断是否解锁
-- @param key gUnlockCsv[feature] nil:该功能暂时不开放，为锁住或隐藏
function dataEasy.getListenUnlock(key, cb)
	if type(key) == "string" then
		key = gUnlockCsv[key]
	end
	local cfg = csv.unlock[key]
	if not cfg then
		if cb then
			cb(false)
		end
		-- assign for add anonyOnly
		return idlereasy.assign(idler.new(false))
	end
	local flag = nil
	local roleLevel = gGameModel.role:getIdler("level")
	local vipLevel = gGameModel.role:getIdler("vip_level")
	local gateFinished = dataEasy.getGateFinished(cfg.startGate)
	return idlereasy.any({roleLevel, vipLevel, gateFinished}, function()
		local isUnlock = dataEasy.isUnlock(key)
		if cb and flag ~= isUnlock then
			flag = isUnlock
			cb(isUnlock)
		end
		return true, isUnlock
	end)
end

local GATE_TITLE = {
	[1] = gLanguageCsv.gateStory,
	[2] = gLanguageCsv.gateDifficult,
	[3] = gLanguageCsv.gateNightMare
}
function dataEasy.getChapterInfoByGateID(gateID)
	local type = math.floor(gateID / 10000)
	local chapterId = math.floor((gateID % 10000) / 100)
	local id = gateID % 100
	return type, chapterId, id, GATE_TITLE[type]
end

-- @desc 获取解锁提示文本
function dataEasy.getUnlockTip(key)
	if type(key) == "string" then
		key = gUnlockCsv[key]
	end
	local cfg = csv.unlock[key]
	if not cfg then
		return gLanguageCsv.comingSoon
	end
	if not dataEasy.isInServer(cfg.feature) then
		return gLanguageCsv.comingSoon
	end
	if not dataEasy.isGateFinished(cfg.startGate) then
		local _, chapterId, gateId, str = dataEasy.getChapterInfoByGateID(cfg.startGate)
		return string.format(gLanguageCsv.unlockGate, str .. chapterId, gateId, cfg.name)
	end
	local roleLevel = gGameModel.role:read("level") or 0
	if roleLevel < cfg.startLevel then
		return string.format(gLanguageCsv.unlockLevel, cfg.startLevel, cfg.name)
	end
	local vipLevel = gGameModel.role:read("vip_level") or 0
	if vipLevel < cfg.startVip then
		return string.format(gLanguageCsv.unlockVip, cfg.startVip, cfg.name)
	end
	return ""
end

-- @desc 使用 cards.csv 的id获取卡牌的服务器数据，没有拥有该卡牌返回nil
function dataEasy.getCardById(cardId)
	for idx, card in gGameModel.cards:pairs() do
		if card:read("card_id") == cardId then
			return idx
		end
	end
end

-- @desc 判断是否拥有 cardMarkID 类型卡牌
function dataEasy.getByMarkId(cardMarkID)
	local gggetCard = getCardById
	for develop, data in pairs(gCardsCsv[cardMarkID]) do
		for branch, card in pairs(data) do
			local ret = gggetCard(card.id)
			if ret then
				return ret
			end
		end
	end
end

-- @desc 获取努力值的上限
function dataEasy.getCardEffortMax(idx, cardId, attr, advance, level)
	level = level or math.huge -- 如果不填level 则默认等级是符合的
	local cfg = csv.cards[cardId]
	local maxVal = 0
	local total = 0
	local advanceTb = gCardEffortAdvance[cfg.effortSeqID]
	advance = advance or 1
	for val,v in orderCsvPairs(advanceTb) do
		if advance == val then
			maxVal = v[attr]
		end
		if advance > val then
			total = total + v[attr]
		end
	end

	local nextTb = advanceTb[advance + 1]
	local levelE = false
	if nextTb and advance < advanceTb[advance].advanceLimit then
		levelE = nextTb.needLevel <= level
	end

	return maxVal, total, nextTb and true or false, levelE
end

-- @desc 获取罗马数字 目前支持到20
function dataEasy.getRomanNumeral(num)
	local romanNumeral = {
		"I",
		"II",
		"III",
		"IV",
		"V",
		"VI",
		"VII",
		"VIII",
		"IX",
		"X",
	}
	if num <= 10 then
		return romanNumeral[num]
	end
	local number = romanNumeral[num%10] or romanNumeral[10]
	return romanNumeral[10] .. number
end

function dataEasy.getCardMaxStar(cardMarkID)
	local cards = gGameModel.role:read("cards")
	-- 背包里相同MarkID的最大星级
	local myMaxStar = 0
	-- 背包里存在的卡牌
	local existCards = {}
	-- 最大星级卡牌的dbid
	local dbid
	for k,v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardId = card:read("card_id")
		local star = card:read("star")
		existCards[cardId] = true
		if cardMarkID == csv.cards[cardId].cardMarkID and star > myMaxStar then
			myMaxStar = star
			dbid = v
		end
	end
	return myMaxStar, existCards, dbid
end
-- 获取星星的资源数据
function dataEasy.getStarData(star)
	local starData = {}
	local starIdx = star - 6
	for i=1,6 do
		local icon = "common/icon/icon_star_d.png"
		if i <= star then
			icon = i <= starIdx and "common/icon/icon_star_z.png" or "common/icon/icon_star.png"
		end
		table.insert(starData,{icon = icon})
	end
	return starData
end

-- 将 "xxx\nyy" 转换为 {{str = "xxx"}, {str = "yy"}}
function dataEasy.getTextScrollStrs(strs, verticalSpace)
	if type(strs) == "string" and string.find(strs, "\n", 1, true) then
		local data = string.split(strs, "\n")
		strs = {}
		for i, v in ipairs(data) do
			if i ~= 1 and verticalSpace then
				table.insert(strs, {str = "", verticalSpace = verticalSpace})
			end
			table.insert(strs, {str = v})
		end
	end
	return strs
end

function dataEasy.getItems(ret, spe)
	local hasHero = {}
	local items = {}
	-- 限时抽取走这个
	for i,v in ipairs(ret) do
		local t = {}
		if v.key == "items" or v.key == "card" then
			for _,v in ipairs(v.num) do
				local data = v
				if v.key == "card" then
					local isNewHero = false
					local card = gGameModel.cards:find(v[1])
					local cardId = card:read("card_id")
					if v[2] and not hasHero[cardId] then
						hasHero[cardId] = true
						isNewHero = true
					end
					data = {dbid = v[1], new = isNewHero}
				end
				table.insert(t, data)
			end
		end
		if #t > 0 then
			table.insert(items, t)
		end
	end
	local t = {}
	local card = nil
	for k,v in pairs(spe) do
		if k == "item" or k == "card" then
			for _,vv in ipairs(v) do
				local data = vv
				if k == "item" then
					data = {vv.key, vv.num}
				else
					local isNewHero = false
					local card = gGameModel.cards:find(data.dbid)
					local cardId = card:read("card_id")
					if data.new and not hasHero[cardId] then
						hasHero[cardId] = true
						isNewHero = true
					end
					data.new = isNewHero
				end
				table.insert(t, data)
			end
		end
	end
	if #t > 0 then
		table.insert(items, t)
	end


	for _,datas in ipairs(items) do
		local len = #datas
		if len < 10 then
			break
		end
		for i=1,5 do
			local idx1 = math.random(1, len)
			local idx2 = math.random(1, len)
			while idx1 == idx2 do
				idx2 = math.random(1, len)
			end
			datas[idx1], datas[idx2] = datas[idx2], datas[idx1]
		end
	end

	return items
end

-- 目前只是个体值红点用，减少数据存储
local localKey = "redHintTodayCheckTable"
function dataEasy.setTodayCheck(checkKey, dbId)
	if not checkKey or not dbId then return end
	if checkKey ~= "nvalue" then return end
	dbId = stringz.bintohex(dbId)
	local today = time.getTodayStr()
	local tb = userDefault.getForeverLocalKey(localKey, {}, {rawKey = true, rawData = true})
	if not tb[today] then
		tb = {[today] = {}}		-- 这样可以移除掉前一天的数据
	end

	if not (tb[today][checkKey] and tb[today][checkKey][dbId]) then
		tb[today][checkKey] = tb[today][checkKey] or {}
		tb[today][checkKey][dbId] = true
		userDefault.setForeverLocalKey(localKey, tb, {rawKey = true, new = true})
	end
end

function dataEasy.isTodayCheck(checkKey, dbId)
	dbId = stringz.bintohex(dbId)
	local today = time.getTodayStr()
	local tb = userDefault.getForeverLocalKey(localKey, {[today] = {}}, {rawKey = true, rawData = true})
	tb[today] = tb[today] or {}
	return tb[today][checkKey] and tb[today][checkKey][dbId]
end

function dataEasy.calcFightingPoint(id, level, attrs, skills)
	local unitID = csv.cards[id].unitID
	local cfg = csv.fighting_weight[csv.cards[id].fightingWeight]
	local point = level * cfg.level
	local rate = 1
	for attr, val in pairs(attrs) do
		if attr == 'strikeDamage' then
			val = val - 15000
		elseif attr == 'blockPower' then
			val = val - 3000
		end
		if val > 0 then
			if game.ATTRDEF_ENUM_TABLE[attr] < 14 then
				point = point + cfg[attr] * val
			else
				if cfg[attr] then
					rate = rate + cfg[attr] * val
				end
			end
		end
	end
	point = point * rate
	-- 技能
	for id, level in pairs(skills) do
		if csv.skill[id] then
			point = point + csv.skill[id].fightingPoint * level
		end
	end
	-- 基础值
	point = point + csv.unit[unitID].fightingPoint
	return math.floor(point)
end

-- 根据参数判断双倍相关活动是否开启中，并获取数据
function dataEasy.isDoubleHuodong(typeIdorStr)
	local typeId = typeIdorStr
	if type(typeIdorStr) == "string" then
		typeId = game.DOUBLE_HUODONG[typeIdorStr]
	end
	if not typeId then return false end
	local paramMaps = {}
	for _, yyId in ipairs(gGameModel.role:read("yy_open")) do
		local cfg = csv.yunying.yyhuodong[yyId]
		if game.YYHUODONG_TYPE_ENUM_TABLE.doubleDrop == cfg.type then
			local paramMap = cfg.paramMap
			if paramMap.type and paramMap.type == typeId then
				table.insert(paramMaps, paramMap)
			end
		end
	end
	local reunionState, reunionParamMaps, count = dataEasy.isReunionDoubleHuodong(typeId)
	if reunionState then
		if #paramMaps == 0 then
			paramMaps = reunionParamMaps
		else
			-- 若与平常日常活动同期，则在两个活动同时生效，两个活动均有加成次数的该活动副本，将叠加所有活动的次数
			if typeId >= game.DOUBLE_HUODONG.goldActivity and typeId <= game.DOUBLE_HUODONG.fragActivity then
				local map =  table.deepcopy(paramMaps[1], true)
				map.count = map.count + reunionParamMaps[1].count
				paramMaps[1] = map
			elseif typeId == game.DOUBLE_HUODONG.buyStamina or typeId == game.DOUBLE_HUODONG.buyGold then
				paramMaps = paramMaps[1].count < reunionParamMaps[1].count and reunionParamMaps or paramMaps
			elseif typeId == game.DOUBLE_HUODONG.gateDrop then
				-- 剧情副本掉落翻倍 扫荡与战斗都在计数内，若与日常关卡翻倍活动同期，则先按照日常活动的时间计算，之后再计算被活动次数
				-- 日常关卡判断
				local sceneConf = csv.scene_conf
				local normalDouble = false
				for k, paramMap in pairs(paramMaps) do
					local startId = tonumber(paramMap["start"])
					local startConf = sceneConf[startId]
					local gateType = startConf.gateType
					if gateType == game.GATE_TYPE.normal then
						normalDouble = true
						break
					end
				end
				-- 没有剧情副本掉落翻倍
				if not normalDouble then
					table.insert(paramMaps, reunionParamMaps[1])
				end
			-- elseif typeId == game.DOUBLE_HUODONG.endlessSaodang then
			-- 	-- 冒险之路扫荡翻倍 若与日常扫荡翻倍活动同期，则取翻倍数多的活动先进行，待该活动结束后再进行另外一个活动。
			-- 	paramMaps = reunionParamMaps[1].multiples > paramMaps[1].multiples and reunionParamMaps or paramMaps
			end
		end
	end
	if #paramMaps == 0 then
		return false
	else
		return true, paramMaps, #paramMaps
	end
end

-- 根据参数判断进度赶超双倍活动是否开启
function dataEasy.isReunionDoubleHuodong(typeId)
	local reunionTypeId = game.NORMAL_TO_REUNION[typeId]
	local reunion = gGameModel.role:read("reunion")
	if not reunionTypeId or not reunion or not reunion.info or reunion.role_type ~= 1 or reunion.info.end_time - time.getTime() <= 0 then
		return false
	end
	local cfg = csv.yunying.yyhuodong[reunion.info.yyID]
	if not cfg or not cfg.paramMap.huodong then
		return false
	end
	local huodongOpen = false
	for k, v in pairs(cfg.paramMap.huodong) do
		if v == "catch" then
			huodongOpen = true
		end
	end
	if not huodongOpen then
		return false
	end
	local function getStrInClock(timestamp) -- str 20150612
		local T = timestamp and time.getDate(timestamp) or time.getTimeTable()
		local freshHour = time.getRefreshHour()
		local freshMin = 0
		if T.hour * 100 + T.min < freshHour * 100 + freshMin then
			local t = timestamp - 24*3600
			T = time.getDate(t)
		end
		return string.format("%04d%02d%02d",T.year,T.month,T.day)
	end

	local startTime = tonumber(getStrInClock(math.floor(reunion.info.reunion_time)))
	local curTime = tonumber(time.getTodayStrInClock())
	if startTime > curTime then
		return false
	end

	local paramMaps = {}
	local catchup = reunion.catchup or {}
	for k, v in csvPairs(csv.yunying.reunion_catchup) do
		if v.huodongID == cfg.huodongID and v.params.type == reunionTypeId then
			if v.addType == 2 and catchup[k] then
				if catchup[k] >= v.addNum then
					return false
				end
			elseif v.addType == 1 then
				local endTime = startTime + v.addNum
				if endTime <= curTime then
					return false
				end
			end
			local paramMap = table.deepcopy(v.params, true)
			paramMap.type = typeId
			table.insert(paramMaps, paramMap)
		end
	end

	if #paramMaps == 0 then
		return false
	else
		return true, paramMaps, #paramMaps
	end
end

-- 判断当前关卡id是否在双倍掉落中
function dataEasy.isGateIdDoubleDrop(gateId)
	local sceneConf = csv.scene_conf[gateId] or csv.endless_tower_scene[gateId]
	if sceneConf.gateType == game.GATE_TYPE.endlessTower then
		return dataEasy.isDoubleHuodong("endlessSaodang")
	elseif sceneConf.gateType == game.GATE_TYPE.randomTower then
		return dataEasy.isDoubleHuodong("randomGold")
	end
	local state, paramMaps, count = dataEasy.isDoubleHuodong("gateDrop")
	if state then
		for _, paramMap in pairs(paramMaps) do
			local startId = paramMap["start"]
			local endId = paramMap["end"]
			if gateId <= endId and gateId >= startId then
				return true
			end
		end
	end
	return false
end

-- @desc 根据key获取物品拥有上限
-- @return math.huge 表示无限
function dataEasy.itemStackMax(key)
	if game.ITEM_STRING_ENUM_TABLE[key] then
		return math.huge
	end
	return dataEasy.getCfgByKey(key).stackMax or math.huge
end


-- @desc 判断开服天数是否达到
-- @param unlockFeature，对应pvpandpve表
function dataEasy.judgeServerOpen(unlockFeature)
	if unlockFeature == nil then
		return true
	end
	for k,v in orderCsvPairs(csv.pvpandpve) do
		if v.unlockFeature == unlockFeature then
			if v.serverDayInfo then
				if v.serverDayInfo.funcType == "less" then
					local day = getCsv(v.serverDayInfo.sevCsv)
					return not dataEasy.serverOpenDaysLess(day), day
				end
			end
			return true
		end
	end
	return true
end

function dataEasy.getUnionFubenCurrentMonth()
	-- 当月1号5点前用上个月做判断； 若1号是周日，则2号5点前用上个月做判断
	-- kr 特殊 0 点刷新
	local nowDate = time.getNowDate()
	local year = nowDate.year
	local month = nowDate.month
	local hour = time.getRefreshHour()
	-- wday 1 为周日
	if (nowDate.day == 1 and (nowDate.hour < hour or nowDate.wday == 1)) or (nowDate.day == 2 and nowDate.wday == 2 and nowDate.hour < hour) then
		month = month - 1
		if month < 1 then
			month = 12
			year = year - 1
		end
	end
	return year * 100 + month
end

-- @desc 判断是否有公会副本奖励
function dataEasy.haveUnionFubenReward()
	local currentMonth = dataEasy.getUnionFubenCurrentMonth()
	local unionFbAward = gGameModel.role:read("union_fb_award")
	local unionFubenPassed = gGameModel.role:read("union_fuben_passed")
	local i = 1
	for csvId,_ in orderCsvPairs(csv.union.union_fuben) do
		-- 已通关
		local complete = unionFubenPassed >= i
		i = i + 1
		-- 已领取
		local received = (unionFbAward[csvId] and unionFbAward[csvId][1] == currentMonth and unionFbAward[csvId][2] > 0)
		if complete and not received then
			return true
		end
	end
	return false
end

-- 活动界面显示替换
function dataEasy.isDisplayReplaceHuodong(typeStr)
	local function getTimestamp(huodongDate, huodongTime)
		local hour, min = time.getHourAndMin(huodongTime)
		return time.getNumTimestamp(huodongDate, hour, min)
	end
	if not typeStr then return false end
	local nowTime = os.time()
	for _, cfg in csvPairs(csv.huodong_display_replace) do
		local beginTime = getTimestamp(cfg.beginDate, cfg.beginTime)
		local endTime = getTimestamp(cfg.endDate, cfg.endTime)
		if cfg.clientParam[typeStr] and nowTime > beginTime and nowTime < endTime then
			return true, cfg.clientParam[typeStr]
		end
	end
	return false
end

-- 判断当前次数是否可扫荡
function dataEasy.getSaoDangState(times)
	local state = {canSaoDang = false, tip = ""}
	-- 特权
	local privilegeSweepTimes = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.GateSaoDangTimes)
	-- vip
	local vipLevel = gGameModel.role:read("vip_level")
	local sweepNum = gVipCsv[vipLevel].saodangCountOpen
	if privilegeSweepTimes < times and sweepNum < times then
		state.tip = gLanguageCsv.saodangMultiRoleNotEnough
	else
		state.canSaoDang = true
	end
	return state
end

-- 修正扫荡本地存储
function dataEasy.fixSaoDangLocalKey(key, timesTab)
	local sweepSelected = userDefault.getForeverLocalKey(key, 1)
	for i = 2, math.min(#timesTab, sweepSelected) do
		local times = timesTab[i]
		local state = dataEasy.getSaoDangState(times)
		if not state.canSaoDang then
			userDefault.setForeverLocalKey(key, i-1)
			return
		end
	end
end

-- 找当前是否存在指定类型的活动id, 注意返回值不准确，多数做为判定是否存在用，同个类型有多个活动id
function dataEasy.getActivityIdInYYOPEN(huodongType)
	for _, yyId in ipairs(gGameModel.role:read("yy_open")) do
		local cfg = csv.yunying.yyhuodong[yyId]
		if cfg.type == huodongType then
			return yyId
		end
	end
end

-- 获取努力值属性数据
function dataEasy.getEffortValueAttrData(attr)
	local attrTypeStr = game.ATTRDEF_TABLE[attr]
	local name = gLanguageCsv["attr" .. string.caption(attrTypeStr)]
	local icon = ui.ATTR_LOGO[game.ATTRDEF_TABLE[attr]]
	-- 把物攻换成双攻
	if attr == game.ATTRDEF_ENUM_TABLE.damage then
		name = gLanguageCsv.attrDoubleAttack
		icon = "common/icon/attribute/icon_sg.png"
	end
	return name, icon
end

-- @desc 显示属性根据类型和内容分别显示对应数值和百分比(当前值和下一等级的值)
function dataEasy.getAttrValueAndNextValue(key, val, nextVal)
	nextVal = dataEasy.getAttrValueString(key, nextVal)
	val = dataEasy.getAttrValueString(key, val)
	local nextHasPercent = string.find(nextVal, "%%")
	local hasPercent = string.find(val, "%%")
	if not hasPercent and nextHasPercent then
		val = val .. "%"
	end
	return val, nextVal
end

-- 和服务器定义保持统一
local USING_CARDS_DATA = {
	{
		-- 1. battle_cards
		key = "battle",
		get = function()
			return gGameModel.role:read("battle_cards")
		end,
	}, {
		-- 2.huodong_cards # 活动副本，PVE玩法会自动下阵，服务器处理
		-- 4.union training
		key = "unionTraining",
		get = function()
			return gGameModel.role:read("card_deployment").union_training.cards
		end,
	}, {
		-- 3. arena
		key = "arena",
		get = function()
			return gGameModel.role:read("card_deployment").arena.defence_cards
		end,
	}, {
		-- 4.craft # 报名阶段不能分解，服务器处理
		key = "craft",
		get = function()
			return gGameModel.role:read("card_deployment").craft.cards
		end,
	}, {
		-- 7.union_fight # 公会战报名阶段不能分解
		key = "unionFight",
		get = function()
			local t = {}
			local modelCard = gGameModel.role:read("card_deployment").union_fight or {}
			for _, v in pairs(modelCard) do
				for _, v1 in pairs(v) do
					table.insert(t, v1)
				end
			end
			return t
		end,
	}, {
		-- 7.crossunionfight # 跨服公会战入选布阵不能分解
		key = "crossunionfight",
		get = function()
			local t = {}
			local modelCard = gGameModel.role:read("card_deployment").cross_union_fight or {}
			for _, v in pairs(modelCard) do
				for _, v1 in pairs(v) do
					table.insert(t, v1)
				end
			end
			return t
		end,
	}, {
		-- 5.clone 元素挑战中不能分解
		key = "cloneBattle",
		get = function()
			return gGameModel.role:read("clone_deploy_card_db_id")
		end,
	}, {
		-- 6.cross craft # 报名阶段不能分解，服务器处理
		key = "crossCraft",
		get = function()
			return gGameModel.role:read("card_deployment").cross_craft.cards
		end,
	}, {
		-- 8.cross arena # 比赛中不能分解，服务器处理
		key = "crossArena",
		get = function()
			return gGameModel.role:read("card_deployment").cross_arena.defence_cards
		end,
	}, {
		-- 8.badge guard # 徽章守护中不能分解
		key = "gymBadgeGuard",
		get = function(cards)
			local t = {}
			local allCards = gGameModel.role:read("cards")
			for _, v in ipairs(allCards) do
				local card = gGameModel.cards:find(v)
				if card then
					local cardData = card:read("badge_guard")
					if cardData[1] then
						table.insert(t, v)
					end
				end
			end
			return t
		end,
	}, {
		-- 9.gymLeader # 占领的道馆馆主阵容
		key = "gymLeader",
		get = function()
			return gGameModel.role:read("card_deployment").gym.cards
		end,
	}, {
		-- 9.crossGymLeader # 占领的跨服道馆馆主
		key = "crossGymLeader",
		get = function()
			return gGameModel.role:read("card_deployment").gym.cross_cards
		end,
	}, {
		-- 11.crossMine # 商业街的防守阵容
		key = "crossMine",
		get = function()
			return gGameModel.role:read("card_deployment").cross_mine.defence_cards
		end,
	},
}
-- 获取使用中的卡牌，无法升星和分解操作
function dataEasy.inUsingCardsHash()
	local cards = {}
	for _, data in ipairs(USING_CARDS_DATA) do
		local modelCards = data.get()
		if type(modelCards) ~= "table" then
			modelCards = {modelCards}
		end
		for _, v in pairs(modelCards) do
			cards[v] = cards[v] or data.key
		end
	end
	return cards
end

-- 判断是否是老服（先锋服）和内服, false表示非先锋服，玩法不可玩
function dataEasy.isInServer(key)
	local cfg = csv.unlock[gUnlockCsv[key]]
	if not cfg then
		return false
	end
	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
	local tag = getServerTag(gameKey)
	local id = getServerId(gameKey, true)
	if cfg.servers[tag] and cfg.servers[tag][1] <= id and cfg.servers[tag][2] >= id then
		return true
	end
	return false
end

--跨服竞技场获取段位数据
function dataEasy.getCrossArenaStageByRank(rank)
	local csvId = game.crossArenaCsvId or gGameModel.cross_arena:read("csvID")
	if not csvId then
		return
	end
	local version = csv.cross.service[csvId].version
	for i, v in orderCsvPairs(csv.cross.arena.stage) do
		if v.version == version then
			if rank >= v.range[1] then
				local stageData = csvClone(v)
				stageData.index = i
				if v.stageID == 19 then
					stageData.rank = rank --王者段位分三段 特殊处理
				else
					stageData.rank = rank - v.range[1] + 1
				end
				return stageData
			end
		end
	end
end

-- 获取队伍buff图标
function dataEasy.getTeamBuff(data)
	local attrs ={}-- [attrId] = num
	for _, attr in pairs(data) do
		attrs[attr] = attrs[attr] or 0
		attrs[attr] = attrs[attr] + 1
	end

	local attrsIdx = {} -- [idx] = num
	for attrId, value in pairs(attrs) do
		table.insert(attrsIdx, value)
	end
	table.sort(attrsIdx, function(a, b)
		return a > b
	end)

	local natureCount = #attrsIdx -- 一共有得元素种类
	local csvHalo = csv.battle_card_halo
	local teamBuff = {} 		-- 比例buff [group] = {csvId, priority}
	local attrNumBuff = {} 		-- 单元素数量buff [csvId] = attrId
	local haloId = 0
	for id, cfg in csvPairs(csvHalo) do
		local args = cfg.args
		if cfg.type == 1 then
			local size = itertools.size(args)
			if size <= natureCount then -- 起码种类数量要符合
				local check = true
				for i = 1, size do
					if attrsIdx[i] < args[i] then -- 不符合
						check = false
						break
					end
				end
				if check == true then -- 最终符合
					local group = cfg.group
					local priority = cfg.priority
					-- 只要优先级不如现在这个则覆盖
					if not (teamBuff[group] and teamBuff[group].priority > priority) then
						teamBuff[group] = {
							csvId = id,
							priority = priority
						}
					end
				end
			end
		elseif cfg.type == 2 then
			for _, arg in pairs(args) do
				local n = attrs[arg[1]] or 0
				if n >= arg[2] then
					attrNumBuff[id] = arg[1]
				end
			end
		end
	end

	local imgPath = "config/embattle/icon_gh.png"
	local teamBuffs = {}
	local curGroup = -1
	for group, tb in pairs(teamBuff) do
		if curGroup < group then
			curGroup = group
			imgPath = csvHalo[tb.csvId].icon
		end
		teamBuffs[tb.csvId] = true
	end
	for id, attrId in pairs(attrNumBuff) do
		teamBuffs[id] = true
	end
	return {imgPath = imgPath, teamBuffs = teamBuffs}
end

-- 获取大于指定时间的下一期的跨服配置 id
-- dt 差值时间
function dataEasy.getCrossServiceData(key, servOpenDays, dt)
	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
	local tag = getServerTag(gameKey)
	local targetTime = time.getNumTimestamp(time.getTodayStrInClock(), time.getRefreshHour())
	if dt then
		targetTime = dt + targetTime
	end
	local function isOK(v)
		if time.getNumTimestamp(tonumber(v.date), time.getRefreshHour()) < targetTime then
			return false
		end
		-- 跨服组若为空，则为服务器自动匹配
		if csvSize(v.servers) == 0 then
			if v.cross == tag then
				return true
			end
		end
		-- 合服处理
		for _, server in ipairs(v.servers) do
			if isCurServerContainMerge(server) then
				return true
			end
		end
		return false
	end
	local targetDate, targetId
	local function setDateId(id, v)
		if not targetDate or v.date < targetDate then
			targetDate = v.date
			targetId = id
		end
	end
	for id, v in orderCsvPairs(csv.cross.service) do
		if v.service == key then
			-- 获取满足条件的最小日期数据
			if isOK(v) then
				if not servOpenDays then
					setDateId(id, v)
				else
					local delta = time.getNumTimestamp(v.date) - time.getNumTimestamp(time.getTodayStrInClock(0))
					local day = servOpenDays - math.floor(delta/86400)
					-- 若不满足玩法开始的开服天数，则显示到满足条件的配置那期
					if not dataEasy.serverOpenDaysLess(day) then
						setDateId(id, v)
					end
				end
			end
		end
	end
	if targetId then
		return targetId, csv.cross.service[targetId].servers
	end
	printWarn("dataEasy.getCrossServiceData: the server no find match ")
end

--获取关卡经验加成
function dataEasy.getWorldLevelExpAdd(gateType)
	local cfg = csv.world_level.base
	local lock = dataEasy.serverOpenDaysLess(cfg[1].servOpenDays)
	if not dataEasy.isUnlock(gUnlockCsv.worldLevel) or lock then
		return
	end
	local worldlevel = gGameModel.global_record:read("world_level") or 0
	local roleLevel = gGameModel.role:read("level")
	local diff = worldlevel - roleLevel
	for id,v in orderCsvPairs(csv.world_level.bonus) do
		if diff >= v.deltaRange[1] and diff <= v.deltaRange[2] then
			if gateType == 1 then
				return v.gateBonus
			elseif gateType == 2 then
				return v.heroGateBonus
			end
		end
	end
end

function dataEasy.onlineFightLoginServer(view, errCb, okCb)
	gGameModel.battle = nil -- 进实时对战之前保证battle为 nil，一次实时对战公平赛会存在两次battle model的创建，存在复用idler的情况
	gGameApp:requestServer("/game/cross/online/main", function(tb)
		local matchResult = gGameModel.cross_online_fight:read("match_result")
		if not itertools.isempty(matchResult) then
			local t = string.split(matchResult.address, ":")
			if not t[2] then
				gGameUI:showTip(gLanguageCsv.onlineFightBanError)
				if errCb then
					errCb()
				end
				return
			end
			gGameApp.net:doRealtime(t[1], tonumber(t[2]), function(ret, err)
				local onErrCb = function()
					gGameApp.net:doRealtimeEnd()
					if errCb then
						errCb()
					end
				end
				if err then
					gGameUI:showTip(err.err)
					onErrCb()
				else
					if not gGameModel.battle then
						gGameUI:showTip(gLanguageCsv.onlineFightBanError)
						onErrCb()
					else
						local hasResult = false
						local t = idlereasy.when(gGameModel.battle.state, function(_, state)
							if not hasResult then
								-- start, wait data, do nothing
								if state ~= game.SYNC_SCENE_STATE.start then
									hasResult = true
									if state == game.SYNC_SCENE_STATE.banpick then
										if okCb then
											okCb(function()
												gGameUI:stackUI("city.pvp.online_fight.ban_embattle", nil, {full = true}, {startFighting = dataEasy.onlineFightStartFighting})
											end)
										else
											gGameUI:stackUI("city.pvp.online_fight.ban_embattle", nil, {full = true}, {startFighting = dataEasy.onlineFightStartFighting})
										end

									elseif state == game.SYNC_SCENE_STATE.waitloading or state == game.SYNC_SCENE_STATE.attack then
										if okCb then
											okCb(dataEasy.onlineFightStartFighting)
										else
											dataEasy.onlineFightStartFighting()
										end
									else
										gGameUI:showTip(gLanguageCsv.onlineFightBanError)
										onErrCb()
									end
								end
							end
						end)
						if view then
							t:anonyOnly(view)
						end
					end
				end
			end)
		end
	end)
end

function dataEasy.onlineFightStartFighting()
	local battleData = gGameModel.battle:getData()
	battleEntrance.battle(battleData, {baseMusic = "battle1.mp3"})
		:enter()
end

--点击判断在不规则图形中属于哪块区域
function dataEasy.checkInRect(posTable, pos)
	for k, xyTable in ipairs(posTable) do
		if dataEasy.getLineIntersection(xyTable, pos) % 2 == 1 then
			return k
		end
	end
end

function dataEasy.getLineIntersection(posTable, pos)
	local count = 0
	for k, pos1 in ipairs(posTable) do
		while true do -- continue
			local pos2 = cc.p(0, 0)
			if posTable[k+1] then
				pos2 = posTable[k+1]
			else
				pos2 = posTable[1]
			end
			if (pos.x < math.min(pos1.x, pos2.x)) or (pos.x > math.max(pos1.x, pos2.x)) or pos.y > math.max(pos1.y, pos2.y) then
				break
			end
			local y = (pos2.y - pos1.y)/ (pos2.x - pos1.x) * (pos.x - pos1.x)+ pos1.y
			if y >= pos.y then
				count = count + 1
			end
			break
		end
	end
	return count
end

-- get符合属性限制的精灵
function dataEasy.getNatureSprite(natureLimit)
	if csvSize(natureLimit) == 0 then
		--不限制
	end
	local hashMap = itertools.map(natureLimit or {}, function(k, v) return v, 1 end)
	local cards = gGameModel.role:read("cards")
	local data = {}
	for i,v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local card_id = card:read("card_id")
		local cardCsv = csv.cards[card_id]
		local unitCsv = csv.unit[cardCsv.unitID]
		if csvSize(natureLimit) == 0 or hashMap[unitCsv.natureType] or hashMap[unitCsv.natureType2] then
			table.insert(data, v)
		end
	end
	return data
end

-- 是否跳过新手引导战斗
function dataEasy.isSkipNewbieBattle(okcb, closeCb)
	if dev.GUIDE_CLOSED or FOR_SHENHE or gGameUI.guideManager:checkFinished(-2) or gGameUI.guideManager:checkFinished(-1) then
		if okcb then
			okcb()
		end
		return true
	end
	local cfg = csv.unlock[gUnlockCsv.skipNewbieBattle]
	if not SERVERS_INFO or not cfg or not dataEasy.isInServer(cfg.feature) then
		if closeCb then
			closeCb()
		end
		return false
	end

	-- 账号内有大于指定等级和vip的角色的时候 直接到新手建号选人物阶段
	local roleInfos = gGameModel.account:read("role_infos")
	for key, _ in pairs(SERVERS_INFO) do
		local data = roleInfos[key]
		if data and data.level >= cfg.startLevel and data.vip >= cfg.startVip then
			if okcb then
				gGameUI:showDialog({
					content = gLanguageCsv.isSkipNewbieBattle,
					cb = okcb,
					closeCb = closeCb,
					btnType = 2,
					clearFast = true,
					dialogParams = {clickClose = false},
				})
			end
			return true
		end
	end

	if closeCb then
		closeCb()
	end
	return false
end

-- 钻石使用二次确认弹窗
-- count 钻石消耗数量 nil则不显示钻石消耗数量
-- str1 拓展描述
function dataEasy.sureUsingDiamonds(cb, count, cancleCb, str1)
	local count = count or ""
	if matchLanguage({"kr"}) and (type(count) == "number" or type(count) == "string" ) then
		local str = string.format(gLanguageCsv.sureUsingDiamonds, count)
		if str1 then
			str = string.format(gLanguageCsv.sureUsingDiamonds2, count) .. " " .. str1
		end
		gGameUI:showDialog({strs = "#C0x5B545B#"..str, cb = cb, closeCb = cancleCb, cancelCb = cancleCb, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
	else
		cb()
	end
end

function dataEasy.tryCallFunc(node, name, ...)
	if node[name] then
		node[name](node, ...)
	end
end

function dataEasy.showDialogToShop()
	if matchLanguage({"kr"}) then
		local str = gLanguageCsv.showDialogToShop
		gGameUI:showDialog({strs = "#C0x5B545B#"..str, cb = function ()
			cc.Application:getInstance():openURL(JUMP_SHOP_URL)
		end, title = gLanguageCsv.evaluation, btnStr = gLanguageCsv.goNow, isRich = true, dialogParams = {clickClose = false}})
	end
end

-- 获取队伍buff图标，双属性选择最优
-- data {{attr1, attr2}, ...}
function dataEasy.getTeamBuffBest(data)
	local flags = {1, 1, 1, 1, 1, 1} -- buff 选择的下标
	if itertools.size(data) < 6 then
		local buf = dataEasy.getTeamBuff({})
		return {buf = buf, flags = flags}
	end
	local result
	local csvHalo = csv.battle_card_halo
	local function dfs(index)
		if index > 6 then
			local attrs = {}
			for i = 1, 6 do
				table.insert(attrs, data[i][flags[i]])
			end
			local buf = dataEasy.getTeamBuff(attrs)
			local csvId, autoPriority
			for id, _ in pairs(buf.teamBuffs) do
				if csvHalo[id].type == 1 and (not autoPriority or autoPriority < csvHalo[id].autoPriority) then
					csvId = id
					autoPriority = csvHalo[id].autoPriority
				end
			end
			if not result then
				result = {csvId = csvId, buf = buf, flags = clone(flags)}
			elseif csvId then
				if not result.csvId or csvHalo[result.csvId].autoPriority < autoPriority then
					result = {csvId = csvId, buf = buf, flags = clone(flags)}
				end
			end
			return
		end
		flags[index] = 1
		dfs(index+1)
		if data[index][2] then
			flags[index] = 2
			dfs(index+1)
		end
	end
	dfs(1)
	return result
end


-- 判断是否是皮肤
function dataEasy.isSkinByKey(key)
	local id = dataEasy.stringMapingID(key)
	if not id or type(id) == "string" then
		return false
	end
	local cfg = nil
	if id <= game.ITEM_CSVID_LIMIT then
		cfg = csvItems[id]
	end

	if cfg  and cfg.type == game.ITEM_TYPE_ENUM_TABLE.skin then
		return true, cfg.specialArgsMap
	else
		return false
	end
end


-- 获取精灵的unitid
function dataEasy.getUnitId(cardid, skinid)
	if skinid == nil or skinid == 0 then
		return csv.cards[cardid].unitID
	end

	local cfg = gSkinCsv[skinid]
	if not cardid then
		-- 多组的按当前有用 markId 最大的显示，若无则显示 unitIds key小的
		if csvSize(cfg.unitIDs) > 1 then
			local fightingPoint = 0
			for _, v in ipairs(gGameModel.role:read("cards")) do
				local card = gGameModel.cards:find(v)
				if card then
					local tmpCardid = card:read("card_id")
					if cfg.unitIDs[tmpCardid] and csv.cards[tmpCardid].cardMarkID == cfg.markID then
						local val = card:read("fighting_point")
						if val > fightingPoint then
							fightingPoint = val
							cardid = tmpCardid
						end
					end
				end
			end
		end
		if not cardid then
			cardid = csvNext(cfg.unitIDs)
		end
	end
	local _, unitId = csvNext(cfg.unitIDs)
	return cfg.unitIDs[cardid] or unitId
end

-- 获取精灵的Res数据
function dataEasy.getUnitCsv(cardid, skinid)
	local unitId = dataEasy.getUnitId(cardid, skinid)
	return csv.unit[unitId]
end


-- 获取精灵的技能列表
function dataEasy.getCardSkillList(cardid, skinid)
	if skinid == nil or skinid == 0 then
		return csv.cards[cardid].skillList
	else
		local map = csv.cards[cardid].skinSkillMap
		return map[skinid]
	end
	return nil
end


function dataEasy.isShowSkinIcon(cardid)
	local map = csv.cards[cardid].skinSkillMap
	local sign = false

	for key, data in csvPairs(map) do
		-- if not assertInWindows(gSkinCsv[key], "skin %d is null", key) then
		if gSkinCsv[key] and gSkinCsv[key].isOpen then
			sign = true
			break
		end
		-- end
	end
	return sign
end

-- 获取jjc形象的ID
function dataEasy.getUnitIdForJJC(id)
	local skinId
	if id > game.SKIN_ADD_NUM then
		skinId = id % game.SKIN_ADD_NUM
		id = nil
	end
	return dataEasy.getUnitId(id, skinId) or 0
end

-- 判断日常副本特殊活动是否开启，是否显示
function dataEasy.isShowDailyActivityIcon()
	local function getTimestamp(huodongDate, huodongTime)
		local hour, min = time.getHourAndMin(huodongTime)
		return time.getNumTimestamp(huodongDate, hour, min)
	end
	local nowTime = time.getTime()
	for k, v in orderCsvPairs(csv.huodong) do
		if csvSize(v.paramMap) > 0 then
			local beginTime = getTimestamp(v.beginDate, v.beginTime)
			local endTime = getTimestamp(v.endDate, v.endTime)
			if nowTime > beginTime and nowTime < endTime then
				return true, v
			end
		end
	end
	return false
end

-- 判断当前技能是否是zawake强化技能
function dataEasy.isZawakeSkill(skillID, zawakeSkills)
	if not csv.skill[skillID] then return false end

	local zawakeEffectID = csv.skill[skillID].zawakeEffect[1]
	for _, id in ipairs(zawakeSkills or {}) do
		if zawakeEffectID == id then
			return true
		end
	end
	return false
end

-- 支付客户端本地存储保护时间
function dataEasy.getPayClientSafeTime()
	-- 先取消本地存储保护时间
	do return -1 end
	if APP_CHANNEL == "lp_en" then
		return 600
	end
	if device.platform == "ios" then
		return 3600
	end
	return 600
end

function dataEasy.setPayClientBuyTimes(key, activityId, idx, nowTimes)
	local curTime = time.getTime()
	local userDefaultData = userDefault.getForeverLocalKey(key, {})
	userDefaultData[activityId] = userDefaultData[activityId] or {}
	local data = userDefaultData[activityId][idx] or {buyTimes = 0, curTime = curTime}
	data.buyTimes = math.max(data.buyTimes, nowTimes) + 1
	data.curTime = curTime
	userDefaultData[activityId][idx] = data
	userDefault.setForeverLocalKey(key, userDefaultData, {new = true})
end

function dataEasy.getPayClientBuyTimes(key, activityId, idx, nowTimes)
	-- 客户端本地存储保护时间
	local curTime = time.getTime()
	local clientSafeTime = dataEasy.getPayClientSafeTime()
	local userDefaultData = userDefault.getForeverLocalKey(key, {})
	userDefaultData[activityId] = userDefaultData[activityId] or {}
	local data = userDefaultData[activityId][idx] or {buyTimes = 0, curTime = curTime}
	-- 本地记录的数据超clientSafeTime，则忽略本地存储计数
	if curTime - data.curTime > clientSafeTime then
		data.buyTimes = 0
		userDefaultData[activityId][idx] = nil
		userDefault.setForeverLocalKey(key, userDefaultData, {new = true})
		return nowTimes
	end

	-- 如果服务器数据已到，即大于等于本地记录数，清掉本地数据
	if nowTimes >= data.buyTimes then
		data.buyTimes = 0
		userDefaultData[activityId][idx] = nil
		userDefault.setForeverLocalKey(key, userDefaultData, {new = true})
		return nowTimes
	end

	return data.buyTimes
end

-- 获取竞技时间
function dataEasy.getTimeStrByKey(key, state, isVal)
	local data = {
		craft = {
			signUpStart = {hour = 10, min = 0},
			signUpEnd = {hour = 19, min = 50},
			matchStart = {hour = 20, min = 0}
		},
		unionFight = {
			signUpStart = {hour = 9, min = 30},
			signUpEnd = {hour = 20, min = 50},
			matchStart = {hour = 21, min = 0}
		},
		crossCraft = {
			signUpStart = {hour = 10, min = 0},
			signUpEnd = {hour = 18, min = 50},
			matchStart = {hour = 19, min = 0},
			matchEnd = {hour = 19, min = 46}
		},
		onlineFight = {
			matchStart = {hour = 12, min = 0},
			matchEnd = {hour = 20, min = 0},
			over = {hour = 22, min = 0}
		},
		crossMine = {
			mineStart = {hour = 10, min = 0},
			mineEnd = {hour = 22, min = 0}
		}
	}
	if matchLanguage({"en"}) then
		data["craft"]["signUpStart"] = {hour = 13, min = 0}
		data["craft"]["signUpEnd"] = {hour = 21, min = 50}
		data["craft"]["matchStart"] = {hour = 22, min = 0}

		data["unionFight"]["signUpStart"] = {hour = 11, min = 30}
		data["unionFight"]["matchStart"] = {hour = 23, min = 0}

		data["crossCraft"]["signUpStart"] = {hour = 13, min = 0}
		data["crossCraft"]["signUpEnd"] = {hour = 21, min = 50}
		data["crossCraft"]["matchStart"] = {hour = 22, min = 0}
		data["crossCraft"]["matchEnd"] = {hour = 22, min = 46}

		data["crossMine"]["mineStart"] = {hour = 12, min = 0}
		data["crossMine"]["mineEnd"] = {hour = 23, min = 0}
	end
	if isVal then
		return data[key][state].hour, data[key][state].min
	end
	return string.format("%02d:%02d", data[key][state].hour, data[key][state].min)
end

-- 获得自身的符石指数
function dataEasy.getGemQualityIndex(card)
	local gems = card:read('gems')
	local qualityCsv, gemCsv = csv.gem.quality, csv.gem.gem
	local qualityNum = 0
	for k, dbid in pairs(gems) do
		local gem = gGameModel.gems:find(dbid)
		local level = gem:read('level')
		local gemId = gem:read('gem_id')
		local quality = gemCsv[gemId].quality
		qualityNum = qualityNum + qualityCsv[level]["qualityNum"..quality]
	end
	return qualityNum
end
