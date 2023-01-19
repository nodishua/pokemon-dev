
--@desc: 重生符石选择界面
local GemRebirth = class("GemRebirth", Dialog)

--是否已嵌套
local createSmallPanel = function(node, dbid)
	local gem = gGameModel.gems:find(dbid)
	if gem:read('card_db_id') then
		ccui.ImageView:create("city/card/helditem/bag/icon_cd.png")
			:align(cc.p(0.5, 0.5), 40, 30)
			:addTo(node, 9999, "isEquiped")
			:xy(150, 150)
	end
end


GemRebirth.RESOURCE_FILENAME = "rebirth_gem.json"
GemRebirth.RESOURCE_BINDING = {
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
				leftPadding = 10,
				topPadding = 10,
				columnSize = 6,
				data = bindHelper.self('showData'),
				item = bindHelper.self('innerList'),
				cell = bindHelper.self('item'),
				onCell = function(list, node, k, v)
					node:get("name"):text(v.cfg.name)
					node:get("name"):color(ui.COLORS.QUALITY[v.cfg.quality])
					createSmallPanel(node, v.dbid)
					bind.extend(list, node, {
						class = 'icon_key',
						props = {
							noListener = true,
							data = {
								key = v.id,
								num = v.num,
								dbId = v.dbid,
							},
							specialKey = {
								leftTopLv = v.level
							},
							onNode = function(node)
								bind.click(list, node, {method = functools.partial(list.itemClick, k, v)})
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
	["tipPanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("showTip"),
		},
	},
}

function GemRebirth:onCreate(params)
	self.item:visible(false)
	self.list:setScrollBarEnabled(false)
	self.innerList:setScrollBarEnabled(false)
	self.showData = idlers.new({})
	self.handlers = params.handlers
	local data = {}
	local level1gems = {}
	self.showTip = idler.new(false)
	local gems = gGameModel.role:read('gems')
	for i, dbid in pairs(gems) do
		local gem = gGameModel.gems:find(dbid)
		local gem_id = gem:read('gem_id')
		local level = gem:read('level')
		if level >= 2 then
			local gemData = {
				id = gem_id,
				num = 1,
				cfg = dataEasy.getCfgByKey(gem_id),
				level = level,
				dbid = dbid,
				cardDbId = gem:read('card_db_id'),
			}
			if level == 1 then
				if not level1gems[gem_id] then
					gemData.dbids = {dbid}
					level1gems[gem_id] = gemData
					table.insert(data, gemData)
				else
					table.insert(level1gems[gem_id].dbids, dbid)
					level1gems[gem_id].num = level1gems[gem_id].num + 1
				end
			else
				table.insert(data, gemData)
			end
		end
	end
	table.sort(data, function(a, b)
		if (a.cardDbId == nil or b.cardDbId == nil) and a.cardDbId ~= b.cardDbId then
			return a.cardDbId == nil
		end
		if a.cfg.quality ~= b.cfg.quality then
			return a.cfg.quality > b.cfg.quality
		end
		if a.cfg.suitID ~= b.cfg.suitID then
			return a.cfg.suitID < b.cfg.suitID
		end
		if a.cfg.suitNo ~= b.cfg.suitNo then
			return a.cfg.suitNo < b.cfg.suitNo
		end
		return a.level > b.level
	end)
	self.showData:update(data)
	self.showTip:set(#data == 0)

	Dialog.onCreate(self)
end


function GemRebirth:onItemClick(list, k, v)
	local cb = function()
		if self.handlers then
			self.handlers(v.dbid)
		end
		self:onClose()
	end

	local gem = gGameModel.gems:find(v.dbid)
	if gem:read('card_db_id') then
		local txt = uiEasy.getCardName(gem:read('card_db_id'))
		local str = string.format(gLanguageCsv.inlayCard, txt)
		gGameUI:showDialog({cb = cb,
			isRich = true,
			btnType = 2,
			content = str,
		})
	else
		cb()
	end
end

return GemRebirth