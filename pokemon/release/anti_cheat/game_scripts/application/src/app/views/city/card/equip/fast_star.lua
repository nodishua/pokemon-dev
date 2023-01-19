
local STEP = 1

local ViewBase = cc.load("mvc").ViewBase
local CardStarOneKeyView = class("CardStarOneKeyView", Dialog)

CardStarOneKeyView.RESOURCE_FILENAME = "card_equip_fast_strengthen.json"
CardStarOneKeyView.RESOURCE_BINDING = {
	["title"] = "title",
	["titleTxt1"] = "titleTxt1",
	["titleTxt2"] = "titleTxt2",
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
			methods = {ended = bindHelper.self("onReduceClick")}
		}
	},
	["top.addBtn"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddClick")}
		}
	},
	["sureBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSureClick")}
		}
	},
	["cancelBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
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
											-- :anchorPoint(0.5, 0.5)
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
}

function CardStarOneKeyView:onCreate(selectDbId, equipId, cb)
	self.selectDbId = selectDbId
	self.equipId = equipId
	self.cb = cb
	self:initModel()
	self.title:hide()
	self.titleTxt2:text(gLanguageCsv.starUp)
	local cfg = csv.equips[self.equipId]
	-- 设置icon
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
	local abilityMax = cfg.abilityMax
	self.currLevelLimit = abilityMax
	local ability = self.equipData.ability or 0
	local equipId = self.equipData.equip_id
	-- 默认选择的等级
	local selectLv = ability + 1
	local needItems = {}
	local needGold = 0
	local isEnoughItem = true
	for i = ability, abilityMax - 1 do
		local costCfg = csv.base_attribute.equip_ability[i]["costItemMap"..cfg.abilitySeqID]
		for id, num in csvMapPairs(costCfg) do
			if id == "gold" then
				if self.gold < needGold + num then
					isEnoughItem = false
					break
				else
					needGold = needGold + num
				end
			else
				if dataEasy.getNumByKey(id) < (needItems[id] or 0) + num then
					isEnoughItem = false
					break
				else
					needItems[id] = (needItems[id] or 0) + num
				end
			end
		end
		if isEnoughItem then
			selectLv = i + 1
		else
			break
		end
	end

	self.selectLv = idler.new(selectLv)
	self.itemData = idlertable.new({})
	idlereasy.when(self.selectLv, function(_, selectLv)
		local needGold = 0
		needItems = {}
		self.isEnoughItem = true
		for i = ability, selectLv - 1 do
			local costCfg = csv.base_attribute.equip_ability[i]["costItemMap"..cfg.abilitySeqID]
			for id,num in csvMapPairs(costCfg) do
				if id == "gold" then
					needGold = needGold + num
				else
					needItems[id] = needItems[id] or {id = id, num = dataEasy.getNumByKey(id), targetNum = 0, orderKey = 1}
					needItems[id].targetNum = needItems[id].targetNum + num
					if dataEasy.getNumByKey(id) < needItems[id].targetNum then
						needItems[id].orderKey = 2
						self.isEnoughItem = false
					end
				end
			end
		end
		-- 金币充足
		self.isEnoughGold = dataEasy.getNumByKey("gold") >= needGold
		self.itemData:set(needItems)
		self.nameMax:text(selectLv)
		self.cashNum:text(needGold)
		local coinColor = self.isEnoughGold and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.RED
		text.addEffect(self.cashNum, {color = coinColor})
		adapt.oneLinePos(self.cashNum, self.cashIcon, cc.p(12, 0))
		cache.setShader(self.addBtn, false, (selectLv >= abilityMax) and "hsl_gray" or  "normal")
		self.addBtn:setTouchEnabled(selectLv < abilityMax)
		cache.setShader(self.subBtn, false, (selectLv <= ability + 1) and "hsl_gray" or  "normal")
		self.subBtn:setTouchEnabled(selectLv > ability +1)
	end)

	Dialog.onCreate(self)
end

function CardStarOneKeyView:initModel()
	local card = gGameModel.cards:find(self.selectDbId)
	self.fight = card:getIdler("fighting_point")
	self.equips = card:getIdler("equips")
	self.roleLv = gGameModel.role:getIdler("level")
	self.gold = gGameModel.role:read("gold")
end

function CardStarOneKeyView:onAddClick()
	self.selectLv:set(math.min(self.currLevelLimit, self.selectLv:read() + STEP))
end

function CardStarOneKeyView:onReduceClick()
	self.selectLv:set(math.max(self.equipData.ability + 1, self.selectLv:read() - STEP))
end

function CardStarOneKeyView:onSureClick()
	local cfg = csv.equips[self.equipId]
	if not self.isEnoughItem then
		gGameUI:showTip(gLanguageCsv.equipNotEnoughStarItems)
		return
	end
	if not self.isEnoughGold then
		gGameUI:showTip(gLanguageCsv.strengthGoldNotEnough)
		return
	end
	local showOver = {false}
	gGameApp:requestServerCustom("/game/equip/ability")
		:params(self.selectDbId, cfg.part, self.selectLv:read() - self.equipData.ability)
		:onResponse(function (tb)
			showOver[1] = true
		end)
		:wait(showOver)
		:doit(function (tb)
			self:addCallbackOnExit(functools.partial(self.cb))
			ViewBase.onClose(self)
		end)
end
function CardStarOneKeyView:onItemClick(list, k, v)
	gGameUI:stackUI("common.gain_way", nil, nil, v.id, self:createHandler("refreshUI"), v.num)
end
function CardStarOneKeyView:refreshUI()
	self.selectLv:notify()
end
--排序
function CardStarOneKeyView:onSortRank(list)
	return function(a, b)
		if a.orderKey ~= b.orderKey then
			return a.orderKey > b.orderKey
		end
		return a.id < b.id
	end
end
return CardStarOneKeyView
