-- @date:   2020-08-18
-- @desc:   道馆挑战主界面

local ViewBase = cc.load("mvc").ViewBase
local GymChallengeView = class("GymChallengeView", ViewBase)

local MAP_SCALE = gCommonConfigCsv.gymMapScale
local CROSS_MAP_SCALE = gCommonConfigCsv.crossMapScale

local STATE = {
	GAMING = 1,
	ENDED = 2,
	WAIT_STAR = 3,
}
local islandCfg = {
	[1] = {pos = {x = 600, y = 3450}, scale = 3, spine = "dao2_loop"},
	[2] = {pos = {x = 5754, y =3040}, scale = 2, spine = "dao5_loop"},
	[3] = {pos = {x = 290, y = 600}, scale = 2, spine = "dao4_loop"},
	[4] = {pos = {x = 4180, y = 160}, scale = 2, spine = "dao1_loop"},
	[5] = {pos = {x = 6000, y = 1800}, scale = 2, spine = "dao3_loop"},
	[6] = {pos = {x = 5000, y = 3550}, scale = 2, spine = "dao15_loop"},
	[7] = {pos = {x = 50, y = 2750}, scale = 2, spine = "dao14_loop"},
	[8] = {pos = {x = 2000, y = 3230}, scale = 1.8, spine = "dao3_loop"},
	[9] = {pos = {x = 400, y = 1640}, scale = 2, spine = "dao2_loop"},
}

GymChallengeView.RESOURCE_FILENAME = "gym_challenge.json"
GymChallengeView.RESOURCE_BINDING = {
	["scrollView"] = {
		varname = "scrollView",
		binds = {
			event = "scrollBarEnabled",
			data = false,
		}
	},
	["gymItem"] = "gymItem",
	["rightTopPanel.textNote1"] = {
		varname = "textNote1",
		binds = {
			event = "effect",
			data = {outline={color= cc.c4b(52, 77, 113, 255), size = 4}},
		}
	},
	["rightTopPanel.textNote2"] = {
		varname = "textNote2",
		binds = {
			event = "effect",
			data = {outline={color= cc.c4b(52, 77, 113, 255), size = 4}},
		}
	},
	["rightTopPanel.textNote1"] = "textNote1",
	["rightTopPanel.textTime"] = {
		varname = "textTime",
		binds = {
			event = "effect",
			data = {outline={color= cc.c4b(52, 77, 113, 255), size = 4}},
		}
	},
	["rightTopPanel.textNote2"] = "textNote2",
	["rightTopPanel.textTimes"] = {
		varname = "textTimes",
		binds = {
			{
				event = "effect",
				data = {outline={color= cc.c4b(52, 77, 113, 255), size = 4}},
			},
		}
	},
	["rightDownPanel"] = "rightDownPanel",
	["rightDownPanel.btnBuf.textNote"] = {
		binds = {
			event = "effect",
			data = {outline={color= cc.c4b(90, 84, 91, 255), size = 3}},
		}
	},
	["rightDownPanel.btnRule.textNote"] = {
		varname = "ruleNote",
		binds = {
			event = "effect",
			data = {outline={color= cc.c4b(90, 84, 91, 255), size = 3}},
		}
	},
	["rightDownPanel.btnRule"] = {
		varname = "btnRule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRuleClick")}
		}
	},
	["rightDownPanel.btnBuf"] = {
		varname = "btnBuf",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onBtnBufClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "gymBuff",
					listenData = {
						gymDatas = bindHelper.self("gymDatas"),
						round = bindHelper.self("round"),
					},
					onNode = function(node)
						node:xy(120, 135)
					end,
				}
			}
		},
	},
	["rightDownPanel.btnCross"] = {
		varname = "btnCross",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onBtnCrossClick")}
			},
			{
				event = "animation",
				res = "gym/kuafu_btn.skel",
				action = "effect_loop",
				pos = {x = 100, y = 100},
				scale = 2,
				onSpine = function(node)
					node:xy(100, 100)
						:scale(2)
				end
			}
		},
	},
	["rightDownPanel.btnCross.textNote"] = "btnCrossText",
	["rightTopPanel.btnAdd"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddClick")}
		}
	},
	["btnLog.textNote"] = {
		varname = "ruleNote",
		binds = {
			event = "effect",
			data = {outline={color= cc.c4b(90, 84, 91, 255), size = 3}},
		}
	},
	["btnLog"] = {
		varname = "btnLog",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onBtnLogClick")},
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "gymLogs",
					listenData = {
						gymLogs = bindHelper.self("record"),
						lastTime = bindHelper.self("lastTime"),
					},
					onNode = function(node)
						node:xy(180, 180)
					end,
				},
			}
		}
	},
}
function GymChallengeView:onCreate(data, baseView)
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.gymChallenge, subTitle = "The Pavilion Challenge"})
	self.gyms = {}
	self.notCross = idler.new(self._notCross == nil and true or self._notCross)
	self.endTime = 0
	self:initScrollView()
	self:initGyms()
	self:initModel()
	self:addBuildingMoveAction()
	self:moveToGym(self.maxLockID)
	self:refreshOpacity()
	self:initParticle()
end

--例子特效
function GymChallengeView:initParticle()
	local plistFile = "particle/huoxin2.plist"
	local aniFile = "particle/ani_huoxin2.json"
	local particleNode = cc.ParticleSystemQuad:create(plistFile, aniFile)
	particleNode:addTo(self.rightDownPanel)
		:xy(self.btnCross:xy())
		:scale(2)
end

function GymChallengeView:onClose(t)
	if not self.notCross:read() then
		--跨服返回本服
		self.notCross:modify(function(val)
			return true, not val
		end)

		self:getResourceNode():removeChildByName("cloudSpine")
		local cloudSpine = widget.addAnimationByKey(self:getResourceNode(), "gym/kuafu_yun.skel", "cloudSpine", "kuafu_effect", 6)
			:xy(cc.p(display.sizeInView.width/2, display.sizeInView.height/2))
			:scale(2)
	else
		ViewBase.onClose(self)
	end
end

function GymChallengeView:onCleanup()
	self._notCross = self.notCross:read()
	ViewBase.onCleanup(self)
end
-- 初始化滚动容器
function GymChallengeView:initScrollView()
	self.mapScale = MAP_SCALE
	self.scrollView:getInnerContainer():scale(self.mapScale)
	self.scrollView:size(display.sizeInViewRect)
		:xy(display.sizeInViewRect)

	--瓦片地图
	local tmxTileMap = cc.TMXTiledMap:create("city/adventure/gym_challenge/map/map.tmx")
	tmxTileMap:z(1)
	tmxTileMap:scale(2)
	tmxTileMap:setColor(cc.c3b(0,0,0))
	tmxTileMap:addTo(self.scrollView:get("bg"))
end

-- 初始化道馆
function GymChallengeView:initGyms()
	--岛屿
	for i = 1, 9 do
		local cfg = islandCfg[i]
		local spine = widget.addAnimationByKey(self.scrollView:get("bg"), "gym/haidao.skel", "spine"..i, cfg.spine, 6)
			:xy(cfg.pos)
			:scale(cfg.scale)
	end
	--建筑
	for id, cfg in orderCsvPairs(csv.gym.gym) do
		local gym = self.gymItem:clone()
			:addTo(self.scrollView)
			:xy(cfg.pos)
		local spine = widget.addAnimationByKey(gym, "gym/haidao.skel", "spine"..id, cfg.spine,0)
			:xy(cfg.posSkew)
			:scale(2)

		self.gyms[id] = gym
		local gymName = gym:get("imgGymNameBg.textGymName")
		gymName:text(cfg.name)
		local ownerName = gym:get("imgHeadBg.textName")
		text.addEffect(ownerName,  {outline = {color = ui.COLORS.OUTLINE.WHITE, size = 4}})
		gym:color(cc.c3b(128, 128, 128))
		gym:get("imgLocked"):show()
		gym:get("imgComplete"):hide()
		bind.touch(self, gym, {methods = {ended = function()
			self:onGymClick(id)
		end}})

		bind.touch(self, gym:get("imgHeadBg"), {methods = {ended = function()
			if self.notCross:read() == false then
				local owners = self.round:read() == "start" and self.gymCrossOwners:read()[id] or self.lastCrossGymOwners:read()[id]
				if owners and owners[1] then
					local recordId = owners[1].record_id
					gGameApp:requestServer("/game/gym/role/info",function(tb)
						local count = csvSize(csv.gym.gym[id].hardDegreeID)
						local maxDegreeID = csv.gym.gym[id].hardDegreeID[count]
						local unlocked = self.gymsInfo:atproxy(id).unlocked and self.gymDatas:read().gym_fuben[id] > maxDegreeID
						gGameUI:createView("city.adventure.gym_challenge.master_info", self):init(tb.view, id, true, unlocked, 1)
					end, recordId, owners[1].game_key)
				end
			else
				local gymOwners = self.round:read() == "start" and self.gymOwners:read() or self.lastGymOwners:read()
				if gymOwners and gymOwners[id] then
					local recordId = gymOwners[id].record_id
					gGameApp:requestServer("/game/gym/role/info",function(tb)
						local count = csvSize(csv.gym.gym[id].hardDegreeID)
						local maxDegreeID = csv.gym.gym[id].hardDegreeID[count]
						local unlocked = self.gymsInfo:atproxy(id).unlocked and self.gymDatas:read().gym_fuben[id] > maxDegreeID
						gGameUI:createView("city.adventure.gym_challenge.master_info", self):init(tb.view, id, false, unlocked)
					end, recordId)
				else
					gGameUI:createView("city.adventure.gym_challenge.npc_info", self):init(id)
				end
			end
		end}})
		bind.extend(self, gymName, {
			class = "red_hint",
			props = {
				specialTag = "gymAward",
				state = self.notCross,
				listenData = {
					gymDatas = bindHelper.self("gymDatas"),
					id = id
				},
				onNode = function(node)
					node:xy(400, 110)
				end,
			},
		})
	end
end

local function setOpacity(widget, opacity)
	widget:setOpacity(opacity)
	for _, widget in pairs(widget:getChildren()) do
		setOpacity(widget, opacity)
	end
end

function GymChallengeView:refreshOpacity( )
	local scrollViewPos = self.scrollView:getInnerContainerPosition()
	local width = self.scrollView:width() - 300
	local height = self.scrollView:height() - 300
	local cx = width / 2
	local cy = height / 2
	for id, gym in ipairs(self.gyms) do
		local gymX, gymY = gym:x(),  gym:y()
		local x, y = scrollViewPos.x + gymX * self.mapScale - 300/2 , scrollViewPos.y + gymY * self.mapScale - 300/2
		local diff = 0 --超出屏幕距离
		if math.abs(x - cx) > cx or math.abs(y - cy) > cy then
			-- 中心点不在屏幕内
			diff = math.max(math.abs(x - cx) - cx, math.abs(y - cy) - cy)
		end
		local opacity = math.max(255*0.3, 255 * (1 - math.min(1, diff/ 300)))
		setOpacity(gym, opacity)
	end

	for i = 1, 9 do
		local img = self.scrollView:get("bg.spine"..i)
		local imgX, imgY = img:x(), img:y()
		local x, y = scrollViewPos.x + imgX * self.mapScale - 300/2, scrollViewPos.y + imgY * self.mapScale -300/2
		local diff = 0 --超出屏幕距离
		if math.abs(x - cx) > cx or math.abs(y - cy) > cy then
			-- 中心点不在屏幕内
			diff = math.max(math.abs(x - cx) - cx, math.abs(y - cy) - cy)
		end
		local opacity = math.max(255*0.3, 255 * (1 - math.min(1, diff/ 300)))
		setOpacity(img, opacity)
	end
end

function GymChallengeView:addBuildingMoveAction()
	local dirty = true
	self.scrollView:onEvent(function(event)
		if event.name == "CONTAINER_MOVED" then
			dirty = true
		end
	end)
	schedule(self.scrollView, function()
		if dirty then
			self:refreshOpacity()
			dirty = false
		end
	end, 0.1)
end

--刷新道馆
function GymChallengeView:updateGym(index, info)
	local function setColor(widget, color)
		widget:setColor(color)
		for _, widget in pairs(widget:getChildren()) do
			setColor(widget, color)
		end
	end
	local gym = self.gyms[index]
	local preId = csv.gym.gym[index].preGymID or 0
	if info.completed == true then
		setColor(gym:get("spine"..index), cc.c3b(255,255,255))
		gym:color(cc.c3b(255, 255, 255))
		gym:get("imgComplete"):show()
		gym:get("imgLocked"):hide()
	elseif info.unlocked == true then
		setColor(gym:get("spine"..index), cc.c3b(255,255,255))
		gym:color(cc.c3b(255, 255, 255))
		gym:get("imgComplete"):hide()
		gym:get("imgLocked"):hide()
	else
		setColor(gym:get("spine"..index), cc.c3b(128,128,128))
		gym:get("imgLocked"):show()
		gym:get("imgComplete"):hide()
	end
end

--刷新道馆
function GymChallengeView:updateGymOwner(index, info, isNpc)
	local imgHeadBg = self.gyms[index]:get("imgHeadBg")
	if info == nil then
		imgHeadBg:hide()
	else
		if isNpc then
			imgHeadBg:get("imgOwner"):texture("city/adventure/gym_challenge/map/txt_gz.png")
		else
			imgHeadBg:get("imgOwner"):texture("city/adventure/gym_challenge/map/txt_rygz.png")
		end
		imgHeadBg:show()
		imgHeadBg:get("textName"):text(info.name)
		local head = bind.extend(self, imgHeadBg, {
			event = "extend",
			class = "role_logo",
			props = {
				logoId = info.logo,
				frameId = false,
				level = false,
				vip = false,
				onNode = function(node)
					if isNpc then
						local npcID = csv.gym.gym[index].npcID
						local npcCfg = csv.gym.npc[npcID]
						local logo = csv.role_figure[npcCfg.figure].logo
						node:get("logoClipping.logo"):texture(logo)
					end
					node:scale(1.22)
				end
			},
		})
	end
end

function GymChallengeView:initModel()
	self.gymDatas = gGameModel.role:getIdler("gym_datas")
	self.gymOwners = gGameModel.gym:getIdler("leaderRoles")
	self.lastGymOwners = gGameModel.gym:getIdler("lastLeaderRoles")
	self.starDate = gGameModel.gym:read("date")
	self.round = gGameModel.gym:getIdler("round")
	self.gymCrossOwners = gGameModel.gym:getIdler("crossGymRoles")
	self.lastCrossGymOwners = gGameModel.gym:getIdler("lastCrossGymRoles")
	self.curIndex = idler.new(0) --当前挑战的道馆
	self.gymsInfo = idlers.newWithMap({{},{},{},{},{},{},{},{}}) --道馆信息(解锁 通关)
	self.buyTimes = gGameModel.daily_record:getIdler("gym_battle_buy_times")
	self.record = gGameModel.gym:getIdler("record")
	local lastTime = userDefault.getForeverLocalKey("gymLogOpenTime", 0)
	self.lastTime = idler.new(lastTime)

	idlereasy.when(self.round, function(_,round)
		self:initCountDown()
	end)
	--道馆信息
	idlereasy.when(self.gymDatas, function(_, gymDatas)
		self.maxLockID = 1
		self.maxCrossLockID = 1
		for id, diff in pairs(gymDatas.gym_fuben or {}) do
			self.gymsInfo:atproxy(id).unlocked = true
			local count = csvSize(csv.gym.gym[id].hardDegreeID)
			local maxDegreeID = csv.gym.gym[id].hardDegreeID[count]
			if diff > maxDegreeID then
				self.gymsInfo:atproxy(id).completed = true
				self.maxCrossLockID = math.max(self.maxLockID, id)
				for i, cfg in orderCsvPairs(csv.gym.gym) do
					if cfg.preGymID == id then
						self.gymsInfo:atproxy(i).unlocked = true
					end
				end
			end
			self.maxLockID = math.max(self.maxLockID, id)
		end
	end)
	idlereasy.any({self.gymsInfo, self.notCross}, function(_, gymsInfo, notCross)
		for id, info in ipairs(gymsInfo) do
			if notCross then
				self:updateGym(id, info:read())
			else
				self:updateGym(id, {unlocked = info:read().completed, completed = false})
			end
			local lastCrossGymRoles = gGameModel.gym:read("lastCrossGymRoles")
			local day = csv.cross.gym.base[1].servOpenDays
			local openTime = self:getOpenTime()
			self.btnCross:get("imgLock"):setVisible(notCross and gGameModel.gym:read("crossKey") == "" and itertools.size(lastCrossGymRoles) == 0 or time.getTime() < openTime)
		end
	end)

	idlereasy.any({self.gymOwners,self.gymCrossOwners, self.notCross, self.round}, function(_, _gymOwners, _gymCrossOwners, notCross, round)
		local gymCrossOwners, gymOwners
		if round == "start" then
			gymCrossOwners = _gymCrossOwners or {}
			gymOwners = _gymOwners or {}
		else
			gymCrossOwners = self.lastCrossGymOwners:read() or {}
			gymOwners = self.lastGymOwners:read() or {}
		end
		for id = 1, 8 do
			if notCross then
				if gymOwners[id] then
					self:updateGymOwner(id, gymOwners[id], false)
				else
					local npcID = csv.gym.gym[id].npcID
					local npcCfg = csv.gym.npc[npcID]
					local figureCfg = csv.role_figure[npcCfg.figure]
					local info = {name = figureCfg.name, logo = npcCfg.figure}
					self:updateGymOwner(id, info, true)
				end
			else
				if gymCrossOwners[id] then
					self:updateGymOwner(id, gymCrossOwners[id][1], false)
				else
					self:updateGymOwner(id, nil, false)
				end
			end
		end
	end)
	self.first = true -- 第一次 不播放动画
	self.notCross:addListener(function (val, oldval)
		local id = 1
		local oldScale = self.mapScale
		if not val then
			local fontScale = matchLanguage({"kr"}) and 1 or 0.8
			self.mapScale = CROSS_MAP_SCALE
			self.btnCrossText:text(gLanguageCsv.gymReturn)
				:scale(fontScale)
			id = self.maxCrossLockID
		else
			self.mapScale = MAP_SCALE
			self.btnCrossText:text(gLanguageCsv.gymCross)
				:scale(1)
			id = self.maxLockID
		end
		local function updateUI()
			self:moveToGym(id)
			self:refreshOpacity()
			if not val then
				self.scrollView:get("bg"):texture("city/adventure/gym_challenge/map/bg_kf_0.png")
				for id, cfg in orderCsvPairs(csv.gym.gym) do
					local nameBg = self.gyms[id]:get("imgGymNameBg")
					nameBg:texture("city/adventure/gym_challenge/map/box_dgmc_kf.png")
					local gymName = self.gyms[id]:get("imgGymNameBg.textGymName")
					if matchLanguage({"kr"}) then gymName:setFontSize(50) end
					gymName:text(gLanguageCsv.crossServer..cfg.name)
				end
			else
				self.scrollView:get("bg"):texture("city/adventure/gym_challenge/map/bg_0.png")
				for id, cfg in orderCsvPairs(csv.gym.gym) do
					local nameBg = self.gyms[id]:get("imgGymNameBg")
					nameBg:texture("city/adventure/gym_challenge/map/box_dgmc.png")
					local gymName = self.gyms[id]:get("imgGymNameBg.textGymName")
					gymName:text(cfg.name)
				end
			end
			if val == false then
				self.btnBuf:hide()
				self.btnRule:xy(394, 155)
				self.ruleNote:text(gLanguageCsv.crossRule)
			else
				self.btnBuf:show()
				self.btnRule:xy(207, 155)
				self.ruleNote:text(gLanguageCsv.spaceRule)
			end

		end
		if self.first == true then
			self.scrollView:getInnerContainer():scale(self.mapScale)
			updateUI()
		else
			local scrollViewSize = self.scrollView:size()
			local containerSize = self.scrollView:getInnerContainerSize()
			local pos = self.scrollView:getInnerContainerPosition()
			--屏幕中心点对应的坐标
			local centerPosX = (scrollViewSize.width/2 - pos.x) / oldScale
			local centerPosY = (scrollViewSize.height/2 - pos.y) / oldScale

			local x, y = scrollViewSize.width / 2 - centerPosX * self.mapScale , scrollViewSize.height / 2 - centerPosY * self.mapScale
			x = math.min(0, x)
			y = math.min(0, y)
			x = math.max( - self.scrollView:getInnerContainerSize().width * self.mapScale + scrollViewSize.width, x)
			y = math.max( - self.scrollView:getInnerContainerSize().height * self.mapScale + scrollViewSize.height, y)

			local ationScale = cc.ScaleTo:create(1, self.mapScale)
			local ationMove = cc.MoveTo:create(1, {x = x, y = y})
			self.scrollView:getInnerContainer():stopAllActions()
			self.scrollView:getInnerContainer():runAction(cc.Sequence:create(cc.Spawn:create(ationScale, ationMove) , cc.CallFunc:create(function()
				updateUI()
			end)))
		end
		self.first = false
	end)

	--剩余挑战次数
	idlereasy.any({gGameModel.daily_record:getIdler("gym_battle_times"), self.buyTimes}, function(_,  times, buyTimes)
		self.textTimes:text(math.max(gCommonConfigCsv.gymBattleTimes - times + buyTimes, 0)  .. gLanguageCsv.times)
	end)
end

function GymChallengeView:moveToGym(id)
	local gym = self.gyms[id]
	local scrollViewSize = self.scrollView:size()
	local gymX, gymY = gym:x(), gym:y()
	local x, y = scrollViewSize.width / 2 - gymX * self.mapScale , scrollViewSize.height / 2 - gymY * self.mapScale
	x = math.min(0, x)
	y = math.min(0, y)
	x = math.max( - self.scrollView:getInnerContainerSize().width * self.mapScale + scrollViewSize.width, x)
	y = math.max( - self.scrollView:getInnerContainerSize().height * self.mapScale + scrollViewSize.height, y)
	self.scrollView:setInnerContainerPosition(cc.p(x, y))
end

-- 检测是否在可挑战时段内
function GymChallengeView:getCountDownState()
	if self.round:read() == "closed" then
		local hour = time.getTimeTable().hour
		if tonumber(hour) >=5 and tonumber(hour) < 10 then
			return STATE.WAIT_STAR
		else
			return STATE.ENDED
		end
	elseif self.round:read() == "start" then
		self.endTime = time.getNumTimestamp(self.starDate, 21, 45) + 6 * 24 * 3600
		return STATE.GAMING
	end
end

--倒计时
function GymChallengeView:initCountDown()
	if self:getCountDownState() ~= STATE.GAMING then
		self.textTime:text("")
		self.textTimes:text(""):hide()
		self.textNote2:text("")
		self.btnAdd:hide()
		text.deleteEffect(self.textNote1, "all")
		text.deleteEffect(self.textNote2, "all")
		if self:getCountDownState() == STATE.ENDED then
			self.textNote1:text(gLanguageCsv.gymEnd)
		else
			self.textNote1:text(gLanguageCsv.gymWaitBegin)
		end
		self.textNote1:color(ui.COLORS.NORMAL.ALERT_YELLOW)
		self.textNote1:y(self.textNote1:y()/2 +self.textNote2:y()/2)
		adapt.oneLinePos(self.textTime, self.textNote1,cc.p(-50,0), "right")
		return
	else
		self.textTimes:show()
		self.btnAdd:show()
	end
	local function setLabel()
		if self.endTime - time.getTime() < 0 then
			performWithDelay(self,function()
				gGameApp:requestServer("/game/gym/main", function(tb)
						end)
			end, 10) --冗余10s 发送请求 更新状态
			self:unSchedule(1)
			return false
		end
		local remainTime = time.getCutDown(self.endTime - time.getTime())
		self.textTime:text(remainTime.str)
		adapt.oneLinePos(self.textTime, self.textNote1,cc.p(5,0), "right")
		return true
	end
	self:enableSchedule()
	setLabel()
	self:schedule(function(dt)
		if not setLabel() then
			return false
		end
	end, 1, 0, 1)

	--每周一5点更新界面
	--道馆特殊，kr也是5点刷新
	local endTime = time.getNumTimestamp(time.getWeekStrInClock(0), 5)
	if endTime <= time.getTime() then
		endTime = endTime + 7 * 24 * 3600
	end
	self:schedule(function(dt)
		if (time.getTime() > endTime + 10) and gGameModel.role:read("gym_record_db_id") then
			gGameApp:requestServer("/game/gym/main", function(tb) end)
			self:unSchedule(2)
			return false
		end
	end, 1, 0, 2)
end

function GymChallengeView:getOpenTime()
	-- 判断到达date日期时，当前服是否满足开服天数
	local servOpenDays = csv.cross.gym.base[1].servOpenDays - 1
	local openStamps = game.SERVER_OPENTIME + servOpenDays * 24 * 3600
	local d = time.getDate(openStamps)
	local wday = d.wday == 1 and 7 or d.wday - 1 -- Sunday is 1
	local openTime = 0
	if wday == 1 and d.hour < time.getRefreshHour() then
		--周一五点以前这周开启
		openTime = openStamps - (d.hour * 3600 + d.min *60 + d.sec) + 5 * 3600
	else
		--下周一五点时间戳
		openTime = openStamps + (8 - wday) * 24 * 3600 - (d.hour * 3600 + d.min *60 + d.sec) + 5 * 3600
	end
	return openTime
end
-- 跨服按钮
function GymChallengeView:onBtnCrossClick()
	local openTime = self:getOpenTime()
	if time.getTime() < openTime then
		gGameUI:showTip(string.format(gLanguageCsv.crossGymDayTips, csv.cross.gym.base[1].servOpenDays))
		return
	end
	if self.notCross:read() == true then
		local lastCrossGymRoles = gGameModel.gym:read("lastCrossGymRoles")
		if gGameModel.gym:read("crossKey") == "" and itertools.size(lastCrossGymRoles) == 0 then
			gGameUI:showTip(gLanguageCsv.crossGymNotOpen)
			return
		end
	end
	self.notCross:modify(function(val)
		return true, not val
	end)

	self:getResourceNode():removeChildByName("cloudSpine")
	local cloudSpine = widget.addAnimationByKey(self:getResourceNode(), "gym/kuafu_yun.skel", "cloudSpine", "kuafu_effect", 6)
		:xy(cc.p(display.sizeInView.width/2, display.sizeInView.height/2))
		:scale(2)
end

-- 挑战加成按钮
function GymChallengeView:onBtnBufClick()
	if self.round:read() == "start" then
		gGameUI:stackUI("city.adventure.gym_challenge.buff", nil, {full = true})
	else
		gGameUI:showTip(gLanguageCsv.gymEndTips)
	end
end

function GymChallengeView:onGymClick(id)
	if not self.notCross:read() then
		local lastCrossGymRoles = gGameModel.gym:read("lastCrossGymRoles")
		if gGameModel.gym:read("crossKey") == "" and itertools.size(lastCrossGymRoles) == 0 then
			gGameUI:showTip(gLanguageCsv.crossGymNotOpen)
			return
		end

		if self.gymsInfo:atproxy(id).completed == true then
			gGameUI:stackUI("city.adventure.gym_challenge.cross_gate", nil, {full = true}, id, self.gymsInfo:atproxy(id).completed)
		else
			gGameUI:showTip(gLanguageCsv.gymCrossTips1)
		end
	else
		if self.gymsInfo:atproxy(id).unlocked == true then
			gGameUI:stackUI("city.adventure.gym_challenge.gate", nil, {full = true}, id)
		else
			local preId = csv.gym.gym[id].preGymID
			if preId then
				gGameUI:showTip(string.format(gLanguageCsv.gymNotUnlock, csv.gym.gym[preId].name))
			end
		end
	end
end

-- 规则
function GymChallengeView:onBtnRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function GymChallengeView:getRuleContext(view)
	local c = adaptContext
	if self.notCross:read() then
		local context = {
			c.clone(view.title, function(item)
				item:get("text"):text(gLanguageCsv.rules)
			end),
			c.noteText(102001, 102100),
		}
		for k, v in orderCsvPairs(csv.gym.gym) do
			table.insert(context, c.clone(view.awardItem, function(item)
				local childs = item:multiget("text", "list")
				childs.text:text("")
				rich.createByStr("#C0x5b545b#" .. v.leaderAwardDesc, 40)
					:anchorPoint(1, 0.5)
					:xy(250, 100)
					:addTo(childs.text, 6)
				uiEasy.createItemsToList(view, childs.list, v.leaderAward)
			end))
		end
		return context
	else
		local context = {
			c.clone(view.title, function(item)
				item:get("text"):text(gLanguageCsv.rules)
			end),
			c.noteText(103001, 103100),
		}
		if gGameModel.gym:read("round") == "start" then
			local servers = gGameModel.gym:read("servers")
			if servers then
				local t = arraytools.map(getMergeServers(servers), function(k, v)
					return string.format(gLanguageCsv.brackets, getServerArea(v, nil, true))
				end)
				table.insert(context, 2, "#C0x5B545B#" .. gLanguageCsv.currentServers .. table.concat(t, ","))
			end
		end

		for k, v in orderCsvPairs(csv.gym.gym) do
			table.insert(context, c.clone(view.awardItem, function(item)
				local childs = item:multiget("text", "list")
				childs.text:text("")
				rich.createByStr("#C0x5b545b#" .. v.crossLeaderAwardDesc, 40)
					:anchorPoint(1, 0.5)
					:xy(260, 100)
					:addTo(childs.text, 6)
				uiEasy.createItemsToList(view, childs.list, v.crossLeaderAward)
			end))

			table.insert(context, c.clone(view.awardItem, function(item)
				local childs = item:multiget("text", "list")
				childs.text:text("")
				rich.createByStr("#C0x5b545b#" .. v.crossSubAwardDesc, 40)
					:anchorPoint(1, 0.5)
					:xy(260, 100)
					:addTo(childs.text, 6)
				uiEasy.createItemsToList(view, childs.list, v.crossSubAward)
			end))
		end

		return context
	end
end

function GymChallengeView:onAddClick( )
	local costCft = gCostCsv.gym_battle_buy_cost
	local times = math.min(self.buyTimes:read() + 1, csvSize(gCostCsv.gym_talent_point_buy_cost))
	local cost = costCft[times]
	if self.buyTimes:read() >= gVipCsv[gGameModel.role:read("vip_level")].gymBattleBuyTimes then
		gGameUI:showTip(gLanguageCsv.cardCapacityBuyMax)
		return
	end
	local str = string.format(gLanguageCsv.gymBattleTimesBuy, cost)
	gGameUI:showDialog({strs = {str}, isRich = true, cb = function ()
		if gGameModel.role:read("rmb") >= cost then
			gGameApp:requestServer("/game/gym/battle/buy",function (tb)
				gGameUI:showTip(gLanguageCsv.buySuccess)
			end)
		else
			uiEasy.showDialog("rmb")
		end
	end,
	btnType = 2 ,dialogParams = {clickClose = false}, clearFast = true})
end

-- 日志
function GymChallengeView:onBtnLogClick()
	gGameApp:requestServer("/game/gym/main", function(tb)
		gGameUI:stackUI("city.adventure.gym_challenge.log", nil, {full = true})
		local curTime = time.getTime()
		self.lastTime:set(curTime)
		userDefault.setForeverLocalKey("gymLogOpenTime", curTime)
	end)
end

return GymChallengeView
