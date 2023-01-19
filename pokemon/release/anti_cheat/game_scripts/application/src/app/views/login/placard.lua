-- @desc: 公告

local SHOW_TYPE = {
	PAGE = 1,
	DROP_DOWN = 2,
}

local LoginPlacardView = class("LoginPlacardView", Dialog)
LoginPlacardView.RESOURCE_FILENAME = "login_placard.json"
LoginPlacardView.RESOURCE_BINDING = {
	["leftPanel.item"] = "leftItem",
	["leftPanel.leftList"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("areaList"),
				itemSize = bindHelper.self("leftListCount"),
				item = bindHelper.self("leftItem"),
				asyncPreload = 7,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
						text.addEffect(panel:get("txt"), {glow = {color = ui.COLORS.GLOW.WHITE}})
					else
						selected:hide()
						panel = normal:show()
					end
					local maxWidth = selected:size().width - 30
					adapt.setTextScaleWithWidth(panel:get("txt"), v.name, maxWidth)
					node:onClick(functools.partial(list.clickCell, k, v))
				end,
				onAfterBuild = function (list)
					list:setTouchEnabled(#list.data >= list.asyncPreload)
				end
			},
			handlers = {
				clickCell = bindHelper.self("onChooseArea")
			},
		},
	},
	["rightList"] = "contentList",
	["rightContentList"] = "rightContentList",
	["bottomPanel.btnKnow"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlacardClose")},
		},
	},
	["bottomPanel.icon"] = {
		varname = "checkStatus",
		binds = {
			event = "click",
			method = bindHelper.self("onCheckBox")
		},
	},
	["bottomPanel.tip"] = {
		varname = "bottomTip",
		binds = {
			event = "click",
			method = bindHelper.self("onCheckBox")
		},
	},
	["topBg"] = "topBg",
	["titleItem"] = "titleItem",
	["contentItem"] = "contentItem",
	["leftPanel"] = "leftPanel",
}

local TabDefines = {
	{
		key = "activity",
		styleType = SHOW_TYPE.DROP_DOWN,
		name = gLanguageCsv.activityBoard,
	},
	{
		key = "update",
		styleType = SHOW_TYPE.PAGE,
		name = gLanguageCsv.updateContent,
	},
	{
		key = "caution",
		styleType = SHOW_TYPE.PAGE,
		name = gLanguageCsv.cautionBoard,
	},
	{
		key = "note1",
		styleType = SHOW_TYPE.PAGE,
		name = gLanguageCsv.note1Content,
	},
	{
		key = "note2",
		styleType = SHOW_TYPE.PAGE,
		name = gLanguageCsv.note2Content,
	},
}

function LoginPlacardView:onPlacardClose()
	sdk.trackEvent(18)
	Dialog.onClose(self)
end

function LoginPlacardView:onCreate(notice)
	notice = notice or {}
	self.bottomTip:setTouchEnabled(true)
		--重新组装一遍数据
	local data = {}
	for _, t in ipairs(TabDefines) do
		if notice[t.key] then
			t.content = notice[t.key]
			table.insert(data, t)
		end
	end


	self.content = self:getResourceNode()
	self.topBg:hide()

	self.contentList:setScrollBarEnabled(false)
	self.rightContentList:setScrollBarEnabled(false)
	self.data = data
	self.banner = notice.banner or {}
	self:initData()
	if #data > 0 then
		self.showTab = idler.new(1)
		self.showTab:addListener(function(val, oldval, idler)
			self.areaList:atproxy(oldval).select = false
			self.areaList:atproxy(val).select = true
			-- self.selected = val
			self:showContent(self.data[val])
		end)
	end

	uiEasy.addTabListClipping(self.leftList, self.leftPanel)

	-- only for dev
	local cnt = 0
	self.leftPanel:onClick(function()
		cnt = cnt + 1
		if cnt ~= 10 then return end
		local ButtonNormal = "img/editor/btn_1.png"
		local ButtonClick = "img/editor/btn.png"
		local node = cc.Node:create()
		local blackLayer = ccui.Layout:create()
			:size(display.sizeInView)
			:xy(-display.sizeInView.width/2, -display.sizeInView.height/2)
		blackLayer:setBackGroundColorType(1)
		blackLayer:setBackGroundColor(cc.c3b(91, 84, 91))
		blackLayer:setBackGroundColorOpacity(204)
		blackLayer:setTouchEnabled(true)
		local box = ccui.EditBox:create(cc.size(400, 100), "")
		box:setText("TianJi")
		box:setFontColor(ui.COLORS.RED)
		local btn = ccui.Button:create(ButtonNormal, ButtonClick)
		btn:setTitleText("OK")
		btn:setTitleColor(cc.c3b(0, 0, 0))
		btn:setTitleFontSize(30)
		btn:setOpacity(100)
		btn:setPressedActionEnabled(true)
		btn:xy(0, -100):show()
		btn:addClickEventListener(function()
			local code = box:getText()
			print("dev code", code)
			if code == "163hzyoumi" then
				DEBUG = 2
				CC_SHOW_FPS = true
				EDITOR_ENABLE = true

				display.director:setDisplayStats(true)
				printInfo('------ Editor init ------')
				local editor = require("editor.builder")
				editor:init(gGameUI.scene)
				printInfo('------------')

				self.parent_:testInLogin()

				-- 可输入回退patch
				local patchKey = "96773f3f45bb6396332b079593367c71"
				local oldPatch = userDefault.getForeverLocalKey(patchKey, 1, {rawKey = true})
				printInfo("oldPatch:%d", oldPatch)
				label.create("patch:", {fontSize = 45, color = ui.COLORS.NORMAL.DEFAULT})
					:anchorPoint(0, 0.5)
					:xy(700, 290)
					:addTo(self, 999)
				local input = ccui.EditBox:create(cc.size(300, 60), "common/box/box_topui.png")
					:anchorPoint(0, 0.5)
					:xy(820, 290)
					:color(cc.c3b(200, 200, 200))
					:setText(oldPatch)
					:addTo(self, 999)
				input:setFontSize(45)
				input:setFontColor(ui.COLORS.NORMAL.DEFAULT)
				local btn = ccui.Button:create("common/btn/btn_normal_red.png")
					:setTitleText("确定")
					:setTitleFontSize(72)
					:xy(900, 200)
					:addTo(self, 999)
					:scale(0.5)
				bind.touch(self, btn, {methods = {ended = function()
					local patch = tonumber(input:getText())
					if not patch then
						gGameUI:showTip("请输入patch值")
					else
						userDefault.setForeverLocalKey(patchKey, patch, {rawKey = true})
						gGameUI:showTip("patch值已修改为%d, 请重新登录", patch)
					end
				end}})
			end
			node:removeSelf()
		end)
		node:add(blackLayer, -99):add(box):add(btn):xy(display.sizeInView.width/2, display.sizeInView.height/2):addTo(gGameUI.scene, 999)
	end)

	Dialog.onCreate(self)
end

function LoginPlacardView:onChooseArea(list, key, val, event)
	self.showTab:set(key)
end

function LoginPlacardView:onChooseImg(list, key, val, event)
	print("click choose placard img!")
end

function LoginPlacardView:onCheckBox()
	self.checkStatusVisible = not self.checkStatusVisible
	local currTime = os.date("%Y%m%d", os.time())
	userDefault.setForeverLocalKey("placardStatusDay", {[currTime] = self.checkStatusVisible}, {rawKey = true})
	self.checkStatus:texture(self.checkStatusVisible and "common/icon/radio_selected.png" or "common/icon/radio_normal.png")
end

function LoginPlacardView:initData()
	local currTime = os.date("%Y%m%d", os.time())
	local data = userDefault.getForeverLocalKey("placardStatusDay", {}, {rawKey = true, rawData = true})
	-- nil 首次登录为勾选状态
	self.checkStatusVisible = data[currTime] ~= false
	userDefault.setForeverLocalKey("placardStatusDay", {[currTime] = self.checkStatusVisible}, {rawKey = true})
	self.checkStatus:texture(self.checkStatusVisible and "common/icon/radio_selected.png" or "common/icon/radio_normal.png")
	self:topInit()

	self.selected = 2
	local areaList = {}
	-- 公告条数
	local count = #self.data
	for i = 1, count do
		local value = {
			iconRes = self.selected == i and "common/box/tab_s.png" or "common/box/tab_n.png",
			name = self.data[i].name,
			effects = {
				['color'] = ui.COLORS.NORMAL.WHITE,
				['outline'] = self.selected == i and {color = ui.COLORS.OUTLINE.ORANGE} or {color = ui.COLORS.OUTLINE.DEFAULT},
			}
		}
		table.insert(areaList, value)
	end
	self.areaList = idlers.newWithMap(areaList)
	self.leftListCount = count

	-- 先显示第一个内容
	self:showContent(self.data[self.selected])
end

function LoginPlacardView:topInit()
	local iconRes = self.banner
	local realSize = self.topBg:size()
	local size = self.topBg:box()
	local topBgPosx, topBgPosy = self.topBg:xy()
	local rect = cc.rect(29, 42, 1, 1)
	local sp = ccui.ImageView:create("login/img_banner_01@.png")
	sp:scale(2):xy(size.width/2, size.height/2)
	local priorSp = sp:clone()
	priorSp:x(- size.width/2)
	local nextSp = sp:clone()
	nextSp:x(1.5*size.width)

	local mask = ccui.Scale9Sprite:create()
	mask:initWithFile(rect, "login/box_mask_banner.png")
	mask:size(realSize.width * 2, realSize.height * 2):xy(size.width/2, size.height/2)
	local clipNode = cc.ClippingNode:create(mask)
	clipNode:setAlphaThreshold(0.01)
	clipNode:add(sp):add(priorSp):add(nextSp)
	clipNode:xy(topBgPosx - size.width/2, topBgPosy - size.height/2)
	self.content:add(clipNode, self.topBg:z() + 1)

	local index = 0
	local _playAction = function(dt, nextIndex)
		if #iconRes == 0 then
			return
		end
		index = nextIndex and index + nextIndex or index + 1
		index = index > #iconRes and 1 or index
		index = index < 1 and #iconRes or index
		sp:loadTexture(iconRes[index])
		local pIndex = index > 1 and index - 1 or #iconRes
		priorSp:loadTexture(iconRes[pIndex])
		local nIndex = index < #iconRes and index + 1 or 1
		nextSp:loadTexture(iconRes[nIndex])
	end

	local dt = 3
	-- 间隔dt时间更换一次图片
	self:enableSchedule()
		:schedule(_playAction, dt, 0, 1)

	local tic = 0
	local spx = sp:x()
	local priorSpx = priorSp:x()
	local nextSpx = nextSp:x()
	-- 如果移动的位置超过某个值的时候就切换下一张图片
	local offsetX = 0
	local beganPosX = 0
	sp:setTouchEnabled(true)
	sp:addTouchEventListener(function(sender, eventType)
		-- 在文件开始的时候记录下图片的位置，一般也只需要移动y就可以了
		if eventType == ccui.TouchEventType.began then
			local beganPos = sender:getTouchBeganPosition()
			self:unSchedule(1)
			self:unSchedule(2)
			tic = os.clock()
			beganPosX = beganPos.x

		elseif eventType == ccui.TouchEventType.moved then
			local movedPos = sender:getTouchMovePosition()
			offsetX = beganPosX - movedPos.x
			sp:x(spx - offsetX)
			priorSp:x(priorSpx - offsetX)
			nextSp:x(nextSpx - offsetX)

		elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
			-- 下一张图片
			self:unSchedule(2)
			local flag = offsetX / ((os.clock() - tic) ^ 2)
			if offsetX >= size.width/2 or flag > 3000 then
				local play = functools.partial(_playAction, dt, 1)
				play()
			-- 上一张图片
			elseif offsetX <= -size.width/2 or flag <= -3000 then
				local play = functools.partial(_playAction, dt, -1)
				play()
				-- print(offsetX, "上一张图片")

			-- 保持本张图片不变
			-- else
			-- 	print(offsetX, "保持不变", spx, beganPosX, offsetX)
			end
			priorSp:x(priorSpx)
			nextSp:x(nextSpx)
			sp:x(spx)
			self:schedule(_playAction, dt, dt, 1)
		end
	end)
end

-- 设置content内容, 分两种显示格式: 整页式 和 下拉式, 样式类型设置到data数据中,记录传入时补充上
function LoginPlacardView:showContent(data)
	data = data or {}
	local styleType = data.styleType
	self.contentList:visible(styleType == SHOW_TYPE.PAGE)
	self.rightContentList:visible(styleType ~= SHOW_TYPE.PAGE)
	if styleType == SHOW_TYPE.PAGE then 		-- 整页式
		self:setStyle1List(data.content)
	else						-- 下拉式
		if not self.initState then
			self:setStyle2List(data.content)
		end
	end
end

function LoginPlacardView:setStyle1List(contents)
	if not contents then return end
	local list = self.contentList
	list:removeAllChildren()
	local richtextWidth = self.contentItem:get("downList"):size().width - 40	-- 与style2富文本宽度保持一致
	local item = self.titleItem
	list:setItemsMargin(30)
	for _, content in ipairs(contents) do
		local cloneItem = item:clone()		-- 标题
		cloneItem:get("title"):text(content.title)
		list:pushBackCustomItem(cloneItem)
		cloneItem:show()
		-- 内容
		local richtext = rich.createWithWidth("#C0x55504D#" .. content.content, 40, deltaSize, richtextWidth)
		list:pushBackCustomItem(richtext)
	end
end

function LoginPlacardView:setStyle2List(contents)
	if not contents then return end
	self.initState = true
	local list = self.rightContentList
	list:removeAllChildren()
	list:setItemsMargin(10)
	local item = self.contentItem
	local originalSize = item:size()
	local kuangWidth = item:get("downList"):size().width		--下拉区域的框宽度
	list.curItem = nil

	--
	local newSetting = {}
	local cloneOneItem
	local clickFunc

	-- clone and 设置信息
	cloneOneItem = function(idx)
		idx = idx or (list.curItem and list.curItem.idx)
		if not idx then return end
		local id = contents[idx].id
		local cloneItem = item:clone()
		cloneItem:z(idx)
		cloneItem:get("title"):text(contents[idx].titlebar)
		cloneItem.idx = idx
		cloneItem:get("tag"):visible(not newSetting[id])
		cloneItem.isDropDown = false
		cloneItem:get("bg"):onClick(functools.partial(clickFunc, cloneItem))
		return cloneItem
	end

	-- 点击
	clickFunc = function(clickedItem)
		-- 创建带有下拉的
		local idx = clickedItem.idx
		local id = contents[idx].id
		newSetting[id] = true
		userDefault.setForeverLocalKey("placardNews", {[id] = true}, {rawKey = true})

		local newItem = cloneOneItem(idx)	-- 创建一个带有常规显示内容item
		local kuangHeight = 100				-- 下拉框的高度, 需要根据text内容来变化
		if not clickedItem.isDropDown then	-- 给item增加下拉的内容显示
			-- 设置下拉后显示的内容
			local kuang = newItem:get("downList")
			local function addItem(v)
				local item = self.titleItem:clone()
				item:get("title"):text(v.title)
				item:anchorPoint(0, 1)
				kuangHeight = kuangHeight + item:size().height + 30
				item:show()
				local richtext = rich.createWithWidth("#C0x55504D#" .. v.content, 40, deltaSize, kuangWidth - 40)	-- richText 内容(目前暂时只设置了文本的)
				local textSize = richtext:size()
				richtext:anchorPoint(0, 1)
				kuangHeight = kuangHeight + textSize.height --+30*2+30*2 + 40
				richtext:xy(15, kuangHeight - 120)
				item:xy(10, kuangHeight - 40)
				kuang:add(richtext)
				kuang:add(item)
			end

			local strs = contents[idx].content
			local flag = false
			for i = #strs, 1, -1 do
				-- 先找有没有指定渠道的内容
				local v = strs[i]
				if v.channel == APP_CHANNEL then
					addItem(v)
					flag = true
				end
			end
			-- 没有指定渠道的内容，则显示渠道为空的内容
			if not flag then
				for i = #strs, 1, -1 do
					local v = strs[i]
					if not v.channel then
						addItem(v)
					end
				end
			end
			kuang:size(kuangWidth - 40, kuangHeight)
			kuang:show()
			newItem.isDropDown = true
			newItem:get("btn"):rotate(180)
		end
		-- 创建一个容器放置 newItem
		local layout =  ccui.Layout:create()
		local newHeight = originalSize.height + (kuangHeight > 0 and kuangHeight - 100 or 0)		-- 需要减去上面压住的30像素
		layout:size(cc.size(originalSize.width, newHeight))
		layout:setAnchorPoint(cc.p(0.5, 0.5))
		layout:addChild(newItem)
		newItem:xy(newItem:size().width/2, newHeight - 44)
		newItem:show()
		-- 先删除, 再添加(这个顺序从0开始的)
		list:removeItem(idx-1)
		list:insertCustomItem(layout, idx-1)

		list.curItem = newItem

		list:jumpToItem(idx-1, cc.p(0,1), cc.p(0,1))
	end
	list.total = #contents
	-- 初次加item
	local setting = userDefault.getForeverLocalKey("placardNews", {}, {rawKey = true})
	for i, content in ipairs(contents) do
		newSetting[content.id] = setting[content.id]
		local cloneItem = cloneOneItem(i)
		cloneItem:setTouchEnabled(true)
		cloneItem:show()
		list:pushBackCustomItem(cloneItem)
		if i == 1 then
			clickFunc(cloneItem)
		end
	end
	userDefault.setForeverLocalKey("placardNews", newSetting, {new = true, rawKey = true})
end

return LoginPlacardView