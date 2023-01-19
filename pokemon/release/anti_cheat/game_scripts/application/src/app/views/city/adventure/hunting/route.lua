-- @date:   2021-04-24
-- @desc:   狩猎地带路线

local ROUTE_TYPE = {
    normal = 1,
    elite = 2,
}

local BG_TYPE = {
	[1] =  "city/adventure/hunting/img_sldd_1.png",
	[2] =  "city/adventure/hunting/img_sldd_2.png",
}

local UNDERGROUND_TYPE = {
	[1] =  "city/adventure/hunting/img_sldd0%d.png",
	[2] =  "city/adventure/hunting/img_sldd0%d_02.png",
}

local PRO_TYPE = {
	[1] =  "city/adventure/hunting/mask_sldd%d_01.png",
	[2] =  "city/adventure/hunting/mask_sldd%d_02.png",
}
local EVENT_TYPE = {
	gate = 1,
	box = 2,
	HP = 3,
	mul = 4,
}

local ACTION_TYPE = {
	[1] = "standby_loop",
	[2] = "run_loop",
	[3] = "win_loop",
}

local SPINE_CARDS = {
	charizard = {res = "koudai_penhuolong/hero_penhuolong.skel", x = 150, y = 0, scale = 2.8},
	bulbasaur = {res = "koudai_miaowazhongzi/hero_miaowazhongzi.skel", x = 430, y = -20, scale = 2.4},
	squirtle = {res = "koudai_jienigui/hero_jienigui.skel", x = 660, y = 0, scale = 2.4},
	pikachu = {res = "koudai_xiaozhibanpikaqiu/hero_xiaozhibanpikaqiu.skel", x = 890, y = 0, scale = 2},
}

local ICON_TYPE = {
	[1] = "city/adventure/hunting/icon_zd1.png",
	[2] = "city/adventure/hunting/icon_box.png",
	[3] = "city/adventure/hunting/icon_jiuyuan.png",
	[4] = "city/adventure/hunting/icon_zd2.png",
}

local GATE_TYPE = {
	[1] = "city/adventure/hunting/icon_zd1.png",
	[2] = "city/adventure/hunting/icon_zd2.png",
	[3] = "city/adventure/hunting/icon_boss.png",
}

local GATE_SPINE_TYPE = {
	[1] = {res = "city/adventure/hunting/icon_zd1_red.png", scale = 1},
	[2] = {res = "city/adventure/hunting/icon_zd2_red.png", scale = 1},
	[3] = {res = "city/adventure/endless_tower/icon_boss.png", scale = 1.5}
}
local actionTime = 3

local EVENT_SPINE = {
	[1] = {res = "koudai_xiaozhibanpikaqiu/hero_xiaozhibanpikaqiu.skel", spineName = "gate", action = "standby_loop", x = 3000, y = 2300, scale = 3},
	[2] = {res = "effect/jiedianjiangli.skel", spineName = "box", action = "effect_loop", x = 2700, y = 1850, scale = 1.3},
	[3] = {res = "koudai_jilidan/hero_jilidan.skel", spineName = "supply", action = "standby_loop", x = 2800, y = 1950, scale = 3},
	[4] = {res = "koudai_kedaya/hero_kedaya.skel", spineName = "mul", action = "standby_loop", x = 2760, y = 1940, scale = 3},
}


local ViewBase = cc.load("mvc").ViewBase
local HuntingRouteView = class("HuntingRouteView", ViewBase)

HuntingRouteView.RESOURCE_FILENAME = "hunting_route.json"
HuntingRouteView.RESOURCE_BINDING = {
    ["bg"] = "bg",
    ["runSpine"] = "runSpine",
    ["spinePanel"] = "spinePanel",
	["coverProPanel.prograssPanel"] = "prograssPanel",
	["coverProPanel.bgLeft"] = "bgLeft",
	["coverProPanel.bgRight"] = "bgRight",
	["coverProPanel.prograssPanel.proPanel1"] = "proPanel1",
	["buffPanel"] = "buffPanel",
	["buffPanel.buffBtn"] = {
		varname = "buffBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBuffBtnClick")},
		},
	},
	["buffPanel.buffBtn.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(255, 252, 237, 255),  size = 4}}
		}
	},
	["buffPanel.item"] = "buffItem",
	["buffPanel.coverPanel"] = "buffCoverPanel",
	["buffPanel.coverPanel.actionNode"] = "buffActionNode",
	["buffPanel.coverPanel.list"] = {
        varname = "buffList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("buffDatas"),
                item = bindHelper.self("buffItem"),
				itemAction = {isAction = true},
                onItem = function(list, node, k, v)
					node:get("icon"):texture(v.icon)
					if k == 1 then
						node:width(270)
						node:get("icon"):x(195)
						node:get("bg"):x(195)
					end
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, list, node, v)}})
				end,
            },
            handlers = {
                itemClick = bindHelper.self("onItemClick"),
            },
        },
    },
	["rightBottomPanel"] = "rightBottomPanel",
    ["rightBottomPanel.btnTask"] = {
        varname = "event",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEndClick")},
		},
	},
	["circlePanel"] = "circlePanel",
}

function HuntingRouteView:onCreate(route)
	self.route = route
	gGameUI.topuiManager:createView("hunting", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.huntingArea, subTitle = "HUNTINGAREA"})
	self:initUnderground(route)
	self:initRoundData()
	self:initProgress()
	self:initSpine()
    self:initModel()
	self:initBuffDatas()
    self:initPanel()
end

function HuntingRouteView:initRoundData()
	local routeInfo = gGameModel.hunting:read("hunting_route")
	local version = routeInfo[self.route].version or 0
	-- 关卡信息
	self.routeData = {}
	local count = 1
	for k, v in orderCsvPairs(csv.cross.hunting.route) do
		if v.routeTag == self.route and version == v.version then
			self.routeData[k] = {
				count = count,
				type = v.type,
				boxDropLibs = v.boxDropLibs,
				supplyGroup = v.supplyGroup,
				gateIDs = v.gateIDs,
			}
			if count == 1 then
				self.minId = k
			end
			count = count + 1
		end
	end
end
-- 初始化背景和地的资源
function HuntingRouteView:initUnderground(route)
	self.bg:texture(BG_TYPE[route])
	for i = 1, 6 do
		for j = 1, 5 do
			self.circlePanel:get("bottomPanel" .. i):get("bg" .. j):texture(string.format(UNDERGROUND_TYPE[route], j))
		end
	end
	-- 进度条资源
	self.bgLeft:texture(string.format(PRO_TYPE[1],route))
	self.bgRight:texture(string.format(PRO_TYPE[2],route))
end

function HuntingRouteView:initModel()
	self.buffDatas = idlers.newWithMap({})
	self.delayTime = 0 -- 可达鸭动画
	self.lastFlag = 0 -- 最后一次动画
	self.clientRouteInfoFlag = idler.new(true)
	idlereasy.any({self.clientRouteInfoFlag}, function()
		local routeInfo = gGameModel.hunting:read("hunting_route")
		if routeInfo[self.route].node == 0 then
			self:onClose()
			return
		elseif routeInfo[self.route].node == self.minId + itertools.size(self.routeData) then -- 通关
			self.curNode = self.minId + itertools.size(self.routeData) --当前阶段
			self:initSpine(3)
			self:initPanel()
			self:checkCurIndex()
			self:initBuffDatas()
			return
		end
		self:initBuffDatas()
		local boardID = routeInfo[self.route].board_id or 0
		if self.curNode == routeInfo[self.route].node and self.routeData[self.curNode].type == EVENT_TYPE.mul and (routeInfo[self.route].board_id and boardID ~= self.boardId) then
			--可达鸭逃跑 怪物跑出来
			self.boardId = boardID
			self:initEventSpine(3)
			-- 在当前界面打过了一关 或者 选择了事件 或者 刚进来
			elseif self.curNode ~= routeInfo[self.route].node or (routeInfo[self.route].board_id and boardID ~= self.boardId) then
			self.curNode = routeInfo[self.route].node --当前阶段
			self.boardId = boardID
			self:initPanel()
			self:initEventSpine(1)
			self:checkCurIndex()
			performWithDelay(self, function ()
				self:updatePerformance()
			end, self.delayTime)
		elseif self.curNode == routeInfo[self.route].node and (self.routeData[self.curNode].type == EVENT_TYPE.gate or boardID > 2 ) and self.lastFlag ~= 1 then
				self:initEventSpine(2)
				self:checkCurIndex(2)
		end
		--	buff 选择界面
		local len = itertools.size(routeInfo[self.route].board_buffs or {})
		if  len > 0 then
			self:checkCurIndex()
			performWithDelay(self, function ()
				self.isOpen = false
				self:onBuffBtnClick()
				gGameUI:stackUI("city.adventure.hunting.select_buff", nil, {blackLayer = true}, {route = self.route, node = self.curNode, cb = self:createHandler("playBuffSpine")})
			end, 1/60)
		end
	end)
end

function HuntingRouteView:playBuffSpine()
	self.buffBtn:removeChildByName("effect")
	local effect = widget.addAnimationByKey(self.buffBtn, "random_tower/new_jiacheng.skel", "effect", "effect", 10)
		:xy(70, 70)
		:scale(2)
	self.clientRouteInfoFlag:notify()
end

-- buff数据初始化
function HuntingRouteView:initBuffDatas()
	local buffDatas = {}
	local routeInfo = gGameModel.hunting:read("hunting_route")
	if itertools.size(routeInfo[self.route].buffs) > 0 then
		for _, id in ipairs(routeInfo[self.route].buffs) do
			local buffCfg = csv.cross.hunting.buffs[id]
			table.insert(buffDatas, {
                name = buffCfg.name,
                desc = buffCfg.desc,
                quality = buffCfg.quality,
				icon = buffCfg.icon,
            })
		end
	end
	self.buffDatas:update(buffDatas)
	local maxWidth = 1500
	local len = itertools.size(buffDatas)
	local bgWidth = len > 6 and maxWidth or (len * 200 + 170)
	local bg = self.buffCoverPanel:get("actionNode.bg")
	bg:width(bgWidth)
	self.buffCoverPanel:get("actionNode"):x( - bgWidth)
	self.buffList:width(bgWidth - 95)
	self.buffList:xy(0, - self.buffList:height()/2)
	self.buffList:retain()
	self.buffList:removeFromParent()
	local size = bg:size()
	local clip = cc.ClippingNode:create()
		:setStencil(bg)
		:setInverted(false)
		:setAlphaThreshold(0.2)
		:xy(cc.p(0, 0))
		:add(self.buffList, 100)
		:addTo(self.buffActionNode, 3, "clipper")
	self.buffList:release()
end

function HuntingRouteView:initSpine(type) -- 1 待机 2 run 3 win
	local effect = widget.addAnimationByKey(self.runSpine, "loading/loading_pikaqiu.skel", "effect", "effect_loop", 10)
		:xy(0, 10)
		:scale(1.3)
	self.spinePanel:removeAllChildren()
	if type then
		for id, v in pairs(SPINE_CARDS) do
			local cardSprite1 = widget.addAnimationByKey(self.spinePanel, v.res, id, ACTION_TYPE[type], 1000)
				:scale(v.scale)
				:xy(v.x, v.y)
		end
	end
end

-- 创建进度条数据
function HuntingRouteView:initProgress()
	self.bar = {}
	self.prograssData = {}
	local index = 0
	self.bar[self.minId] = self.prograssPanel:get("proPanel1")
	for id, val in pairs(self.routeData) do
		if val.count == itertools.size(self.routeData) then
			local bar = self.prograssPanel:get("proPanel3"):clone():show()
				:addTo(self.prograssPanel, 5, "bar" .. id)
				:xy(self.prograssPanel:get("proPanel2"):x() + 252 * ( val.count - 2 ) + 170, self.prograssPanel:get("proPanel2"):y())
				if self.routeData[id].type == EVENT_TYPE.mul then
					bar:get("txt"):visible(true)
					bar:get("icon"):visible(false)
				else
					if self.routeData[id].type == EVENT_TYPE.gate then
						local gateId = self.routeData[id].gateIDs[1]
						bar:get("icon"):texture(GATE_TYPE[csv.cross.hunting.gate[gateId].type])
					else
						bar:get("icon"):texture(ICON_TYPE[self.routeData[id].type])
					end
					bar:get("txt"):visible(false)
					bar:get("icon"):visible(true)
				end
				self.bar[id + 1] = bar
		else
			local bar = self.prograssPanel:get("proPanel2"):clone():show()
				:addTo(self.prograssPanel, 5, "bar" .. id)
				:xy(self.prograssPanel:get("proPanel2"):x() + 253 * ( val.count - 1 ) - 2, self.prograssPanel:get("proPanel2"):y())
				bar:get("icon"):visible(self.routeData[id].type ~= EVENT_TYPE.mul )
				if self.routeData[id].type == EVENT_TYPE.gate then
					local gateId = self.routeData[id].gateIDs[1]
					bar:get("icon"):texture(GATE_TYPE[csv.cross.hunting.gate[gateId].type])
				else
					bar:get("icon"):texture(ICON_TYPE[self.routeData[id].type])
				end
				bar:get("txt"):visible(self.routeData[id].type == EVENT_TYPE.mul )
				self.bar[id + 1] = bar
		end
	end
	local spineSumX = self.runSpine:x()
	local panelSumX = self.prograssPanel:x()
	for id = self.minId, self.minId + itertools.size(self.routeData) - 1 do
		-- 如果选择关卡要多加一条数据
		if index == 0 then
			index = index + 1
			self.prograssData[index] = {prograssIndex = self.minId, round = id, percent = 0, panelX = panelSumX, spineX = spineSumX}
		end
		if self.routeData[id].count == itertools.size(self.routeData) then -- 最后一关特殊处理
			index = index + 1
			self.prograssData[index] = {prograssIndex= id + 1, round = id, percent = 100, panelX = panelSumX, spineX = spineSumX + 250}
		else
			local spineX = self.routeData[id].count > 3 and self.routeData[id].count < itertools.size(self.routeData) - 2 and 0 or 250
			local panelX = self.routeData[id].count > 3 and self.routeData[id].count < itertools.size(self.routeData) - 2 and 250 or 0
			spineSumX = spineSumX + spineX
			panelSumX = panelSumX - panelX
			index = index + 1
			self.prograssData[index] = {prograssIndex= id, round = id, percent = 100, panelX = panelSumX, spineX = spineSumX}
			index = index + 1
			self.prograssData[index] = {prograssIndex= id + 1, round = id, percent = 32, panelX = panelSumX, spineX = spineSumX}
		end
	end
	self.prograssPanel:get("proPanel2"):hide()
end

--更新进度条初始进度
function HuntingRouteView:refreshProgress(curProIndex)
	self.runSpine:x(self.prograssData[curProIndex].spineX)
	self.prograssPanel:x(self.prograssData[curProIndex].panelX)
	if curProIndex == 1 then	-- 第一关
		self.bar[self.minId]:get("pro"):setPercent(0)
	elseif curProIndex >= 2 then
		for index = self.minId, self.prograssData[curProIndex].prograssIndex - 1 do
			self.bar[index]:get("pro"):setPercent(100)
		end
		self.bar[self.prograssData[curProIndex].prograssIndex]:get("pro"):setPercent(self.prograssData[curProIndex].percent)
	end
end

-- 设置接下来出现的事件spine
function HuntingRouteView:initEventSpine(flag)
	if flag == 2 then
		if self.lastFlag == 1 or self.lastFlag == 3 then
			return
		else
			self:initSpine(1)
		end
	end
	self.lastFlag = flag
	self.eventID = self.routeData[self.curNode].type
	if self.eventID == EVENT_TYPE.mul and self.boardId > 0 then -- 已经选择了
		if self.boardId == 1 then
			self.eventID = EVENT_TYPE.box
		elseif self.boardId == 2 then
			self.eventID = EVENT_TYPE.HP
		else
			self.eventID = EVENT_TYPE.gate
		end
	end

	local function eventCb()
		self.circlePanel:removeChildByName("eventPanel")
		if flag == 1 or flag == 3 then
			self.circlePanel:removeChildByName("gatePanel")
		end
		if flag ~= 3 then
			self.circlePanel:setRotation(0)
		end
		local x = flag == 2 and 1300 or EVENT_SPINE[self.eventID].x
		local y = flag == 2 and 3600 or EVENT_SPINE[self.eventID].y
		x = flag == 3 and 3700 or x
		y = flag == 3 and 800 or y
		local rotation = flag == 2 and 0 or 36
		rotation = flag == 3 and 72 or rotation
		-- 挑战关卡
		if self.eventID == EVENT_TYPE.gate then
			local enemyID = self.boardId > 0 and self.boardId or self.routeData[self.curNode].gateIDs[1]
			performWithDelay(self, function ()
				gGameApp:requestServer("/game/hunting/battle/info", function(tb)
					self.gateDatas = tb.view or {}
					local data = tb.view.defence_role_info or {}
					local fightingpointMax = 0
					local unitId
					for _, v in pairs(data.defence_card_attrs) do
						local unitID = csv.cards[v.card_id].unitID
						local res = csv.unit[unitID].unitRes
						unitId = fightingpointMax < v.fighting_point and unitID or unitId
						fightingpointMax = fightingpointMax < v.fighting_point and v.fighting_point or fightingpointMax
					end
					local x = flag == 2 and 1300 or EVENT_SPINE[self.eventID].x
					local y = flag == 2 and 3600 or EVENT_SPINE[self.eventID].y
					x = flag == 3 and 3700 or x
					y = flag == 3 and 800 or y
 					local rotation = flag == 2 and 0 or 36
					rotation = flag == 3 and 72 or rotation
					 -- 创建一个层容器用来点击
					local panel = self.circlePanel:get("gatePanel")
					if flag == 2 and panel then
					else
						local gatePanel= ccui.Layout:create()
							:size(600, 800)
							:addTo(self.circlePanel, 10, "gatePanel")
							:anchorPoint(0.5, 0.5)
							:xy(x, y)
						gatePanel:setTouchEnabled(true)
						gatePanel:setRotation(rotation)
						--精灵
						local nodeSpine = widget.addAnimationByKey(self.circlePanel:get("gatePanel"), csv.unit[unitId].unitRes, EVENT_SPINE[self.eventID].spineName, EVENT_SPINE[self.eventID].action, 10)
							:xy(300, 20)
							:anchorPoint(0.5, 0)
							:scale(EVENT_SPINE[self.eventID].scale)
							:scaleX(EVENT_SPINE[self.eventID].scale * - 1)
						nodeSpine:setSkin(csv.unit[unitId].skin)
						-- 头上图片
						local iconBg = cc.Sprite:create("city/adventure/hunting/logo_sldd.png")
							:anchorPoint(0.5, 0.5)
							:addTo(nodeSpine, 10, "iconBg")
							:xy(0, 40 + csv.unit[unitId].everyPos.headPos.y / 2)
							:scale(1 / EVENT_SPINE[self.eventID].scale)
						local respurse = GATE_SPINE_TYPE[csv.cross.hunting.gate[self.routeData[self.curNode].gateIDs[1]].type]
						local iconPic = cc.Sprite:create(respurse.res)
							:anchorPoint(0.5, 0.5)
							:addTo(nodeSpine:get("iconBg"), 10, "icon")
							:xy(80, 100)
							:scale(respurse.scale)
						if flag == 3 then
							local panel = self.circlePanel:get("gatePanel")
							local sequence = cc.Sequence:create(
								cc.MoveTo:create(actionTime - 1, cc.p(panel:x() - 700, panel:y() + 1530))
							)
							panel:get("gate"):play("run_loop")
							panel:runAction(sequence)
							local action1 = cc.EaseInOut:create(cc.RotateTo:create(actionTime - 1, 36), self.delayTime)
							panel:runAction(action1)
							performWithDelay(self, function ()
								panel:get("gate"):play("standby_loop")
							end,actionTime - 1)
						end
						bind.click(self, gatePanel, {method = function()
							self:onNodeClick()
						end})
					end
				end, self.route, self.curNode, enemyID)
			end, 1/60)
		-- 宝箱关卡
		else
			x = flag == 3 and 3500 or x
			y = flag == 3 and 500 or y
			-- 创建一个层容器用来点击
			local gatePanel= ccui.Layout:create()
				:size(400, 500)
				:addTo(self.circlePanel, 10, "eventPanel")
				:anchorPoint(0.5, 0)
				:xy(x, y)
			gatePanel:setRotation(rotation)
			gatePanel:setTouchEnabled(false)
			bind.click(self, gatePanel, {method = function()
				self:onNodeClick()
			end})
			performWithDelay(self, function ()
				gatePanel:setTouchEnabled(true)
			end, actionTime)
			local nodeSpine = widget.addAnimationByKey(self.circlePanel:get("eventPanel"), EVENT_SPINE[self.eventID].res, EVENT_SPINE[self.eventID].spineName, EVENT_SPINE[self.eventID].action, 10)
				:xy(200, 100)
				:anchorPoint(0.5, 0)
				:scale(EVENT_SPINE[self.eventID].scale)
				:scaleX(EVENT_SPINE[self.eventID].scale * - 1)
			if self.eventID == EVENT_TYPE.box then
				local iconBg = cc.Sprite:create("common/icon/icon_box_sldd.png")
					:anchorPoint(0.5, 0)
					:addTo(nodeSpine, 10, "iconBg")
					:xy(0, 0)
					:scale(1.6)
					:scaleX(-1.6)
				self.isBoxToOpen = true
				performWithDelay(self, function()
					if self.dialog == nil then
						self:onNodeClick()
						self.isBoxToOpen = false
					end
				end, actionTime)
			else
				local iconBg = cc.Sprite:create("city/adventure/hunting/logo_sldd.png")
					:anchorPoint(0.5, 0.5)
					:addTo(nodeSpine, 10, "iconBg")
					:xy(0, 120)
					:scale(1 / EVENT_SPINE[self.eventID].scale)
			end
			if self.eventID == EVENT_TYPE.mul then
				local label = cc.Label:createWithTTF("!", "font/youmi1.ttf", 100)
					:align(cc.p(1, 0), 40, 30)
					:addTo(nodeSpine:get("iconBg"), 10, "icon")
					:xy(100, 50)
					text.addEffect(label, {color = cc.c4b(241, 59, 84, 255)})
			elseif self.eventID == EVENT_TYPE.HP then
				local iconPic = cc.Sprite:create("city/adventure/hunting/img_box_jy.png")
					:anchorPoint(0.5, 0.5)
					:addTo(nodeSpine:get("iconBg"), 10, "icon")
					:xy(80, 110)
				if flag == 3 then

					local panel = self.circlePanel:get("eventPanel")
					local sequence = cc.Sequence:create(
						cc.MoveTo:create(actionTime - 1, cc.p(panel:x() - 750, panel:y() + 1400))
					)
					panel:get("supply"):play("run_loop")
					panel:runAction(sequence)
					local action1 = cc.EaseInOut:create(cc.RotateTo:create(actionTime - 1, 36), self.delayTime)
					panel:runAction(action1)
					performWithDelay(self, function ()
						panel:get("supply"):play("standby_loop")
					end, actionTime - 1)
				end
			end

		end
	end

	--可达鸭逃跑
	local panel = self.circlePanel:get("eventPanel") and self.circlePanel:get("eventPanel"):get("mul")
	if self.routeData[self.curNode].type == EVENT_TYPE.mul and panel then
		self.delayTime = 1.5
		self.circlePanel:get("eventPanel"):setTouchEnabled(false)
		panel:play("run_loop")
		panel:scaleX(EVENT_SPINE[self.eventID].scale)
		local sequence = cc.Sequence:create(
			cc.MoveTo:create(self.delayTime, cc.p(panel:x() + 800, panel:y() - 1000)),
			cc.CallFunc:create(eventCb)
		)
		panel:runAction(sequence)
		local action1 = cc.EaseInOut:create(cc.RotateTo:create(actionTime, 36), self.delayTime)
		panel:runAction(action1)
	else
		self.delayTime = 0
		eventCb()
	end

end
-- 初始化线路信息
function HuntingRouteView:initPanel()
	if self.curNode > self.minId + itertools.size(self.routeData) - 1 then
		self.rightBottomPanel:get("clearance"):visible(true)
		self.rightBottomPanel:get("proBg"):visible(false)
		self.rightBottomPanel:get("proText"):visible(false)
		self.rightBottomPanel:removeChildByName("richText")
	else
		local normalContent = string.format(gLanguageCsv.huntingRouteDetail, self.routeData[self.curNode].count, itertools.size(self.routeData))
		self.rightBottomPanel:get("proText"):hide()
		self.rightBottomPanel:removeChildByName("richText")
		local richText = rich.createByStr(normalContent, 36, nil)
			:xy(self.rightBottomPanel:get("proText"):x(), self.rightBottomPanel:get("proText"):y())
			:anchorPoint(0.5, 0.5)
			:addTo(self.rightBottomPanel, 100, "richText")
			-- :formatText()
		self.rightBottomPanel:get("clearance"):visible(false)
		self.rightBottomPanel:get("proBg"):visible(true)
	end

end

-- 确认当前位置
function HuntingRouteView:checkCurIndex(type)
	local curProIndex = 1
	for k, v in ipairs(self.prograssData) do
		if self.curNode == self.minId + itertools.size(self.routeData) then -- 最后一关
			curProIndex = itertools.size(self.prograssData)
			break
		else
			if v.prograssIndex == self.curNode and v.round == self.curNode - 1 then
				curProIndex = k
				break
			end
		end
	end
	curProIndex = type == 2 and curProIndex + 1 or curProIndex
	self:refreshProgress(curProIndex)
	self.curProIndex = curProIndex
end
--	动画表现
function HuntingRouteView:updatePerformance()
	local percentStart = self.prograssData[self.curProIndex].percent
	local percentEnd = self.prograssData[self.curProIndex + 1].percent
	local del = percentEnd - percentStart

	local prograss = self.bar[self.prograssData[self.curProIndex].prograssIndex]:get("pro")
	self.prograssPanel:scheduleUpdate(function(detal)
		local curpercent = prograss:getPercent()
		if curpercent >= percentEnd then
			self.prograssPanel:unscheduleUpdate()
		else
			prograss:setPercent(curpercent + detal * del /actionTime)
		end
	end)
	--	精灵运动
	local sequence = cc.Sequence:create(
		cc.MoveTo:create(actionTime, cc.p(self.prograssData[self.curProIndex + 1].spineX, self.runSpine:y()))
	)
	self.runSpine:runAction(sequence)
	--	进度条运动
	local sequence1 = cc.Sequence:create(
		cc.MoveTo:create(actionTime, cc.p(self.prograssData[self.curProIndex + 1].panelX, self.prograssPanel:y()))
	)
	self.prograssPanel:runAction(sequence1)

	--	待机精灵跑动
	self:initSpine(2)
	performWithDelay(self, function()
		self:initSpine(1)
		if self.circlePanel:get("eventPanel") then
			bind.click(self, self.circlePanel:get("eventPanel"), {method = function()
				self:onNodeClick()
			end})
		end
	end, actionTime)

	--	地旋转
	local action1 = cc.EaseInOut:create(cc.RotateTo:create(actionTime, -36), actionTime)
	self.circlePanel:runAction(action1)


end
-- 关卡点击
function HuntingRouteView:onNodeClick()
	local node = self.curNode
	if self.eventID == EVENT_TYPE.gate then
		if self.curNode < self.minId + itertools.size(self.routeData) then
			local enemyID = self.boardId > 0 and self.boardId or self.routeData[self.curNode].gateIDs[1]
			gGameUI:stackUI("city.adventure.hunting.gate_detail", nil, nil, self.gateDatas, enemyID, self.route, node, self:createHandler("onClientRouteRefresh"))
		end
	elseif self.eventID == EVENT_TYPE.box then
		gGameUI:stackUI("city.adventure.hunting.open_box", nil, {clickClose = true, blackLayer = true}, self.route, node, self:createHandler("onClientRouteRefresh"))
	elseif self.eventID == EVENT_TYPE.HP then
		local group = csv.cross.hunting.route[node].supplyGroup or 1
		gGameUI:stackUI("city.adventure.hunting.supply", nil, {blackLayer = true}, {route = self.route, node = node, group = group}, self:createHandler("onClientRouteRefresh"))
	elseif self.eventID == EVENT_TYPE.mul then
		gGameUI:stackUI("city.adventure.hunting.select_event", nil, {blackLayer = true}, node, self:createHandler("onClientRouteRefresh"))
	end
end

function HuntingRouteView:onClientRouteRefresh()
	self.clientRouteInfoFlag:notify()
end

--	结束路线
function HuntingRouteView:onEndClick()
	local callbacks = function()
		gGameApp:requestServer("/game/hunting/route/end", function(tb)
			self:onClose()
		end, self.route)
	end

	local cancelAndCloseCb = function()
		self.dialog = nil
		if self.isBoxToOpen then
			self:onNodeClick()
		end
		self.isBoxToOpen = false
	end

	local params = {
		cb = callbacks,
		isRich = false,
		closeCb = cancelAndCloseCb,
		cancelCb = cancelAndCloseCb,
		btnType = 2,
		content = gLanguageCsv.huntingExitGame,
		dialogParams = {clickClose = false},
	}
	self.dialog = gGameUI:stackUI("common.prompt_box", nil, nil, params)
end

-- buff按钮点击
function HuntingRouteView:onBuffBtnClick()
	local routeInfo = gGameModel.hunting:read("hunting_route")
	local buff = routeInfo[self.route].buffs or {}
	if itertools.size(buff) == 0 then
		gGameUI:showTip(gLanguageCsv.huntingNoBuff)
		return
	end

	local y = self.buffActionNode:y()
	local endPos
	if self.isOpen then
		endPos = cc.p(- self.buffCoverPanel:get("actionNode.bg"):width(), 100)
	else
		endPos = cc.p(0, 100)
	end
	local sequence = cc.Sequence:create(
		cc.MoveTo:create(0.5, endPos), cc.CallFunc:create(function()
			self.isOpen = not self.isOpen
		end)
	)
	self.buffActionNode:stopAllActions()
	self.buffActionNode:runAction(sequence)
end

--buff图标点击
function HuntingRouteView:onItemClick(self, list, node, v)
	if gGameUI.itemDetailView then
		gGameUI.itemDetailView:onClose()
	end
	local name = "city.adventure.hunting.buff_detail"
	local canvasDir = "horizontal"
	local childsName = {"baseNode"}

	local view = tip.create(name, nil, {relativeNode = node, canvasDir = canvasDir, childsName = childsName, dir = "top", offy = 150}, v)
	view:onNodeEvent("exit", functools.partial(gGameUI.unModal, gGameUI, view))
	gGameUI:doModal(view)
	gGameUI.itemDetailView = view
end



return HuntingRouteView