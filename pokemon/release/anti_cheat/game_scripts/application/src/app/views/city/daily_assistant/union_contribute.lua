-- @date:   2021-01-27
-- @desc:   公会捐献界面

local UnionContribInfoView = class("UnionContribInfoView", Dialog)

UnionContribInfoView.RESOURCE_FILENAME = "daily_assistant_union_contribute.json"
UnionContribInfoView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemDatas"),
				item = bindHelper.self("item"),
				vip = bindHelper.self("vip"),
				onItem = function(list, node, k, v)
					local children = node:multiget("textTitle", "info1", "info2", "cost", "btnOk")
					children.textTitle:text(gLanguageCsv[v.cfg.title])
					children.info1:get("textAddNum"):text("+" .. v.cfg.contrib)
					local _, awardVal = csvNext(v.cfg.award)
					children.info2:get("textAddNum"):text("+" .. awardVal)
					local key, val = csvNext(v.cfg.cost)
					local costText = children.cost:get("textNum")
					costText:text(val)
					local myNum = dataEasy.getNumByKey(key)
					local color = ui.COLORS.NORMAL.DEFAULT
					if not v.isEnough then
						color = ui.COLORS.NORMAL.RED
					end
					text.addEffect(costText, {color = color})
					local icon = children.cost:get("imgIcon")
					icon:texture(dataEasy.getIconResByKey(key))
					adapt.oneLineCenterPos(cc.p(150, 35), {children.cost:get("textNote"), costText, icon}, cc.p(6, 0))
					local vipEnough = list.vip:read() >= v.cfg.vipNeed
					if not vipEnough then
						children.btnOk:get("textNote"):text(string.format(gLanguageCsv.vipCanUse, v.cfg.vipNeed))
						if matchLanguage({"kr"}) then
							children.btnOk:get("textNote"):setFontSize(38)
						end
					end
					cache.setShader(children.btnOk, false, v.canContrubute and vipEnough and "normal" or "hsl_gray")
					if v.canContrubute and vipEnough then
						text.addEffect(children.btnOk:get("textNote"), {glow = {color = ui.COLORS.GLOW.WHITE}})
					else
						text.deleteAllEffect(children.btnOk:get("textNote"))
						text.addEffect(children.btnOk:get("textNote"), {color = ui.COLORS.DISABLED.WHITE})
					end

					bind.touch(list, children.btnOk, {methods = {
						ended = functools.partial(list.clickCell, k, v)
					}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["imgBG"] = "imgBg",
}

function UnionContribInfoView:onCreate(params)
	self.callBack = params.callBack
	self.list:setName("contribInfoList") -- 引导名
	self:initModel()
	self.unionExpPro = idler.new(0)
	self.todayExpPro = idler.new(0)
	self.todayExp = idler.new("")
	self.unionCurLvExp = idler.new("")
	self.leftCount = idler.new("")

	local itemDatas = {}
	for i,v in orderCsvPairs(csv.union.contrib) do
		local data = {}
		data.cfg = v
		data.csvId = i
		data.canContrubute = true
		local key, val = csvNext(data.cfg.cost)
		local myNum = dataEasy.getNumByKey(key)
		if key == "gold" then
			data.isEnough = myNum >= val
		elseif key == "rmb" then
			data.isEnough = myNum >= val
		end
		table.insert(itemDatas, data)
	end
	self.itemDatas = idlers.newWithMap(itemDatas)

	idlereasy.any({self.gold, self.rmb}, function(_, gold, rmb)
		for i,v in ipairs(itemDatas) do
			local key, val = csvNext(v.cfg.cost)
			if key == "gold" then
				self.itemDatas:atproxy(i).isEnough = gold >= val
			elseif key == "rmb" then
				self.itemDatas:atproxy(i).isEnough = rmb >= val
			end
		end
	end)
	if self.imgBg:get("privilege") then
		self.imgBg:get("privilege"):removeSelf()
	end
	-- uiEasy.setPrivilegeRichText(game.PRIVILEGE_TYPE.UnionContribCoinRate, self.imgBg, gLanguageCsv.unionCoin, cc.p(40, 50))

	Dialog.onCreate(self)
end

function UnionContribInfoView:initModel()
	local unionInfo = gGameModel.union
	self.vip = gGameModel.role:getIdler("vip_level")
	self.unionLv = unionInfo:getIdler("level")
	self.unionDayExp = unionInfo:getIdler("day_contrib") -- 每日的捐献经验
	self.unionExp = unionInfo:getIdler("contrib") -- 公会的总经验
	local dailyRecord = gGameModel.daily_record
	self.contribCount = dailyRecord:getIdler("union_contrib_times")
	self.gold = gGameModel.role:getIdler("gold")
	self.rmb = gGameModel.role:getIdler("rmb")
end

function UnionContribInfoView:onItemClick(list, k, v)
	if self.vip:read() < v.cfg.vipNeed then
		return
	end
	self.callBack(v.csvId, function()
		self:onClose()
	end)
	-- if not v.canContrubute then
	-- 	gGameUI:showTip(gLanguageCsv.contrubuteCountNotEnough)
	-- 	return
	-- end
	-- local costKey, costVal = csvNext(v.cfg.cost)
	-- local myNum = dataEasy.getNumByKey(costKey)
	-- if not v.isEnough then
	-- 	uiEasy.showDialog(costKey)
	-- 	return
	-- end

	-- local function cb()
	-- 	-- 捐献
	-- 	gGameApp:requestServer("/game/union/contrib", function()
	-- 		local _, awardVal = csvNext(v.cfg.award)
	-- 		gGameUI:showTip(string.format(gLanguageCsv.contrubuteSucc, awardVal))
	-- 	end, v.csvId)
	-- end
	-- if costKey == "rmb" then
	-- 	dataEasy.sureUsingDiamonds(cb, costVal)
	-- else
	-- 	cb()
	-- end
end

return UnionContribInfoView