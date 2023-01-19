local GemStrengthenView = class('GemStrengthenView', Dialog)
local insert = table.insert

GemStrengthenView.RESOURCE_FILENAME = 'gem_strengthen.json'
GemStrengthenView.RESOURCE_BINDING = {
	['btnClose'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onClose')}
		}
	},
	['gemPanel'] = 'gemPanel',
	['gemPanel.equipOn'] = 'equipOn',
	['gemPanel.cardName'] = 'cardName',
	['gemPanel.gemName'] = 'gemName',
	['gemPanel.icon'] = 'icon',
	['gemPanel.lv'] = {
		varname = "lv",
			binds = {
			{
				event = 'effect',
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}}
			}
		}
	},
	['gemPanel.lvBg'] = 'lvBg',
	['gemPanel.gemIconBg'] = 'gemIconBg',
	['subList'] = 'subList',
	['item'] = 'item',
	['list'] = {
		varname = 'list',
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				leftPadding = 10,
				topPadding = 10,
				asyncPreload = 15,
				preloadCenterIndex = bindHelper.self('curIdx'),
				data = bindHelper.self('gems'),
				columnSize = 5,
				item = bindHelper.self('subList'),
				cell = bindHelper.self('item'),
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = 'icon_key',
						props = {
							noListener = true,
							data = {
								key = v.key,
								num = v.num,
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
								node:stopAllActions()
								node:scale(1)
								bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, node, k, v)}})
							end
						}
					})
				end
			},
			handlers = {
				itemClick = bindHelper.self('onItemClick')
			}
		}
	},
	['btnPanel.btnStrengthen'] = {
		varname = 'btnStrengthen',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onStrengthen')}
		}
	},
	['btnPanel.btnStrengthen.title'] = {
		varname = 'btnStrengthenTxt',
		binds = {
			{
				event = 'effect',
				data = {glow = {color = ui.COLORS.GLOW.WHITE}}
			}
		}
	},
	['btnPanel.btnOneKeyStrengthen'] = {
		varname = 'btnOneKeyStrengthen',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('oneKeyStrengthen')}
		}
	},
	['btnPanel.btnOneKeyStrengthen.title'] = {
		varname = 'btnOneKeyStrengthenTxt',
		binds = {
			{
				event = 'effect',
				data = {glow = {color = ui.COLORS.GLOW.WHITE}}
			}
		}
	},
	['btnPanel'] = 'btnPanel',
	['btnPanel.txtCost'] = 'txtCost',
	['detail.attr'] = 'attr',
	['detail'] = 'detail',
	['detail.attrList'] = {
		varname = 'attrList',
		binds = {
			event = 'extend',
			class = 'listview',
			props = {
				data = bindHelper.self('attrData'),
				item = bindHelper.self('attr'),
				onItem = function(list, node, k, v)
					-- 符石指数
					if v.type == "special" then
						node:get('attrTxt'):text(gLanguageCsv.attrIndexPoint)
						node:get('attrNum'):text('+'..v.num)
					else
						local attrKey = game.ATTRDEF_TABLE[v.type]
						attrKey = 'attr'..string.caption(attrKey)
						node:get('attrTxt'):text(gLanguageCsv[attrKey])
						local val = dataEasy.getAttrValueString(v.type, v.num)
						node:get('attrNum'):text('+'..val)
					end
					adapt.oneLinePos(node:get('attrTxt'), node:get('attrNum'), cc.p(10, 0))
					local sameNum = v.num == v.nextNum
					node:get('arrowUp'):visible(false)
					node:get('attrNum3'):visible(false)
					if not v.isMaxLv then
						if not sameNum then
							if v.type == "special" then
								node:get('attrNum2'):text('+'..v.nextNum..'(+'..v.nextNum - v.num)
							else
								local nextVal = dataEasy.getAttrValueString(v.type, v.nextNum)
								local delVal = dataEasy.getAttrValueString(v.type, v.nextNum - v.num)
								node:get('attrNum2'):text('+'..nextVal..'(+'..delVal)
							end
							node:get('arrowUp'):visible(true)
							node:get('attrNum3'):visible(true)
							adapt.oneLinePos(node:get('attrNum'), {node:get('arrow'), node:get('attrNum2')}, cc.p(40, 0))
							adapt.oneLinePos(node:get('attrNum2'), {node:get('arrowUp'), node:get('attrNum3')})
						elseif v.nextLevel then
							node:get('tip'):text(string.format(gLanguageCsv.strengthenWhenlvN, v.nextLevel))
							adapt.oneLinePos(node:get('attrNum'), node:get('tip'))
						end
					end
					node:get('tip'):visible(sameNum and not v.isMaxLv and v.nextLevel and true or false)
					node:get('attrNum2'):visible(not sameNum and not v.isMaxLv)
					node:get('arrow'):visible(not sameNum and not v.isMaxLv)
				end
			}
		}
	},
	['detail.lvNum'] = 'detailLv',
	['detail.lvNum2'] = 'detailLv2',
	['detail.lvMax'] = 'detailLvMax',
	['imgLvMax'] = 'imgLvMax',
	['detail.arrow'] = 'detailArrow',
	["acquire.num"] = "acquireNum",
	["acquire"] = "acquire",
}

function GemStrengthenView:onCreate(gemdbid)
	self.attr:visible(false)
	self:initModel()
	self.costNodes = {}
	dataEasy.getListenUnlock(gUnlockCsv.gemOnekeyStrengthen, function(unlock)
		self.btnOneKeyStrengthen:visible(unlock)
		self.btnStrengthen:x(unlock and 587 or 357)
		self.unlock = unlock
		self:resetCostNodesXY()
	end)
	self.gemIdler = idler.new()
	self.attrData = idlers.newWithMap({})
	if gemdbid then
		self.gemIdler:set(gemdbid)
	end
	self.selectEffect = ccui.ImageView:create("common/box/box_selected.png")
		:alignCenter(self.item:size())
		:retain()
	idlereasy.when(self.gemIdler, function(_, gemdbid)
		self.firstDetail = false
		local gem = gGameModel.gems:find(gemdbid)
		local cfg = dataEasy.getCfgByKey(gem:read('gem_id'))
		self.icon:texture(cfg.icon)
		local name, effect = uiEasy.setIconName(gem:read('gem_id'))
		self.gemName:text(name)
		text.addEffect(self.gemName, effect)
		self.gemIconBg:texture('city/card/helditem/strengthen/img_dt'..cfg.quality..'.png')
		self.gemlevel = idlereasy.assign(gem:getIdler('level'), self.gemlevel)
	end)
	idlereasy.any({self.gemlevel, self.gold}, function(_, level)
		self:setDetail()
	end)
	local carddbid = gGameModel.gems:find(gemdbid):read('card_db_id')
	if not carddbid then
		self.equipOn:visible(false)
		self.cardName:visible(false)
	else
		local card = gGameModel.cards:find(carddbid)
		uiEasy.setIconName('card', card:read('card_id'), {node = self.cardName, name = card:read('name'), advance = card:read('advance'), space = true})
		adapt.oneLineCenterPos(cc.p(241, 0), {self.equipOn, self.cardName})
	end
	self.gems = idlers.new()
	local count = 0
	local data = {}
	local gems
	if carddbid then
		gems = gGameModel.cards:find(carddbid):read('gems')
	else
		gems = gGameModel.role:read('gems')
	end
	for k, dbid in pairs(gems) do
		local gem = gGameModel.gems:find(dbid)
		if carddbid or not gem:read('card_db_id') then
			count = count + 1
			local cfg = dataEasy.getCfgByKey(gem:read('gem_id'))
			local t = {
				gemdbid = dbid,
				key = gem:read('gem_id'),
				quality = cfg.quality,
				suitID = cfg.suitID,
				suitNo = cfg.suitNo,
				level = gem:read('level'),
			}
			table.insert(data, t)
		end
	end
	table.sort(data, function(a, b)
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
	for i, v in ipairs(data) do
		if v.gemdbid == gemdbid then
			self.curIdx = math.ceil(i / 5)
			v.selectEffect = self.selectEffect
		end
		v.idx = i
		idlereasy.when(gGameModel.gems:find(v.gemdbid):getIdler('level'), function(_, level)
			local data = self.gems:atproxy(i)
			data.level = level
		end, true):anonyOnly(self, stringz.bintohex(v.gemdbid))
	end
	self.gems:update(data)
	if #data <= 10 then
		performWithDelay(self, function()
			self.list:setItemAlignCenter()
		end, 0)
	end
	self.selectItem = idler.new()
	self.selectItem:addListener(function(val, oldval)
		if val then
			local data = self.gems:atproxy(val)
			data.selectEffect = self.selectEffect
		end
	end)

	self.item529 = idler.new(0)
	idlereasy.when(gGameModel.role:getIdler('items'), function(_, items)
		self.item529:set(items[529] or 0)
	end)
	idlereasy.when(self.item529, function(_, num)
		self.acquireNum:text(num)
		local width = self.acquireNum:width() + 50
		width = math.max(width, 187)
		self.acquire:get("bg"):width(width)
		self.acquireNum:x(self.acquire:get("bg"):x() + width / 2)
	end)
	Dialog.onCreate(self)
end

function GemStrengthenView:setDetail()
	local gem = gGameModel.gems:find(self.gemIdler:read())
	local level = gem:read('level')
	local cfg = dataEasy.getCfgByKey(gem:read('gem_id'))

	self.lv:text('Lv'..level)
	self.detailLv:text('Lv'..level)
	self.detailLv2:text('Lv'..(level + 1))
	self.lvBg:visible(false)
	local isMaxLv = level == cfg.strengthMax
	self.detailLvMax:visible(isMaxLv)
	self.detailLv2:visible(not isMaxLv)
	self.imgLvMax:visible(isMaxLv)
	self.detailArrow:visible(not isMaxLv)
	adapt.oneLinePos(self.detailLv, {self.detailLvMax})
	self.btnPanel:visible(not isMaxLv)
	local cost = csv.gem.cost[level]['costItemMap'..cfg.strengthCostSeq]
	for k, v in pairs(self.costNodes) do
		v:removeSelf()
	end
	self.costNodes = {}
	self.needCost = nil
	for key, num in csvMapPairs(cost) do
		local numNode = cc.Label:createWithTTF(num, ui.FONT_PATH, 40):addTo(self.btnPanel, 100):setTextColor(ui.COLORS.NORMAL.BLACK)
		local icon = ccui.ImageView:create(dataEasy.getIconResByKey(key)):addTo(self.btnPanel, 100):scale(0.8)
		insert(self.costNodes, numNode)
		insert(self.costNodes, icon)
		if dataEasy.getNumByKey(key) < num then
			text.addEffect(numNode, {color = ui.COLORS.NORMAL.RED})
			self.needCost = key
		end
	end
	self:resetCostNodesXY()
	self.curCost = cost
	local data = {}
	for i = 1, math.huge do
		if cfg['attrType'..i] and cfg['attrType'..i] ~= 0 then
			local nums = cfg['attrNum'..i]
			local t = {
				type = cfg['attrType'..i],
				num = nums[level],
				nextNum = nums[level + 1],
				level = level,
				isMaxLv = isMaxLv
			}
			for j = level, cfg.strengthMax do
				if not nums[j] then
					break
				elseif nums[j] ~= nums[level] then
					t.nextLevel = j
					break
				end
			end
			table.insert(data, t)
		else
			break
		end
	end


	local csvQuality = csv.gem.quality
	local quality = cfg.quality
	local qKey = 'qualityNum'..quality
	local t = {type = "special", num = csvQuality[level][qKey], isMaxLv = isMaxLv}
	if csvQuality[level + 1] then
		t.nextNum = csvQuality[level + 1][qKey]
	end
	for i = level, cfg.strengthMax do
		if not csvQuality[i] then
			break
		elseif csvQuality[i] and csvQuality[level][qKey] ~= csvQuality[i][qKey] then
			t.nextLevel = i
			break
		end
	end
	table.insert(data, t)
	self.attrData:update(data)
	if not self.firstDetail then
		self.firstDetail = true
	else
		self:showLvUpEffects()
	end
end

function GemStrengthenView:resetCostNodesXY()
	local x, y = self.btnStrengthen:xy()
	local tbl = {self.txtCost, unpack(self.costNodes)}
	local space = {}
	if self.unlock then
		local reverseTbl = {}
		local flag = false -- 空一些间距
		for i = #tbl - 1, 1, -1 do
			tbl[i]:y(y + 100)
			insert(reverseTbl, tbl[i])
			insert(space, flag and cc.p(15, 0) or cc.p(0, 0))
			flag = not flag
		end
		tbl[#tbl]:xy(x + 120, y + 100)
		adapt.oneLinePos(tbl[#tbl], reverseTbl, space, 'right')
	else
		local flag = true -- 空一些间距
		for i = 1, #tbl do
			insert(space, flag and cc.p(15, 0) or cc.p(0, 0))
			flag = not flag
		end
		adapt.oneLineCenterPos(cc.p(x, y + 100), tbl, space)
	end
end

function GemStrengthenView:showLvUpEffects()
	local items = self.attrList:getItems()
	for k, v in ipairs(items) do
		if v:get('effect') then
			v:get('effect'):removeSelf()
		end
		widget.addAnimationByKey(v, 'haogandujiesuo/shuzhibianhua.skel ', "effect", "effect", 10)
			:alignCenter(v:size())
			:xy(320, 40)
	end
	if self.gemPanel:get('effect') then
		self.gemPanel:get('effect'):removeSelf()
	end
	widget.addAnimationByKey(self.gemPanel, 'koudai_gonghuixunlian/gonghuixunlian.skel', 'effect', 'fangguang2', 100)
		:xy(241, 150)
	gGameUI:showTip(gLanguageCsv.strengthenSuccess)
end

function GemStrengthenView:onItemClick(list, node, k, v)
	self.selectItem:set(v.idx)
	self.gemIdler:set(v.gemdbid)
end

function GemStrengthenView:onStrengthen()
	if self.needCost then
		if self.needCost == 'gold' or self.needCost == 'rmb' then
			uiEasy.showDialog(self.needCost)
		else
			gGameUI:showTip(gLanguageCsv.materialsNotEnough)
		end
		return
	end
	local gemdbid = self.gemIdler:read()
	local gem = gGameModel.gems:find(gemdbid)
	gGameApp:requestServer('/game/gem/strength', function()
	end, gemdbid, gem:read('level') + 1)
end

function GemStrengthenView:oneKeyStrengthen()
	if self.needCost then
		if self.needCost == 'gold' or self.needCost == 'rmb' then
			uiEasy.showDialog(self.needCost)
		else
			gGameUI:showTip(gLanguageCsv.materialsNotEnough)
		end
		return
	end
	gGameUI:stackUI('city.card.gem.onekey_strengthen', nil, nil, self.gemIdler:read())
end

function GemStrengthenView:initModel()
	self.gold = gGameModel.role:getIdler('gold')
end

return GemStrengthenView