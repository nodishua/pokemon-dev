local PersonalFigureView = class("PersonalFigureView", Dialog)

local SORT_DATAS = {
	{name = gLanguageCsv.spaceAll, val = 1},--全部
	{name = gLanguageCsv.unlockSuccess, val = 2},--已激活
	{name = gLanguageCsv.canUnlock, val = 3},--可激活
	{name = gLanguageCsv.notUnlock, val = 4}--未激活
}

local FIGURE_TYPE = {
	ALL = 1,		-- 	全局
	UNLOCKED = 2,	-- 已解锁
	CAN_UNLOCK = 3,	-- 可解锁
	NOT_UNLOCK = 4	-- 不能解锁
}


local SKILL_TYPE = {
	UNLOCKED = 1,	-- 已解锁
	CAN_UNLOCK = 2,	-- 可解锁
	NOT_UNLOCK = 3,	-- 不能解锁
	NO_SHOW   = 4   -- 不显示
}

local SHOW_TYPE = {
	FIGURE_ATTR = 1,
	FIGURE_EXPLAIN = 2,
}

local SKILL_NUM_MAX = 3

local STATE_ACTION = {"effect_shiyongzhong_loop", "effect_xuanzhong", "effect_jiesuo"}

local function onInitItem(list, node, k, itemDatas)
	for i=1,math.huge do
		local item = node:get("item"..i)
		if not item then
			break
		end
		item:removeFromParent()
	end

	local listW = list:size().width
	local sign = itemDatas[1].sign
	if sign == "title" then
		local title = node:get("title")

		title:visible(true)
		node:get("list"):visible(false)
		title:text(itemDatas[1].typ == 1 and gLanguageCsv.normalFigure or gLanguageCsv.raceFigure )

		local box = title:getBoundingBox()
		node:size(cc.size(listW, box.height))
		title:y(box.height / 2 - 10)

	else
		node:get("title"):visible(false)
		node:get("list"):visible(true)

		local itemSize = list.cloneItem:size()
		node:size(cc.size(listW, itemSize.height))
		node:get("list"):size(cc.size(listW, itemSize.height))
		local binds = {
			class = "listview",
			props = {
				data = itemDatas,
				item = list.cloneItem,
				-- topPadding = padding,
				onItem = function(innerList, cell, kk ,v)

					local figureCsv = gRoleFigureCsv[v.id]

					cell:get("icon"):texture(figureCsv.logo):scale(1.7)
					cell:get("selected"):visible(v.isSel)
					cell:get("used"):visible(v.isUse)
					cell:get("locked"):visible(v.unlocked ~= FIGURE_TYPE.UNLOCKED)
					cell:get("locked.lock"):visible(v.unlocked ~= FIGURE_TYPE.UNLOCKED and v.unlocked ~= FIGURE_TYPE.CAN_UNLOCK)

					v.figureSprite = widget.addAnimationByKey(cell, "figure/touxiang.json", "effect", STATE_ACTION[1], 16)
						:alignCenter(cell:size())
						:scale(0.55)
						:hide()

					if v.unlocked == FIGURE_TYPE.CAN_UNLOCK then
						widget.addAnimation(cell, "figure/touxiang.json", STATE_ACTION[1], 15)
							:alignCenter(cell:size())
							:scale(0.55)
					end

					if v.isAuto then
						v.figureSprite:show():play(STATE_ACTION[2])
						v.isAuto = false
					end

					bind.touch(list, cell, {methods = {ended = functools.partial(list.clickCell,k,kk,v)}})
				end,
			},
		}
		bind.extend(list, node:get("list"), binds)
	end
end

PersonalFigureView.RESOURCE_FILENAME = "personal_figure.json"
PersonalFigureView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["itemLogo"] = "figureSubItem",
	["item"]  = "item",
	["leftList"] = {
		varname = "figureList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("figureDatas"),
				item = bindHelper.self("item"),
				cloneItem = bindHelper.self("figureSubItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k ,v)
					onInitItem(list,node,k,v)
				end
			},
			handlers = {
				clickCell = bindHelper.self("onClickItem"),
			}
		}
	},

	["emptyPanel"] = "emptyPanel",
	["name"] = "figureName",
	["condition"] = "condition",
	["complete"] = "complete",
	["addPanel"] = "addPanel",
	["descPanel"] = "descPanel",
	["pos"] = {
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				data = bindHelper.self("filterTabData"),
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				width = 310,
				height = 80,
				btnWidth = 308,
				btnHeight = 102,
				btnType = 3,
				onNode = function(node)
					node:xy(-1120, -502):z(25)
				end,
			},
		}
	},
	["btnAdd"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onChangeClick(1)
			end)}
		}
	},
	["btnDesc"] = {
		varname = "btnDesc",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onChangeClick(2)
			end)}
		}
	},
	["descPanel.txt"] = "figureExplain",
	["addPanel.itemAttr"] = "itemAttr",
	["addPanel.list"] = "attrList",
	["addPanel.title1"] = "addPanelTitle1",
	["itemSkill"] = "itemSkill",
	["skillDescPanel"] = "skillDescPanel",
	["skillList"] = {
		varname = "skillList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("skillData"),
				item = bindHelper.self("itemSkill"),
				onItem = function(list, node, k, v)

					local skillPanel = node:get("skillPanel")

					local unlockSign = v.state == SKILL_TYPE.UNLOCKED
					local canUnlockSign = v.state == SKILL_TYPE.CAN_UNLOCK
					local notUnlock = v.state == SKILL_TYPE.NOT_UNLOCK

					skillPanel:visible(v.id ~= -1)

					node:get("imgAdd"):visible(unlockSign and v.id == -1)
					node:get("imgInfo"):visible(canUnlockSign)
					node:get("imgSuo"):visible(notUnlock)
					node:setTouchEnabled(not notUnlock)

					if v.id ~= -1 then
						local skillTab = csv.skill[v.id]
						skillPanel:get("imgSkill"):texture(skillTab.iconRes)
					end

					if canUnlockSign then
						local sprite = widget.addAnimation(node, "figure/touxiang.json", STATE_ACTION[1], 15)
							:alignCenter(node:size())
							:scale(0.55)
							:play(STATE_ACTION[1])
					end

					bind.touch(list, node, {methods = {ended = functools.partial(list.btnClick, k, v)}})
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
				btnClick = bindHelper.self("onBtnClick")
			},
		},
	},
	["skillTitle"] = "skillTitle",
	["skillCurrentTitle"] = "skillCurrentTitle",
	["specialTxt"] = "specialTxt",
	["costPanel"] = "costPanel",
	["btnSave.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["btnSave"] = {
		varname = "btnSave",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("btnSaveClick")}
		},
	},
	["figureIcon"] = {
		binds = {
			event = "extend",
			class = "role_figure",
			props = {
				data = bindHelper.self("figureId"),
				onNode = function(node)
					node:scale(0.78)
				end,
			},
		}
	},
	["shade"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("btnClickClose")}
		}
	},
	["lockSkillPanel"] = "lockSkillPanel",
	["conditionList"] = "conditionList"
}

function PersonalFigureView:onCreate(selectDbId)

	self.attrList:setScrollBarEnabled(false)

	self.skillCountLimit  = gCommonConfigCsv["figureSkillLimit"]            -- 携带的最多技能个数
	self.unLockSkillLimit = {0,gCommonConfigCsv["figureSkill2"],gCommonConfigCsv["figureSkill3"]} --可解锁对应技能的个数
	self.unLockSkillCost  = gCostCsv["figure_skill_unlock_cost"]    -- 解锁技能对应技能花费{50,50} 对应二三技能槽

	self.selItemInfo = self.selItemInfo or {}

	self:initModel()
	self.skillData   = idlers.new()
	self.filterKey   = idler.new(FIGURE_TYPE.ALL)
	self.figureId    = idler.new()
	self.selectData  = idlertable.new({})
	self.figureBaseDatas = idlertable.new()

	self.figureDatas = idlers.new()

	local tmpFilterTabData = {}
	for _,v in pairs(SORT_DATAS) do
		table.insert(tmpFilterTabData, v.name)
	end
	self.filterTabData = idlertable.new(tmpFilterTabData)

	-- 基本数据变动
	idlereasy.any({self.figures,self.vipLevel,self.roleLv, self.figure, self.gold, self.rmb}, function(_, figures, vipLevel, roleLv, figure)
		self:refreshFigureBaseIdlerData()
	end)

	-- 展示数据变动
	idlereasy.any({self.filterKey,self.figureBaseDatas},function(_,filterKey,figureDatas)
		if not self.isActive then

			local txt = string.format(gLanguageCsv.withoutSomeFigure, self.filterTabData:read()[filterKey])
			self.emptyPanel:get("txt"):text(txt)

			self:refreshFigureIdlerData(figureDatas)
		end
	end)

	-- 选择
	self.selectData:addListener(function(val, oldval)
		self:btnClickClose()

		self:setCostItemState(val.id, val.unlocked, val.typ)
		--设置按钮状态
		self:setBtnState(val.unlocked)

		self:setFigureBaseInfo(val.id)
	end)

	-- 技能
	idlereasy.any({self.skillFigure, self.skillCount}, function()
		local val = self.selectData:read()
		self:setCostItemState(val.id, val.unlocked, val.typ)
	end)


	--切换选择
	self.showType = idler.new(1)
	idlereasy.when(self.showType, function(_, showType)
		local showAttr = (SHOW_TYPE.FIGURE_ATTR == showType)
		self.addPanel:visible(showAttr)
		self.descPanel:visible(not showAttr)
		self.btnAdd:setBright(not showAttr)
		self.btnDesc:setBright(showAttr)

		local brightTitle = showAttr and self.btnAdd:get("txt") or self.btnDesc:get("txt")
		local normalTitle = (not showAttr) and self.btnAdd:get("txt") or self.btnDesc:get("txt")

		text.addEffect(brightTitle, {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}})
		text.deleteAllEffect(normalTitle)
		text.addEffect(normalTitle, {color = ui.COLORS.NORMAL.RED})
	end)
	self.addPanel:get("desc"):text(gLanguageCsv.personalDesc)
	Dialog.onCreate(self)
end

function PersonalFigureView:initModel()
	self.figure   = gGameModel.role:getIdler("figure")            -- 当前形象
	self.figures  = gGameModel.role:getIdler("figures")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.roleLv   = gGameModel.role:getIdler("level")
	self.gold     = gGameModel.role:getIdler("gold")
	self.rmb      = gGameModel.role:getIdler("rmb")

	self.gateStar      = gGameModel.role:getIdler("gate_star")             -- 星星数量
	self.fightingPoint = gGameModel.role:getIdler("battle_fighting_point")
	self.pwRank        = gGameModel.role:getIdler("pw_rank")
	self.skillFigure   = gGameModel.role:getIdler("skill_figures")
	self.skillCount    = gGameModel.role:getIdler("figure_skill_count")   -- 当前技能数量

end

-- 基本数据获取
function PersonalFigureView:refreshFigureBaseIdlerData()
	local curFigure = self.figure:read()
	local figures = self.figures:read()

	local figureDatas = {}

	for k,v in csvPairs(gRoleFigureCsv) do
		if v.hide == 0  then
			local figureData = {
				isUse    = curFigure == k,
				isSel    = false,
				unlocked = FIGURE_TYPE.NOT_UNLOCK,
				showIdx  = v.showIdx,
				typ      = v.type,
				id       = k
			}

			local func = function()
				if csvNext(v.unlock) then
					local id,num = csvNext(v.activeCost)
					local typ, level = csvNext(v.unlock)
					if dataEasy.getNumByKey(id) >= num and self:getConditionLevel(typ, level) then
						figureData.unlocked = FIGURE_TYPE.CAN_UNLOCK
					end
				end
			end

			if figures[k] then
				figureData.unlocked = FIGURE_TYPE.UNLOCKED
			else
				func()
			end

			table.insert(figureDatas,figureData)
		end
	end

	table.sort(figureDatas,function(v1, v2)
			if v1.unlocked ~= v2.unlocked then
				return v1.unlocked < v2.unlocked
			end
			if v1.showIdx ~= v2.showIdx then
				return v1.showIdx > v2.showIdx
			end
			return v1.id < v2.id
		end)

	self.figureBaseDatas:set(figureDatas)
end

--过滤数据
function PersonalFigureView:refreshFigureIdlerData(list)
	local showType = self.filterKey:read()
	local figureDatas = {}
	for k, v in ipairs(list) do
		v.isSel = false
		if figureDatas[v.typ] == nil then
			figureDatas[v.typ] = {}
		end
		if showType == 1 then
			table.insert(figureDatas[v.typ],v)
		elseif showType == v.unlocked then
			table.insert(figureDatas[v.typ],v)
		end
	end

	figureDatas = self:resetDataStruct(figureDatas)
	self.emptyPanel:visible(#figureDatas == 0)
	self.figureDatas:update(figureDatas)
end

-- 组织数据
function PersonalFigureView:resetDataStruct(data)
	local newDatas = {}
	local sign = 0
	local row = 0
	local idx = 0
	local tempSelect = nil

	local info = self.selectData:read()
	for typ, list in ipairs(data) do
		if #list > 0  then
			table.insert(newDatas,{{sign = "title", typ = typ}})
		end
		local item = {}
		for k, v in ipairs(list) do
			if k%3 == 1 then
				if k > 3 then
					table.insert(newDatas, item)
				end
				item = {}
			end
			table.insert(item, v)

			local func = function(num)
				sign = num
				tempSelect = v
				row = #newDatas +1
				idx = k%3
			end

			if sign < 3 then
				if info.id and info.id == v.id then
					func(3)
				end

				if sign < 2 then
					if v.isUse then
						func(2)
					end

					if sign == 0 then
						func(1)
					end
				end
			end
		end

		if #item > 0 then
			table.insert(newDatas, item)
			item = {}
		end
	end

	if tempSelect then
		if idx == 0 then idx = 3 end
		self.selItemInfo = {row = row, idx = idx}
		newDatas[row][idx].isSel = true
		self.selectData:set(tempSelect)
	end
	return newDatas
end


function PersonalFigureView:getConditionLevel(typ, num)
	--解锁条件格式 {条件=数值} 1=等级 2=关卡 5=VIP等级 6=战力 44=竞技场排名  79=训练家等级
	if typ == 1 then
		return self.roleLv:read() >= num
	end
	if typ == 2 then
		return (self.gateStar:read()[num] or 0) >= 1
	end
	if typ == 5 then
		return self.vipLevel:read() >= num
	end
	if typ == 6 then
		return self.fightingPoint:read() >= num
	end
	if typ == 44 then
		return self.pwRank:read() >= num
	end
	if typ == 79 then
		return gGameModel.role:read("trainer_level") >= num
	end
end


-- 设置选中形象和基本信息
function PersonalFigureView:setFigureBaseInfo(figureId)
	local csvFigure = gRoleFigureCsv[figureId]
	self.figureName:text(csvFigure.name)
	self.figureId:set(figureId)
	self.descPanel:get("txt"):text(csvFigure.desc)

	--创建列表
	local attrDatas = {}
	local index = 0
	for i=1,3 do
		index = csvFigure["attrNatureType"..i] + 1
		if not attrDatas[index] then
			attrDatas[index] = {}
		end
		local attrType = csvFigure["attrType"..i]
		if attrType ~= 0 then
			table.insert(attrDatas[index], {attrType = attrType, attrValue = csvFigure["attrValue"..i]})
		end
	end

	self.attrList:removeAllChildren()
	self.addPanelTitle1:text(gLanguageCsv.allTeamActiveText)
	for typ,attrData in pairs(attrDatas) do
		for k,v in pairs(attrData) do

			local attrItem = self.itemAttr:clone():show()
			local childs   = attrItem:multiget("txt", "icon")

			local titleTxt = typ == 1 and gLanguageCsv.allSprite or string.format(gLanguageCsv.someSprite, gLanguageCsv[game.NATURE_TABLE[typ-1]])
			local path = ui.ATTR_LOGO[game.ATTRDEF_TABLE[v.attrType]]

			local itemTxt  = getLanguageAttr(v.attrType)

			childs.icon:texture(path)
			childs.txt:text(itemTxt.." +"..dataEasy.getAttrValueString(v.attrType, v.attrValue))

			adapt.oneLinePos(childs.icon, childs.txt, cc.p(15, 0), "left")
			self.attrList:pushBackCustomItem(attrItem)
		end
		local y = self.attrList:y() + self.attrList:height() - math.min(self.attrList:height(), self.attrList:getInnerItemSize().height) - 30
		self.addPanel:get("desc"):y(y)
	end
end

--控制形象相关界面的显示
function PersonalFigureView:setViewHideOrShow(unlocked,typ)
	local unlockSign = unlocked == FIGURE_TYPE.UNLOCKED
	self.skillCurrentTitle:visible(unlockSign)
	self.skillList:visible(unlockSign)
	self.conditionList:visible(unlockSign)

	self.skillTitle:visible((not unlockSign) and typ == 2)
	self.lockSkillPanel:visible((not unlockSign) and typ == 2)

	self.condition:visible(not unlockSign)
	self.complete:visible(unlocked == FIGURE_TYPE.CAN_UNLOCK)
end

--设置右边信息
function PersonalFigureView:setCostItemState(figureId, unlocked, typ)

	self:setViewHideOrShow(unlocked,typ)

	if unlocked == FIGURE_TYPE.UNLOCKED then
		local skillList = {}
		local csvFigure = gRoleFigureCsv[figureId]

		local skillFigure = self.skillFigure:read()
		local skillFigureList = skillFigure[figureId]

		if skillFigureList then
			for index, value in pairs(skillFigureList) do
				local skillId = gRoleFigureCsv[value].skills[1]
				table.insert(skillList, {id = skillId,figureId = value})
			end
		else
			local skillId = csvFigure.skills[1]
			table.insert(skillList, {id = skillId,figureId = figureId})
		end

		local count = self.skillCount:read()
		local figures = self.figures:read()
		local figureCount = table.nums(figures)

		-- 整理多技能数据
		for index = 1, self.skillCountLimit do
			if skillList[index] == nil then skillList[index] = {} end
			local data = skillList[index]
			data.id = data.id or -1
			data.figureId = data.figureId or -1

			if index <= count then
				data.state = SKILL_TYPE.UNLOCKED
			else
				if figureCount >= self.unLockSkillLimit[index] then
					data.state = SKILL_TYPE.CAN_UNLOCK
				else
					data.state = SKILL_TYPE.NOT_UNLOCK
				end
				break
			end
		end
		self.skillData:update(skillList)
	else
		if typ == 2 then
			self:setLockSkillPanel(figureId)
		end
		self:showActiveState(figureId,unlocked)
	end

	self:setSkillTip()
end


-- 设置未解锁时技能显示
function PersonalFigureView:setLockSkillPanel(figureId)

	local csvFigure = gRoleFigureCsv[figureId]
	local skillId   = csvFigure.skills[1]
	local skillTab  = csv.skill[skillId]

	self.lockSkillPanel:get("icon"):texture(skillTab.iconRes)
	self.lockSkillPanel:get("name"):text(skillTab.skillName)

	beauty.textScroll({
		list = self.lockSkillPanel:get("descList"),
		strs = "#C0x5B545B#" .. skillTab.describe,
		isRich = true,
	})
end

--设置激活状态
function PersonalFigureView:showActiveState(figureId,unlocked)
	local csvFigure = gRoleFigureCsv[figureId]

	self.condition:text(csvFigure.unlockDesc)
	text.addEffect(self.condition, {color = unlocked == FIGURE_TYPE.CAN_UNLOCK and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.QUALITY[6]})
	adapt.oneLinePos(self.condition, self.complete, cc.p(10, 0))

	-- 设置激活状态
	local activeCost = csvFigure.activeCost
	if activeCost then
		self.specialTxt:hide()
		self.costPanel:show()
		self.btnSave:show()
	else
		self.specialTxt:show()
		self.costPanel:hide()
		self.btnSave:hide()
		return
	end

	local id,num = csvNext(activeCost)
	local childs = self.costPanel:multiget("item", "icon", "txt", "title")
	local itemPanel = self.costPanel:get("item")

	if id == "rmb" or id == "gold" then
		childs.title:show()
		itemPanel:hide()
		local icon = string.format("common/icon/icon_%s.png",(id == "rmb") and "diamond" or "gold")
		self.costPanel:get("icon"):texture(icon):show()
		self.costPanel:get("txt"):text(num):show()
		adapt.oneLinePos(childs.icon, childs.txt, cc.p(10,0), "right")
		adapt.oneLinePos(childs.txt, childs.title, cc.p(0,0), "right")

	else
		childs.title:hide()
		itemPanel:show()
		self.costPanel:get("icon"):hide()
		self.costPanel:get("txt"):hide()

		local size = self.costPanel:size()
		local curNum = dataEasy.getNumByKey(id)
		bind.extend(self, itemPanel, {
			class = "icon_key",
			props = {
				data = {
					key = id,
					num = curNum,
					targetNum = num,
				},
				grayState = curNum >= num and 0 or 1,
				onNode = function(node)
					node:scale(0.9)
				end,
			},
		})
	end

	local color = (dataEasy.getNumByKey(id) >= num) and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.RED
	text.addEffect(self.costPanel:get("txt"), {color = color})
end

--设置按钮状态
function PersonalFigureView:setBtnState(unlocked)
	local btnTitle = gLanguageCsv.spaceActive
	if unlocked == FIGURE_TYPE.UNLOCKED then
		self.btnSave:show()
		self.specialTxt:hide()
		self.costPanel:hide()
		btnTitle = gLanguageCsv.spaceUse
	end

	self.btnSave:setTouchEnabled(unlocked ~= FIGURE_TYPE.NOT_UNLOCK)
	cache.setShader(self.btnSave, false, unlocked ~= FIGURE_TYPE.NOT_UNLOCK and "normal" or "hsl_gray")
	if unlocked == FIGURE_TYPE.NOT_UNLOCK then
		text.deleteAllEffect(self.btnSave:get("txt"))
	else
		text.addEffect(self.btnSave:get("txt"), {glow={color=ui.COLORS.GLOW.WHITE}})
	end
	self.btnSave:get("txt"):text(btnTitle)
end


-- 设置技能提示文字
function PersonalFigureView:setSkillTip()
	local count       = self.skillCount:read()
	local figures     = self.figures:read()
	local figureCount = table.nums(figures)

	local str = ""
	if count < self.skillCountLimit then
		if  figureCount < self.unLockSkillLimit[count+1]  then
			str = string.format(gLanguageCsv.unlockSkillLimitTip,self.unLockSkillLimit[count+1])
		else
			str = string.format(gLanguageCsv.unlockSkillCostTip,self.unLockSkillCost[count])
		end
	end

	beauty.textScroll({
		list   = self.conditionList,
		strs   = {str,gLanguageCsv.sureChangeSkillTip},
		isRich = true,
		align  = "left",
	})
end

--形象的加成和说明切换
function PersonalFigureView:onChangeClick(typ)
	self.showType:set(typ)
end

--点击空白关掉技能介绍框
function PersonalFigureView:btnClickClose()
	if self.showSkillDesc then
		self.skillDescPanel:visible(false)
		self.showSkillDesc = false
	end
end

--激活
function PersonalFigureView:btnSaveClick()
	local selectData = self.selectData:read()
	if selectData.unlocked == FIGURE_TYPE.UNLOCKED then
		if self.figure:read() ~= selectData.id then
			gGameApp:requestServer("/game/role/figure",function()
				self:onClose()
			end, selectData.id)
		end
	else
		if self.isActive then
			return
		end
		local function cb()
			self.isActive = true
			self.btnSave:setTouchEnabled(false)

			local showOver = {false}
			gGameApp:requestServerCustom("/game/role/figure_active")
				:params(selectData.id)
				:onResponse(function (tb)
					gGameUI:showTip(gLanguageCsv.activeSuccess)
					local effect = selectData.figureSprite
					effect:show()
					effect:play(STATE_ACTION[3])
					effect:setSpriteEventHandler(function(event, eventArgs)
						effect:setSpriteEventHandler()
						performWithDelay(self, function()
							self.isActive = false
							showOver[1] = true
						end, 0.01)
					end, sp.EventType.ANIMATION_COMPLETE)
				end)
				:wait(showOver)
				:doit(function (tb)
					self:setBtnState(FIGURE_TYPE.UNLOCKED)
					self.btnSave:setTouchEnabled(true)
					self.filterKey:set(self.filterKey:read(),true)
				end)
		end
		local csvFigure = gRoleFigureCsv[selectData.id]
		if csvFigure.activeCost then
			local id, num = csvNext(csvFigure.activeCost)
			if id == "rmb" then
				dataEasy.sureUsingDiamonds(cb, num)
			else
				cb()
			end
		else
			cb()
		end
	end
end

-- 切换
function PersonalFigureView:onSortMenusBtnClick(panel, node, k, v)
	dataEasy.tryCallFunc(self.figureList, "setItemAction", {isAction = true, alwaysShow = true})
	self.filterKey:set(k)
	dataEasy.tryCallFunc(self.figureList, "setItemAction", {isAction = false})
end

--没有技能
function PersonalFigureView:onAfterBuild()
	local isEmpty = self.skillData:size() == 0
end

-- 操作按钮
function PersonalFigureView:onBtnClick(list,k, v)
	local unlockSign = v.state == SKILL_TYPE.UNLOCKED
	local canUnlockSign = v.state == SKILL_TYPE.CAN_UNLOCK

	-- 解锁技能栏
	if canUnlockSign then
		local count = self.skillCount:read()
		local cost = self.unLockSkillCost[count]

		gGameUI:showDialog({
			strs = {string.format(gLanguageCsv.sureBuyFigureSkillTip,cost), gLanguageCsv.sureChangeSkillTip2},
			cb = function()
				gGameApp:requestServer("/game/role/figure/skill/unlock",function (tb)
				end,count)
			end,
			isRich = true,
			btnType = 2,
			dialogParams = {clickClose = false},
		})
	end

	-- 换技能
	if unlockSign then
		local selectData = self.selectData:read()
		gGameUI:stackUI("city.personal.skill_choose", nil, {clickClose = true}, selectData.id, v.figureId, k)
	end
end


function PersonalFigureView:onClickItem(list,row,idx,v)
	self.figureDatas:atproxy(self.selItemInfo.row)[self.selItemInfo.idx].isSel = false
	self.selItemInfo = {row = row, idx = idx}
	self.figureDatas:atproxy(row)[idx].isSel = true
	self.figureDatas:atproxy(row)[idx].isAuto = true

	self.selectData:set(v)
end

return PersonalFigureView
