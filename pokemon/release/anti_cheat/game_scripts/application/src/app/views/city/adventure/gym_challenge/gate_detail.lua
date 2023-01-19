-- @date:   2020-9-3
-- @desc:   道馆挑战-关卡详情

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

local function createRichTxt(str, x, y, parent)
	return rich.createByStr(str, 40)
			:anchorPoint(0, 0.5)
			:xy(x, y)
			:addTo(parent, 6)
end

local function setSpecialEff(sceneCsv, textNote)
	local x, y = 0, 50
	local hasSpecialEff = false
	for i,v in csvPairs(sceneCsv.specialEff) do
		hasSpecialEff = true
		y = y - 50
		local str = "#C0x5b545b#"
		for j, vv in csvPairs(v[1]) do
			local s = gLanguageCsv[game.NATURE_TABLE[vv]] .. gLanguageCsv.xi
			str = str .. s
		end
		str = str .. gLanguageCsv.card
		local attrType = getLanguageAttr(v[2])
		str = str .. attrType
		if v[3] == 0 then
			str = str .. gLanguageCsv.improve .. "#C0xFF60C456#"
		else
			str = str .. gLanguageCsv.reduce .."#C0x5b545b#"
		end
		str = str .. dataEasy.getAttrValueString(attrType, v[4])
		local icon = v[3] == 0 and "#Icommon/icon/logo_arrow_green.png-30-45#" or "#Icommon/icon/logo_arrow_red.png-30-45#"
		str = str .. icon
		createRichTxt(str, x, y, textNote)

	end
	if sceneCsv.specialEffDesc ~= "" then
		local rich = rich.createWithWidth("#C0x5b545b#"..sceneCsv.specialEffDesc or "", 40, nil, 960)
			:anchorPoint(0, 1)
			:xy(0, y + 25 - 50)
			:addTo(textNote)
		y =   y + 25 - 50 -rich:height()
		return y
	end
	if hasSpecialEff == false and sceneCsv.specialEffDesc == ""  then
		y = y - 50
	end
	return y - 20
end

local ViewBase = cc.load("mvc").ViewBase
local EndlessTowerGateDetail = class("EndlessTowerGateDetail", Dialog)
EndlessTowerGateDetail.RESOURCE_FILENAME = "gym_gate_detail.json"
EndlessTowerGateDetail.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["iconItem"] = "iconItem",
	["roleItem"] = "roleItem",
	["infoPanel.enemyList"] = {
		varname = "enemyList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 6,
				padding = 10,
				data = bindHelper.self("monsterDatas"),
				item = bindHelper.self("roleItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							levelProps = {
								data = v.level,
							},
							isBoss = v.isBoss,
							rarity = v.rarity,
							showAttribute = true,
							onNode = function(panel)
								local x, y = panel:xy()
								node:scale(v.isBoss and 1.1 or 1)
							end,
						}
					})
				end,
			}
		},
	},
	["infoPanel.awardList"] = "awardList",
	["infoPanel.btnChallenge"] = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnChallenge")},
		},
	},
	["battleBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["title.textGym"] = "textGym",
	["title.textDiff"] = "textDiff",
	["title.textGate"] = "textGate",
	["infoPanel.text1"] = "text1",
	["infoPanel.text2"] = "text2",
	["infoPanel.text3"] = "text3",
	["infoPanel.textNote3"] = "textNote3",
	["infoPanel.text4"] = "text4",
	["infoPanel.textNote4"] = "textNote4",

}

function EndlessTowerGateDetail:initText()
	local gateCfg = csv.gym.gate[self.gateId]
	local sceneCsv = csv.scene_conf[self.gateId]

	self.textGym:text(csv.gym.gym[gateCfg.gymID].name)
	self.textDiff:text(gLanguageCsv["gymDifficulty"..self.k])
	adapt.oneLinePos(self.textGym, self.textDiff, cc.p(5, 0))
	--text1
	if gateCfg.deployType == 1 then
		self.text1:text(gLanguageCsv["embattleType"..gateCfg.deployType])
	else
		self.text1:text(string.format(gLanguageCsv["embattleType"..gateCfg.deployType], gateCfg.deployCardNumLimit))
	end
	--text2
	local sceneCsv = csv.gym.gate[self.gateId]
	local y = setSpecialEff(sceneCsv, self.text2)
	--text3
	if gateCfg.weatherDesc ~= "" then
		self.textNote3:y(self.text2:y() + y - 50)
		self.text3:text("")
			:y(self.text2:y() + y - 50)
		local str = "#C0x5b545b#"..gateCfg.weatherDesc
		local rich = rich.createWithWidth(str, 40, nil, 960)
			:anchorPoint(0, 1)
			:xy(0, 20)
			:addTo(self.text3)
		y = self.text2:y() + y - rich:height() + 30 - 50
	else
		self.textNote3:hide()
		self.text3:hide()
		y = self.text2:y() + y + 40 - 50
	end

	if gateCfg.placeDesc ~= "" then
		self.textNote4:y(y - 50)
		self.textNote4:text(sceneCsv.palce)
		self.text4:text("")
			:y(y - 50)
		local str = "#C0x5b545b#"..gateCfg.placeDesc
		local rich = rich.createWithWidth(str, 40, nil, 1000)
			:anchorPoint(0, 1)
			:xy(0, 20)
			:addTo(self.text4)
	else
		self.textNote4:hide()
		self.text4:hide()
	end
end

function EndlessTowerGateDetail:onCreate(gateId, k, id, canChallenge)
	self.gateId = gateId
	self.id = id
	self.k = k
	self:initText()
	local gateCfg = csv.gym.gate[self.gateId]
	local sceneCsv = csv.scene_conf[self.gateId]
	local bossDatas = getCfgData(sceneCsv.boss, true)
	local monsterDatas = getCfgData(sceneCsv.monsters, false)
	self.monsterDatas = arraytools.merge({bossDatas, monsterDatas})
	self.btnChallenge:visible(canChallenge)
	uiEasy.createItemsToList(self, self.awardList , sceneCsv.dropIds, {margin = 20,
		onNode = function(panel,v)
			if v.key ~= "gold" then
				ccui.ImageView:create("city/adventure/endless_tower/icon_gl.png")
					:anchorPoint(1, 0.5)
					:xy(panel:width() - 5, panel:height() - 25)
					:addTo(panel, 15)
			end
		end})
	Dialog.onCreate(self)
end

--挑战按钮
function EndlessTowerGateDetail:onBtnChallenge()
	if self:getChallengeState() == false then
		gGameUI:showTip(gLanguageCsv.gymTimeOut)
		return
	end
	local buyTimes = gGameModel.daily_record:read("gym_battle_buy_times")
	if gCommonConfigCsv.gymBattleTimes - gGameModel.daily_record:read("gym_battle_times") + buyTimes <= 0 then
		gGameUI:showTip(gLanguageCsv.timesLimit2048)
		return
	end

	local natureLimit = csv.gym.gate[self.gateId].deployNatureLimit or {}
	if #dataEasy.getNatureSprite(natureLimit) == 0 then
		gGameUI:showTip(gLanguageCsv.gymNoSptire1)
		return
	end

	local gateId = self.gateId
	local deployType = csv.gym.gate[gateId].deployType
	local id = self.id
	local fightCb = function(view, battleCards)
		local data = battleCards:read()
		battleEntrance.battleRequest("/game/gym/gate/start", gateId, id, data)
			:onStartOK(function(data)
				view:onClose(false)
			end)
			:show()
	end
	if deployType == 1 then
		local limitInfo = csv.gym.gate[gateId].deployNatureLimit
		local maxNum = csv.gym.gate[gateId].deployCardNumLimit
		local from = game.EMBATTLE_FROM_TABLE.gymChallenge
		if itertools.size(limitInfo) ~= 0 or maxNum ~= 6 then --属性或者数量限制 使用一件布阵阵容
			from = game.EMBATTLE_FROM_TABLE.onekey
		end
		gGameUI:stackUI("city.adventure.gym_challenge.embattle1", nil, {full = true}, {
			fightCb = fightCb,
			gateId = gateId,
			gymId = id,
			from = from,
		})
	elseif deployType == 2 then
		gGameUI:stackUI("city.adventure.gym_challenge.embattle2", nil, {full = true}, {
			fightCb = fightCb,
			gateId = gateId,
			gymId = id,
		})
	else
		gGameUI:stackUI("city.adventure.gym_challenge.embattle3", nil, {full = true}, {
			fightCb = fightCb,
			gateId = gateId,
			gymId = id,
		})
	end
	self:onClose()
end

-- 检测是否在可挑战时段内
function EndlessTowerGateDetail:getChallengeState()
	if gGameModel.gym:read("round") == "closed" then
		return false
	end
	local endStamp = time.getNumTimestamp(gGameModel.gym:read("date"), 21, 45) + 6 * 24 * 3600
	return time.getTime() < endStamp
end

return EndlessTowerGateDetail
