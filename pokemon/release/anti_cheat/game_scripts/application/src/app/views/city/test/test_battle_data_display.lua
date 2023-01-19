-- @date 2021-1-21
-- @desc 战斗中伤害恢复量数据实时显示

local TestBattleDataDisplay = class("TestBattleDataDisplay", cc.load("mvc").ViewBase)

TestBattleDataDisplay.RESOURCE_FILENAME = "test_battle_data_display.json"
TestBattleDataDisplay.RESOURCE_BINDING = {
	["leftPanel"] = "leftPanel",
	["rightPanel"] = "rightPanel",
	["leftPanel.item"] = "item",
	["btnState"] = {
		varname = "btnState",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnStateClick")},
		},
	},
}

function TestBattleDataDisplay:onCreate()
	self:onBtnStateClick(true)
	self.item:hide()
	for i = 1, 2 do
		local panel = i == 1 and self.leftPanel or self.rightPanel
		panel:get("list"):setScrollBarEnabled(false)
		panel:setCascadeOpacityEnabled(true)
		panel:opacity(200)
		text.addEffect(panel:get("card"), {outline={color=ui.COLORS.OUTLINE.DEFAULT,size=2}})
		text.addEffect(panel:get("damage"), {outline={color=ui.COLORS.OUTLINE.DEFAULT,size=2}})
		text.addEffect(panel:get("recover"), {outline={color=ui.COLORS.OUTLINE.DEFAULT,size=2}})
		text.addEffect(panel:get("takeDamage"), {outline={color=ui.COLORS.OUTLINE.DEFAULT,size=2}})
		text.addEffect(panel:get("bigSkill"), {outline={color=ui.COLORS.OUTLINE.DEFAULT,size=2}})
		panel:get("bigSkill"):setFontSize(10)
	end

	self.obj = {}
	local function addEffect(item, name)
		local node = item:get(name):hide()
		text.addEffect(node:get("num"), {outline={color=ui.COLORS.OUTLINE.WHITE,size=2}})
		text.addEffect(node:get("percent"), {outline={color=ui.COLORS.OUTLINE.DEFAULT,size=2}})
		bind.extend(self, node:get("progress"), {
			class = "loadingbar",
		})
		node:get("num"):getVirtualRenderer():setLineSpacing(-5)--行间距
	end
	for i = 1, 12 do
		local item = self.item:clone():show()
		local list = i <= 6 and self.leftPanel:get("list") or self.rightPanel:get("list")
		list:pushBackCustomItem(item)
		addEffect(item, "damage")
		addEffect(item, "recover")
		addEffect(item, "takeDamage")
		text.addEffect(item:get("bigSkill"), {outline={color=ui.COLORS.OUTLINE.WHITE,size=2}})
		item:get("bigSkill"):hide()
		self.obj[i] = {
			item = item,
		}
	end
	-- 记录累计数据，传过来的data没有死亡单位的数据 dbId
	-- 记录左右方总伤害，总治疗，总承伤
	self.datas = {
		[1] = {},
		[2] = {},
	}
end

-- battle test 没有dbId
local function getDbID(v)
	if not v then
		return nil
	end
	return v.dbID or v.seat
end

-- 若数据有新精灵，则认为是新的队伍数据（马桶王会移位）
function TestBattleDataDisplay:setData(data, st, ed, idx)
	-- 是否重置数据
	for i = st, ed do
		if data[i] and not self.datas[idx][getDbID(data[i])] then
			self.datas[idx] = {}
			break
		end
	end
	-- 累计数据记录
	for i = st, ed do
		if data[i] then
			local dbID = getDbID(data[i])
			-- 位置保留不变
			local oldSeat = self.datas[idx][dbID] and self.datas[idx][dbID].seat or data[i].seat
			self.datas[idx][dbID] = clone(data[i])
			self.datas[idx][dbID].seat = oldSeat
		end
	end
	if not self:visible() then
		return
	end
	local totalDamage = 0
	local totalRecover = 0
	local totalTakeDamage = 0
	for _, v in pairs(self.datas[idx]) do
		local damage = 0
		local recover = 0
		local takeDamage = 0
		for _, v in pairs(v.totalDamage) do
			damage = damage + v:get(battle.ValueType.normal)
		end
		for _, v in pairs(v.totalResumeHp) do
			recover = recover + v:get(battle.ValueType.normal)
		end
		for _, v in pairs(v.totalTakeDamage) do
			takeDamage = takeDamage + v:get(battle.ValueType.normal)
		end

		local damageValid = 0
		local recoverValid = 0
		local takeDamageValid = 0
		for _, v in pairs(v.totalDamage) do
			damageValid = damageValid + v:get(battle.ValueType.valid)
		end
		for _, v in pairs(v.totalResumeHp) do
			recoverValid = recoverValid + v:get(battle.ValueType.valid)
		end
		for _, v in pairs(v.totalTakeDamage) do
			takeDamageValid = takeDamageValid + v:get(battle.ValueType.valid)
		end
		v.damage = damage
		v.recover = recover
		v.takeDamage = takeDamage
		v.damageValid = damageValid
		v.recoverValid = recoverValid
		v.takeDamageValid = takeDamageValid
		v.bigSkill = v.bigSkillUseTimes or 0

		totalDamage = totalDamage + v.damage
		totalRecover = totalRecover + v.recover
		totalTakeDamage = totalTakeDamage + v.takeDamage
	end
	-- 显示刷新
	local flag = {}
	local function show(item, name, v, total)
		local node = item:get(name):show()
		node:get("num"):text(mathEasy.getShortNumber(v[name], 2))
		local percent = 0
		if self.state == 1 then
			percent = total == 0 and 0 or math.floor(v[name] * 100 / total)

		elseif self.state == 2 then
			percent = v[name] == 0 and 100 or math.floor(100 * v[name .. "Valid"] / v[name])
		end
		node:get("progress"):percent(percent)
		node:get("percent"):text(percent .. "%")

	end
	for _, v in pairs(self.datas[idx]) do
		local seat = v.seat
		flag[seat] = true
		local item = self.obj[seat].item
		item:get("bigSkill"):show()
		if item:get("_card_") then
			item:get("_card_"):show()
		end
		show(item, "damage", v, totalDamage)
		show(item, "recover", v, totalRecover)
		show(item, "takeDamage", v, totalTakeDamage)
		item:get("bigSkill"):text(v.bigSkill .. "次")

		local dbID = getDbID(v)
		if self.obj[seat].dbID ~= dbID then
			self.obj[seat].dbID = dbID
			local unitId = v.unitID
			local unitCfg = csv.unit[unitId]
			bind.extend(self, item, {
				class = "card_icon",
				props = {
					unitId = unitId,
					advance = v.advance,
					star = v.star,
					rarity = unitCfg.rarity,
					-- levelProps = {
					-- 	data = v.level,
					-- },
					onNode = function(panel)
						panel:scale(0.25)
						local width = item:width()
						local height = item:height()
						local x = (width - panel:box().width)/2
						panel:xy(x, height - panel:box().height)
					end,
				}
			})
		end
	end

	for i = st, ed do
		if not flag[i] then
			local item = self.obj[i].item
			item:get("damage"):hide()
			item:get("recover"):hide()
			item:get("takeDamage"):hide()
			item:get("bigSkill"):hide()
			if item:get("_card_") then
				item:get("_card_"):hide()
			end
		end
	end
end

local STATE_STR = {
	[1] = "队伍数值占比",
	[2] = "有效值比",
}
function TestBattleDataDisplay:onBtnStateClick(init)
	if init == true then
		self.state = 1
		self.btnState:get("label"):text(STATE_STR[self.state])
		return
	end
	self.state = self.state % #STATE_STR + 1
	self.btnState:get("label"):text(STATE_STR[self.state])

	self:setData({}, 1, 6, 1)
	self:setData({}, 7, 12, 2)
end

function TestBattleDataDisplay:refresh(data)
	if data then
		self:setData(data, 1, 6, 1)
		self:setData(data, 7, 12, 2)
	end
end

return TestBattleDataDisplay