local ROLEBUFF =
{
	{
		info = gLanguageCsv.crossMineWish01,
		role = "roleDamageAdd",
		server = "serverDamageAdd"
	},
	{
		info = gLanguageCsv.crossMineWish02,
		role = "roleDefenceAdd",
		server = "serverDefenceAdd"
	},
	{
		info = gLanguageCsv.crossMineWish03,
		role = "roleHpAdd",
		server = "serverHpAdd"
	}
}


local CrossMineWishView = class("CrossMineWishView", Dialog)

CrossMineWishView.RESOURCE_FILENAME = "cross_mine_wish.json"
CrossMineWishView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["title.textTitle1"] = "textTitle1",
	["title.textTitle2"] = "textTitle2",
	["leftPanel"] = "leftPanel",
	["leftPanel.tabItem"] = "tabItem",
	["leftPanel.tabList"] = {
		varname = "tabList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
					end
					panel:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					adapt.setAutoText(panel:get("txt"), v.name, 240)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},

	["item1"] = "itemFeed",
	["item2"] = "itemBuff",
	["panelRight.txtInfo"] = "txtInfo",
	["panelRight.listFeed"] = {
		varname = "listFeed",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemFeedDatas"),
				item = bindHelper.self("itemFeed"),
				vip = bindHelper.self("vip"),
				onItem = function(list, node, k, v)

					local children = node:multiget("textTitle", "info1", "info2", "cost", "btnOk","textCount")
					children.info1:get("textAddNum"):text("+" .. v.feedExp)

					children.textTitle:text(gLanguageCsv.gameMineWishTip2)

					local awardID, awardVal = csvNext(v.feedAward)
					children.info2:get("imgIcon"):texture(dataEasy.getIconResByKey(awardID))
					local cfg = dataEasy.getCfgByKey(awardID)
					children.info2:get("textContent"):text(cfg.name)
					children.info2:get("textAddNum"):text("+" .. awardVal)

					local costText = children.cost:get("textNum")
					costText:text(v.costCoin13)
					adapt.oneLineCenterPos(cc.p(150, 35), {children.cost:get("textNote"), costText, children.cost:get("imgIcon")}, cc.p(6, 0))


					children.textCount:text(string.format("%d/%d", v.timesLimit - v.times,v.timesLimit))

					local color = ui.COLORS.NORMAL.DEFAULT
					if not v.isEnough then
						color = ui.COLORS.NORMAL.RED
					end
					text.addEffect(costText, {color = color})


					local vipEnough = list.vip:read() >= v.feedVip
					if not vipEnough then
						children.btnOk:get("textNote"):text(string.format(gLanguageCsv.vipCanUse, v.feedVip))
					else
						children.btnOk:get("textNote"):text(gLanguageCsv.crossMineWishBtn)
					end

					local canTrubute = v.times < v.timesLimit
					if canTrubute and vipEnough then
						text.addEffect(children.btnOk:get("textNote"), {glow = {color = ui.COLORS.GLOW.WHITE}})
						text.addEffect(children.btnOk:get("textNote"), {color = ui.COLORS.NORMAL.WHITE})
						children.btnOk:setEnabled(true)
					else
						text.deleteAllEffect(children.btnOk:get("textNote"))
						text.addEffect(children.btnOk:get("textNote"), {color = ui.COLORS.DISABLED.WHITE})
						text.addEffect(children.btnOk:get("textNote"), {glow = {color = ui.COLORS.DISABLED.WHITE}})
						children.btnOk:setEnabled(false)
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
	["panelRight.listBuff"] = {
		varname = "listBuff",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemBuffDatas"),
				item = bindHelper.self("itemBuff"),
				onItem = function(list, node, k, v)
					local children = node:multiget("txtInfo","txtCur", "txtNext","img", "imgMax")
					children.txtInfo:text(v[1])

					if k == 1 then
						text.addEffect(children.txtInfo, {bold = true})
						text.addEffect(children.txtCur, {bold = true})
						text.addEffect(children.txtNext, {bold = true})
					end

					if v[3] then
						children.txtCur:text(v[2])
						children.txtNext:text(v[3])
						children.imgMax:hide()
					else
						children.imgMax:show()
						children.txtNext:hide()
						children.img:hide()
						children.txtCur:text(v[2])
						if k == 1 then
							children.imgMax:show()
							adapt.oneLineCenterPos(cc.p(650, 35), {children.txtCur,children.imgMax}, cc.p(6, 0))
						else
							children.imgMax:hide()
							adapt.oneLineCenterPos(cc.p(650, 35), {children.txtCur}, cc.p(6, 0))
						end
					end
				end
			}
		}
	},
	["panelPerson"] = "panelPerson",
	["panelPerson.txtInfo01"] =
	{
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["panelPerson.txtLv"] =
	{
		varname = "personTxtLv",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["panelPerson.txtGrade"] =
	{
		varname = "personTxtGrade",
		binds ={
			{
				event = "text",
				idler = bindHelper.self("roleGrade"),
			},
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
			}

		},
	},
	["panelPerson.txtInfo02"] =
	{
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["panelPerson.txtExp"] =
	{
		varname = "personTxtExp",
		binds = {
			{
				event = "text",
				idler = bindHelper.self("roleExp"),
			},
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
			}
		}
	},
	["panelPerson.bar"] =
	{
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("roleExpPro"),
				maskImg = "common/icon/bar_red.png"
			},
		},

	},
	["panelPerson.imgMax"] = "personMax",
	["panelPerson.btnInfo"] =
	{
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPersonBtnInfo")},
		},
	},
	["panelServer"] = "panelServer",
	["panelServer.txtInfo01"] =
	{
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["panelServer.txtLv"] = {
		varname = "serverTxtLv",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["panelServer.txtGrade"] =
	{
		varname = "serverTxtGrade",
		binds ={
			{
				event = "text",
				idler = bindHelper.self("serverGrade"),
			},
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
			}
		}
	},
	["panelServer.txtInfo02"] =
	{
		binds =
		{
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["panelServer.txtExp"] =
	{
		varname = "serverTxtExp",
		binds =
		{
			{
				event = "text",
				idler = bindHelper.self("serverExp"),
			},
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
			}

		},
	},
	["panelServer.imgMax"] = "serverMax",
	["panelServer.barExp"] =
	{
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("serverExpPro"),
				maskImg = "common/icon/bar_red.png"
			},
		},
	},
	["panelServer.txtInfo03"] =
	{
		binds =
		{
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["panelServer.txtExpLimit"] =
	{
		binds =
		{
			{
				event = "text",
				idler = bindHelper.self("serverExpLimit"),
			},
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
			}
		},
	},
	["panelServer.barExpLimit"] =
	{
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("serverExpProLimit"),
				maskImg = "common/icon/bar_red.png"
			},
		},
	},
	["panelServer.btnInfo"] =
	{
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onServerBtnInfo")},
		},
	},

}

function CrossMineWishView:onCreate()
	self:initModel()
	self.itemFeedDatas = idlers.new()
	self.itemBuffDatas = idlers.new()

	self.roleGrade = idler.new(0)
	self.roleExp = idler.new(0)
	self.roleExpPro = idler.new(0)

	self.serverGrade = idler.new(0)
	self.serverExp = idler.new(0)
	self.serverExpPro = idler.new(0)
	self.serverExpProLimit = idler.new(0)
	self.serverExpLimit = idler.new(0)

	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.crossMineWish04, fontSize = 50},
		[2] = {name = gLanguageCsv.crossMineWish05, fontSize = 50},
	})

	self.panel = {
		[1] = {
			idler = self.roleBuffInfo ,
			title = gLanguageCsv.crossMineWish06,
			key = "role",
			max = csv.cross.mine.base[1].roleAddLevelLimit,

		},
		[2] = {
			idler = self.serverBuffInfo ,
			title = gLanguageCsv.crossMineWish07,
			key = "server",
			max = csv.cross.mine.base[1].serverAddLevelLimit[3],
		}
	}

	self.vip =  gGameModel.role:getIdler("vip_level")
	self.showTab     = idler.new(1)

	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true

		self:initDatas()
	end)

	idlereasy.any({self.serverBuffInfo,self.roleBuffInfo,self.buffFeed}, function(_, serverBuffInfo,roleBuffInfo,buffFeed)
		self:initDatas()
	end)

	Dialog.onCreate(self)
end

function CrossMineWishView:initModel()
	self.buffFeed = gGameModel.daily_record:getIdler("cross_mine_buff_feed")
	self.serverBuffInfo = gGameModel.cross_mine:getIdler("serverBuffInfo")
	self.roleBuffInfo = gGameModel.cross_mine:getIdler("roleBuffInfo")
end


function CrossMineWishView:initDatas()
	local val = self.showTab:read()
	local sign = val == 1
	local csvBuffAdd = csv.cross.mine.buff_add
	local panelData = self.panel[val]
	local buffInfos = panelData["idler"]:read()
	local curBuffInfo = csvBuffAdd[buffInfos.level] or {}
	local nextLevel = math.min( buffInfos.level + 1, panelData.max)
	local nextBuffInfo = csvBuffAdd[nextLevel]
	local signLv = nextLevel == buffInfos.level

	local buffDatas = {}
	if signLv then
		table.insert(buffDatas, {gLanguageCsv.level,string.format(gLanguageCsv.crossMineWish09,buffInfos.level)})
	else
		table.insert(buffDatas, {gLanguageCsv.level,string.format(gLanguageCsv.crossMineWish09,buffInfos.level),string.format(gLanguageCsv.crossMineWish09,nextLevel)})
	end
	for index ,data in pairs(ROLEBUFF) do
		local key = data[panelData.key]
		local curInfo = curBuffInfo[key] or 0
		if signLv then
			table.insert(buffDatas, {data.info, string.format("%s%%",curInfo*100)})
		else
			table.insert(buffDatas, {data.info, string.format("%s%%",curInfo*100),string.format("%s%%",nextBuffInfo[key]*100)})
		end
	end
	self.itemBuffDatas:update(buffDatas)

	local feedDatas = {}
	local roleTimes = {}
	if self.buffFeed:read() then
		roleTimes = self.buffFeed:read()[panelData.key] or {}
	end

	local coinNum = dataEasy.getNumByKey("coin13")

	for index, data in csvPairs(csv.cross.mine.buff_feed) do
		local feedAward = sign and data.roleFeedAward or data.serverFeedAward
		local tempTab = {
			id = index,
			costCoin13 = data.costCoin13,
			feedExp = data.feedExp,
			feedAward = feedAward,
			timesLimit = data.dayFeedTimesLimit,
			feedVip = data.feedVip,
			times = roleTimes[index] or 0,
			isEnough = coinNum > data.costCoin13
		}
		table.insert(feedDatas, tempTab)
	end
	table.sort(feedDatas, function(v1, v2)
		local sign1 = v1.times == v1.timesLimit and 1 or 0
		local sign2 = v2.times == v2.timesLimit and 1 or 0
		if sign1 > sign2 then
			return false
		elseif sign1 < sign2 then
			return true
		else
			return v1.id < v2.id
		end
	 end)

	for index, data in ipairs(feedDatas) do
		data.index = index
	end

	self.itemFeedDatas:update(feedDatas, function(v) return v.index end)
	self.txtInfo:text(panelData.title)

	local curLvSumExp = 0
	if sign then
		if buffInfos.level ~= 0 then
			for count = 1, buffInfos.level do
				curLvSumExp = curLvSumExp + csvBuffAdd[count].roleExp
			end
		end
		self.roleGrade:set(buffInfos.level)
		local lastExp = buffInfos.sum_exp - curLvSumExp
		self.roleExp:set(string.format("%d/%d", lastExp,nextBuffInfo.roleExp))
		local percen = lastExp/nextBuffInfo.roleExp*100
		if signLv then
			self.personMax:show()
			self.personTxtExp:hide()
			percen = 100
		else
			self.personMax:hide()
			self.personTxtExp:show()
		end
		self.roleExpPro:set(percen)

		adapt.oneLinePos(self.personTxtLv,self.personTxtGrade, cc.p(8,0))
	else
		local curLvSumExp = 0
		if buffInfos.level ~= 0 then
			for count = 1, buffInfos.level do
				curLvSumExp = curLvSumExp + csvBuffAdd[count].serverExp
			end
		end
		self.serverGrade:set(buffInfos.level)
		local lastExp = buffInfos.sum_exp - curLvSumExp
		self.serverExp:set(string.format("%d/%d", lastExp,nextBuffInfo.serverExp))
		local percen = lastExp/nextBuffInfo.serverExp*100

		self.serverExpLimit:set(string.format("%d/%d", buffInfos.day_exp,nextBuffInfo.serverExpDayMax))
		local percen2 = buffInfos.day_exp/nextBuffInfo.serverExpDayMax*100

		if signLv then
			self.serverMax:show()
			self.serverTxtExp:hide()
			percen = 100
		else
			self.serverMax:hide()
			self.serverTxtExp:show()
		end
		self.serverExpPro:set(percen)
		self.serverExpProLimit:set(percen2)

		adapt.oneLinePos(self.serverTxtLv,self.serverTxtGrade, cc.p(8,0))
	end

	self.panelPerson:visible(sign)
	self.panelServer:visible(not sign)
end


function CrossMineWishView:onTabClick(list, index)
	self.showTab:set(index)
end

function CrossMineWishView:onItemClick(listview, k, v)
	if self.vip:read() < v.feedVip then
		gGameUI:showTip(gLanguageCsv.redPacketVipLimit)
		return
	end

	local myNum = dataEasy.getNumByKey("coin13")
	if myNum < v.costCoin13 then
		gGameUI:showTip(gLanguageCsv.csvShopCoinNotEnough)
		return
	end
		-- 捐献
	gGameApp:requestServer("/cross/mine/buff/feed", function()
			local awardID, awardVal = csvNext(v.feedAward)
			local cfg = dataEasy.getCfgByKey(awardID)

		gGameUI:showTip(string.format(gLanguageCsv.gameMineWishTip,cfg.name, awardVal,v.feedExp))
	end,self.showTab:read() == 1 and "role" or "server", v.id)
end

function CrossMineWishView:onPersonBtnInfo()
end

function CrossMineWishView:onServerBtnInfo()
end

return CrossMineWishView