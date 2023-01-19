local ViewBase = cc.load("mvc").ViewBase
local GemOneKeyStrengthenView = class('GemOneKeyStrengthenView', Dialog)
local insert = table.insert
GemOneKeyStrengthenView.RESOURCE_FILENAME = 'gem_onekey_strengthen.json'

GemOneKeyStrengthenView.RESOURCE_BINDING = {
	['level'] = 'txtLevel',
	["sliderPanel.slider"] = "slider",
	["sliderPanel.subBtn"] = {
		varname = "sliderSubBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["sliderPanel.addBtn"] = {
		varname = "sliderAddBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
	['btnSure'] = {
		varname = 'btnSure',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onClickBtnSure')},
		}
	},
	['btnClose'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onClose')},
		}
	},
	['txtCost'] = 'txtCost',
}

function GemOneKeyStrengthenView:onCreate(gemdbid)
	self:enableSchedule()
	self:initModel()
	self.gemdbid = gemdbid
	self.slider:setPercent(50)
	self.curLv = gGameModel.gems:find(gemdbid):read('level')
	local cfg = dataEasy.getCfgByKey(gGameModel.gems:find(gemdbid):read('gem_id'))
	self.levelMax = cfg.strengthMax
	self.costNodes = {}
	self.levelCosts = {}
	local costs = {}
	for i = self.curLv, self.levelMax do
		local costCfg = csv.gem.cost[i]['costItemMap'..cfg.strengthCostSeq]
		for k, v in csvMapPairs(costCfg) do
			costs[k] = (costs[k] or 0) + v
		end
		self.levelCosts[i] = {}
		for k, v in pairs(costs) do
			self.levelCosts[i][k] = v
		end
	end
	self:calculateLvUpMax()
	self.level = idler.new(self.curLv + 1)
	idlereasy.when(self.level, function(_, level)
		self:setDetail()
	end)
	idlereasy.when(self.gold, function()
		self:calculateLvUpMax()
		self:setDetail()
	end)
	self.slider:addEventListener(function(sender,eventType)
		self:unScheduleAll()
		local percent = sender:getPercent()
		local num = cc.clampf(self.curLv + math.ceil((self.levelMax - self.curLv) * percent * 0.01), self.curLv + 1, self.canLvUpMax)
		self.level:set(num)
		if num >= self.canLvUpMax then
			local percent = math.ceil((num - self.curLv) / (self.levelMax - self.curLv) * 100)
			self.slider:setPercent(percent)
		end
	end)
	Dialog.onCreate(self)
end

function GemOneKeyStrengthenView:calculateLvUpMax()
	self.canLvUpMax = self.levelMax
	for level = self.curLv, self.levelMax do
		local cost = self.levelCosts[level]
		for k, v in pairs(cost) do
			if dataEasy.getNumByKey(k) < v and level >= self.curLv + 1 then
				self.canLvUpMax = level
				return
			end
		end
	end
end

function GemOneKeyStrengthenView:setDetail()
	local level = self.level:read()
	self.txtLevel:setString(level..'/'..self.levelMax)
	-- 非拖动时才设置进度
	if not self.slider:isHighlighted() then
		local percent = math.ceil((level - self.curLv) / (self.levelMax - self.curLv) * 100)
		self.slider:setPercent(percent)
	end
	local cost = self.levelCosts[level - 1]
	for k, v in pairs(self.costNodes) do
		v:removeSelf()
	end
	local tbl = {self.txtCost}
	self.costNodes = {}
	self.costNeed = nil
	for key, num in pairs(cost) do
		local numNode = cc.Label:createWithTTF(num, ui.FONT_PATH, 40):addTo(self:getResourceNode(), 100):setTextColor(ui.COLORS.NORMAL.BLACK)
		local icon = ccui.ImageView:create(dataEasy.getIconResByKey(key)):addTo(self:getResourceNode(), 100):scale(0.8)
		insert(self.costNodes, numNode)
		insert(self.costNodes, icon)
		insert(tbl, numNode)
		insert(tbl, icon)
		if dataEasy.getNumByKey(key) < num then
			text.addEffect(numNode, {color = ui.COLORS.NORMAL.RED})
			self.costNeed = key
		end
	end
	local space = {}
	local flag = true -- 空一些间距
	for i = 1, #tbl do
		insert(space, flag and cc.p(15, 0) or cc.p(0, 0))
		flag = not flag
	end
	adapt.oneLineCenterPos(cc.p(self.btnSure:x(), self.txtCost:y()), tbl, space)
	cache.setShader(self.sliderAddBtn, false, (level >= self.canLvUpMax) and "hsl_gray" or  "normal")
	cache.setShader(self.sliderSubBtn, false, (level <= self.curLv + 1) and 'hsl_gray' or 'normal')
end

function GemOneKeyStrengthenView:onIncreaseNum(step)
	self.level:modify(function(num)
		return true, cc.clampf(num + step, self.curLv + 1, self.canLvUpMax)
	end)
end

function GemOneKeyStrengthenView:onChangeNum(node, event, step)
	if event.name == "click" then
		self:unScheduleAll()
		self:onIncreaseNum(step)

	elseif event.name == "began" then
		self:schedule(function()
			self:onIncreaseNum(step)
		end, 0.05, 0, 100)

	elseif event.name == "ended" or event.name == "cancelled" then
		self:unScheduleAll()
	end
end

function GemOneKeyStrengthenView:onClickBtnSure()
	if self.costNeed then
		if self.costNeed == 'gold' then
			uiEasy.showDialog('gold')
		else
			gGameUI:showTip(gLanguageCsv.materialsNotEnough)
		end
		return
	end
	local gemdbid = self.gemdbid
	local level = self.level:read()
	ViewBase.onClose(self)
	gGameApp:requestServer('/game/gem/strength', nil, gemdbid, level)
end

function GemOneKeyStrengthenView:initModel()
	self.gold = gGameModel.role:getIdler('gold')
end

return GemOneKeyStrengthenView