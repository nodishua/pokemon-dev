-- @date:   2020-04-01
-- @desc:   随机塔-直通高层

local ViewBase = cc.load("mvc").ViewBase
local randomTowerTools = require "app.views.city.adventure.random_tower.tools"
local RandomTowerJumpView = class("RandomTowerJumpView", Dialog)
local OPEN_TIMES = {
	ONCE = "ONCE",
	ALL = "ALL"
}

RandomTowerJumpView.RESOURCE_FILENAME = "random_tower_jump.json"
RandomTowerJumpView.RESOURCE_BINDING = {
	["panel1"] = "panel1",
	["panel1.subList"] = "awardList",
	["panel1.item"] = "awardItem",

	["panel2"] = "panel2",
	["panel2.item"] = "item2",
	["panel2.sortPanel"] = {
		varname = "sortPanel",
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				data = bindHelper.self("sortDatas"),
				expandUp = true,
				btnType = 4,
				btnClick = bindHelper.self("onSortMenusBtnClick",true),
				onNode = function (node)
					node:xy(-1125,-477):z(18)
					node.btn4:setColor(cc.c3b(255, 255, 255))
				end
			}
		}
	},
	["panel2.btnOpenAll"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClickOpenAll")},
		},
	},
	["panel2.textTitle"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("boxesCount"),
			method = function(val)
				return string.format(gLanguageCsv.randomTowerJumpBoxesCount,val)
			end,
		},
	},
	["panel2.subList"] = {
		varname = "list2",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				margin = 24,
				data = bindHelper.self("boxData"),
				item = bindHelper.self("item2"),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					local aCfg = csv.random_tower.board[a.boardID]
					local aCsvTower = csv.random_tower.tower[aCfg.room]

					local bCfg = csv.random_tower.board[b.boardID]
					local bCsvTower = csv.random_tower.tower[bCfg.room]

					local maxOpen = gCommonConfigCsv.randomTowerBoxLimit2 --最多开次数
					if a.times == b.times then
						if aCsvTower.floor == bCsvTower.floor then
							return aCsvTower.roomIdx < bCsvTower.roomIdx
						else
							return aCsvTower.floor < bCsvTower.floor
						end
						return false
					elseif a.times == maxOpen then
						return false
					elseif b.times == maxOpen then
						return true
					else
						if aCsvTower.floor == bCsvTower.floor then
							return aCsvTower.roomIdx < bCsvTower.roomIdx
						else
							return aCsvTower.floor < bCsvTower.floor
						end
						return false
					end
				end,
				onItem = function(list, node, k, v)
					local maxOpen = gCommonConfigCsv.randomTowerBoxLimit2 --最多开次数
					local imgGotten = node:get("imgGotten")
					imgGotten:setVisible(v.times == maxOpen)
					if v.times == maxOpen then
						nodetools.invoke(node, {"imgGotten","textBox"}, "show")
						nodetools.invoke(node, {"btn1","btn2", "imgDiamond1", "imgDiamond2", "textDiamond1", "textDiamond2"}, "hide")
					else
						nodetools.invoke(node, {"imgGotten","textBox"}, "hide")
						nodetools.invoke(node, {"btn1","btn2", "imgDiamond1", "imgDiamond2", "textDiamond1", "textDiamond2"}, "show")
						local costCsv = gCostCsv.random_tower_box_cost2
						local openOneCost = costCsv[math.min(v.times + 2, table.length(costCsv))]
						local openAllCost = 0
						for i = v.times + 2, maxOpen + 1 do --第一次免费 从第二次开始算
							if costCsv[i] then
								openAllCost = openAllCost + costCsv[i]
							else
								openAllCost = openAllCost + costCsv[table.length(costCsv)]
							end
						end
						node:get("textDiamond1"):text(openOneCost)
						node:get("textDiamond2"):text(openAllCost)

						local btn1 = node:get("btn1")
						bind.touch(list, btn1, {methods = {ended = function()
							if gGameModel.role:read("rmb") < openOneCost then
								uiEasy.showDialog("rmb")
							else
								gGameApp:requestServer("/game/random_tower/jump/box_open", function (tb)
									gGameUI:showGainDisplay(tb)
								end, v.boardID, "open1")
							end
						end}})

						local btn2 = node:get("btn2")
						btn2:get("textNote"):text(string.format(gLanguageCsv.openBoxesTimes,(maxOpen - v.times)))
						bind.touch(list, btn2, {methods = {ended = function()
							if gGameModel.role:read("rmb") < openAllCost then
								uiEasy.showDialog("rmb")
							else
								gGameApp:requestServer("/game/random_tower/jump/box_open", function (tb)
									gGameUI:showGainDisplay(tb)
								end, v.boardID, "open5")
							end
						end}})
					end

					local cfg = csv.random_tower.board[v.boardID]
					local imgBox = node:get("imgBox")
					imgBox:texture(cfg.icon)

					local csvTower = csv.random_tower.tower[cfg.room]
					local textRoom = node:get("textRoom")
					textRoom:text(string.format(gLanguageCsv.randomTowerFloorAndRoom,csvTower.floor, csvTower.roomIdx))
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end,
			},
			handlers = {
				clickBtn1 = bindHelper.self("onBoxClick1"),
				clickBtn2 = bindHelper.self("onBoxClick2"),
			},
		},
	},
	["panel2.textDiamond"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("openAllBoxesCost"),
		},
	},

	["panel3"] = "panel3",
	["panel3.item"] = "item3",
	["panel3.btnRandom"] = {
		binds = {
			event = "touch",
			methods = {ended = function(  )
				gGameApp:requestServer("/game/random_tower/jump/buff", function (tb)
					-- gGameUI:showGainDisplay(tb)
				end, 0)
			end},
		},
	},
	["panel3.subList"] = {
		varname = "list3",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				margin = 24,
				data = bindHelper.self("bufData"),
				item = bindHelper.self("item3"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local buffCsv = csv.random_tower.buffs[v]
					local desc = buffCsv.desc
					local icon = buffCsv.icon
					local iconBg = buffCsv.iconBg
					node:get("iconBg"):texture(iconBg)
					node:get("icon"):texture(icon)

					beauty.textScroll({
						list = node:get("desc"),
						strs = desc,
						align = "center",
						fontSize = 34,
					})

					bind.touch(list, node, {methods = {ended = function()
						gGameApp:requestServer("/game/random_tower/jump/buff", function (tb)
							-- gGameUI:showGainDisplay(tb)
						end, k)
					end}})

					local strTab = {
						[1] = gLanguageCsv.randomTowerJumpBUff1,
						[2] = gLanguageCsv.randomTowerJumpBUff2,
						[3] = gLanguageCsv.randomTowerJumpBUff3,
						[4] = gLanguageCsv.randomTowerJumpBUff4,
					}
					local textRoom = node:get("name")
					textRoom:text(strTab[buffCsv.buffType])
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end,
			},
			handlers = {
				clickBtn1 = bindHelper.self("onClickBuff"),
			},
		},
	},

	["panel4"] = "panel4",
	["panel4.item"] = "item4",
	["panel4.subList"] = {
		varname = "list4",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				margin = 24,
				data = bindHelper.self("eventData"),
				item = bindHelper.self("item4"),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					local aCfg = csv.random_tower.board[a.boardID]
					local aCsvTower = csv.random_tower.tower[aCfg.room]

					local bCfg = csv.random_tower.board[b.boardID]
					local bCsvTower = csv.random_tower.tower[bCfg.room]
					local flagA = a.data[2]
					local flagB = b.data[2]

					if flagA == flagB then
						if aCsvTower.floor == bCsvTower.floor then
							return aCsvTower.roomIdx < bCsvTower.roomIdx
						else
							return aCsvTower.floor < bCsvTower.floor
						end
						return false
					elseif flagA == 1 then
						return false
					elseif flagB == 1 then
						return true
					else
						if aCsvTower.floor == bCsvTower.floor then
							return aCsvTower.roomIdx < bCsvTower.roomIdx
						else
							return aCsvTower.floor < bCsvTower.floor
						end
						return false
					end
				end,
				onItem = function(list, node, k, v)
					local eventId = v.data[1]
					local flag = v.data[2]
					local eventCsv = csv.random_tower.event[eventId]
					local desc = eventCsv.desc
					local icon = eventCsv.icon

					local cfg = csv.random_tower.board[v.boardID]
					local csvTower = csv.random_tower.tower[cfg.room]
					local floor = csvTower.floor
					local index =  csvTower.roomIdx

					node:get("name"):text(string.format(gLanguageCsv.randomTowerFloorAndRoom,floor, index))
					node:get("imgCheck"):setVisible(flag ~= 0)
					beauty.textScroll({
						list = node:get("desc"),
						strs = desc,
						align = "center",
						fontSize = 34,
					})
					if flag == 0 then
						bind.touch(list, node, {methods = {ended = function()
							if eventCsv.choice1 == "" then
								gGameUI:stackUI("city.adventure.random_tower.event_reward", nil, {clickClose = true}, {
									boardID = v.boardID,
									eventId = eventId,
								})
							else
								gGameUI:stackUI("city.adventure.random_tower.select_event", nil, {clickClose = true}, v.boardID, nil, eventId)
							end
						end}})
					else
						node:setEnabled(false)
					end
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end,
			},
		},
	},
	["btnNext"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("requestNext")},
		},
	},
	["progressPanel"] = "progressPanel",
}



function RandomTowerJumpView:onCreate(jumpData, cb)
	self:initModel()
	self.cb = cb
	self.jumpData = jumpData
	idlereasy.any({self.jumpStep,self.jumpInfo}, function(_, jumpStep, jumpInfo)
		if jumpStep == game.RANDOM_TOWER_JUMP_STATE.POINT then
			self.panel1:show()
		elseif jumpStep == game.RANDOM_TOWER_JUMP_STATE.BOX then
			self.panel1:hide()
			self.panel2:show()
		elseif jumpStep == game.RANDOM_TOWER_JUMP_STATE.BUFF then
			self.panel2:hide()
			self.panel3:show()
		elseif jumpStep == game.RANDOM_TOWER_JUMP_STATE.EVENT then
			self.panel3:hide()
			self.panel4:show()
		end
		if jumpStep <= game.RANDOM_TOWER_JUMP_STATE.EVENT then
			self["refreshPanel"..jumpStep.."Data"](self,jumpInfo)
			self:refreshProgressPanel(jumpStep)
		end
	end)

	idlereasy.when(self.jumpStep, function(_, jumpStep)
		if jumpStep == game.RANDOM_TOWER_JUMP_STATE.OVER then
			self:addCallbackOnExit(self.cb)
			ViewBase.onClose(self)
		end
	end)


	Dialog.onCreate(self)
end

function RandomTowerJumpView:onClose(  )

end

function RandomTowerJumpView:initModel()
	self.jumpStep = gGameModel.random_tower:getIdler("jump_step")
	self.jumpInfo = gGameModel.random_tower:getIdler("jump_info")
	--宝箱数据
	self.boxData = idlers.newWithMap({})
	self.openAllBoxesCost = idler.new(0)
	self.boxesCount = idler.new(0)
	--加成数据
	self.bufData = idlertable.new({})
	self.bufRoomIndex = idler.new(0)

	--事件数据
	self.eventData = idlers.newWithMap({})

	--全部开启列表
	local OPEN_TIMES1 = {gLanguageCsv.randomTowerOpenAll,gLanguageCsv.randomTowerOpenOnce}
	self.sortDatas = idlertable.new(OPEN_TIMES1)
	self.openTimes = idler.new(OPEN_TIMES.ALL)
end

function RandomTowerJumpView:refreshOpenAllBoxesCost(boxes, openTimes)
	local maxOpen = gCommonConfigCsv.randomTowerBoxLimit2 --最多开次数
	local costCsv = gCostCsv.random_tower_box_cost2
	local openAllCost = 0
	if openTimes == OPEN_TIMES.ONCE then
		for k, v in pairs(boxes) do
			if costCsv[v + 2] and v <= maxOpen - 1 then
				openAllCost = openAllCost + costCsv[v + 2]
			end
		end
	else
		for k, v in pairs(boxes) do
			for i = v + 2, maxOpen + 1 do
				if costCsv[i] then
					openAllCost = openAllCost + costCsv[i]
				else
					openAllCost = openAllCost + costCsv[table.length(costCsv)]
				end
			end
		end
	end
	self.openAllBoxesCost:set(openAllCost)
end

function RandomTowerJumpView:refreshPanel1Data( )
	self.panel1:show()
	self:initRichPanel()
	self:initAward()
end

function RandomTowerJumpView:refreshPanel2Data(jumpInfo)
	self.panel1:hide()
	self.panel2:show()
	local data = {}
	local boxes = jumpInfo.boxes or {}
	for k, v in pairs(boxes) do
		table.insert(data,{boardID = k,times = v})
	end
	self.boxData:update(data)
	self.boxesCount:set(itertools.size(boxes))
	idlereasy.when(self.openTimes, function(_, openTimes)
		self:refreshOpenAllBoxesCost(boxes, openTimes)
	end)
end

function RandomTowerJumpView:refreshPanel3Data(jumpInfo)
	self.panel2:hide()
	self.panel3:show()
	local buffs = jumpInfo.buffs
	if jumpInfo.buff_index and buffs and buffs[jumpInfo.buff_index] then
		local buf = buffs[jumpInfo.buff_index]
		self.bufData:set(buf)
		self.bufRoomIndex:set(jumpInfo.buff_index)
		self:refreshBuffIndex()
	else
		self.bufData:set({})
	end
end

function RandomTowerJumpView:refreshPanel4Data(jumpInfo)
	self.panel3:hide()
	self.panel4:show()

	local data = {}
	local events = jumpInfo.events or {}
	for k, v in pairs(events) do
		table.insert(data,{boardID = k,data = v})
	end
	self.eventData:update(data)
end

--获取可碾压提示文本
function RandomTowerJumpView:getPanel1Str()
	local tablestr = {
		[1] = "",
		[2] = "",
		[3] = "",
		[4] = "",
	}

	local max = randomTowerTools.getCanJumpMaxRoom()
	if max <= 1 then
		tablestr[1] = ""
	else
		local csvTower = csv.random_tower.tower[max]
		local str1 = gLanguageCsv.randomTowerJumpTips1
		tablestr[1] =  string.format(str1,csvTower.floor, csvTower.roomIdx)
	end
	local jumpInfo = self.jumpInfo:read()
	local str2 = gLanguageCsv.randomTowerJumpTips2
	tablestr[2] = string.format(str2,self.jumpData.battle,self.jumpData.points)

	local buffs = jumpInfo.buffs or {}
	local bufCount = itertools.size(buffs)
	local events = jumpInfo.events or {}
	local eventCount = itertools.size(events)
	local str3 = gLanguageCsv.randomTowerJumpTips3
	tablestr[3] = string.format(str3,bufCount,eventCount)

	local boxes = jumpInfo.boxes or {}
	local boxCount = itertools.size(boxes)
	local str4 = gLanguageCsv.randomTowerJumpTips4
	tablestr[4] = string.format(str4,self.jumpData.generalBoxes,boxCount)
	return tablestr
end
function RandomTowerJumpView:initRichPanel( )
	local str = self:getPanel1Str()
	for k, v in ipairs(str) do
		local rich = rich.createByStr(v, 50)
			:addTo(self.panel1, 10)
			:setAnchorPoint(cc.p(0,0.5))
			:xy(cc.p(80,1082 - 90 * k))
			:formatText()
	end
end

function RandomTowerJumpView:initAward( )
	local awardData = self.jumpData.award
	bind.extend(self, self.awardList, {
		class = "listview",
		props = {
			data = dataEasy.getItemData(awardData),
			item = self.awardItem,
			dataOrderCmp = dataEasy.sortItemCmp,
			itemAction = {isAction = true},
			onAfterBuild = function()
				self.awardList:setItemAlignCenter()
				self.awardList:adaptTouchEnabled()
			end,
			onItem = function(list, node, k, v)
				bind.extend(list, node, {
					class = "icon_key",
					props = {
						data = v,
						grayState = v.grayState,
					},
				})
			end,
		}
	})

end

function RandomTowerJumpView:requestNext( )
	local step = self.jumpStep:read()
	local jumpInfo = self.jumpInfo:read()
	local tips = ""
	if step == game.RANDOM_TOWER_JUMP_STATE.BOX then
		if self.openAllBoxesCost:read() ~= 0 then
			tips = gLanguageCsv.randomTowerJumpNextTips1
		end
	elseif step == game.RANDOM_TOWER_JUMP_STATE.BUFF then
		local roomIndex = jumpInfo.buff_index or 0
		local buffs = jumpInfo.buffs or {}
		local count = itertools.size(buffs)
		if roomIndex < count then
			tips = gLanguageCsv.randomTowerJumpNextTips2
		end
	elseif step == game.RANDOM_TOWER_JUMP_STATE.EVENT then
		local events = jumpInfo.events or {}
		for k, v in pairs(events)do
			if v[2] == 0 then
				tips = gLanguageCsv.randomTowerJumpNextTips3
				break
			end
		end
	end
	if tips ~= "" then
		gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = tips, btnType = 2, cb = function ()
			gGameApp:requestServer("/game/random_tower/jump/next")
		end})
	else
		gGameApp:requestServer("/game/random_tower/jump/next")
	end
end

--刷新底部进度
function RandomTowerJumpView:refreshProgressPanel(step)
	local imgTab = {}
	local imgBarTab = {}
	local textTab = {}
	for i = 2, 4 do
		if step >= i then
			table.insert(imgTab,"img"..i)
			table.insert(imgBarTab,"imgBar"..i)
			table.insert(textTab,"text"..i)
		end
	end
	local panel = self.progressPanel
	nodetools.invoke(panel, imgTab, "texture","city/adventure/random_tower/bar_d.png")
	nodetools.invoke(panel, imgBarTab, "texture","city/adventure/random_tower/bar_dt.png")
	nodetools.invoke(panel, textTab, "setTextColor", cc.c4b(247, 83, 100, 255))
end

--buf房间
function RandomTowerJumpView:refreshBuffIndex()
	local str1 = gLanguageCsv.randomTowerJumpBuffTips
	local roomIndex = self.bufRoomIndex:read() or 0
	local buffs = self.jumpInfo:read().buffs or {}
	local count = itertools.size(buffs)
	local floor = 0
	local index = 0
	for boardID, buffId in pairs(buffs[roomIndex]) do
		local cfg = csv.random_tower.board[boardID]
		local csvTower = csv.random_tower.tower[cfg.room]
		floor = csvTower.floor
		index =  csvTower.roomIdx
		break
	end
	local str = string.format(str1,floor,index,roomIndex, count)
	local textTips = self.panel3:get("textTips"):hide()
	self.panel3:removeChildByName("richTips")
	rich.createByStr(str, 50)
		:addTo(self.panel3, 10)
		:setAnchorPoint(cc.p(0.5,0.5))
		:xy(textTips:xy())
		:formatText()
		:setName("richTips")
end

function RandomTowerJumpView:onClickOpenAll( )
	if self.openAllBoxesCost:read() == 0 then
		return
	end
	if gGameModel.role:read("rmb") < self.openAllBoxesCost:read() then
		uiEasy.showDialog("rmb")
	else
		local showOver = {false}
			if self.openTimes:read() == OPEN_TIMES.ONCE then
				gGameApp:requestServerCustom("/game/random_tower/jump/box_open")
					:params(0, "open1")
					:onResponse(function (tb)
						showOver[1] = true
					end)
					:wait(showOver)
					:doit(function (tb)
						gGameUI:showGainDisplay(tb)
					end)
			else
				gGameApp:requestServerCustom("/game/random_tower/jump/box_open")
					:params(0, "open5")
					:onResponse(function (tb)
						showOver[1] = true
					end)
					:wait(showOver)
					:doit(function (tb)
						gGameUI:showGainDisplay(tb)
					end)
			end
	end
end
--随机buf
function RandomTowerJumpView:onClickBufRandom(  )
	local showOver = {false}
	gGameApp:requestServerCustom("/game/random_tower/jump/buff")
		:params(0)
		:onResponse(function (tb)
			showOver[1] = true
		end)
		:wait(showOver)
		:doit(function (tb)
		end)
end
--选择buf
function RandomTowerJumpView:onClickbuff(boardID)
	local showOver = {false}
	gGameApp:requestServerCustom("/game/random_tower/jump/buff")
		:params(boardID)
		:onResponse(function (tb)
			showOver[1] = true
		end)
		:wait(showOver)
		:doit(function (tb)
			gGameUI:showTip("buf2")
		end)
end


function RandomTowerJumpView:onSortMenusBtnClick(panel, node, k, v, oldval)
	if k == 1 then
		self.openTimes:set(OPEN_TIMES.ALL)
	else
		self.openTimes:set(OPEN_TIMES.ONCE)
	end
end

return RandomTowerJumpView
