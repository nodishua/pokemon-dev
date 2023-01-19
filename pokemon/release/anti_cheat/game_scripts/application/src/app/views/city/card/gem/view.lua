-- @desc 符石镶嵌主界面

local insert = table.insert
local sort = table.sort
local PAGEBTN_TEXTURES = {
	NORMAL = 'city/card/gem/btn_yq_b.png',
	SELECTED = 'city/card/gem/btn_yq_h.png'
}

local SUITEFFECT = {
	[2] = 'effect_lv',
	[3] = 'effect_lan',
	[4] = 'effect_zi',
	[5] = 'effect_huang',
	[6] = 'effect_hong'
}

local SUITEFFECT_LOOP = {
	[2] = 'effect_lv_loop',
	[3] = 'effect_lan_loop',
	[4] = 'effect_zi_loop',
	[5] = 'effect_huang_loop',
	[6] = 'effect_hong_loop'
}

local ViewBase = cc.load('mvc').ViewBase
local GemTools = require('app.views.city.card.gem.tools')
local GemView = class('GemView', ViewBase)
GemView.RESOURCE_FILENAME = 'gem.json'
GemView.RESOURCE_BINDING = {
	['right.subList'] = 'subList',
	['right.item'] = 'item',
	['right.list'] = {
		varname = 'list',
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				asyncPreload = bindHelper.self('asyncPreload'),
				data = bindHelper.self('showData'),
				columnSize = bindHelper.self('midColumnSize'),
				item = bindHelper.self('subList'),
				cell = bindHelper.self('item'),
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = 'icon_key',
						props = {
							noListener = true,
							data = {
								key = v.id,
								num = v.num,
								dbId = v.dbid
							},
							specialKey = {
								leftTopLv = v.level
							},
							onNode = function(node)
								if v.selectEffect then
									v.selectEffect:removeSelf()
									v.selectEffect:alignCenter(node:size())
									node:add(v.selectEffect, -1)
								end
								node:scale(1.15)
								node:onTouch(functools.partial(list.itemClick, list, node, k, v))
							end
						},
					})
				end
			},
			handlers = {
				itemClick = bindHelper.self('onItemClick')
			}
		}
	},
	['right.pageBtn'] = 'pageBtn',
	['right.pageList'] = {
		varname = 'pageList',
		binds = {
			event = 'extend',
			class = 'listview',
			props = {
				margin = bindHelper.self('pageBtnSpace'),
				data = bindHelper.self('pageBtns'),
				item = bindHelper.self('pageBtn'),
				onItem = function(list, node, k, v)
					local res = v.select and PAGEBTN_TEXTURES.SELECTED or PAGEBTN_TEXTURES.NORMAL
					node:get('bg'):texture(res)
					local color = v.select and ui.COLORS.WHITE or ui.COLORS.RED
					node:get('title'):setTextColor(color)
					node:get('title'):setString(gLanguageCsv['symbolRome'..k])
					node:get('bg'):setTouchEnabled(true)
					bind.touch(list, node:get('bg'), {methods = {ended = functools.partial(list.clickCell, k)}})
				end
			},
			handlers = {
				clickCell = bindHelper.self('pageBtnClick')
			}
		}
	},
	['left.card'] = {
		varname = "card",
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onShowSelectSpriteView')}
		}
	},
	['left.btnExchange'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self("onShowSelectSpriteView")}
		}
	},
	['left'] = 'left',
	['right'] = 'right',
	['left.btnDraw'] = {
		binds = {
			{
				event = 'touch',
				methods = {ended = bindHelper.self('onClickDraw')}
			},{
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("gemFreeNumer"),
					onNode = function(node)
						node:xy(150, 150)
					end,
				},
			},
		}
	},
	['left.btnShowAll'] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self('btnShowAllFunc')}
		}
	},
	['left.btnPoint'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onClickIndex')}
		}
	},
	['left.btnPoint.pointNum'] = {
		binds = {
			event = 'text',
			idler = bindHelper.self('qualityNum')
		}
	},
	['left.btnDecompose'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('btnDecompose')}
		}
	},
	['left.btnOneKeyUnEquip'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('unEquipAll')}
		}
	},
	['left.btnOneKeyUnEquip.txt'] = {
		binds = {
			{
				event = 'effect',
				data = {glow = {color = ui.COLORS.GLOW.WHITE}}
			},
		}
	},
	['left.btnOneKeyEquip'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('oneKeyEquip')}
		}
	},
	['left.btnOneKeyEquip.txt'] = {
		binds = {
			{
				event = 'effect',
				data = {glow = {color = ui.COLORS.GLOW.WHITE}}
			},
		}
	},
	['right.btnFilterPanel'] = 'btnFilterPanel',
	['right.btnFilterPanel.btnFilter'] = {
		varname = 'btnFilter',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onFilter')}
		}
	},
	['right.btnFilterPanel.btnFilter.arrow'] = 'filterArrow',
	['right.btnFilterPanel.btnFilter.txt'] = {
		varname = 'filterTxt',
		binds = {
			{
				event = 'effect',
				data = {glow = {color = ui.COLORS.GLOW.WHITE}}
			}
		}
	},
	['right.noGemTip'] = 'noGemTip',
	['right.acquire.num'] = 'acquireNum',
	['right.acquire.bg'] = 'acquireBg',
	['right.acquire.btnAdd'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('btnDecompose')}
		}
	},
	['left.bg2'] = 'centerBg'
}
GemView.RESOURCE_STYLES = {
	full = true,
}

function GemView:onCreate(curCardId)
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.gemTitle, subTitle = "GEM"})
	self.selectEffect = ccui.ImageView:create("common/box/box_selected.png")
		:alignCenter(self.item:size())
		:retain()

	self.baglevelIdlers = {}
	self:initModel()

	local deltaWidth, count = adapt.centerWithScreen("left", "right", {
		itemWidth = self.item:size().width,
		itemWidthExtra = 80,
	},{
		{{self.bagSubList, self.bagList}, "width"},
		{{self.subList, self.list, self.pageList}, "width"},
		{{self.subList, self.list, self.pageList}, "pos", 'left'}
	})

	self.deltaWidth = deltaWidth or 0
	self.midColumnSize = 4 + (count or 0)
	self.asyncPreload = self.midColumnSize * 5
	self.pageBtnSpace = math.floor((self.pageList:width() - 6 * self.pageBtn:width()) / 5)
	self.btnFilterPanel:x(self.list:x() + self.list:width() - self.btnFilterPanel:width() / 2)
	self.right:get('acquire'):x(self.list:x())


	-- 异常，作为反例说明，工程描点非居中，导致适配非通用异常KDYG-6119，使用 display.uiOriginMax 适配
	local pos = cc.p(30 + display.sizeInViewRect.x, 0)
	self.left:runAction(cc.MoveTo:create(0.4, pos))
	self.right:runAction(cc.MoveTo:create(0.4, cc.p(display.uiOrigin.x + 1500, 0)))
	for k, v in ipairs({'btnDraw', 'btnShowAll', 'btnPoint', 'btnDecompose'}) do
		text.addEffect(self.left:get(v):get('txt'), {outline = {color=ui.COLORS.NORMAL.WHITE, size=4}})
	end
	self.pageBtns = idlers.newWithMap({
		{}, {}, {}, {}, {}, {}
	})
	self.selectedPage = idler.new()
	self.selectedPage:addListener(function(val, oldval)
		if oldval then
			self.pageBtns:atproxy(oldval).select =  false
		end
		if val then
			self.pageBtns:atproxy(val).select = true
		end
	end)

	self.gemFreeNumer = idler.new(true)
	idlereasy.any({self.goldFreeCount, self.rmbFreeCount}, function(_, goldCount, rmbCount)
		if goldCount ~= 0 and rmbCount ~= 0 then
			self.gemFreeNumer:set(false)
		end
	end)

	self.selectItem = idlertable.new({})

	self.selectItem:addListener(function(val, oldval)
		if next(val) then
			local data = self.showData:atproxy(val.k)
			data.selectEffect = self.selectEffect
		end
	end)

	local item529 = idler.new(0)
	idlereasy.when(self.items, function(_, items)
		item529:set(items[529] or 0)
	end)
	idlereasy.when(item529, function(_, item529)
		local childs = self.right:get('acquire'):multiget('icon', 'btnAdd', 'bg', 'num')
		childs.num:text(item529)
		local width = childs.num:width()
		width = width / 0.8 + 130
		if width > 296 then
			childs.bg:width(width)
			adapt.oneLinePos(childs.icon, {childs.num, childs.btnAdd})
		end
	end)

	self.filterType = 0
	self.qualityNum = idler.new(0)
	self.showData = idlers.new({})
	idlereasy.when(self.gems, function(_, gems)
		self:updateShowData()
	end)
	self:createGemSlots()

	idlereasy.when(gGameModel.role:getIdler("cards"), function (_, cards)
		local dataDbid = {}
		local rarity = 0
		local cardsId
		local fighting_point = 0
		for i, cardId in ipairs(cards) do
			local card = gGameModel.cards:find(cardId)
			local cardDatas = card:read("card_id", "fighting_point", "level", "star", "advance")
			local cardCsv = csv.cards[cardDatas.card_id]
			local unitCsv = csv.unit[cardCsv.unitID]
			dataDbid[cardId] = true
			if unitCsv.rarity > rarity then
				cardsId = cardId
				rarity = unitCsv.rarity
				fighting_point = cardDatas.fighting_point
			elseif unitCsv.rarity == rarity and cardDatas.fighting_point > fighting_point then
				cardsId = cardId
				fighting_point = cardDatas.fighting_point
			end
		end
		if curCardId and dataDbid[curCardId] then
			self:setCardID(curCardId)
		else
			self:setCardID(cardsId)
		end
	end)
end

function GemView:onTouchSlot(i, event)
	local slot = self.gemSlots[i]
	local gems = self.curCard:read('gems')
	local dbid = gems[i]
	if not GemTools.isSlotLocked(self.carddbid, i) then
		self.curSlot:set(i)
	else
		local cardCfg = csv.cards[gGameModel.cards:find(self.carddbid):read('card_id')]
		local condition = gGemPosCsv[cardCfg.gemPosSeqID][i].openCondition
		if condition[1] == 1 then
			gGameUI:showTip(gLanguageCsv.nLvUnlock, condition[2])
		elseif condition[1] == 2 then
			local quality, space = dataEasy.getQuality(condition[2])
			gGameUI:showTip(gLanguageCsv.openAdvance, gLanguageCsv[ui.QUALITY_COLOR_TEXT[quality]]..space)
		end
	end
	if not dbid then
		return
	end
	local gem = gGameModel.gems:find(dbid)
	if event.name == 'began' then
		self.touchBeganPos = slot:getTouchBeganPosition()

	elseif event.name == 'moved' then
		local pos = event
		local deltaX = math.abs(pos.x - self.touchBeganPos.x)
		local deltaY = math.abs(pos.y - self.touchBeganPos.y)
		if not self.hasMovingItem then
			if deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD then
				slot:get('gemPanel'):visible(false)
				self.hasMovingItem = true
				self:createMovePanel({id = gem:read('gem_id'), level = gem:read('level')})
			end
		end
		if self.hasMovingItem then
			pos = self:convertToNodeSpace(pos)
			self.movePanel:xy(pos.x, pos.y)
		end
	elseif event.name == 'ended' or event.name == 'cancelled' then
		if not self.hasMovingItem then
			self:showDetails()
		else
			self.hasMovingItem = false
			local moveBox = self.movePanel:box()
			local pos = self:convertToWorldSpace(cc.p(moveBox.x, moveBox.y))
			pos = self.left:convertToNodeSpace(pos)
			moveBox.x, moveBox.y = pos.x, pos.y
			local box = slot:box()
			local slotIdx = self:checkRectInSlots(moveBox)
			if slotIdx == i then
				slot:get('gemPanel'):visible(true)
			elseif not slotIdx then
				GemTools.unEquipGem(self.carddbid, i)
			else
				GemTools.moveGem(self.carddbid, slotIdx, dbid, function()
					slot:get('gemPanel'):visible(true)
				end)
			end
			self.movePanel:removeSelf()
			self.movePanel = nil
		end
	end
end

function GemView:checkRectInSlots(moveBox)
	local distancemin = math.huge
	local slotIdx
	-- 用box相交判定，相邻的box容易重复，找出最近的一个
	for k, v in pairs(self.gemSlots) do
		local box = v:box()
		if cc.rectIntersectsRect(box, moveBox) then
			local pos1 = cc.p(box.x + box.width / 2, box.y + box.height / 2)
			local pos2 = cc.p(moveBox.x + moveBox.width / 2, moveBox.y + moveBox.height / 2)
			local distance = cc.pGetDistance(pos1, pos2)
			if distance < distancemin then
				distancemin = distance
				slotIdx = k
			end
		end
	end
	return slotIdx
end

function GemView:createGemSlots()
	self.suitEffectQualitys = {}
	self.gemSlots = {}
	self.curSlot = idler.new(1)
	local centerPos = cc.p(772, 704)
	local pos0 = cc.p(772, 1100)
	widget.addAnimationByKey(self.left, 'fushichouqu/baoshixiangqian.skel', "bg", "effect_shiban_loop", 5)
		:xy(centerPos)
	local dx = pos0.x - centerPos.x
	local dy = pos0.y - centerPos.y
	for i = 1, 9 do
		self.suitEffectQualitys[i] = 0
		local rotation = (i - 0.5) / 9 * 360 + 180
		local r = - math.rad(rotation)
		local x = centerPos.x + dx * math.cos(r) + dy * math.sin(r)
		local y = centerPos.y + dx * math.sin(r) - dy * math.cos(r)
		self.gemSlots[i] = self.left:get('gemSlot'):clone()
			:addTo(self.left, 30)
			:xy(x, y)
		widget.addAnimationByKey(self.gemSlots[i], 'fushichouqu/baoshixiangqian.skel', "empty", 'effect_kong_loop', 1)
			:alignCenter(self.gemSlots[i]:size())
			:setRotation(rotation + 180)
		self.gemSlots[i]:get('bg'):visible(false)
		self.gemSlots[i]:onTouch(function(event)
			self:onTouchSlot(i, event)
		end)
	end
	self.slotEffect = ccui.ImageView:create("common/box/box_portrait_select.png")
		:alignCenter(self.item:size())
		:retain()
	idlereasy.when(self.curSlot, function(_, slotIdx)
		local slot = self.gemSlots[slotIdx]
		self.slotEffect:removeSelf()
		self.slotEffect:alignCenter(slot:size())
		slot:add(self.slotEffect, 5)
	end)
end

function GemView:updateShowData()
	self.selectItem:set({})
	dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndexAdaptFirst")
	local data = {}
	local level1gems = {}

	local gems = gGameModel.role:read('gems')
	for i, dbid in pairs(gems) do
		local gem = gGameModel.gems:find(dbid)
		local gem_id = gem:read('gem_id')
		local level = gem:read('level')
		local cfg = dataEasy.getCfgByKey(gem_id)
		local gemData = {
			id = gem_id,
			num = 1,
			suitNo = cfg.suitNo,
			suitID = cfg.suitID,
			level = level,
			quality = cfg.quality,
			dbid = dbid
		}
		local belongCarddbid = gem:read('card_db_id')
		local selectSuitNo = self.selectedPage:read()
		if not belongCarddbid
			and (not selectSuitNo or (selectSuitNo == gemData.suitNo) or not gemData.suitNo)
			and (self.filterType == 0 or self.filterType == gemData.suitID or not gemData.suitID) then
			if level == 1 then
				if not level1gems[gem_id] then
					gemData.dbids = {dbid}
					level1gems[gem_id] = gemData
					insert(data, gemData)
				else
					insert(level1gems[gem_id].dbids, dbid)
					level1gems[gem_id].num = level1gems[gem_id].num + 1
				end
			else
				insert(data, gemData)
			end
		end
	end
	sort(data, function(a, b)
		if a.quality ~= b.quality then
			return a.quality > b.quality
		end
		if a.suitID ~= b.suitID then
			if a.suitID and b.suitID then
				return a.suitID < b.suitID
			else
				return not b.suitID
			end
		end
		if a.suitNo ~= b.suitNo then
			if a.suitNo and b.suitNo then
				return a.suitNo < b.suitNo
			else
				return not b.suitNo
			end
		end
		return a.level > b.level
	end)
	local listener = function(k, dbid, isTable)
		self.baglevelIdlers[dbid] = idlereasy.when(gGameModel.gems:find(dbid):getIdler('level'), function(_, level)
			if isTable then
				self:updateShowData()
			else
				local data = self.showData:atproxy(k)
				if data then
					data.level = level
				end
			end
		end, true):anonyOnly(self, stringz.bintohex(dbid))
	end
	for k, v in ipairs(data) do
		if v.dbids then
			for _, dbid in ipairs(v.dbids) do
				listener(k, dbid, true)
			end
		else
			listener(k, v.dbid)
		end
	end
	self.showData:update(data)
	self.noGemTip:visible(#data == 0)
end

function GemView:pageBtnClick(list, k)
	local old = self.selectedPage:read()
	if old == k then
		k = nil
	end
	self.selectedPage:set(k)
	self:updateShowData()
end

function GemView:getPercent()
	local container = self.list:getInnerContainer()
	local innerSize = container:size()
	local listSize = self.list:size()
	local x, y = container:xy()
	return 100 - math.abs(y) / (innerSize.height - listSize.height) * 100
end

function GemView:onItemClick(list, node, panel, k, v, event)
	if event.name == 'began' then
		self.touchBeganPos = panel:getTouchBeganPosition()
		self.list:setTouchEnabled(false)
		self.isClicked = true
		self.hasMovingItem = nil
	elseif event.name == 'moved' then
		local pos = event
		local deltaX = math.abs(pos.x - self.touchBeganPos.x)
		local deltaY = math.abs(pos.y - self.touchBeganPos.y)
		if self.hasMovingItem == nil then
			if deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD then
				self.hasMovingItem = false
				if deltaX > deltaY * 0.7 then
					self.hasMovingItem = true
					self:createMovePanel(v)
				end
				self.list:setTouchEnabled(not self.hasMovingItem)
				self.isClicked = false
			end
		end
		if self.hasMovingItem then
			pos = self:convertToNodeSpace(pos)
			self.movePanel:xy(pos.x, pos.y)
		end

	elseif event.name == 'ended' or event.name == 'cancelled' then
		if not self.hasMovingItem then
			if self.isClicked then
				local t = list:getIdx(k)
				t.data = v
				self.selectItem:set(t)
				self:showDetails(v.dbid)
			end
		else
			self.hasMovingItem = false
			local moveBox = self.movePanel:box()
			local pos = self:convertToWorldSpace(cc.p(moveBox.x, moveBox.y))
			pos = self.left:convertToNodeSpace(pos)
			moveBox.x, moveBox.y = pos.x, pos.y
			local slotIdx = self:checkRectInSlots(moveBox)
			if slotIdx then
				local oldgemid = self.curCard:read('gems')[slotIdx]
				if oldgemid then
					self:swapGem(slotIdx, self.movePanel.dbid)
				else
					self:equipGem(slotIdx, self.movePanel.dbid)
				end
				self.curSlot:set(slotIdx)
			end
			self.movePanel:removeSelf()
			self.movePanel = nil
		end
	end
end

function GemView:swapGem(slot, new)
	GemTools.swapGem(self.carddbid, slot, new)
end

function GemView:equipGem(slot, dbid)
	GemTools.equipGem(self.carddbid, slot, dbid, function()
		local gemSlot = self.gemSlots[slot]
		if gemSlot:get('effectEquip') then
			gemSlot:get('effectEquip'):removeSelf()
		end
		local rotation = (slot - 0.5) / 9 * 360
		local ani = widget.addAnimationByKey(gemSlot, 'fushichouqu/baoshixiangqian.skel', "effectEquip", "effect_jihuo", 5)
			:alignCenter(gemSlot:size())
			:setRotation(rotation)
		performWithDelay(ani, function()
			ani:removeSelf()
		end, 0.5)
	end)
end

function GemView:createMovePanel(v)
	if self.movePanel then
		self.movePanel:removeSelf()
		self.movePanel = nil
	end
	self.movePanel = self.item:clone():addTo(self, 100)
	self.movePanel.dbid = v.dbid
	self.moveData = v
	bind.extend(self, self.movePanel, {
		class = 'icon_key',
		props = {
			simpleShow = true,
			data = {
				key = v.id
			},
			specialKey = {
				leftTopLv = v.level
			},
			onNode = function(panel)
				panel:scale(1.15)
			end
		}
	})
end

function GemView:onShowSelectSpriteView()
	gGameUI:stackUI('city.card.gem.select_sprite', nil, nil, self.carddbid, self:createHandler('setCardID'))
end

function GemView:setCardID(dbid)
	if not dbid then return end
	local card = gGameModel.cards:find(dbid)
	local cardDatas = card:read("card_id","skin_id", "fighting_point", "level", "star", "advance")
	local cardCsv = csv.cards[cardDatas.card_id]
	local unitCsv = csv.unit[cardCsv.unitID]
	local unitId = dataEasy.getUnitId(cardDatas.card_id, cardDatas.skin_id)

	bind.extend(self, self.card, {
		class = "card_icon",
		props = {
			unitId = unitId,
			advance = cardDatas.advance,
			rarity = unitCsv.rarity,
			star = cardDatas.star,
			levelProps = {
				data = cardDatas.level,
			},
			onNode = function(panel)
			end,
		}
	})
	self.carddbid = dbid
	self.curCard = card
	idlereasy.when(card:getIdler('gems'), function(_, gems)
		self:updateShowData()
		self:resetGemSlots(gems)
	end):anonyOnly(self, 'cardgems')
end

function GemView:checkSuits(gems)
	local map = {}
	for i = 1, 9 do
		local gemdbid = gems[i]
		if gemdbid then
			local gem = gGameModel.gems:find(gemdbid)
			local cfg = csv.gem.gem[gem:read('gem_id')]
			if cfg.suitID then
				if not map[cfg.suitID] then
					map[cfg.suitID] = {}
				end
				insert(map[cfg.suitID], {slot = i, quality = cfg.quality})
			end
		end
	end
	local suitQualitys = {}
	for suitID, tbl in pairs(map) do
		sort(tbl, function(a, b)
			if a.quality ~= b.quality then
				return a.quality > b.quality
			end
			return a.slot < b.slot
		end)
		local _, cfg = next(gGemSuitCsv[suitID])
		for suitNum = 9, 1, -1 do
			if cfg[suitNum] and #tbl >= suitNum then
				for i = 1, suitNum do
					suitQualitys[tbl[i].slot] = tbl[suitNum].quality
				end
			end
		end
	end
	return suitQualitys
end

function GemView:resetGemSlots(gems)
	-- 套装特效todo
	local suitQualitys =  self:checkSuits(gems)
	for i, slot in pairs(self.gemSlots) do
		if not suitQualitys[i] or self.suitEffectQualitys[i] ~= suitQualitys[i] then
			if slot:get('effect') then
				slot:get('effect'):removeSelf()
			end
		end
		if self.suitEffectQualitys[i] ~= suitQualitys[i] and suitQualitys[i] then
			local rotation = (i - 0.5) / 9 * 360
			local ani = widget.addAnimationByKey(slot, 'fushichouqu/baoshixiangqian.skel', "effect", SUITEFFECT[suitQualitys[i]], 1)
				:alignCenter(slot:size())
			performWithDelay(ani, function()
				ani:removeSelf()
				widget.addAnimationByKey(slot, 'fushichouqu/baoshixiangqian.skel', "effect", SUITEFFECT_LOOP[suitQualitys[i]], 1)
					:alignCenter(slot:size())
					:setRotation(rotation)
			end, 0.5)
			ani:setRotation(rotation)
		end
		self.suitEffectQualitys[i] = suitQualitys[i]
		local iconPanel = slot:get('gemPanel')
		local icon = iconPanel:get('icon')
		local lvBg = iconPanel:get('levelBg')
		local unlockLv = slot:get('unlockLv')
		local unlockLvBg = slot:get('unlockLvBg')
		local advance = self.curCard:read('advance')
		local isLocked, lockedStr = GemTools.isSlotLocked(self.carddbid, i)
		local hasGem = gems[i] and true or false
		iconPanel:visible(hasGem)
		lvBg:visible(false)
		local txt = iconPanel:get('lv')
		text.addEffect(txt, {outline={color=ui.COLORS.NORMAL.DEFAULT}})
		if hasGem then
			local gem = gGameModel.gems:find(gems[i])
			local gem_id = gem:read('gem_id')
			local cfg = dataEasy.getCfgByKey(gem_id)
			icon:texture(cfg.icon)
			icon:visible(true)
			if self.baglevelIdlers[gems[i]] then
				self.baglevelIdlers[gems[i]]:destroy()
				self.baglevelIdlers[gems[i]] = nil
			end
			idlereasy.when(gem:getIdler('level'), function(_, level)
				txt:setString('Lv'..level)
				-- iconPanel:get('levelBg'):width(txt:size().width + 20)
				self:updateIndexPoints()
			end):anonyOnly(self, 'gemSlot'..i)
		else
			icon:texture('city/card/gem/btn_jh2.png')
		end
		unlockLv:visible(isLocked)
		if isLocked then
			unlockLv:text(lockedStr)
		end
		unlockLvBg:visible(isLocked)
		slot:get('lock'):visible(isLocked)
		slot:get('imgAdd'):visible(not hasGem and not isLocked)
	end
	self:updateIndexPoints()
end

function GemView:updateIndexPoints()
	local card = gGameModel.cards:find(self.carddbid)
	local qualityNum = dataEasy.getGemQualityIndex(card)
	self.qualityNum:set(qualityNum)
end

function GemView:unEquipAll()
	local gems = self.curCard:read('gems')
	local gemids = {}
	for i, id in pairs(gems) do
		if id then
			insert(gemids, id)
		end
	end
	if #gemids == 0 then
		gGameUI:showTip(gLanguageCsv.noEquippedGem)
		return
	end
	gGameApp:requestServer('/game/gem/unload', function()
		gGameUI:showTip(gLanguageCsv.dischargeSuccess)
	end, gemids)
end

function GemView:onFilter()
	self.filterArrow:setRotation(180)
	local size = self.btnFilterPanel:size()
	local pos = self.btnFilterPanel:convertToWorldSpace(cc.p(size.width, - 100))
	gGameUI:stackUI('city.card.gem.filter', nil, nil, pos, {'right', 'top'}, self:createHandler('setFilterType'), self.filterType)
end

function GemView:setFilterType(filterType)
	self.filterArrow:setRotation(0)
	if filterType then
		self.filterType = filterType
		self.filterTxt:text(gLanguageCsv['gemSuit'..filterType] or gLanguageCsv.typeFilter)
		self:updateShowData()
	end
end

--查看指数
function GemView:onClickIndex()
	gGameUI:stackUI("city.card.gem.quality_index", nil, nil, self.carddbid, self.qualityNum:read())
end

--加成总览
function GemView:btnShowAllFunc()
	gGameUI:stackUI("city.card.gem.add_effect", nil, {blackLayer = true, clickClose = true}, self.carddbid, self.qualityNum:read())
end

--分解
function GemView:btnDecompose()
	gGameUI:stackUI("city.card.gem.decompose", nil, nil)
end

function GemView:onClickDraw()
	gGameUI:stackUI("city.card.gem.draw", nil, {full = true})
end

function GemView:showDetails(dbid)
	local slotIdx = self.curSlot:read()
	local pos = self.centerBg:convertToWorldSpaceAR(cc.p(0, 0))
	local align = 'right'
	if not dbid and slotIdx < 5 then
		align = 'left'
	end
	self.details = gGameUI:stackUI('city.card.gem.details', nil, {dispatchNodes = {self.list, self.left}, clickClose = true}, {cardID = self.carddbid,
		slotIdx = slotIdx,
		dbid = dbid,
		pos = pos,
		align = align,
	})
end

function GemView:closeDetails()
	self.details:onClose()
end

function GemView:oneKeyEquip()
	local gems = gGameModel.role:read('gems')
	local data = {}
	for _, v in pairs(gems) do
		local gem = gGameModel.gems:find(v)
		local cfg = dataEasy.getCfgByKey(gem:read('gem_id'))
		if gem:read('card_db_id') == nil or gem:read('card_db_id') == self.carddbid then
			insert(data, {
					dbid = v,
					quality = cfg.quality,
					level = gem:read('level'),
					suitID = cfg.suitID,
					suitNo = cfg.suitNo,
					gem_id = gem:read('gem_id')
				}
			)
		end
	end
	table.sort(data, function(a, b)
		if a.quality ~= b.quality then
			return a.quality > b.quality
		end
		return a.level > b.level
	end)
	if #data == 0 then
		gGameUI:showTip(gLanguageCsv.noGemTip)
		return
	end
	local map = {}
	local dbids = {}
	local csvIDMap = {}
	for i, v in pairs(data) do
		if not (map[v.suitID] and map[v.suitID][v.suitNo]) and not csvIDMap[v.gem_id] then
			if v.suitID and v.suitNo then
				map[v.suitID] = map[v.suitID] or {}
				map[v.suitID][v.suitNo] = true
			else
				csvIDMap[v.gem_id] = true
			end
			insert(dbids, v.dbid)
			if #dbids == 9 then
				break
			end
		end
	end
	local slots = {}
	local count = 0
	for i = 1, 9 do
		local isLocked, _ = GemTools.isSlotLocked(self.carddbid, i)
		if not isLocked then
			count = count + 1
			slots[i] = dbids[count]
		end
	end
	gGameApp:requestServer('/game/gem/onekey/equip', function(tb)
		gGameUI:showTip(gLanguageCsv.inlaySuccess)
	end, self.carddbid, slots)
end

function GemView:initModel()
	self.items = gGameModel.role:getIdler('items')
	self.gems = gGameModel.role:getIdler('gems')
	self.goldFreeCount = gGameModel.daily_record:getIdler('gem_gold_dc1_free_count')
	self.rmbFreeCount = gGameModel.daily_record:getIdler('gem_rmb_dc1_free_count')
end

function GemView:onCleanup()
	ViewBase.onCleanup(self)
	self.selectItem:destroy()
end

return GemView