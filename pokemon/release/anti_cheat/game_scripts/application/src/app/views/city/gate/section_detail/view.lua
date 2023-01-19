local ViewBase = cc.load("mvc").ViewBase
local GateSectionDetailView = class("GateSectionDetailView", Dialog)

local BOTTOM_VIEW_LIST = {
	[1] = "city.gate.section_detail.normal",
	[2] = "city.gate.section_detail.hard",
	[3] = "city.gate.section_detail.nightmare",
}

local CHAPTER_NUM = {
	[1] = 10,
	[2] = 110,
	[3] = 210,
}

GateSectionDetailView.RESOURCE_FILENAME = "gate_section_detail.json"
GateSectionDetailView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["title.textGate"] = "titleNum",
	["title.textGateName"] = "titleName",
	["leftTop.textDesc"] = "textDesc",

	["leftTop.btnSave.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["leftTop.lockPanel"] = "lockPanel",
	["starItem"] = "starItem",
	["rightTop.starList"] = {
		varname = "starList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("starDatas"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("star1"):visible(not v.enabled)
					node:get("star2"):visible(v.enabled)
				end,
				asyncPreload = 5,
			}
		},
	},
	["itemText"] = "itemText",
	["rightTop.list"] = {
		varname = "conditionList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("conditionDatas"),
				item = bindHelper.self("itemText"),
				onItem = function(list, node, k, v)
					node:get("textNote"):text(string.format(k..". "..gLanguageCsv["starCondition"..v.key], v.value))
				end,
				asyncPreload = 5,
			}
		},
	},
	["roleItem"] = "roleItem",
	["rightTop.enemyList"] = {
		varname = "battleList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("monsterDatas"),
				item = bindHelper.self("roleItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							rarity = v.rarity,
							advance = v.advance,
							isBoss = v.isBoss,
							showAttribute = true,
							levelProps = {
								data = v.level,
							},
							onNode = function(panel)
								local x, y = panel:xy()
								panel:scale(1.1)
								node:scale(v.isBoss and 1 or 0.9)
							end,
						}
					})
				end,
				asyncPreload = 6,
			}
		},
	},
	["leftTop.roleNode"] = "cardIcon",
	["bottomPanel"] = "bottomPanel",
}

function GateSectionDetailView:onCreate(gateId, pageId)
	self:initModel()
	self.gateId = gateId or 101
	self.pageId = pageId

	self:initTopView()
	self:initRightTop()
	self:initLeftTop()
	self:initBottomView()
	self:isPreGatePass()

	Dialog.onCreate(self)
end

function GateSectionDetailView:isPreGatePass()
	local csvSceneConf = csv.scene_conf
	local sceneCsv = csv.scene_conf[self.gateId]
	local preGateId = sceneCsv.preGateID
	if preGateId then
		local gateStar = gGameModel.role:read("gate_star")
		if not gateStar[preGateId] then
			local preSceneCsv = csv.scene_conf[preGateId]
			local worldCsv = csv.world_map[preSceneCsv.ownerId]
			self.bottomView:setBtnFalse()
			self.lockPanel:show()
			local strs = {
				[1] = gLanguageCsv.gateStory,
				[2] = gLanguageCsv.gateDifficult,
				[3] = gLanguageCsv.gateNightMare,
			}

			local gateStr = preSceneCsv.ownerId - CHAPTER_NUM[worldCsv.chapterType]

			local tmpGateId = 0
			for k,v in pairs(worldCsv.seq) do
				if preGateId == v then
					tmpGateId = k
					break
				end
			end
			gateStr = gateStr.."-"..tmpGateId

			self.lockPanel:get("text"):text(string.format(gLanguageCsv.pleasePassGate, strs[worldCsv.chapterType], gateStr))
		end
	end
end

function GateSectionDetailView:initModel()
	self.gate_star = gGameModel.role:getIdler("gate_star") -- 星星数量
	self.roleLv = gGameModel.role:getIdler("level")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.stamina = gGameModel.role:getIdler("stamina")
	self.buyHerogateTimes = gGameModel.daily_record:getIdler("buy_herogate_times")
	self.gateTimes = gGameModel.daily_record:getIdler("gate_times")
end

function GateSectionDetailView:initTopView()
	local sceneCsv = csv.scene_conf[self.gateId]
	local worldCsv = csv.world_map[sceneCsv.ownerId]
	local tmpGateId = 0
	for k,v in pairs(worldCsv.seq) do
		if self.gateId == v then
			tmpGateId = k
			break
		end
	end
	self.titleNum:text(self.pageId.."-"..tmpGateId)
	self.titleName:text(sceneCsv.sceneName)
	adapt.oneLinePos(self.titleNum, self.titleName, cc.p(18, 0), "left")
end

function GateSectionDetailView:initLeftTop()
	local sceneCsv = csv.scene_conf[self.gateId]
	local size = self.cardIcon:size()
	ccui.ImageView:create(sceneCsv.bg_boss)
		:align(cc.p(0.5, 0.5), size.width/2+sceneCsv.bg_boss_pos.x, size.height+sceneCsv.bg_boss_pos.y + 70)
		:scale(1.5)
		:addTo(self.cardIcon, 5,"icon")

	beauty.textScroll({
		list = self.textDesc,
		strs = sceneCsv.desc,
		align = "center",
	})

	local childHeight = 0
	for i,child in ipairs(self.textDesc:getChildren()) do
		childHeight = childHeight + child:size().height
	end
	local listHeight = self.textDesc:size().height
	if listHeight > childHeight then
		local y = - listHeight/2 + childHeight/2
		self.textDesc:y(y)
	end
end

function GateSectionDetailView:initBottomView()
	local sceneCsv = csv.scene_conf[self.gateId]
	local worldCsv = csv.world_map[sceneCsv.ownerId]

	self.chapterType = worldCsv.chapterType
	local viewName = BOTTOM_VIEW_LIST[self.chapterType]

	self.bottomView = gGameUI:createView(viewName, self.bottomPanel):init(self.gateId, self.pageId, self:createHandler("startFighting")):z(999)
end

function GateSectionDetailView:initRightTop()
	local sceneCsv = csv.scene_conf[self.gateId]
	local worldCsv = csv.world_map[sceneCsv.ownerId]

	local function getCfgData(cfg, isBoss)
		local data = {}
		for _, v in ipairs(cfg) do
			local unitCfg = csv.unit[v.unitId]
			table.insert(data, {
				unitId = v.unitId,
				level = v.level,
				advance = v.advance,
				rarity = unitCfg.rarity,
				attr1 = unitCfg.natureType,
				attr2 = unitCfg.natureType2,
				isBoss = isBoss,
			})
		end
		table.sort(data, function(a,b)
			return a.advance > b.advance
		end )
		return data
	end
	local bossDatas = getCfgData(sceneCsv.boss, true)
	local monsterDatas = getCfgData(sceneCsv.monsters, false)
	self.monsterDatas = arraytools.merge({bossDatas, monsterDatas})

	local size = self.cardIcon:size()
	ccui.ImageView:create(sceneCsv.bg_boss)
		:align(cc.p(0.5, 0.5), size.width/2+sceneCsv.bg_boss_pos.x, size.height+sceneCsv.bg_boss_pos.y + 70)
		:scale(1.5)
		:addTo(self.cardIcon, 5,"icon")

	local conditionDatas = {}
	for _,v in csvPairs(sceneCsv.stars) do
		table.insert(conditionDatas,v)
	end
	self.conditionDatas = conditionDatas

	self.starDatas = idlertable.new()
	idlereasy.when(self.gate_star,function(_,star)
		local starDatas = {}
		local starNum = star[self.gateId] and self.gate_star:read()[self.gateId].star or 0
		local maxStar = 3
		for i=1,maxStar do
			table.insert(starDatas,{enabled = (i <= starNum)})
		end
		self.starDatas:set(starDatas)
		-- self.sweepOpen = starNum >= maxStar		-- 只有星星够了才能扫荡
	end)
end

--battleCards 当前阵容
function GateSectionDetailView:startFighting(view)
	local gateId = self.gateId
	local sectionId = self.pageId or 1
	-- -- 2.正常的开始战斗 跳过布阵
	battleEntrance.battleRequest("/game/start_gate", gateId)
		:onStartOK(function(data)
			if self.chapterType == 3 then
				-- todo 噩梦关卡有专有的阵容
				local huodongCards = gGameModel.role:read("huodong_cards")
				data.battleCards = huodongCards[game.EMBATTLE_HOUDONG_ID.nightmare] or gGameModel.role:read("battle_cards")
			end
			gGameUI:goBackInStackUI("city.gate.view")
		end)
		:onResult(function(data, results)
			local n = 0
			if results.result == "win" and results.gateStar then
				n = math.max(results.gateStar-(data.preData.dungeonStar or 0), 0)
			end
			userDefault.setForeverLocalKey("gateAddStarNum", {
				gateId = data.sceneID,
				starAdd = n,
				sectionId = sectionId
			})
		end)
		:show()
end


return GateSectionDetailView
