-- @date:   2020-08-20
-- @desc:   道馆挑战副本

local GymCrossGate = class("GymCrossGate", cc.load("mvc").ViewBase)
GymCrossGate.RESOURCE_FILENAME = "gym_cross_gate.json"
GymCrossGate.RESOURCE_BINDING = {
	["imgFileter"] = "imgFileter",
	["panel1"] = "panel1",
	["panel2"] = "panel2",
	["panel3"] = "panel3",
	["panel4"] = "panel4",
	["panel5"] = "panel5",
	["panel6"] = "panel6",
	["panel7"] = "panel7",
	["panel8"] = "panel8",
	["panel8"] = "panel8",
	["btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRuleClick")}
		}
	},
	["attrItem"] = "attrItem",
	["leftTop.arrList"] = {
		varname = "arrList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrData"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					node:get("imgIcon"):texture(ui.ATTR_ICON[v])
				end,
			}
		},
	},
}

function GymCrossGate:onCreate(id, crossUnlock)
	self.id = id
	self.crossUnlock = crossUnlock
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.gymChallenge, subTitle = "The Pavilion Challenge"})
	self:initModel()
	self:initUI()
end


-- 初始化界面
function GymCrossGate:initUI()
	--馆类型 改变相关UI
	local path = "city/adventure/gym_challenge/gate/"
	self.imgFileter:texture(path.."bg_"..csv.gym.gym[self.id].texture)
		:size(display.sizeInView)
	self.panel1:get("imgBgCircle"):texture(path.."icon_"..csv.gym.gym[self.id].texture)
	self.panel1:get("imgBgCircle"):runAction(cc.RepeatForever:create(cc.RotateBy:create(90, 360)))
	self.panel1:get("imgOwner"):texture("city/adventure/gym_challenge/map/"..csv.gym.gym[self.id].namePng)
	--馆主信息
	self:initMember()
end

function GymCrossGate:initModel()
	self.inCd = idler.new(false)
	self.gates = idlers.newWithMap({})
	--道馆信息
	self.gymDatas = gGameModel.role:getIdler("gym_datas")
	self.gatesDatas = gGameModel.gym:getIdler("GymCrossGates")
	self.crossAlGatesDatas = gGameModel.gym:getIdler("crossGymRoles")
	self.attrData = idlers.newWithMap(csv.gym.gym[self.id].limitAttribute)
	self.round = gGameModel.gym:getIdler("round")
	idlereasy.when(self.gymDatas, function(_,data)
		self:initCountDown()
	end)
end

-- 初始化界面
function GymCrossGate:initMember()
	local path = "city/adventure/gym_challenge/gate/"
	idlereasy.any({self.crossAlGatesDatas, self.inCd, self.round}, function(_, _crossGatesDatas, inCd, round)
		local crossGatesDatas
		if round == "start" then
			crossGatesDatas = _crossGatesDatas or {}
		else
			crossGatesDatas = gGameModel.gym:read("lastCrossGymRoles") or {}
		end
		for i = 1, 8 do
			local panel = self["panel"..i]
			local infoPanel = panel:get("infoPanel")
			local emptyPanel = panel:get("emptyPanel")
			local btnChallenge = panel:get("btnChallenge")
			local btnText = btnChallenge:get("textNote")
			local data = crossGatesDatas[self.id] and crossGatesDatas[self.id][i]
			if i == 1 then
				text.addEffect(panel:get("textTime"), {outline={color = cc.c4b(255, 224, 171, 255), size = 2}})
			end
			if data then
				infoPanel:show()
				emptyPanel:hide()
				local childs = infoPanel:multiget("textFight", "textName", "textLv", "textSever", "txt", "figurePanel", "figurePanel")
				text.addEffect(childs.textFight, {outline={color = cc.c4b(255, 252, 237, 255), size = 2}})
				text.addEffect(childs.textLv, {outline={color = cc.c4b(79, 72, 79, 255), size = 2}})
				text.addEffect(childs.textName, {outline={color = cc.c4b(79, 72, 79, 255), size = 2}})
				text.addEffect(childs.textSever, {outline={color = cc.c4b(79, 72, 79, 255), size = 2}})
				if i ~= 1 then
					text.addEffect(childs.txt, {outline={color = cc.c4b(79, 72, 79, 255), size = 2}})
				end
				childs.textName:text(data.name)
				childs.textLv:text("Lv."..data.level)
				childs.textFight:text(data.fighting_point)
				childs.textSever:text(string.format(gLanguageCsv.brackets, getServerArea(data.game_key, true)))
				if i == 1 then
					adapt.oneLineCenterPos(cc.p(150,childs.textLv:y()), {childs.textLv, childs.textName}, cc.p(6,8))
					adapt.oneLineCenterPos(cc.p(150,childs.textSever:y()), {childs.txt, childs.textFight, childs.textSever}, {cc.p(10,-5), cc.p(0, 0)})
				else
					adapt.oneLineCenterPos(cc.p(150,childs.textLv:y()), {childs.textLv, childs.textName}, cc.p(5,6))
					adapt.oneLineCenterPos(cc.p(150,childs.textSever:y()), {childs.txt, childs.textFight, childs.textSever}, {cc.p(10,0), cc.p(0, 0)})
				end
				if data.figure ~= "" then
					local size = infoPanel:size()
					local figureCfg = gRoleFigureCsv[data.figure]
					widget.addAnimationByKey(childs.figurePanel, figureCfg.resSpine, "figure", "standby_loop1", 1)
						:xy(size.width / 2, 0)
						:scale(i == 1 and 1 or 0.9)
					bind.touch(self,childs.figurePanel, {methods = {ended = function()
						gGameApp:requestServer("/game/gym/role/info",function(tb)
							gGameUI:createView("city.adventure.gym_challenge.master_info", self):init(tb.view, self.id, true, true, i)
						end, data.record_id, data.game_key)
					end}})
				end

				panel:get("btnChallenge.textNote"):text(gLanguageCsv.spaceChallenge)
				if i == 1 then
					btnChallenge:y(0)
					panel:get("textTime"):y(-60)
				end

				if gGameModel.role:read("gym_record_db_id") == data.record_id then
					btnChallenge:hide()
				else
					if inCd then
						uiEasy.setBtnShader(btnChallenge, btnText, 3)
					else
						uiEasy.setBtnShader(btnChallenge, btnText, 1)
					end
					btnChallenge:show()
				end
			else
				infoPanel:hide()
				emptyPanel:show()
				if i == 1 then
					panel:get("btnChallenge.textNote"):text(gLanguageCsv.gymTobeOwner)
					btnChallenge:y(50):show()
					panel:get("textTime"):y(-10)
				else
					panel:get("btnChallenge.textNote"):text(gLanguageCsv.gymTobeMember)
				end
				if inCd then
					uiEasy.setBtnShader(btnChallenge, btnText, 3)
				else
					uiEasy.setBtnShader(btnChallenge, btnText, 1)
				end
			end

			bind.touch(self, btnChallenge, {methods = {ended = function()
				if data then
					self:onBtnChallenge(i, data)
				else
					self:onBtnOccupy(i)
				end
			end}})
			if self:getChallengeState() == false or not self.crossUnlock then
				uiEasy.setBtnShader(btnChallenge, btnText, 3)
			end
		end
	end)
end

-- 挑战按钮
function GymCrossGate:onBtnChallenge(k, data)
	if gGameModel.gym:read("crossKey") == ""  then
		gGameUI:showTip(gLanguageCsv.crossGymNotOpen)
		return
	end
	if self:getChallengeState() == false then
		gGameUI:showTip(gLanguageCsv.gymTimeOut)
		return
	end
	if not self.crossUnlock then
		gGameUI:showTip(gLanguageCsv.gymCrossTips1)
		return
	end

	if self.inCd:read() then
		gGameUI:showTip(gLanguageCsv.gymInCd)
		return
	end

	local natureLimit = csv.gym.gym[self.id].limitAttribute
	if #dataEasy.getNatureSprite(natureLimit) == 0 then
		gGameUI:showTip(gLanguageCsv.gymNoSptire1)
		return
	end
	local fightCb = function(view, battleCards)
		if self:getChallengeState() == false then
			gGameUI:showTip(gLanguageCsv.gymTimeOut)
			return
		end
		local cardDatas = battleCards:read()
		battleEntrance.battleRequest("/game/cross/gym/battle/start", cardDatas, self.id, k, data.game_key, data.record_id)
		:onStartOK(function(data)
			view:onClose(false)
		end)
		:run()
		:show()
	end
	gGameUI:stackUI("city.adventure.gym_challenge.embattle1", nil, {full = true}, {
		fightCb = fightCb,
		limitInfo = csv.gym.gym[self.id].limitAttribute,
		from = game.EMBATTLE_FROM_TABLE.onekey,
	})
end

-- 占领按钮
function GymCrossGate:onBtnOccupy(k)
	if gGameModel.gym:read("crossKey") == ""  then
		gGameUI:showTip(gLanguageCsv.crossGymNotOpen)
		return
	end
	if self:getChallengeState() == false then
		gGameUI:showTip(gLanguageCsv.gymTimeOut)
		return
	end
	if not self.crossUnlock then
		gGameUI:showTip(gLanguageCsv.gymCrossTips1)
		return
	end

	if self.inCd:read() then
		gGameUI:showTip(gLanguageCsv.gymInCd)
		return
	end

	local natureLimit = csv.gym.gym[self.id].limitAttribute
	if #dataEasy.getNatureSprite(natureLimit) == 0 then
		gGameUI:showTip(gLanguageCsv.gymNoSptire2)
		return
	end

	local saveCb = function(view, clientbattleCards, battleCards, bCloseView)
		local cardDatas = clientbattleCards:read()
		gGameApp:requestServer("/game/cross/gym/battle/occupy",function(tb)
			battleCards:set(cardDatas)
			view.haveSaved = true -- 保存过阵容
			if bCloseView then
				view:onClose(false)
			else
				gGameUI:showTip(gLanguageCsv.positionSave)
			end
		end, cardDatas, self.id, k)
	end
	gGameUI:stackUI("city.adventure.gym_challenge.embattle1", nil, {full = true}, {
		saveCb = saveCb,
		limitInfo = csv.gym.gym[self.id].limitAttribute,
		from = game.EMBATTLE_FROM_TABLE.onekey,
	})
end

-- 检测是否在可挑战时段内
function GymCrossGate:getChallengeState()
	if self.round:read() == "closed" then
		return false
	end
	local endStamp = time.getNumTimestamp(gGameModel.gym:read("date"), 21, 45) + 6 * 24 * 3600
	return time.getTime() < endStamp
end

function GymCrossGate:initCountDown()
	local textTime = self.panel1:get("textTime"):show()
	if not self:getChallengeState() then
		textTime:hide()
		return
	end
	local function setLabel()
		local endTime = gGameModel.role:read("gym_datas").cross_gym_pw_last_time + gCommonConfigCsv.gymPwCD
		local remainTime = time.getCutDown(endTime - time.getTime())
		textTime:text(remainTime.short_date_str..gLanguageCsv.gymTimeLimit)
		adapt.oneLinePos(textTime, self.textNote1,cc.p(5,0), "right")
		if endTime - time.getTime() <= 0 then
			textTime:hide()
			self:unSchedule(1)
			self.inCd:set(false)
			return false
		else
			self.inCd:set(true)
			return true
		end
	end
	self:enableSchedule()
	setLabel()
	self:unScheduleAll()
	self:schedule(function(dt)
		if not setLabel() then
			return false
		end
	end, 1, 0, 1)
end

-- 规则
function GymCrossGate:onBtnRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function GymCrossGate:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.rules)
        end),
        c.noteText(103001, 103100),
	}
	if self.round:read() == "start" then
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

return GymCrossGate
