local GET_TYPE = {
	GOTTEN = 0, 	--已领取
	CAN_GOTTEN = 1, --可领取
	CAN_NOT_GOTTEN = 2, --未完成
}

local function setBtnState(btn, state)
	btn:setTouchEnabled(state)
	cache.setShader(btn, false, state and "normal" or "hsl_gray")
	if state then
		text.addEffect(btn:get("txt"), {glow={color=ui.COLORS.GLOW.WHITE}})
	else
		text.deleteAllEffect(btn:get("txt"))
		-- text.addEffect(btn:get("txt"), {color = ui.COLORS.DISABLED.WHITE})
	end
end

local SkyScraperRewardView = class("SkyScraperRewardView", Dialog)

SkyScraperRewardView.RESOURCE_FILENAME = "sky_scraper_reward.json"
SkyScraperRewardView.RESOURCE_BINDING = {
	["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	----------------------------------------------leftPanel----------------------------------------------------
	["leftPanel"] = "leftPanel",
	["leftPanel.icon"] = "icon",
	["leftPanel.barPanel"] = "barPanel",
	["leftPanel.bar"] = {
		varname = "bar",
		binds = {
		  event = "extend",
		  class = "loadingbar",
		  props = {
			data = bindHelper.self("curPagePro"),
		  },
		}
	  },
	["leftPanel.barPanel.txt"] = "barTxt",
	["leftPanel.max"] = "max",
	["leftPanel.box"] = {
		varname = "box",
		binds = {
            event = "touch",
            methods = {ended = bindHelper.self("onBoxClick")},
        },
	},
	----------------------------------------------rightPanel---------------------------------------------------
	["rightPanel.tabItem"] = "tabItem",
	["rightPanel.tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				showTab = bindHelper.self("showTab"),
				padding = 5,
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
					if v.redHint then
						bind.extend(list, node, {
							class = "red_hint",
							props = {
								state = list.showTab:read() ~= k,
								specialTag = v.redHint,
								listenData = {
									id = v.id,
								},
								onNode = function (red)
									red:xy(node:width() + 5, node:height() + 5)
								end
							},
						})
					end
					panel:get("txt"):text(v.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["rightPanel.centerItem"] = "centerItem",
	["rightPanel.centerList"] = {
		varname = "centerList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 5,
				data = bindHelper.self("centerData"),
				item = bindHelper.self("centerItem"),
				padding = 5,
				itemAction = {isAction = true},
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "taskName", "taskNumTxt","btnGet","itemList","got")
					if next(v.award) ~= nil then
						uiEasy.createItemsToList(list, childs.itemList, v.award, {scale = 0.7, margin = 20})
					end
					childs.taskName:text(v.label)
					childs.icon:get("txt"):text(v.points)
					local had = v.had or 0
					childs.taskNumTxt:text(had.."/"..v.params)
					bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, v.csvId)}})
					--0已领取，1可领取
					if v.get == GET_TYPE.GOTTEN then
						childs.btnGet:visible(false)
						childs.got:visible(true)
						childs.taskNumTxt:visible(false)
					else
						setBtnState(childs.btnGet, v.get == GET_TYPE.CAN_GOTTEN)
						text.addEffect(childs.taskNumTxt, {color = had >= v.params and cc.c4b(96, 196, 86, 255) or cc.c4b(247, 107, 67, 255)})
						childs.btnGet:visible(true)
						childs.got:visible(false)
						childs.taskNumTxt:visible(true)
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onGetBtn"),
			},
		},
	},
	["rightPanel.btnOneKey"] = {
		varname = "getBtn1",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOneKey")}
		},
	},
	["rightPanel.btnOneKey.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
}

function SkyScraperRewardView:onCreate(activityId)
	self.activityId = activityId
	self.showTab = idler.new(1)
	self:initModel()
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yydata = yyhuodongs[self.activityId] or {}
		self.yydata = yydata
		self:initLeft()
		self:initRight(self.activityId)
	end)
	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		self:initRight(self.activityId)
	end)
	Dialog.onCreate(self)
end

function SkyScraperRewardView:initModel()
	self.centerData = idlers.newWithMap({})
	self.curPagePro = idler.new(0)
	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.skyScraperS, redHint = "skyScraperSetTask",id = self.activityId},
		[2] = {name = gLanguageCsv.skyScraperScoreTask, redHint = "skyScraperScoreTask",id = self.activityId},
		[3] = {name = gLanguageCsv.skyScraperPerfectStructures, redHint = "skyScraperPerfectStructures",id = self.activityId},
	})
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function SkyScraperRewardView:onTabClick(list, index)
	self.showTab:set(index)
end

function SkyScraperRewardView:onGetBtn(list, csvId)
	gGameApp:requestServer("/game/yy/skyscraper/awards", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId,csvId,0)
end
--更新左边Panel
function SkyScraperRewardView:initLeft()
	local yycfg = csv.yunying.yyhuodong[self.activityId]
    self.huodongId = yycfg.huodongID
	local cfg = csv.yunying.skyscraper_medals
	local info = self.yydata.info or {}
	local taskNum = info.task_points or 0
	local curPro = 0	--当前进度条
	local stamps1 = self.yydata.stamps1 or {}
	local cal = 0 --计算勋章值
	local maxLevelIndex = 1
	local curLevelIndex = 0
	for k, val in orderCsvPairs(cfg) do
		if val.huodongID == self.huodongId then
			maxLevelIndex = val.medalLevel > cfg[maxLevelIndex].medalLevel and k or maxLevelIndex
		end
	end
	for k, v in orderCsvPairs(cfg) do
		if v.huodongID == self.huodongId then
			cal = cal + v.points
			if cal > taskNum then
				curLevelIndex = k
				curPro = taskNum - (cal - v.points)
				break
			end
		end
	end
	--最大等级
	if curLevelIndex == 0 then
		curLevelIndex = maxLevelIndex
		self.curPagePro:set(100)
		self.max:visible(true)
		self.barPanel:visible(false)
	else
		self.curPagePro:set(math.min(100, curPro / cfg[curLevelIndex].points * 100))
		self.max:visible(false)
		self.barPanel:visible(true)
		self.barTxt:text(curPro.."/"..cfg[curLevelIndex].points)
	end
	self.icon:texture(cfg[curLevelIndex].resource)
	self.icon:get("imgRank"):texture(cfg[curLevelIndex].resourceNum)
	self.icon:get("textRank"):text(gLanguageCsv[cfg[curLevelIndex].medalsName])
	self.icon:get("textRank"):setTextColor(cc.c3b(unpack(cfg[curLevelIndex].color)))

	--宝箱
	local open = false
	for k, v in pairs(stamps1) do
		if v == 1 then
			open = true
			break
		end
	end
	self.box:visible(true)
	if open then
		local effect = widget.addAnimationByKey(self.leftPanel, "effect/jiedianjiangli.skel", "effect", "effect_loop", 1)
			:xy(self.box:x(),self.box:y() - 50)
	else
		self.leftPanel:removeChildByName("effect")
		if curMedal == cfg[maxLevelIndex].medalLevel + 1 then
			self.box:visible(false)
			self.leftPanel:removeChildByName("effect")
		end
	end
end
--更新右侧Panel
function SkyScraperRewardView:initRight(activityId)
	local data1 = {}
	local data2 = {}
	local data3 = {}
	local btnAllGetState = false
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID
	local info = self.yydata.info or {}
	for i, v in csvPairs(csv.yunying.skyscraper_tasks) do
		if v.huodongID == huodongID then
			local data = table.shallowcopy(v)
			data.csvId = i
			local stamps = self.yydata.stamps or {} --修改
			data.get = stamps[i]
			if data.get == 1 and v.type == 1 then
				btnAllGetState = true
			elseif data.get == 1 and v.type == 2 then
				btnAllGetState = true
			elseif data.get == 1 and v.type == 3 then
				btnAllGetState = true
			end
			if v.type == 1 then
				data.had = info.floors
				table.insert(data1, data)
			elseif v.type == 2 then
				data.had = info.points
				table.insert(data2, data)
			elseif v.type == 3 then
				data.had = info.perfections
				table.insert(data3, data)
			end
		end
	end
	if self.showTab:read() == 1 then
		self.centerData:update(data1)
	elseif self.showTab:read() == 2 then
		self.centerData:update(data2)
	else
		self.centerData:update(data3)
	end
	setBtnState(self.getBtn1, btnAllGetState)
end
--宝箱
function SkyScraperRewardView:onBoxClick()
	local yycfg = csv.yunying.yyhuodong[self.activityId]
    self.huodongId = yycfg.huodongID
	local stamps1 = self.yydata.stamps1 or {}
	local info = self.yydata.info or {}
	local taskNum = info.task_points or 0
	local curAward = {}
	local cal = 0 --计算勋章值
	for k, v in orderCsvPairs(csv.yunying.skyscraper_medals) do
		if v.huodongID == self.huodongId then
			cal = cal + v.points
			if cal > taskNum then
				curAward = v.award
				break
			end
		end
	end
	local open = false
	local min
	for k, v in pairs(stamps1) do
		if v == 1 then
			open = true
			if min == nil then
				min = k
			elseif k < min then
				min = k
			end
		end
	end
	if open then
		gGameApp:requestServer("/game/yy/skyscraper/awards", function(tb)
			gGameUI:showGainDisplay(tb)
		end, self.activityId,min,1)
	else
		if itertools.size(curAward) ~= 0 then
			local str = gLanguageCsv.skyScraperBoxTip
			gGameUI:showBoxDetail({
				data = curAward,
				content = str,
				state = 1
			})
		end
	end
end
function SkyScraperRewardView:onSortCards(list)
	return function(a, b)
		local va = a.get or 0.5
		local vb = b.get or 0.5
		if va ~= vb then
			return va > vb
		end
		return a.csvId < b.csvId
	end
end

function SkyScraperRewardView:onOneKey()
	gGameApp:requestServer("/game/yy/award/get/onekey",function (tb)
		gGameUI:showGainDisplay(tb)
	end,self.activityId)
end


return SkyScraperRewardView
