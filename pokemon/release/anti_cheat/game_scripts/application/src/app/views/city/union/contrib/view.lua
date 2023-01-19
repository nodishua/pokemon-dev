-- @date:   2019-06-11
-- @desc:   公会捐献主界面

local TYPE = {
	"city/union/contribute/logo_l.png",
	"city/union/contribute/logo_c.png",
}

local TYPETEXT = {
	gLanguageCsv.everyday,
	gLanguageCsv.everyweek
}

local USERTYPE = {
	"city/union/contribute/logo_l1.png",
	"city/union/contribute/logo_z.png",
}

local USERTYPETEXT = {
	gLanguageCsv.personal,
	gLanguageCsv.guild
}

local BGICON = {
	"city/union/contribute/img_dt_l.png",
	"city/union/contribute/img_dt_c.png",
}

local UnionContribView = class("UnionContribView", Dialog)

UnionContribView.RESOURCE_FILENAME = "union_contribute_main.json"
UnionContribView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["left.textUnionLvNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("unionLv"),
		},
	},
	["left.textUnionExpNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("unionCurLvExp"),
		},
	},
	["left.textCount"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("leftCount"),
		},
	},
	["left.progress"] = {
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("unionExpPro"),
				maskImg = "common/icon/mask_bar_red.png"
			},
		},
	},
	["left.btnContrbute"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onContrbuteClick")},
		},
	},
	["left.btnRule"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onRuleClick")},
			},
			{
				event = "visible",
				idler = bindHelper.self("isMaxLv"),
				method  = function(isMaxLv)
					return not isMaxLv
				end,
			},
		},
	},
	["top.textCount"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("allCount"),
		},
	},
	["top.textNote"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("tipNote"),
		},
	},
	["top.textProgress"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("textProgress"),
		},
	},
	["top.bar"] = {
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("weekExpPro"),
				maskImg = "common/icon/mask_bar_red.png"
			},
		},
	},
	["maskPanel"] = "maskPanel",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("contrubuteDatas"),
				item = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortDatas", true),
				asyncPreload = 5,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local path = TYPE[v.cfg.type]
					local showTxt = TYPETEXT[v.cfg.type]
					node:get("imgFlagBg1"):texture(path)
					node:get("textFlag1"):text(showTxt)
					path = USERTYPE[v.cfg.userType]
					showTxt = USERTYPETEXT[v.cfg.userType]
					node:get("imgFlagBg2"):texture(path)
					node:get("textFlag2"):text(showTxt)
					path = BGICON[v.cfg.type]
					node:get("imgTypeBg"):texture(path)
					node:get("textProgress"):text(string.format("%s/%s", v.info[1], v.cfg.targetDisplay))
					node:get("textContent"):text(v.cfg.desc)

					node:get("imgFlagBg1"):width(node:get("textFlag1"):width() + 20)
					node:get("imgFlagBg2"):width(node:get("textFlag2"):width() + 20)

					adapt.oneLinePos(node:get("imgFlagBg1"),node:get("imgFlagBg2"),cc.p(20,0))
					node:get("textFlag1"):x(node:get("imgFlagBg1"):x())
					node:get("textFlag2"):x(node:get("imgFlagBg2"):x())

					local color = ui.COLORS.NORMAL.ALERT_ORANGE
					if v.info[1] >= tonumber(v.cfg.targetDisplay) then
						color = ui.COLORS.NORMAL.FRIEND_GREEN
					end
					text.addEffect(node:get("textProgress"), {color = color})
					local y = 112
					local canGet = false
					showTxt = gLanguageCsv.goto
					-- 满足领取条件
					node:get("btnGet"):loadTextureNormal("common/btn/btn_leave.png")
					if v.state == 1 then
						showTxt = gLanguageCsv.commonTextGet
						node:get("btnGet"):loadTextureNormal("common/btn/btn_normal.png")
						y = 160
						canGet = true
						local size = node:size()

					elseif v.state ~= 2 and v.cfg.goToPanel then
						y = 160
						canGet = true
					end
					node:get("textProgress"):y(y)
					node:get("btnGet"):visible(canGet)
					node:get("btnGet.textNote"):text(showTxt)
					text.addEffect(node:get("btnGet.textNote"), {glow = {color = ui.COLORS.GLOW.WHITE}})
					node:get("textProgress"):visible(not (v.state == 2))
					node:get("imgDown"):visible(v.state == 2)

					local award = {}
					for k,v in csvMapPairs(v.cfg.award) do
						award[k] = v
					end
					award.contrib = v.cfg.contrib
					uiEasy.createItemsToList(list, node:get("listview"), award, {scale = 0.8})
					bind.touch(list, node:get("btnGet"), {methods = {
						ended = functools.partial(list.clickCell, k, v, node)
					}})
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
}

function UnionContribView:onCreate()
	self.list:setName("contribList") -- 引导名
	self:initModel()
	local unionInfo = csv.union.union_level[self.unionLv:read()]
	self.unionExpPro = idler.new(0)
	self.weekExpPro = idler.new(0)
	self.unionCurLvExp = idler.new("")
	self.leftCount = idler.new("")
	self.allCount = idler.new(0)
	self.tipNote = idler.new("")
	self.textProgress = idler.new("")

	self.contrubuteDatas = idlers.newWithMap({})
	idlereasy.any({self.unionTasks, self.tasks}, function(_, unionTasks, tasks)
		local contrubuteDatas = {}
		for k,v in orderCsvPairs(csv.union.union_task) do
			if matchLanguage(v.languages) then
				local data = {}
				data.cfg = v
				data.csvId = k
				local taskInfo = unionTasks[k]
				if data.cfg.userType == 2 then
					data.info = taskInfo or (tasks[k] or {0, 0})
					if taskInfo and taskInfo[2] == 2 then
						data.state = 2
					else
						data.state = tasks[k] and tasks[k][2] or 0
					end
				else
					data.info = taskInfo or {0, 0}
					data.state = taskInfo and taskInfo[2] or 0
				end
				table.insert(contrubuteDatas, data)
			end
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.contrubuteDatas:update(contrubuteDatas)
	end)

	local listertab = {self.unionLv, self.unionExp, self.contribCount, self.weekExp}
	idlereasy.any(listertab, function(_, unionLv, unionlExp, contribCount, weekExp)
		local cfg = csv.union.union_level
		local nextExp = cfg[unionLv].levelUpContrib
		local allExp = 0
		for i=1,unionLv - 1 do
			allExp = allExp + cfg[i].levelUpContrib
		end
		local curExp = unionlExp - allExp
		self.unionCurLvExp:set(string.format("%d/%d", curExp, nextExp))
		local percent = curExp / nextExp * 100
		self.unionExpPro:set(percent)

		local contribMax = cfg[unionLv].ContribMax
		self.leftCount:set(string.format("%d/%d", contribMax - contribCount, contribMax))

		local curTaskMax = cfg[unionLv].taskExpMax
		self.allCount:set(weekExp)
		self.tipNote:set(string.format(gLanguageCsv.taskUnionExpMax, curTaskMax))
		self.textProgress:set(string.format("%d/%d", weekExp, curTaskMax))
		local percent = weekExp / curTaskMax * 100
		self.weekExpPro:set(percent)

		self.isMaxLv = idler.new(csvSize(cfg) <= unionLv)
	end)

	Dialog.onCreate(self)
end

function UnionContribView:initModel()
	-- 0 未完成 1 可领取 2 已领取
	self.unionTasks = gGameModel.role:getIdler("union_contrib_tasks")
	local unionInfo = gGameModel.union
	self.unionLv = unionInfo:getIdler("level")
	self.unionDayExp = unionInfo:getIdler("day_contrib") -- 每日的捐献经验
	self.unionExp = unionInfo:getIdler("contrib") -- 公会的总经验
	self.weekExp = unionInfo:getIdler("week_task_contrib") -- 每周的任务经验
	-- 0 未完成 1 可领取
	self.tasks = unionInfo:getIdler("contrib_tasks") -- 公会任务信息
	local dailyRecord = gGameModel.daily_record
	self.contribCount = dailyRecord:getIdler("union_contrib_times")
end

function UnionContribView:onItemClick(listview, k, v, item)
	-- 未完成 可跳转
	if v.state == 0 and v.cfg.goToPanel then
		jumpEasy.jumpTo(v.goToPanel)
	end
	-- 领取
	if v.state == 1 then
		gGameApp:requestServer("/game/union/contrib/task", function(tb)
			-- local effect = item:get("effect")
			-- if effect then
			-- 	effect:removeFromParent()
			-- end
			gGameUI:showGainDisplay(tb)
		end, v.csvId)
	end
end

function UnionContribView:onContrbuteClick()
	gGameUI:stackUI("city.union.contrib.contrib_info")
end

function UnionContribView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 860})
end

function UnionContribView:getRuleContext(view)
	local unionLv = gGameModel.union:read("level")
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.levelIntro)
		end),
		string.format(gLanguageCsv.unionLvUpTip, unionLv + 1),
	}
	local info = csv.union.union_level[unionLv + 1]
	for i = 1,math.huge do
		if not info["notice"..i] or info["notice"..i] == "" then
			break
		end
		table.insert(context, string.format("  %d.%s", i, info["notice"..i]))
	end
	return context
end

function UnionContribView:onSortDatas(list)
	return function(a, b)
		local stateA = a.info[2]
		local stateB = b.info[2]
		if stateA == stateB then
			return a.cfg.sortID < b.cfg.sortID
		end
		if stateA == 2 then
			return false
		end
		if stateB == 2 then
			return true
		end

		return stateA > stateB
	end
end
function UnionContribView:onAfterBuild()
	uiEasy.setBottomMask(self.list, self.maskPanel)
end

return UnionContribView