-- @date:   2019-11-14
-- 可捕捉精灵界面
local CaptureHandbook = class("CaptureHandbook", cc.load("mvc").ViewBase)

local MAX_ROW = 9 -- 每行限时的最大精灵个数

-- 初始化标题的item
local function initTileItem(list, node, k, v)
	node:size(1950, 90)
	node:get("list"):hide()
	node:get("title"):y(45):show()
	local title = node:get("title.textTitle")
	local imgRight = node:get("title.imgRight")
	local imgLeft = node:get("title.imgLeft")
	if v.gate == 0 then	--可捕捉精灵
		title:text(gLanguageCsv.card)
	else
		local content = string.format(gLanguageCsv.unlockGateToCapture,v.gate,csv.world_map[v.gate+10].name)
		title:text(content)
	end
	title:x(1950/2)
	imgRight:x(title:width() / 2 + 40 + 1950 / 2)
	imgLeft:x(-title:width() / 2 - 40 + 1950 / 2)
end

-- 初始化精灵列表的item
local function initSpriteItem(list, node, k, v)
	local datas = {}
	for _, data in ipairs(v) do
		table.insert(datas, {key = "card", num = data.cardID})
	end
	node:get("title"):hide()
	local spriteList = node:get("list"):y(0)
	local innerItem = list.spriteItem
	node:size(cc.size(1950, 195))
	bind.extend(list, spriteList, {
		class = "listview",
		props = {
			data = datas,
			item = innerItem,
			onItem = function(innerList, cell, kk ,vv)
				bind.extend(innerList, cell, {
					class = "icon_key",
					props = {
						data = vv,
					},
				})
				cell:visible(true)
			end,
		}
	})
end

CaptureHandbook.RESOURCE_FILENAME = "capture_handbook.json"
CaptureHandbook.RESOURCE_BINDING = {
	["spriteItem"] = "spriteItem",	-- 每列item
	["item"] = "item",			-- 每行item
	["list"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showDatas"),
				item = bindHelper.self("item"),
				spriteItem = bindHelper.self("spriteItem"),
				asyncPreload = 7,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					if v.type == "title" then
						initTileItem(list, node, k, v)
					else
						initSpriteItem(list, node, k, v)
					end
				end,
			},
		},
	},
}

function CaptureHandbook:onCreate()
	local gateOpen = gGameModel.role:read("gate_open") -- 开放的关卡列表
	self.showDatas = {} --分组好的数据

	--合并已经可以捕捉的精灵
	local tempData = {[0] = {}}
	for i,v in orderCsvPairs(csv.capture.sprite) do
		if v.type == 2 and v.weight ~= 0 then
			-- 权重为0 不显示
			local chapterId = math.floor((v.gate % 10000) / 100)
			--去重
			local hasSame = false
			if tempData[chapterId] then
				for ii, vv in ipairs(tempData[chapterId]) do
					if v.cardID == vv.cardID then
						hasSame = true
						break
					end
				end
			end

			if hasSame == false then
				if itertools.include(gateOpen, v.gate) or v.gate == 0 then
					table.insert(tempData[0], v)
				else
					tempData[chapterId] = tempData[chapterId] or {}
					table.insert(tempData[chapterId], v)
				end
			end
		end
	end

	-- 稀有度排序
	for k, v in pairs(tempData) do
		table.sort(v,function(a, b )
			local unitID1 = csv.cards[a.cardID].unitID
			local unitID2 = csv.cards[b.cardID].unitID
			local rarity1 = csv.unit[unitID1].rarity
			local rarity2 = csv.unit[unitID2].rarity
			return rarity2 < rarity1
		end)
	end

	local maxGate = 0
	for k, v in pairs(tempData) do
		maxGate = math.max(maxGate, k)
	end

	-- 分成9个一组的数据
	local row = 1
	for k = 0, maxGate do
		local v = tempData[k]
		if v ~= nil then
			self.showDatas[row] = {type = "title",gate = k}
			local count = 0
			for kk, vv in ipairs(v) do
				local x = math.ceil(kk / MAX_ROW)	-- 行
				local y = (kk - 1) % MAX_ROW + 1	-- 列
				self.showDatas[x + row] = self.showDatas[x + row] or {}
				self.showDatas[x + row][y] = vv
				count = count + 1
			end
			row = math.ceil(count / MAX_ROW) + row + 1
		end
	end
end

return CaptureHandbook