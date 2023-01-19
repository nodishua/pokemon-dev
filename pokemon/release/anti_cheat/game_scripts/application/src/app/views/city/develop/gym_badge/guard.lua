-- @Date:   2020-08-3
-- @Desc: 徽章守护精灵界面
local ViewBase = cc.load("mvc").ViewBase
local gymBadgeGuardView = class("gymBadgeGuardView", ViewBase)

gymBadgeGuardView.RESOURCE_FILENAME = "gym_badge_guard.json"
gymBadgeGuardView.RESOURCE_BINDING = {
	["subList"] = "subList",
	["item"] = "item",
	["slider"] = "slider",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("guardData"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				sliderBg = bindHelper.self("slider"),
				columnSize = 3,
				onCell = function(list, node, k, v)
					local childs = node:multiget("bgPanel", "textAttr", "icon1", "icon", "rarity", "btn1", "btn2", "add", "txt", "btnPanel")
					list:setScrollBarEnabled(false)
					node:setTouchEnabled(true)
					local skinAction = childs.bgPanel:get("skinAction")
					bind.touch(list, childs.bgPanel, {methods = {ended = functools.partial(list.showDetail, node, list:getIdx(k).k, v)}})
					childs.bgPanel:get("add"):hide()
					childs.txt:hide()
					childs.btnPanel:hide()
					childs.bgPanel:removeChildByName("suoEffect")
					if v.id ~= 0 then
						childs.textAttr:show()
						childs.rarity:show()
						childs.icon:show()
						childs.btn1:show()
						childs.btn2:show()
						childs.bgPanel:get("bg"):show()
						childs.bgPanel:get("bg1"):hide()
						childs.bgPanel:get("imgCk"):show()
						local csvUnit = dataEasy.getUnitCsv(v.id, v.skinId)

						if skinAction then
							skinAction:removeFromParent()
						end
						skinAction = widget.addAnimation(childs.bgPanel, csvUnit.unitRes, "standby_loop", 11)
							:scale(1.8)
							:xy(190,150)
							:name("skinAction")

						skinAction:setSkin(csvUnit.skin)
						childs.textAttr:text(csvUnit.name)
						childs.rarity:texture(ui.RARITY_ICON[csvUnit.rarity])
						childs.icon:texture(ui.ATTR_ICON[csvUnit.natureType])
						if csvUnit.natureType2 then
							childs.icon1:show()
							childs.icon1:texture(ui.ATTR_ICON[csvUnit.natureType2])
						else
							childs.icon1:hide()
						end
						adapt.oneLineCenterPos(cc.p(300, 133), {childs.rarity, childs.textAttr, childs.icon, childs.icon1}, cc.p(15, 0))
						bind.touch(list, childs.btn1, {methods = {ended = functools.partial(list.chanceSetUp, list:getIdx(k).k, v)}})
						bind.touch(list, childs.btn2, {methods = {ended = functools.partial(list.setUp, list:getIdx(k).k, v)}})

					else
						childs.textAttr:hide()
						childs.rarity:hide()
						childs.icon:hide()
						childs.icon1:hide()
						childs.btn1:hide()
						childs.btn2:hide()
						childs.bgPanel:get("bg"):hide()
						childs.bgPanel:get("bg1"):show()
						childs.bgPanel:get("imgCk"):hide()
						if skinAction then
							skinAction:hide()
						end
						if v.isOpen == true then
							childs.bgPanel:get("add"):show()
							childs.txt:show()
							childs.txt:text(gLanguageCsv.choosePokemon)
						else
							if v.isFee == true then
								widget.addAnimationByKey(childs.bgPanel, "daoguanhuizhang/jiesuo.skel", "suoEffect", "suo_loop", 1)
									:xy(190, 180)
									:scale(2)
								childs.btnPanel:show()
								bind.touch(list, childs.btnPanel:get("btn"), {methods = {ended = functools.partial(list.openLock, node, list:getIdx(k).k, v)}})
								local txt = ""
								for k, v in ipairs(v.openCost) do
									if v.key == "rmb" then
										if v.bool then
											txt = txt.."#C0x5b545b#"..v.num.." #Icommon/icon/icon_diamond.png-56-56# "
										else
											txt = txt.."#C0xF13B54#"..v.num.." #Icommon/icon/icon_diamond.png-56-56# "
										end
									elseif v.key == "gold" then
										if v.bool then
											txt = txt.."#C0x5b545b#"..v.num.."# Icommon/icon/icon_gold.png-56-56# "
										else
											txt = txt.."#C0xF13B54#"..v.num.." #Icommon/icon/icon_gold.png-56-56# "
										end
									else
										if v.bool then
											txt = txt.."#C0x5b545b#"..v.num.." #I"..v.icon.."-56-56# "
										else
											txt = txt.."#C0xF13B54#"..v.num.." #I"..v.icon.."-56-56# "
										end
									end
								end
								local richText = rich.createWithWidth("#C0x5b545b#"..txt, 40, nil, 1250)
									:addTo(childs.btnPanel, 10)
									:anchorPoint(cc.p(0, 0.5))
									:formatText()
								adapt.oneLineCenterPos(cc.p(722, 124), {childs.btnPanel:get("text1"), richText}, cc.p(15, 0))
								node:setTouchEnabled(false)
							else
								widget.addAnimationByKey(childs.bgPanel, "daoguanhuizhang/jiesuo.skel", "suoEffect", "suo_loop", 1)
									:xy(190, 180)
									:scale(2)
								childs.txt:show()
								if v.isComeOpen then
									childs.txt:text(gLanguageCsv.comingSoon)
								else
									childs.txt:text(string.format(gLanguageCsv.awakeLevelToOpen, v.openParam))
								end
							end
							-- node:setTouchEnabled(false)
						end
					end
				end,
				onAfterBuild = function(list)
					if #list:getChildren() > 2 then
						list.sliderBg:show()
						local listX, listY = list:xy()
						local listSize = list:size()
						local size = list.sliderBg:size()
						list.sliderBg:x(listX + listSize.width - 50)
						list:setScrollBarEnabled(true)
						list:setScrollBarColor(cc.c3b(241, 59, 84))
						list:setScrollBarOpacity(255)
						list:setScrollBarAutoHideEnabled(false)
						list:setScrollBarPositionFromCorner(cc.p(50, (listSize.height - size.height) / 2))
						list:setScrollBarWidth(size.width)
						list:refreshView()
					else
						list.sliderBg:hide()
						list:setScrollBarEnabled(false)
					end
				end,
			},
			handlers = {
				chanceSetUp = bindHelper.self("onChanceSetUp"),
				setUp = bindHelper.self("onSetUp"),
				openLock = bindHelper.self("onOpenLock"),
				showDetail = bindHelper.self("onShowDetail"),
			},
		},
	},
	["item1"] = "item1",
	["list1"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("badgeData"),
				item = bindHelper.self("item1"),
				onItem = function(list, node, k, v)
					node:get("icon"):texture(v.icon)
					if not v.isOpen then
						node:get("mask"):show()
					else
						node:get("mask"):hide()
					end
					if v.isSel then
						node:get("redIcon"):show()
					else
						node:get("redIcon"):hide()
					end
					bind.touch(list, node, {methods = {ended = functools.partial(list.chooseBadge, k, v)}})
				end,
				asyncPreload = 5,
				preloadCenterIndex = bindHelper.self("curIndex"),
			},
			handlers = {
				chooseBadge = bindHelper.self("onChooseBadge"),
			},
		},
	},
	["item2"] = "item2",
	["list2"] = {
		varname = "list2",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("natureData"),
				item = bindHelper.self("item2"),
				onItem = function(list, node, k, v)
					node:get("icon"):texture(ui.ATTR_ICON[v])
				end,
			},
			handlers = {
			},
		},
	},
	["text1"] = "text1",
	["text2"] = "text2",
	["text3"] = "text3",
}

function gymBadgeGuardView:onCreate(badge)
	self.badgeNumb = idler.new(badge)
	self.badgeData = idlers.new()
	self.guardData = idlers.new()
	self.natureData = idlers.new()
	self.curIndex = badge
	self:initModel()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.cardGuard, subTitle = "CARDGUARD"})

	local csvGuard = csv.gym_badge.guard
	local csvBadge = csv.gym_badge.badge
	local csvItems = csv.items
	idlereasy.any({self.rmb, self.gold, self.badgeNumb, self.badges, self.items}, function(_,rmb, gold, badgeNumb, badges, items)
		local badgesData = badges and badges[badgeNumb] or {}
		local guards = badgesData.guards or {}
		local awake = badgesData.awake or 0
		local positions = badgesData.positions or {}
		local guardData = {}
		local guardTab = csvBadge[badgeNumb].guardIDs
		-- local cardId = 0
		-- local isOpen = false
		-- local isFee = false
		for k, v in ipairs(guardTab) do
			local cardId = 0
			local skinId = 0
			local isOpen = false
			local isFee = false
			local openCost = {}
			local guardValue = csvGuard[v]
			local costItem = dataEasy.getItemData(guardValue.openCost)
			if guardValue.isOpen == true then
				if guards[v] then
					local cards = gGameModel.cards:find(guards[v])
					if cards then
						cardId = cards:read("card_id")
						skinId = cards:read("skin_id")
					end
				end
				if guardValue.openParam == 0 or positions[v] then
					isOpen = true
				else
					if guardValue.openCondition == 1 then
						if guardValue.openParam <= awake then
							isFee = true
							for k, v in ipairs(costItem) do
								if v.key == "rmb" then
									table.insert(openCost, {key = v.key, bool = rmb >= v.num, num = v.num})
								elseif  v.key == "gold" then
									table.insert(openCost, {key = v.key, bool = gold >= v.num, num = v.num})
								else
									table.insert(openCost, {key = v.key, bool = items[v.key] and items[v.key] >= v.num, num = v.num, icon = csvItems[v.key].icon})
								end
							end
						end
					end
				end
				table.insert(guardData, {
					selectDbId = guards[v],
					id = cardId,
					skinId = skinId,
					isOpen = isOpen,
					isFee = isFee,
					openParam = guardValue.openParam,
					openCost = openCost,
					guardId = v,
					isComeOpen = false
				})
			else
				table.insert(guardData, {
					id = cardId,
					isComeOpen = true,
					isFee = isFee,
					isOpen = isOpen,
					guardId = v,
				})
			end
		end
		-- self.slider:visible(#guardData > 6)
		if #guardData > 6 then
			self.slider:show()
		else
			self.slider:hide()
		end
		if self.guardData:size() ~= #guardData then
			self.guardData:update(guardData)
		else
			for index, data in ipairs(guardData) do
				self.guardData:at(index):set(data)
			end
		end
	end)

	local badgeData = {}
	idlereasy.when(self.badgeNumb, function(_, badgeNumb)
		self.natureData:update(csvBadge[badgeNumb].nature)
		local natureLen = 0
		for k, v in pairs(csvBadge[badgeNumb].nature) do
			natureLen = natureLen + 1
		end
		for k, v in ipairs(csvBadge) do
			local isOpen = self:badgeIsOpen(k)
			table.insert(badgeData, {icon = v.icon, isOpen = isOpen, isSel = k == badgeNumb})
		end
		local itemSize = self.item2:size().width
		self.list2:size(natureLen*itemSize, 80)
		adapt.oneLinePos(self.text1, {self.list2, self.text2, self.text3}, {cc.p(5, 0),cc.p(0,0)}, "left")
	end)
	self.badgeData:update(badgeData)
end

function gymBadgeGuardView:initModel()
	self.rmb = gGameModel.role:getIdler("rmb")
	self.gold = gGameModel.role:getIdler("gold")
	self.badges = gGameModel.role:getIdler("badges")
	self.items = gGameModel.role:getIdler("items")
end

function gymBadgeGuardView:onChanceSetUp(list, key, val)
	gGameApp:requestServer("/game/badge/guard/setup", nil, self.badgeNumb:read(), val.guardId, -1)
	gGameUI:showTip(gLanguageCsv.alreadyCancelGuard)
end

function gymBadgeGuardView:onSetUp(list, key, val)
	gGameUI:stackUI("city.develop.gym_badge.guard_choose", nil, nil, {key = val.guardId, badgeNumb = self.badgeNumb:read(), setType = 1})
end

function gymBadgeGuardView:onShowDetail(list, node, key, val)
	if val.id ~= 0 then
		local view = gGameUI:stackUI("city.develop.gym_badge.guard_detail", nil, {clickClose = true, blackLayer = false, dispatchNodes = self.list}, {selectDbId = val.selectDbId, badgeNumb = self.badgeNumb:read()})
		tip.adaptView(view, self, {relativeNode = node:get("bgPanel"), canvasDir = "horizontal", childsName = {"baseNode"}})
	else
		if val.isOpen == true then
			gGameUI:stackUI("city.develop.gym_badge.guard_choose", nil, nil, {key = val.guardId, badgeNumb = self.badgeNumb:read(), setType = 0})
		elseif val.isFee == false then
			if val.isComeOpen then
				gGameUI:showTip(gLanguageCsv.comingSoon)
			else
				gGameUI:showTip(string.format(gLanguageCsv.awakeLevelToOpen, val.openParam))
			end
		end
	end

end

function gymBadgeGuardView:onChooseBadge(list, key, val)
	local csvBadge = csv.gym_badge.badge
	local preBadgeID = csvBadge[key].preBadgeID
	local preBadgeType = csvBadge[key].preBadgeType
	if val.isOpen then
		self.badgeNumb:set(key)
		local csvBadge = csv.gym_badge.badge
		for k, _ in ipairs(csvBadge) do
			if k ~= key then
				self.badgeData:atproxy(k).isSel = false
			else
				self.badgeData:atproxy(k).isSel = true
			end
		end
	else
		-- gGameUI:showTip(gLanguageCsv.noOpenPleaseToGymView)
		if preBadgeType == 1 then
			gGameUI:showTip(string.format(gLanguageCsv.noOpenPleaseToGymView1, csvBadge[preBadgeID].name,csvBadge[key].preLevel))
		else
			gGameUI:showTip(string.format(gLanguageCsv.noOpenPleaseToGymView2, csvBadge[preBadgeID].name,csvBadge[key].preLevel))
		end
	end
end

function gymBadgeGuardView:onOpenLock(list, node, key, val)
	-- if self.rmb:read() < val.openCost.rmb then
	-- 	uiEasy.showDialog("rmb", nil, {dialog = true})
	-- 	return
	-- end
	local content = ""
	for k, v in ipairs(val.openCost) do
		if v.key == "rmb" then
			if v.bool then
				content = content.."#C0x5b545b#"..v.num.." #Icommon/icon/icon_diamond.png-56-56# "
			else
				content = content.."#C0xF13B54#"..v.num.." #Icommon/icon/icon_diamond.png-56-56# "
				uiEasy.showDialog("rmb", nil, {dialog = true})
				return
			end
		elseif v.key == "gold" then
			if v.bool then
				content = content.."#C0x5b545b#"..v.num.."# Icommon/icon/icon_gold.png-56-56# "
			else
				content = content.."#C0xF13B54#"..v.num.." #Icommon/icon/icon_gold.png-56-56# "
				uiEasy.showDialog("gold", nil, {dialog = true})
				return
			end
		else
			if v.bool then
				content = content.."#C0x5b545b#"..v.num.." #I"..v.icon.."-56-56# "
			else
				content = content.."#C0xF13B54#"..v.num.." #I"..v.icon.."-56-56# "
				gGameUI:showTip(gLanguageCsv.itemNotEnoughtGuard)
				return
			end
		end
	end
	content = "#C0x5b545b#"..gLanguageCsv.consumptionOrNot..content.."#C0x5b545b#"..gLanguageCsv.openGuardsText
	gGameUI:showDialog({content = content, cb = function()
		node:get("bgPanel"):removeChildByName("suoEffect")
		local showOver = {false}
		gGameApp:requestServerCustom("/game/badge/guard/unlock")
			:params(self.badgeNumb:read(), val.guardId)
			:onResponse(function()
			-- 特效
			widget.addAnimationByKey(node, "daoguanhuizhang/jiesuo.skel", "suoEffect", "jiesuo_effect", 2)
					:xy(300, 270)
					:scale(2)
					:play("jiesuo_effect")
				performWithDelay(self, function()
					showOver[1] = true
				end, 26/30)
		end)
		:wait(showOver)
		:doit()
	end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
end

function gymBadgeGuardView:badgeIsOpen(badge)
	local csvBadge = csv.gym_badge.badge
	local preBadgeID = csvBadge[badge].preBadgeID
	local preBadgeType = csvBadge[badge].preBadgeType
	if preBadgeID then
		local badgesData = self.badges:read() and self.badges:read()[preBadgeID] or {}
		local awake = badgesData.awake or 0
		if preBadgeType == 1 then
			if csvBadge[badge].preLevel > awake then
				return false
			else
				return true
			end
		else
			local index = csv.gym_badge.badge[preBadgeID].talentIDs[6]
			local talents = badgesData.talents
			local talent = talents and talents[index] or 0
			if csvBadge[badge].preLevel > talent then
				return false
			else
				return true
			end
		end
	else
		return true
	end
end

return gymBadgeGuardView