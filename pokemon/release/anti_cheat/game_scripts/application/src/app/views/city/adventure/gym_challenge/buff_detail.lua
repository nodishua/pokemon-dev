
local ViewBase = cc.load("mvc").ViewBase
local GymBuffDetail = class("GymBuffDetail", ViewBase)

GymBuffDetail.RESOURCE_FILENAME = "gym_buf_detail.json"
GymBuffDetail.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnAct"] = {
		varname = "btnAct",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onActClick")}
		}
	},
	["btnDetail"] = {
		varname = "btnDetail",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDetailClick")}
		}
	},
	["textNote"] = "textNote",
	["imgIcon"] = "imgIcon",
	["imgTextBg"] = "imgTextBg",
	["textName"] = "textName",
	["textNoteLv"] = "textNoteLv",
	["textLv"] = "textLv",
	["textDesc"] = "textDesc",
	["textNoteCost"] = "textNoteCost",
	["textCost"] = "textCost",
	["imgCost"] = "imgCost",
	["imgCost"] = "imgCost",
	["imgLockBg"] = "imgLockBg",
	["lockPanel"] = "lockPanel",
}
local function getSkillStr(str, level)
	local list = string.split(str, "$")
	local desc = ""
	for i, v in pairs(list) do
		local s = v
		local pos = string.find(s, "skilllevel")
		if pos then
			local symbol = ""
			if list[i+1] and string.find(list[i+1],"^%%") then
				symbol = "%"
				list[i+1] = string.gsub(list[i+1],"^%%","")
			end
			local num = eval.doFormula(v, {skilllevel = level,math = math}, str)
			s = num..symbol
		end
		desc = desc .. s
	end
	return desc
end

function GymBuffDetail:onCreate(id, unlocked, preLv, needPerLv)
	self.id = id
	self.unlocked = unlocked
	self.lv = 0
	local cfg = csv.gym.talent_buff[id]
	self.imgIcon:texture(cfg.icon)
	self.textName:text(cfg.name)
	self.gymDatas = gGameModel.role:getIdler("gym_datas")
	idlereasy.when(self.gymDatas, function(_, gymDatas)
		local tree = gymDatas.gym_talent_trees[cfg.treeID]
		local lv =  0
		if tree then
			lv = tree.talent[self.id] or 0
		end
		self.textLv:text(lv.."/"..cfg.levelUp)
		if cfg.effectType == 1 then
			local effectData = {}
			for i = 1, math.huge do
				if cfg['attrType'.. i] and cfg['attrType' .. i] ~= 0 and cfg['attrNum' .. i] then
					local data = 0
					if lv == 0 then--0级显示1级的配置
						data = dataEasy.getAttrValueString(cfg['attrType'.. i], cfg['attrNum' .. i][1])
					else
						data = dataEasy.getAttrValueString(cfg['attrType'.. i], cfg['attrNum' .. i][lv])
					end
					table.insert(effectData, data)
				else
					break
				end
			end
			self.textDesc:text(string.format(cfg.desc,table.unpack(effectData)))
		else
			self.textDesc:text(getSkillStr(cfg.desc, lv or 0))
		end
		adapt.oneLineCenterPos(cc.p(self.imgIcon:x(), 720-113), {self.textNoteLv, self.textLv})
		if self.unlocked == false then
			self.btnAct:get("textNote"):text(gLanguageCsv.notActivatedTip)
			uiEasy.setBtnShader(self.btnAct,self.btnAct:get("textNote"), 2)
			itertools.invoke({self.textNoteCost, self.textCost, self.imgCost, self.textNoteLv, self.textLv}, "hide")

			local cfg = csv.gym.talent_buff[id]
			local preId = cfg.preTalentIDs
			local preLevel = cfg.preLevel

			self.lockPanel:show()
			self.lockPanel:get("textNote3")
			local str = string.format("(%d/%d)", preLv, needPerLv)
			self.lockPanel:get("textLevel"):text(str)
		elseif lv >= cfg.levelUp then
			self.btnAct:get("textNote"):text(gLanguageCsv.levelMax)
			uiEasy.setBtnShader(self.btnAct,self.btnAct:get("textNote"), 2)
			itertools.invoke({self.textNoteCost, self.textCost, self.imgCost, self.btnDetail}, "hide")
			self.imgLockBg:hide()
			self.lockPanel:hide()
		else
			local cost = csv.gym.talent_cost[lv]["cost"..cfg.costID].gym_talent_point
			self.textCost:text(cost)
			self.imgLockBg:hide()
			adapt.oneLineCenterPos(cc.p(self.btnAct:x(), self.textNoteCost:y()), {self.textNoteCost, self.textCost, self.imgCost}, {cc.p(10,0), cc.p(10,0)})
			if lv == 0 then
				self.btnAct:get("textNote"):text(gLanguageCsv.spaceActive)
				uiEasy.setBtnShader(self.btnAct,self.btnAct:get("textNote"), 1)
			else
				self.btnAct:get("textNote"):text(gLanguageCsv.spaceUpgrade)
				uiEasy.setBtnShader(self.btnAct,self.btnAct:get("textNote"), 1)
			end
			self.lockPanel:hide()
		end
		self.lv = lv
	end)
end

function GymBuffDetail:onActClick( )
	local cfg = csv.gym.talent_buff[self.id]
	local cost = csv.gym.talent_cost[self.lv]["cost"..cfg.costID].gym_talent_point
	if self.gymDatas:read().gym_talent_point < cost then
		gGameUI:showTip(gLanguageCsv.gymBuffPointNotEnough)
		return
	end
	gGameApp:requestServer("/game/gym/talent/level/up",function (tb)
		self.imgTextBg:show()
			:y(720-100)
			:stopAllActions()
			:setOpacity(255)
		self.imgTextBg:get("imgText")
			:stopAllActions()
			:setOpacity(255)
		local delay1 = 2 -- 停留时间
		local delay2 = 1
		local delay3 = 0.5
		if self.lv == 0 then
			self.imgTextBg:get("imgText"):texture("city/adventure/gym_challenge/txt_jhcg.png")
		else
			self.imgTextBg:get("imgText"):texture("city/adventure/gym_challenge/txt_sjcg.png")
		end
		-- 动画效果
		audio.playEffectWithWeekBGM("new_advance_suc.mp3")
		transition.executeSequence(self.imgTextBg)
			:moveBy(delay3, 0, 100)
			:delay(delay1)
			:moveBy(delay2, 0, 100)
			:hide()
			:done()
		transition.executeSequence(self.imgTextBg)
			:delay(delay1 + delay3)
			:fadeOut(delay2)
			:done()
		transition.executeSequence(self.imgTextBg:get("imgText"))
			:delay(delay1 + delay3)
			:fadeOut(delay2)
			:done()

	end, self.id)
end

function GymBuffDetail:onDetailClick(target)
	local lv = self.lv + 1
	local cfg = csv.gym.talent_buff[self.id]
	local content = "#L10##C0x5B545B#"..gLanguageCsv.gymBufLvUpEff.."\n#L0#"
	if cfg.effectType == 1 then

		local effectData = {}
		for i = 1, math.huge do
			if cfg['attrType'.. i] and cfg['attrType' .. i] ~= 0 and cfg['attrNum' .. i] then
				local data = 0
				if lv == 0 then--0级显示1级的配置
					data = dataEasy.getAttrValueString(cfg['attrType'.. i], cfg['attrNum' .. i][1])
				else
					data = dataEasy.getAttrValueString(cfg['attrType'.. i], cfg['attrNum' .. i][lv])
				end
				table.insert(effectData, data)
			else
				break
			end
		end
		content = content .. string.format(cfg.desc,table.unpack(effectData))
	elseif cfg.effectType == 2 then
		content = content .. getSkillStr(cfg.desc, lv or 0)
	end
	gGameUI:showText(target, {content = content,width = 420})
end

return GymBuffDetail
