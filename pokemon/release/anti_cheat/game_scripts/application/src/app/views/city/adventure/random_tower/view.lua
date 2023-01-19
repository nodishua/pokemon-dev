-- @date:   2019-09-27
-- @desc:   试练-随机塔主界面

local FLOOR_STATE = {
	scale = {[0] = 1, 1, 0.9, 0.85, 0.85},
	opacity = {[0] = 0, 255, 255*0.7, 255*0.4, 0},
	y = {[0] = -570, -12, 142, 250, 200},
	z = {[0] = 6, 5, 4, 3, 2}
}
--[[
房间的元素主要包含：
1	怪物对战			根据配置，读取怪物列表，完成后根据战斗表现和关卡难度获得战斗奖励、积分
2	获取buff			点击可获得一些属性加成、补给回复、特殊加成等
3	获取宝箱			免费获得一个宝箱奖励，可以使用钻石继续（重复）开启，次数根据配置，开启花费逐次递增直到次数用尽
4	事件				根据情况随机，可能出现随机的事件
--]]
local BOARD_TYPE = {
	monster = 1,
	buff = 2,
	box = 3,
	event = 4,
}
local MONSTER_COLOR = {
	[1] = cc.c4b(94, 235, 169, 255),--简单
	[2] = cc.c4b(86, 229, 255, 255),--普通
	[3] = cc.c4b(254, 159, 255, 255),--困难
	[4] = cc.c4b(253, 189, 89, 255),--boss
}
--刷新item数据
local function refreshItem(item, boardID, roomInfo)
	local cfg = csv.random_tower.board[boardID]
	local childs = item:multiget("item", "icon", "iconBg", "name", "desc", "pos")
	childs.name:text(cfg.name)
	local desc = cfg.desc
	local icon = cfg.icon
	childs.iconBg:hide()
	if cfg.type == BOARD_TYPE.monster then
		local monsterCsv = csv.random_tower.monsters[cfg.monster]
		text.addEffect(childs.name, {color = MONSTER_COLOR[cfg.monsterType]})
		if monsterCsv and "" == icon then
			icon = monsterCsv.res
		end
		childs.icon:y(childs.iconBg:y() - 34)
	elseif cfg.type == BOARD_TYPE.buff and roomInfo.buff then
		local buffCsv = csv.random_tower.buffs[roomInfo.buff[boardID]]
		if buffCsv then
			desc = buffCsv.desc
			icon = buffCsv.icon
			childs.iconBg:show():texture(buffCsv.iconBg)
		end
	elseif cfg.type == BOARD_TYPE.box then
		childs.icon:scale(1)
	end
	childs.icon:texture(icon)
	beauty.textScroll({
		list = childs.desc,
		strs = desc,
		align = "center",
		fontSize = matchLanguage({"kr"}) and 36 or ui.FONT_SIZE
	})
	childs.desc:setItemAlignCenter()
end
local randomTowerTools = require "app.views.city.adventure.random_tower.tools"
--获取可碾压提示文本
local function getCanPassOrJumpStr()
	if not dataEasy.isUnlock(gUnlockCsv.randomTowerJump) then
		local max1 = randomTowerTools.getCanPassMaxRoom()
		if max1 <= 1 then
			return ""
		end
		local csvTower1 = csv.random_tower.tower[max1]
		return string.format(gLanguageCsv.randomTowerCanPassTip, csvTower1.floor, csvTower1.roomIdx)
	else
		local max2 = randomTowerTools.getCanJumpMaxRoom()
		local max1 = randomTowerTools.getCanPassMaxRoom()
		if max2 <= 1 and max1 <= 1 then
			return ""
		end
		if max1 > 1 and max2 <= 1 then
			local csvTower1 = csv.random_tower.tower[max1]
			return string.format(gLanguageCsv.randomTowerCanPassTip2, csvTower1.floor, csvTower1.roomIdx)
		elseif max1 <= 1 and max2 > 1 then
			local csvTower2 = csv.random_tower.tower[max2]
			return string.format(gLanguageCsv.randomTowerCanJumpTips3,csvTower2.floor, csvTower2.roomIdx)
		elseif max1 > 1 and max2 > 1 then
			local csvTower1 = csv.random_tower.tower[max1]
			local csvTower2 = csv.random_tower.tower[max2]
			return string.format(gLanguageCsv.randomTowerCanJumpTips1, csvTower1.floor, csvTower1.roomIdx,csvTower2.floor, csvTower2.roomIdx)
		end
	end
end



local ViewBase = cc.load("mvc").ViewBase
local RandomTowerView = class("RandomTowerView", ViewBase)

RandomTowerView.RESOURCE_FILENAME = "random_tower.json"
RandomTowerView.RESOURCE_BINDING = {
	["item"] = "item",
	["panel"] = "panel",
	["startPanel"] = "startPanel",
	["endPanel"] = "endPanel",
	["startPanel.item.name"] = "startName",
	["startPanel.jump.name"] = "jumpName",
	["startPanel.item"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onStartClick"),
		}
	},
	["startPanel.jump"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onJumpClick"),
		}
	},
	["leftBottomPanel.floorTitle"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		}
	},
	["leftBottomPanel.floor"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
			}, {
				event = "text",
				idler = bindHelper.self("room"),
				method = function(val)
					local roomIdx = csv.random_tower.tower[val].roomIdx
					if val == 1 then
						return ""
					end
					return string.format(gLanguageCsv.randomTowerSomeFloor, csv.random_tower.tower[val].floor)
				end
			}
		}
	},
	["leftBottomPanel.roomTitle"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		}
	},
	["leftBottomPanel.room"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
			}, {
				event = "text",
				idler = bindHelper.self("room"),
				method = function(val)
					local floor = csv.random_tower.tower[val].floor
					local roomIdx = csv.random_tower.tower[val].roomIdx
					if roomIdx == 0 then
						return ""
					end
					local str = roomIdx .. "/" .. gRandomTowerFloorMax[floor]
					return str
				end
			}
		}
	},
	["leftBottomPanel.pointPanel.point"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("dayPoint"),
		}
	},
	["leftBottomPanel.tip"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		}
	},
	["rightBottomPanel.enbattleBtn"] = {
		varname = "enbattleBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEnbattle")},
		}
	},
	["rightBottomPanel.enbattleBtn.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		}
	},
	["rightBottomPanel.buffBtn"] = {
		varname = "buffBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBuff")},
		}
	},
	["rightBottomPanel.buffBtn.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		}
	},
	["rightBottomPanel.shopBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShop")},
		}
	},
	["rightBottomPanel.shopBtn.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		}
	},
	["rightBottomPanel.rankBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRank")},
		}
	},
	["rightBottomPanel.rankBtn.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		}
	},
	["rightBottomPanel.pointBtn"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onPoint")},
			}, {
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "randomTowerPoint",
				}
			}
		}
	},
	["rightBottomPanel.pointBtn.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		}
	},
	["rightBottomPanel.ruleBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRule")},
		}
	},
	["rightBottomPanel.ruleBtn.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		}
	},
	["bg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onBgClick")
		}
	},
	["ruleRankItem"] = "ruleRankItem",
	["marqueePanel"] = {
		varname = "marqueePanel",
		binds = {
			event = "extend",
			class = "marquee",
		}
	}
}

function RandomTowerView:onCreate()
	-- 适配问题	begin
	adapt.centerWithScreen("left", "right", nil, {
		{self.panel, "width"},
	})
	-- 适配问题 end

	gGameModel.currday_dispatch:getIdlerOrigin("randomTower"):set(true)
	gGameUI.topuiManager:createView("random_tower", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.randomTower, subTitle = "AETHER PARADISE"})
	self:initModel()
	adapt.setTextScaleWithWidth(self.startName, nil, 400)
	adapt.setTextScaleWithWidth(self.jumpName, nil, 400)
	self.data = {}
	self.state = idler.new(self:getState())
	self.itemX = self.startPanel:get("item"):x()
	idlereasy.when(self.state, function(_, state)
		local room = self.room:read()
		local floor = csv.random_tower.tower[room].floor
		self.endPanel:visible(state == "end")
		if state == "start" then
			self.startPanel:show()
			self.canStart = true
			--可碾压提示
			local str = getCanPassOrJumpStr()
			if str ~= "" and (floor <= 1) then
				gGameUI:showDialog({title = "", content = str, btnType = 1, isRich = true})
			end
			-- 根据玩家的战斗表现和VIP等级，直接达到较高的层级
			local item = self.startPanel:get("item"):show()
			local jump = self.startPanel:get("jump"):show()
			self.startPanel:removeChildByName("effect")
			if dataEasy.isUnlock(gUnlockCsv.randomTowerJump) and (floor <= 1) then
				item:x(self.itemX)
				randomTowerTools.setEffect(item, "effect_loop", "random_tower/kaishishilian.skel", 100)
				randomTowerTools.setEffect(jump, "effect_loop", "random_tower/kaishishilian.skel", 100)
			else
				randomTowerTools.setEffect(item, "effect_loop", "random_tower/kaishishilian.skel", 100)
				item:x(self.startPanel:width()/2)
				local str = gLanguageCsv.randomTowerStart
				if floor > 1 then
					str = gLanguageCsv.randomTowerEnterNext
				end
				item:get("name"):text(str):show()
				jump:hide()
			end
			self:clearPanel()
		elseif state == "end" then
			self.startPanel:hide()
			local boards = self.boards:read()
			self:initPanel(1, boards[room])
			self:refreshPanel()
		elseif state == "jump" then
			self.startPanel:hide()
			if self.clickToJump ~= true then
				local jumpStep = self.jumpStep:read()
				if jumpStep == game.RANDOM_TOWER_JUMP_STATE.POINT then
					gGameApp:requestServer("/game/random_tower/jump/next", function (tb)
						gGameUI:stackUI("city.adventure.random_tower.jump", nil, nil, nil, self:createHandler("jumpOver"))
					end)
				else
					gGameUI:stackUI("city.adventure.random_tower.jump", nil, nil, nil, self:createHandler("jumpOver"))
				end
			end
		else
			-- 当前层过关后才可以选择下一房间，未过关时所有的后续层都是不可选状态
			-- 可以预览下2个房间的内容
			-- 特殊：一层的最后2间无法预览下一层内容
			self.startPanel:hide()
			local boards = self.boards:read()
			for i = 1, 3 do
				local idx = room + i - 1
				local csvTower = csv.random_tower.tower[idx]
				if csvTower and csvTower.floor ~= floor then
					break
				end
				self:initPanel(i, boards[idx])
			end
			self:refreshPanel(true)
		end
	end)
	-- 当玩家凌晨5点（游戏周期结算时间点）正在游戏，飘字提示，刷新界面：
	local t = time.getNumTimestamp(tonumber(time.getTodayStrInClock()), 5) + 3600 * 24 - time.getTime() + 1
	performWithDelay(self, function()
		local showOver = {false}
		gGameApp:requestServerCustom("/game/random_tower/prepare")
			:params({})
			:onResponse(function (tb)
				showOver[1] = true
			end)
			:wait(showOver)
			:doit(function(tb)
				gGameUI:showTip(gLanguageCsv.randomTowerNextDay)
				self.state:set("start", true)
			end)
	end, t)
end

function RandomTowerView:initModel()
	self.historyRoom = gGameModel.random_tower:getIdler("history_room")
	self.lastRoom = gGameModel.random_tower:getIdler("lastRoom")
	self.room = gGameModel.random_tower:getIdler("room")
	self.boards = gGameModel.random_tower:getIdler("boards")
	self.roomInfo = gGameModel.random_tower:getIdler("room_info")
	self.dayPoint = gGameModel.random_tower:getIdler("day_point")
	self.dayRank = gGameModel.random_tower:getIdler("day_rank")

	self.jumpStep = gGameModel.random_tower:getIdler("jump_step")
	--卡牌血量怒气 {cardID: (hp, mp)}
	self.cardStates = gGameModel.random_tower:getIdler("card_states")
	self.cards = gGameModel.role:getIdler("cards")
end

-- 根据 FLOOR_STATE.scale 初始化面板，居中显示
function RandomTowerView:initPanel(floor, board)
	board = table.deepcopy(board or {}, true)
	local panel = self.panel:clone()
	self.data[floor] = {
		panel = panel,
		board = board,
	}
	for i, v in ipairs(board) do
		local item = self.item:clone()
		local x, y = self:getItemPos(floor, i)
		item:xy(x, y)
			:setCascadeOpacityEnabled(true)
			:setCascadeColorEnabled(true)
			:opacity(FLOOR_STATE.opacity[floor])
			:scale(FLOOR_STATE.scale[floor])
			:show()
			:addTo(panel, 1, i)
		refreshItem(item, v, self.roomInfo:read())
	end
	local x, y = self.panel:xy()
	panel:z(FLOOR_STATE.z[floor])
		:xy(x, y + FLOOR_STATE.y[floor])
		:show()
		:addTo(self:getResourceNode())
	panel:setEnabled(false)
	return panel
end

function RandomTowerView:refreshPanel(enable)
	if self.data[1] == nil then return end

	local panel = self.data[1].panel
	local roomInfo = self.roomInfo:read()
	for _, child in pairs(panel:getChildren()) do
		local canTouch = true
		local idx = child:getTag()
		refreshItem(child, self.data[1].board[idx], roomInfo)
		-- 选定面板。 如怪物挑战，杀进程重进等不能再切换其他面板
		if roomInfo.board_id then
			canTouch = self.data[1].board[idx] == roomInfo.board_id

		-- 攻略一层后，只能选择与上一层序列相近的元素
		elseif idx < roomInfo.next_room_scope[1] or idx > roomInfo.next_room_scope[2] then
			canTouch = false
		end
		child:setTouchEnabled(canTouch == true)
		if canTouch then
			bind.touch(self, child, {
				longtouch = 0.2,
				scaletype = 0,
				method = function(list, node, event)
					self:onItemClick(event, idx)
				end
			})
		else
			cache.setShader(child:get("bg"), false, "hsl_gray_white")
			text.addEffect(child:get("name"), {color = ui.COLORS.NORMAL.WHITE})
			cache.setShader(child:get("name"), false, "hsl_gray_white")
			cache.setShader(child:get("icon"), false, "hsl_gray_white")
			cache.setShader(child:get("iconBg"), false, "hsl_gray_white")
		end
	end
	if enable then
		panel:setEnabled(enable)
	end
end

function RandomTowerView:clearPanel(idx)
	if idx then
		self.data[idx].panel:removeSelf()
		self.data[idx] = nil
	else
		for _, v in pairs(self.data) do
			v.panel:removeSelf()
		end
		self.data = {}
	end
end

function RandomTowerView:getState()
	local room = self.room:read()
	local roomInfo = self.roomInfo:read()
	local roomIdx = csv.random_tower.tower[room].roomIdx
	local jumpStep = self.jumpStep:read()
	if roomInfo.pass then
		return "end"
	end
	if roomIdx == 0 then
		if jumpStep > game.RANDOM_TOWER_JUMP_STATE.BEGIN and jumpStep < game.RANDOM_TOWER_JUMP_STATE.OVER then
			return "jump"
		else
			return "start"
		end
	end
	return "board"
end

function RandomTowerView:onItemClick(event, k)
	if self.isPlaying then
		return
	end
	if event.name == "click" then
		if not self.selectId or self.selectId ~= k then
			if self.selectId then
				self:onPlayLongTouch(self.selectId, false)
			end
			self.selectId = k
			self:onPlayLongTouch(k, true)
			return
		end
		local boardID = self.data[1].board[k]
		local cfg = csv.random_tower.board[boardID]
		-- 怪物对战
		if cfg.type == BOARD_TYPE.monster then
			gGameUI:stackUI("city.adventure.random_tower.gate_detail", nil, nil, boardID, self:createHandler("startFighting", k), self:createHandler("startPassing", k))

		-- 获取buff
		elseif cfg.type == BOARD_TYPE.buff then
			local roomInfo = self.roomInfo:read()
			local buffId = roomInfo.buff[boardID]
			local buffCfg = csv.random_tower.buffs[buffId]
			--buffType  1=属性加成;2=补给;3=积分加成;4=被动技能
			--supplyType 补给类型（1-回血；2-回怒；3-复活）
			--supplyTarget 补给对象（1-选择一只；2-上阵精灵；3-全体符合条件精灵）
			if buffCfg.buffType == 2 and not self:isNeedSupply(buffCfg.condition, buffCfg.supplyTarget) then
				local str = gLanguageCsv.recover
				if buffCfg.supplyType == 3 then
					str = gLanguageCsv.revive
				end
				gGameUI:showDialog({title = "", content = string.format(gLanguageCsv.noCardSupply, str), cb = function()
					local showOver = {false}
					gGameApp:requestServerCustom("/game/random_tower/board")
						:params(boardID)
						:onResponse(function (tb)
							showOver[1] = true
						end)
						:wait(showOver)
						:doit(function(tb)
							showOver[1] = false
							gGameApp:requestServerCustom("/game/random_tower/buff/used")
								:params({})
								:onResponse(function (tb)
									showOver[1] = true
								end)
								:wait(showOver)
								:doit(function(tb)
									self:refreshPanel()
									self:onPlayClick(k)
								end)
						end)
				end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
				return
			end
			local showOver = {false}
			gGameApp:requestServerCustom("/game/random_tower/board")
				:params(boardID)
				:onResponse(function (tb)
					showOver[1] = true
				end)
				:wait(showOver)
				:doit(function(tb)
					self:refreshPanel()
					if buffCfg.buffType == 2 then
						if buffCfg.supplyTarget == 1 then
							gGameUI:stackUI("city.adventure.random_tower.use_buff", nil, nil, boardID, self:createHandler("onPlayClick", k))
						else
							showOver[1] = false
							gGameApp:requestServerCustom("/game/random_tower/buff/used")
								:params({})
								:onResponse(function (tb)
									showOver[1] = true
								end)
								:wait(showOver)
								:doit(function(tb)
									self:onPlayClick(k)
									randomTowerTools.setEffect(self.buffBtn:get("icon"), buffCfg.buffColor, "random_tower/jiacheng.skel")
								end)
						end
					else
						self:onPlayClick(k)
						randomTowerTools.setEffect(self.buffBtn:get("icon"), buffCfg.buffColor, "random_tower/jiacheng.skel")
					end
				end)
		-- 获取宝箱
		elseif cfg.type == BOARD_TYPE.box then
			local showOver = {false}
			gGameApp:requestServerCustom("/game/random_tower/board")
				:params(boardID)
				:onResponse(function (tb)
					showOver[1] = true
				end)
				:wait(showOver)
				:doit(function(tb)
					self:refreshPanel()
					gGameUI:stackUI("city.adventure.random_tower.open_box", nil, {clickClose = true}, boardID, self:createHandler("onPlayClick", k))
				end)
		-- 随机事件
		elseif cfg.type == BOARD_TYPE.event then
			local roomInfo = self.roomInfo:read()
			local eventId =  roomInfo.event[boardID]
			local showOver = {false}
			gGameApp:requestServerCustom("/game/random_tower/board")
				:params(boardID)
				:onResponse(function (tb)
					showOver[1] = true
				end)
				:wait(showOver)
				:doit(function(tb)
					self:refreshPanel()
					local cfg = csv.random_tower.event[eventId]
					if cfg.choice1 == "" then
						gGameUI:stackUI("city.adventure.random_tower.event_reward", nil, {clickClose = true}, {
							boardID = boardID,
							eventId = eventId,
							tb = tb,
							cb = self:createHandler("onPlayClick", k)
						})
					else
						gGameUI:stackUI("city.adventure.random_tower.select_event", nil, {clickClose = true}, boardID, self:createHandler("onPlayClick", k))
					end
				end)
		end
	end
end

--判断是否有需要补给的精灵
function RandomTowerView:isNeedSupply(condition, supplyTarget)
	local cards = randomTowerTools.getCards(supplyTarget)
	for i,cardDbId in pairs(cards) do
		local cardState = self.cardStates:read()[cardDbId]
		if randomTowerTools.reachCondition(condition, cardState, cardDbId) then
			return true
		end
	end
	return false
end
-- 获取对应层，对应缩放面板的 位置
function RandomTowerView:getItemPos(floor, idx)
	local panel = self.data[floor].panel
	local n = #self.data[floor].board
	local scale = FLOOR_STATE.scale[floor]
	local step = (self.item:width() * scale + 20 * (1 - scale))*(display.sizeInViewRect.width/display.width)
	local x = panel:width()/2 - (n - 1)/2 * step + (idx - 1) * step
	local y = panel:height()/2
	return x, y
end

-- 设置子面板的动画
function RandomTowerView:onItemAnimation(floor, params)
	local panel = self.data[floor].panel
	local t = params.t
	local scale = FLOOR_STATE.scale[floor]
	local opacity = FLOOR_STATE.opacity[floor]
	for _, child in pairs(panel:getChildren()) do
		if child:getTag() == params.choose then
			transition.executeSpawn(child, true)
				:fadeTo(1, opacity)
				:done()

			widget.addAnimation(child, "random_tower/shilianta_dianji.skel", "effect", 99)
				:xy(child:width()/2, child:height()/2)
				:scale(2)
				:play("effect")
		else
			local x, y = self:getItemPos(floor, child:getTag())
			transition.executeSpawn(child, true)
				:scaleTo(t, scale)
				:moveTo(t, x, y + (params.dx or 0))
				:fadeTo(t, opacity)
				:done()
		end
	end
end
-- 点击背景复原动画
function RandomTowerView:onBgClick()
	if self.selectId then
		self:onPlayLongTouch(self.selectId, false)
		self.selectId = nil
	end
end
-- 固定只能点击第一层，选择第 idx 个面板
function RandomTowerView:onPlayClick(idx)
	self:onBgClick()
	self.isPlaying = true
	if self.data[1] then
		self.data[1].panel:setEnabled(false)
	end

	-- 加入后一层数据界面
	local room = self.room:read()
	local floor = csv.random_tower.tower[math.max(room-1, 1)].floor
	local csvTower = csv.random_tower.tower[room + 2]
	if csvTower and csvTower.floor == floor then
		local boards = self.boards:read()
		self:initPanel(4, boards[room + 2])
	end

	local n = table.maxn(self.data) - 1
	if n < 1 then
		self.isPlaying = false
		self.state:set(self:getState())
		return
	end

	-- 先数据变动，后面设置动画表现
	-- TODO: self.data有中空的可能
	local data, j = {}, 0
	for i = 0, n do
		local floorData = self.data[i+1]
		if floorData then
			data[j] = floorData
			floorData.panel:z(FLOOR_STATE.z[i])
			j = j + 1
		end
	end
	self.data = data
	n = j - 1
	self:refreshPanel()

	local function playEnd(flag)
		if n == flag then
			self.isPlaying = false
			if self.data[1] then
				self.data[1].panel:setEnabled(true)
			end
			self:clearPanel(0)
			self.state:set(self:getState())
		end
	end
	local x, y = self.panel:xy()
	local dt = 1
	local t = 0.2
	transition.executeSequence(self.data[0].panel, true)
		:func(functools.partial(self.onItemAnimation, self, 0, {t = dt/2, choose = idx, dx = FLOOR_STATE.y[0]}))
		:delay(dt)
		:hide()
		:func(functools.partial(playEnd, 0))
		:done()

	for i = 1, math.min(n, 2) do
		transition.executeSequence(self.data[i].panel, true)
			:delay(dt + t * (i - 1))
			:easeBegin("OUT")
				:moveTo(t, x, y + FLOOR_STATE.y[i+1] + 50)
			:easeEnd()
			:func(functools.partial(self.onItemAnimation, self, i, {t = t*2}))
			:easeBegin("OUT")
				:moveTo(t*2, x, y + FLOOR_STATE.y[i])
			:easeEnd()
			:func(functools.partial(playEnd, i))
			:done()
	end

	if n >= 3 then
		transition.executeSequence(self.data[3].panel, true)
			:delay(dt + t*3)
			:func(functools.partial(self.onItemAnimation, self, 3, {t = t*2}))
			:easeBegin("OUT")
				:moveTo(t*2, x, y + FLOOR_STATE.y[3])
			:easeEnd()
			:func(functools.partial(playEnd, 3))
			:done()
	end
end

-- 长按第 idx 个面板动画表现  press：按住/松开
function RandomTowerView:onPlayLongTouch(idx, press)
	local t = 0.4
	if self.data[1] then
		local panel = self.data[1].panel
		local opacity = FLOOR_STATE.opacity[1]
		for _, child in pairs(panel:getChildren()) do
			local tag = child:getTag()
			local x, y = self:getItemPos(1, tag)
			if press then
				if tag == idx then
					transition.executeSpawn(child, true)
						:easeBegin("EXPONENTIALOUT")
							:moveTo(t, x, y + 50)
						:easeEnd()
						:done()
					local effect = widget.addAnimationByKey(child, "random_tower/slt_xuanzhong.skel", "effect", "effect_loop", 99)
						:xy(child:width()/2, child:height()/2)
						:scale(2)
					effect:show()
				else
					transition.executeSpawn(child, true)
						:easeBegin("BACKOUT")
							:moveTo(2*t, x, y)
						:easeEnd()
						:done()
					if child:get("effect") then
						child:get("effect"):hide()
					end
				end
			else
				transition.executeSpawn(child, true)
					:easeBegin("OUT")
						:moveTo(t, x, y)
					:easeEnd()
					:done()
				if child:get("effect") then
					child:get("effect"):hide()
				end
			end
		end
	end

	if self.data[2] then
		local panel = self.data[2].panel
		local opacity = FLOOR_STATE.opacity[2]
		for _, child in pairs(panel:getChildren()) do
			local tag = child:getTag()
			local x, y = self:getItemPos(2, tag)
			if press then
				if self:isLongTouchHighLight(idx, tag) then
					y = y + 35
					local effect = widget.addAnimationByKey(child, "random_tower/slt_xuanzhong.skel", "effect", "effect_loop", 99)
						:xy(child:width()/2, child:height()/2)
						:scale(2)
					effect:show()
				end
				transition.executeSpawn(child, true)
					:easeBegin("OUT")
						:moveTo(2*t, x, y)
					:easeEnd()
					:done()

			else
				transition.executeSpawn(child, true)
					:easeBegin("OUT")
						:moveTo(t, x, y)
					:easeEnd()
					:done()

				if self:isLongTouchHighLight(idx, tag) and child:get("effect") then
					child:get("effect"):hide()
				end
			end
		end
	end
end

-- 选择第一层 idx1, 第二层 idx2 是否是高亮
function RandomTowerView:isLongTouchHighLight(idx1, idx2)
	local n1 = #self.data[1].board
	local n2 = #self.data[2].board
	-- 1-任意，任意-1，都是全部可选
	if n1 == 1 or n2 == 1 then
		return true
	end
	local st = (n2 - n1) / 2
	return (idx2 >= st + idx1 - 1) and (idx2 <= st + idx1 + 1)
end

function RandomTowerView:onStartClick()
	if self.canStart == true then
		local showOver = {false}
		gGameApp:requestServerCustom("/game/random_tower/board")
			:params({})
			:onResponse(function (tb)
				self.startPanel:get("jump"):hide()
				local item = self.startPanel:get("item")
					:x(self.startPanel:width()/2)
				item:get("name"):hide()
				randomTowerTools.setEffect(self.startPanel, "bj", "random_tower/kaishishilian.skel")
				randomTowerTools.setEffect(item, "effect", "random_tower/kaishishilian.skel")
				--选择高亮ID为空
				self.selectId = nil
				performWithDelay(self, function()
					self.canStart = false
					showOver[1] = true
				end, 1)
			end)
			:wait(showOver)
			:doit(function(tb)
				self.state:set(self:getState(), true)
			end)
	end
end
--直通高层跳转
function RandomTowerView:onJumpClick( )
	if self.canStart == true then
		local showOver = {false}
		gGameApp:requestServerCustom("/game/random_tower/jump/next")
			:params({})
			:onResponse(function (tb)
				self.startPanel:get("item"):hide()
				local jump = self.startPanel:get("jump")
					:x(self.startPanel:width()/2)
				jump:get("name"):hide()
				randomTowerTools.setEffect(self.startPanel, "bj", "random_tower/kaishishilian.skel")
				randomTowerTools.setEffect(jump, "effect", "random_tower/kaishishilian.skel")
				--选择高亮ID为空
				self.selectId = nil
				performWithDelay(self, function()
					self.canStart = false
					showOver[1] = true
				end, 1)
			end)
			:wait(showOver)
			:doit(function(tb)
				self.clickToJump = true --是否是点击跳转到直达页面
				self.state:set(self:getState(), true)
				gGameUI:stackUI("city.adventure.random_tower.jump", nil, nil,tb.view, self:createHandler("jumpOver"))
			end)
	end
end

function RandomTowerView:onEnbattle()
	gGameUI:stackUI("city.card.embattle.random", nil, {full = true},
		{
			from = "huodong",
			fromId = game.EMBATTLE_HOUDONG_ID.randomTower
		})
end
function RandomTowerView:onBuff()
	gGameUI:stackUI("city.adventure.random_tower.look_buff", nil, {clickClose = true, backGlass = true})
end

function RandomTowerView:onShop()
	if not gGameUI:goBackInStackUI("city.shop") then
		local showOver = {false}
		gGameApp:requestServerCustom("/game/random_tower/shop/get")
			:params({})
			:onResponse(function (tb)
				showOver[1] = true
			end)
			:wait(showOver)
			:doit(function(tb)
				gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.RANDOM_TOWER_SHOP)
			end)
	end
end

function RandomTowerView:onRank()
	local showOver = {false}
	gGameApp:requestServerCustom("/game/rank")
		:params("random_tower", 0, 50)
		:onResponse(function (tb)
			showOver[1] = true
		end)
		:wait(showOver)
		:doit(function(tb)
			gGameUI:stackUI("city.adventure.random_tower.rank", nil, nil, tb.view)
		end)
end

function RandomTowerView:onPoint()
	gGameUI:stackUI("city.adventure.random_tower.point_reward")
end

function RandomTowerView:onRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function RandomTowerView:getRuleContext(view)
	local rank = self.dayRank:read()
	local nowAwardData
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.randomTowerRule)
		end),
		c.clone(self.ruleRankItem, function(item)
			local childs = item:multiget("textNow1", "now", "textNow2", "list")
			if not nowAwardData then
				nodetools.invoke(item, {"textNow1", "now", "textNow2", "list"}, "hide")
				setContentSizeOfAnchor(item, cc.size(self.ruleRankItem:size().width, nowAwardData and 320 or 0))
			else
				childs.now:text(rank)
				adapt.oneLinePos(childs.textNow1, {childs.now, childs.textNow2}, cc.p(5, 0))
				uiEasy.createItemsToList(view, childs.list, nowAwardData.periodAward)
				childs.list:setItemAlignCenter()
			end
		end),
		c.noteText(110),
		c.noteText(2001, 2010),
		c.noteText(108),
		c.noteText(2011, 2020),
		c.noteText(103),
	}
	local version = getVersionContainMerge("randomTowerAwardVer")
	for k, v in orderCsvPairs(csv.random_tower.rank_award) do
		if v.version == version then
			if rank >= v.range[1] and rank < v.range[2] then
				nowAwardData = v
			end
			table.insert(context, c.clone(view.awardItem, function(item)
				local childs = item:multiget("text", "list")
				if v.range[2] - v.range[1] == 1 then
					childs.text:text(string.format(gLanguageCsv.rankSingle, v.range[1]))
				else
					childs.text:text(string.format(gLanguageCsv.rankMulti, v.range[1], v.range[2] - 1))
				end
				uiEasy.createItemsToList(view, childs.list, v.periodAward)
			end))
		end
	end
	return context
end

function RandomTowerView:startFighting(k)
	local boardID = self.data[1].board[k]
	local battleCardIDs = table.deepcopy(gGameModel.role:read("huodong_cards")[game.EMBATTLE_HOUDONG_ID.randomTower], true)

	battleEntrance.battleRequest("/game/random_tower/start", battleCardIDs, boardID)
		:onStartOK(function(data)
			self.selectId = nil
			gGameUI:goBackInStackUI("city.adventure.random_tower.view")
		end)
		:show()
end

-- 碾压战斗回调
function RandomTowerView:startPassing(k)
	local boardID = self.data[1].board[k]
	local showOver = {false}
	gGameApp:requestServerCustom("/game/random_tower/pass")
		:params(boardID)
		:onResponse(function (tb)
			showOver[1] = true
		end)
		:wait(showOver)
		:doit(function(tb)
			gGameUI:goBackInStackUI("city.adventure.random_tower.view")
			local data = clone(tb.view.award) or {}
			-- 特殊积分当道具显示
			if tb.view.point then
				table.insert(data, {[417] = tb.view.point})
			end
			gGameUI:showGainDisplay(data, {cb = function()
				self:onPlayClick(k)
			end})
		end)
end
--直达高层结束 刷新状态
function RandomTowerView:jumpOver()
	self:clearPanel()
	--调用此函数时 self.room 数据可能未同步 顾延迟一帧操作
	performWithDelay(self,function ()
		self.state:set(self:getState(), true)
	end,0)
end

return RandomTowerView