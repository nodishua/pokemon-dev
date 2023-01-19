
local ViewBase = cc.load("mvc").ViewBase
local GymBuffTree = class("GymBuffTree", ViewBase)

GymBuffTree.RESOURCE_FILENAME = "gym_buff.json"
GymBuffTree.RESOURCE_BINDING = {
	["bufItem"] = "bufItem",
	["leftPanel"] = "leftPanel",
	["leftPanel.item"] = "leftItem",
	["leftPanel.listview"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftDatas"),
				item = bindHelper.self("leftItem"),
				showTab = bindHelper.self("showTab"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
						panel:get("subTxt"):text(v.subName)
					end
					panel:get("txt"):text(v.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
					adapt.setTextScaleWithWidth(panel:get("txt"), nil, 300)
					local a = bindHelper.self("gymDatas"),
					bind.extend(list, node, {
						class = "red_hint",
						props = {
							specialTag = "gymBuffTab",
							state = list.showTab:read() ~= k,
							listenData = {
								treeId = k,
								gymDatas = bindHelper.parent("gymDatas"),
								round = gGameModel.gym:getIdler("round")
							},
							onNode = function(panel)
								panel:xy(340, 160)
							end,
						},
					})

				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["scrollview"] = {
		varname = "scrollview",
		binds = {
			event = "scrollBarEnabled",
			data = false,
		}
	},
	["rightTopPanel"] = "rightTopPanel",
	["rightTopPanel.textPoint"] = "textPoint",
	["rightTopPanel.btnAdd"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddClick")}
		}
	},
	["btnReset"] = {
		varname = "btnReset",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onResetClick")}
		}
	}
}

function GymBuffTree:onCreate(data)
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.gymBuff, subTitle = "CHALLENGE ADD"})
	self:initData()
	self:initModel()
end

function GymBuffTree:initModel()
	self.showTab = idler.new(1)
	self.treeId = idler.new(1)
	local leftData = {}
	for k,v in orderCsvPairs(csv.gym.talent_tree) do
		leftData[k] = {name = v.name,  subName = v.desc, select = false}
	end
	self.leftDatas = idlers.newWithMap(leftData)
	self.showTab:addListener(function(val, oldval)
		self.leftDatas:atproxy(oldval).select = false
		self.leftDatas:atproxy(val).select = true
		self.treeId:set(val)
	end)
	self.unlockTable = idlertable.new()
	self.gymDatas = gGameModel.role:getIdler("gym_datas")
	idlereasy.any({self.gymDatas, self.treeId}, function(_, gymDatas, treeID)
		self.depthData = {}
		self:refreshShowData(treeID)
		self.textPoint:text(gymDatas.gym_talent_point)
		adapt.oneLinePos(self.rightTopPanel:get("btnAdd"), {self.textPoint, self.rightTopPanel:get("textNote"), self.rightTopPanel:get("imgIcon") }, {cc.p(10,0), cc.p(5,0),cc.p(10,0)}, "right")
		local tree = gymDatas.gym_talent_trees[treeID] or {}
		local unlockTable = {}
		for id, lv in pairs(tree.talent or {}) do
			local depth = csv.gym.talent_buff[id].depth
			self.depthData[treeID] = self.depthData[treeID] or {}
			self.depthData[treeID][depth] = id
		end
		for id, icon in orderCsvPairs(csv.gym.talent_buff) do
			unlockTable[id] = self:checkUnlock(id)
		end
		self.unlockTable:set(unlockTable)

		for id, icon in pairs(self.bufIcons) do
 			if tree.talent and tree.talent[id] then
				self:refreshBufIcon(id, tree.talent[id])
			else
				self:refreshBufIcon(id, 0)
			end
		end
		if itertools.isempty(gymDatas.gym_talent_trees) then
			uiEasy.setBtnShader(self.btnReset,self.btnReset:get("textNote"), 3)
		else
			uiEasy.setBtnShader(self.btnReset,self.btnReset:get("textNote"), 1)
		end
	end)
	local textNote1 = self.rightTopPanel:get("textNote1"):hide()
	local richText = rich.createByStr(string.format(gLanguageCsv.gymBuffDesc, gCommonConfigCsv.gymAutoRecoverPoints), 40)
		:xy(cc.p(textNote1:xy()))
		:anchorPoint(1, 0.5)
		:addTo(self.rightTopPanel, 3)
	self.buyTimes = gGameModel.daily_record:getIdler("gym_talent_point_buy_times")
end


function GymBuffTree:initData( )
	local data = {}
	for id, cfg in orderCsvPairs(csv.gym.talent_buff) do
		data[id] = {id = id}
		for k, v in pairs(cfg) do
			data[id][k] = v
		end
	end
	for id, cfg in pairs(data) do
		--寻找后置
		for i, preID in pairs(cfg.preTalentIDs or {}) do
			data[preID].nextTalentIDs = data[preID].nextTalentIDs or {}
			table.insert(data[preID].nextTalentIDs, id)
		end
	end
	-- treeID 分类
	self.cfgData = {}
	for id, cfg in pairs(data) do
		self.cfgData[cfg.treeID] = self.cfgData[cfg.treeID] or {}
		self.cfgData[cfg.treeID][id] =  cfg
	end
end

function GymBuffTree:createBufIcon(id)
	local cfg = csv.gym.talent_buff[id]
	local item = self.bufItem:clone()
		:z(5)
		:scale(cfg.iconRate)
	local icon = item:get("imgBg.icon")
		:texture(cfg.icon)
	item:setTouchEnabled(true)
	bind.touch(self,  item, {methods = {ended = function()
			local unlockTable = self.unlockTable:read()
			local preLv, needPerLv = self:getPreLv(id)
			gGameUI:stackUI("city.adventure.gym_challenge.buff_detail", nil, {blackLayer = true, clickClose = true}, id, unlockTable[id], preLv, needPerLv)
		end}})
	self.bufIcons[id] = item
	bind.extend(self, self.bufIcons[id], {
		class = "red_hint",
		props = {
			specialTag = "gymBuffIcon",
			listenData = {
				id = id,
				round = gGameModel.gym:getIdler("round"),
				gymDatas = bindHelper.self("gymDatas"),
			},
			onNode = function (panel)
				panel:x(panel:x() - 10)
				panel:y(panel:y() - 10)
			end
		},
	})
	return item
end

function GymBuffTree:refreshBufIcon(id, lv)
	local bufItem = self.bufIcons[id]
	local unlock = self.unlockTable:read()[id]
	if unlock == false then
		bufItem:get("imgLockBg"):show()
		bufItem:get("imgLvBg"):hide()
		bufItem:get("textLv"):hide()
	else
		bufItem:get("imgLockBg"):hide()
		bufItem:get("imgLvBg"):show()
		bufItem:get("textLv"):show()
	end
	for preId, lines in pairs(self.lines[id]) do
		for _, line in ipairs(lines) do
			if unlock == false then
				line:setColor(cc.c4b(183,176,158, 255/2))
				line:z(0)
			else
				if self.unlockTable:read()[preId] == false then
					line:setColor(cc.c4b(183,176,158, 255/2))
					line:z(0)
				else
					line:setColor(cc.c4b(241,59,84, 255))
					line:z(1)
				end
			end
		end
	end
	bufItem:get("textLv"):text("Lv."..lv)
end

function GymBuffTree:checkUnlock(id)
	local cfg = csv.gym.talent_buff[id]
	local preId = cfg.preTalentIDs
	local preLevel = cfg.preLevel
	local depth = cfg.depth
	local tree = self.gymDatas:read().gym_talent_trees[cfg.treeID] or {}
	local lv = tree.talent and tree.talent[id] or 0
	if lv > 0 then
		return true
	end
	if depth == 1 then
		return true
	end
	if self.depthData[cfg.treeID] and self.depthData[cfg.treeID][depth] and self.depthData[cfg.treeID][depth] ~= id  then
		return false
	end
	for _, _id in ipairs(preId) do
		local lv = tree.talent and tree.talent[_id] or 0
		if lv >= preLevel then
			return true
		end
	end
	return false
end

function GymBuffTree:getPreLv(id)
	local cfg = csv.gym.talent_buff[id]
	local preId = cfg.preTalentIDs
	local preLevel = cfg.preLevel
	local depth = cfg.depth
	local tree = self.gymDatas:read().gym_talent_trees[cfg.treeID] or {}
	local lv = tree.talent and tree.talent[id] or 0
	if depth == 1 then
		return 0, 0
	end
	for _, _id in ipairs(preId) do
		local lv = tree.talent and tree.talent[_id]
		if lv and lv ~= 0 then
			return lv, cfg.preLevel
		end
	end
	return 0, cfg.preLevel
end

function GymBuffTree:getDepthData(index)
	local data = {}
	local maxW = 0  --一行最大多少列
	for i, cfg in pairs(self.cfgData[index]) do
		data[cfg.depth] = data[cfg.depth] or {}
		table.insert(data[cfg.depth], cfg)
		maxW = math.max(maxW, #data[cfg.depth])
	end

	for k, v in ipairs(data) do
		table.sort(v, function(a, b)
			return a.id < b.id
		end)
	end
	return data, maxW
end

function GymBuffTree:drawBufIcon(data, maxW)
	local width =  self.scrollview:width()
	local maxDepth = #data
	local containerSize = cc.size(width, math.max(maxDepth * 300 - 100, 1120))
	local spacingY1 = 350	-- 普通间距
	local spacingY2 = 180 -- 一二行间距特殊
	local spacingX = (containerSize.width - 300) / (maxW - 1)
	self.scrollview:setInnerContainerSize(containerSize)
	local posY = containerSize.height - 120
	for i, v in ipairs(data) do
		local iconY = 0
		if i == 1 then
			iconY = posY
			posY = iconY
		elseif i == 2 or i == #data then
			iconY = posY - spacingY2
			posY = iconY
		else
			iconY = posY - spacingY1
			posY = iconY
		end
		for ii, vv in ipairs(v) do
			local icon = self:createBufIcon(vv.id)
				:addTo(self.scrollview)
			if #v == 2 then
				icon:xy(width/3 * (ii), iconY)
			else
				local pos1 = width/2 - spacingX/2 * (#v - 1)
				local iconX = pos1 + spacingX *(ii - 1)
				icon:xy(iconX, iconY)
			end
			data[i][ii].pos = cc.p(icon:xy())
			data[i][ii].icon = icon
		end
	end
end

function GymBuffTree:drawLine(data)
	self.lines = {} -- key preId
	for i, v in ipairs(data) do
		for ii, vv in ipairs(v) do
			local lines = {}
			self.lines[vv.id] = lines
			local leftData, rightData, preNum
			if i > 1 then
				if #data[i - 1] > #v then
					leftData = data[i - 1][ii]
					rightData = data[i - 1][ii + 1]

				elseif #data[i - 1] < #v then
					leftData = data[i - 1][ii - 1]
					rightData = data[i - 1][ii]
				end
				preNum = (leftData and rightData) and 2 or 1
			end
			local iconWidth = vv.icon:getBoundingBox().width/2
			local cornerWidth = 22
			if i == 2 then --第一排 左右划线
				if leftData then
					local leftLines = {}
					local data1 = leftData
					local parentIconWidth = data1.icon:getBoundingBox().width/2
					local cornerL = ccui.ImageView:create("city/adventure/gym_challenge/bar_1.png")
					table.insert(leftLines,cornerL)
					cornerL:scaleX(1)
						:anchorPoint(22/32, 22/32)
						:xy(vv.pos.x, data1.pos.y)
						:addTo(self.scrollview)

					local vertical = ccui.Scale9Sprite:create()
					table.insert(leftLines,vertical)
					vertical:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
					vertical:height(data1.pos.y - vv.pos.y - cornerWidth - iconWidth)
						:anchorPoint(0.5, 1)
						:xy(vv.pos.x, data1.pos.y - cornerWidth)
						:addTo(self.scrollview)

					local horizontal = ccui.Scale9Sprite:create()
					table.insert(leftLines,horizontal)
					horizontal:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
					horizontal:height(math.abs(vv.pos.x - data1.pos.x) - cornerWidth - parentIconWidth)
						:setRotation(270)
						:anchorPoint(0.5, 0)
						:xy(vv.pos.x - cornerWidth, data1.pos.y)
						:addTo(self.scrollview)
					lines[leftData.id] = leftLines
				end
				if rightData then
					local rightLines = {}
					local data1 = rightData
					local parentIconWidth = data1.icon:getBoundingBox().width/2
					local cornerL = ccui.ImageView:create("city/adventure/gym_challenge/bar_1.png")
					table.insert(rightLines,cornerL)
					cornerL:scaleX(-1)
						:anchorPoint(22/32, 22/32)
						:xy(vv.pos.x, data1.pos.y)
						:addTo(self.scrollview)

					local vertical = ccui.Scale9Sprite:create()
					table.insert(rightLines,vertical)
					vertical:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
					vertical:height(data1.pos.y - vv.pos.y - cornerWidth - iconWidth)
						:anchorPoint(0.5, 1)
						:xy(vv.pos.x, data1.pos.y - cornerWidth)
						:addTo(self.scrollview)

					local horizontal = ccui.Scale9Sprite:create()
					table.insert(rightLines,horizontal)
					horizontal:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
					horizontal:height(math.abs(vv.pos.x - data1.pos.x) - cornerWidth - parentIconWidth)
						:setRotation(90)
						:anchorPoint(0.5, 0)
						:xy(vv.pos.x + cornerWidth, data1.pos.y)
						:addTo(self.scrollview)
					lines[rightData.id] = rightLines
				end
			elseif i == #data  then --最后一行
				local posY = vv.pos.y
				if leftData then
					local leftLines = {}
					if #leftData.nextTalentIDs == 1 then
						local data1 = leftData
						local parentIconWidth = data1.icon:getBoundingBox().width/2
						local cornerL = ccui.ImageView:create("city/adventure/gym_challenge/bar_1.png")
						table.insert(leftLines,cornerL)
						cornerL:scale(-1)
							:anchorPoint(22/32, 22/32)
							:xy(data1.pos.x, vv.pos.y)
							:addTo(self.scrollview)

						local vertical = ccui.Scale9Sprite:create()
						vertical:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						table.insert(leftLines,vertical)
						vertical:height(data1.pos.y - vv.pos.y - cornerWidth - parentIconWidth + 10)
							:anchorPoint(0.5, 0)
							:xy(cornerL:x(), cornerL:y() + cornerWidth)
							:addTo(self.scrollview)

						local horizontal = ccui.Scale9Sprite:create()
						table.insert(leftLines,horizontal)
						horizontal:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						horizontal:height(math.abs(vv.pos.x - data1.pos.x) - vv.icon:getBoundingBox().width/2 - cornerWidth)
							:setRotation(90)
							:anchorPoint(0.5, 0)
							:xy(cornerL:x() + cornerWidth, cornerL:y())
							:addTo(self.scrollview)
					else
						local horizontalL = ccui.Scale9Sprite:create()
						table.insert(leftLines, horizontalL)
						horizontalL:initWithFile(cc.rect(15, 10, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						horizontalL:height(vv.pos.x - leftData.pos.x -  vv.icon:getBoundingBox().width/2)
							:setRotation(90)
							:anchorPoint(0.5, 0)
							:xy(leftData.pos.x, posY)
							:addTo(self.scrollview)

						local verticalL = ccui.Scale9Sprite:create()
						table.insert(leftLines,verticalL)
						verticalL:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						local iconLHight = leftData.icon:getBoundingBox().height/2
						verticalL:height(leftData.pos.y - posY - iconLHight + 10)
							:anchorPoint(0.5, 0)
							:xy(leftData.pos.x, posY - 10)
							:addTo(self.scrollview)
					end
					lines[leftData.id] = leftLines
				end

				if rightData then
					local rightLines = {}
					if #rightData.nextTalentIDs == 1 then
						local data1 = rightData
						local parentIconWidth = data1.icon:getBoundingBox().width/2
						local cornerR = ccui.ImageView:create("city/adventure/gym_challenge/bar_1.png")
						table.insert(rightLines,cornerR)
						cornerR:scaleY(-1)
							:anchorPoint(22/32, 22/32)
							:xy(data1.pos.x, vv.pos.y)
							:addTo(self.scrollview)

						local vertical = ccui.Scale9Sprite:create()
						table.insert(rightLines,vertical)
						vertical:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						vertical:height(data1.pos.y - vv.pos.y - cornerWidth - parentIconWidth + 10)
							:anchorPoint(0.5, 0)
							:xy(cornerR:x(), cornerR:y() + cornerWidth)
							:addTo(self.scrollview)

						local horizontal = ccui.Scale9Sprite:create()
						table.insert(rightLines,horizontal)
						horizontal:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						horizontal:height(math.abs(vv.pos.x - data1.pos.x) - vv.icon:getBoundingBox().width/2 - cornerWidth)
							:setRotation(270)
							:anchorPoint(0.5, 0)
							:xy(cornerR:x() - cornerWidth, cornerR:y())
							:addTo(self.scrollview)
					else
						local horizontalR = ccui.Scale9Sprite:create()
						table.insert(rightLines, horizontalR)
						horizontalR:initWithFile(cc.rect(15, 10, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						horizontalR:height(rightData.pos.x - vv.pos.x -  vv.icon:getBoundingBox().width/2)
							:setRotation(270)
							:anchorPoint(0.5, 0)
							:xy(rightData.pos.x, posY)
							:addTo(self.scrollview)

						local verticalL = ccui.Scale9Sprite:create()
						table.insert(rightLines,verticalL)
						verticalL:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						local iconLHight = rightData.icon:getBoundingBox().height/2
						verticalL:height(rightData.pos.y - posY - iconLHight + 10)
							:anchorPoint(0.5, 0)
							:xy(rightData.pos.x, posY - 10)
							:addTo(self.scrollview)
					end
					lines[rightData.id] = rightLines
				end
			elseif i > 1 and i ~= #data then
				local posY = (data[i - 1][1].pos.y + vv.pos.y)/2
				if leftData then
					local leftLines = {}
					local cornerL = ccui.ImageView:create("city/adventure/gym_challenge/bar_1.png")
					table.insert(leftLines,cornerL)
					local cornerLX = preNum == 1 and vv.pos.x or vv.pos.x - (iconWidth/2 - 5)
					cornerL:scaleX(1)
						:anchorPoint(22/32, 22/32)
						:xy(cornerLX, posY)
						:addTo(self.scrollview)
					if #leftData.nextTalentIDs == 2 then
						local horizontalL = ccui.Scale9Sprite:create()
						table.insert(leftLines,horizontalL)
						horizontalL:initWithFile(cc.rect(15, 10, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						horizontalL:height(cornerL:x() - leftData.pos.x - 22)
							:setRotation(270)
							:anchorPoint(0.5, 0)
							:xy(cornerL:x() - 22 , posY)
							:addTo(self.scrollview)

						local verticalL = ccui.Scale9Sprite:create()
						table.insert(leftLines,verticalL)
						verticalL:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						local iconLHight = leftData.icon:getBoundingBox().height/2
						verticalL:height(leftData.pos.y - posY - iconLHight + 10)
							:anchorPoint(0.5, 0)
							:xy(leftData.pos.x, posY - 10)
							:addTo(self.scrollview)
					else
						local cornerL2 = ccui.ImageView:create("city/adventure/gym_challenge/bar_1.png")
						table.insert(leftLines,cornerL2)
						cornerL2:scale(-1)
							:anchorPoint(22/32, 22/32)
							:xy(leftData.pos.x, posY)
							:addTo(self.scrollview)

						local horizontalL = ccui.Scale9Sprite:create()
						table.insert(leftLines,horizontalL)
						horizontalL:initWithFile(cc.rect(15, 10, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						horizontalL:height(cornerL:x() - leftData.pos.x - cornerWidth * 2)
							:setRotation(90)
							:anchorPoint(0.5, 0)
							:xy(cornerL2:x() + cornerWidth, posY)
							:addTo(self.scrollview)

						local verticalL = ccui.Scale9Sprite:create()
						table.insert(leftLines,verticalL)
						verticalL:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						local iconLHight = leftData.icon:getBoundingBox().height/2
						verticalL:height(leftData.pos.y - posY - iconLHight - cornerWidth + 10)
							:anchorPoint(0.5, 0)
							:xy(leftData.pos.x, posY + cornerWidth)
							:addTo(self.scrollview)
					end
					if preNum == 2 then
						local verticalL2 = ccui.Scale9Sprite:create()
						table.insert(leftLines,verticalL2)
						verticalL2:initWithFile(cc.rect(15, 10, 1, 1), "city/adventure/gym_challenge/bar_5.png")
						verticalL2:height(posY - 22 - vv.pos.y - vv.icon:getBoundingBox().height/2 + 15)
							:scaleX(-1)
							:anchorPoint(0.5, 1)
							:xy(cornerL:x(), posY - 22)
							:addTo(self.scrollview)
					else
						local verticalL2 = ccui.Scale9Sprite:create()
						table.insert(leftLines,verticalL2)
						verticalL2:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						verticalL2:height(posY - 22 - vv.pos.y - vv.icon:getBoundingBox().height/2)
							:scaleX(-1)
							:anchorPoint(0.5, 1)
							:xy(cornerL:x(), posY - 22)
							:addTo(self.scrollview)
					end
					lines[leftData.id] = leftLines
				end

				if rightData then
					local rightLines = {}
					local cornerR = ccui.ImageView:create("city/adventure/gym_challenge/bar_1.png")
					table.insert(rightLines,cornerR)
					local cornerRX = preNum == 1 and vv.pos.x or vv.pos.x + (iconWidth/2 - 5)
					cornerR:scaleX(-1)
						:anchorPoint(22/32, 22/32)
						:xy(cornerRX, posY)
						:addTo(self.scrollview)
					if #rightData.nextTalentIDs == 2 then
						local horizontalR = ccui.Scale9Sprite:create()
						table.insert(rightLines,horizontalR)
						horizontalR:initWithFile(cc.rect(15, 10, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						horizontalR:height(rightData.pos.x - cornerR:x() - 22)
							:setRotation(90)
							:anchorPoint(0.5, 0)
							:xy(cornerR:x() + 22 , posY)
							:addTo(self.scrollview)

						local verticalR = ccui.Scale9Sprite:create()
						table.insert(rightLines,verticalR)
						verticalR:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						local iconLHight = rightData.icon:getBoundingBox().height/2
						verticalR:height(rightData.pos.y - posY - iconLHight + 10)
							:anchorPoint(0.5, 0)
							:xy(rightData.pos.x, posY - 10)
							:addTo(self.scrollview)
					else
						local cornerR2 = ccui.ImageView:create("city/adventure/gym_challenge/bar_1.png")
						table.insert(rightLines,cornerR2)
						cornerR2:scaleY(-1)
							:anchorPoint(22/32, 22/32)
							:xy(rightData.pos.x, posY)
							:addTo(self.scrollview)

						local horizontalR = ccui.Scale9Sprite:create()
						table.insert(rightLines,horizontalR)
						horizontalR:initWithFile(cc.rect(15, 10, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						horizontalR:height(rightData.pos.x  - cornerR:x() - cornerWidth * 2)
							:setRotation(270)
							:anchorPoint(0.5, 0)
							:xy(cornerR2:x() - cornerWidth, posY)
							:addTo(self.scrollview)

						local verticalR = ccui.Scale9Sprite:create()
						table.insert(rightLines,verticalR)
						verticalR:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						local iconLHight = rightData.icon:getBoundingBox().height/2
						verticalR:height(rightData.pos.y - posY - iconLHight - cornerWidth + 10)
							:anchorPoint(0.5, 0)
							:xy(rightData.pos.x, posY + cornerWidth)
							:addTo(self.scrollview)
					end

					if preNum == 2 then
						local verticalR2 = ccui.Scale9Sprite:create()
						table.insert(rightLines,verticalR2)
						verticalR2:initWithFile(cc.rect(15, 10, 1, 1), "city/adventure/gym_challenge/bar_5.png")
						verticalR2:height(posY - 22 - vv.pos.y - vv.icon:getBoundingBox().height/2 + 15)
							:scaleX(1)
							:anchorPoint(0.5, 1)
							:xy(cornerR:x(), posY - 22)
							:addTo(self.scrollview)
					else
						local verticalR2 = ccui.Scale9Sprite:create()
						table.insert(rightLines,verticalR2)
						verticalR2:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
						verticalR2:height(posY - 22 - vv.pos.y - vv.icon:getBoundingBox().height/2)
							:scaleX(1)
							:anchorPoint(0.5, 1)
							:xy(cornerR:x(), posY - 22)
							:addTo(self.scrollview)
					end
					lines[rightData.id] = rightLines
				end
			end
		end
	end
end

function GymBuffTree:refreshShowData(index)
	self.bufIcons = {}
	self.scrollview:removeAllChildren()
	local data, maxW= self:getDepthData(index)
	self:drawBufIcon(data,maxW)
	self:drawLine(data)
end

function GymBuffTree:onTabClick(list, index)
	self.showTab:set(index)
end

function GymBuffTree:onResetClick( )
	local resetTime = self.gymDatas:read().gym_talent_reset_times or 0
	local times = math.min(resetTime + 1, csvSize(gCostCsv.gym_talent_reset_cost))
	local cost = gCostCsv.gym_talent_reset_cost[times]
	local gymDatas = self.gymDatas:read()
	if csvSize(gymDatas.gym_talent_trees) == 0  then
		gGameUI:showTip(gLanguageCsv.gymBuffCannotReset)
		return
	end
	local str = string.format(gLanguageCsv.gymBuffReset, cost)
	gGameUI:showDialog({strs = {str}, isRich = true, cb = function ()
		if gGameModel.role:read("rmb") >= cost then
			gGameApp:requestServer("/game/gym/talent/reset",function (tb)

			end)
		else
			uiEasy.showDialog("rmb")
		end
	end,
	btnType = 2,dialogParams = {clickClose = false}, clearFast = true})
end

function GymBuffTree:onAddClick( )
	local costCft = gCostCsv.gym_talent_point_buy_cost
	local times = math.min(self.buyTimes:read() + 1, csvSize(gCostCsv.gym_talent_point_buy_cost))
	local cost = costCft[times]
	if gGameModel.daily_record:read("gym_talent_point_buy_times") >= gVipCsv[gGameModel.role:read("vip_level")].gymTalentPointBuyTimes then
		gGameUI:showTip(gLanguageCsv.cardCapacityBuyMax)
		return
	end
	local str = string.format(gLanguageCsv.gymBuffBuy, cost, gCommonConfigCsv.gymTalentPointBuyCount)
	gGameUI:showDialog({strs = {str}, isRich = true, cb = function ()
		if gGameModel.role:read("rmb") >= cost then
			gGameApp:requestServer("/game/gym/talent/point/buy",function (tb)
				gGameUI:showTip(gLanguageCsv.buySuccess)
			end)
		else
			uiEasy.showDialog("rmb")
		end
	end,
	btnType = 2 ,dialogParams = {clickClose = false}, clearFast = true})
end

return GymBuffTree
