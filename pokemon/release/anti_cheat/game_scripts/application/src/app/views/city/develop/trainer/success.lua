local ViewBase = cc.load("mvc").ViewBase
local TrainLevelUpgrade = class("TrainLevelUpgrade", ViewBase)
local TrainerView = require "app.views.city.develop.trainer.view"
TrainLevelUpgrade.RESOURCE_FILENAME = "trainer_success.json"
TrainLevelUpgrade.RESOURCE_BINDING = {
	["item"] = "item",
	["leftList"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftData"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "name")
					local attr = game.ATTRDEF_TABLE[v.id]
					childs.icon:texture(ui.ATTR_LOGO[attr])
					childs.name:text(getLanguageAttr(v.id).." +"..dataEasy.getAttrValueString(v.id, v.num))
				end,
			},
		},
	},
	["rightList"] = {
		varname = "rightList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rightData"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "name")
					local attr = game.ATTRDEF_TABLE[v.id]
					childs.icon:texture(ui.ATTR_LOGO[attr])
					childs.name:text(getLanguageAttr(v.id).." +"..dataEasy.getAttrValueString(v.id, v.num))
				end,
			},
		},
	},
	["leftTxt"] = "leftTxt",
	["rightTxt"] = "rightTxt",
	["name"] = "nodeName",
	["pos"] = "pos",
	["bg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose"),
		},
	},
	["centerTip.txt"] = "centerTxt",
	["centerTip.num"] = "centerNum",
	["centerTip.bg"] = "centerBg",
	["centerTip.arrow"] = "centerArrow",
	["arrow"] = "arrow",

}

function TrainLevelUpgrade:onCreate(oldlevel, params)
	audio.playEffectWithWeekBGM("unlock.mp3")
	self:initModel()
	self.topCenter = params()
	if oldlevel == 0 then
		--第一次进来
		self.leftList:hide()
		self.arrow:hide()
		self.rightList:x(self.rightList:x() - 327)
		self.leftTxt:hide()
		self.rightTxt:x(self.rightTxt:x() - 317)
		self.leftData = idlertable.new({})
	else
		local oldData = csv.trainer.trainer_level[oldlevel]
		local t = {}
		for i,v in csvPairs(oldData.attrs) do
			table.insert(t, {id = i, num = v})
		end
		table.sort(t, function (a, b)
			return a.id < b.id
		end)
		self.leftData = idlertable.new(t)
		self.leftTxt:text(oldData.name)
	end

	local newT = {}
	local newData = csv.trainer.trainer_level[self.trainerLevel:read()]
	for i,v in csvPairs(newData.attrs) do
		table.insert(newT, {id = i, num = v})
	end
	table.sort(newT, function (a, b)
		return a.id < b.id
	end)
	self.rightData = idlertable.new(newT)
	table.sort(newT, function (a, b)
		return a.id < b.id
	end)
	self.rightData = idlertable.new(newT)
	self.nodeName:text(newData.name)
	self.rightTxt:text(newData.name)
	-- 特效文件分两个1-6为第一个，7-12为第二个
	local skelName = self.trainerLevel:read() < 7 and "1_6" or "7_12"
	widget.addAnimation(self.pos, "kapai/kapai"..skelName..".skel", tostring(self.trainerLevel:read()).."_loop", 2)
		:alignCenter(self.pos:size())

	local key, value = csvNext(newData.privilege)
	if not string.find(tostring(value), ".", 1, true) then
		self.centerNum:text((itertools.first(TrainerView.ADD_SHOW, key) ~= nil and "+" or "")..value)
	else
		self.centerNum:text((itertools.first(TrainerView.ADD_SHOW, key) ~= nil and key ~= game.PRIVILEGE_TYPE.ExpItemCostFallRate and "+" or "")..(value * 100).."%")
	end
	local str = gLanguageCsv["trainerPrivilege"..key]
	if key == game.PRIVILEGE_TYPE.BattleSkip then
		local name = gLanguageCsv[game.SCENE_TYPE_STRING_TABLE[value]]
		str = string.format(gLanguageCsv["trainerPrivilege"..key], name)

	elseif key == game.PRIVILEGE_TYPE.GateSaoDangTimes or key == game.PRIVILEGE_TYPE.DrawItemFreeTimes then
		-- str = string.format(gLanguageCsv["trainerPrivilege"..key], value)
		-- local addNum = math.max(dataEasy.getPrivilegeVal(key), value)
		str = string.format(gLanguageCsv["trainerPrivilege"..key], value)
	end
	self.centerTxt:text(str)
	local width = 0
	if key ~= 1 then
		width = width + self.centerNum:size().width
	end
	if itertools.first(TrainerView.ARROW_NOT_SHOW, key) then
		self.centerArrow:hide()
		if key == game.PRIVILEGE_TYPE.ExpItemCostFallRate then
			self.centerNum:show()
		else
			self.centerNum:hide()
		end
	else
		self.centerArrow:show()
		self.centerNum:show()
		width = width + self.centerArrow:getBoundingBox().width
	end
	width = width + self.centerTxt:size().width

	local size = self.centerBg:size()
	self.centerBg:size(width + 200, size.height)
	local x = self.centerBg:x()
	self.centerTxt:x(x - (width - 200)/2 - 20)
	adapt.oneLinePos(self.centerTxt, {self.centerNum, self.centerArrow})
	local pnode = self:getResourceNode()
	local spine1 = widget.addAnimationByKey(pnode, "level/jiesuanshengli.skel", "spine1", "jiesuan_jinshengzi", 103)
	spine1:align(cc.p(0.5,1.0), pnode:get("title"):xy())
	spine1:addPlay("jiesuan_jinshengzi_loop")
	local spine2 = widget.addAnimationByKey(pnode, "level/jiesuanshengli.skel", "spine2", "jiesuan_shenglitu", 100)
	spine2:align(cc.p(0.5,1.0), pnode:get("title"):xy())
	spine2:addPlay("jiesuan_shenglitu_loop")
end

function TrainLevelUpgrade:initModel()
	self.trainerLevel = gGameModel.role:getIdler("trainer_level")
end

function TrainLevelUpgrade:onClose()
	self.topCenter:set(self.trainerLevel:read() + 1)
	ViewBase.onClose(self)
end

return TrainLevelUpgrade
