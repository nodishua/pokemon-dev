local STATE_ACTION = {"standby_loop", "attack", "win_loop", "run_loop", "skill1"}

local NATIVE_BUFF_OBJ = {
	gLanguageCsv.skinBuff1,
	gLanguageCsv.skinBuff2,
}

local SKIN_BG =
{
	"city/drawcard/draw/panel_card_gh.png",
	"city/drawcard/draw/panel_card_l.png",
	"city/drawcard/draw/panel_card_b.png",
	"city/drawcard/draw/panel_card_z.png",
	"city/drawcard/draw/panel_card_h.png",
	"city/drawcard/draw/panel_card_c.png",
	"city/drawcard/draw/panel_card_r.png",
}

local CardSkinView = class("CardSkinView", Dialog)

CardSkinView.RESOURCE_FILENAME = "card_skin.json"
CardSkinView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["attrItem"] = "attrItem",
	["panelLeft.attrList"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					node:get("imgIcon"):texture(ui.ATTR_ICON[v])
				end,
			},
		},
	},

	["panelLeft.textName"] = "cardNameTxt",
	["panelLeft.btnSwitch"] = {
		varname = "btnSwitch",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnSwitch")}
		}
	},
	["panelLeft.btnSwitch.labelSwitch"] = "labelSwitch",
	["panelLeft.btnSwitch.imgSwitch"] = "imgSwitch",

	["starItem"] = "starItem",
	["panelLeft.imgFlag"] = "imgFlag",
	["panelLeft.starList"] = {
		varname = "starList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("starDatas"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("imgStar"):texture(v.icon)
				end,
				asyncPreload = 6,
			}
		},
	},

	["panelLeft.heroNode"] = {
		varname = "heroNode",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onCardClick")}
		},
	},

	["panelLeft.imgActionDi"] = "imgActionBg",
	["panelLeft.imgIcon"] = "imgIcon",
	["panelLeft.imgIconBg"] = "imgIconBg",
	["panelCell"] = "panelCell",
	["panelRight"] = "panelRight",
	["panelRight.skinList"] = "skinList",

	["panelRight.panelNature"] = "panelNature",
	["panelRight.skinNoAdd"] = "skinNoAdd",
	["panelRight.panelNature.txtBuffObj"] = "txtBuffObj",
	["panelRight.panelNature.infoList"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("skinNativeDatas"),
				item = bindHelper.self("itemAttr"),
				itemCell = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local binds = {
						class = "listview",
						props = {
							data = v,
							item = list.itemCell,
							margin = 100,
							onItem = function(innerList, cell, kk ,vv)
								local childs = cell:multiget("title","num")
								childs.title:text(getLanguageAttr(vv.attrType))
								childs.num:text("+"..dataEasy.getAttrValueString(vv.attrType, vv.attrValue))
								adapt.oneLinePos(childs.title, childs.num, cc.p(5, 0), "left")
								local titWidth = childs.title:width()
								local numWidth = childs.num:width()
								cell:width(titWidth+numWidth+5)
							end
						}
					}
					bind.extend(list, node, binds)
				end
			}
		}
	},

	["panelRight.buttonLeft"] ={
		varname = "buttonLeft",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onButtonLeft")}
		}
	},
	["panelRight.buttonRight"] ={
		varname = "buttonRight",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onButtonRight")}
		}
	},
	["panelRight.buttonOp"] = {
		varname = "buttonOp",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onButtonOp")}
		}
	},
	["panelRight.buttonOp.text"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["panelRight.buttonBuy"] ={
		varname = "buttonBuy",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onButtonBuy")}
		}
	},
	["panelRight.buttonBuy.text"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["itemAttr"]= "itemAttr",
	["item"] = "item",
	["panelRight.imgDress"] = "imgDress",
	["panelRight.txtSkinDesc"] = "txtSkinDesc",
	["panelRight.txtLimitTime"] = "txtLimitTime",

}




function CardSkinView:onCreate(cardDbid)
	self.cardDbid = cardDbid

	self.selectID     = idler.new(0)
	self.selectSkinID = idler.new(0)
	self.starDatas    = idlertable.new({})
	self.attrDatas    = idlers.newWithMap({})
	self.skinDatas    = {}
	self.skinItemList = {}
	self.showTp       = idler.new(0)
	self.skinNativeDatas = idlers.new({})
	self.cardActionState = idler.new(1)

	self.skinChilds = {}

	self.count  = 10
	self:initModel()

	local card    = gGameModel.cards:find(cardDbid)
	self.cardName = idlereasy.assign(card:getIdler("name"), self.cardName)
	self.cardId   = idlereasy.assign(card:getIdler("card_id"), self.cardId)
	self.unitId   = idlereasy.assign(card:getIdler("unit_id"), self.unitId)
	self.skinId   = idlereasy.assign(card:getIdler("skin_id"), self.skinId)
	self.star     = idlereasy.assign(card:getIdler("star"), self.star)
	self.advance  = idlereasy.assign(card:getIdler("advance"), self.advance)
	self.level    = idlereasy.assign(card:getIdler("level"), self.level)

	uiEasy.setIconName("card", self.cardId:read(),
		{node = self.cardNameTxt, name = self.cardName:read(), advance = self.advance:read(), space = true})

	idlereasy.when(self.star, function(_, star)
		local starDatas = {}
		local starIdx = star - 6
		for i=1,6 do
			local icon = "common/icon/icon_star_d.png"
			if i <= star then
				icon = i <= starIdx and "common/icon/icon_star_z.png" or "common/icon/icon_star.png"
			end
			table.insert(starDatas, {icon = icon})
		end
		self.starDatas:set(starDatas)
	end)

	local id = userDefault.getForeverLocalKey("skinShowType", 0, {rawKey = true,  rawData = true})
	self.showTp:set(id)

	self.cardId:addListener(function(val, odlval)
		local unitId = csv.cards[val].unitID
		local unit   = csv.unit[unitId]
		local attrDatas = {}
		table.insert(attrDatas, unit.natureType)
		if unit.natureType2 then
			table.insert(attrDatas, unit.natureType2)
		end
		self.attrDatas:update(attrDatas)
		self.imgFlag:texture(ui.RARITY_ICON[unit.rarity])
	end)

	idlereasy.any({self.cardId, self.skins}, function(_, cardId, skinInfo)
		self:setSkinList(cardId, skinInfo)
		self:initSkinList()

		if self.selectID:read() ~= 0 then
			self.selectID:notify()
		end
	end)

	idlereasy.when(self.skinId, function(_, skinId)
		skinId = skinId or 0
		for index,v in ipairs(self.skinDatas) do
			if v.id and v.id == skinId then
				self.selectID:set(index - 1,true)
				break
			end
		end
	end)

	self.selectID:addListener(function(val, oldVal)
		local data    = self.skinDatas[val+1]

		self:setSkinInfo(data.id)
		self:setButtonInfo(data)
		self:setButtonEnabled()
		self:setAutoScroll(val)
		self:setLeftPanelInfo(data.unitId)
	end)

	idlereasy.when(self.showTp, function(_, tpye)
		self:setLeftPanelShow()
		self.cardActionState:set(3, true)
	end)


	idlereasy.when(self.cardActionState, function (_, cardState)
		self.cardSprite:setSpriteEventHandler()

		local size = self.heroNode:getContentSize()
		self.cardSprite:retain()
		self.cardSprite:removeFromParent()
		self.cardSprite:addTo(self.heroNode, 5)
			:xy(size.width/2, 0)
		self.cardSprite:release()

		if cardState ~= 1 then
			local count = 0
			self.cardSprite:setSpriteEventHandler(function(event, eventArgs)
				if cardState == 4  then
					count = count + 1
					if count > 5 then
						self.cardSprite:setSpriteEventHandler()
						self.cardActionState:set(1)
					end
				else
					self.cardSprite:setSpriteEventHandler()
					self.cardActionState:set(1)
				end

			end, sp.EventType.ANIMATION_COMPLETE)
		end

		if cardState == 4 then
			self.cardSprite:play(STATE_ACTION[cardState], false)
			for i = 2,5 do
				self.cardSprite:addPlay(STATE_ACTION[cardState])
			end
		else
			self.cardSprite:play(STATE_ACTION[cardState])
		end

		local cardCfg = csv.cards[self.cardId:read()]
		local soundsEffect = cardCfg.soundsEffect or {}
		if soundsEffect[STATE_ACTION[cardState]] then
			audio.playEffectWithWeekBGM(soundsEffect[STATE_ACTION[cardState]])
		end
	end)

	Dialog.onCreate(self)
end


function CardSkinView:initModel()
	self.skins = gGameModel.role:getIdler("skins")
end


-- 初始化数据
function CardSkinView:setSkinList(id,info)
	local card = csv.cards[id]
	local skinList = card.skinSkillMap
	local skinDatas = {}
	skinDatas[1] = {sign = false, rank = 0}

	local unitCsv = csv.unit[self.unitId:read()]
	skinDatas[2] =
	{
		sign          = true,
		id            = 0,
		skinType      = 1,
		days          = 0,
		isHas         = 0,
		icon          = unitCsv.cardShow,
		scale         = unitCsv.cardShowScale,
		posOffset     = unitCsv.cardShowPosC,
		rarity        = unitCsv.rarity,
		unitId        = self.unitId:read(),
		rank          = 1,
		name          = gLanguageCsv.skinStart,
		skinFrameType = 1,
	}

	for skinId,value in csvMapPairs(skinList) do
		local skinCsv = gSkinCsv[skinId]

		if skinCsv then
			local sign = skinCsv.isOpen
			if sign then
				local unitId = dataEasy.getUnitId(self.cardId:read(), skinId)
				local unitCsv = csv.unit[unitId]
				local data = {
					sign          = true,
					id            = skinId,
					skinType      = skinCsv.skinType,
					days          = skinCsv.days,
					isHas         = info[skinId] or false,
					icon          = unitCsv.cardShow,
					scale         = unitCsv.cardShowScale,
					posOffset     = unitCsv.cardShowPosC,
					rarity        = unitCsv.rarity,
					costMap       = skinCsv.costMap,
					skinFrameType = 0,
					skinFrameRes  = skinCsv.skinFrameRes,
					extraItem     = skinCsv.extraItem,
					isOpen        = skinCsv.isOpen,
					name          = skinCsv.name,
					desc          = skinCsv.desc,
					rank          = skinCsv.rank + 2,
					activeType    = skinCsv.activeType,
					unitId        = unitId,
				}
				skinDatas[#skinDatas+1] = data
			end
		end
	end

	skinDatas[#skinDatas+1] = {sign = false, rank = 99999}
	table.sort(skinDatas, function(v1, v2)
		return v1.rank < v2.rank
	end)
	self.skinDatas = skinDatas
end


-- cell初始化
function CardSkinView:initCell(cell, v, num)
	local childs = cell:multiget("ImageBg","labelName","imageAdd","imgLimitBg","labelInfo")
	nodetools.map({childs.imageAdd,childs.imgLimitBg,childs.labelInfo}, "visible", false)


	cell:visible(v.sign)

	if not v.sign then return end

	local size = childs.ImageBg:size()
	local maskValue = 80 			-- 部分遮罩不覆盖的地方 需要手动设置遮罩 0-255
	local mask = ccui.Scale9Sprite:create()

	mask:initWithFile(cc.rect(82, 82, 1, 1), "common/icon/mask_card.png")
	mask:size(size.width - 39, size.height - 39)
		:alignCenter(size)

	local sp     = cc.Sprite:create(v.icon)
	local spSize = sp:size()
	local soff   = cc.p(v.posOffset.x/v.scale, -v.posOffset.y/v.scale)
	local ssize  = cc.size(size.width/v.scale, size.height/v.scale)
	local rect   = cc.rect((spSize.width-ssize.width)/2-soff.x, (spSize.height-ssize.height)/2-soff.y, ssize.width, ssize.height)

	sp:alignCenter(size)
		:scale(v.scale + 0.2)
		:setTextureRect(rect)

	cell:removeChildByName("clipping")
	cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.1)
		:size(size)
		:alignCenter(cell:size())
		:add(sp)
		:addTo(cell, 5, "clipping")

	childs.labelName:text(v.name)
	if v.skinFrameType == 1 then
		childs.ImageBg:texture(SKIN_BG[v.rarity+2])
	else
		childs.ImageBg:texture(v.skinFrameRes)
	end

	bind.touch(self, cell, {scaletype = 0,clicksafe = true,methods = {ended = function()
						self.onButtonClick(self, num)
					end}})

	if v.isHas then return end

	if v.extraItem and csvSize(v.extraItem) == 1 then
		childs.imageAdd:visible(true)

		local key, num = csvNext(v.extraItem)
		local itemCsv = csv.items[key]
		local imgIcon     = cc.Sprite:create(itemCsv.icon)
		imgIcon:alignCenter(imgIcon:size())
			:scale(1.2)
			:xy(cc.p(80,80))
			:addTo(childs.imageAdd)
	end
end

-- 列表初始化
function CardSkinView:initSkinList()
	local childs = {}
	for index, data in ipairs(self.skinDatas) do
		local cell = self.panelCell:clone()
		childs[#childs + 1] = cell
		self:initCell(cell, data,index)
	end

	self.skinChilds = childs

	self.skinList:removeAllChildren()
	local anchor = self.panelCell:anchorPoint()
	local size = self.panelCell:size()

	for index, cell in pairs(childs) do
		local anchor = cell:anchorPoint()
		cell:xy(size.width*(anchor.x + index - 1),size.height*anchor.y)
		self.skinList:add(cell, #childs - index)
	end

	self.skinList:setInnerContainerSize(cc.size(#childs*size.width, size.height))
	self.skinList:setScrollBarEnabled(false)
	self.skinList:setInertiaScrollEnabled(false)
	local scrollViewSize = self.skinList:size()
	local containerSize  = self.skinList:getInnerContainerSize()
	local innter         = self.skinList:getInnerContainer()
	local length = scrollViewSize.width/2
	local dot   = containerSize.width - scrollViewSize.width

	local cellWidth = size.width

	local func = function()
		local intx = innter:x()
		for index, node in pairs(childs) do
			local pos = node:xy()
			local num = 1.1 - 0.4*math.abs(length - pos - intx)/length

			node:scale(num,num)
		end
	end

	self.skinList:onScroll(function(event)
		if event.name =="CONTAINER_MOVED" then
			func()

		elseif event.name =="SCROLLING_ENDED" then

			local intx = innter:x()
			intx = math.min(intx, 0)
			intx = math.max(intx, -dot)
			intx = math.abs(intx)

			local num   = intx%cellWidth
			local count = math.floor(intx/cellWidth)

			if num > cellWidth/2 then
				count = count + 1
			end

			self.selectID:set(count+1,true)
		end
	end)

	func()
end

-- 设置形象展示
function CardSkinView:setLeftPanelInfo(unitId)
	-- 动画
	local unit   = csv.unit[unitId]

	if self.cardSprite then
		self.cardSprite:removeFromParent()
	end
	local size = self.heroNode:getContentSize()
	self.cardSprite = widget.addAnimation(self.heroNode, unit.unitRes, "standby_loop", 5)
		:xy(size.width/2, 0)
	self.cardSprite:scale(unit.scaleU*3)
	self.cardSprite:setSkin(unit.skin)

	self.imgIcon:texture(unit.cardShow)
	self.cardActionState:set(3, true)
end


-- 设置皮肤属性
function CardSkinView:setSkinInfo(id)
	self.panelNature:visible(id ~= 0)
	self.skinNoAdd:visible(id == 0)
	if id == 0 then
		 return
	end

	local skinCsv = csv.card_skin[id]
	--创建列表
	local attrDatas = {}
	local index = 0

	index = skinCsv["attrAddType"]

	self.txtBuffObj:text(NATIVE_BUFF_OBJ[index])
	local temp = {}
	for i=1,6 do
		if i%3 == 1 then
			if i > 3 and #temp > 0 then
				attrDatas[#attrDatas + 1] = temp
			end
			temp = {}
		end

		local attrType = skinCsv["attrType"..i]
		if attrType and attrType ~= 0 then
			table.insert(temp, {attrType = attrType, attrValue = skinCsv["attrNum"..i]})
		end
	end

	if #temp > 0 then
		attrDatas[#attrDatas + 1] = temp
	end
	if #attrDatas > 0 then
		self.skinNativeDatas:update(attrDatas)
		local y = self.attrList:y() + self.attrList:height() - self.attrList:size().height
		self.panelNature:get("desc"):y(y)
	else
		self.panelNature:visible(false)
		self.skinNoAdd:visible(true)
	end
end

-- 设置srollview滑动指定位置
function CardSkinView:setAutoScroll(val)
	local scrollViewSize = self.skinList:size()
	local containerSize  = self.skinList:getInnerContainerSize()
	local innter         = self.skinList:getInnerContainer()
	local size           = self.panelCell:size()
	local dot            = containerSize.width - scrollViewSize.width

	local intx = innter:x()
	intx = math.min(intx, -1)
	intx = math.max(intx, -(dot+1))
	intx = math.abs(intx)

	local x = size.width*(val - 1)
	x = math.min(x, dot)
	if intx >= 0 and intx-2 <= dot then
		self.skinList:scrollToPercentHorizontal(x/dot*100, 0.4, true)
	end

	self.count = self.count + 1
	self.skinChilds[val+1]:setLocalZOrder(self.count)
end

-- 设置购买信息
function CardSkinView:setButtonInfo(val)
	local privilege = self.panelRight:get("privilege")
	if privilege then privilege:removeFromParent() end
	nodetools.map({self.imgDress,self.buttonOp,self.buttonBuy,self.txtLimitTime,self.txtSkinDesc}, "visible", false)

	if self.skinId:read() == val.id then
		self.imgDress:show()

	elseif val.isHas then
		self.buttonOp:show()

	elseif csvSize(val.costMap) > 0 then
		self.buttonBuy:show()
		local str = gLanguageCsv.skinXiaoFei
		local sign = true
		for index, value in csvMapPairs(val.costMap) do
			if dataEasy.getNumByKey(index) < value then
				sign = false
			end
			str = str..string.format("%d#I%s-56-56#",value,dataEasy.getIconResByKey(index))
		end

		local size = self.buttonBuy:size()
		local x,y = self.buttonBuy:xy()
		local richText = rich.createByStr(str, 40)
			:addTo(self.panelRight, 10, "privilege")
			:anchorPoint(1, 0.5)
			:xy(cc.p(x-size.width/2-10, y))
			:formatText()

		-- self.buttonBuy:setEnabled(sign)

	else
		self.txtSkinDesc:show()
		self.txtSkinDesc:text(val.desc)
	end


	if val.isHas and val.isHas > 0 then
		local lastTime = math.ceil(val.isHas)
		local curTime = time.getTime()

		if curTime < lastTime then
			self.txtLimitTime:show()

			local dotTime = lastTime -curTime
			local day = math.floor(dotTime / 3600 / 24)

			local strTip = ""
			-- 时间不足一天限时时分秒
			if day > 0 then
				strTip = string.format(gLanguageCsv.skinTip05, day)
				self.txtLimitTime:text(strTip)
			else
				local function setLabel()
					dotTime = lastTime -time.getTime()
	    			if dotTime < 0 then
	    				return false
	    			end
	    			local str = time.getCutDown(dotTime).clock_str
	    			strTip = string.format(gLanguageCsv.skinTip06,str)
	    			self.txtLimitTime:text(strTip)
	    			return true
	    		end

	    		setLabel()

				local scheduleTag = tag or 100-- 定时器tag
				-- 移除上次的刷新定时器
				self:enableSchedule():unSchedule(scheduleTag)
				self:schedule(function()
					if not setLabel() then
						-- 皮肤结束，刷新皮肤数据，重置
						gGameApp:requestServer("/game/sync")
						return false
					end
				end, 1, 1, scheduleTag)-- 1秒钟刷新一次
			end
		end
	end
end


-- 按钮状态
function CardSkinView:setButtonEnabled()
	local num = self.selectID:read()
	self.buttonRight:visible( num + 2 < #self.skinDatas)
	self.buttonLeft:visible(num > 1)
end

function CardSkinView:setLeftPanelShow()
	local sign = self.showTp:read() == 0
	self.heroNode:visible(sign)
	self.imgActionBg:visible(sign)
	self.imgIcon:visible(not sign)
	self.imgIconBg:visible(not sign)

	self.imgSwitch:xy(sign and cc.p(156,40) or cc.p(40,40))
	self.labelSwitch:xy(sign and cc.p(70,40) or cc.p(125,40))
	self.labelSwitch:text(sign and gLanguageCsv.skinAction or gLanguageCsv.skinImg)
end

-- 购买
function CardSkinView:onButtonBuy()
	local data = self.skinDatas[self.selectID:read() + 1]

	local str = gLanguageCsv.skinTip01

	local sign = true
	local key, num = csvNext(data.costMap)
	str = str..string.format("%d#I%s-56-56#",num,dataEasy.getIconResByKey(key))

	if dataEasy.getNumByKey(key) < num then
		sign = false
	end

	if sign  then
		gGameUI:showDialog({
			strs = string.format(gLanguageCsv.skinTip02,str,data.name),
			cb = function()
				gGameApp:requestServer("/game/card/skin/buy",function (tb)
					gGameUI:stackUI("city.card.skin.award", nil, nil,data.id)
				end, data.id)
			end,
			isRich = true,
			btnType = 2,
			dialogParams = {clickClose = false},
		})
	else
		uiEasy.showDialog(key)
	end
end


function CardSkinView:onCardClick()
	local old = self.cardActionState:read()
	local rand
	repeat
		rand = math.random(2, #STATE_ACTION)
	until rand ~= old
	self.cardActionState:set(rand, true)
end


-- 右边的按钮
function CardSkinView:onButtonRight()
	local num = self.selectID:read()
	num =math.min(num+1, #self.skinDatas-2)
	self.selectID:set(num)
end

-- 左边按钮
function CardSkinView:onButtonLeft()
	local num = self.selectID:read()
	num =math.max(num-1, 1)
	self.selectID:set(num)
end

-- 使用
function CardSkinView:onButtonOp()
	local data = self.skinDatas[self.selectID:read() + 1]
	gGameApp:requestServer("/game/card/skin/use",function (tb)
		gGameUI:showTip(gLanguageCsv.skinTip03)
	end, data.id,self.cardDbid)
end

-- 显示切换
function CardSkinView:onBtnSwitch()
	local tp = self.showTp:read()
	tp = tp == 0 and 1 or 0
	self.showTp:set(tp)
end

function CardSkinView:onButtonClick(index)
	self.selectID:set(index - 1)
	local delay = 0.2
	self.skinList:setEnabled(false)
	performWithDelay(self.skinList, function()
		self.skinList:setEnabled(true)
	end, delay)
end

function CardSkinView:onClose()
	Dialog.onClose(self)
	userDefault.setForeverLocalKey("skinShowType", self.showTp:read(), {rawKey = true})
end


return CardSkinView