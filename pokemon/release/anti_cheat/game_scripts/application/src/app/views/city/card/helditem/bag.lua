-- @date:   2019-06-21
-- @desc:   携带道具背包界面

local HeldItemTools = require "app.views.city.card.helditem.tools"

local EQUIPSTATE = {
	dress = 1,
	down = 2,
}

local LIST_WIDTH = 450

local HeldItemBagView = class("HeldItemBagView", Dialog)

HeldItemBagView.RESOURCE_FILENAME = "held_item_bag.json"
HeldItemBagView.RESOURCE_BINDING = {
	["left"] = "left",
	["left.title.textNote1"] = "textNote1",
	["left.title.textNote2"] = "textNote2",
	["left.title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["left.btnLeft"] = {
		varname = "btnLeft",
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				data = bindHelper.self("leftSortData"),
				btnClick = bindHelper.self("onSortLeftMenusBtnClick", true),
				btnTouch = bindHelper.self("onCloseLeftOtherView", true), -- 关闭其他展开项
				showSortList = bindHelper.self("isLeftDownListShow"), -- 是否展开
				showSelected = bindHelper.self("showLeftSelected"), -- 默认选中项
				btnWidth = 260,
				btnHeight = 80,
				width = 240,
				btnType = 2,
				onNode = function(node)
					node:xy(-1150, -528)
				end,
			},
		}
	},
	["left.btnRight"] = {
		varname = "btnRight",
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				data = bindHelper.self("rightSortData"),
				btnClick = bindHelper.self("onSortRightMenusBtnClick", true),
				btnTouch = bindHelper.self("onCloseRightOtherView", true), -- 关闭其他展开项
				showSortList = bindHelper.self("isRightDownListShow"), -- 是否展开
				showSelected = bindHelper.self("showRightSelected"), -- 默认选中项
				btnWidth = 260,
				btnHeight = 80,
				width = 240,
				btnType = 2,
				onNode = function(node)
					node:xy(-1150, -528)
				end,
			},
		}
	},
	["left.noItem"] = {
		varname = "noItem",
		binds = {
			event = "visible",
			idler = bindHelper.self("hasItem"),
		},
	},
	["left.handbook"] = {
		varname = "handbook",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("bagHandbook")},
		},
	},
	["right"] = {
		varname = "rightPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("isVisibleRight")
		},
	},
	["item"] = "item",
	["innweList"] = "innweList",
	["left.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("heldItems"),
				item = bindHelper.self("innweList"),
				cell = bindHelper.self("item"),
				asyncPreload = 25,
				columnSize = 5,
				topPadding = 10,
				leftPadding = 10,
				itemAction = {isAction = true, alwaysShow = true},
				onCell = function(list, node, k, v)
					node:get("imgSel"):visible(v.isSel)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {key = v.csvId, num = v.num, dbId = v.dbId[1]},
							noListener = true,
							specialKey = {
								lv = v.lv,
							},
							onNode = function(panel)
								local t = list:getIdx(k)
								bind.click(list, panel, {method = functools.partial(list.clickCell, t, v)})
							end,
						}
					})
					local dbid = v.dbId[1]
					local heldItem = gGameModel.held_items:find(dbid)
					local heldItemData = heldItem and heldItem:read("exist_flag", "card_db_id")
					if heldItemData and heldItemData.card_db_id then
						bind.extend(list, node:get("redHint"), {
							class = "red_hint",
							props = {
								listenData = {
									curDbId = idler.new(dbid)
								},
								specialTag = {
									-- "heldItemLevelUpOrAdvance",
									"heldItemLevelUp",
									"heldItemAdvanceUp",
								},
							}
						})
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["right.item"] = "rightItem",
	["right.textName"] = {
		varname = "heldItemName",
		binds = {
			event = "text",
			idler = bindHelper.self("itemName"),
		},
	},
	["right.textLv"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("itemLv"),
		},
	},
	["right.roleInfo"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("hasRoleDress")
		},
	},
	["right.roleInfo.roleItem"] = "roleInfoItem",
	["attrInnerList"] = "attrInnerList",
	["item1"] = "item1",
	["right.list"] = {
		varname = "rightlist",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrs"),
				item = bindHelper.self("attrInnerList"),
				cell = bindHelper.self("item1"),
				columnSize = 2,
				onCell = function(list, node, k, v)
					local attr = game.ATTRDEF_TABLE[v.attr]
					local attrName = gLanguageCsv["attr" .. string.caption(attr)]
					local path = ui.ATTR_LOGO[attr]
					node:get("imgIcon"):texture(path)
					node:get("textAttrName"):text(attrName)
					node:get("textAttrNum"):text("+" .. v.val)
					adapt.oneLinePos(node:get("textAttrName"), node:get("textAttrNum"), cc.p(10, 0), "left")
				end,
			},
		},
	},
	["right.center"] = "rightCenter",
	["right.center.list"] = "rightCenterList",
	["right.center.btnInfo"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onInfoClick")},
		},
	},
	["roleItem"] = "roleItem",
	["right.down.list"] = {
		varname = "downlist",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("hasShowCards")
			},
			{
				event = "extend",
				class = "listview",
				props = {
					data = bindHelper.self("tabCards"),
					item = bindHelper.self("roleItem"),
					itemAction = {isAction = true, alwaysShow = true},
					onItem = function(list, node, k, v)
						bind.extend(list, node, {
							class = "card_icon",
							props = {
								rarity = v.rarity,
								cardId = v.card.id,
								onNode = function(panel)
									panel:scale(0.9)
								end,
							}
						})
					end,
				},
			},
		},
	},
	["right.down"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("hasShowCards")

		},
	},
	["right.btnStrengthen"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onStrengthenClick")},
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("curItemOnCard"),
					listenData = {
						curDbId = bindHelper.self("curSelDbId"),
					},
					specialTag = {
						-- "heldItemLevelUpOrAdvance",
						"heldItemLevelUp",
						"heldItemAdvanceUp",
					}
					-- onNode = function (node)
					-- 	node:xy(144, 140)
					-- end
				}
			},
		},
	},
	["right.btnDress"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDressClick")},
		},
	},
	["right.btnDress.textNote"] = {
		binds = {
			{
				event = "text",
				idler = bindHelper.self("btnText"),
			},
			{
				event = "effect",
				data = {glow = {color=ui.COLORS.GLOW.WHITE}},
			},
		},
	},
}

function HeldItemBagView:onCreate(cardDbId, handlers)
	self:initModel()
	Dialog.onCreate(self)
	dataEasy.getListenUnlock(gUnlockCsv.propHandbook, function(isUnlock)
		self.handbook:visible(isUnlock)
	end)
	self.cardDbId = cardDbId or self.cards:read()[1]
	self.handlers = handlers
	adapt.oneLinePos(self.textNote1, self.textNote2)
	self.isVisibleRight = idler.new(false)
	self.curSelDbId = idler.new()
	self.curItemOnCard = idler.new(true)
	self.heldItems = idlers.newWithMap({})
	self.hasItem = idler.new(false)
	self.leftSortData = idlertable.new({
		gLanguageCsv.spaceAll,
		gLanguageCsv.aleardyDress,
		gLanguageCsv.notDress,
	})
	self.isLeftDownListShow = idler.new(false)
	self.showLeftSelected = idler.new(1)

	self.rightSortData = idlertable.new({
		gLanguageCsv.spaceQuality,
		gLanguageCsv.strengthenLv,
		gLanguageCsv.breachLv,
	})
	self.isRightDownListShow = idler.new(false)
	self.showRightSelected = idler.new(1)

	self.itemName = idler.new("")
	self.itemLv = idler.new("")
	-- 1:装备 2:卸下
	self.curBtnState = idler.new(1)
	self.attrs = idlers.newWithMap({})
	self.tabCards = idlers.newWithMap({})
	self.hasShowCards = idler.new(false)
	self.btnText = idler.new(gLanguageCsv.spaceEquip)
	self.hasRoleDress = idler.new(false)

	idlereasy.when(self.curSelDbId, function(_, curSelDbId)
		if not curSelDbId then
			self.curItemOnCard:set(false)
		end

		if type(curSelDbId) == "table" then
			curSelDbId = curSelDbId[1]
		end

		local heldItem = gGameModel.held_items:find(curSelDbId)
		local heldItemData = heldItem and heldItem:read("exist_flag", "card_db_id")
		if heldItemData and heldItemData.card_db_id then
			self.curItemOnCard:set(true)
		else
			self.curItemOnCard:set(false)
		end
	end)

	idlereasy.when(self.isVisibleRight, function(_, isVisibleRight, xxx)
		local centerPos = display.sizeInView.width / 2
		local width = self.left:size().width
		local x = isVisibleRight and centerPos - width / 2 - 17 or centerPos
		self.left:x(x)
	end)

	idlereasy.any({self.showLeftSelected, self.showRightSelected, self.refreshFlag}, function(_, left, right, refreshFlag)
		self:refreshData()
		local t = {}
		local count = 0
		for i,v in ipairs(self.tableDatas) do
			if left == 2 and v.cardDbID then
				count = count + 1
				table.insert(t, clone(v))
			elseif left == 3 and not v.cardDbID then
				count = count + 1
				table.insert(t, clone(v))
			elseif left == 1 then
				count = count + 1
				table.insert(t, clone(v))
			end
		end

		table.sort(t, function(a, b)
			if right == 1 then
				return dataEasy.sortHelditemCmp(a, b)

			elseif right == 2 then
				if a.lv ~= b.lv then
					return a.lv > b.lv
				end
				return dataEasy.sortHelditemCmp(a, b)

			elseif right == 3 then
				if a.advance ~= b.advance then
					return a.advance > b.advance
				end
				return dataEasy.sortHelditemCmp(a, b)
			end
		end)
		local card = gGameModel.cards:find(self.cardDbId)
		local heldItemId = self.curDbId or card:read("held_item")
		local targetIdx
		if heldItemId then
			for i,v in ipairs(t) do
				if v.dbId[1] == heldItemId then
					targetIdx = i
					break
				end
			end
		end
		local val = targetIdx or 1
		if val > count then
			val = 1
		end
		local isSel = self.selIdx:read() ~= -1 and t[val] or false
		if isSel then
			t[val].isSel = true
		end
		self.selIdx:set(val)
		self.heldItems:update(t)
		self.hasItem:set(count <= 0)
		self.selIdx:notify()
		self.isVisibleRight:set(isSel ~= false)
		self.curDbId = nil
	end)

	self.selIdx:addListener(function(idx, oldval)
		local size = self.heldItems:size()
		if size <= 0 then
			self.isVisibleRight:set(false)
			return
		end
		if oldval ~= -1 and idx ~= oldval then
			if self.heldItems:atproxy(oldval) and self.heldItems:atproxy(oldval).isSel ~= false then
				self.heldItems:atproxy(oldval).isSel = false
			end
		end
		if not self.heldItems:atproxy(idx) then
			self.curSelDbId:set(nil)
			return
		end
		if idx ~= oldval and self.heldItems:atproxy(idx).isSel ~= true then
			self.heldItems:atproxy(idx).isSel = true
		end
		self.curSelDbId:set(self.heldItems:atproxy(idx).dbId)
		local csvTab = csv.held_item.items
		local effectTab = csv.held_item.effect
		local info = self.heldItems:atproxy(idx)
		local heldItemInfo = csvTab[info.csvId]
		local dressDbId = info.cardDbID
		local state = 1
		local str = gLanguageCsv.spaceEquip
		local hasRoleDress, isExc = HeldItemTools.isExclusive(info)
		-- 穿戴的卡牌形象
		if dressDbId then
			if dressDbId == self.cardDbId then
				state = 2
				str = gLanguageCsv.dressDown
			end
			local card = gGameModel.cards:find(dressDbId):read("card_id", "skin_id", "advance", "level", "star")
			local cardCfg = csv.cards[card.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			local unitId = dataEasy.getUnitId(card.card_id, card.skin_id)
			bind.extend(self, self.roleInfoItem, {
				class = "card_icon",
				props = {
					levelProps = {
						data = card.level,
					},
					rarity = unitCfg.rarity,
					unitId = unitId,
					advance = card.advance,
					star = card.star,
					onNode = function(node)

					end
				}
			})
		end
		self.hasRoleDress:set(hasRoleDress)
		self.curBtnState:set(state)
		self.btnText:set(str)
		local nameStr = info.cfg.name
		if info.advance > 0 then
			nameStr = string.format("%s +%d", info.cfg.name, info.advance)
		end
		self.itemName:set(nameStr)
		text.addEffect(self.heldItemName, {color= info.cfg.quality == 1 and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.QUALITY[info.cfg.quality]})
		self.itemLv:set("Lv." .. info.lv)
		-- 左上角item
		bind.extend(self, self.rightItem, {
			class = "icon_key",
			props = {
				data = {
					key = info.csvId,
					num = info.num,
					dbId = info.dbId[1],
				},
				noListener = true,
			}
		})
		-- 英雄显示
		-- 默认用第一个效果id索引
		local effectInfo = effectTab[heldItemInfo.effect1]
		--专属精灵属性判断
		if heldItemInfo and itertools.size(heldItemInfo.exclusiveCards) > 0 then
			effectInfo = effectTab[heldItemInfo.effect2]
		end
		local cards = {}
		for k,v in csvMapPairs(effectInfo.exclusiveCards) do
			for _, data in pairs(gCardsCsv[v]) do
				for _, card in pairs(data) do
					local unitCfg = csv.unit[card.unitID]
					table.insert(cards, {card = card, rarity = unitCfg.rarity})
				end
			end
		end
		self.tabCards:update(cards)
		local hasDownList = #cards > 0
		self.hasShowCards:set(itertools.size(effectInfo.exclusiveCards) > 0)
		-- 属性显示
		local attrTypes = info.cfg.attrTypes
		local attrNumRates = info.cfg.attrNumRates
		local advanceAttrTab = csv.held_item.advance_attrs[info.advance]
		local advAttrNum = advanceAttrTab["attrNum" .. info.cfg.advanceAttrSeq]
		local advAttrRate = advanceAttrTab["attrRate" .. info.cfg.advanceAttrSeq]
		local lvAttrNum = csv.held_item.level_attrs[info.lv]["attrNum" .. info.cfg.strengthAttrSeq]
		local t = {}
		for i,v in ipairs(attrTypes) do
			local data = {}
			data.attr = v
			data.val = math.floor(attrNumRates[i] * advAttrRate[i] * (lvAttrNum[i] + advAttrNum[i]))
			table.insert(t, data)
		end
		self.attrs:update(t)
		-- 属性加成显示
		if gGameModel.held_items:find(info.dbId[1]) then
			local strTab = {}
			for i=1,100 do
				local effectVal = info.cfg[string.format("effect%dLevelAdvSeq", i)]
				local curAdv = gGameModel.held_items:find(info.dbId[1]):read("advance")
				-- 没有配置  或者没有达到开放的advance等级 就不显示
				if not info.cfg["effect" .. i] or info.cfg["effect" .. i] == 0 or not effectVal or curAdv < effectVal[1] then
					break
				end
				local resultStr = HeldItemTools.getStrinigByData(i, info)
				table.insert(strTab, resultStr)
			end
			local targetStr = "#C0x5B545B#"..table.concat(strTab, '\n')
			local list = beauty.textScroll({
				list = self.rightCenterList,
				strs = targetStr,
				isRich = true,
				fontSize = 40,
			})

			self:setRightCenterListSize()
		end
	end)
end

function HeldItemBagView:initModel()
	self.myHeldItem = gGameModel.role:getIdler("held_items")
	self.cards = gGameModel.role:getIdler("cards")
	self.refreshFlag = idler.new(false)
	self.selIdx = idler.new(1)
end

function HeldItemBagView:setRightCenterListSize()
	local sign = self.hasShowCards:read()
	local containSize = self.rightCenterList:getInnerContainerSize()
	local size = self.rightCenterList:size()
	containSize.height = containSize.height > LIST_WIDTH and LIST_WIDTH or containSize.height
	if not sign then
		self.rightCenterList:size(containSize)
		self.rightCenterList:y(self.rightCenterList:y() - (containSize.height - size.height))
	end
end

function HeldItemBagView:refreshData()
	self.tableDatas = {}
	self.dataIdx = {}
	local t = {}
	local datas = {}
	local count = 0
	local csvTab = csv.held_item.items
	for _,dbId in pairs(self.myHeldItem:read()) do
		local dbData = gGameModel.held_items:find(dbId)
		-- assertInWindows(dbData, "helditem dbId(%s) in model.role, not in model.held_items", stringz.bintohex(dbId))
		if dbData then
			local heldItemData = dbData:read("exist_flag", "card_db_id", "advance", "level", "sum_exp", "held_item_id")
			if heldItemData.exist_flag then
				local cfg = csvTab[heldItemData.held_item_id]
				if heldItemData.sum_exp == 0 and heldItemData.advance == 0 and not heldItemData.card_db_id then
					if not t[heldItemData.held_item_id] then
						t[heldItemData.held_item_id] = {num = 0, maxNum = cfg.stackShow, dbIds = {}}
					end
					t[heldItemData.held_item_id].num = t[heldItemData.held_item_id].num + 1
					table.insert(t[heldItemData.held_item_id].dbIds, dbId)
				else
					count = count + 1
					local data = {}
					data.cfg = cfg
					data.csvId = heldItemData.held_item_id
					data.dbId = {dbId}
					data.num = 1
					data.isSel = false
					data.lv = heldItemData.level
					data.cardDbID = heldItemData.card_db_id
					data.advance = heldItemData.advance
					local isDress, isExc = HeldItemTools.isExclusive(data)
					data.isDress = isDress
					data.isExc = isExc
					table.insert(datas, data)
					self.dataIdx[dbId] = count
				end
			end
		end
	end
	-- 堆叠部分处理
	for k,v in pairs(t) do
		local allNum = v.num
		local maxNum = v.maxNum
		-- 计算需要多少个cell
		for i=1,math.ceil(allNum / maxNum) do
			count = count + 1
			local data = {}
			data.cfg = csvTab[k]
			data.csvId = k
			local curShowNum = math.min(maxNum, allNum)
			data.num = curShowNum
			local ids = {}
			for i=1,curShowNum do
				table.insert(ids, v.dbIds[i])
			end
			data.dbId = ids
			data.isSel = false
			data.lv = 1
			data.advance = 0
			local _, isExc = HeldItemTools.isExclusive(data)
			data.isDress = false
			data.isExc = isExc
			table.insert(datas, data)
			allNum = allNum - maxNum
			self.dataIdx[k] = count
		end
	end
	self.tableDatas = datas
end

function HeldItemBagView:onDressClick()
	-- self.isVisibleRight:set(false)
	-- 1:装备 2:卸下
	local state = self.curBtnState:read()
	local curSelIdx = self.selIdx:read()
	local heldItemData = self.heldItems:atproxy(curSelIdx)
	if state == EQUIPSTATE.dress then
		-- 是否是换一个英雄穿戴
		local isChange = false
		local dressDbId = heldItemData.cardDbID
		local function dress()
			local paramDbId = heldItemData.dbId[1]
			gGameApp:requestServer("/game/helditem/equip", function()
				self.selIdx:set(-1)
				self.refreshFlag:notify()
				-- self.isVisibleRight:set(false)
				if self.handlers then
					self.handlers(paramDbId)
				end
				audio.playEffectWithWeekBGM("equip.mp3")
				gGameUI:showTip(gLanguageCsv.dressSuccess)
			end, self.cardDbId, paramDbId)
		end


		if dressDbId then
			isChange = true
			local card = gGameModel.cards:find(dressDbId)
			local cardId = card:read("card_id")
			local name = csv.cards[cardId].name
			local sIdx, eIdx = string.find(gLanguageCsv.heldItemReDress, "%%s")
			local colorStr, numStr = HeldItemTools.getCardNameColor(dressDbId)
			local str1 = HeldItemTools.insertColor(gLanguageCsv.heldItemReDress, colorStr, false, 1, false)
			str1 = "#C0x5B545B#" .. str1
			name = name .. numStr
			local targetStr = string.format(str1, name)
			local params = {
				cb = dress,
				isRich = true,
				btnType = 2,
				content = targetStr,
			}
			gGameUI:showDialog(params)
		else
			dress()
		end

	elseif state == EQUIPSTATE.down then
		gGameApp:requestServer("/game/helditem/unload", function()
			self.selIdx:set(-1)
			self.refreshFlag:notify()
			-- self.isVisibleRight:set(false)
			if self.handlers then
				self.handlers()
			end
			gGameUI:showTip(gLanguageCsv.dressDownSuccess)
		end, heldItemData.dbId[1])
	end
end

function HeldItemBagView:callBackData(curDbId)
	self.curDbId = curDbId
	self.refreshFlag:notify()
end

function HeldItemBagView:onStrengthenClick()
	gGameUI:stackUI("city.card.helditem.advance", {refreshData = self:createHandler("callBackData")}, {full = true}, self.heldItems:atproxy(self.selIdx:read()).dbId)
end

function HeldItemBagView:onSortLeftMenusBtnClick(ode, layout, idx, val)
	self.showLeftSelected:set(idx)
end

function HeldItemBagView:onCloseLeftOtherView(node, btn)
	self.isRightDownListShow:set(false)
end

function HeldItemBagView:onSortRightMenusBtnClick(ode, layout, idx, val)
	self.showRightSelected:set(idx)
end

function HeldItemBagView:onCloseRightOtherView(node, btn)
	self.isLeftDownListShow:set(false)
end

function HeldItemBagView:onInfoClick(node, event)
	local data = self.heldItems:atproxy(self.selIdx:read())
	local x, y = node:getPosition()
	local pos = node:getParent():convertToWorldSpace(cc.p(x, y))
	local params = {data = data, target = node, x = pos.x, y = pos.y, offx = 256, offy = 120}
	gGameUI:stackUI("city.card.helditem.advance_detail", nil, nil, params)
end

function HeldItemBagView:onItemClick(list, t, v)
	self.selIdx:set(t.k, true)
	if self.heldItems:atproxy(t.k) and self.heldItems:atproxy(t.k).isSel ~= true then
		self.heldItems:atproxy(t.k).isSel = true
	end
	self.isVisibleRight:set(true)
end

--道具手册
function HeldItemBagView:bagHandbook()
	gGameUI:stackUI("city.card.helditem.bag_handbook", nil, nil, self.cardDbId)
end

function HeldItemBagView:onClose()
	local heldItemDbId = gGameModel.cards:find(self.cardDbId):read("held_item")
	if self.handlers then
		self.handlers(heldItemDbId)
	end
	Dialog.onClose(self)
end

return HeldItemBagView