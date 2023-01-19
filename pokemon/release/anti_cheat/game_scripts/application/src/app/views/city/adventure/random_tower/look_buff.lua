-- @date:   2019-10-12
-- @desc:   随机塔-查看buff
--补给类型（1-回血；2-回怒；3-复活）
local SUPPLY_TYPE = {
	hp = 1,
	mp = 2,
	life = 3
}
--buff类型 (1=属性加成;2=补给;3=积分加成;4=被动技能)
local BUFF_TYPE = {
	attr = 1,
	supply = 2,
	point = 3,
	skill = 4
}

local function onInitItem(list, node, k, v)
	for i=1,math.huge do
		local item = node:get("item"..i)
		if not item then
			break
		end
		item:removeFromParent()
	end
	local childs = node:multiget("titlePanel", "list", "textDesc")
	local listW = list:size().width
	childs.titlePanel:visible(v.itemType == "title")
	childs.textDesc:visible(v.itemType == "empty")
	childs.list:visible(v.itemType == "item")

	if v.itemType == "title" then
		local box = node:get("titlePanel"):getBoundingBox()
		node:size(cc.size(listW, box.height))
		node:get("titlePanel"):y(box.height / 2)
		local title = childs.titlePanel:get("textTitle")
		title:text(v.title)
		text.addEffect(title, {outline={color=ui.COLORS.OUTLINE.WHITE}})
	elseif v.itemType == "empty" then
		local itemSize = list.cloneItem:size()
		node:size(cc.size(listW, itemSize.height + 10))
		node:get("list"):size(cc.size(listW, itemSize.height + 10))
		childs.textDesc:text(v.desc)
	else
		local itemSize = list.cloneItem:size()
		node:size(cc.size(listW, itemSize.height + 10))
		node:get("list"):size(cc.size(listW, itemSize.height + 10))
		local binds = {
			class = "listview",
			props = {
				data = v.buffDatas,
				item = list.cloneItem,
				topPadding = padding,
				onItem = function(subList, cell, kk ,v)
					cell:get("icon"):texture(v.icon):scale(1.5)
					cell:onClick(functools.partial(list.clickCell, k, v))
				end,
			},
		}
		bind.extend(list, node:get("list"), binds)
	end
end
local ViewBase = cc.load("mvc").ViewBase
local RandomTowerLookBuffView = class("RandomTowerLookBuffView", ViewBase)

RandomTowerLookBuffView.RESOURCE_FILENAME = "random_tower_look_buff.json"
RandomTowerLookBuffView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["textNum"] = "textNum",
	["buffItem"] = "buffItem",
	["centerItem"] = "centerItem",
	["subList"] = "subList",
	["centerList"] = {
		varname = "centerList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("centerDatas"),
				item = bindHelper.self("centerItem"),
				cloneItem = bindHelper.self("buffItem"),
				clonSubList = bindHelper.self("subList"),
				backupCached = false,
				onItem = function(list, node, k, v)
					onInitItem(list, node, k, v)
				end,
				asyncPreload = 6,
			},
			handlers = {
				clickCell = bindHelper.self("onClickItem"),
			},
		},
	},
	["rightTitlePanel.textTitle"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		}
	},
	["rightItem"] = "rightItem",
	["rightList"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("rightItem"),
				dataOrderCmp = function(a, b)
					return a.sortKey < b.sortKey
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("textTitle", "textNum")
					childs.textTitle:text(v.name)
					adapt.setTextScaleWithWidth(childs.textTitle, nil, 240)
					local str = "+0%"
					local color = ui.COLORS.NORMAL.WHITE
					if tonumber(v.num) > 0 then
						str = "+"..dataEasy.getAttrValueString(k, v.num..v.symbol)
					elseif tonumber(v.num) < 0 then
						str = dataEasy.getAttrValueString(k, v.num..v.symbol)
						color = ui.COLORS.NORMAL.RED
					end
					text.addEffect(childs.textNum, {color = color})
					childs.textNum:text(str)
				end,
			},
		},
	},
}
function RandomTowerLookBuffView:onCreate(boardID, cb)
	self:initModel()
	self.cb = cb
	self.centerDatas = idlers.new()
	self.attrDatas = idlers.new()
	local attrDatas = {
		[7] = {sortKey = 1, name = gLanguageCsv.spaceDamage, num = 0, symbol = ""},
		[8] = {sortKey = 2, name = gLanguageCsv.spaceSpecialDamage, num = 0, symbol = ""},
		[9] = {sortKey = 3, name = gLanguageCsv.spaceDefence, num = 0, symbol = ""},
		[10] = {sortKey = 4, name = gLanguageCsv.spaceSpecialDefence, num = 0, symbol = ""},
		[14] = {sortKey = 5, name = gLanguageCsv.spaceStrike, num = 0, symbol = ""},
		[15] = {sortKey = 6, name = gLanguageCsv.attrStrikeDamage, num = 0, symbol = ""},
		[17] = {sortKey = 7, name = gLanguageCsv.spaceBlock, num = 0, symbol = ""},
		[26] = {sortKey = 8, name = gLanguageCsv.spaceSuckBlood, num = 0, symbol = ""},
		[22] = {sortKey = 9, name = gLanguageCsv.attrDamageAdd, num = 0, symbol = ""},
		[23] = {sortKey = 10, name = gLanguageCsv.attrDamageSub, num = 0, symbol = ""},

	}

	local titleDatas = {
		[BUFF_TYPE.point] = {title = gLanguageCsv.pointAdd},
		[BUFF_TYPE.skill] = {title = gLanguageCsv.battleAdd}
	}
	idlereasy.when(self.buffs, function(_, buffs)
		local buffDatas = {}
		--属性数据
		for k,buffId in ipairs(buffs) do
			local buffCfg = csv.random_tower.buffs[buffId]
			local buffType = buffCfg.buffType
			--属性加成数据
			if BUFF_TYPE.attr == buffType then
				for i=1,3 do
					local attrNum = buffCfg["attrNum"..i]
					local attrType = buffCfg["attrType"..i]
					if attrDatas[attrType] ~= nil and attrNum ~= "" then
						if string.find(attrNum,"%%") then
							attrNum = string.gsub(attrNum,"%%","")
							attrDatas[attrType].symbol = "%"
						end
						attrDatas[attrType].num = attrDatas[attrType].num + tonumber(attrNum)
					end
				end
			end
			--积分加成和战斗加成数据
			if BUFF_TYPE.point == buffType or BUFF_TYPE.skill == buffType then
				if not buffDatas[buffType] then
					buffDatas[buffType] = {}
				end
				table.insert(buffDatas[buffType], buffId)
			end
		end
		self.attrDatas:update(attrDatas)
		--加成数据
		local centerDatas = {}
		for buffType,v in csvMapPairs(titleDatas) do
			table.insert(centerDatas, {itemType = "title", title = v.title})
			if not buffDatas[buffType] then
				table.insert(centerDatas, {itemType = "empty", desc = string.format(gLanguageCsv.noSomeAdd, v.title)})
			else
				local t = {}
				for k,buffId in ipairs(buffDatas[buffType]) do
					local buffCfg = csv.random_tower.buffs[buffId]
					table.insert(t, {icon = buffCfg.icon, buffId = buffId})
					if k % 5 == 0 then
						table.insert(centerDatas, {itemType = "item", buffDatas = t})
						t = {}
					end
				end
				if next(t) ~= nil then
					table.insert(centerDatas, {itemType = "item", buffDatas = t})
				end
			end
		end
		self.centerDatas:update(centerDatas)
	end)
end

function RandomTowerLookBuffView:initModel()
	self.cardStates = gGameModel.random_tower:getIdler("card_states")
	self.roomInfo = gGameModel.random_tower:getIdler("room_info")
	self.cards = gGameModel.role:getIdler("cards")
	self.buffs = gGameModel.random_tower:getIdler("buffs")
end

function RandomTowerLookBuffView:onitemClick(list, t, v)
	self.selectIdx:set(t.k)
end

--查看详情
function RandomTowerLookBuffView:onClickItem(list, index, v, event)
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x - 290, y - 90))
	gGameUI:stackUI("city.adventure.random_tower.buff_detail", nil, nil, {
		buffId = v.buffId,
		pos = pos,
		target = list.item
	})
end
return RandomTowerLookBuffView
