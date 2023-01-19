-- @Date:   2019-05-17
-- @Desc:
-- @Last Modified time: 2019-08-20

local function onInitItem(list, node, index, v)
	idlereasy.when(list.titleId, function (_, val)
		if v.isSelected then
			local childs = node:multiget("downPanel", "list", "layout")
			local data = list.checkState:read() and v.ownTitles or v.titles
			childs.downPanel:size(list.titleItem:size().width, list.titleItem:size().height * #data)
			childs.list:size(childs.downPanel:size())
			childs.list:anchorPoint(cc.p(0.5, 1))
			itertools.invoke({childs.downPanel, childs.list}, "show")
			bind.extend(list, childs.list, {
				event = "extend",
				class = "listview",
				props = {
					data = data,
					item = list.titleItem,
					onItem = function(childList, item, k, v)
						local childs = item:multiget("txt", "img", "used", "imgTime", "bg")
						if type(v.data) ~= "string" then
							childs.txt:text("")
							local props = {
								event = "extend",
								class = "role_title",
								props = {
									isGray = v.data == nil,
									data = v.id,
									onNode = function (node)
										node:xy(item:size().width/2, item:size().height/2)
											:z(10)
									end
								}
							}
							itertools.invoke({childs.img, childs.used}, "visible", v.id == val)
							if v.data and v.data[1] ~= 0 then
								childs.imgTime:show()
							else
								childs.imgTime:hide()
							end
							idlereasy.when(list.id, function (_, id)
								if not tolua.isnull(item) then
									childs.bg:texture(id == v.id and
										"city/develop/title_book/box_xlxz.png" or "city/develop/title_book/box_xld.png")
									if v.id == id then
										list:enableSchedule():unSchedule("tag")
										if v.data and v.data[1] ~= 0 then
											local countdown = v.data[1]- time.getTime()
											list:schedule(function()
												countdown = countdown - 1
												local t = time.getCutDown(countdown)
												local txt = t.head_date_str
												txt = string.format(gLanguageCsv.titleHaveTimeLimit, txt)
												list.timeLimit:text(txt)
												adapt.setTextScaleWithWidth(list.timeLimit, nil, 1120)
												text.addEffect(list.timeLimit, {color = ui.COLORS.NORMAL.ALERT_ORANGE})
												text.addEffect(list.rightPanelTip, {color = ui.COLORS.NORMAL.DEFAULT})
												if countdown <= 0 then
													list.timeLimit:hide()
													return false
												end
											end, 1, 0, "tag")
										else
											local titleCfg = gTitleCsv[v.id]
											local strTyp = gLanguageCsv.afterObtaining
											if v.data then
												strTyp = ""
												text.addEffect(list.timeLimit, {color = ui.COLORS.NORMAL.FRIEND_GREEN})
												text.addEffect(list.rightPanelTip, {color = ui.COLORS.NORMAL.DEFAULT})
											else
												text.addEffect(list.timeLimit, {color = ui.COLORS.NORMAL.GRAY})
												text.addEffect(list.rightPanelTip, {color = ui.COLORS.NORMAL.GRAY})
											end
											if titleCfg.days > 0 then
												list.timeLimit:text(string.format(gLanguageCsv.titleHaveTimeLimitDays, strTyp, titleCfg.days))
											else
												list.timeLimit:text(string.format(gLanguageCsv.foreverUse, strTyp))
											end
										end
									end
								end
							end):anonyOnly(list, "title"..v.id)
							bind.extend(list, item, props)
							item:onClick(functools.partial(list.clickCell, k, v))
							if list.id:read() == v.id then
								functools.partial(list.clickCell, k, v)()
							end
						else
							childs.txt:text(v.data)
							itertools.invoke({childs.img, childs.used}, "hide")
							childs.imgTime:hide()
						end
					end,
				},
			})
			node:size(childs.list:size().width, childs.list:size().height + 186)
			childs.layout:y(childs.list:size().height + 186)
			childs.downPanel:y(childs.list:size().height + 186 - childs.layout:size().height + 5)
			childs.list:xy(childs.downPanel:xy())
		end
	end):anonyOnly(list, "initItem"..index)
end

local TitleBookView = class("TitleBookView", Dialog)
TitleBookView.RESOURCE_FILENAME = "title_book.json"
TitleBookView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["rightPanel.btnUse"] = {
		varname = "btn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onUseOrDown")}
		},
	},
	["leftPanel"] = "leftPanel",
	["leftPanel.item"] = "leftItem",
	["leftPanel.title"] = "titleItem",
	["leftPanel.list"] = {
		varname  = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("leftItem"),
				margin = -20,
				titleId = bindHelper.self("titleId"),
				titleItem = bindHelper.self("titleItem"),
				timeLimit = bindHelper.self("timeLimit"),
				rightPanelTip = bindHelper.self("rightPanelTip"),
				checkState = bindHelper.self("checkState"),
				id = bindHelper.self("id"),
				backupCached = false,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:get("layout"):multiget("name", "selected", "flag", "line", "bg")
					adapt.setTextScaleWithWidth(childs.name,v.name,node:width() - 150)
					childs.selected:visible(v.isSelected == true)
					childs.bg:visible(v.isSelected == true)
					if v.isSelected and v.isDropDown then
						childs.flag:texture("common/btn/btn_arrow_white.png")
						childs.flag:rotate(0):z(10)
						text.addEffect(childs.name, {color = ui.COLORS.NORMAL.WHITE})
						onInitItem(list, node, k, v)
						childs.line:hide()
					else
						childs.flag:texture("common/btn/btn_arrow_red.png")
						childs.flag:rotate(180):z(10)
						text.addEffect(childs.name, {color = ui.COLORS.NORMAL.DEFAULT})
						node:size(518, 186)
						node:get("layout"):y(180)
						node:get("list"):hide()
						node:get("downPanel"):hide()
						childs.line:show()
					end
					list:forceDoLayout()
					node:onClick(functools.partial(list.itemClick, k, v))
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onParentNodeClick"),
				clickCell = bindHelper.self("onNodeClick")
			},
		}
	},
	["rightPanel"] = "rightPanel",
	["rightPanel.tip"] = "rightPanelTip",
	["rightPanel.title"] = "titlePanel",
	["itemAttr"] = "attrItem",
	["rightPanel.list1"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrData"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("name", "icon", "attr", "num")
					childs.name:text(v.txt)
					childs.attr:text(getLanguageAttr(v.attrType))
					childs.num:text("+"..dataEasy.getAttrValueString(v.attrType, v.attrValue))
					if ui.ATTR_LOGO[game.ATTRDEF_TABLE[v.attrType]] then
						childs.icon:texture(ui.ATTR_LOGO[game.ATTRDEF_TABLE[v.attrType]])
					else
						childs.icon:hide()
					end
					adapt.oneLinePos(childs.attr, childs.num, cc.p(20, 0), "left")
				end,
			},

		}
	},
	["itemCondition"] = "conditionItem",
	["rightPanel.list2"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("conditionData"),
				item = bindHelper.self("conditionItem"),
				onItem = function(list, node, k, v)
					local tip = node:get("tip"):text(v.con)
					local tip1 = node:get("tip1")
					if v.progress and v.progress[1] < v.progress[2] then
						local str = "(%d/%d)"
						tip1:text(string.format(str, v.progress[1], v.progress[2]))
						tip:text(v.con..tip1:text())
						tip1:hide()
					else
						tip1:hide()
					end
				end,
			},
		}
	},
	["rightPanel.timeLimit"] = "timeLimit",
	["leftPanel.icon"] = {
		varname = "checkStatus",
		binds = {
			event = "click",
			method = bindHelper.self("onChangeState"),
		},
	},
	["leftPanel.tip"] = {
		varname = "checkTip",
		binds = {
			event = "click",
			method = bindHelper.self("onChangeState"),
		},
	},
}

function TitleBookView:onCreate()
	self:initModel()
	self.originY = self.timeLimit:y()
	self.attrData = idlertable.new({})
	self.conditionData = idlertable.new({})
	self.id = idler.new(0)
	self.showTab = idler.new(1)
	self.checkState = idler.new(false)
	self.checkTip:setTouchEnabled(true)

	local titles, tab = self:getData()
	self.tabDatas = idlers.newWithMap(tab)

	self.leftList:setBounceEnabled(true)
	idlereasy.when(self.checkState, function(_, state)
		self.checkStatus:texture(state and "common/icon/radio_selected.png" or "common/icon/radio_normal.png")
		self.tabDatas:at(self.showTab):notify()
		performWithDelay(self, function()
			self.leftList:refreshView()
			if self.leftList:getScrolledPercentVertical() > 100 then
				self.leftList:scrollToBottom(0.3, true)
			end
		end, 0.01)
	end)

	self.showTab:addListener(function (val, oldVal, _)
		if oldVal == val then
			self.tabDatas:atproxy(oldVal).isSelected = not self.tabDatas:atproxy(oldVal).isSelected
			self.tabDatas:atproxy(val).isDropDown = not self.tabDatas:atproxy(val).isDropDown
		else
			self.tabDatas:atproxy(val).isDropDown = true
			self.tabDatas:atproxy(oldVal).isSelected = false
			self.tabDatas:atproxy(val).isSelected = true
		end
		performWithDelay(self, function()
			self.leftList:refreshView()
			if self.leftList:getScrolledPercentVertical() > 100 then
				if val > oldVal then
					self.leftList:jumpToBottom()
				else
					self.leftList:scrollToBottom(0.3, true)
				end
			end
		end, 0.01)
	end, true)

	idlereasy.any({self.id, self.titleId}, function (_, currId, titleId)
		local txt = self.btn:get("txt")
		if currId == titleId then
			txt:text(gLanguageCsv.spaceDischarge)
			text.addEffect(txt, {glow = {color = ui.COLORS.GLOW.WHITE}, color = ui.COLORS.NORMAL.WHITE})
			cache.setShader(self.btn, false, "normal")
			self.btn:setTouchEnabled(true)
		else
			local state = titles[currId] or titles[gTitleCsv[currId].sameId]
			cache.setShader(self.btn, false, state and "normal" or "hsl_gray")
			if not state then
				text.deleteAllEffect(txt)
				text.addEffect(txt, {color = ui.COLORS.DISABLED.WHITE})
			else
				text.addEffect(txt, {glow = {color = ui.COLORS.GLOW.WHITE}, color = ui.COLORS.NORMAL.WHITE})
			end
			self.btn:setTouchEnabled(state ~= nil)
			txt:text(gLanguageCsv.spaceUse)
		end
	end)
	Dialog.onCreate(self)
end

function TitleBookView:getData()
	-- 近期获得称号
	local roleTitles = gGameModel.role:read("titles")
	local titles = {}
	for k, v in pairs(roleTitles) do
		if not gTitleCsv[k].sameId then
			titles[k] = {[1] = v[1], [2] = v[2], id = k}
		end
	end
	-- 有sameid的 比较有效时间长的替换原有数据
	for k, v in pairs(roleTitles) do
		local sameId = gTitleCsv[k].sameId
		if sameId then
			if not titles[sameId] or v[1] > titles[sameId][1] then
				titles[sameId] = {[1] = v[1], [2] = v[2], id = k}
			end
		end
	end

	local orderTitles = {}
	for k, v in pairs(titles) do
		if gTitleCsv[k].alwaysDisplay == 1 then
			table.insert(orderTitles, {id = v.id, data = v})
		end
	end

	local ownCount = 0
	local allCount = 0
	-- 获得称号数据
	local allDatas = {}
	local ownDatas = {}
	for k, v in orderCsvPairs(gTitleCsv) do
		if v.alwaysDisplay == 1 and not v.sameId then
			allDatas[v.type] = allDatas[v.type] or {}
			allCount = allCount + 1
			local id = titles[k] and titles[k].id or k
			table.insert(allDatas[v.type], {id = titles[k] and titles[k].id or k, data = titles[k]})

			if titles[k] then
				ownDatas[v.type] = ownDatas[v.type] or {}
				table.insert(ownDatas[v.type], {id = titles[k] and titles[k].id or k, data = titles[k]})
				ownCount = ownCount + 1
			end
		end
	end
	self.checkTip:text(string.format(gLanguageCsv.gotTitle, ownCount, allCount))
	adapt.oneLineCenterPos(cc.p(281, 53), {self.checkStatus, self.checkTip}, cc.p(10, 0))
	for _, v in pairs(allDatas) do
		table.sort(v, function(a, b)
			if not a.data and b.data then
				return false
			end
			if a.data and not b.data then
				return true
			end
			return a.id < b.id
		end)
	end
	for _, v in pairs(ownDatas) do
		table.sort(v, function(a, b)
			return a.id < b.id
		end)
	end
	local emptyData = {{data = gLanguageCsv.currNoTitle, id = -1}}
	-- 标签数据设置
	local tab = {}
	if not itertools.isempty(orderTitles) then
		table.sort(orderTitles, function (a, b)
			return a.data[2] > b.data[2]
		end)
		self.id:set(orderTitles[1].id)
		-- 根据配表加入称号分类，第一个默认是最近分类
		table.insert(tab, {name = gLanguageCsv.recentGain, titles = arraytools.slice(orderTitles, 1, 3)})
	end
	for k, v in orderCsvPairs(csv.title_type) do
		table.insert(tab, {
			name = v.name,
			titles = itertools.isempty(allDatas[v.type]) and emptyData or allDatas[v.type],
			ownTitles = itertools.isempty(ownDatas[v.type]) and emptyData or ownDatas[v.type],
		})
	end
	tab[1].isSelected = true
	tab[1].isDropDown = true
	return titles, tab
end

function TitleBookView:initModel()
	self.titleId = gGameModel.role:getIdler("title_id")
end

function TitleBookView:onChangeState()
	self.checkState:modify(function (val)
		return true, not val
	end)
end

function TitleBookView:onParentNodeClick(list, index, data)
	self.showTab:set(index, true)
end

function TitleBookView:onNodeClick(list, k, v)
	local cfg = gTitleCsv[v.id]
	bind.extend(self, self.titlePanel, {
		event = "extend",
		class = "role_title",
		props = {
			data = v.id,
		}
	})

	local attrData = {}
	for i=1, 3 do
		local attrType = cfg["attrType"..i]
		if attrType == nil or attrType == 0 then
			break
		end
		local typ = cfg["attrNatureType"..i]
		local titleTxt = (typ == 0) and gLanguageCsv.allSprite or string.format(gLanguageCsv.someSprite, gLanguageCsv[game.NATURE_TABLE[typ]])
		local attrValue = cfg["attrValue"..i]
		if attrValue then
			table.insert(attrData, {txt = titleTxt, attrType = attrType, attrValue = attrValue, typ = typ})
		end
	end
	self.attrData:set(attrData)
	local conditionData = {}
	for i=1,2 do
		local con = cfg[i == 1 and "conditionDesc" or "conditionDesc2"]
		if con then
			table.insert(conditionData, {con = con})
		end
	end
	if cfg.feature == nil and cfg.itemId == nil then
		local progress = gGameModel.role:getTitleProgress(cfg.condition1, cfg.conditionArg1_1, cfg.conditionArg1_2)
		conditionData[1].progress = progress
	end
	self.conditionData:set(conditionData)
	self.id:set(v.id)
	self.timeLimit:y(#conditionData == 1 and self.originY + 20 or self.originY - 40)
end

function TitleBookView:onUseOrDown()
	gGameApp:requestServer("/game/role/title/switch",function (tb)
		if self.id:read() == self.titleId:read() then
			gGameUI:showTip(gLanguageCsv.successUseTitle)
		else
			gGameUI:showTip(gLanguageCsv.successDischargeTitle)
		end
	end, self.id:read() == self.titleId:read() and -1 or self.id:read())
end

return TitleBookView