local __TestDefine = require "app.views.city.test.test_define"
local __TestEasy = require "app.views.city.test.test_easy"
local __TestProtocol = require "app.views.city.test.test_protocol"

local _msgpack = require '3rd.msgpack'
local msgpack = _msgpack.pack
local msgunpack = _msgpack.unpack

local fs = require "editor.fs"
local Prefab = require "app.views.city.test.model.prefab"
local EasyView = require "app.views.city.test.easy_view"
local MultiForce = require "app.views.city.test.multi_force"

require "battle.app_views.battle.battle_entrance.include"

local csvUnits = csv.unit
local csvCards = csv.cards

local csvTestBattle1 = csvClone(csv.test_battle)
csvTestBattle1 = csvTestBattle1[1] or {}

local function readAndUnpack(filename)
	print('load', filename)
	local fp = io.open(filename, 'rb')
	local data = fp:read('*a')
	fp:close()
	return msgunpack(data)
end

local function removeInternalTable(t)
	--data读出来会加上__raw和__proxy 这里修下型
	local ret = {}
	for k,v in pairs(t) do
		local hasRaw = false
		local newTb = {}
		if type(v) == "table" then
			for k2,v2 in pairs(v) do
				if k2 == "__raw" then
					hasRaw = true
					for k3,v3 in pairs(v2) do
						if type(v3) == "table" then
							newTb[k3] = removeInternalTable(v3)
						else
							newTb[k3] = v3
						end
					end
				end
			end
		end

		if not hasRaw then
			ret[k] = v
		else
			ret[k] = newTb
		end
	end
	print("###########")
	print_r(ret)
	return ret
end

local function getMultiTeamRoleOutStr(roleOutStr, roleOut, group)
	for i=1,2 do
		if i == 2 then roleOutStr = roleOutStr .. "\tvs\t" end
		for j=1,group do
			roleOutStr = string.format("%s team%d",roleOutStr, j)
			for k=1,12 do
				if roleOut[i][j][k] then
					roleOutStr = string.format("%s %s(%d)",roleOutStr,csv.unit[roleOut[i][j][k].roleId].name,k)
				end
			end
		end
	end
	return roleOutStr
end

---[[ ---------------------------- 配置 ----------------------------
local FightType = {
	Normal = 1,
	OneByOne = 2,
	Chaos = 3,
	Craft = 4,
	CrossArena = 5,
	CrossMine = 6,
	BraveChallenge = 7,
	Pve = 8
}
local FightTypeStr = {"阵容模式","单挑模式","大乱斗模式","竞技场模式","跨服竞技场","跨服商业街","勇者挑战","PVE模式"}

local BtnConfigList = {
	"btnManual|返回主界面",
	"btnFightTest|战斗测试",
	"btnFightView|战斗界面",
	"btnLoadRecord|加载战报",
	"btnBattleMonitor|战斗监控(关闭)",
	"btnShowHistory|战斗记录",
	"btnAddPrefab|添加精灵",
	"btnCleanTeam|清除布阵",
	"btnFullMp|满蓝",
	"btnAttrAdd|属性加成(开启)",
	"btnCloseRandFix|伤害波动(开启)",
	"btnRecordLog|战报Log导出",
	"btnMultiForce|多阵容战斗",
	"btnSyncFight|同步测试",
	--"btnUdpTest|远程测试",
	"btnRandSeedSwitch|随机种子(关闭)",
	"btnExchangeSeat|交换位置",
	"btnSameSpeedRandFix|同速度随机(关闭)",
}

local NeedShowAttr = {
	hp = true,
	mp1 = true,
	damage = true,
	specialDamage = true,
	defence = true,
	specialDefence = true,
	defenceIgnore = true,
	dodge = true,
	speed = true,
	strike = true,
	strikeDamage = true,
	strikeResistance = true,
	block = true,
	breakBlock = true,
	blockPower = true,
	damageAdd = true,
	damageSub = true,
	suckBlood = true,
	rebound = true,
	cure = true,
	star = true,
	fightPoint = true,
	controlPer = true,
}
-- 属性默认显示的值
local DefaultAttr = {
	star = 5,
	classify = 0,
	level = 1,
	hp = 100000,
	mp1 = 1000,
	mp2 = 1,
	hpRecover = 1,
	mp1Recover = 1,
	mp2Recover = 1,
	damage = 10000,
	specialDamage = 10000,
	defence = 3000,
	specialDefence = 3000,
	defenceIgnore = 1,
	specialDefenceIgnore = 1,
	speed = 14,
	strike = 1,
	strikeDamage = 15000,
	strikeResistance = 1,
	block = 1,
	breakBlock = 1,
	blockPower = 1,
	dodge = 1,
	hit = 10000,
	damageAdd = 1,
	damageSub = 1,
	ultimateAdd = 0,
	ultimateSub = 0,
	damageDeepen = 1,
	damageReduce = 1,
	suckBlood = 0,
	rebound = 0,
	cure = 1,
	natureRestraint = 1,
	gatePer = 1,
	immuneGate = 1,
	skills = {},
	passive_skills = {},
	fightPoint = 0,
	controlPer = 0,
}

local defaultRoleAttr = {
	star = 1,
	level = 1,
	breake_through = 1,
	skill_level = 1,
	potential = 1,
	efforts = 1,
	individual = 1,
	feel_level = 1,
	decorations_level = 1,
	decorations_star = 1,
	decorations_awake_level = 1,
	get_all_runes = 0,
	get_all_titles = 0,
	get_all_limit_attribute = 0,
	character = 0
}

local defaultForceAttr = {
	talents = 0,
	handbook = 0,
	device = 0
}

local seatMap = {4,5,6,1,2,3}
local pveGateType = {
	[1] = true,
	[3] = true,
	[4] = true,
	[5] = true,
	[6] = true,
	[7] = true,
	[8] = true,
	[15] = true,
	[16] = true,
	[18] = true
}
--]] ------------------------------ End -------------------------------


local TestChooseCardView = class("TestChooseCardView", cc.load("mvc").ViewBase)

TestChooseCardView.RESOURCE_FILENAME = "test_choose_card.json"
TestChooseCardView.RESOURCE_BINDING = {
	["stage"] = "stage",
	["stage.gameObjectView"] = "gameObjects",
	["stage.gameObject"] = "gameObject",
	["stage.prefabView"] = "prefabs",
	["stage.prefab"] = "prefab",
	["stage.forcePanel"] = "forcePanel",
	["stage.btnFightTypeSwitch"] = {
		varname = "btnFightTypeSwitch",
		binds = {
			event = "click",
			method = bindHelper.self("onBtnFightTypeSwitch"),
		},
	},
	["stage.btnFightTypeSwitch.label"] = "btnFightTypeSwitchLabel",
	["stage.fightTypeList"] = "fightTypeList",
	["stage.btnList"] = "btnList",
	["stage.btnItem"] = "btnItem",
	["stage.attrView"] = "attrView",
	["stage.recordView"] = "recordView",
	["stage.attrItem"] = "attrItem",
	["stage.panelSceneID"] = "panelSceneID",
	["stage.panelSceneID.btnGateType"] = "btnGateType",
	["stage.panelSceneID.gateTypeList"] = "gateTypeList",
	["stage.panelSceneID.textSceneID"] = "textSceneID",
	["stage.panelLeftAttrAdd"] = "panelLeftAttrAdd",
	["stage.panelRightAttrAdd"] = "panelRightAttrAdd",
	["stage.panelLeftAttrAdd.inputAttr"] = "leftInputAttr",
	["stage.panelRightAttrAdd.inputAttr"] = "rightInputAttr"
}

TestChooseCardView.RESOURCE_STYLES = {
	full = true,
}


--目录
--[[
   配置
   按钮功能
   注册事件
   界面功能
   其他功能
   数据监视
--]]

function TestChooseCardView:onCreate(oldData)
	battleEntrance.preloadConfig()

	local testRoleOut = csvClone(csv.test_battle)

	self.resources = {}
	self.lastClickObj = nil

	EasyView.stage = self.stage
	EasyView.btnItem = self.btnItem

	self.dragSpriteNow = cc.Node:create()
		:addTo(self.stage,1000)
	self.btnRecordData = {}
	self.leftAttrAdd = 1
	self.rightAttrAdd = 1
	self.gameEnvData = nil

	self.drawNode = cc.DrawNode:create()
	self.stage:addChild(self.drawNode,2000)

	local pos = cc.p(self.gameObjects:x(),self.gameObjects:y())
	local size = self.gameObjects:size()
	self.gameObjectsRect = cc.rect(pos.x, pos.y, size.width, size.height)

	self:initBtnState()
	self:initFightTypeList()
	self:initTextAttrAdd()

	for _,roleOut in pairs(testRoleOut) do
		self:addRes(roleOut.roleId,roleOut)
	end

	self:loadOldData(oldData,testRoleOut)

	self:checkBtnState()

	self.leftForceInfo = {}
	self.rightForceInfo = {}

	self.prefabs:x(display.sizeInViewRect.x)

	self:showRecordView()

end

-- 初始化部分按钮的状态
function TestChooseCardView:initBtnState()
	for _,str in pairs(BtnConfigList) do
		local btn = self.btnItem:clone()
		local btnInfo = string.split(str,'|')
		local btnName = btnInfo[1]
		local eventName = "on" .. btnName:gsub("^%l", string.upper)
		btn:get("label"):setString(btnInfo[2])
		if self[eventName] then
			btn:addClickEventListener(functools.handler(self,self[eventName]))
		end
		self[btnName] = btn
		self.btnList:pushBackCustomItem(btn)
	end

	self:onBtnFullMp(nil,gSceneAttrCorrect[__TestDefine.TestSceneID].addMp1)
end

function TestChooseCardView:initFightTypeList()
	for _,type in pairs(FightType) do
		local btn = self.btnItem:clone()
		btn:get("label"):setString(FightTypeStr[type])
		btn:addClickEventListener(functools.handler(self, self.changeFightType, type))
		self.fightTypeList:pushBackCustomItem(btn)
	end
end

function TestChooseCardView:initTextAttrAdd(  )
	self.leftInputAttr:setString(self.leftAttrAdd)
	self.leftInputAttr:addEventListener(function(callback)
		local text = callback:text()
		self.leftAttrAdd = tonumber(text) or 1
	end)
	self.rightInputAttr:setString(self.rightAttrAdd)
	self.rightInputAttr:addEventListener(function(callback)
		local text = callback:text()
		self.rightAttrAdd = tonumber(text) or 1
	end)
end

-- 更新部分按钮的状态
function TestChooseCardView:checkBtnState()
	self:updateBtnState(self.btnShowHistory,#__TestDefine.historyBattleInfo ~= 0)
	self:onBtnAttrAdd(self.btnAttrAdd,self.btnRecordData["attrAdd"])
	self:onBtnBattleMonitor(nil,__TestDefine.Monitor)
	self:onBtnCloseRandFix(nil,__TestDefine.closeRandFix)
	self:onBtnRandSeedSwitch(nil,__TestDefine.randSeedSwitch)
	self:onBtnSameSpeedRandFix(nil,__TestDefine.sameSpeedRandFix)
	-- if __TestDefine.Monitor then
	-- 	-- self:monitorBattleInfo()
	-- 	self:onBtnBattleMonitor(nil,__TestDefine.Monitor)
	-- else
	-- 	self:onBtnBattleMonitor(nil,false)
	-- 	self:updateBtnState(self.btnRecordLog,false)
	-- 	self:updateBtnState(self.btnBattleMonitor,false)
	-- 	-- self.btnRecordLog:updateBtnState(false)
	-- end
end

function TestChooseCardView:loadOldData(data,record)
	data = data or {}
	self:changeFightType(data._fightType or FightType.Normal)

	if data._resources then
		for k,_prefab in pairs(data._resources) do
			self:addRes(_prefab.roleId,_prefab.extraData)
		end
	end

	if data._scene then
		self.gate:parseScene(data._scene)
	else
		self.gate:parseRecord(record)
	end

	-- if self.fightType == FightType.CrossArena then
	-- 	self.gate:parseRecord(csvClone(csv.test_battle))
	-- end

	if self.fightType == FightType.Pve then
		self.gate:changeGateType(data._gameEnvData.gateType or 1)
		self.textSceneID:setString(data._gameEnvData.sceneID or "")
	end

	self.btnRecordData = data._btnRecordData or {}
	self.gameEnvData = data._gameEnvData
end
-- 更新按钮状态
-- @param btn 按钮
-- @param isOpen 是否开启
function TestChooseCardView:updateBtnState(btn,isOpen)
	btn:setBright(isOpen)
	btn:setEnabled(isOpen)
end
-- 更改战斗状态
function TestChooseCardView:changeFightType(_type)
	if self.fightType and self.fightType == _type then return end
	local typeStr = FightTypeStr[_type]
	self.btnFightTypeSwitchLabel:setString(typeStr)
	self.fightType = _type
	self.gameEnvData = nil
	self.leftAttrAdd, self.rightAttrAdd = 1,1
	self:initTextAttrAdd()
	self.fightTypeList:hide()
	self.panelSceneID:hide()
	self.panelLeftAttrAdd:show()
	self.panelRightAttrAdd:show()

	self.gameObjects:removeAllChildren()
	self:updateBtnState(self.btnFightView,true)
	self:updateBtnState(self.btnManual,true)

	if _type == FightType.Normal then
		self.gate = require "app.views.city.test.gate.normal_gate"
	elseif _type == FightType.OneByOne then
		self.gate = require "app.views.city.test.gate.single_gate"
		self:updateBtnState(self.btnFightView,false)
	elseif _type == FightType.Chaos then -- 大乱斗
		self.gate = require "app.views.city.test.gate.chaos_gate"
	elseif _type == FightType.Craft then
		self.gate = require "app.views.city.test.gate.craft_gate"
	elseif _type == FightType.CrossArena then
		self.gate = require "app.views.city.test.gate.cross_arena_gate"
	elseif _type == FightType.CrossMine then
		self.gate = require "app.views.city.test.gate.cross_mine_gate"
		local size = self.gameObjects:size()
		local container = self.gameObjects:getInnerContainer()
		container:size(3100, size.height)
	elseif _type == FightType.BraveChallenge then
		self.gate = require "app.views.city.test.gate.brave_challenge_gate"
	elseif _type == FightType.Pve then
		self.panelSceneID:show()
		self.panelLeftAttrAdd:hide()
		self.panelRightAttrAdd:hide()
		self.gate = require "app.views.city.test.gate.pve_gate"
	end

	self.gate = self.gate.new(self)
	self.gate:init()
	-- if _type == FightType.CrossArena then
	-- 	self.gate:parseRecord(csvClone(csv.test_battle))
	-- end
end
---[[ ---------------------------- 按钮功能 ----------------------------
local en2cn = {
	["Dmg/buff"] = "BUFF伤害",
	["Dmg/rebound"] = "反伤伤害",
	["Dmg/skill"] = "技能伤害",
	["Dmg/allocate"] = "伤害分摊",
	["Dmg/link"] = "伤害链接",
	["validDamage"] = "有效伤害",
	["totalDamage"] = "总伤害",
	["extraHerosDamage"] = "召唤物伤害",

	["Rhp/buff"] = "BUFF治疗",
	["Rhp/skill"] = "技能治疗",
	["Rhp/suckblood"] = "吸血治疗",
	["Rhp/special"] = "特殊治疗",
	["totalResumeHp"] = "总治疗",

	["totalTake"] = "承受伤害",
	["kill"] = "击杀数",
	["skillTime"] = "大招次数",
	["firstBigSkillRound"] = "第一次大招回合",
	["firstKill"] = "首杀回合",
	["deadBigRound"] = "死亡回合",
	["beAttack"] = "受击(暴击/抵御)",
	["onceMaxDamage"] = "单次最高伤害",
	["totalRound"] = "持续回合"
}
function TestChooseCardView:onBtnShowHistory()
	local battleInfo = __TestDefine.historyBattleInfo[1]
	-- 多次测试取平均值
	local allBattleInfo = __TestDefine.allHistoryBattleInfo

	local customViewData = EasyView.initScrollView(self,EasyView.stage:width(), EasyView.stage:height()*2)

	if not battleInfo then return end

	local newRecordText = function(ishead,showLabel)
		showLabel = en2cn[showLabel] or showLabel
		local assignColor = cc.c4b(255, 255, 255, 255)
		local stringToColor = function(str)
			if string.find(str, "伤害") then
				return cc.c4b(255, 0, 0, 255)
			elseif string.find(str, "治疗") then
				return cc.c4b(0, 255, 0, 255)
			elseif string.find(str, "名字") or string.find(str, "站位") or string.find(str, "胜败") then
				return cc.c4b(255, 255, 255, 255)
			else
				return cc.c4b(255, 165, 80, 255)
			end
		end
		if type(showLabel) == "string" then
			if ishead then assignColor = stringToColor(showLabel)
			else assignColor = cc.c4b(0, 190, 255, 255) end
		end
		return ccui.Text:create(showLabel,"font/youmi1.ttf", 35)
			:addTo(customViewData.scrollView,1)
			:setTextColor(assignColor)
			:anchorPoint(ishead and cc.p(1,0.5) or cc.p(1,0.5))
	end

	local dealTextHighlight = function(head, textInfo)
		if not en2cn[head] then return end
		local minValue, maxValue = math.huge, 0
		-- 先筛选一遍 可能同时出现多个最大最小值
		for _, value in pairs(textInfo) do
			if value[2] then
				minValue = math.min(minValue, value[2])
				maxValue = math.max(maxValue, value[2])
			end
		end
		if head == "firstKill" or head == "firstBigSkillRound" then
			for _, value in pairs(textInfo) do
				if value[2] == minValue and minValue ~= 0 then value[1]:setTextColor(cc.c4b(255,255,0,255)) end
			end
		elseif head == "totalRound" then
			for _, value in pairs(textInfo) do
				if value[2] == 20 then value[1]:setTextColor(cc.c4b(255,255,0,255)) end
			end
		else
			for _, value in pairs(textInfo) do
				if value[2] == maxValue and maxValue ~= 0 then value[1]:setTextColor(cc.c4b(255,255,0,255)) end
			end
		end
	end

	local layer,lineFeed = 0,0
	local text,posX,posY,adjust
	local newColumnText = function(head,def,get,...)
		local args = {...}
		layer = layer + 1
		posX = customViewData.scrollView:width() / 10 * (layer - 0.5) + 100
		posY = customViewData.scrollView:getInnerContainerSize().height - lineFeed - 32
		text = newRecordText(true,head)
		local textInfo = {}
		if get then
			text:xy(posX,customViewData.scrollView:getInnerContainerSize().height-lineFeed-32)
			for i = 1, 12 do
				if i == 7 then posY = posY - 24 end
				if battleInfo[i] then
					posY = posY - 44
					local showStr, calNumber = get(i,...)
					text = newRecordText(false,showStr or def)
					text:xy(posX,posY)
					local drawLine = newRecordText(false, "_______________")
					drawLine:setTextColor(cc.c4b(90, 90, 90, 255))
					drawLine:xy(posX,posY - 8)
					table.insert(textInfo, {text, calNumber})
				end
			end
			dealTextHighlight(head, textInfo)
		else
			layer = 0
			lineFeed = lineFeed + 600
		end
	end

	local getValueInValueTypeTableArray = function(i,tableName,key,valueKey)
		if #allBattleInfo > 1 then
			local avgValue = 0
			for _,battleInfo in ipairs(allBattleInfo) do
				if key == "all" then
					for k, v in pairs(battleInfo[i][tableName]) do
						avgValue = avgValue + v:get(valueKey)
					end
				else
					if battleInfo[i][tableName][key] then
						avgValue = avgValue + battleInfo[i][tableName][key]:get(valueKey)
					end
				end
			end

			return math.ceil(avgValue / #allBattleInfo), math.ceil(avgValue / #allBattleInfo)
		else
			if not battleInfo[i][tableName][key] then return 0 end
			return battleInfo[i][tableName][key]:get(valueKey), battleInfo[i][tableName][key]:get(valueKey)
		end
	end

	local getValueInValueTypeTable = function(i,tableName,valueKey)
		if #allBattleInfo > 1 then
			local avgValue = 0
			for _,battleInfo in ipairs(allBattleInfo) do
				if battleInfo[i][tableName] then
					avgValue = avgValue + battleInfo[i][tableName]:get(valueKey)
				end
			end

			return math.ceil(avgValue / #allBattleInfo), math.ceil(avgValue / #allBattleInfo)
		else
			if not battleInfo[i][tableName] then return 0 end
			return battleInfo[i][tableName]:get(valueKey), battleInfo[i][tableName]:get(valueKey)
		end
	end

	-- local getArray = function(i,...)
	-- 	local len = #allBattleInfo
	-- 	if len > 1 then
	-- 		local avgValue = {}
	-- 		for k,battleInfo in ipairs(allBattleInfo) do
	-- 			local data = table.get(battleInfo[i],...)
	-- 			if data then
	-- 				for _k,v in ipairs(data) do
	-- 					avgValue[_k] = (avgValue[_k] or 0) + v
	-- 					if k == len then
	-- 						avgValue[_k] = math.ceil(avgValue[_k] / len)
	-- 					end
	-- 				end
	-- 			end
	-- 		end

	-- 		return dumps(avgValue)
	-- 	end

	-- 	local t = table.get(battleInfo[i],...)
	-- 	return dumps(t)
	-- end
	local getNumber = function(i,...)
		local len = #allBattleInfo
		if len > 1 then
			local avgValue = nil
			for k,battleInfo in ipairs(allBattleInfo) do
				local data = table.get(battleInfo[i],...)
				if data then
					avgValue = (avgValue or 0) + data
				end
				if len == k and avgValue then avgValue = math.ceil(avgValue / len) end
			end
			return avgValue, avgValue
		end
		return table.get(battleInfo[i],...), table.get(battleInfo[i],...)
	end

	local getString = function(i,...)
		return table.get(battleInfo[i],...), table.get(battleInfo[i],...)
	end

	local getBeAttackString = function(i,...)
		local args = {...}
		local len = #allBattleInfo
		if len > 1 then
			local avgValue1, avgValue2, avgValue3, finalString = nil, nil, nil, nil
			for k,battleInfo in ipairs(allBattleInfo) do
				local data1 = table.get(battleInfo[i],args[1]) or 0
				local data2 = table.get(battleInfo[i],args[2]) or 0
				local data3 = table.get(battleInfo[i],args[3]) or 0
				avgValue1 = (avgValue1 or 0) + data1
				avgValue2 = (avgValue2 or 0) + data2
				avgValue3 = (avgValue3 or 0) + data3
				if len == k and avgValue1 and avgValue2 and avgValue3 then
					avgValue1 = math.ceil(avgValue1 / len)
					finalString = avgValue1.."("..math.ceil(avgValue2 / len).."/"..math.ceil(avgValue3 / len)..")"
				end
			end
			return finalString, avgValue1
		end
		return (table.get(battleInfo[i],args[1]) or 0).."("..(table.get(battleInfo[i],args[2]) or 0).."/"..(table.get(battleInfo[i],args[3]) or 0)..")", table.get(battleInfo[i],args[1])
	end

	local valueType = battle.ValueType.normal
	newColumnText("名字","",getString,"name")
	newColumnText("站位","",getString,"seat")
	newColumnText("胜败","",getString,"result")

	newColumnText("Dmg/skill",0,getValueInValueTypeTableArray,"totalDamage",battle.DamageFrom.skill,valueType)
	newColumnText("Dmg/buff",0,getValueInValueTypeTableArray,"totalDamage",battle.DamageFrom.buff,valueType)
	newColumnText("Dmg/rebound",0,getValueInValueTypeTableArray,"totalDamage",battle.DamageFrom.rebound,valueType)
	newColumnText("Dmg/allocate",0,getValueInValueTypeTableArray,"totalDamage",battle.DamageFromExtra.allocate,valueType)
	newColumnText("Dmg/link",0,getValueInValueTypeTableArray,"totalDamage",battle.DamageFromExtra.link,valueType)
	newColumnText("extraHerosDamage",0,getNumber,"extraHerosDamage")
	newColumnText("validDamage",0,getValueInValueTypeTable,"_totalDamage",battle.ValueType.valid)
	newColumnText("totalDamage",0,getValueInValueTypeTable,"_totalDamage",valueType)

	newColumnText("lineFeed")
	newColumnText("名字","",getString,"name")
	newColumnText("totalTake",0,getValueInValueTypeTableArray,"totalTakeDamage","all",valueType)
	newColumnText("Rhp/skill",0,getValueInValueTypeTableArray,"totalResumeHp",battle.ResumeHpFrom.skill,valueType)
	newColumnText("Rhp/buff",0,getValueInValueTypeTableArray,"totalResumeHp",battle.ResumeHpFrom.buff,valueType)
	newColumnText("Rhp/suckblood",0,getValueInValueTypeTableArray,"totalResumeHp",battle.ResumeHpFrom.suckblood,valueType)
	newColumnText("Rhp/special",0,getNumber,"resumeSpecialHp")
	newColumnText("totalResumeHp",0,getValueInValueTypeTable,"_totalResumeHp",valueType)

	newColumnText("kill",0,getNumber,"kill")
	newColumnText("firstKill",0,getNumber,"firstKill")
	newColumnText("skillTime",0,getNumber,"skillTime",battle.MainSkillType.BigSkill)
	newColumnText("firstBigSkillRound",20,getNumber,"firstBigSkillRound")

	newColumnText("lineFeed")
	newColumnText("名字","",getString,"name")
	newColumnText("deadBigRound",20,getNumber,"deadBigRound")
	newColumnText("beAttack","0(0/0)",getBeAttackString,"beAttack","beAttackStrike", "beAttackBlock")
	newColumnText("onceMaxDamage",0,getNumber,"onceMaxDamage")
	newColumnText("totalRound",0,getNumber,"totalRound")

	-- for _,valueT in pairs(battleInfo) do
	-- 	layer = layer + 1
	-- 	posY = customViewData.root:height() - (layer + 0.5) * 40 - layer*10
	-- 	text = newRecordText(true,valueT.head)
	-- 	if valueT.v then
	-- 		text:xy(10,posY)
	-- 		for i=1,12 do
	-- 			if valueT.v[i] then
	-- 				posX = 220 + (customViewData.root:width() - 220)/12 * (i - 0.5)
	-- 				text = newRecordText(false,valueT.v[i])
	-- 				text:xy(posX,posY)
	-- 			end
	-- 		end
	-- 	else
	-- 		text:anchorPoint(cc.p(0.5,0.5))
	-- 			:xy(customViewData.root:width()/2 + 125,posY)
	-- 	end
	-- end
end

function TestChooseCardView:onBtnCleanTeam()
	self.gate:cleanGameObject()
	self.gameEnvData = nil
end
-- 战斗监控
function TestChooseCardView:onBtnBattleMonitor(btn,state)
	if state == nil then
		state = not __TestDefine.Monitor
	end

	if state then
		self.btnBattleMonitor:get("label"):text("战斗监控(开启)")
	else
		self.btnBattleMonitor:get("label"):text("战斗监控(关闭)")
	end
	__TestDefine.Monitor = state
	self.btnBattleMonitor:setBright(state)
	self:updateBtnState(self.btnRecordLog,state)
	print("__TestDefine.Monitor",__TestDefine.Monitor)
end
-- 更改场景蓝量
function TestChooseCardView:onBtnFullMp(btn,initMp)
	local sceneAttrCorrect = table.getraw(gSceneAttrCorrect)
	local fullMp = 1000
	local valTab = {[fullMp] = 0,[400] = fullMp,[0] = 400}
	local val = valTab[(sceneAttrCorrect[__TestDefine.TestSceneID].addMp1)] or 0
	local nextMp = initMp or val

	self.btnFullMp:get("label"):text(string.format("%d%%怒气",nextMp/fullMp*100))
	table.getraw(sceneAttrCorrect[__TestDefine.TestSceneID]).addMp1 = nextMp
	table.getraw(sceneAttrCorrect[-__TestDefine.TestSceneID]).addMp1 = nextMp
	-- print("scene Mp",nextMp)
	__TestEasy.log("scene Mp",nextMp)
end
-- 更改伤害波动
function TestChooseCardView:onBtnCloseRandFix(btn,state)
	if state == nil then
		state = not __TestDefine.closeRandFix
	end

	if state then
		self.btnCloseRandFix:get("label"):text("伤害波动(关闭)")
	else
		self.btnCloseRandFix:get("label"):text("伤害波动(开启)")
	end
	__TestDefine.closeRandFix = state
end
-- 同速度随机出手
function TestChooseCardView:onBtnSameSpeedRandFix(btn,state)
	if state == nil then
		state = not __TestDefine.sameSpeedRandFix
	end

	if state then
		self.btnSameSpeedRandFix:get("label"):text("同速度随机(开启)")
	else
		self.btnSameSpeedRandFix:get("label"):text("同速度随机(关闭)")
	end
	self.btnSameSpeedRandFix:setBright(state)
	__TestDefine.Monitor = state
	__TestDefine.sameSpeedRandFix = state
end
-- 切换战斗模式
function TestChooseCardView:onBtnFightTypeSwitch()
	local isVisible = self.fightTypeList:isVisible()
	self.fightTypeList:setVisible(not isVisible)


	-- local nextType = self.fightType + 1
	-- for k,v in pairs(FightType) do
	-- 	if v == nextType then
	-- 		self:changeFightType(v)
	-- 		return
	-- 	end
	-- end
	-- self:changeFightType(1)
end
-- 返回主界面
function TestChooseCardView:onBtnManual()
	self:onClose()
end
-- 显示战斗界面
function TestChooseCardView:onBtnFightView()
	self:createTestSceneData()
	if self.fightType == FightType.Pve then
		local gateType = self.gate:getCurGateType()
		local sceneID = self.textSceneID:getString()
		if gateType == "" or sceneID == "" then return end
		self.gameEnvData.gateType = tonumber(gateType)
		self.gameEnvData.sceneID = tonumber(sceneID)
	end
	local roleOutTab,gateType = self:getFightRoleData()
	if #roleOutTab == 0 then return end
	self.gameEnvData.roleOut = roleOutTab[1]
	self.gameEnvData.roleOut2 = self.fightType == FightType.CrossArena and {{},{}} or {}
	self.gameEnvData.gateType = gateType or self.gameEnvData.gateType
	local saveData = self:saveInitData()
	__TestDefine.allHistoryBattleInfo = {}
	-- self.gameEnvData.randSeed = 156348
	self.gameEnvData.closeRandFix = __TestDefine.closeRandFix
	if  __TestDefine.randSeedSwitch then
		self.gameEnvData.randSeed = math.random(1, 1000000)
	end


	local t = {
		_data = self.gameEnvData,
		_modes = {baseMusic = "battle1.mp3", fromRecordFile=true, isRecord = (self.gameEnvData.play_record_id  or self.gameEnvData.recordResult or self.gameEnvData.isFromRecord) and true},
	}
	battleEntrance._switchUI(t, function()
		local t = {
			_results = {},
			_onResult = function(data, results)
				performWithDelay(gRootViewProxy:raw(), function()
					gGameUI:switchUI("login.view")
					gGameUI:stackUI("city.test.choose_card", nil, {full = true},saveData)
				end, 0)
			end,
			_isTestScene = true,
		}
		battleEntrance._localHack.postEndResultToServer(t)
		gRootViewProxy:raw().showEndView = t._onResult
		gRootViewProxy:call("backToLogin", saveData)

		performWithDelay(gRootViewProxy:raw(), function()
			local play = gRootViewProxy:raw()._model.scene.play
			if not csvTestBattle1.gateType and not play.OperatorArgs then
				play.OperatorArgs = battlePlay.TestGate.OperatorArgs
			end
			play:initFightOperatorMode()
		end, 1)
		battleEntrance._localHack.postEndResultToServer(t)
		battleEntrance._localHack.showEndView(t)
	end)
end

--战斗测试
function TestChooseCardView:onBtnFightTest()
	self:createTestSceneData()
	local roleOutTab,gateType = self:getFightRoleData()
	if #roleOutTab == 0 then return end
	self.gameEnvData.gateType = gateType or self.gameEnvData.gateType
	-- local editView = self:initBaseView({"btnClose|关闭","btnStart|开始"})
	--     :addEditControl("editControl")

	local editView = EasyView.initBaseView(self)
	EasyView.addBtnListToView(
		editView,
		{"btnClose|关闭","btnStart|开始","btnSendToServer|服务器计算","btnStartLessTime|战斗5秒"},
		cc.p(self.stage:width()/2,100),
		EasyView.CustomBtnType.Center
	)
	EasyView.addInputControl(
		editView,
		cc.p(self.stage:width()/2,self.stage:height()/2 + 200),
		cc.EDITBOX_INPUT_MODE_NUMERIC,
		"战斗测试次数",
		1
	)
	EasyView.addInputControl(
		editView,
		cc.p(self.stage:width()/2,self.stage:height()/2 ),
		cc.EDITBOX_INPUT_MODE_SINGLELINE,
		"需要记录的buffid",
		2
	)

	local function showBuffEffectTakeEffect()
		local battleInfo = __TestDefine.historyBattleInfo[1]
		-- 多次测试取平均值
		local allBattleInfo = __TestDefine.allHistoryBattleInfo
		local round = table.length(allBattleInfo)
		local result = {}
		local hasData = false
		for k, battleRound in ipairs(allBattleInfo) do
			for _, card in pairs(battleRound) do
				if card["buffTakeEffect"] then
					hasData = true
					result[card.seat] = result[card.seat] or {}
					result[card.seat]["name"] = card.name
					result[card.seat]["data"] = result[card.seat]["data"] or {}
					for id, times in pairs(card["buffTakeEffect"]) do
						result[card.seat]["data"][id] = result[card.seat]["data"][id] or 0
						result[card.seat]["data"][id] = result[card.seat]["data"][id] + times
					end
				end
			end
		end

		if hasData then
			EasyView.addTextListView(editView, cc.p(self.stage:width()/2 - 800,self.stage:height()/2 - 500), cc.size(1500,400))
			editView.listView:show()
			for k, v in pairs(result) do
				local str = k.."号位 "..v.name.." "
				for cfgId, times in pairs(v.data) do
					str = str.."buffid:"..cfgId.." 总次数:"..times.."  "
				end
				local text = ccui.Text:create(str, FONT_PATH, 36)
				text:getVirtualRenderer():setTextColor(cc.c4b(0, 255, 0, 200))
				text:enableOutline(cc.c4b(0, 0, 0, 255), 3)
				editView.listView:pushBackCustomItem(text)
			end
		else
			if editView.listView then
				editView.listView:hide()
			end
		end
	end

	local time = 1
	editView.btnSendToServer:addTouchEventListener(function(sender, eventType)
		if eventType == ccui.TouchEventType.ended then
			time = editView.editBox[1]:getText()
			time = time == "" and 100 or tonumber(time)
			local filename = string.format("%s_%s_%s", self.gameEnvData.sceneID, self.gameEnvData.gateType, os.date("%y%m%d-%H%M%S"))
			print("!!!!! choose_card", self.gameEnvData.sceneID, self.gameEnvData.gateType)
			for idx, roleOut in pairs(roleOutTab) do
				self.gameEnvData.roleOut = roleOut
				local _filename = filename
				_filename = _filename .. string.format("_%s", idx)
				-- for k,v in pairs(roleOut) do
				-- 	_filename = _filename .. string.format("_%s=%s", k, csv.unit[v.roleId].name)
				-- end
				gGameApp.net:sendHttpRequest(
					"POST",
					-- "http://192.168.1.96:39081/test_rand_fight",
					"http://localhost:9999/api/client/upload",
					msgpack({
						filename = _filename .. ".record",
						record = msgpack(self.gameEnvData),
						count = time
					}),
					cc.XMLHTTPREQUEST_RESPONSE_STRING,
					function(xhr)
						gGameUI:showTip(string.format("发送战报:%s, 次数:%s, 结果:%s",_filename, time, xhr.status))
					end
				)
			end
		end
	end)

	editView.btnStart:addTouchEventListener(function(sender, eventType)
		if eventType == ccui.TouchEventType.began then
			self:updateBtnState(editView.btnStart,false)
			self:updateBtnState(editView.btnClose,false)
			self:updateBtnState(editView.btnStartLessTime,false)
		elseif eventType == ccui.TouchEventType.ended then
			-- local resultTab = {}
			-- time = editView.editBox:getText()
			-- time = time == "" and 1 or tonumber(time)
			-- for _,roleOut in pairs(roleOutTab) do
			--     local winTimes = 0
			--     local loseTimes = 0
			--     local str = "vs"
			--     for _seat,_temp in pairs(roleOut) do
			--         local name = csvUnits[_temp.roleId].name
			--         str = _seat > 6 and string.format("%s %s",str,name) or string.format("%s %s",name,str)
			--     end
			--     resultTab[#resultTab + 1] = str
			--     self.gameEnvData.roleOut = roleOut
			--     for i=1,time do
			--         local result = battleEntrance.battleRecord(self.gameEnvData, {}, {fromRecordFile=true}):run()
			--         if result.result == "win" then
			-- 	        winTimes = winTimes + 1
			--         elseif result.result == "fail" then
			-- 	        loseTimes = loseTimes + 1
			--         end
			--         self.gameEnvData.randSeed = math.random(1, 100000)
			--         print(string.format("---------------------(%d/%d)---------------------",i,time))
			--     end
			--     resultTab[#resultTab + 1] = string.format("总战斗测试次数: %d 其中赢%d次 输%d次",time,winTimes,loseTimes)
			-- end

			-- for _,str in ipairs(resultTab) do
			--     print(str)
			-- end

			time = editView.editBox[1]:getText()
			__TestDefine.buffId = string.split(editView.editBox[2]:getText(), ",")
			time = time == "" and 1 or tonumber(time)
			__TestDefine.allHistoryBattleInfo = {}
			self.battleResultInfo = {}
			for _,roleOut in pairs(roleOutTab) do
				self:runGameLogicByRoleOut(roleOut,time,false)
			end
			print("+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-")
			for _, info in ipairs(self.battleResultInfo) do
				print(info)
			end
			print("+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-")
			-- print("__TestDefine.historyBattleInfo",dump(__TestDefine.historyBattleInfo))
			self:updateBtnState(self.btnShowHistory,#__TestDefine.historyBattleInfo ~= 0)
			self:updateBtnState(editView.btnStart,true)
			self:updateBtnState(editView.btnClose,true)
			self:updateBtnState(editView.btnStartLessTime,true)

			showBuffEffectTakeEffect()
		end
	end)

	editView.btnStartLessTime:addTouchEventListener(function(sender, eventType)
		if eventType == ccui.TouchEventType.began then
			self:updateBtnState(editView.btnStart,false)
			self:updateBtnState(editView.btnClose,false)
			self:updateBtnState(editView.btnStartLessTime,false)
		elseif eventType == ccui.TouchEventType.ended then

			time = editView.editBox[1]:getText()
			time = time == "" and 1 or tonumber(time)
			__TestDefine.buffId = string.split(editView.editBox[2]:getText(), ",")
			__TestDefine.allHistoryBattleInfo = {}
			for _,roleOut in pairs(roleOutTab) do
				self:runGameLogicByRoleOutLessTime(roleOut,time,false)
			end
			-- print("__TestDefine.historyBattleInfo",dump(__TestDefine.historyBattleInfo))
			self:updateBtnState(self.btnShowHistory,#__TestDefine.historyBattleInfo ~= 0)
			self:updateBtnState(editView.btnStart,true)
			self:updateBtnState(editView.btnClose,true)
			self:updateBtnState(editView.btnStartLessTime,true)

			showBuffEffectTakeEffect()
		end
	end)
end

-- 添加精灵
function TestChooseCardView:onBtnAddPrefab()
	local view = EasyView.initScrollView(self,self.stage:width()*10)
	-- local editView = self:initEditView(nil,"请输入精灵id")

	EasyView.addInputControl(view,cc.p(self.stage:width()/2+500,100),cc.EDITBOX_INPUT_MODE_ANY,"精灵名称")
	for i,v in ipairs(gHandbookArrayCsv) do
		local cardInfo = csvCards[v.cardID]
		local unitInfo = csvUnits[cardInfo.unitID]

		local btn = self.prefab:clone()
		-- btn:get("label"):text(unitInfo.name)
		btn:get("icon"):texture(unitInfo.iconSimple)
		btn.id = cardInfo.unitID
		btn.name = unitInfo.name
		btn.index = view.scrollView:getChildrenCount() + 1
		local lerpPos,limit = cc.p(10,5),6
		local startPos = cc.p(btn:size().width/2 + lerpPos.x
			,btn:size().height/2+lerpPos.y)
		self:addItemToScrollView(view.scrollView,btn,lerpPos,startPos,limit)
		if self.resources[cardInfo.unitID] then
			self:updateBtnState(btn,false)
		else
			btn:addClickEventListener(function(_btn)
				self:addRes(_btn.id)
				self:updateBtnState(_btn,false)
				cache.setShader(_btn, false, "hsl_gray")
			end)
		end
	end
	-- view.editBox:setPlaceHolder("精灵名字")
	view.editBox:registerScriptEditBoxHandler(function(eventname,sender)
		if eventname == "ended" then
			local str = string.gsub(view.editBox:getText(),'[%w%p]+',"")
			local lastIndex = 1
			for _,v in ipairs(view.scrollView:getChildren()) do
				v:visible(false)
				if string.find(v.name,str,1) then
					local k = v.index
					if lastIndex ~= k then
						local x,y = view.scrollView:getChildren()[k]:xy()
						view.scrollView:getChildren()[k]:xy(view.scrollView:getChildren()[lastIndex]:xy())
						view.scrollView:getChildren()[lastIndex]:xy(x,y)

						view.scrollView:getChildren()[k].index = lastIndex
						view.scrollView:getChildren()[lastIndex].index = k
					end
					v:visible(true)
					lastIndex = lastIndex + 1
				end
			end
		end
	end)
end

function TestChooseCardView:onBtnRecordLog(btn)
	local folder = io.open(__TestDefine.ReadRecordFolderPath)
	if not folder then
		os.execute('mkdir ' .. __TestDefine.ReadRecordFolderPath)
	else
		folder:close()
	end

	local logFolderPath = __TestDefine.ReadRecordFolderPath.."\\log"
	local logFolder = io.open(logFolderPath)
	if not logFolder then
		os.execute('mkdir ' .. logFolderPath)
	else
		logFolder:close()
	end

	-- 导出结果到文件夹
	-- local file = io.open(__TestDefine.ReadRecordFolderPath ..string.format("\\%s.txt",os.time()), "a")
	-- file:write(string.format("单位\t\t站位\t\t伤害(Buff\\反伤\\技能)\t\t治疗(Buff\\技能\\吸血)\t\t击杀\n\n"))
	-- for i = 1,raw.curWave do
	--     file:write(string.format("Wave: (%d/%d)\n",i,raw.curWave))
	--     for j = 1,12 do
	--         local obj = __TestDefine.historyBattleInfo[i][j]
	--         if obj then
	--             file:write(string.format("%s\t\t%d\n",obj.name,obj.id))
	--         end
	--     end
	-- end

	-- record
	self:onBtnAttrAdd(nil,false)
	local func = userDefault.getForeverLocalKey
	local runTime = 1

	local condition = function(objData)
		if objData.unitID == 3631 then
			return true
		end
		return false
	end

	userDefault.getForeverLocalKey = function(...)
		return true
	end

	local startTime = os.time()

	local files = fs.listAllFiles(__TestDefine.ReadRecordFolderPath, function (name)
		return name:match("%.record$")
	end, false)

	local count = 0
	for _,v in pairs(files) do
		count = count + 1
	end

	local file = io.open(logFolderPath ..string.format("\\%s.txt","record"), "a")
	file:write("单位\t\t站位\t\t伤害(Buff\\反伤\\技能)\t\t治疗(Buff\\技能\\吸血)\t\t击杀\n\n")
	local curNum = count
	for name, time in pairs(files) do
		local data = readAndUnpack(name)
		local envData = removeInternalTable(data)
		if envData.gateType == 'cross_craft' or envData.gateType == 'craft' then
			self:changeFightType(FightType.Craft)
		elseif envData.gateType == game.GATE_TYPE.crossArena then
			self:changeFightType(FightType.CrossArena)
		elseif envData.gateType == game.GATE_TYPE.crossMine then
			self:changeFightType(FightType.CrossMine)
		end
		self.gameEnvData = envData
		self:runGameLogicByRoleOut(self.gameEnvData.roleOut,runTime,function(result)
			file:write(string.format("RunTime: (%d/%d), Seed: %d Result:%s\n",result.time,runTime,result.seed,result.result))
			for i = 1,#__TestDefine.historyBattleInfo do
				file:write(string.format("Wave: (%d/%d)\n",i,#__TestDefine.historyBattleInfo))
				for j = 1,12 do
					local obj = __TestDefine.historyBattleInfo[i][j]
					if obj then
						file:write(string.format("%s\t\t%d\t\t%d,%d,%d\t\t%d,%d,%d\t\t%d\n",
							obj.name,obj.id,
							obj.totalDamage[battle.DamageFrom.buff]:get(1),
							obj.totalDamage[battle.DamageFrom.rebound]:get(1),
							obj.totalDamage[battle.DamageFrom.skill]:get(1),
							obj.totalResumeHp[battle.ResumeHpFrom.buff]:get(1),
							obj.totalResumeHp[battle.ResumeHpFrom.skill]:get(1),
							obj.totalResumeHp[battle.ResumeHpFrom.suckblood]:get(1),
							obj.kill or 0
						))
					end
				end
			end
			file:write("\n\n")
			if result.time == 10 then
				file:write(string.format("[INFO] 总战斗测试次数: %d (%d vs %d)",10,result.win,result.lose))
			end
		end)
		curNum = curNum - 1
		print("record to log <%d/%d> !!!!!!!!!!!",curNum,count)
	end
	file:close()
	-- play
	files = fs.listAllFiles(__TestDefine.ReadRecordFolderPath, function (name)
		return name:match("%.play$")
	end, false)

	count = 0
	for _,v in pairs(files) do
		count = count + 1
	end

	local _file = io.open(logFolderPath ..string.format("\\%s.txt","play"), "a")
	_file:write("单位\t\t站位\t\t伤害(Buff\\反伤\\技能)\t\t治疗(Buff\\技能\\吸血)\t\t击杀\n\n")
	curNum = count
	for name, time in pairs(files) do
		local data = readAndUnpack(name)
		local playName = data[1]
		if type(data[2]) == 'table' then
			data = data[2]
		else
			data = msgunpack(data[2])
		end
		self.gameEnvData = self:parseBattle(playName,data)
		self:runGameLogicByRoleOut(self.gameEnvData.roleOut,runTime,function(result)
			_file:write(string.format("RunTime: (%d/%d), Seed: %d Result:%s\n",result.time,runTime,result.seed,result.result))
			for i = 1,#__TestDefine.historyBattleInfo do
				_file:write(string.format("Wave: (%d/%d)\n",i,#__TestDefine.historyBattleInfo))
				for j = 1,12 do
					local obj = __TestDefine.historyBattleInfo[i][j]
					if obj then
						_file:write(string.format("%s\t\t%d\t\t%d,%d,%d\t\t%d,%d,%d\t\t%d\n",
							obj.name,obj.seat,
							obj.totalDamage[battle.DamageFrom.buff]:get(1),
							obj.totalDamage[battle.DamageFrom.rebound]:get(1),
							obj.totalDamage[battle.DamageFrom.skill]:get(1),
							obj.totalResumeHp[battle.ResumeHpFrom.buff]:get(1),
							obj.totalResumeHp[battle.ResumeHpFrom.skill]:get(1),
							obj.totalResumeHp[battle.ResumeHpFrom.suckblood]:get(1),
							obj.kill or 0
						))
					end
				end
			end
			_file:write("\n\n")
			if result.time == 10 then
				_file:write(string.format("[INFO] 总战斗测试次数: %d (%d vs %d)\n\n",10,result.win,result.lose))
			end
		end)
		curNum = curNum - 1
		print(string.format("play to log <%d/%d> !!!!!!!!!!!",curNum,count))
	end
	_file:close()
	print("!!!!!!!!!!!!!! cost time",os.time() - startTime,"s")

	userDefault.getForeverLocalKey = func
end

function TestChooseCardView:onBtnSyncFight(btn)
	userDefault.getForeverLocalKey = function(...)
		return true
	end
	gGameApp.net:doRealtime('192.168.1.96', 1234, function(ret, err)
		if ret then
			print_r(ret)
			local battleData = gGameModel.battle:getData()
			print("!!!!!!!!!!!!!!",gGameModel,dump(battleData,nil,999))
			-- battleData.gateType = game.GATE_TYPE.test
			battleData.operateForce = ret.operate_force
			local t = {
				_data = battleData,
				_modes = {baseMusic = "battle1.mp3"},
			}
			battleEntrance._switchUI(t, function()
				local t = {
					_results = {},
					_onResult = function(data, results)
						performWithDelay(gRootViewProxy:raw(), function()
							gGameUI:switchUI("login.view")
							gGameUI:stackUI("city.test.choose_card", nil, {full = true})
						end, 0)
					end,
					_isTestScene = true,
				}
				battleEntrance._localHack.postEndResultToServer(t)
				gRootViewProxy:raw().showEndView = t._onResult

				-- performWithDelay(gRootViewProxy:raw(), function()
				-- 	local play = gRootViewProxy:raw()._model.scene.play
				-- 	play.OperatorArgs = battlePlay.SyncFightGate.OperatorArgs
				-- 	play:initFightOperatorMode()
				-- end, 1)
				battleEntrance._localHack.postEndResultToServer(t)
				battleEntrance._localHack.showEndView(t)
			end)
		end
		if err then
			gGameUI:showTip(err.err)
		end
	end)
end

-- 随机种子开关
function TestChooseCardView:onBtnRandSeedSwitch(btn,state)
	if state == nil then
		state = not __TestDefine.randSeedSwitch
	end

	if state then
		self.btnRandSeedSwitch:get("label"):text("随机种子(开启)")
	else
		self.btnRandSeedSwitch:get("label"):text("随机种子(关闭)")
	end

	print("randSeedSwitch", state)
	__TestDefine.randSeedSwitch = state
end

function TestChooseCardView:onBtnExchangeSeat(btn)
	self.gate:exchange()
end

-- 属性加成
function TestChooseCardView:onBtnAttrAdd(btn,initState)
	if initState == nil then
		if self.btnRecordData["attrAdd"] == nil then
			self.btnRecordData["attrAdd"] = false
		end
		self.btnRecordData["attrAdd"] = not self.btnRecordData["attrAdd"]
	else
		self.btnRecordData["attrAdd"] = initState
	end

	if self.btnRecordData["attrAdd"] then
		self.btnAttrAdd:get("label"):text("属性加成(开启)")
	else
		self.btnAttrAdd:get("label"):text("属性加成(关闭)")
	end

	print("attrAdd",self.btnRecordData["attrAdd"])
	self.btnAttrAdd:setBright(self.btnRecordData["attrAdd"])
end

function TestChooseCardView:onBtnUdpTest(btn)
	local data = {str = "撒大声地21312dsadas世界"}
	--custom_plugin.create()
	-- custom_plugin.send(1,data)
	print("\n\n---------------------------")
	for k,v in pairs(data) do
		print(k,v)
	end
	--custom_plugin.close()
end
-- 加载战报
function TestChooseCardView:onBtnLoadRecord(btn, path, view)
	path = path or "."

	local files = fs.listAllFiles(path, function (name)
		return name:match("%.record$")
	end, false)
	-- local editor = require("editor.builder")

	local initText = function(idx,name)
		local menuText = string.format("%2d %s", idx, name)
		local ffi = require("ffi")
		if ffi.os == "Windows" then
			local iconv = require "editor.win32.ansi2unicode"
			menuText = iconv.a2u(menuText)
		end

		local text = ccui.Text:create(menuText, FONT_PATH, view and 48 or 72)
		text:getVirtualRenderer():setTextColor(cc.c4b(0, 255, 0, 200))
		text:enableOutline(cc.c4b(0, 0, 0, 255), 3)
		-- text:setTouchScaleChangeEnabled(true)
		text:setTouchEnabled(true)
		return text
	end

	local customView = view or EasyView.initListView(self)
	local idx = 1
	local datas = {}
	for name, time in pairs(files) do
		table.insert(datas, {name = name, time = time})
	end
	table.sort(datas, function(a, b)
		return a.name < b.name
	end)
	for _, v in ipairs(datas) do
		local name = v.name
		local time = v.time
		local text = initText(idx,name)
		text:addTouchEventListener(function(sender, eventType)
			text:scale((eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled) and 1 or 1.05)
			if eventType == ccui.TouchEventType.ended then
				local data = readAndUnpack(name)
				data = removeInternalTable(data)
				if data.gateType == game.GATE_TYPE.crossCraft or data.gateType == game.GATE_TYPE.craft then
					self:changeFightType(FightType.Craft)
				elseif data.gateType == game.GATE_TYPE.crossArena then
					self:changeFightType(FightType.CrossArena)
				elseif data.gateType == game.GATE_TYPE.crossMine then
					self:changeFightType(FightType.CrossMine)
				elseif pveGateType[data.gateType] then
					self:changeFightType(FightType.Pve)
					self.gate:initRecordGateAndSceneID(data.gateType, data.sceneID)
				else
					self:changeFightType(FightType.Normal)
				end
				data.isFromRecord = true -- 加载的是战报
				self.gameEnvData = data
				self:onBtnAttrAdd(nil,false)
				self.gate:parseRecord(self.gameEnvData.roleOut)
			end
		end)
		customView.listView:pushBackCustomItem(text)
		idx = idx + 1
	end

	files = fs.listAllFiles(path, function (name)
		return name:match("%.play$")
	end, false)
	idx = 1
	local datas = {}
	for name, time in pairs(files) do
		table.insert(datas, {name = name, time = time})
	end
	table.sort(datas, function(a, b)
		return a.name < b.name
	end)
	for _, v in ipairs(datas) do
		local name = v.name
		local time = v.time
		local text = initText(idx,name)
		text:addTouchEventListener(function(sender, eventType)
			if eventType == ccui.TouchEventType.ended then
				local data = readAndUnpack(name)
				local playName = data[1]
				if type(data[2]) == 'table' then
					data = data[2]
				else
					data = msgunpack(data[2])
				end
				self.gameEnvData = self:parseBattle(playName,data)
				self:onBtnAttrAdd(nil,false)
				self.gate:parseRecord(self.gameEnvData.roleOut)
			end
		end)
		customView.listView:pushBackCustomItem(text)
		idx = idx + 1
	end
end

-- 选择布阵
function TestChooseCardView:onBtnMultiForce(  )
	local view = EasyView.initForceScrollView(self,self.stage:width()*10)

	local testForce = csvClone(csv.test_force)
	self.unitTb = {
		left_front_tb = {},
		left_back_tb = {},
		right_front_tb = {},
		right_back_tb = {}
	}
	local forceAttr = {}

	for k,v in pairs(testForce) do
		if k <= 100 then
			table.insert(forceAttr,v)
		elseif k > 100 and k <= 200 then
			if v.priproity > 0 then
				table.insert(self.unitTb.left_front_tb,v)
			else
				table.insert(self.unitTb.left_back_tb,v)
			end
		elseif k >200 then
			if v.priproity > 0 then
				table.insert(self.unitTb.right_front_tb,v)
			else
				table.insert(self.unitTb.right_back_tb,v)
			end
		end
	end

	self:addUnitPanel(view,self.unitTb.left_front_tb,1)
	self:addUnitPanel(view,self.unitTb.left_back_tb,2)
	self:addUnitPanel(view,self.unitTb.right_front_tb,3)
	self:addUnitPanel(view,self.unitTb.right_back_tb,4)

	self.dataTb = {}
	MultiForce.loadFiles(self)
	MultiForce.fillDataTb(self,self.unitTb,self.dataTb)

	EasyView.addBtnListToView(
		view,
		{"btnClose|关闭","btnStartForce|6v6开始","btnStartSolo|1v1开始"},
		cc.p(self.stage:width()/2,100),
		EasyView.CustomBtnType.Center
	)

	view.btnStartForce:addTouchEventListener(function(sender, eventType)
		if eventType == ccui.TouchEventType.ended then
			local left_zuhe = self:getZuheForce(self.dataTb.left_front_tb,self.dataTb.left_back_tb)
			local right_zuhe = self:getZuheForce(self.dataTb.right_front_tb,self.dataTb.right_back_tb)

			self:onForceTest(left_zuhe,right_zuhe)
		end
	end)

	view.btnStartSolo:addTouchEventListener(function(sender, eventType)
		if eventType == ccui.TouchEventType.ended then
			local leftFightForce = {}
			local rightFightForce = {}
			for _,v in ipairs(self.dataTb.left_front_tb) do
				table.insert(leftFightForce,v)
			end

			for _,v in ipairs(self.dataTb.left_back_tb) do
				table.insert(leftFightForce,v)
			end

			for _,v in ipairs(self.dataTb.right_front_tb) do
				table.insert(rightFightForce,v)
			end

			for _,v in ipairs(self.dataTb.right_back_tb) do
				table.insert(rightFightForce,v)
			end

			if table.length(leftFightForce) <= 0 or table.length(rightFightForce) <= 0 then return end

			local fightRoleOut = {}

			for _,v in ipairs(leftFightForce) do
				for _,v2 in ipairs(rightFightForce) do
					local newRoleOut = {}
					newRoleOut[1] = v
					newRoleOut[7] = v2
					table.insert(fightRoleOut,newRoleOut)
				end
			end

			local leftWin,rightWin = 0,0
			local oldTime = socket.gettime()
			local i = 1
			while true do
				if i > #fightRoleOut then break end
				if socket.gettime() - oldTime >= 0.2 then
					MultiForce.requestFightSolo(self,fightRoleOut[i],i,function(ret,t,roleOut,idx)
						if ret.ret then
							local fightPvp = roleOut
							print("----------------------------------------")
							print("第"..tostring(idx).."场")
							for k,v in pairs(fightPvp) do
								if k == 7 then
									print("vs")
								end
								print(csvCards[v.card_id].name.." ")
							end
							print("\n")
							print("结果:"..t.result[1].."\n")
							print("积分:"..t.result[2].." vs "..t.result[3])
							if t.result[1] == "win" then
								leftWin = leftWin + 1
							else
								rightWin = rightWin + 1
							end
						else
							print("----------------------------------------")
							print("第"..tostring(idx).."场")
							print("结果失败")
						end
						print("\n")
						print("总场次:"..tostring(leftWin+rightWin).." 左胜:"..tostring(leftWin).." 右胜:"..tostring(rightWin))
					end)
					i = i + 1
					oldTime = socket.gettime()
				end
			end

		end
	end)

	-- view.btnSaveForce:addTouchEventListener(function(sender, eventType)
	-- 	if eventType == ccui.TouchEventType.ended then
	-- 		local file = io.open(__TestDefine.ReadRecordFolderPath..string.format("\\%s.txt","test_force"),"a")

	-- 		file:write("左队前排\t\t左队后排\t\t右队前排\t\t右队后排\n")

	-- 		local maxNum = 10
	-- 		local forceStr = {"left_front","left_back","right_front","right_back"}
	-- 		for i=1,maxNum do
	-- 			for j=1,4 do
	-- 				if self.unitTb[forceStr[j].."_tb"][i] then
	-- 					file:write(tostring(self.unitTb[forceStr[j].."_tb"][i].unitID).."\t\t")
	-- 				else
	-- 					file:write("\t\t\t")
	-- 				end
	-- 			end
	-- 			file:write("\n")
	-- 		end
	-- 	end
	-- end)
end
--]] ------------------------------ End -------------------------------

---[[ ---------------------------- 注册事件 ----------------------------
function TestChooseCardView:addGameObject(_prefab)
	self.gate:addGameObject(_prefab)
end
-- 添加资源到库
-- @param roleId string csv.unit 上的id
-- @param extraData table 类test_battle上的数值
function TestChooseCardView:addRes(roleId,extraData)
	if roleId and not self.resources[roleId] then
		local _prefab = Prefab.new(self.prefab:clone())

		local itemNode = _prefab.node
		local lerpPos,limit = cc.p(10,2),3
		local startPos = cc.p(itemNode:size().width/2+lerpPos.x
			,itemNode:size().height/2+lerpPos.y)

		self:addItemToScrollView(self.prefabs,itemNode,lerpPos,startPos,limit)

		itemNode:onTouch(functools.handler(self,self.dragSprite,_prefab))
		itemNode:get("add"):addClickEventListener(functools.handler(self,self.addGameObject,_prefab))
		itemNode:get("del"):addClickEventListener(functools.handler(self,self.delRes,_prefab))

		_prefab:init(roleId,extraData or clone(DefaultAttr))
		self.resources[roleId] = _prefab
	end
end
-- 删除资源
-- @param _prefab Prefab 资源单位
function TestChooseCardView:delRes(_prefab)
	if self.lastClickObj and self.lastClickObj.id == _prefab.id then
		self.lastClickObj = nil
		self:showAttr()
	end
	self:delItemFromScrollView(self.prefabs,_prefab.node)
	self.resources[_prefab.roleId] = nil
	_prefab:clean()
end

-- 删除单位从滚动容器
-- @param _parent Node 单位父节点
-- @param delNode Node 删除的节点
function TestChooseCardView:delItemFromScrollView(_parent,delNode)
	if self.lastClickObj and self.lastClickObj.node:name() == delNode:name() then
		self.lastClickObj = nil
	end

	local lastPos
	for k,node in ipairs(_parent:getChildren()) do
		print("delItemFromScrollView",node:name())
		if lastPos then
			local pos = cc.p(node:x(),node:y())
			node:xy(lastPos.x,lastPos.y)
			lastPos = pos
		end

		if node:name() == delNode:name() then
			print("del sprite ",delNode:name(),k)
			lastPos = cc.p(node:x(),node:y())
		end
	end
end

-- 添加单位到滚动容器
-- @param _parent Node 单位父节点
-- @param addNode Node 添加的节点
-- @param lerpPos cc.p 节点之间的间隔
-- @param startPos cc.p 节点的起始位置
-- @param limit int 垂直方向限制的个数
function TestChooseCardView:addItemToScrollView(_parent,addNode,lerpPos,startPos,limit)
	local width = addNode:size().width*addNode:scaleX()
	local height = addNode:size().height*addNode:scaleY()
	local posX,posY = 0,0

	local index = _parent:getChildrenCount()
	if _parent == self.gameObjects then
		index = self.gate:getGameObjectIndex(index)
	end

	_parent:addChild(addNode)
	posX = startPos.x + math.modf(index/limit) * (width + lerpPos.x)
	posY = _parent:height() - startPos.y - math.fmod(index,limit) * (height + lerpPos.y)
	addNode:xy(posX,posY)
	--addNode:z(_parent:height() - posY)
	return addNode
end

-- 只显示选择目标
-- @param _parent Node 单位父节点
function TestChooseCardView:onlyShowSelect(_parent,_view)
	if _view and _view.selectShowChild then
		if self.lastClickObj and self.lastClickObj.id == _view.id then return end

		for _,name in ipairs(_view.selectShowChild) do
			_view.node:get(name):visible(true)
		end

		if self.lastClickObj and not tolua.isnull(self.lastClickObj.node) then
			for _,name in ipairs(self.lastClickObj.selectShowChild) do
				self.lastClickObj.node:get(name):visible(false)
			end
		end

		self.lastClickObj = _view
		self:showAttr(_view)
		local showPassiveSkills = _view.roleData["passive_skills"]
			if showPassiveSkills then
				local unitName = csv.unit[_view.roleId].name
				local skillListInfo = unitName .. "  [upd skill] skillList passive_skills    "
				for k, v in pairs(showPassiveSkills) do
					skillListInfo = skillListInfo .. k .. "=" .. v .. ";"
				end
				print(skillListInfo)
				dump(showPassiveSkills)
			end
	end
end
-- 拖拽精灵注册事件
function TestChooseCardView:dragSprite(_prefab,event)
	local beganPos
	if event.name == "began" then
		self.dragSpriteNow.collider = nil
		self:onlyShowSelect(self.prefabs,_prefab)
		beganPos = event.target:getTouchBeganPosition()
	elseif event.name == "moved" then
		local icon = self.dragSpriteNow:get("icon")
		local movePos = event.target:getTouchMovePosition()
		local rect = self.dragSpriteNow.collider and self.dragSpriteNow.collider:getRect() or nil
		if not icon then
			local cardSprite = widget.addAnimation(self.dragSpriteNow, _prefab.unit.unitRes, "standby_loop", 5)
				:name("icon")
				:anchorPoint(0.5, 1)
				:xy(0, 10)
				:scale(1)
			cardSprite:setSkin(_prefab.unit.skin)
		end
		self.dragSpriteNow:xy(movePos.x,movePos.y)
		if cc.rectContainsPoint(self.gameObjectsRect,movePos) then
			if rect and cc.rectContainsPoint(rect,movePos) then return end
			for k,_gameObject in ipairs(self.gate.scene) do
				rect = _gameObject:getRect()
				if cc.rectContainsPoint(_gameObject:getRect(),movePos) then
					self.dragSpriteNow.collider = _gameObject
					self.drawNode:clear()
					self.drawNode:drawRect(cc.p(rect.x,rect.y),cc.p(rect.x+rect.width,rect.y+rect.height),cc.c4f(1, 0, 0, 1))
					return
				end
			end
		end
		self.drawNode:clear()
		self.dragSpriteNow.collider = nil
	elseif event.name == "ended" or event.name == "cancelled" then
		local icon = self.dragSpriteNow:get("icon")
		local movePos = event.target:getTouchMovePosition()
		if self.dragSpriteNow.collider then
			self.dragSpriteNow.collider:init(self.dragSpriteNow.collider.index,self.dragSpriteNow.collider.seat,_prefab)
			self.drawNode:clear()
			self.dragSpriteNow.collider = nil
		end
		if icon then
			icon:removeFromParent()
		end
	end
end

function TestChooseCardView:showAttr(_view)
	if not _view then
		self.attrView:removeAllChildren()
		return
	end
--    local ParseData = function(name,value)
--        local _type = type(value)
--        if _type == "table" then
--            for k,v in csvMapPairs(value) do

--            end
--        else
--            local len = string.len(tostring(value)) + 3
--            return ccui.EditBox:create(cc.size(len*8,24), "img/editor/input.png"),1
--        end
--    end
	self.attrView:removeAllChildren()
	local roleData = _view:getRoleData()
	local node,head = {},{}
	local defaultValue
	if roleData then
		for k,v in csvMapPairs(roleData) do
			if type(v) ~= "table" and NeedShowAttr[k] then
				local attrName = k
				defaultValue = DefaultAttr[k]
				node = self.attrItem:clone()
				head = node:get("head")
					:text(k .. ": ")
				node:get("edit")
					:setPlaceHolder(defaultValue)
					:addEventListener(function(sender, eventType)
					if eventType == 2 or eventType == 3 then
						local result,count = string.gsub(sender:text(), "[^%d]", "")
						if count > 0 then
							 sender:text(result)
							 return
						end
						result = result == "" and DefaultAttr[attrName] or tonumber(result)
						result = math.max(result,0)
						print("[upd Attr]attr value ",attrName,result)
						_view.roleData[attrName] = result
					end
				end)

				if defaultValue ~= v then
					node:get("edit"):text(v)
				end

				self.attrView:pushBackCustomItem(node)

				node:get("edit")
					:x(head:width() + head:x() + 10)
			end
		end

		-- 更改携带道具用 begin
		local k = "passive_skills"
		local v = roleData[k] or {}
		local passiveSkillStr = ""
		local unitName = csv.unit[_view.roleId].name
		for skillId, skillLevel in pairs(v) do
			if passiveSkillStr == "" then
				passiveSkillStr = string.format("%s=%s;", skillId, skillLevel)
			else
				passiveSkillStr = string.format("%s%s=%s;",passiveSkillStr, skillId, skillLevel)
			end
		end
		node = self.attrItem:clone()
		head = node:get("head")
			:text(k .. ": ")
		node:addTouchEventListener(function(sender, eventType)
			if eventType == ccui.TouchEventType.ended then
				self:createPassiveSkillList(sender, _view)
			end
		end)
		node:get("edit")
			:setPlaceHolder("1234")
			:addEventListener(function(sender, eventType)
			if eventType == 2 or eventType == 3 then
				local result = sender:text()
				print(unitName .. "  [upd skill] skillList",k,result)
				local skills = string.split(result, ";")
				local newSkills = {}
				for _, oneSkillStr in ipairs(skills) do
					local info = string.split(oneSkillStr,"=")
					if info[1] and info[2] then
						newSkills[tonumber(info[1])] = tonumber(info[2])
					end
				end
				dump(newSkills)
				_view.roleData[k] = newSkills
			end
		end)
		if passiveSkillStr ~= "1234" then
			node:get("edit"):text(passiveSkillStr)
		end
		self.attrView:pushBackCustomItem(node)
		node:get("edit")
			:x(head:width() + head:x() + 10)
		-- 更改携带道具用 over

		node = self.attrItem:clone()
		head = node:get("head")
			:text("name")
		node:get("edit"):text(_view.node:name())
		self.attrView:pushBackCustomItem(node)
		node:get("edit")
			:x(head:width() + head:x() + 10)

		return
	end
end

function TestChooseCardView:createPassiveSkillList(attrNode, _view)
	local view = EasyView.initBaseView(self)
	local passiveSkillStr = ""
	local k = "passive_skills"
	local newView = self.attrView:clone()
	newView:anchorPoint(cc.p(0.5,0.5))
	newView:x(view.root:width()/2)
	newView:y(view.root:height()/2)
	view.root:addChild(newView)

	local function writeData()
		attrNode:get("edit"):text(passiveSkillStr)
		local skills = string.split(passiveSkillStr, ";")
		local newSkills = {}
		for _, oneSkillStr in ipairs(skills) do
			local info = string.split(oneSkillStr,"=")
			if info[1] and info[2] then
				newSkills[tonumber(info[1])] = tonumber(info[2])
			end
		end
		_view.roleData[k] = newSkills
	end

	local function createAllAttr()
		local roleData = _view:getRoleData()
		local v = roleData[k] or {}
		newView:removeAllChildren()
		passiveSkillStr = ""
		for skillId, skillLevel in pairs(v) do
			if passiveSkillStr == "" then
				passiveSkillStr = string.format("%s=%s;", skillId, skillLevel)
			else
				passiveSkillStr = string.format("%s%s=%s;",passiveSkillStr, skillId, skillLevel)
			end
			local panel = ccui.Layout:create():size(500,60):anchorPoint(cc.p(0,0.5))
			local txt = ccui.Text:create(string.format("%s=%s;", skillId, skillLevel),"font/youmi1.ttf", 35):anchorPoint(cc.p(0,0.5)):addTo(panel):x(0):y(0)
			local delBtn = self.prefab:get("del"):clone():addTo(panel):anchorPoint(cc.p(0.5,0.5)):x(400):y(0):setVisible(true):scale(0.5)
			newView:pushBackCustomItem(panel)
			delBtn:addClickEventListener(function()
				passiveSkillStr = string.gsub(passiveSkillStr, string.format("%s=%s;", skillId, skillLevel), "")
				writeData()
				createAllAttr()
			end)
		end
	end

	EasyView.addBtnListToView(
		view,
		{"btnClose|关闭","btnAdd|添加数据"},
		cc.p(self.stage:width()/2,100),
		EasyView.CustomBtnType.Center
	)

	view.btnAdd:addTouchEventListener(function(sender, eventType)
		if eventType == ccui.TouchEventType.ended then
			local newText = view.editBox[1]:getText()
			view.editBox[1]:setText("")
			local info = string.split(newText,"=")
			if info[1] and info[2] then
				passiveSkillStr = passiveSkillStr .. newText .. ";"
			end
			writeData()
			createAllAttr()
		end
	end)

	EasyView.addInputControl(
		view,
		cc.p(self.stage:width()/2,200),
		cc.EDITBOX_INPUT_MODE_ANY,
		"skillId=skillLevel",
		1
	)

	createAllAttr()
end

function TestChooseCardView:showRecordView()
	-- self.recordView
	-- 测试界面
	self:onBtnLoadRecord(nil, nil, {listView = self.recordView})
end

--]] ------------------------------ End -------------------------------

---[[ ---------------------------- 其他功能 ----------------------------
-- 获得战斗布阵信息
function TestChooseCardView:getFightRoleData()
	local setValue = function(val,rate)
		return val and val*rate or rate
	end

	local addValue = function(val,rate)
		val = val or 0
		return val + rate
	end

	local getRoleData = function(data,seat)
		 if self.btnRecordData["attrAdd"] then
			if (seat >= 1 and seat <= 3) or (seat >=7 and seat <= 9) then
				data.hp = setValue(data.hp,1.1)
				data.damageSub = addValue(data.damageSub,1000)
--                data.strikeResistance = addValue(data.strikeResistance,600)
			else
				data.damageAdd = addValue(data.damageAdd,1000)
				data.specialDamage = setValue(data.specialDamage,1.1)
				data.damage = setValue(data.damage,1.1)
--                data.strike = addValue(data.strike,600)
			end
		end

		local attrAdd
		if ((seat >= 1 and seat <= 6 ) and self.leftAttrAdd ~= 1) then
			attrAdd = self.leftAttrAdd
		elseif ((seat >= 7 and seat <= 12) and self.rightAttrAdd ~= 1) then
			attrAdd = self.rightAttrAdd
		end

		if attrAdd then
			data.hp = setValue(data.hp, attrAdd)
			data.damage = setValue(data.damage, attrAdd)
			data.specialDamage = setValue(data.specialDamage, attrAdd)
			data.defence = setValue(data.defence, attrAdd)
			data.specialDefence = setValue(data.specialDefence, attrAdd)
		end

		return data
	end
	local data,typ = self.gate:getFightRoleData()
	for _,dataTab in ipairs(data) do
		for k,v in pairs(dataTab) do
			dataTab[k] = getRoleData(v,k)
		end
	end
	return data,typ
end
-- 储存需要初始化的数据
function TestChooseCardView:saveInitData()
	local data = {
		_scene = {},
		_resources = {},
		_fightType = self.fightType,
		_debug = tjdebug.isenable(),
		_btnRecordData = self.btnRecordData, -- 按钮状态存储
		_gameEnvData = self.gameEnvData
	}
	for k,_prefab in pairs(self.resources) do
		data._resources[k] = {
			roleId = _prefab.roleId,
			extraData = _prefab:getRoleData()
		}
	end

	for k,_gameObject in pairs(self.gate.scene) do
		local _roleData = _gameObject:getRoleData()
		if _roleData then
			data._scene[k] = {
				index = _gameObject.index,
				_prefab = {
					roleId = _roleData.roleId,
					data = _roleData,
					getRoleData = function(_self)
						return _self.data
					end
				}
			}
		end
	end

	return data
end

local function fakeModel()
	-- 假造数据，防止报错
	if gGameModel.role.__idlers == nil then
		gGameModel.role:init({_db = {
			id = "1111111",
			name = 'test',
			level = 99,
			level_exp = 1,
			sum_exp = 1,
			vip_level = 15,
			yy_delta = {},
			yy_endtime = 0,
			yyhuodongs = {},
			gate_star = {},
			logos = {},
			pokedex = {},
			figures = {},
			skins = {},
			trainer_level = 1,
			trainer_skills = {},
			gate_star = {
				[10102] = {star = 3},
				[10105] = {star = 3},
			},
			top_cards = {}
		}})
	end
	if gGameModel.capture.__idlers == nil then
		gGameModel.capture:init({_db = {
			limit_sprites = {},
		}})
	end
	if gGameModel.random_tower.__idlers == nil then
		gGameModel.random_tower:init({_db = {
			buffs = {},
			skill_used = {}
		}})
	end
	gGameModel.hunting =  require("app.models.hunting").new(self)
	if gGameModel.hunting.__idlers == nil then
		gGameModel.hunting:init({_db = {
			hunting_route = {
				[1] = {
					buffs = {}
				},
				[2] = {
					buffs = {}
				}}
		}})
	end
end

function TestChooseCardView:parseBattle(name,data)
	local battle
	-- print("parseBattle",name)

	if name == 'craft' then
		self:changeFightType(FightType.Craft)
		battle = require('app.models.craft_battle').new(gGameModel):init(data)
	elseif name == 'arena'then
		self:changeFightType(FightType.Normal)
		battle = require('app.models.arena_battle').new(gGameModel):init(data)
	elseif name == 'gate' then
		self:changeFightType(FightType.Normal)
		battle = require("app.models.battle").new(gGameModel):init(data)
		battle.result = "fail"
	elseif name == 'union_fight' then
		self:changeFightType(FightType.Normal)
		battle = require('app.models.union_fight_battle').new(gGameModel):init(data)
	elseif name == 'cross_craft' or name == 'crosscraft' then
		self:changeFightType(FightType.Craft)
		battle = require('app.models.cross_craft_battle').new(gGameModel):init(data)
	elseif name == 'cross_arena' or name == 'crossarena' then
		self:changeFightType(FightType.CrossArena)
		battle = require('app.models.cross_arena_battle').new(gGameModel):init(data)
	elseif name == 'cross_mine' or name == 'crossmine' then
		self:changeFightType(FightType.CrossMine)
		battle = require('app.models.cross_mine_battle').new(gGameModel):init(data)
	else
		error(name .. " not defined")
	end

	fakeModel()

	local data = battle:getData()
	if data.preData and data.preData.cardsInfo then
		data.preData.cardsInfo = {}
	end
	return data
end

function TestChooseCardView:runGameLogicByRoleOut(roleOut,time,runOnceCall)
	local winTimes = 0
	local loseTimes = 0
	-- local str = "vs"
	-- for _seat,_temp in pairs(roleOut) do
	--     local name = csvUnits[_temp.roleId].name
	--     str = _seat > 6 and string.format("%s %s",str,name) or string.format("%s %s",name,str)
	-- end
	local log = function(...)
		print(...)
	end

	local braveChallengeMonster = nil
	self.gameEnvData.roleOut = roleOut
	local roleOutStr = ""
	local roleExSkillStr = ""
	if self.fightType == FightType.CrossArena then
		roleOutStr = getMultiTeamRoleOutStr(roleOutStr, roleOut, 2)
	elseif self.fightType == FightType.CrossMine then
		roleOutStr = getMultiTeamRoleOutStr(roleOutStr, roleOut, 3)
	else
		for i=1,12 do
			if i == 7 then
				roleOutStr = roleOutStr .. "  vs  "
				roleExSkillStr = roleExSkillStr .. "  vs  "
			end
			if roleOut[i] then
				if self.fightType == FightType.BraveChallenge then
					braveChallengeMonster = braveChallengeMonster or roleOut[i].key
				end
				roleOutStr = string.format("%s %s(%d)",roleOutStr,csv.unit[roleOut[i].roleId].name, roleOut[i].roleId)
				roleExSkillStr = string.format("%s %s",roleExSkillStr,roleOut[i].ex_skills and roleOut[i].ex_skills[1])
			end
		end
	end

	if braveChallengeMonster then
		print(string.format("\n\n\n\n\n当前正在进行的: csv brave_challenge/monster ID: %d", braveChallengeMonster))
		print(roleOutStr)
		print(roleExSkillStr)

		-- local filename = string.format("%s_%s.record", "braveChallenge", os.date("%y%m%d-%H%M%S"))
		-- local fp = io.open(filename, 'wb')
		-- local outPutData = msgpack(self.gameEnvData)
		-- fp:write(outPutData)
		-- fp:close()
	end

	for i=1,time do
		-- 测试增加对速度的随机处理
		-- self.gameEnvData.roleOut = clone(roleOut)
		-- for k, v in pairs(self.gameEnvData.roleOut) do
		--	v.speed = math.random(0.5, 1.5) * v.speed
		-- end
		self.gameEnvData.closeRandFix = __TestDefine.closeRandFix
		local curResult

		-- 勇者挑战检测报错 保存战报
		local function getCurResult()
			return battleEntrance.battleRecord(self.gameEnvData, {}, {fromRecordFile=true}):run()
		end
		if braveChallengeMonster then
			local status, msg = xpcall(getCurResult, __G__TRACKBACK__)
			curResult = msg
			if not status then
				print('xpcall game main error', status, msg)
				local filename = string.format("%s_%s.record", "braveChallenge", os.date("%y%m%d-%H%M%S"))
				local fp = io.open(filename, 'wb')
				local outPutData = msgpack(self.gameEnvData)
				fp:write(outPutData)
				fp:close()
			end
		end

		curResult = getCurResult()
		if curResult.result == "win" then
			winTimes = winTimes + 1
		elseif curResult.result == "fail" then
			loseTimes = loseTimes + 1
		end
		if runOnceCall then
			runOnceCall({
				time = i,
				result = curResult.result,
				win = winTimes,lose = loseTimes,
				seed = self.gameEnvData.randSeed,
			})
		end
		log(string.format("[INFO] RunTime: (%d/%d), Seed: %d",i,time,self.gameEnvData.randSeed))
		self.gameEnvData.randSeed = math.random(1, 100000)
		log(string.format("[INFO] 当前胜局比:  %d vs %d",winTimes,loseTimes), roleOutStr)
		table.insert(__TestDefine.allHistoryBattleInfo,__TestDefine.historyBattleInfo[1])
	end

	-- 记录胜负情况
	local result = "draw"
	if winTimes > loseTimes then result = "win"
	elseif winTimes < loseTimes then result = "fail" end
	if __TestDefine.historyBattleInfo[1] then
		for k, v in pairs(__TestDefine.historyBattleInfo[1]) do
			if k > 6 then
				if result == "win" then v.result = "fail"
				elseif result == "fail" then v.result = "win"
				else v.result = result end
			else v.result = result end
		end
	end
	table.insert(self.battleResultInfo, "[INFO]"..roleOutStr)
	table.insert(self.battleResultInfo, string.format("[INFO] 总战斗测试次数: %d (%d vs %d)    胜率: %d%s",time,winTimes,loseTimes,math.floor(100 * winTimes/time), "%"))
end

function TestChooseCardView:runGameLogicByRoleOutLessTime(roleOut,time,runOnceCall)
	-- local str = "vs"
	-- for _seat,_temp in pairs(roleOut) do
	--     local name = csvUnits[_temp.roleId].name
	--     str = _seat > 6 and string.format("%s %s",str,name) or string.format("%s %s",name,str)
	-- end
	local log = function(...)
		print(...)
	end

	self.gameEnvData.roleOut = roleOut
	local roleOutStr = ""
	if self.fightType == FightType.CrossArena then
		roleOutStr = getMultiTeamRoleOutStr(roleOutStr, roleOut, 2)
	elseif self.fightType == FightType.CrossMine then
		roleOutStr = getMultiTeamRoleOutStr(roleOutStr, roleOut, 3)
	else
		for i=1,12 do
			if i == 7 then roleOutStr = roleOutStr .. "\tvs\t" end
			if roleOut[i] then
				roleOutStr = string.format("%s %s(%d)",roleOutStr,csv.unit[roleOut[i].roleId].name,i)
			end
		end
	end

	for i=1,time do
		log(string.format("[INFO] RunTime: (%d/%d), Seed: %d",i,time,self.gameEnvData.randSeed))
		self.gameEnvData.closeRandFix = __TestDefine.closeRandFix
		battleEntrance.battleRecord(self.gameEnvData, {}, {fromRecordFile=true})
			:timeLimit(5)
			:run()

		self.gameEnvData.randSeed = math.random(1, 100000)

		table.insert(__TestDefine.allHistoryBattleInfo,__TestDefine.historyBattleInfo[1])
	end

	log(roleOutStr)
end

function TestChooseCardView:createTestSceneData()
	fakeModel()
	self.gameEnvData = self.gameEnvData or {
		sceneID = __TestDefine.TestSceneID,
		randSeed = math.random(1, 1000000),
		roleLevel = 1,
		talents = {{},{}},
		fightgoVal = {0,0},
		gateFirst = true,
		gateType = game.GATE_TYPE.test,
		-- 战斗选择类型默认为 1: 常规  2: 全手动
		moduleType = 1,
	}

	if self.fightType == FightType.CrossMine then
		if not self.gameEnvData.role_key then
			self.gameEnvData.role_key = {"cn.dev.1"}
			self.gameEnvData.defence_role_key = {"cn.dev.1"}
		end
	end
end

--]] ------------------------------ End -------------------------------

---[[ ---------------------------- 数据监控 ----------------------------

-- local env_base = {
--     __index = function(s,k)
--     	if s.t[k] then
--     		return s.t[k]
--     	end
--     	return s.h[k]
--     end,
--     __newindex = function(s,k,v)
--     	if k:match("_t") then
--     		s.t[string.sub(k,1,-3)] = v
--     	else
--     		s.h[k] = v
--     	end
--     end,
-- }
-- local env = setmetatable({
--     t = {},
--     h = {},
--     clean = function(_self)
--     	_self.t = {}
-- 	end,
--     cleanAll = function(_self)
--         _self:clean()
--     	_self.h = {}
-- 	end,
-- }, env_base)

function TestChooseCardView:monitorBattleInfo()

	-- __TestProtocol["SceneModel/newWave"] = function(self,state,raw,...)
	--     local args = {...}
	--     if state == __TestDefine.CallState.enter then
	--         if raw.play.curWave == 0 then return end
	--         local curWave = raw.play.curWave
	--         __TestDefine.historyBattleInfo[curWave] = {}
	--         for i=1,12 do
	--             local obj = raw:getObject(i)
	--             if obj then
	--                 __TestDefine.historyBattleInfo[curWave][i] = __TestEasy.toObject(obj)
	--                 __TestDefine.historyBattleInfo[curWave][i].totalDamage = obj.totalDamage
	--                 __TestDefine.historyBattleInfo[curWave][i].totalResumeHp = obj.totalResumeHp
	--                 __TestDefine.historyBattleInfo[curWave][i].totalTakeDamage = obj.totalTakeDamage
	--             end
	--         end
	--     elseif state == __TestDefine.CallState.exit then
	--     end
	-- end


	-- local callList = {}
	-- local newMonitor = function(name,call)
	--     tjdebug.includeCall(name)
	--     callList[name] = call
	-- end
	-- tjdebug.disable()
	-- tjdebug.includeFile("battle/models/object.lua")
	-- newMonitor("beAttack",function(callInfo)
	--     if callInfo.typ == "call" then
	--         local params = callInfo.params
	--         env.self_t = params.self
	--         env.hp_t = params.self:hp()
	--         env.damageFrom_t = params.damageArgs.from
	--         env.attacker_t = params.attacker
	--         -- 统计伤害
	--     elseif callInfo.typ == "return" and env.self then
	--         local damage = env.hp  - env.self:hp()
	--         --custom_plugin.send(1,{str = damage})
	--         env.recordDamage = env.recordDamage or {}
	--         env.recordTakeDamage = env.recordTakeDamage or {}
	--         if env.attacker then
	--             local attackerId = env.attacker.id
	--             local damageArray = env.recordDamage[attackerId] or {}
	--             damageArray[env.damageFrom] = damageArray[env.damageFrom] or 0
	--             damageArray[env.damageFrom] = damageArray[env.damageFrom] + math.floor(damage)
	--             env.recordDamage[attackerId] = damageArray
	--         end
	--         env.recordTakeDamage[env.self.id] = env.recordTakeDamage[env.self.id] or 0
	--         env.recordTakeDamage[env.self.id] = env.recordTakeDamage[env.self.id] + math.floor(damage)
	--     end
	-- end)
	-- newMonitor("resumeHp",function(callInfo)
	--     if callInfo.typ == "call" then
	--         local params = callInfo.params
	--         env.self_t = params.self
	--         env.hp_t = params.self:hp()
	--         env.resumeFrom_t = params.args.from
	--         env.casteId_t = params.args.casterId
	--         -- 统计伤害
	--     elseif callInfo.typ == "return" and env.self then
	--         local resumeHp = env.self:hp() - env.hp
	--         env.recordResumeHp = env.recordResumeHp or {}
	--         if env.casteId then
	--             local casteId = env.casteId
	--             local resumeArray = env.recordResumeHp[casteId] or {}
	--             resumeArray[env.resumeFrom] = resumeArray[env.resumeFrom] or 0
	--             resumeArray[env.resumeFrom] = resumeArray[env.resumeFrom] + math.floor(resumeHp)
	--             env.recordResumeHp[casteId] = resumeArray
	--         end
	--     end
	-- end)
	-- newMonitor("processRealDeath",function(callInfo)
	--     if callInfo.typ == "call" then
	--         local params = callInfo.params
	--         env.self_t = params.self
	--         -- 统计伤害
	--     elseif callInfo.typ == "return" and env.self then
	--         local attackerId = env.self.attackMeDeadObj.id
	--         env.recordKill = env.recordKill or {}
	--         env.recordKill[attackerId] = env.recordKill[attackerId] or 0
	--         env.recordKill[attackerId] = env.recordKill[attackerId] + 1
	--     end
	-- end)
	-- -- tjdebug.includeFile("battle/models/play/gate.lua")
	-- newMonitor("newWaveAddObjsStrategy",function(callInfo)
	--     if callInfo.typ == "call" then
	--         env.self_t = callInfo.params.self
	--     elseif callInfo.typ == "return" then
	--         __TestDefine.historyBattleInfo[1] = {}
	--         local info = {}
	--         for i=1,12 do
	--             local obj = env.self.scene:getObject(i)
	--             if obj then
	--                 info["name"] = info["name"] or { v = {}, priority = 1 }
	--                 info["id"] = info["id"] or { v = {}, priority = 2 }
	--                 info["name"].v[i] = obj.unitCfg.name
	--                 info["id"].v[i] = obj.id
	--             end
	--         end
	--         print("save __TestDefine.historyBattleInfo role !!!!!!!!!!!!!!!!!!!!!")
	--         __TestDefine.historyBattleInfo[1] = info
	--     end
	-- end)
	-- newMonitor("onBattleEndSupply",function(callInfo)
	--     if callInfo.typ == "call" then
	--         env.self_t = callInfo.params.self
	--     elseif callInfo.typ == "return" then
	--         local info = __TestDefine.historyBattleInfo[1]
	--         local priority = 3
	--         local name
	--         -- 回合数
	--         info[string.format("---Round %d/%d---",env.self.curRound,env.self.roundLimit)] = { priority = 1 }
	--         -- 伤害总量
	--         priority = priority + 1
	--         info["---Damage Strart---"] = { priority = priority }
	--         info["totalDamage"] = { v = {} , priority = 0 }
	--         for k,v in pairs(battle.DamageFrom) do
	--             priority = priority + 1
	--             name = "Dmg/".. k
	--             info[name] = { v = {} , priority = priority }
	--             for i=1,12 do
	--                 if env.recordDamage[i] then
	--                     info[name].v[i] = env.recordDamage[i][v] or 0
	--                     info["totalDamage"].v[i] = info["totalDamage"].v[i] or 0
	--                     info["totalDamage"].v[i] = info["totalDamage"].v[i] + info[name].v[i]
	--                 end
	--             end
	--         end
	--         priority = priority + 1
	--         info["totalDamage"].priority = priority

	--         -- 治疗量
	--         priority = priority + 1
	--         info["---ResumeHp Strart---"] = { priority = priority }
	--         info["totalResumeHp"] = { v = {} , priority = 0 }
	--         for k,v in pairs(battle.ResumeHpFrom) do
	--             priority = priority + 1
	--             name = "Rhp/".. k
	--             info[name] = { v = {} , priority = priority }
	--             for i=1,12 do
	--                 if env.recordResumeHp[i] then
	--                     info[name].v[i] = env.recordResumeHp[i][v] or 0
	--                     info["totalResumeHp"].v[i] = info["totalResumeHp"].v[i] or 0
	--                     info["totalResumeHp"].v[i] = info["totalResumeHp"].v[i] + info[name].v[i]
	--                 end
	--             end
	--         end
	--         priority = priority + 1
	--         info["totalResumeHp"].priority = priority

	--         priority = priority + 1
	--         info["-------Other-------"] = { priority = priority }
	--         priority = priority + 1
	--         info["totalTake"] = { v = {} , priority = priority }
	--         priority = priority + 1
	--         info["kill"] = { v = {} , priority = priority }
	--         priority = priority + 1
	--         info["result"] = { v = {} , priority = priority }
	--         for i=1,12 do
	--             if info["id"].v[i] then
	--                 local result = ((env.self.result == "win" and i <= 6)
	--                     or (env.self.result == "fail" and i > 6)) and "win" or "fail"
	--                 info["result"].v[i] = result
	--             end
	--             -- 杀人数
	--             info["kill"].v[i] = env.recordKill[i] or 0
	--             -- 承受伤害
	--             if env.recordTakeDamage[i] then
	--                 -- info[name].v[i] = env.recordTakeDamage[i][v] or 0
	--                 info["totalTake"].v[i] = info["totalTake"].v[i] or 0
	--                 info["totalTake"].v[i] = info["totalTake"].v[i] + env.recordTakeDamage[i]
	--             end
	--         end
	--         -------------------------------------------------------------------------------
	--         local _info = {}
	--         for k,data in pairs(info) do
	--             _info[#_info + 1] = {head = k,v = data.v,priority = data.priority}
	--         end
	--         table.sort(_info,function(a,b)
	--             return a.priority < b.priority
	--         end)
	--         print("save __TestDefine.historyBattleInfo result !!!!!!!!!!!!!!!!!!!!!")
	--         __TestDefine.historyBattleInfo[1] = __TestDefine.historyBattleInfo[1] or {}
	--         __TestDefine.historyBattleInfo[1] = _info
	--         env:cleanAll()
	--     end
	-- end)

	--tjdebug.enable()
	-- tjdebug.custom("cr",function(name,callInfo)
	--      if callList[name] then
	--          callList[name](callInfo)
	--          if callInfo.typ == "return" then
	--              env:clean()
	--          end
	--      end
	--  end)

end

function TestChooseCardView:updateMultiForceAttrView( info,attrView )
	attrView:removeAllChildren()
	local node,head = {},{}

	if info.unitInfo then
		node = self.attrItem:clone()
		head = node:get("head"):text(info.unitInfo.name)
	end

	for k,v in pairs(info.attrInfo) do
		local attrName = k
		node = self.attrItem:clone()
		head = node:get("head"):text(k .. ": ")

		node:get("edit")
			:setPlaceHolder(v)
			:addEventListener(function(sender, eventType)
			if eventType == 2 or eventType == 3 then
				local result,count = string.gsub(sender:text(), "[^%d]", "")
				if count > 0 then
					sender:text(result)
					return
				end
				result = result == "" and 1 or tonumber(result)
				result = math.max(result,0)
				print("[upd Attr]attr value ",attrName,result)
				attrInfo[attrName] = result
			end
		end)

		node:setScale(1.5)
		-- if defaultValue ~= v then
			node:get("edit"):text(v)
		-- end

		attrView:pushBackCustomItem(node)

		node:get("edit")
			:x(head:width() + head:x() + 10)
	end
end

function TestChooseCardView:onForceTest( leftFightForce,rightFightForce )
	local fightRoleOut = {}

	for _,left in ipairs(leftFightForce) do
		for _,right in ipairs(rightFightForce) do
			local newRoleOut = {}
			for _,v in ipairs(left) do
				table.insert(newRoleOut,v)
			end
			for _,v2 in ipairs(right) do
				table.insert(newRoleOut,v2)
			end

			table.insert(fightRoleOut,newRoleOut)
		end
	end

	local leftWin,rightWin = 0,0
	local oldTime = socket.gettime()
	local i = 1
	while true do
		if i > #fightRoleOut then break end
		if socket.gettime() - oldTime >= 0.2 then
			MultiForce.requestFight(self,fightRoleOut[i],i,function(ret,t,roleOut,idx)
				if ret.ret then
					local fightPvp = roleOut
					print("----------------------------------------")
					print("第"..tostring(idx).."场")
					for k,v in ipairs(fightPvp) do
						if k == 7 then
							print("vs")
						end
						print(csvCards[v.card_id].name.." ")
					end
					print("\n")
					print("结果:"..t.result.."\n")
					if t.result == "win" then
						leftWin = leftWin + 1
					elseif t.result == "fail" then
						rightWin = rightWin + 1
					end
				else
					print("----------------------------------------")
					print("第"..tostring(idx).."场")
					print("结果失败")
				end
				print("\n")
				print("总场次:"..tostring(leftWin+rightWin).." 左胜:"..tostring(leftWin).." 右胜:"..tostring(rightWin))
			end)
			i = i + 1
			oldTime = socket.gettime()
		end
	end

end

function TestChooseCardView:getZuheForce( front_tb,back_tb )
	local function hasSameTable(b_tb,s_tb)
		for _,v in ipairs(b_tb) do
			local isSameTable = true
			for i=1,3 do
				if v[i].id ~= s_tb[i].id then
					isSameTable = false
				end
			end
			if isSameTable then
				return true
			end
		end

		return false
	end

	local function zuhe(big_tb,tb)
		if #tb == 3 and not hasSameTable(big_tb,tb) then
			table.insert(big_tb,tb)
			return
		end

		for i=1,#tb do
			local temp_tb = clone(tb)
			table.remove(temp_tb,i)
			zuhe(big_tb,temp_tb)
		end
	end

	local front_zuhe = {}
	zuhe(front_zuhe,front_tb)
	local back_zuhe = {}
	zuhe(back_zuhe,back_tb)

	local final_zuhe = {}
	for _,v in ipairs(front_zuhe) do
		for _,v2 in ipairs(back_zuhe) do
			local temp = {}
			for _,unitFront in ipairs(v) do
				table.insert(temp,unitFront)
			end

			for _,unitBack in ipairs(v2) do
				table.insert(temp,unitBack)
			end
			table.insert(final_zuhe,temp)
		end
	end
	return final_zuhe
end

function TestChooseCardView:addForcePanel( view,zuhe_tb,isLeft,forceAttr )
	self.chooseAttr = 1
	for i,v in ipairs(zuhe_tb) do
		local forceInfo = {}
		forceInfo.roleOut = {}
		local panel = self.forcePanel:clone()
		local showPanel = panel:getChildByName("showPanel")
		for j=1,6 do
			local oneInfo = {}

			local unitID = v[j].unitID
			local unitInfo = csvUnits[unitID]

			local btn = self.prefab:clone()

			btn:get("icon"):texture(unitInfo.iconSimple)
			btn:setScale(0.6)
			btn.id = unitID
			btn.name = unitInfo.name
			btn.index = showPanel:getChildrenCount() + 1

			local lerpPos,limit = cc.p(10,5),3
			local startPos = cc.p(btn:size().width/2
			,btn:size().height/2-lerpPos.y * 3)

			self:addItemToScrollView(showPanel,btn,lerpPos,startPos,limit)

			oneInfo.unitID = unitID
			oneInfo.unitInfo = unitInfo
			oneInfo.attrInfo = {star=v[j].star}

			btn:addClickEventListener(function()
				self:updateMultiForceAttrView(oneInfo,view.attrView)
			end)

			table.insert(forceInfo.roleOut,oneInfo)
		end
		local lerpPos,limit = cc.p(20,10),3
		local startPos = cc.p(panel:size().width/2 + lerpPos.x
			,panel:size().height/2+lerpPos.y)

		self:addItemToScrollView(view.scrollForceView,panel,lerpPos,startPos,limit)

		panel.index = view.scrollForceView:getChildrenCount() + 1

		forceInfo.index = view.scrollForceView:getChildrenCount() + 1
		forceInfo.attrInfo = {chooseAttr=self.chooseAttr}
		forceInfo.panel = panel
		forceInfo.selected = true

		panel:addClickEventListener(function()
			self:updateMultiForceAttrView(forceInfo,view.attrView)
		end)

		local forceName = panel:get("forceText")
		forceName:setString(isLeft and "左" or "右")

		showPanel:addClickEventListener(function()
			self:updateMultiForceAttrView(forceInfo,view.attrView)
		end)

		local checkBox = panel:get("checkBox")
		checkBox:setSelectedState(forceInfo.selected)

		checkBox:addEventListenerCheckBox(function (  )
			forceInfo.selected = not forceInfo.selected
		end)


		table.insert(isLeft and self.leftForceInfo or self.rightForceInfo,forceInfo)
	end
end

local panelStr = {
	"leftFrontUnitScrollView","leftBackUnitScrollView","rightFrontUnitScrollView","rightBackUnitScrollView"
}

local forceStr = {"left_front","left_back","right_front","right_back"}

function TestChooseCardView:addUnitPanel( view,unitTb,panelIdx )
	for k,v in ipairs(unitTb) do
		local cardID = v.cardID
		local unitInfo = csvUnits[csvCards[cardID].unitID]

		v.unitInfo = unitInfo
		local btn = self.prefab:clone()

		btn:get("icon"):texture(unitInfo.iconSimple)
		btn:setScale(0.6)
		-- btn.id = unitID
		-- btn.name = unitInfo.name
		btn.index = view[panelStr[panelIdx]]:getChildrenCount() + 1

		local lerpPos,limit = cc.p(8,4),5
		local startPos = cc.p(btn:size().width/2
		,btn:size().height/2)

		self:addItemToScrollView(view[panelStr[panelIdx]],btn,lerpPos,startPos,limit)

		btn:addClickEventListener(function()
			self:updateUnitAttr(panelIdx,v,view.attrView,k)
		end)
	end
end

function TestChooseCardView:updateUnitAttr( panelIdx,info,attrView,idx )
	attrView:removeAllChildren()
	local node,head = {},{}

	node = self.attrItem:clone()
	head = node:get("head"):text(info.unitInfo.name)

	local showAttr = {
		star = true,
		advance = true,
		level = true
	}

	for k,v in pairs(info) do
		if showAttr[k] then
			local attrName = k
			node = self.attrItem:clone()
			head = node:get("head"):text(k .. ": ")

			node:get("edit")
				:setPlaceHolder(v)
				:addEventListener(function(sender, eventType)
				if eventType == 2 or eventType == 3 then
					local result,count = string.gsub(sender:text(), "[^%d]", "")
					if count > 0 then
						sender:text(result)
						return
					end
					result = result == "" and 1 or tonumber(result)
					result = math.max(result,0)
					print("[upd Attr]attr value ",attrName,result)
					info[k] = result
					MultiForce.requestCardData(self,info,function(ret,t)
						self.dataTb[forceStr[panelIdx].."_tb"][idx] = t
					end)
					-- for _,v in ipairs(panelIdx > 2 and self.rightForceInfo or self.leftForceInfo) do
					-- 	for _,v2 in ipairs(v.roleOut) do
					-- 		if v2.unitID == info.unitID then
					-- 			v2.attrInfo[k] = result
					-- 		end
					-- 	end
					-- end
				end
			end)

			node:setScale(1.5)
			-- if defaultValue ~= v then
				node:get("edit"):text(v)
			-- end

			attrView:pushBackCustomItem(node)

			node:get("edit")
				:x(head:width() + head:x() + 10)
		end
	end

end

--]] ------------------------------ End -------------------------------

return TestChooseCardView




