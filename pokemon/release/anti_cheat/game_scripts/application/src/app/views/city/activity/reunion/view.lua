-- @date 2020-08-27
-- @desc 训练家重聚主界面

-- 角色类型  1 回归 2 资深玩家
local STATE_ROLE_TYPE = {
	reunion = 1,
	senior = 2,
}

local RED_HINTS = {
	["gift"] = {
		specialTag = "reunionGift",
	},
	["sign"] = {
		specialTag = "reunionSign",
	},
	["reunion"] = {
		specialTag = "reunionTask",
	},
	["bindPlayer"] = {
		specialTag = "reunionBindGift",
	},
}

local REUNION_SHOW_INFO = {
	["gift"] = {
		name = gLanguageCsv.reunionGift,
		viewName = "city.activity.reunion.gift",
		sortWeight = 1,
	},
	["sign"] = {
		name = gLanguageCsv.reunionSign,
		viewName = "city.activity.reunion.sign",
		sortWeight = 2,
	},
	["catch"] = {
		name = gLanguageCsv.reunionCatchUp,
		viewName = "city.activity.reunion.catchup",
		sortWeight = 3,
	},
	["reunion"] = {
		name = gLanguageCsv.reunionActivity,
		viewName = "city.activity.reunion.reunion",
		sortWeight = 4,
	},
	["recharge"] = {
		name = gLanguageCsv.reunionRecharge,
		viewName = "city.activity.reunion.recharge",
		sortWeight = 5,
	},
	["bindPlayer"] = {
		name = gLanguageCsv.reunionBind,
		viewName = "city.activity.reunion.bind_player",
		sortWeight = 3,
	},
}

local ViewBase = cc.load("mvc").ViewBase
local ReunionView = class("ReunionView", ViewBase)
ReunionView.RESOURCE_FILENAME = "reunion.json"
ReunionView.RESOURCE_BINDING = {
	["leftPanel"] = "leftPanel",
	["leftPanel.leftTime"] = {
		varname = "leftTime",
		binds = {
			event = "effect",
			data = {
				color = cc.c4b(91,84,91,255),
			},
		}
	},
	["leftPanel.timeLabel"] = {
		varname = "timeLabel",
		binds = {
			event = "effect",
			data = {
				color = cc.c4b(91,84,91,255),
			},
		}
	},
	["leftPanel.item"] = "tabItem",
	["leftPanel.list"] = {
		varname = "tabList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				dataOrderCmp = function(a, b)
					return a.sortWeight < b.sortWeight
				end,
				onItem = function(list, node, name, v)
					local cfg = csv.yunying.yyhuodong[id]
					adapt.setTextScaleWithWidth(node:get("name"), REUNION_SHOW_INFO[name].name, node:width() - 40)
					node:get("line"):texture("login/box_tagline.png"):visible(not v.isLast)
					if RED_HINTS[name] then
						local props = RED_HINTS[name]
						props.state = not v.selected
						bind.extend(list, node, {
							class = "red_hint",
							props = props,
						})
					end
					node:get("selected"):texture("login/tab_popupsel.png"):visible(v.selected)
					if v.selected then
						text.addEffect(node:get("name"), {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
					else
						text.deleteAllEffect(node:get("name"))
						text.addEffect(node:get("name"), {color = ui.COLORS.NORMAL.DEFAULT})
					end
					bind.click(list, node, {method = functools.partial(list.clickCell, name, v)})
				end,
				asyncPreload = 5,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
}

function ReunionView:onCreate(param)
	local info = param.info
	local reunionRecord = param.reunionRecord
	self.reunion = gGameModel.role:getIdler("reunion")

	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.reunion, subTitle = "ACTIVITY"})

	self.subViews = {}
	self.activityName = idler.new(self.activityName or nil)
	-- self.index = idler.new(self.index or 1)
	self.tabDatas = idlers.new()
	self.yyID = self.reunion:read().info.yyID
	local cfg = csv.yunying.yyhuodong[self.yyID]
	local huodongInfo = cfg.paramMap.huodong
	self.role_type = self.reunion:read().role_type
	local selectName = not self.activityName:read() and huodongInfo[1] or self.activityName:read()
	--判断老玩家 还是 回归玩家，老玩家只显示相逢有时
	if self.role_type == STATE_ROLE_TYPE.reunion and huodongInfo[1] then
		self:onTabData(selectName)
	elseif self.role_type == STATE_ROLE_TYPE.senior then
		selectName = ""
		for k, val in pairs(huodongInfo) do
			if val == "reunion" then
				self:onTabData(val)
				selectName = val
			end
		end
	end

	self.activityName:addListener(function(val, oldval)
		if oldval then
			self.tabDatas:atproxy(oldval).selected = false
		end
		if val then
			self.tabDatas:atproxy(val).selected = true
		end
		if self.subViews[oldval] then
			self.subViews[oldval]:hide()
		end
		local cfg = csv.yunying.yyhuodong[self.yyID]
		if cfg then
			local viewData = REUNION_SHOW_INFO[val]
			if viewData then
				if not self.subViews[val] then
					local params = {bindInfo = info, reunionRecord = reunionRecord}
					self.subViews[val] = gGameUI:createView(viewData.viewName, self):init(self.yyID, params)
				else
					self.subViews[val]:show()
				end
			else
				printWarn("activityType(%d) was not define", cfg.type)
			end
		end
	end)
	if selectName ~= "" then
		self.activityName:set(selectName)
		if self.role_type == STATE_ROLE_TYPE.senior then
			self.activityName:set("bindPlayer")
		end
	end


	-- 活动刷新时，刷新d倒计时
	idlereasy.when(self.reunion, function(_, reunion)
		local countdown = reunion.info.end_time - time.getTime()
		self:setCountdown(countdown, self.timeLabel, self.leftTime)
	end)
end

function ReunionView:onTabClick(list, name, data)
	self.activityName:set(name)
end

function ReunionView:onTabData(name)
	local index = 1
	local datas = {}
	local keys = {}
	local isSelected = false
	local cfg = csv.yunying.yyhuodong[self.yyID]
	local huodongInfo = cfg.paramMap.huodong
	for _,v in ipairs(huodongInfo) do
		local function insertTab(v)
			datas[v] = {name = v, sortWeight = REUNION_SHOW_INFO[v].sortWeight, selected = false}
			table.insert(keys, datas[v])
			if name and (name == v or v == "bindPlayer")then
				datas[v].selected = true
				isSelected = true
			end
		end
		if self.role_type == STATE_ROLE_TYPE.reunion then
			insertTab(v)
		elseif self.role_type == STATE_ROLE_TYPE.senior and v == name then
			insertTab("bindPlayer")
			insertTab(v)
		end
	end
	table.sort(keys, function(a, b)
		return a.sortWeight < b.sortWeight
	end)
	if #keys >= 1 then
		datas[keys[#keys].name].isLast = true
	end
	if not isSelected then
		index = math.min(index, #keys)
		if index <= 0 then
			name = nil
			printWarn("no open activity!!!")
		else
			local data = datas[keys[index].name]
			data.selected = true
			name = data.name
		end
	end
	self.tabDatas:update(datas)
end

-- @param params: {tag, labelChangeCb}
function ReunionView:setCountdown(countdown, uiTimeLabel, uiTime)
	self:enableSchedule():unSchedule(1)

	countdown = countdown > 0 and countdown or 0
	if countdown == 0 then return end

	bind.extend(self, uiTime, {
		class = 'cutdown_label',
		props = {
			time = countdown,
			tag = 1,
			strFunc = function(t)
				return t.str
			end,
			callFunc = function()
			end,
			endFunc = function()
				countdown = self.reunion:read().info.end_time - time.getTime()
				if countdown > 0 then
					performWithDelay(self, function()
						self:setCountdown(countdown, uiTimeLabel, uiTime)
					end, 1)
				else
					uiTimeLabel:text(gLanguageCsv.activityOver)
				end
			end
		}
	})
end

function ReunionView:onCleanup()
	self.activityName = self.activityName:read()
	ViewBase.onCleanup(self)
end

return ReunionView