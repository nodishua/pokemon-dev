-- @date:   2019-08-07
-- @desc:   探险界面
local ViewBase = cc.load("mvc").ViewBase
local ExploreView = class("ExploreView", ViewBase)
local ExplorerTools = require "app.views.city.develop.explorer.tools"
local redHintHelper = require "app.easy.bind.helper.red_hint"

local LIST1MARGIN = 20 -- list1 间隔

ExploreView.RESOURCE_FILENAME = "explore_view.json"
ExploreView.RESOURCE_BINDING = {
	["bottomPanel.item"] = "bottomItem",
	["bottomPanel"] = "bottomPanel",
	["bottomPanel.list"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("bottomData"),
				item = bindHelper.self("bottomItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local panel = node:get("panel")
					local childs = panel:multiget("icon", "lock", "selected", "name", "bg")
					childs.name:text(v.cfg.name)
					childs.icon:texture(v.cfg.simpleIcon)
					childs.bg:texture("city/develop/explore/panel_icon_tx"..v.cfg.quality..".png")
					if v.advance == 0 then
						childs.name:text(v.cfg.name)
					else
						childs.name:text(v.cfg.name..string.format(" +%d", v.advance))
					end
					adapt.setTextScaleWithWidth(childs.name, nil, 450)
					text.addEffect(childs.name, {outline = {color = ui.COLORS.QUALITY[v.cfg.quality], size = 4}, color = ui.COLORS.OUTLINE.WHITE})
					if v.advance == 0 then
						if v.selected then
							childs.lock:texture("common/btn/btn_lock_big.png")
							childs.lock:scale(1)
						else
							childs.lock:texture("city/develop/talent/btn_lock.png")
							childs.lock:scale(0.75)
						end
					end

					list.state = v.selected ~= true
					local props = {
						class = "red_hint",
						props = {
							specialTag = "explorerShow",
							state = bindHelper.self("state"),
							listenData = {
								-- originData = bindHelper.parent("bottomData"),
								id = v.id,
							},
							onNode = function (node)
								node:xy(panel:size().width - 9,panel:size().height - 5)
							end
						}
					}
					bind.extend(list, node, props)
					childs.lock:visible(v.advance == 0)
					cache.setShader(childs.icon, false, v.advance == 0 and "gray" or "normal")
					bind.touch(list, panel, {methods = {
						ended = functools.partial(list.clickCell, k, v)
					}})
					childs.selected:visible(v.selected == true)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["upLeftPanel.icon"] = "icon",
	["upRightPanel.name"] = "nodeName",
	["upRightPanel.upList"] = "upList",
	["upRightPanel.downList"] = "downList",
	["upLeftPanel.componentPanel"] = "componentPanel",
	["upLeftPanel.btnDecompose"] = {
		varname = "btnDecompose",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDecomposeClick")}
		},
	},
	["upLeftPanel.btnShop"] = {
		varname = "btnShop",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShopClick")}
		},
	},
	["upLeftPanel.btnDecompose.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.WHITE}},
		},
	},
	["upLeftPanel.btnFind"] = {
		varname = "btnFind",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onFindClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "explorerFind",
				}
			}
		},
	},
	["upLeftPanel.btnFind.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.WHITE}},
		},
	},
	["upLeftPanel.btnShop.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.WHITE}},
		},
	},
	["upLeftPanel.btnRule"] = {
		varname = "btnRule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")}
		},
	},
	["upLeftPanel.btnRule.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.WHITE}},
		},
	},
	["upRightPanel.btn.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["componentPanel"] = "componentDetailPanel",
	["mask"] = {
		varname = "mask",
		binds = {
			event = "click",
			method = bindHelper.self("onMaskClick"),
		},
	},
	["componentPanel.otherPanel"] = "otherPanel",
	["componentPanel.upgradePanel"] = "upgradePanel",
	["componentPanel.otherPanel.item"] = "otherItem",
	["componentPanel.otherPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("componentData"),
				dataOrderCmp = function (a, b)
					return a.attrType < b.attrType
				end,
				item = bindHelper.self("otherItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("name", "left", "max")
					local attrNum = v.attrNum[v.level == 0 and 1 or v.level]
					childs.name:text(getLanguageAttr(v.attrType))
					childs.left:text("+"..dataEasy.getAttrValueString(v.attrType, attrNum))
					childs.max:visible(v.isMax == true)
					adapt.oneLinePos(childs.left, childs.max, cc.p(30, 0))
					if string.utf8len(getLanguageAttr(v.attrType)) > 4 then
						adapt.oneLinePos(childs.name, {childs.left, childs.max}, {cc.p(5,0), cc.p(30, 0)})
					else
						adapt.oneLinePos(childs.name, {childs.left, childs.max}, {cc.p(100,0), cc.p(30, 0)})
					end
				end,
			},
		},
	},
	["componentPanel.upgradePanel.item"] = "upgradeItem",
	["componentPanel.upgradePanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("componentData"),
				dataOrderCmp = function (a, b)
					return a.attrType < b.attrType
				end,
				item = bindHelper.self("upgradeItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("name", "left", "right")
					local attrNum1 = v.attrNum[v.level == 0 and 1 or v.level]
					local attrNum2 = v.attrNum[v.level + 1]
					childs.name:text(getLanguageAttr(v.attrType))
					local fontSize = string.utf8len(getLanguageAttr(v.attrType)) > 5 and (40 - 5*(string.utf8len(getLanguageAttr(v.attrType))-5)) or 40
					childs.name:setFontSize(fontSize)
					childs.left:text(dataEasy.getAttrValueString(v.attrType, attrNum1))
					if attrNum2 then
						childs.right:text(dataEasy.getAttrValueString(v.attrType, attrNum2))
					else
						childs.right:text("")
					end
				end,
			},
		},
	},
	["componentPanel.upgradePanel.item1"] = "item1",
	["componentPanel.upgradePanel.list1"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("upgradeData"),
				margin = LIST1MARGIN,
				item = bindHelper.self("item1"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("add", "mask")
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = v.num,
								targetNum = v.targetNum
							},
							grayState = v.targetNum > v.num and 3 or 0,
							onNode = function (node)
								if v.targetNum > v.num then
									bind.click(list, node, {method =  functools.partial(list.clickCell, k, v)})
								end
							end
						},
					})
					childs.mask:hide()
					childs.add:hide()
					childs.add:visible(v.targetNum > v.num)
					childs.mask:texture(dataEasy.getIconResByKey(v.id)):scale(2)
				end,
				onAfterBuild = function(list)
					list.afterBuild()
					list:setClippingEnabled(false)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemMaskClick"),
				afterBuild = bindHelper.self("onList1AfterBuild"),
			},
		},
	},
	["upRightPanel.btn"] = {
		varname = "btnRight",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRightClick")}
		},
	},
	["upLeftPanel.btn"] = "btnLeft",
	["upLeftPanel.btnEffect"] = {
		varname = "btnEffect",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRightClick")}
		},
	},
	["upRightPanel.maxPanel"] = "maxPanel",
	["upRightPanel.activeTip"] = "activeTip",
	["flip1"] = "flip1",
	["flip2"] = "flip2",
	["flip3"] = "flip3",
	["flip4"] = "flip4",
	["upLeftPanel.linePanel"] = "linePanel",
	["bottomPanel.bg"] = "bottomBg",
	["upLeftPanel"] = "upLeftPanel",
}

function ExploreView:onCreate(drawType)
	adapt.centerWithScreen("left", "right", nil, {
		{self.listview, "width"},
		{self.listview, "pos", "left"},
		{self.bottomBg, "width"},
		{self.bottomBg, "pos", "left"},
	})
	self.bottomBg:x(self.listview:x()+self.listview:size().width/2)

	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")}):init(
		{title = gLanguageCsv.explorer, subTitle = "EXPLORER"})
	self:initModel()

	-- 激活/进阶特效
	self.kejihuoEffect = widget.addAnimationByKey(self.btnEffect, "jinjie/kejinjiekejiesuo.skel", 'kejihuoEffect', "kejihuo_loop", 99)
		:xy(self.btnEffect:width()/2, self.btnEffect:height()/2)
		:scale(1.3)

	local t = {}
	for k,v in orderCsvPairs(csv.explorer.explorer) do
		local newT = {id = k, cfg = v, advance = 0}
		for index, component in ipairs(v.componentIDs) do
			local componentCfg = csv.explorer.component[component]
			newT.components = newT.components or {}
			local level = 0
			newT.components[componentCfg.componentPosID] = {
				id = component,
				count = 0,
				level = level,
			}
		end
		table.insert(t, newT)
	end
	self.bottomData = idlers.newWithMap(t)
	self.components = idlertable.new({})
	self.showTab = idler.new(self._showTab or 1)
	idlereasy.any({self.explores, self.items}, function (_, explorers, items)
		local t = {}
		for i, explore in self.bottomData:ipairs() do
			for index, component in ipairs(explore:proxy().components) do
				local componentCfg = csv.explorer.component[component.id]
				local level = component.level
				if explorers[i] and explorers[i].components[component.id] then
					level = explorers[i].components[component.id]
					explore:proxy().components[index].level = level
				end
				explore:proxy().components[index].count = items[componentCfg.itemID] or 0
				table.insert(t, {id = component.id, count = items[componentCfg.itemID] or 0})
			end
			if explorers[explore:proxy().id] and explorers[explore:proxy().id].advance then
				explore:proxy().advance = explorers[explore:proxy().id].advance or 0
			end
		end
		self.components:set(t)
		self.showTab:set(self.showTab:read(), true)
	end)
	self.showTab:addListener(function (val, oldval)
		self.bottomData:atproxy(oldval).selected = false
		self.bottomData:atproxy(val).selected = true
		local proxy = self.bottomData:atproxy(val)
		if self.upLeftPanel:get("explorer") then
			self.upLeftPanel:removeChildByName("explorer")
		end

		-- 背景特效
		self:getResourceNode():removeChildByName("bgEffect")
		self.bgEffect = widget.addAnimationByKey(self:getResourceNode(), proxy.cfg.bg, 'bgEffect', "effect_loop", -1)
			:xy(self:getResourceNode():width()/2, self:getResourceNode():height()/2)
			:scale(2)

		local isNotActive = proxy.advance == 0

		if string.find(proxy.cfg.res, "skel") then
			self.icon:hide()
			local spine = widget.addAnimationByKey(self.upLeftPanel, proxy.cfg.res, "explorer", "effect_loop", 2)
			if proxy.cfg.coordinate then
				spine:xy(proxy.cfg.coordinate.x or 700, proxy.cfg.coordinate.y or 500)
					:scale(proxy.cfg.coordinate.scale or 2.5)
			else
				spine:xy(700, 500)
					:scale(2.5)
			end
			spine:setTimeScale(isNotActive and 0 or 1)
			cache.setShader(spine, false, isNotActive and "gray" or "normal")
		else
			self.icon:show()
			self.icon:texture(proxy.cfg.res)
		end
		local minLevel = ExplorerTools.getMinComponentLevel(proxy.components)
		if isNotActive then
			self.nodeName:text(proxy.cfg.name)
			self.btnLeft:get("mask"):visible(minLevel == 0)
			self.btnRight:get("txt"):text(gLanguageCsv.spaceActive)
			if minLevel == 0 then
				self.btnLeft:get("txt"):text(gLanguageCsv.notActivatedTip)
				text.deleteAllEffect(self.btnLeft:get("txt"))
				text.addEffect(self.btnLeft:get("txt"),{color = ui.COLORS.NORMAL.GRAY})
			else
				self.btnLeft:get("txt"):text(gLanguageCsv.canActive)
				text.addEffect(self.btnLeft:get("txt"), {glow = {color = ui.COLORS.GLOW.WHITE}})
				text.addEffect(self.btnLeft:get("txt"),{color = ui.COLORS.NORMAL.WHITE})
			end
			adapt.setTextScaleWithWidth(self.btnLeft:get("txt"), nil, 180)
		else
			self.btnLeft:get("mask"):hide()
			self.btnRight:get("txt"):text(gLanguageCsv.spaceAdvance)
			self.nodeName:text(proxy.cfg.name..string.format(" +%d", proxy.advance))
			text.addEffect(self.btnLeft:get("txt"),{color = ui.COLORS.NORMAL.WHITE})
		end
		text.addEffect(self.nodeName, {color = ui.COLORS.QUALITY[proxy.cfg.quality]})
		adapt.setTextAdaptWithSize(self.activeTip, {size = cc.size(650, 80), vertical = "bottom", horizontal = "center"})
		local isShow = false
		if isNotActive and minLevel == 0 then
			self.activeTip:text(gLanguageCsv.collectAllComponentsCanActive)
			isShow = true
		elseif proxy.advance >= minLevel then
			self.activeTip:text(string.format(gLanguageCsv.allComponentsNeedLevelCondition, proxy.advance + 1))
			isShow = true
		end
		adapt.setTextAdaptWithSize(self.activeTip, {size = cc.size(650, 80), vertical = "bottom", horizontal = "center"})
		self.activeTip:setAnchorPoint(0.5, 0.5)

		local isMaxAdvance = proxy.advance == proxy.cfg.levelMax

		local itemEnough = true  -- 进阶道具是否足够(默认为true)
		if not isMaxAdvance then -- 满级不需要再判断itemEnough
			for k, v in csvMapPairs(csv.explorer.explorer_advance[proxy.advance + 1]["costItemMap"..proxy.cfg.advanceCostSeq]) do
				if itemEnough then
					itemEnough = dataEasy.getNumByKey(k) >= v  -- 当其中一种材料不足时，判定道具不足
				end
			end
		end
		self.activeTip:visible(isShow and not isMaxAdvance)
		self.maxPanel:visible(isMaxAdvance)
		self.btnRight:visible(not isMaxAdvance)
		self.btnLeft:visible(isNotActive and minLevel == 0)
		self.btnEffect:visible(isNotActive and minLevel > 0 and itemEnough) -- 未激活状态
		self.kejihuoEffect:play("kejihuo_loop")
		self:setComponentPanel(proxy.advance)
		ExplorerTools.effectShow(self.upList, self.downList, proxy)

		-- 是否可进阶
		if not isNotActive and not isShow and not isMaxAdvance and itemEnough then
			self.btnEffect:visible(true)
			self.kejihuoEffect:play("kejinjie_loop")
		end
	end)
	self.componentData = idlertable.new({})
	self.upgradeData = idlertable.new({})
end

function ExploreView:onCleanup()
	self._showTab = self.showTab:read()
	ViewBase.onCleanup(self)
end

function ExploreView:setComponentPanel(advance)
	for i = 1, 6 do
		if self.componentPanel:get(i) then
			self.componentPanel:get(i):hide()
		end
	end
	self.linePanel:removeAllChildren()
	local data = self.bottomData:atproxy(self.showTab:read())
	for i,v in ipairs(data.components) do
		local cfg = csv.explorer.component[v.id]
		local line = self["flip"..cfg.componentLine.flip]:clone():show()
				:size(cfg.componentsize, 92)
				:addTo(self.linePanel)
				:xy(cfg.componentLine.x, cfg.componentLine.y)
		local panel = self:initComponent(i, v, data.cfg.levelMax, advance)
				:xy(cfg.coordinate.x, cfg.coordinate.y)
				:show()
				:anchorPoint(0.5, 0.5)
				:setTouchEnabled(true)
		cache.setShader(line, false, v.level == 0 and "gray" or "normal")
		bind.touch(self, panel, {methods = {ended = function()
			if v.count > 0 and v.level == 0 then
				gGameApp:requestServer("/game/explorer/component/strength",function (tb)
					gGameUI:stackUI("city.develop.explorer.component_success", nil, {blackLayer = true, clickClose = true}, v)
				end, v.id)
			else
				self:componentDetailShow(i, v, data.cfg, advance)
				self.mask:show()
			end
		end}})
	end
end

function ExploreView:detailSendParams()
	local proxy = self.bottomData:atproxy(self.showTab:read())
	return proxy
end

function ExploreView:componentDetailShow(index, componentData, explorer, advance)
	self.componentDetailPanel:show()
	local itemPos = self.componentDetailPanel:get("itemPos")
	local cfg = csv.explorer.component[componentData.id]
	local itemCfg = csv.items[cfg.itemID]
	local boxRes = string.format("city/card/helditem/panel_icon_%d.png", itemCfg.quality)
	local size = itemPos:size()
	local imgBG = itemPos:get("bg")
	if not imgBG then
		imgBG = ccui.ImageView:create()
			:alignCenter(size)
			:addTo(itemPos, 1, "bg")
	end
	imgBG:texture(boxRes)
	local icon = itemPos:get("icon")
	if not icon then
		icon = ccui.ImageView:create()
			:alignCenter(size)
			:scale(2)
			:addTo(itemPos, 2, "icon")
	end
	icon:texture(itemCfg.icon)
	itemPos:scale(1.2)

	local str = gLanguageCsv.attributeAdd
	local newStr1
	if cfg.attrTarget and csvSize(cfg.attrTarget) > 0 then
		local t = {}
		for i,v in ipairs(cfg.attrTarget) do
			table.insert(t, "#I"..ui.ATTR_ICON[v].."-60-60#")
		end
		local newStr = table.concat(t)
		newStr1 = string.format(str, newStr)
	else
		newStr1 = string.format(str, gLanguageCsv.allTeamActive)
	end
	local t = {}
	for i = 1, 10 do
		if cfg["attrNumType"..i] and cfg["attrNumType"..i] ~= 0 then
			table.insert(t, {
				attrType = cfg["attrNumType"..i],
				attrNum = cfg["attrNum"..i],
				level = componentData.level or 0,
			})
		else
			break
		end
	end
	self.componentData:set(t)

	if componentData.level == 0 then
		--未激活
		self.otherPanel:show()
		local childs = self.otherPanel:multiget("name", "nameMax", "txtPos", "maxPanel", "noCom", "btnPath")
		itertools.invoke({self.upgradePanel, childs.nameMax, childs.maxPanel}, "hide")
		local name = uiEasy.setIconName(cfg.itemID, nil, {node = childs.name})
		childs.txtPos:removeAllChildren()
		childs.noCom:visible(componentData.count == 0)
		if componentData.count == 0 then
			local richtext = rich.createByStr(newStr1, 40, nil, nil, cc.p(0, 0.5))
			richtext:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
			richtext:addTo(childs.txtPos)
				:alignCenter(childs.txtPos:size())
			bind.touch(self, childs.btnPath, {
				methods = {
					ended = function ()
						gGameUI:stackUI("common.gain_way", nil, nil, cfg.itemID)
					end
				}
			})
			text.addEffect(childs.btnPath:get("txt"), {glow = {color = ui.COLORS.GLOW.WHITE}})
			childs.btnPath:show()
		end
	elseif componentData.level == explorer.levelMax then
		self.otherPanel:show()
		local childs = self.otherPanel:multiget("name", "nameMax", "txtPos", "noCom", "btnPath")
		childs.txtPos:removeAllChildren()
		self.upgradePanel:hide()
		childs.name:hide()
		local name = uiEasy.setIconName(cfg.itemID, nil, {node = childs.nameMax:get("name")})
		childs.nameMax:get("level"):text("Lv"..componentData.level)
		adapt.oneLineCenterPos(cc.p(270, 40), {childs.nameMax:get("name"), childs.nameMax:get("level")}, cc.p(15, 0))
		childs.noCom:hide()
		childs.btnPath:hide()
		local richtext = rich.createByStr(newStr1, 40, nil, nil, cc.p(0, 0.5))
		richtext:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
		richtext:addTo(childs.txtPos)
			:alignCenter(childs.txtPos:size())
	else
		self.otherPanel:hide()
		self.upgradePanel:show()
		local childs = self.upgradePanel:multiget("name", "txtPos", "btnPath", "level")
		childs.txtPos:removeAllChildren()
		local name = uiEasy.setIconName(cfg.itemID, nil, {node = childs.name})
		childs.level:text("Lv"..componentData.level)
		adapt.setTextScaleWithWidth(childs.name, nil, 555)
		adapt.oneLineCenterPos(cc.p(self.upgradePanel:width()/2, childs.name:y()), {childs.name, childs.level}, cc.p(20, 0))
		local richtext = rich.createByStr(newStr1, 40, nil, nil, cc.p(0, 0.5))
		richtext:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
		richtext:addTo(childs.txtPos)
			:alignCenter(childs.txtPos:size())
		local t = {}
		local isCanUp = true
		for k, v in csvMapPairs(csv.explorer.component_level[componentData.level + 1]["costItemMap"..cfg.strengthCostSeq]) do
			table.insert(t, {key = k, id = k, targetNum = v, num = dataEasy.getNumByKey(k)})
			if isCanUp then
				isCanUp = dataEasy.getNumByKey(k) >= v
			end
		end

		childs.btnPath:loadTextureNormal(isCanUp and "common/btn/btn_normal.png" or "common/btn/btn_recharge.png")
		text.addEffect(childs.btnPath:get("txt"), {color = isCanUp and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED})
		text.deleteAllEffect(childs.btnPath:get("txt"))
		if isCanUp and advance > 0 then
			text.addEffect(childs.btnPath:get("txt"), {glow = {color = ui.COLORS.GLOW.WHITE}})
		end
		self.upgradeData:set(t)
		bind.touch(self, childs.btnPath, {
			methods = {
				ended = function ()

					if isCanUp then
						gGameApp:requestServer("/game/explorer/component/strength",function (tb)
							local data = self.bottomData:atproxy(self.showTab:read())
							self:componentDetailShow(index, data.components[index], data.cfg, advance)
							gGameUI:stackUI("city.develop.explorer.component_success", nil, {blackLayer = true, clickClose = true}, data.components[index])
						end, componentData.id)
					else
						gGameUI:showTip(gLanguageCsv.inadequateProps)
					end
				end
			}
		})
	end
end

local function createForeverAnim(x, y)
	return cc.RepeatForever:create(
		cc.Sequence:create(
			cc.DelayTime:create(0.1),
			cc.MoveTo:create(0.3, cc.p(x, y + 10)),
			cc.DelayTime:create(0.1),
			cc.MoveTo:create(0.3, cc.p(x, y))
		)
	)
end

function ExploreView:initComponent(pos, data, levelMax, advance)
	local panel, imgBG, imgSel, imgArrow, frameNode, icon
	if not self.componentPanel:get(pos) then
		local panelSize = cc.size(198, 198)
		panel = ccui.Layout:create()
			:size(198, 198)
			:addTo(self.componentPanel, 1, pos)
		imgBG = ccui.ImageView:create(ui.QUALITY_BOX[1])
			:alignCenter(panelSize)
			:addTo(panel, 1, "bg")
		imgSel = ccui.ImageView:create("common/box/box_selected.png")
			:alignCenter(panelSize)
			:visible(false)
			:addTo(panel, -1, "imgSel")
		imgArrow = ccui.ImageView:create("common/icon/icon_up.png")
			:alignCenter(panelSize)
			:xy(170, 40)
			:scale(0.8)
			:visible(true)
			:addTo(panel, 5, "imgArrow")
		frameNode = ccui.ImageView:create()
			:xy(30, 99)
			:addTo(panel, 3, "frame")
		icon = ccui.ImageView:create()
			:alignCenter(panelSize)
			:scale(2)
			:addTo(panel, 2, "icon")
	else
		panel = self.componentPanel:get(pos)
		imgBG = panel:get("bg")
		imgSel = panel:get("imgSel")
		imgArrow = panel:get("imgArrow")
		icon = panel:get("icon")
		frameNode = panel:get("frame")
	end
	panel:show()
	local size = panel:size()
	local labelLv = panel:get("txtLv")
	if not labelLv then
		labelLv = cc.Label:createWithTTF("Lv", ui.FONT_PATH, 30)
			:align(cc.p(1, 0), 150, 10)
			:addTo(panel, 2, "txtLv")

		text.addEffect(labelLv, {outline={color=ui.COLORS.OUTLINE.DEFAULT}})
	end

	local txtLvNum = panel:get("txtLvNum")
	if not txtLvNum then
		txtLvNum = cc.Label:createWithTTF("", ui.FONT_PATH, 30)
			:align(cc.p(1, 0), 160, 10)
			:addTo(panel, 2, "txtLvNum")

		text.addEffect(txtLvNum, {outline={color=ui.COLORS.OUTLINE.DEFAULT}})
	end
	local cfg = csv.explorer.component[data.id]
	local itemCfg = csv.items[cfg.itemID]
	local boxRes = string.format("city/card/helditem/panel_icon_%d.png", itemCfg.quality)
	imgBG:texture(boxRes)
	icon:texture(itemCfg.icon)
	local txtNoGain = panel:get("txtNoGain")

	if not txtNoGain then
		txtNoGain = cc.Label:createWithTTF(gLanguageCsv.noGet, ui.FONT_PATH, 40)
			:align(cc.p(0.5, 0), 98, 10)
			:addTo(panel, 7, "txtNoGain")

		text.addEffect(txtNoGain, {outline={color=ui.COLORS.OUTLINE.WHITE}, color = ui.COLORS.NORMAL.DEFAULT})
	end

	local imgCanActive = panel:get("imgCanActive")
	if not imgCanActive then
		imgCanActive = ccui.ImageView:create("city/develop/explore/txt_kjh.png")
			:alignCenter(size)
			:xy(100, 40)
			:addTo(panel, 7, "imgCanActive")
	end
	txtNoGain:hide()
	imgCanActive:hide()

	panel:get("txtLvNum"):text(data.level)
	if data.level == 0 then
		itertools.invoke({labelLv, txtLvNum, imgArrow}, "hide")
		if data.count > 0 then
			imgCanActive:show()
		else
			txtNoGain:show()
		end
		cache.setShader(icon, false, "gray")
	else
		itertools.invoke({labelLv, txtLvNum}, "show")
		local haveArrow = true
		if levelMax == data.level then
			haveArrow = false
			panel:get("txtLvNum"):text(data.level.." Max")
		else
			for k, v in csvMapPairs(csv.explorer.component_level[data.level + 1]["costItemMap"..cfg.strengthCostSeq]) do
				if dataEasy.getNumByKey(k) < v then
					haveArrow = false
					break
				end
			end
		end
		imgArrow:visible(haveArrow)
		panel.action = panel.action or createForeverAnim(170, 40)
		imgArrow:stopAction(panel.action)
		if haveArrow then
			panel.action = createForeverAnim(170, 40)
			imgArrow:runAction(panel.action)
		end
		cache.setShader(icon, false, "normal")
	end
	if data.level == levelMax then
		adapt.oneLineCenterPos(cc.p(100,0), {labelLv, txtLvNum}, cc.p(0,0))
	else
		adapt.oneLinePos(imgArrow, {txtLvNum, labelLv}, nil, "right")
	end
	return panel
end

function ExploreView:onDecomposeClick()
	gGameUI:stackUI("city.develop.explorer.decompose", nil, nil, self:createHandler("sendParams"))
end

function ExploreView:initModel()
	self.explores = gGameModel.role:getIdler("explorers")
	self.items = gGameModel.role:getIdler("items")
end

function ExploreView:sendParams()
	return self.components
end

function ExploreView:onItemClick(list, k, v)
	self.showTab:set(k)
end

function ExploreView:onMaskClick()
	self.mask:hide()
	self.componentDetailPanel:hide()
end

function ExploreView:onItemMaskClick(list, k, v)
	gGameUI:stackUI("common.gain_way", nil, nil, v.id, nil, v.targetNum)
end

function ExploreView:onBtnRightClick()
	gGameUI:stackUI("city.develop.explorer.detail", nil, nil, self:createHandler("detailSendParams"))
end

function ExploreView:onFindClick()
	gGameUI:stackUI("city.develop.explorer.draw_item.view", nil, nil)
end

function ExploreView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1150})
end

function ExploreView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.explorer)
		end),
		c.noteText(67001, 67007),
	}
	return context
end

function ExploreView:onShopClick()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/explorer/shop/get", function()
			gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.EXPLORER_SHOP)
		end)
	end
end

function ExploreView:onList1AfterBuild()
	local margin = LIST1MARGIN
	local itemWidth = self.item1:width()
	local itemNums = self.upgradeData:size()
	self.list1:width(itemWidth*itemNums + margin*(itemNums - 1))
	self.list1:x(self.upgradePanel:width()/2 - self.list1:width()/2)
end

return ExploreView


