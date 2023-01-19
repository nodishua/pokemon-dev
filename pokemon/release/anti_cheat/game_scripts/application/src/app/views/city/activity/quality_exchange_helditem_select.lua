-- @date 2020-10-10
-- @desc 携带道具限时分解选择界面

local HeldItemTools = require "app.views.city.card.helditem.tools"

local ActivityQualityExchangeHelditemSelectView = class("ActivityQualityExchangeHelditemSelectView", Dialog)

ActivityQualityExchangeHelditemSelectView.RESOURCE_FILENAME = "activity_quality_exchange_helditem_select.json"
ActivityQualityExchangeHelditemSelectView.RESOURCE_BINDING = {
	['title'] = "title",
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["innerList"] = "innerList",
	['list'] = {
		varname = "list",
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				columnSize = 6,
				data = bindHelper.self('datas'),
				item = bindHelper.self('innerList'),
				cell = bindHelper.self('item'),
				asyncPreload = 24,
				onCell = function(list, node, k, v)
					local name, effect = uiEasy.setIconName(v.csvId, nil, {space = true, advance = v.advance})
					node:get("name"):hide()
					node:removeChildByName("richName")
					local richName = beauty.singleTextLimitWord(name, {fontSize = 40}, {width =  240})
						:xy(node:get("name"):xy())
						:addTo(node, 10, "richName")
					text.addEffect(richName, effect)
					bind.extend(list, node:get("icon"), {
						class = "icon_key",
						props = {
							data = {
								key = v.csvId,
								num = v.num,
								dbId = v.dbId,
							},
							specialKey = {
								lv = v.lv,
							},
							onNode = function(panel)
								panel:setTouchEnabled(false)
							end,
						},
					})
					bind.touch(list, node:get("icon"), {methods = {ended = functools.partial(list.itemClick, k, v)}})
				end
			},
			handlers = {
				itemClick = bindHelper.self('onItemClick')
			}
		}
	},
	["tipPanel"] = "tipPanel",
}

-- 显示限定品质的携带道具
function ActivityQualityExchangeHelditemSelectView:onCreate(qualities, cb)
	self.qualities = qualities
	self.cb = cb
	self.datas = idlers.new()
	self.resetHelditem = idler.new()
	local tmpHash = {}
	local datasCount = 0
	idlereasy.any({gGameModel.role:getIdler("held_items"), self.resetHelditem}, function(_, heldItems)
		tmpHash = {}
		datasCount = itertools.size(heldItems)
		for _, dbId in pairs(heldItems) do
			local dbData = gGameModel.held_items:find(dbId)
			if dbData then
				local itemData = dbData:multigetIdler("exist_flag", "card_db_id", "advance", "level", "sum_exp", "held_item_id")
				idlereasy.any(itemData, function(_, exist_flag, card_db_id, advance, level, sum_exp, held_item_id)
					tmpHash[dbId] = true
					if itertools.size(tmpHash) == datasCount then
						self.datas:update(self:getData())
					end
				end):anonyOnly(self, stringz.bintohex(dbId))
			end
		end
	end)
	self.tipPanel:visible(itertools.size(self.datas) == 0)

	Dialog.onCreate(self)
end

function ActivityQualityExchangeHelditemSelectView:getData()
	local heldItems = gGameModel.role:read("held_items")
	local t = {} -- 堆叠汇总
	local datas = {}
	for _, dbId in pairs(heldItems) do
		local dbData = gGameModel.held_items:find(dbId)
		local itemData = dbData:read("exist_flag", "card_db_id", "advance", "level", "sum_exp", "held_item_id")
		if itemData.exist_flag then
			local csvId = itemData.held_item_id
			local cfg = dataEasy.getCfgByKey(csvId)
			if self.qualities[cfg.quality] then
				if itemData.sum_exp == 0 and itemData.advance == 0 and not itemData.card_db_id then
					if not t[csvId] then
						t[csvId] = {num = 0, cfg = cfg, dbId = dbId}
					end
					t[csvId].num = t[csvId].num + 1
				else
					local data = {
						num = 1,
						cfg = cfg,
						csvId = csvId,
						dbId = dbId,
						lv = itemData.level,
						cardDbID = itemData.card_db_id,
						advance = itemData.advance,
						isSpecial = true,
					}
					local isDress, isExc = HeldItemTools.isExclusive(data)
					data.isDress = isDress
					data.isExc = isExc
					table.insert(datas, data)
				end
			end
		end
	end

	-- 堆叠部分处理
	for csvId, v in pairs(t) do
		local allNum = v.num
		local maxNum = v.cfg.stackShow
		-- 计算需要多少个cell
		for i = 1, math.ceil(allNum / maxNum) do
			local data = {
				num = math.min(maxNum, allNum),
				cfg = v.cfg,
				csvId = csvId,
				dbId = v.dbId,
				lv = 1,
				advance = 0,
			}
			local isDress, isExc = HeldItemTools.isExclusive(data)
			data.isDress = isDress
			data.isExc = isExc
			table.insert(datas, data)
			allNum = allNum - maxNum
		end
	end
	table.sort(datas, dataEasy.sortHelditemCmp)

	return datas
end

function ActivityQualityExchangeHelditemSelectView:onResetHelditem(dbId)
	self.resetHelditem:notify()
end

function ActivityQualityExchangeHelditemSelectView:onItemClick(list, k, v)
	if v.isDress then
		gGameUI:showDialog({
			cb = function()
				gGameUI:stackUI("city.card.helditem.bag", nil, nil, v.cardDbID, self:createHandler("onResetHelditem"))
			end,
			btnType = 2,
			isRich = true,
			content = string.format(gLanguageCsv.qualityExchangeHelditemSelectTip2, ui.QUALITYCOLOR[v.cfg.quality], uiEasy.setIconName(v.csvId, nil, {space = true, advance = v.advance})),
		})
		return
	end
	if v.isSpecial then
		gGameUI:showDialog({
			cb = function()
				gGameUI:stackUI("city.card.rebirth.view", nil, {full = true}, 3, nil, nil, {heldItemId = v.dbId})
			end,
			btnType = 2,
			isRich = true,
			content = string.format(gLanguageCsv.qualityExchangeHelditemSelectTip1, ui.QUALITYCOLOR[v.cfg.quality], uiEasy.setIconName(v.csvId, nil, {space = true, advance = v.advance})),
		})
		return
	end
	if self.cb then
		self.cb(v.dbId)
	end
	self:onClose()
end

return ActivityQualityExchangeHelditemSelectView