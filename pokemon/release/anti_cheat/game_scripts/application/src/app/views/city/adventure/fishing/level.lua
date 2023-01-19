-- @date 2020-06-30
-- @desc 钓鱼等级

local FishingLevelView = class('FishingLevelView', Dialog)
FishingLevelView.RESOURCE_FILENAME = 'fishing_level.json'

FishingLevelView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["left.item"] = "leftItem",
	["left.list"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("listDatas"),
				item = bindHelper.self("leftItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("name", "num", "bar")
					childs.name:text(v.name)
					childs.num:text(v.num.."/"..v.maxNum)
					childs.bar:percent(cc.clampf(100*(v.num/v.maxNum), 0, 100))
				end,
			},
		},
	},
	["right.now.fish.name"] = "fishName",
	["right.now.fish.item"] = "fishItem",
	["right.now.fish.list"] = {
		varname = "fishList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("fishDatas"),
				item = bindHelper.self("fishItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("txt1", "num1")
					childs.txt1:text(v.name)
					if k == 1 then
						childs.num1:text("-"..v.num*100 .."%")
					elseif k == 3 then
						childs.num1:text("+"..v.num*100 .."%")
					else
						childs.num1:text("+"..v.num*100 .."%")
					end
					adapt.oneLinePos(childs.txt1, childs.num1, cc.p(15, 0), "left")
					if not v.isLock then
						text.addEffect(childs.txt1, {color = cc.c4b(183, 176, 158, 255)})
						text.addEffect(childs.num1, {color = cc.c4b(183, 176, 158, 255)})
					end
				end,
			},
		},
	},
	["right.now.attr.name"] = "attrName",
	["right.now.attr.item"] = "attrItem",
	["right.now.attr.subList"] = "subList",
	["right.now.attr.list"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrDatas"),
				columnSize = 2,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("attrItem"),
				onCell = function(list, node, k, v)
					local childs = node:multiget("txt1", "num1")
					childs.txt1:text(v.name..":")
					childs.num1:text(v.num)
					adapt.oneLinePos(childs.txt1, childs.num1, cc.p(20, 0), "left")
					if not v.isLock then
						text.addEffect(childs.txt1, {color = cc.c4b(183, 176, 158, 255)})
						text.addEffect(childs.num1, {color = cc.c4b(183, 176, 158, 255)})
					end
				end,
			},
		},
	},
	["left.level"] = "level",
	["left.level1"] = "level1",
	["left.nextLevel"] = "nextLevel",
	["right.now.text"] = "text",
	["right.btnUp"] = {
		varname = "btnUp",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnUp")}
		},
	},
	["right.btnNext"] = {
		varname = "btnNext",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnNext")}
		},
	},
}

function FishingLevelView:onCreate()
	self:initModel()
	-- 钓鱼属性
	self.fishDatas = idlers.new({})
	-- 精灵属性
	self.attrDatas = idlers.new({})
	-- 钓鱼数量
	self.listDatas = idlers.new({})
	-- 翻页等级
	self.clientLevel = idler.new(1)

	local listData = {"lowNum", "middleNum", "highNum", "totalNum", "targetNum"}
	idlereasy.any({self.fishLevel,self.fishCounter,self.targetCounter}, function(_, fishLevel,fishCounter,targetCounter)
		local cfg = csv.fishing.level[fishLevel]
		local listDatas = {}

		local lowCounter = 0
		local middleCounter = 0
		local highCounter = 0
		local fishCounter1 = 0
		local fishCounter2 = 0
		local fishCounter3 = 0

		if fishCounter ~= nil then
			if fishCounter[1] ~= nil then
				lowCounter = fishCounter[1] < cfg.lowNum and fishCounter[1] or cfg.lowNum
				fishCounter1 = fishCounter[1]
			end
			if fishCounter[2] ~= nil then
				middleCounter = fishCounter[2] < cfg.middleNum and fishCounter[2] or cfg.middleNum
				fishCounter2 = fishCounter[2]
			end
			if fishCounter[3] ~= nil then
				highCounter = fishCounter[3] < cfg.highNum and fishCounter[3] or cfg.highNum
				fishCounter3 = fishCounter[3]
			end
		end

		local name = {gLanguageCsv.lowFishNum, gLanguageCsv.middleFishNum, gLanguageCsv.highFishNum, gLanguageCsv.totalFishNum,""}
		local sum = fishCounter1 + fishCounter2 + fishCounter3
		if sum > cfg.totalNum then
			sum = cfg.totalNum
		end
		local num = {lowCounter,middleCounter,highCounter,sum,targetCounter}
		for i,v in ipairs(listData) do
			if i < 5 and cfg[v] ~= 0 then
				table.insert(listDatas, {
					name = name[i],
					num = num[i],
					maxNum = cfg[v]
				})
			end
			if i == 5 and not itertools.isempty(cfg[v]) then
				local key, val = csvNext(cfg[v])
				if key ~= nil then
					local fish = csv.fishing.fish[key]
					local name = string.format(gLanguageCsv.targetFishNum, val, fish.name)
					table.insert(listDatas, {
						name = name,
						num = num[i],
						maxNum = val
					})
				end
			end
		end
		self.listDatas:update(listDatas)
		self.clientLevel:set(fishLevel)

		self.level1:text(fishLevel)
		adapt.oneLinePos(self.level, self.level1, cc.p(5, 0), "left")
		local str = string.format(gLanguageCsv.completeLvUp, fishLevel+1)
		self.nextLevel:text(fishLevel == table.length(csv.fishing.level) and gLanguageCsv.lvIsMax or str)
	end)
	-- 点击切换等级
	idlereasy.any({self.clientLevel,self.fishLevel}, function(_, clientLevel, fishLevel)
		self:setRightPanel(clientLevel, fishLevel)
	end)
	Dialog.onCreate(self)
end

function FishingLevelView:setRightPanel(clientLevel, fishLevel)
	local cfg = csv.fishing.level[clientLevel]
	local fishDatas = {
		{name = gLanguageCsv.timeDown, num = cfg.timeDown, isLock = self.fishLevel:read() >= clientLevel},
		{name = gLanguageCsv.fasterSpeed, num = cfg.fasterSpeed, isLock = self.fishLevel:read() >= clientLevel},
		{name = gLanguageCsv.extraProbability, num = cfg.extraProbability, isLock = self.fishLevel:read() >= clientLevel},
	}
	self.fishDatas:update(fishDatas)

	local attrDatas = {}
	for i = 1, 99 do
		if cfg["attrNum"..i] and cfg["attrNum"..i] ~= 0 then
			local num = cfg["attrNum"..i]
			local name = getLanguageAttr(cfg["attrType"..i])
			if cfg["attrType"..i] == 22 or cfg["attrType"..i] == 23 then
				num = "+"..(num/10000)*100 .."%"
			else
				num = "+"..num
			end
			table.insert(attrDatas, {
				name = name,
				num = num,
				isLock = self.fishLevel:read() >= clientLevel
			})
		end
	end
	self.attrDatas:update(attrDatas)

	local other = string.format(gLanguageCsv.otherLevelBonuses,clientLevel)
	self.text:text(clientLevel ~= fishLevel and other or gLanguageCsv.nowLevelBonuses)

	local lockColor = cc.c4b(183, 176, 158, 255)
	local isLockColor = cc.c4b(91, 84, 91, 255)
	text.addEffect(self.text, {color = self.fishLevel:read() < clientLevel and lockColor or isLockColor})
	text.addEffect(self.attrName, {color = self.fishLevel:read() < clientLevel and lockColor or isLockColor})
	text.addEffect(self.fishName, {color = self.fishLevel:read() < clientLevel and lockColor or isLockColor})

	self.btnNext:setTouchEnabled(clientLevel < table.length(csv.fishing.level))
	cache.setShader(self.btnNext, false, clientLevel < table.length(csv.fishing.level) and "normal" or "hsl_gray")
	self.btnUp:setTouchEnabled(clientLevel ~= 1)
	cache.setShader(self.btnUp, false, clientLevel ~= 1 and "normal" or "hsl_gray")

end
function FishingLevelView:onBtnUp()
	self.clientLevel:set(math.max(self.clientLevel:read() - 1, 1))
end

function FishingLevelView:onBtnNext()
	self.clientLevel:set(math.min(self.clientLevel:read() + 1, table.length(csv.fishing.level)))
end

function FishingLevelView:initModel()
	self.fishLevel = gGameModel.fishing:getIdler("level")
	self.fishCounter = gGameModel.fishing:getIdler("fish_counter")
	self.targetCounter = gGameModel.fishing:getIdler("target_counter")
end

return FishingLevelView