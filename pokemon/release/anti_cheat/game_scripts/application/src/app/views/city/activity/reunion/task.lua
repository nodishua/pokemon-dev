-- @date 2020-8-31
-- @desc 训练家重聚 相逢有时任务界面

-- 服务端对应状态 未达成 (不可领取)，可领取，已领取
local STATE_TYPE = {
	noReach = 0,
	canReceive = 1,
	received = 2,
}

-- 展示状态 可领取, 未达成 (不可领取)，已领取
local STATE_TYPE_SHOW = {
	canReceive = 1,
	noReach = 2,
	received = 3,
}

--奖励类型 1-重聚礼包 2-绑定奖励 3-任务奖励 4-积分奖励
local STATE_TYPE_GET =
{
	ReunionGift = 1,
	BindAward = 2,
	TaskAward = 3,
	PointAward = 4,
}

-- 回归玩家-1，老玩家-2
local STATE_ROLE_TYPE = {
	reunion = 1,
	senior = 2,
}

--tab配置信息
local REUNIONTAB_INFO = {
	[1] = {
		name = gLanguageCsv.reunionTaskBack,
		sortWeight = 1,
	},
	[2] = {
		name = gLanguageCsv.reunionTaskAll,
		sortWeight = 2,
	},
	[3] = {
		name = gLanguageCsv.reunionTaskBindInfo,
		sortWeight = 3,
	},
}

local function getShowState(state)
	local showState = STATE_TYPE_SHOW.noReach
	if state and state == STATE_TYPE.canReceive then
		showState = STATE_TYPE_SHOW.canReceive
	elseif state and state == STATE_TYPE.received then
		showState = STATE_TYPE_SHOW.received
	end
	return showState
end

local ReunionTaskView = class("ReunionTaskView", cc.load("mvc").ViewBase)

ReunionTaskView.RESOURCE_FILENAME = "reunion_task.json"
ReunionTaskView.RESOURCE_BINDING = {
	["rightBg"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowRightBg"),
		},
	},
	["topPanel.bg.reunion"] = "topPanelReunion",
	["topPanel.bg.senior"] = "topPanelSenior",
	["topPanel.bg.reunion.title"] = {
		binds = {
			event = "effect",
			data = {
				outline = {color = cc.c4b(255, 217, 121, 255), size = 3},
			},
		},
	},
	["topPanel.bg.reunion.title_0"] = {
		binds = {
			event = "effect",
			data = {
				outline = {color = cc.c4b(162, 60, 17, 255), size = 5},
				shadow = {color = cc.c4b(255, 220, 23, 255), offset = cc.size(0,-3), size = 2}
			},
		},
	},
	["topPanel.bg.senior.title"] = {
		binds = {
			event = "effect",
			data = {
				outline = {color = cc.c4b(162, 60, 17, 255), size = 5},
				shadow = {color = cc.c4b(255, 220, 23, 255), offset = cc.size(0,-3), size = 2}
			},
		},
	},
	["topPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRule")},
		}
	},
	["rightPanel.reunionPanel"] = "reunionPanel",
	["rightPanel.reunionPanel.pageInfo.textPro"] = "pageInfoTextPro",
	["rightPanel.reunionPanel.pageInfo.progress"] = {
		varname = "pageInfoProgressBar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("curPagePro"),
				maskImg = "common/icon/mask_bar_red.png"
			},
		}
	},
	["rightPanel.reunionPanel.pageInfo.box"] = {
		varname = "pageInfoBox",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onBoxGetClick")},
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("pageInfoBoxRedHint"),
					onNode = function(node)
						node:xy(122, 83)
						node:scale(0.8)
					end,
				}
			}
		},

	},
	["rightPanel.reunionPanel.pageInfo.box.imgBox"] = {
		binds = {
			{
				event = "texture",
				idler = bindHelper.self("boxPath"),
			},
		},
	},
	["rightPanel.reunionPanel.taskPanel"] = "taskPanel",
	["rightPanel.reunionPanel.infoPanel"] = "infoPanel",
	["rightPanel.reunionPanel.infoPanel.nameBg.name"] = {
		binds = {
			event = "effect",
			data = {
				outline = {color = ui.COLORS.NORMAL.WHITE, size = 2},
			},
		},
	},
	["rightPanel.tabItem"] = "tabItem",
	["rightPanel.reunionPanel.tabList"] = {
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
				onItem = function(list, node, k, v)
					-- local cfg = v.cfg
					node:get("label"):text(v.name)
					node:setTouchEnabled(not v.selected)
					node:setEnabled(not v.selected)
					text.deleteAllEffect(node:get("label"))

					if v.selected then
						node:setTouchEnabled(v.selected)
						text.addEffect(node:get("label"), {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}})
					else
						text.addEffect(node:get("label"), {color = ui.COLORS.NORMAL.RED})
					end
					bind.click(list, node, {method = functools.partial(list.clickCell, k, v)})
				end,
				asyncPreload = 3,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["rightPanel.item"] = "item",
	["rightPanel.reunionPanel.taskPanel.list"] = {
		varname = "reunionList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("reunionDatas"),
				item = bindHelper.self("item"),
				dataOrderCmp = function(a, b)
					if a.state ~= b.state then
						return a.state < b.state
					end
					return a.csvID < b.csvID
				end,
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					node:get("textCount"):text(cfg.point)
					local childs = node:get("panel"):multiget("textNote1", "textNote2", "list", "btnGet", "textPro", "imgGot", "btnGo")
					uiEasy.createItemsToList(list, childs.list, cfg.award, {scale = 0.9})
					childs.textNote1:text(cfg.theme)
					childs.textNote2:text(cfg.desc)
					childs.textPro:text(v.count.. "/"..cfg.taskParam)
					if v.count < cfg.taskParam then
						text.addEffect(childs.textPro, {color = ui.COLORS.NORMAL.RED})
					else
						text.addEffect(childs.textPro, {color = ui.COLORS.NORMAL.FRIEND_GREEN})
					end
					childs.btnGet:visible(v.state == STATE_TYPE_SHOW.canReceive)
					childs.btnGo:visible(v.state == STATE_TYPE_SHOW.noReach)
					childs.imgGot:visible(v.state == STATE_TYPE_SHOW.received)
					if cfg.goto == "" then
						childs.btnGo:visible(false)
					end
					local size = childs.btnGo:size()
					widget.addAnimationByKey(childs.btnGo:get("panel"), "effect/jiantou.skel", "efc1", "effect_loop", 6)
						:xy(size.width / 2, size.height / 2)
						:scale(0.8)
					bind.touch(list, childs.btnGo, {methods = {ended = functools.partial(list.goCell, cfg.goto)}})
					bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
				asyncPreload = 5,
			},
			handlers = {
				clickCell = bindHelper.self("onReceiveClick"),
				goCell = bindHelper.self("onJumpToClick"),
			},
		},
	},
	["rightPanel.seniorPanel.showTextPanel"] = "seniorShowTextPanel",
	["rightPanel.seniorPanel.textPro"] = "seniorTextPro",
	["rightPanel.seniorPanel.textPro2"] = {
		varname = "seniorTextPro2",
		binds = {
			event = "effect",
			data = {
				color = ui.COLORS.NORMAL.DEFAULT,
				outline = {color = ui.COLORS.NORMAL.WHITE, size = 3},
			},
		},
	},
	["rightPanel.seniorPanel.progress"] = {
		varname = "seniorProgressBar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("curPagePro"),
				maskImg = "common/icon/mask_bar_red.png"
			},
		}
	},
	["rightPanel.seniorPanel.btnGet"] = {
		varname = "seniorBtnGet",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBoxGetClick")},
		},
	},
	["rightPanel.seniorPanel.img.light"] = "seniorPanelLight",
	["rightPanel.seniorPanel.img.redIcon"] = {
		binds = {
			event = "extend",
			class = "red_hint",
			props = {
				state = bindHelper.self("seniorBoxRedHint"),
				onNode = function(node)
					node:xy(20, 20)
				end,
			}
		}
	},
	["rightPanel.seniorPanel.img.imgIcon"] = {
		varname = "seniorPanelImgIcon",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("showBoxAward")},
		},
	},
	["rightPanel.item1"] = "item1",
	["rightPanel.seniorPanel"] = "seniorPanel",
	["rightPanel.seniorPanel.list"] = {
		varname = "seniorList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("seniorDatas"),
				item = bindHelper.self("item1"),
				dataOrderCmp = function(a, b)
					return a.csvID < b.csvID
				end,
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					node:get("textCount"):text(cfg.point)
					local childs = node:get("panel"):multiget("textNote1", "textNote2", "textPro", "imgGot")
					childs.textNote1:text(cfg.theme)
					childs.textNote2:text(cfg.desc)
					childs.textPro:text(v.count.. "/"..cfg.taskParam)
					if v.count < cfg.taskParam then
						text.addEffect(childs.textPro, {color = ui.COLORS.NORMAL.RED})
					else
						text.addEffect(childs.textPro, {color = ui.COLORS.NORMAL.FRIEND_GREEN})
					end
					childs.textPro:visible(v.state ~= STATE_TYPE_SHOW.received)
					childs.imgGot:visible(v.state == STATE_TYPE_SHOW.received)
				end,
				asyncPreload = 5,
			},
		},
	},
}

function ReunionTaskView:onCreate(yyID, params)
	self.yyID = yyID
	local cfg = csv.yunying.yyhuodong[yyID]
	local bindInfo = params.bindInfo
	self.huodongID = cfg.huodongID
	self:initModel(params.reunionRecord)
	local role_type = self.reunion:read().role_type
	self.role_type = role_type

	self.topPanelReunion:visible(role_type == STATE_ROLE_TYPE.reunion)
	self.topPanelSenior:visible(role_type == STATE_ROLE_TYPE.senior)
	self.reunionPanel:visible(role_type == STATE_ROLE_TYPE.reunion)
	self.seniorPanel:visible(role_type == STATE_ROLE_TYPE.senior)

	self.tabType:addListener(function(val, oldval)
		self.taskPanel:visible(val == 1 or val == 2)
		self.infoPanel:visible(val == 3)
		self.isShowRightBg:set(val == 3)
		if oldval then
			self.tabDatas:atproxy(oldval).selected = false
		end
		if val then
			self.tabDatas:atproxy(val).selected = true
		end
		if val == 1 or val == 2 then
			self:updateTaskInfo(role_type, val)
		end
	end)

	idlereasy.any({self.reunion, self.reunionBindPoint, self.reunionValsums}, function(_, reunion, reunionBindPoint, reunionValsums)
		--刷新任务信息 刷新宝箱信息
		local curPoints = reunionBindPoint or 0
		local point_box = reunion.point_box or {}
		local minPoint = 0
		local csvID = nil
		local boxData = {}
		local boxAllData = {}
		--已领取宝箱数
		local getBoxCount = 0
		for k, v in csvPairs(csv.yunying.reunion_point_box) do
			if v.huodongID == self.huodongID then
				local state = point_box[k] or STATE_TYPE.noReach
				table.insert(boxAllData, {csvID = k, cfg = v, state = state, boxGet = state == STATE_TYPE.received})
			end
		end
		table.sort(boxAllData, function (a, b)
			return a.cfg.pointNode < b.cfg.pointNode
		end)
		--最大可领取宝箱数
		local maxBoxCount = #boxAllData

		for k, v in pairs(boxAllData) do
			local state = v.state
			if curPoints < v.cfg.pointNode and minPoint == 0 then
				minPoint = v.cfg.pointNode
			end
			if (state == STATE_TYPE.canReceive or state == STATE_TYPE.noReach) and #boxData == 0 then
				table.insert(boxData, v)
			elseif state == STATE_TYPE.received then
				getBoxCount = getBoxCount + 1
				if getBoxCount == maxBoxCount and #boxData == 0 then
					table.insert(boxData, v)
					minPoint = minPoint == 0 and v.cfg.pointNode or minPoint
					self.haveReceiveAllBox:set(true)
				end
			end
			local key, val = next(boxAllData, k)
			if key == nil and minPoint == 0 then
				minPoint = v.cfg.pointNode
			end
		end
		if role_type == STATE_ROLE_TYPE.reunion then
			self:updateTaskInfo(role_type, self.tabType:read(), reunion, reunionValsums)
			self.pageInfoTextPro:text(curPoints.."/"..minPoint)
			--刷新宝箱
			self.pageInfoBox:get("light"):visible(boxData[1].state == STATE_TYPE_SHOW.canReceive)
			self.pageInfoBoxRedHint:set(boxData[1].state == STATE_TYPE_SHOW.canReceive)
			if self.haveReceiveAllBox:read() then
				self.boxPath:set(boxData[1].cfg.resOpen)
			else
				self.boxPath:set(boxData[1].cfg.res)
			end
			self.pageInfoBox:setTouchEnabled(not self.haveReceiveAllBox:read())
		else
			self.seniorTextPro2:text(curPoints.."/"..minPoint)
			self.seniorTextPro:text(string.format(gLanguageCsv.haveGetBy, getBoxCount, maxBoxCount))
			text.deleteAllEffect(self.seniorBtnGet:get("textNote"))
			if boxData[1] and boxData[1].state == STATE_TYPE_SHOW.canReceive then
				cache.setShader(self.seniorBtnGet, false, "normal")
				text.addEffect(self.seniorBtnGet:get("textNote"), {glow = {color = ui.COLORS.GLOW.WHITE}})
			else
				cache.setShader(self.seniorBtnGet, false, "hsl_gray")
			end
			self.seniorBtnGet:setTouchEnabled(boxData[1] and boxData[1].state == STATE_TYPE_SHOW.canReceive)
			self.seniorPanelLight:setVisible(boxData[1] and boxData[1].state == STATE_TYPE_SHOW.canReceive)
			self.seniorBoxRedHint:set(boxData[1] and boxData[1].state == STATE_TYPE_SHOW.canReceive)
			self:updateTaskInfo(role_type, nil, reunion, reunionValsums)
			self.seniorPanelImgIcon:setTouchEnabled(not self.haveReceiveAllBox:read())
		end
		self.curPagePro:set(math.min(100, curPoints / minPoint * 100))
		self.livenessPoint:set(curPoints)
		self.boxDatas:set(boxData)
	end)

	if role_type == STATE_ROLE_TYPE.reunion then
		self:onTabDatas(1)
		self:showBindInfo(bindInfo)
		self.pageInfoBox:get("light"):runAction(cc.RepeatForever:create(cc.RotateBy:create(30, 360)))
	else
		--显示老玩家界面
		local fontSize = self.seniorShowTextPanel:get("label"):getFontSize()
		local richText = rich.createByStr(gLanguageCsv.reunionTaskBindToText, fontSize)
			:anchorPoint(cc.p(0,0.5))
			:addTo(self.seniorShowTextPanel)
			:xy(self.seniorShowTextPanel:get("label"):xy())
			:formatText()
		self.seniorShowTextPanel:get("bg"):width(richText:width()/0.8 + 20)
		self.seniorPanelLight:runAction(cc.RepeatForever:create(cc.RotateBy:create(30, 360)))
	end
end

function ReunionTaskView:initModel(reunionRecord)
	self.reunionRecord = reunionRecord
	self.reunion = gGameModel.role:getIdler("reunion")
	if self.reunion:read().role_type == STATE_ROLE_TYPE.reunion then
		self.reunionValsums = gGameModel.reunion_record:getIdler("valsums")
		self.reunionBindPoint = gGameModel.reunion_record:getIdler("bind_point")
	else
		self.reunionValsums = idlertable.new(reunionRecord.valsums)
		self.reunionBindPoint = idler.new(reunionRecord.bind_point)
	end

	-- 当前页签进度条进度
	self.curPagePro = idler.new(0)
	self.tabDatas = idlers.new()
	self.reunionDatas = idlers.new()
	self.seniorDatas = idlers.new()
	self.tabType = idler.new()
	self.boxDatas = idlertable.new({})
	self.livenessPoint = idler.new(0)
	-- 箱子资源
	self.boxPath = idler.new("")
	-- 是否显示背景图
	self.isShowRightBg = idler.new(false)
	-- 是否所有宝箱都已经领取了
	self.haveReceiveAllBox = idler.new(false)
	-- 回归玩家是否有宝箱可以领取
	self.pageInfoBoxRedHint = idler.new(false)
	-- 回归玩家是否有宝箱可以领取
	self.seniorBoxRedHint = idler.new(false)
end

function ReunionTaskView:onTabDatas(index)
	local datas = {}
	for i=1, 3 do
		local selected = false
		if index == i then
			selected = true
		end
		table.insert(datas, {k = i, name = REUNIONTAB_INFO[i].name, sortWeight = REUNIONTAB_INFO[i].sortWeight, selected = selected})
	end
	self.tabDatas:update(datas)
	self.tabType:set(index)
end

function ReunionTaskView:updateTaskInfo(role_type, taskType, _reunion, _reunionValsums)
	if role_type == STATE_ROLE_TYPE.reunion and taskType ~= 1 and taskType ~= 2 then return end
	local datas = {}
	local taskDatas = {}
	local syncDatas = {}
	local reunion = _reunion or self.reunion:read()
	local stamps = reunion.stamps or {}
	if role_type == STATE_ROLE_TYPE.senior then
		stamps = self.reunionRecord.stamps or {}
	end
	local valsums = _reunionValsums or self.reunionValsums:read()
	for k, v in csvPairs(csv.yunying.reunion_task) do
		if v.huodongID == self.huodongID and v.themeType == 2 then
			if v.isSync then
				if not syncDatas[v.taskType] then
					syncDatas[v.taskType] = {}
				end
				table.insert(syncDatas[v.taskType], {csvID = k, cfg = v, state = getShowState(stamps[k])})
			else
				if not taskDatas[v.taskType] then
					taskDatas[v.taskType] = {}
				end
				table.insert(taskDatas[v.taskType], {csvID = k, cfg = v, state = getShowState(stamps[k])})
			end
		end
	end
	local function getDatas(tableDatas)
		local datas1 = {}
		for k, v in pairs(tableDatas) do
			table.sort(v, function (a, b)
				if a.state ~= b.state and role_type == STATE_ROLE_TYPE.reunion then
					return a.state < b.state
				end
				return a.cfg.taskLinks < b.cfg.taskLinks
			end)
			for k1, v1 in pairs(v) do
				local key, val = next(v, k1)
				if v1.state == STATE_TYPE_SHOW.canReceive or v1.state == STATE_TYPE_SHOW.noReach or key == nil then
					local count = valsums[k] and valsums[k][1] or 0
					if v1.cfg.isCooperative then
						local valsums2 = valsums[k] and valsums[k][2] or 0
						count = math.min(count, valsums2)
					end
					table.insert(datas1, {csvID = v1.csvID, cfg = v1.cfg, state = v1.state, count = count})
					break
				end
			end
		end
		return datas1
	end
	if role_type == STATE_ROLE_TYPE.reunion then
		if taskType == 1 then
			datas = getDatas(taskDatas)
		elseif taskType == 2 then
			datas = getDatas(syncDatas)
		end
		self.reunionDatas:update(datas)
	else
		datas = getDatas(syncDatas)
		self.seniorDatas:update(datas)
	end
end

function ReunionTaskView:showBindInfo(bindInfo)
	local info = bindInfo
	local childs = self.infoPanel:multiget("playerPanel", "bindLabel", "name", "lv", "infoList", "power", "guild", "nameBg", "playerBtn", "nameLabel", "powerLabel", "lvLabel", "guildLabel")

	childs.nameBg:get("name"):text(info.name)
	childs.name:text(info.name)
	childs.lv:text(info.level)
	childs.guild:text(info.union_name ~= "" and info.union_name or gLanguageCsv.none)
	childs.power:text(info.battle_fighting_point)

	childs.playerPanel:removeAllChildren()
	local cfg = gRoleFigureCsv[info.figure]
	local x, y = childs.playerPanel:width()/2, 0
	local sp = cc.Sprite:create(cfg.res)
		:anchorPoint(0.5, 0.5)
		:xy(x, y)
		:addTo(childs.playerPanel, 2)

	beauty.textScroll({
		list = childs.infoList,
		strs = info.personal_sign ~= "" and info.personal_sign or gLanguageCsv.soLazy,
		fontSize = 36,
	})
	childs.bindLabel:removeAllChildren()
	local str = string.format(gLanguageCsv.reunionTaskOldText, info.name)
	rich.createWithWidth(str, 36, nil, 800)
		:addTo(childs.bindLabel, 2)
		:anchorPoint(0, 0.5)
		:xy(0,0)

	adapt.oneLinePos(childs.nameLabel, childs.name, cc.p(5, 0), "left")
	adapt.oneLinePos(childs.guildLabel, childs.guild, cc.p(5, 0), "left")
	adapt.oneLinePos(childs.lvLabel, childs.lv, cc.p(5, 0), "left")
	adapt.oneLinePos(childs.powerLabel, childs.power, cc.p(5, 0), "left")
	childs.playerBtn:onClick(functools.partial(self.onBindHeadBtnClick, self, info))
end

function ReunionTaskView:onTabClick(list, k, v)
	self.tabType:set(k)
end

function ReunionTaskView:onReceiveClick(list, k, v)
	self:onGetAward(v.csvID, STATE_TYPE_GET.TaskAward, function (tb)
		gGameUI:showGainDisplay(tb)
	end)
end

function ReunionTaskView:onJumpToClick(list, goto)
	if goto ~= "" then
		jumpEasy.jumpTo(goto)
	end
end

function ReunionTaskView:onPointReceiveClick(csvID)
	self:onGetAward(csvID, STATE_TYPE_GET.PointAward, function (tb)
		gGameUI:showGainDisplay(tb)
	end)
end

function ReunionTaskView:onGetAward(csvID, awardType, cb)
	if self.reunion:read().info.end_time - time.getTime() < 0 then
		gGameUI:showTip(gLanguageCsv.activityOver)
		return
	end
	gGameApp:requestServer("/game/yy/reunion/award/get", function(tb)
		if cb then
			cb(tb)
		end
	end, self.yyID, csvID, awardType)
end

-- 规则按钮
function ReunionTaskView:onRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function ReunionTaskView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.reunionRule)
		end),
		c.noteText(148),
		c.noteText(101001, 101020),
	}
	return context
end

--玩家信息
function ReunionTaskView:onBindHeadBtnClick(info, event)
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
	pos.x = pos.x + 250
	pos.y = pos.y + 600
	gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, {role = info})
end

-- 开宝箱
function ReunionTaskView:onBoxGetClick()
	local data = self.boxDatas:proxy()[1]
	if self.livenessPoint:read() >= data.cfg.pointNode and not data.boxGet then
		--领取宝箱奖励
		self:onGetAward(data.csvID, STATE_TYPE_GET.PointAward,function (tb)
			gGameUI:showGainDisplay(tb)
		end)
	else
		self:showBoxAward()
	end
end

function ReunionTaskView:showBoxAward()
	local data = self.boxDatas:proxy()[1]
	--显示奖励
	local award = data.cfg.award1
	if self.role_type == STATE_ROLE_TYPE.reunion then
		award = data.cfg.award2
	end
	gGameUI:showBoxDetail({
		data = award,
		content = string.format(gLanguageCsv.canReceivedByScore .. "", data.cfg.pointNode),
		state = data.boxGet == true and 0 or 1
	})
end

return ReunionTaskView