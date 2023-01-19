-- @date 2021-5-8
-- @desc 学习芯片功能详情

-- 镶嵌，卸下，替换
local CHANGE_TYPE = {
	up = 1,
	down = 2,
	change = 3,
}
local CHANGE_TYPE_TEXT = {gLanguageCsv.spaceInlay, gLanguageCsv.spaceDischarge, gLanguageCsv.spaceReplace}

local ViewBase = cc.load("mvc").ViewBase
local ChipDetailsView = class("ChipDetailsView", ViewBase)
local ChipTools = require('app.views.city.card.chip.tools')

ChipDetailsView.RESOURCE_FILENAME = "chip_details.json"
ChipDetailsView.RESOURCE_BINDING = {
	["panel"] = "panel",
	["panel.btnChange"] = {
		varname = "btnChange",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeClick")}
		}
	},
	["panel.btnStrength"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStrengthClick")}
		}
	},
	["panel.btnStrength.txt"] = {
		binds = {
			event = "effect",
			data = {color=ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
}

-- @params {cardDBID, dbId, subDBID, plan, justShow, pos, align, showExp, cb}
function ChipDetailsView:onCreate(params)
	self.cb = params.cb
	self.chipDBID = params.dbId
	self.cardDBID = params.cardDBID
	self.plan = params.plan
	self.subDBID = params.subDBID
	self.showExp = params.showExp
	self.dataRefresh = params.dataRefresh

	local chip = gGameModel.chips:find(self.chipDBID)
	local chipData = chip:read("chip_id", "card_db_id", "level")
	local cfg = csv.chip.chips[chipData.chip_id]
	self.chipIdx = cfg.pos

	self.panel:get("btnChange"):hide()
	self.panel:get("btnStrength"):hide()
	-- 指定卡牌，若选择的芯片在卡牌上则为卸下
	if self.cardDBID then
		if self.cardDBID == chipData.card_db_id then
			self.changeType = CHANGE_TYPE.down
		else
			if not self.subDBID then
				local card = gGameModel.cards:find(self.cardDBID)
				local cardChips = card:read("chip")
				self.subDBID = cardChips[self.chipIdx]
			end
			if self.subDBID then
				-- 对比项显示已装备
				self.changeType = CHANGE_TYPE.change
			else
				self.changeType = CHANGE_TYPE.up
			end
		end
	-- 指定套装存储，若选择的芯片在套装存储上则为卸下
	elseif self.plan then
		local plan = self.plan:read()
		if self.chipDBID == plan[self.chipIdx] then
			self.changeType = CHANGE_TYPE.down
		else
			self.subDBID = plan[self.chipIdx]
			if self.subDBID then
				-- 对比项显示已装备
				self.changeType = CHANGE_TYPE.change
			else
				self.changeType = CHANGE_TYPE.up
			end
		end
	end
	if params.justShow then
		self.changeType = nil
	end
	if self.changeType then
		self.panel:get("btnChange"):show()
		self.panel:get("btnStrength"):show()
		self.btnChange:get("txt"):text(CHANGE_TYPE_TEXT[self.changeType])
	end

	if params.pos then
		local x = params.pos.x
		if params.align == "right" then
			x = x + self.panel:width() / 2
		else
			x = x - self.panel:width() / 2
		end
		self.panel:x(x)
	end

	local isFirst = true
	local chipDatas = chip:multigetIdler("level", "now", "locked")
	idlereasy.any(chipDatas, function()
		self:setPanel(self.panel, self.chipDBID)
		if not isFirst and self.dataRefresh then
			self.dataRefresh()
		end
	end)
	isFirst = false

	if self.subDBID then
		local subPanel = self.panel:clone()
			:addTo(self.panel:parent())
			:xy(self.panel:x() + self.panel:width() + 10, self.panel:y())
		subPanel:get("btnChange"):hide()
		subPanel:get("btnStrength"):hide()
		local chip1 = gGameModel.chips:find(self.subDBID)
		local chipDatas1 = chip1:multigetIdler("level", "now", "locked")
		idlereasy.any(chipDatas1, function()
			self:setPanel(subPanel, self.subDBID)
		end)
	end
end

function ChipDetailsView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

function ChipDetailsView:onChangeClick()
	if self.cardDBID then
		local chipState = -1
		if self.changeType ~= CHANGE_TYPE.down then
			chipState = self.chipDBID
		end
		gGameApp:requestServer("/game/card/chip/change", function(tb)
			if self.changeType == CHANGE_TYPE.up then
				gGameUI:showTip(gLanguageCsv.inlaySuccess)

			elseif self.changeType == CHANGE_TYPE.down then
				gGameUI:showTip(gLanguageCsv.dischargeSuccess)
			else
				gGameUI:showTip(gLanguageCsv.exchange2Success)
			end
			self:onClose()
		end, self.cardDBID, {[self.chipIdx] = chipState})
	else
		self.plan:modify(function(data)
			data[self.chipIdx] = self.changeType ~= CHANGE_TYPE.down and self.chipDBID or nil
			return true, data
		end)
		print_r(self.plan:read())
		if self.dataRefresh then
			self.dataRefresh()
		end
		self:onClose()
	end
end

function ChipDetailsView:setPanel(panel, dbId)
	local childs = panel:multiget("bg", "bg2", "lock", "icon", "name", "level", "noEquip", "equip", "cardName", "gainExpText", "gainExp", "list", "attrItem", "lineItem", "suitItem", "btnChange", "btnStrength")
	local chip = gGameModel.chips:find(dbId)
	local chipData = chip:read("chip_id", "card_db_id", "level", "level_exp", "locked")
	local cfg = csv.chip.chips[chipData.chip_id]
	bind.extend(self, childs.icon, {
		class = 'icon_key',
		props = {
			noListener = true,
			data = {
				key = chipData.chip_id,
				dbId = chipData.card_db_id,
			},
			specialKey = {
				lv = chipData.level,
			},
			onNode = function(panel)
				panel:get("defaultLv"):hide()
			end,
		},
	})
	uiEasy.setIconName(chipData.chip_id, 0, {node = childs.name})
	childs.level:text("Lv" .. chipData.level)
	childs.noEquip:hide()
	childs.equip:hide()
	childs.cardName:hide()
	childs.lock:texture(chipData.locked and "city/card/chip/btn_lock.png" or "city/card/chip/btn_unlock.png")
	bind.touch(self, childs.lock, {methods = {ended = functools.partial(self.onLockClick, self, dbId)}})

	childs.gainExpText:hide()
	childs.gainExp:hide()
	if self.showExp then
		childs.gainExpText:show()
		childs.gainExp:show()
		adapt.oneLinePos(childs.gainExpText, childs.gainExp)
		childs.gainExp:text(self.showExp)
	else
		if chipData.card_db_id then
			childs.equip:show()
			childs.cardName:show()
			local card = gGameModel.cards:find(chipData.card_db_id)
			uiEasy.setIconName("card", card:read("card_id"), {node = childs.cardName, advance = card:read("advance"), space = true})
			adapt.oneLinePos(childs.equip, childs.cardName, cc.p(10, 0), "left")
		else
			childs.noEquip:show()
		end
	end

	childs.list:removeAllChildren()
	childs.list:setScrollBarEnabled(false)
	-- 物攻 特攻 显示为双攻
	local firstAttrs, secondAttrs = ChipTools.getAttr(dbId, nil, true, true)
	-- 主属性
	local flag = false
	for _, data in ipairs(firstAttrs) do
		local key = data.key
		if not ChipTools.ignoreAttr(key) then
			flag = true
			local val = data.val
			local item = childs.attrItem:clone():show()
			local name = ChipTools.getAttrName(key)
			item:get("key"):text(name)
			item:get("val"):text("+" .. val)
			childs.list:pushBackCustomItem(item)
		end
	end
	if flag then
		local item = childs.lineItem:clone():show()
		childs.list:pushBackCustomItem(item)
	end
	-- 副属性
	flag = false
	for k, data in ipairs(secondAttrs) do
		local key = data.key
		if not key then
			local item = childs.attrItem:clone():show()
			item:get("key"):text(data.name)
			item:get("val"):text(data.val)
			text.addEffect(item:get("key"), {color = ui.COLORS.NORMAL.GRAY})
			text.addEffect(item:get("val"), {color = ui.COLORS.NORMAL.GRAY})
			childs.list:pushBackCustomItem(item)

		elseif not ChipTools.ignoreAttr(key) then
			flag = true
			local val = data.val
			local item = childs.attrItem:clone():show()
			local name = ChipTools.getAttrName(key)
			item:get("key"):text(name)
			item:get("val"):text("+" .. val)
			childs.list:pushBackCustomItem(item)
		end
	end

	if flag then
		local item = childs.lineItem:clone():show()
		childs.list:pushBackCustomItem(item)
	end

	-- 添加套装属性
	local strs = {}
	local suitAttrs = ChipTools.getSuitAttrByChip(dbId)
	for _, data in ipairs(suitAttrs) do
		local str = ChipTools.getSuitAttrStr(cfg.suitID, data)
		table.insert(strs, {str = str})
	end
	local suitItem = childs.suitItem:clone():show()
	local list, height = beauty.textScroll({
		list = suitItem:get("list"),
		strs = strs,
		margin = 10,
		isRich = true,
	})
	list:height(height)
	list:setTouchEnabled(false)
	suitItem:height(height)
	childs.list:pushBackCustomItem(suitItem)

	local extraHeight = (childs.btnChange:visible() and 0 or 124)
	local height = cc.clampf(childs.list:getInnerItemSize().height, 420, 590 + extraHeight)
	local diff = 590 - height
	childs.list:height(height):y(180 + diff)
	childs.bg2:height(642 - diff)
	childs.bg:height(1030 - diff - extraHeight)
	childs.btnChange:y(90 + diff)
	childs.btnStrength:y(90 + diff)


	if dataEasy.isUnlock(gUnlockCsv.chipPlan) then
		panel:removeChildByName("planNamesBg")
		panel:removeChildByName("planNames")
		local names = {}
		local plans = gGameModel.role:read("chip_plans")
		for _, data in pairs(plans) do
			for _, key in pairs(data.chips or {}) do
				if key == dbId then
					table.insert(names, data.name)
					break
				end
			end
		end
		if #names > 0 then
			local dw = 60
			local list, height = beauty.textScroll({
				size = cc.size(childs.bg:width() - 2 * dw, 0),
				strs = "#C0xFFFCED##L00100000##LOC0xF13B54#" .. gLanguageCsv.chipUsedInPlans .. " #C0xFFFF66##L00100000##LOC0xF13B54#" .. table.concat(names, ", "),
				isRich = true,
			})
			local showHeight = math.min(height, 120)
			list:setTouchEnabled(showHeight < height)
			list:height(showHeight)
			list:xy(childs.bg:box().x + dw, childs.bg:box().y - showHeight - 10)
				:addTo(panel, 2, "planNames")

			local bg = ccui.Scale9Sprite:create()
			bg:initWithFile(cc.rect(243, 17, 1, 1), "city/card/chip/bg_red.png")
			bg:size(childs.bg:width() + 140, showHeight + 40)
				:anchorPoint(0.5, 1)
				:xy(childs.bg:box().x + childs.bg:width()/2, childs.bg:box().y + 10)
				:addTo(panel, 1, "planNamesBg")
		end
	end
end

-- 强化
function ChipDetailsView:onStrengthClick()
	gGameUI:stackUI('city.card.chip.advance', nil, {full = true}, self.chipDBID)
end

function ChipDetailsView:onLockClick(dbId)
	gGameApp:requestServer("/game/card/chip/locked/switch", function()
		local chip = gGameModel.chips:find(dbId)
		local locked = chip:read("locked")
		if locked then
			gGameUI:showTip(gLanguageCsv.chipLocked)
		end
	end, dbId)
end

return ChipDetailsView