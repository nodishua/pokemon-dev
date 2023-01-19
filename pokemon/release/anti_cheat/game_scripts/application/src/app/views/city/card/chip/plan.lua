-- @date 2021-6-2
-- @desc 学习芯片方案

local ViewBase = cc.load("mvc").ViewBase
local ChipBagView = require "app.views.city.card.chip.bag"
local ChipPlanView = class("ChipPlanView", ChipBagView)
local ChipTools = require('app.views.city.card.chip.tools')
local ATTR_FILTER_TYPE = ChipBagView.ATTR_FILTER_TYPE

ChipPlanView.RESOURCE_FILENAME = "chip_plan.json"
ChipPlanView.RESOURCE_BINDING = clone(ChipBagView.RESOURCE_BINDING)
local resourceBinding = {
	["left.btnEquip"] = {
		varname = "btnEquipShow",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEquipShowClick")}
		}
	},
	["leftPlan"] = "leftPlan",
	["leftPlan.btnNewPlan"] = {
		varname = "btnLeftPlanNew",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onLeftPlanNewClick")}
		}
	},
	["leftPlan.btnNewPlan.txt"] = {
		binds = {
			event = "effect",
			data = {color=ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["leftPlan.btnSuitFilter"] = {
		varname = "btnPlanSuitFilter",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlanSuitFilterClick")}
		}
	},
	["leftPlan.btnOrder"] = {
		varname = "btnPlanOrder",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlanOrderClick")}
		}
	},
	["leftPlan.empty"] = "planEmpty",
	["leftPlan.item"] = "planItem",
	["leftPlan.subList"] = "planSubList",
	['leftPlan.list'] = {
		varname = 'planList',
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				asyncPreload = 12,
				columnSize = 2,
				data = bindHelper.self('planData'),
				item = bindHelper.self('planSubList'),
				cell = bindHelper.self('planItem'),
				onCell = function(list, node, k, v)
					local childs = node:multiget("bg", "icon", "name", "curName", "newName", "inEquip", "chipPanel",  "equipPanel",  "inEquipPanel")
					itertools.invoke(childs, "hide")
					local data = v.data or {}

					if v.suitId then
						childs.icon:show():texture(ChipTools.getSuitRes(v.suitId)):scale(0.9)
					else
						childs.chipPanel:show()
						childs.chipPanel:get("add"):visible(v.addNew and not v.id or false)
						for i = 1, 6 do
							local item = childs.chipPanel:get("chip" .. i)
							if data.chips and data.chips[i] then
								local chip = gGameModel.chips:find(data.chips[i])
								local cfg = csv.chip.chips[chip:read("chip_id")]
								item:show():texture(string.format("city/card/chip/img_dw_%d.png", cfg.quality))
							else
								item:hide()
							end
						end
					end

					if data.name then
						childs.name:show():text(data.name)
					else
						if v.addNew then
							childs.newName:show()
						else
							childs.curName:show()
						end
					end
					childs.inEquip:hide()
					node:removeChildByName("inEquipRich")
					if v.cardDBID ~= nil then
						local name = uiEasy.getCardName(v.cardDBID)
						local richText = rich.createWithWidth("#C0x5B545B#" .. gLanguageCsv.chipInEquip .. name, 26, nil, 300)
						richText:addTo(node, 5, "inEquipRich")
							:anchorPoint(0, 0.5)
							:xy(childs.inEquip:xy())
					end

					local selectPlanId = list.selectPlanId()
					idlereasy.when(selectPlanId, function(_, selectPlanId)
						if not tolua.isnull(childs.bg) then
							childs.bg:show()
							if not v.addNew and selectPlanId == v.id then
								childs.bg:texture("city/card/chip/panel_sl.png")
							else
								childs.bg:texture("city/card/chip/panel_up.png")
							end
						end
					end):anonyOnly(list, v.id)

					if v.addNew then
						bind.touch(list, node, {methods = {ended = functools.partial(list.itemNewClick, node, k, v)}})
					else
						if v.curCard then
							childs.inEquipPanel:show()
							text.addEffect(childs.inEquipPanel:get("name"), {outline={color=cc.c4b(250, 88, 103, 255), size = 3}})
						else
							childs.equipPanel:show()
							text.addEffect(childs.equipPanel:get("name"), {outline={color=cc.c4b(204, 163, 122, 255), size = 3}})
						end
						bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, node, k, v)}})
						bind.touch(list, childs.equipPanel, {methods = {ended = functools.partial(list.equipClick, node, k, v)}})
					end
				end
			},
			handlers = {
				itemNewClick = bindHelper.self('onPlanItemNewClick'),
				itemClick = bindHelper.self('onPlanItemClick'),
				equipClick = bindHelper.self('onPlanItemEquipClick'),
				selectPlanId = bindHelper.self('selectPlanId'),
			}
		}
	},
	["right.namePanel"] = {
		varname = "planNamePanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlanNameClick")}
		}
	},
	["right.btnNewPanel"] = "planBtnNewPanel",
	["right.btnSavePanel"] = "planBtnSavePanel",
	["right.btnEditPanel"] = "planBtnEditPanel",
	["right.btnEquipPanel"] = "planBtnEquipPanel",
	["right.btnNewPanel.btnNew"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRightPlanNewClick")}
		}
	},
	["right.btnNewPanel.btnNew.txt"] = {
		binds = {
			event = "effect",
			data = {color=ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["right.btnSavePanel.btnSave"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlanSaveClick")}
		}
	},
	["right.btnSavePanel.btnSave.txt"] = {
		binds = {
			event = "effect",
			data = {color=ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["right.btnEditPanel.btnDelete"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlanDeleteClick")}
		}
	},
	["right.btnEditPanel.btnTop"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlanTopClick")}
		}
	},
	["right.btnEditPanel.btnEdit"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlanEditClick")}
		}
	},
	["right.btnEditPanel.btnEdit.txt"] = {
		binds = {
			event = "effect",
			data = {color=ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["right.btnEquipPanel.btnDelete"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlanDeleteClick")}
		}
	},
	["right.btnEquipPanel.btnTop"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlanTopClick")}
		}
	},
	["right.btnEquipPanel.btnEdit"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlanEditClick")}
		}
	},
	["right.btnEquipPanel.btnEdit.txt"] = {
		binds = {
			event = "effect",
			data = {color=ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["right.btnEquipPanel.btnEquip"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlanEquipClick")}
		}
	},
	["right.btnEquipPanel.btnEquip.txt"] = {
		binds = {
			event = "effect",
			data = {color=ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["planSuitFilterPanel"] = "planSuitFilterPanel",
	["planSuitFilterPanel.panel.item"] = "planSuitFilterItem",
	["planSuitFilterPanel.panel.subList"] = "planSuitFilterSubList",
	['planSuitFilterPanel.panel.list'] = {
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				data = bindHelper.self('planSuitFilterData'),
				item = bindHelper.self('planSuitFilterSubList'),
				cell = bindHelper.self('planSuitFilterItem'),
				columnSize = 2,
				onCell = function(list, node, k, v)
					node:get("bg"):visible(v.selected ~= true)
					node:get("bgSelected"):visible(v.selected == true)
					local suitIcon
					local suitName
					local scale = 1
					if v.suitId == -1 then
						suitIcon = "city/card/chip/icon_qb.png"
						suitName = gLanguageCsv.all

					elseif v.suitId == 0 then
						suitIcon = "city/card/chip/icon_wtz.png"
						suitName = gLanguageCsv.noSuit
					else
						suitIcon = v.cfg.suitIcon
						suitName = v.cfg.suitName
						scale = 0.9
					end
					node:get("icon"):texture(suitIcon):scale(scale)
					node:get("name"):text(suitName)
					node:get("count"):text(gLanguageCsv.have .. ": " .. v.count)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, node, k, v)}})
				end
			},
			handlers = {
				itemClick = bindHelper.self('onPlanSuitFilterItemClick'),
			}
		}
	},
	["planOrderPanel"] = "planOrderPanel",
	["planOrderPanel.panel.item"] = "planOrderItem",
	["planOrderPanel.panel.subList"] = "planOrderSubList",
	['planOrderPanel.panel.list'] = {
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				data = bindHelper.self('planOrderData'),
				item = bindHelper.self('planOrderSubList'),
				cell = bindHelper.self('planOrderItem'),
				columnSize = 3,
				onCell = function(list, node, k, v)
					adapt.setTextScaleWithWidth(node:get("name"), v.name, 240)
					if v.selected then
						node:get("icon"):texture("city/card/chip/btn_r.png")
						text.addEffect(node:get("name"), {color = ui.COLORS.NORMAL.WHITE})
					else
						node:get("icon"):texture("city/card/chip/btn_w.png")
						text.addEffect(node:get("name"), {color = ui.COLORS.NORMAL.RED})
					end
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, node, list:getIdx(k), v)}})
				end
			},
			handlers = {
				itemClick = bindHelper.self('onPlanOrderItemClick'),
			}
		}
	},

	---- 覆盖重写 ----
	["right.chipPanel"] = {
		varname = "chipPanel",
		binds = {
			event = "extend",
			class = "chips_panel",
			props = {
				data = bindHelper.self("curChipPlan"),
				panelIdx = 2,
				slotFlags = bindHelper.self("slotFlags"),
				selected = bindHelper.self("selectRightPos"),
				showSuitEffect = true,
				onItem = function(panel, item, k, dbId)
					if dbId then
						item:get("defaultLv"):y(0)
					end
				end,
			},
		}
	},
	["right.baseAttrPanel.list"] = {
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				columnSize = 2,
				data = bindHelper.self('baseAttrData'),
				item = bindHelper.self('baseAttrSubList'),
				cell = bindHelper.self('baseAttrItem'),
				onCell = function(list, node, k, v)
					local childs = node:multiget("icon", "text", "val", "up1", "upVal", "upIcon", "up2")
					childs.icon:texture(ui.ATTR_LOGO[v.attr])
					childs.text:text(getLanguageAttr(v.key))
					if type(v.val) == "table" then
						-- {左侧值, 右侧值, 对比数值(界面显示颜色等), 对比显示值}
						itertools.invoke({childs.up1, childs.upVal, childs.upIcon, childs.up2}, "show")
						childs.val:text(v.val[1])
						childs.upVal:text(v.val[4])
						if v.val[3] == 0 then
							childs.upIcon:hide()
							text.addEffect(childs.upVal, {color=cc.c4b(183, 176, 158, 255)})

						elseif v.val[3] > 0 then
							childs.upIcon:texture("common/icon/logo_arrow_green.png")
							text.addEffect(childs.upVal, {color=ui.COLORS.NORMAL.FRIEND_GREEN})
						else
							childs.upIcon:texture("common/icon/logo_arrow_red.png")
							text.addEffect(childs.upVal, {color=ui.COLORS.NORMAL.ALERT_ORANGE})
						end
						adapt.oneLinePos(childs.up1, {childs.upVal, childs.upIcon, childs.up2})
					else
						itertools.invoke({childs.up1, childs.upVal, childs.upIcon, childs.up2}, "hide")
						childs.val:text("+" .. v.val)
					end
				end
			},
		}
	},
	["right.baseAttrPanel.btnDetail"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBaseAttrDetailClick")}
		}
	},
	["right.suitAttrPanel.btnDetail"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSuitAttrDetailClick")}
		}
	},
}
table.merge(ChipPlanView.RESOURCE_BINDING, resourceBinding)

ChipPlanView.RESOURCE_STYLES = {
	full = true,
}

-- @params {curCardDBID, page, planId, cb}
-- @params page 1:套装(默认), 2:背包
function ChipPlanView:onCreate(params)
	params = params or {}
	params.itemWidthExtra = 40
	self.page = params.page or 1
	self.selectPlanId = idler.new()
	self.curChipPlan = idlereasy.new({})
	self.planData = idlers.newWithMap({})

	self.planSuitFilterData = idlers.newWithMap({})
	self.planOrderData = idlers.newWithMap({})
	self.showCard = idler.new(false)

	ChipBagView.onCreate(self, params)
	local title = gLanguageCsv.chipPlan
	local subTitle = "CHIP PLAN"
	if self.page == 2 then
		title = gLanguageCsv.chipPlanBag
		subTitle = "CHIP PLAN BAG"
	end
	self.topuiView:updateTitle(title, subTitle)
	self.right:stopAllActions()
	self.right:x(self.originRightPos.x)
	self.midColumnSize = self.midColumnSize + 1
	self.asyncPreload = self.midColumnSize * 5

	-- 适配
	local leftPlanPos = cc.p(self.leftPlan:xy())
	self.leftPlan:x(leftPlanPos.x - self.leftPlan:width() - 100)
	self.leftPlan:runAction(cc.MoveTo:create(0.4, leftPlanPos))
	self.left:visible(self.page == 2)
	self.leftPlan:visible(self.page == 1)
	adapt.dockWithScreen(self.leftPlan, "left")
	adapt.dockWithScreen(self.planSuitFilterPanel:get("panel"), "left")
	adapt.dockWithScreen(self.planOrderPanel:get("panel"), "left")

	self.chipPlans = gGameModel.role:getIdler("chip_plans")
	self.selectPlanId:set(params.planId)
	if self.page == 2 then
		local plans = self.chipPlans:read()
		local selectPlanId = self.selectPlanId:read()
		self.curChipPlan:set(table.deepcopy(plans[selectPlanId] and plans[selectPlanId].chips or {}, true))
	end

	-- 右侧按钮状态
	idlereasy.any({self.selectPlanId, self.cardChips, self.chipPlans, self.isRefreshBagPanel}, function(_, selectPlanId, cardChips, plans)
		self:setPlanName()
		itertools.invoke({self.planBtnNewPanel, self.planBtnSavePanel, self.planBtnEditPanel, self.planBtnEquipPanel}, "hide")
		local showCard = false
		if self.page == 2 then
			self.planBtnSavePanel:show()
		else
			if not selectPlanId then
				showCard = true
				self.curChipPlan:set(table.deepcopy(cardChips, true))
				self.planBtnNewPanel:show()
			else
				self.curChipPlan:set(table.deepcopy(plans[selectPlanId] and plans[selectPlanId].chips or {}, true))
				if self.cardChipsPlanId == selectPlanId then
					showCard = true
					self.planBtnEditPanel:show()
				else
					self.planBtnEquipPanel:show()
				end
			end
		end
		self.showCard:set(showCard, true)
	end)
	-- 右侧芯片刷新
	self.curChipPlanIdler_ = {}
	idlereasy.when(self.showCard, function()
		for _, v in pairs(self.curChipPlanIdler_) do
			v:destroy()
		end
		self.curChipPlanIdler_ = {}
		local plan = self.curChipPlan:read()
		for i = 1, 6 do
			local dbId = plan[i]
			if dbId then
				local chip = gGameModel.chips:find(dbId)
				-- 等级和副属性变动影响属性
				local chipDatas = chip:multigetIdler("level", "now")
				self.curChipPlanIdler_[dbId] = idlereasy.any(chipDatas, function()
					self:showPanel()
				end, true):anonyOnly(self, stringz.bintohex(dbId))
			end
		end
		self:showPanel()
	end)

	-- 方案套装筛选
	self.planSuitFilterPanel:hide()
	bind.click(self, self.planSuitFilterPanel, {method = function()
		self.planSuitFilterPanel:hide()
		self.btnPlanSuitFilter:get("arrow"):setFlippedY(false)
	end})
	self.selectPlanSuitId = idler.new(-1) -- -1 为全部, 0 为无套装, suitId
	idlereasy.when(self.selectPlanSuitId, function(_, selectPlanSuitId)
		self.planList:jumpToTop()
		self.planSuitFilterPanel:hide()
		self.btnPlanSuitFilter:get("arrow"):setFlippedY(false)
		local str = gLanguageCsv.chipPlanSuitFilter
		if selectPlanSuitId == 0 then
			str = gLanguageCsv.noSuit
		elseif selectPlanSuitId > 0 then
			str = gChipSuitCsv[selectPlanSuitId][2][2].suitName
		end
		self.btnPlanSuitFilter:get("txt"):text(str)
	end)

	-- 方案排序
	self.planOrderPanel:hide()
	bind.click(self, self.planOrderPanel, {method = function()
		self.planOrderPanel:hide()
		self.btnPlanOrder:get("arrow"):setFlippedY(false)
	end})
	self.selectPlanOrder = idler.new() -- nil 为默认创建时间降序, 属性单选key
	idlereasy.when(self.selectPlanOrder, function(_, selectPlanOrder)
		self.planList:jumpToTop()
		self.planOrderPanel:hide()
		self.btnPlanOrder:get("arrow"):setFlippedY(false)
		local str = selectPlanOrder and ChipTools.getAttrName(selectPlanOrder) or gLanguageCsv.chipPlanOrderDefault
		adapt.setTextScaleWithWidth(self.btnPlanOrder:get("txt"), str, 200)
	end)

	-- 方案刷新,
	self.isRefreshPlanPanel = idler.new(true)
	if self.page == 1 then
		local refreshPlanTimes = 0
		idlereasy.any({self.isRefreshPlanPanel, self.selectPlanSuitId, self.selectPlanOrder, self.chipPlans, self.cardChips}, function()
			refreshPlanTimes = refreshPlanTimes + 1
			-- 延迟一帧导致界面状态显示有一帧错乱，先去掉
			-- performWithDelay(self, function()
				if refreshPlanTimes > 0 then
					refreshPlanTimes = 0
					self:refreshLeftPlanPanel()
				end
			-- end, 0)
		end)
	end

	-- 芯片方案显示精灵装备
	self.equipShow = idler.new(true)
	idlereasy.when(self.equipShow, function(_, show)
		if show then
			self.btnEquipShow:get("img"):texture("common/btn/btn_nomal_3.png")
			self.btnEquipShow:get("icon"):texture("city/card/chip/icon_xs.png")
			self.btnEquipShow:get("txt"):text(gLanguageCsv.chipPlanEquipShow)
			text.addEffect(self.btnEquipShow:get("txt"), {color = ui.COLORS.NORMAL.RED})
		else
			self.btnEquipShow:get("img"):texture("common/btn/btn_nomal_2.png")
			self.btnEquipShow:get("icon"):texture("city/card/chip/icon_yc.png")
			self.btnEquipShow:get("txt"):text(gLanguageCsv.chipPlanEquipHide)
			text.addEffect(self.btnEquipShow:get("txt"), {color = ui.COLORS.NORMAL.WHITE})
		end
		self.isRefreshBagPanel:notify()
	end)
end

function ChipPlanView:refreshLeftPlanPanel()
	local selectPlanId = self.selectPlanId:read()
	local plans = self.chipPlans:read()
	if self.isPlanAddNew or not plans[selectPlanId] then
		selectPlanId = nil
	end

	-- {id, data = {chips, created_time, name}, suitId, addNew, cardDBID, curCard}
	local datas = {}
	-- 为选定则选择为当前精灵的方案
	local cardChipsPlanId = nil
	local selectCardDBID = self.selectCardDBID:read()
	local cardChips = self.cardChips:read()
	if selectPlanId and itertools.size(cardChips) > 0 and itertools.equal(cardChips, plans[selectPlanId].chips) then
		cardChipsPlanId = selectPlanId
	end

	for id, data in pairs(plans) do
		local suitId = nil
		local suitAttrs = ChipTools.getSuitAttrByCard(data.chips)
		for k, attr in pairs(suitAttrs) do
			if attr[2] and attr[2][3] == true then
				suitId = k
			end
		end
		local cardDBID = ChipTools.getCardDBID(data.chips)
		if not cardChipsPlanId and cardDBID == selectCardDBID then
			cardChipsPlanId = id
		end
		table.insert(datas, {
			id = id,
			data = data,
			suitId = suitId,
			addNew = self.isPlanAddNew,
			cardDBID = cardDBID,
			curCard = cardChipsPlanId == id,
			attrsValue = ChipTools.getAttrsValue(data.chips),
		})
	end
	self.cardChipsPlanId = cardChipsPlanId
	if self.isPlanAddNew then
		table.insert(datas, {addNew = self.isPlanAddNew, attrsValue = ChipTools.getAttrsValue()})

	else
		if not cardChipsPlanId then
			local suitId = nil
			local suitAttrs = ChipTools.getSuitAttrByCard(cardChips)
			for k, attr in pairs(suitAttrs) do
				if attr[2] and attr[2][3] == true then
					suitId = k
				end
			end
			table.insert(datas, {
				data = {chips = cardChips},
				suitId = suitId,
				addNew = self.isPlanAddNew,
				curCard = true,
				attrsValue = ChipTools.getAttrsValue(cardChips),
			})
		end
		if not selectPlanId then
			selectPlanId = cardChipsPlanId
		end
	end
	self.planDataAll = datas

	-- 过滤
	local selectPlanSuitId = self.selectPlanSuitId:read()
	if selectPlanSuitId >= 0 then
		local function filter(data)
			if data.id then
				if selectPlanSuitId == 0 then
					if data.suitId then
						return false
					end
				elseif selectPlanSuitId > 0 then
					if selectPlanSuitId ~= data.suitId then
						return false
					end
				end
			end
			return true, id
		end
		local newDatas = {}
		local hashId = {}
		for _, data in ipairs(datas) do
			if filter(data) then
				table.insert(newDatas, data)
				if data.id then
					hashId[data.id] = true
				end
			end
		end
		datas = newDatas
		if not hashId[selectPlanId] then
			selectPlanId = nil
		end
	end

	-- 排序 默认按创建时间降序
	local selectPlanOrder = self.selectPlanOrder:read()
	local function order(a, b)
		if not a.id or not b.id then
			return not a.id
		end
		if selectPlanOrder then
			-- 先按固定值排序
			local a1 = a.attrsValue[1][selectPlanOrder]
			local b1 = b.attrsValue[1][selectPlanOrder]
			if a1 and b1 then
				if a1 ~= b1 then
					a1 = tonumber(a1)
					b1 = tonumber(b1)
					return a1 > b1
				end
			elseif a1 or b1 then
				return a1
			end
			-- 再按百分比排序
			local a2 = a.attrsValue[2][selectPlanOrder]
			local b2 = b.attrsValue[2][selectPlanOrder]
			if a2 and b2 then
				if a2 ~= b2 then
					a2 = tonumber(string.sub(a2, 1, #a2 - 1))
					b2 = tonumber(string.sub(b2, 1, #b2 - 1))
					return a2 > b2
				end
			elseif a2 or b2 then
				return a2
			end
		end
		return a.data.created_time > b.data.created_time
	end
	table.sort(datas, order)
	if not selectPlanId then
		selectPlanId = datas[1].id
	end

	self.selectPlanId:set(selectPlanId, true)
	dataEasy.tryCallFunc(self.planList, "updatePreloadCenterIndexAdaptFirst")
	self.planData:update(datas)
end

-- 新建方案
function ChipPlanView:onLeftPlanNewClick()
	local plans = self.chipPlans:read()
	local newId = 0
	for i = 1, table.maxn(plans) + 1 do
		if not plans[i] then
			newId = i
			break
		end
	end
	local name = gLanguageCsv.planNew
	gGameApp:requestServer("/game/chip/plan/new", function()
		self.planList:jumpToTop()
		self.selectPlanId:set(newId)
		self.isRefreshPlanPanel:notify()
	end, {}, name)
end

-- 类型筛选
function ChipPlanView:onSuitFilterClick()
	ChipBagView.onSuitFilterClick(self, true)
end

-- 套装筛选
function ChipPlanView:onPlanSuitFilterClick()
	self.btnPlanSuitFilter:get("arrow"):setFlippedY(true)
	local counts = {[-1] = 0}
	for _, v in pairs(self.planDataAll) do
		counts[-1] = counts[-1] + 1
		if v.id then
			local suitId = v.suitId or 0
			counts[suitId] = counts[suitId] or 0
			counts[suitId] = counts[suitId] + 1
		end
	end
	local selectPlanSuitId = self.selectPlanSuitId:read()
	local data = {}
	for suitId, count in pairs(counts) do
		table.insert(data, {
			suitId = suitId,
			count = count,
			selected = selectPlanSuitId == suitId,
			cfg = suitId > 0 and gChipSuitCsv[suitId][2][2],
		})
	end
	table.sort(data, function(a, b)
		return a.suitId < b.suitId
	end)
	self.planSuitFilterData:update(data)
	self.planSuitFilterPanel:show()
end

-- 套装排序
function ChipPlanView:onPlanOrderClick()
	self.btnPlanOrder:get("arrow"):setFlippedY(true)
	local selectPlanOrder = self.selectPlanOrder:read()
	local data = {{name = gLanguageCsv.default, selected = selectPlanOrder == nil}}
	for _, key in ipairs(ATTR_FILTER_TYPE) do
		local id = game.ATTRDEF_ENUM_TABLE[key]
		table.insert(data, {id = id, name = ChipTools.getAttrName(id), selected = selectPlanOrder == id})
	end
	self.planOrderData:update(data)
	self.planOrderPanel:show()
end

function ChipPlanView:onPlanItemNewClick(panel, node, t, v)
	local plan = self.curChipPlan:read()
	if v.id then
		local function cb()
			gGameApp:requestServer("/game/chip/plan/edit", function()
				self.selectPlanId:set(v.id)
				self:onPlanMaskClose()
			end, v.id, plan)
		end
		local key = "chipPlanItemNewTip"
		local state = userDefault.getCurrDayKey(key, "first")
		if state == "first" then
			state = "true"
			userDefault.setCurrDayKey(key, state)
		end
		if (state == "first" or state == "true") and (not itertools.isempty(v.data.chips)) then
			local name = v.data.name
			gGameUI:showDialog({content = {
				"#C0x5B545B#" .. gLanguageCsv.chipPlanItemNewTip,
				"#C0xF76B45#(" .. name .. ")",
			}, cb = cb, isRich = true, btnType = 2, selectKey = key, selectType = 2, selectTip = gLanguageCsv.todayNoTip})
		else
			cb()
		end
	else
		local plans = self.chipPlans:read()
		local newId = 0
		for i = 1, table.maxn(plans) + 1 do
			if not plans[i] then
				newId = i
				break
			end
		end
		local name = gLanguageCsv.planNew
		gGameApp:requestServer("/game/chip/plan/new", function()
			self:onPlanMaskClose()
		end, plan, name)
	end
end

function ChipPlanView:onPlanItemClick(panel, node, t, v)
	self.selectPlanId:set(v.id)
end

function ChipPlanView:onPlanItemEquipClick(panel, node, t, v)
	self:onPlanEquipClick(v.data)
end

function ChipPlanView:setPlanName(name)
	local selectPlanId = self.selectPlanId:read()
	local plans = self.chipPlans:read()
	if selectPlanId and plans[selectPlanId] then
		self.planNamePanel:show()
		self.planNamePanel:get("name"):text(plans[selectPlanId].name)
		adapt.oneLineCenterPos(cc.p(self.planNamePanel:width()/2, self.planNamePanel:height()/2), {self.planNamePanel:get("name"), self.planNamePanel:get("icon")}, cc.p(10, 0))
	else
		self.planNamePanel:hide()
	end
end

-- 方案名
function ChipPlanView:onPlanNameClick()
	local name
	local selectPlanId = self.selectPlanId:read()
	local plans = self.chipPlans:read()
	if selectPlanId and plans[selectPlanId] then
		name = plans[selectPlanId].name
	end
	gGameUI:stackUI("city.card.changename", nil, nil, {
		typ = "plan",
		name = name,
		noBlackList = true,
		titleTxt = gLanguageCsv.changPlanName,
		requestParams = {self.selectPlanId:read(), nil},
		requestParamsCount = 2,
		customCheck = function(text)
			-- 不能与已有方案名相同
			for id, data in pairs(plans) do
				if text == data.name then
					gGameUI:showTip(gLanguageCsv.planNameSame)
					return false
				end
			end
			return true
		end,
	})
end

-- 新增方案
function ChipPlanView:onRightPlanNewClick()
	self.isPlanAddNew = true
	self.isRefreshPlanPanel:notify()
	self.planMaskView = gGameUI:createView("city.card.chip.plan_mask", self):init({onClose = self:createHandler("onPlanMaskClose")})
end

function ChipPlanView:onPlanMaskClose()
	if self.planMaskView then
		self.planMaskView:onClose()
		self.planMaskView = nil
	end
	self.isPlanAddNew = false
	self.isRefreshPlanPanel:notify()
end

-- 保存方案
function ChipPlanView:onPlanSaveClick()
	gGameApp:requestServer("/game/chip/plan/edit", function()
		gGameUI:showTip(gLanguageCsv.planSaved)
		if self.page == 2 then
			self:onClose()
		else
			self.isRefreshPlanPanel:notify()
		end
	end, self.selectPlanId:read(), self.curChipPlan:read())
end

-- 删除方案
function ChipPlanView:onPlanDeleteClick()
	local selectPlanId = self.selectPlanId:read()
	local function cb()
		gGameApp:requestServer("/game/chip/plan/delete", function()
			self.selectPlanId:set(nil)
			self.isRefreshPlanPanel:notify()
		end, selectPlanId)
	end
	local plans = self.chipPlans:read()
	local key = "chipPlanDeleteTip"
	local state = userDefault.getCurrDayKey(key, "first")
	if state == "first" then
		state = "true"
		userDefault.setCurrDayKey(key, state)
	end
	if (state == "first" or state == "true") and (plans[selectPlanId] and not itertools.isempty(plans[selectPlanId].chips)) then
		local name = plans[selectPlanId].name
		gGameUI:showDialog({content = {
			"#C0x5B545B#" .. gLanguageCsv.chipPlanDeleteTip,
			"#C0xF76B45#(" .. name .. ")",
		}, cb = cb, isRich = true, btnType = 2, selectKey = key, selectType = 2, selectTip = gLanguageCsv.todayNoTip})
	else
		cb()
	end
end

-- 置顶方案
function ChipPlanView:onPlanTopClick()
	gGameApp:requestServer("/game/chip/plan/edit", function()
		self.isRefreshPlanPanel:notify()
	end, self.selectPlanId:read(), nil, nil, true)
end

-- 编辑方案
function ChipPlanView:onPlanEditClick()
	gGameUI:stackUI('city.card.chip.plan', nil, nil, {
		page = 2,
		planId = self.selectPlanId:read(),
		cb = self:createHandler("planEditCb"),
	})
end

function ChipPlanView:planEditCb()
	self.isRefreshPlanPanel:notify()
end

-- 装备方案
function ChipPlanView:onPlanEquipClick(data)
	local function cb()
		local selectCardDBID = self.selectCardDBID:read()
		local chips
		if type(data) ~= "table" then
			chips = self.curChipPlan:read()
		else
			chips = data.chips
		end
		chips = table.deepcopy(chips, true)

		local function equip()
			for i = 1, 6 do
				if not chips[i] then
					chips[i] = -1
				end
			end
			gGameApp:requestServer("/game/card/chip/change", function(tb)
				gGameUI:showTip(gLanguageCsv.exchange2Success)
				-- 自动选择当前精灵方案
				self.selectPlanId:set(nil)
				self.isRefreshPlanPanel:notify()
			end, selectCardDBID, chips)
		end
		-- 当前方案是否被其他精灵携带
		for _, dbId in pairs(chips) do
			local chip = gGameModel.chips:find(dbId)
			local cardDBID = chip:read("card_db_id")
			if cardDBID and cardDBID ~= selectCardDBID then
				gGameUI:stackUI("city.card.chip.plan_equip_tip", nil, nil, {
					chips = chips,
					cb = equip,
				})
				return
			end
		end
		equip()
	end
	-- 弹框提示 当前精灵的芯片未保存为方案，确认装备当前方案？
	if not self.cardChipsPlanId and not itertools.isempty(self.cardChips:read()) then
		gGameUI:showDialog({content = gLanguageCsv.chipPlanEquipTip, cb = cb, btnType = 1, clearFast = true})
	else
		cb()
	end
end

function ChipPlanView:onPlanSuitFilterItemClick(list, node, k, v)
	self.selectPlanSuitId:set(v.suitId, true)
end

function ChipPlanView:onPlanOrderItemClick(list, node, t, v)
	self.selectPlanOrder:set(v.id, true)
end

function ChipPlanView:onEquipShowClick()
	self.equipShow:modify(function(val)
		return true, not val
	end)
end

---- 覆盖重写 ----
function ChipPlanView:onClose()
	if self.page == 2 then
		local id = self.selectPlanId:read()
		local plans = self.chipPlans:read()
		if not itertools.equal(plans[id].chips, self.curChipPlan:read()) then
			gGameUI:showDialog({content = gLanguageCsv.chipPlanBagCloseTip, cb = function()
				ChipBagView.onClose(self)
			end, btnType = 1, clearFast = true})
			return
		end
	end
	ChipBagView.onClose(self)
end

function ChipPlanView:showPanel()
	local plan = self.curChipPlan:read()
	-- 方案界面并且非当前精灵时显示对比属性
	local ret
	if self.page == 1 and not self.showCard:read() then
		ret = ChipTools.getAttrsValueCmp(plan, self.cardChips:read())
	else
		ret = ChipTools.getAttrsValue(plan)
	end
	local attrs = {}
	for _, attr in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
		local key = game.ATTRDEF_ENUM_TABLE[attr]
		if ret[1][key] then
			table.insert(attrs, {attr = attr, key = key, val = ret[1][key]})
		end
	end
	self.baseAttrData:set(attrs)
	self.baseAttrTip:visible(#attrs == 0)

	-- 套装属性
	local suitAttrData = {}
	local suitAttrs = ChipTools.getComplateSuitAttrByCard(plan)
	for _, val in pairs(suitAttrs) do
		-- 最大激活的套件数
		local maxActiveNum = 0
		for _, v in ipairs(val.data) do
			if v[3] then
				maxActiveNum = math.max(maxActiveNum, v[1])
			end
		end
		if maxActiveNum > 0 then
			table.insert(suitAttrData, {suitId = val.suitId, maxActiveNum = maxActiveNum, data = val.data})
		end
	end
	self.suitAttrData:set(suitAttrData)
	self.suitAttrTip:visible(#suitAttrData == 0)
end

function ChipPlanView:setCardDBID(dbId)
	if not dbId then
		return
	end
	local card = gGameModel.cards:find(dbId)
	local cardDatas = card:read("card_id", "skin_id", "level", "star", "advance")
	local cardCfg = csv.cards[cardDatas.card_id]
	local unitCfg = csv.unit[cardCfg.unitID]
	local unitId = dataEasy.getUnitId(cardDatas.card_id, cardDatas.skin_id)
	bind.extend(self, self.cardPanel, {
		class = "card_icon",
		props = {
			unitId = unitId,
			advance = cardDatas.advance,
			rarity = unitCfg.rarity,
			star = cardDatas.star,
			levelProps = {
				data = cardDatas.level,
			},
			onNode = function(panel)
				panel:alignCenter(self.cardPanel:size()):scale(0.9)
			end,
		}
	})

	self.selectPlanId:set(nil)
	self.selectCardDBID:set(dbId)
	-- bind.extend 延迟一帧创建
	performWithDelay(self, function()
		idlereasy.when(self.showCard, function(_, flag)
			self.cardPanel:visible(flag)
			for i = 1, 6 do
				local item = self.chipPanel:getItem(i)
				item:get("effect_line"):visible(not flag):scale(1.2)
			end
		end):anonyOnly(self)
		idlereasy.when(self.curChipPlan, function(_, plan)
			for i = 1, 6 do
				local item = self.chipPanel:getItem(i)
				item:setTouchEnabled(false)
				local dbId = plan[i]
				if dbId then
					local chip = gGameModel.chips:find(dbId)
					local chipData = chip:read("chip_id", "card_db_id", "level")
					local data = {
						dbId = dbId,
						chipId = chipData.chip_id,
						level = chipData.level,
						cfg = csv.chip.chips[chipData.chip_id],
					}
					item:setTouchEnabled(true)
					item:onTouch(functools.partial(self.onCardChipClick, self, item, i, data))
				else
					if self.page == 2 then
						item:setTouchEnabled(true)
						item:onTouch(function(event)
							if event.name == 'ended' then
								self.selectLeftPos:set(i)
								self.selectRightPos:set(i)
							end
						end)
					end
				end
			end
		end):anonyOnly(self)
	end, 0)
end

-- 显示所有芯片，已装备的芯片置灰显示
function ChipPlanView:refreshLeftPanel()
	if self.page == 1 then
		return
	end
	local roleChips = self.roleChips:read()
	local selectLeftPos = self.selectLeftPos:read()
	local selectSuitId = self.selectSuitId:read()
	local selectAttrIds = self.selectAttrIds:read()
	local equipShow = self.equipShow:read()
	local data = {}
	local flags = {} -- 筛选后的芯片可以镶嵌的位置

	local function filter(cfg, dbId)
		if selectLeftPos and selectLeftPos ~= cfg.pos then
			return false
		end
		if selectSuitId and selectSuitId ~= cfg.suitID then
			return false
		end
		if itertools.size(selectAttrIds) > 0 then
			local _, secondAttrs = ChipTools.getAttrs({dbId})
			for id, _ in pairs(selectAttrIds) do
				-- 副属性中 固定值或百分比没有该属性过滤掉
				if not secondAttrs[1][id] and not secondAttrs[2][id] then
					return false
				end
			end
		end
		return true
	end

	local planHash = itertools.map(self.curChipPlan:read(), function(k, v) return v, true end)
	for idx, dbId in ipairs(roleChips) do
		local chip = gGameModel.chips:find(dbId)
		local chipData = chip:read("chip_id", "card_db_id", "level", "locked")
		local cfg = csv.chip.chips[chipData.chip_id]

		local unitId = nil
		if chipData.card_db_id then
			local cardData = gGameModel.cards:find(chipData.card_db_id)
			unitId = dataEasy.getUnitId(cardData:read("card_id"), cardData:read("skin_id"))
		end
		if filter(cfg, dbId) then
			data[dbId] = {
				idx = idx, -- 用于排序有序显示
				dbId = dbId,
				unitId = unitId,
				chipId = chipData.chip_id,
				level = chipData.level,
				locked = chipData.locked,
				equipShow = equipShow,
				cfg = cfg,
				-- 若当前方案中置灰显示
				grayState = planHash[dbId] and 1 or 0,
			}
			if selectSuitId then
				flags[cfg.pos] = true
			end
		end
	end
	dataEasy.tryCallFunc(self.bagList, "updatePreloadCenterIndexAdaptFirst")
	self.bagData:update(data)
	self.slotFlags:set(flags)
	self.empty:visible(itertools.size(data) == 0)
end

function ChipPlanView:onItemTouch(list, node, t, v, event)
	if event.name == 'ended' or event.name == 'cancelled' then
		if not self.moved then
			self:showDetails(list, node, nil, v.dbId, nil, self.curChipPlan)
			return
		end
		self:resetSelected()
		if self.movePanel then
			self:deleteMovingItem()
			for i = 1, 6 do
				local item = self.chipPanel:getItem(i)
				local rect = item:box()
				local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
				rect.x, rect.y = pos.x, pos.y
				rect.width, rect.height = rect.width * self.chipPanel:scale(), rect.height * self.chipPanel:scale()
				if cc.rectContainsPoint(rect, event) then
					if i == v.cfg.pos then
						self.curChipPlan:modify(function(data)
							data[i] = v.dbId
							return true, data
						end)
						self.isRefreshBagPanel:notify()
					else
						gGameUI:showTip(gLanguageCsv.chipSlotError)
					end
					return
				end
			end
		end
	else
		ChipBagView.onItemTouch(self, list, node, t, v, event)
	end
end

function ChipPlanView:onCardChipClick(node, idx, v, event)
	if self.page == 1 then
		if event.name == 'ended' then
			self.selectRightPos:set(idx)
			self:showDetails(list, node, idx, v.dbId)
		end
		return
	end
	if event.name == 'ended' or event.name == 'cancelled' then
		if not self.moved then
			self.selectLeftPos:set(idx)
			self.selectRightPos:set(idx)
			self:showDetails(list, node, idx, v.dbId, nil, self.curChipPlan)
			return
		end
		self:resetSelected()
		if self.movePanel then
			self:deleteMovingItem()
			local rect = self.bagList:box()
			local pos =  self.bagList:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))
			rect.x, rect.y = pos.x, pos.y
			if cc.rectContainsPoint(rect, event) then
				self.curChipPlan:modify(function(data)
					data[idx] = nil
					return true, data
				end)
				self.isRefreshBagPanel:notify()
			end
		end
	else
		ChipBagView.onCardChipClick(self, node, idx, v, event)
	end
end

function ChipPlanView:onBaseAttrDetailClick()
	local plan = self.curChipPlan:read()

	if self.page == 1 and not self.showCard:read() then
		gGameUI:stackUI('city.card.chip.total_detail', nil, nil, {typ = 2, curPlan = plan, cardPlan = self.cardChips:read()})
	else
		gGameUI:stackUI('city.card.chip.total_detail', nil, nil, {typ = 1, cardPlan = plan})
	end
end

function ChipPlanView:onSuitAttrDetailClick()
	gGameUI:stackUI('city.card.chip.suit_detail', nil, nil, self.curChipPlan:read())
end

return ChipPlanView