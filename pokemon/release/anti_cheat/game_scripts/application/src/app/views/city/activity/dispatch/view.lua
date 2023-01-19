local ViewBase = cc.load("mvc").ViewBase
local DispatchView = class("DispatchView",ViewBase)

DispatchView.RESOURCE_FILENAME = "activity_dispatch_main.json"
DispatchView.RESOURCE_BINDING = {
    ["leftDownPanel.btnRule.textNote"] = {
		varname = "ruleNote",
		binds = {
			event = "effect",
			data = {outline={color= cc.c4b(90, 84, 91, 255), size = 3}},
		}
	},
	["leftDownPanel.btnRule"] = {
		varname = "btnRule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRuleClick")}
		}
	},
	["leftDownPanel.btnTask"] = {
		varname = "btnTask",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onBtnTaskClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "dispatchTaskType",
					listenData = {
						activityId = bindHelper.self("activityId"),
					},
					onNode = function(node)
						node:xy(120, 135)
					end,
				}
			}
		},
	},
	["leftDownPanel.btnTask.textNote"] = {
		varname = "ruleNote",
		binds = {
			event = "effect",
			data = {outline={color= cc.c4b(90, 84, 91, 255), size = 3}},
		}
	},
	["scrollView"] = {
		varname = "scrollView",
		binds = {
			event = "scrollBarEnabled",
			data = false,
		}
	},
	["item"] = "item",
	["item.cdPanel.text"] = {
		binds = {
			event = "effect",
			data = {outline={color= cc.c4b(255, 252, 237, 255), size = 3}},
		}
	},
	["rightDownPanel.textCountDown"] = {
		varname = "textCountDown",
		binds = {
			event = "effect",
			data = {outline={color= cc.c4b(91, 84, 91, 255), size = 3}},
		}
	},
	["rightDownPanel.textNote"] = {
		varname = "textCountDownNote",
		binds = {
			event = "effect",
			data = {outline={color= cc.c4b(91, 84, 91, 255), size = 3}},
		}
	},
}


-- 计算出所有的点并且加的关卡上
local function getAllPassPoints(node, info, off)
	local function getPosintes(startPoint, endedPoint)
		local pointes = {}
		table.insert(pointes, {x = startPoint.x, y = startPoint.y})

		local offx = math.abs(endedPoint.x - startPoint.x)
		local offy = math.abs(endedPoint.y - startPoint.y)
		local off = math.max(offx, offy)
		local num = math.max(0, math.floor(off / 45) - 1)
		for i=1, num do
			local vecX = endedPoint.x >= startPoint.x and 1 or -1
			local vecY = endedPoint.y >= startPoint.y and 1 or -1
			local disx = offx / (num + 1)
			local x = startPoint.x + i * disx * vecX + math.random(0, 8)
			local disy = offy / (num + 1)
			local y = startPoint.y + i * disy * vecY + math.random(0, 8)
			table.insert(pointes, {x = x, y = y})
		end
		return pointes
	end

	local pathPointes = {}
	for i=2, itertools.size(info.frontWay or {}) do
		local sp = info.frontWay[i - 1]
		local ep = info.frontWay[i]
		local pt = getPosintes({x = sp[1], y = sp[2]}, {x = ep[1], y = ep[2]})
		for _,pos in ipairs(pt) do
			local point = cc.Sprite:create("city/gate/logo_path.png")
			point:visible(false)
			point:xy(pos.x + off, pos.y)
			node:addChild(point, 9, "point")
			table.insert(pathPointes, point)
		end
	end
	return pathPointes
end

function DispatchView:onBtnRuleClick()
    gGameUI:stackUI("common.rule", nil, {nil}, self:createHandler("getRuleContext"), {width = 1000})
end

function DispatchView:getRuleContext(view)
    local c = adaptContext
local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.rules)
        end),
        c.noteText(124201),
        c.noteText(124202, 124300),
    }
    return context
end

function DispatchView:onBtnTaskClick( )
	gGameUI:stackUI("city.activity.dispatch.task", nil, {clickClose = true}, self.activityId)
end

function DispatchView:onCreate(activityId, data)
    self.activityId = activityId
	self:enableSchedule()
	local actionPointKey = csv.yunying.yyhuodong[self.activityId].paramMap.item
	gGameUI.topuiManager:createView("activity_dispatch", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.activityDispatch, subTitle = "DISPATCH", actionPointKey = actionPointKey})
	self:initMap()
	self:initModel()
	adapt.oneLinePos(self.textCountDownNote, self.textCountDown, cc.p(0,0))
	self:endTimeCountDown()
end

function DispatchView:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	idlereasy.when(self.yyhuodongs,function(_, yyhuodongs)
		self:unScheduleAll()
		local yydata = yyhuodongs[self.activityId] or {}
		local dispatch = yydata.dispatch or {}
		local maxID = 0
		for taskId, v in pairs(dispatch) do
			local item = self.gameCfg[taskId].item
			item:removeChildByName("rewardEffect")
			if dispatch[taskId].times >= csv.yunying.dispatch[taskId].times then--超过派遣次数
				--已完成
				item:get("dispatchingPanel"):hide()
				item:get("completePanel"):show()
				item:get("cdPanel"):hide()
				item:get("lockPanel"):show()
				item:get("posIcon"):texture("activity/dispatch/51send_ywc.png"):scale(1):y(85)
				item:setTouchEnabled(false)
				item:get("canDispatchImg"):hide()
			elseif v.status == 1 then
				item:get("dispatchingPanel"):show()
				item:get("completePanel"):hide()
				item:get("cdPanel"):hide()
				item:get("lockPanel"):hide()
				item:get("canDispatchImg"):hide()
				if time.getTime() > dispatch[taskId].end_time then
					--成功结束 可领取
					item:get("dispatchingPanel.imgIcon"):texture("common/icon/icon_box4.png"):scale(1.5)
					widget.addAnimationByKey(item, "effect/guanqiabaoxiang.skel", "rewardEffect", "effect_loop", 2)
						:xy(100, 200)
						:scale(0.5)
				else
					--派遣ing
					local unitCsv = dataEasy.getUnitCsv(v.cards[1].card_id, v.cards[1].skin_id)
					item:get("dispatchingPanel.imgIcon"):texture(unitCsv.iconSimple)
					self:schedule(function(dt)
						if time.getTime() > dispatch[taskId].end_time then
							item:get("dispatchingPanel.imgIcon"):texture("common/icon/icon_box4.png"):scale(1.5)
							widget.addAnimationByKey(item, "effect/guanqiabaoxiang.skel", "rewardEffect", "effect_loop", 2)
								:xy(100, 200)
								:scale(0.5)
							return false
						end
					end, taskId)
				end
			elseif v.status == 2 then
				item:get("dispatchingPanel"):hide()
				item:get("completePanel"):hide()
				if dispatch[taskId].cd_time and time.getTime() < dispatch[taskId].cd_time then
					--cd
					item:get("cdPanel"):show()
					item:get("lockPanel"):hide()
					self:countDown(item:get("cdPanel"), dispatch[taskId].cd_time, taskId)
					item:get("canDispatchImg"):hide()
				else
					--可派遣状态
					item:get("cdPanel"):hide()
					item:get("lockPanel"):show()
					item:get("canDispatchImg"):show()
					item:get("canDispatchImg"):stopAllActions()
				end
			end
			if self.gameCfg[taskId].data.type == 1 then
				maxID = math.max(maxID, taskId)
			end
		end
		self:moveToDispatch(maxID)
		self:setSelEffect(maxID)
	end)
end

function DispatchView:initMap()
	self.gameCfg = {}
    for k, cfg in orderCsvPairs(csv.yunying.dispatch) do
        if cfg.huodongID == csv.yunying.yyhuodong[self.activityId].huodongID then
            self.gameCfg[k] = {data = cfg, id = k}
        end
    end

	self.scrollView:size(display.sizeInViewRect)
		:xy(display.sizeInViewRect)
	for k, v in pairs(self.gameCfg) do
		local item = self.item:clone()
			:addTo(self.scrollView)
			:show()
			:xy(v.data.position)
			:z(10)
		self.gameCfg[k].item = item
		item:get("lockPanel"):show()
		item:get("lockPanel.text"):text(v.data.numText)
		bind.touch(self.scrollView, item, {methods = {ended = functools.partial(self.clickGateItem, self, v.id)}})
		item:get("posIcon"):texture(v.data.icon):scale(1):y(85)
		if v.data.type == 3 then
			item:get("posIcon"):scale(2):y(120)
		end
		local pathPointes = getAllPassPoints(self.scrollView, v.data, 0)
		for i,point in ipairs(pathPointes) do
			point:visible(true)
		end
		self.gameCfg[k].item:get("canDispatchImg"):hide()
	end
end

function DispatchView:moveToDispatch(id)
	local item = self.gameCfg[id].item
	local scrollViewSize = self.scrollView:size()
	local itemX, itemY = item:x(), item:y()
	local x, y = scrollViewSize.width / 2 - itemX  , scrollViewSize.height / 2 - itemY
	x = math.min(0, x)
	y = math.min(0, y)
	x = math.max( - self.scrollView:getInnerContainerSize().width + scrollViewSize.width, x)
	y = math.max( - self.scrollView:getInnerContainerSize().height + scrollViewSize.height, y)
	self.scrollView:setInnerContainerPosition(cc.p(x, y))
end

-- 允许无参数的 selEffect初始化
function DispatchView:setSelEffect(id)
	self.selEffectId = id
	if not self.selEffect then
		self.selEffect = CSprite.new("level/xuanguan.skel")
		self.selEffect:play("effect_loop")
		self.selEffect:visible(true)
		self.selEffect:retain()
	end
	local item = self.gameCfg[id].item
	local pos = cc.p(100, -80)
	if item:get("dispatchingPanel"):isVisible() then
		pos = cc.p(100, 120)
	elseif item:get("completePanel"):isVisible() then
		self.selEffect:hide()
		return
	elseif item:get("cdPanel"):isVisible() then
		pos = cc.p(100, 10)
	elseif item:get("lockPanel"):isVisible() then
		if csv.yunying.dispatch[id].type == 3 then
			pos = cc.p(100, 0)
		else
			pos = cc.p(100, -80)
		end
	end
	if item and self.selEffect then
		self.selEffect:removeFromParent()
		self.selEffect:addTo(item, 100, "selEffect")
		self.selEffect:xy(pos)
		self.selEffect:retain()
		return self.selEffect
	end
end

function DispatchView:clickGateItem(id)
	if csv.yunying.dispatch[id].type == 3 then
		local yyhuodongs = self.yyhuodongs:read()
		local yydata = yyhuodongs[self.activityId] or {}
		local dispatch = yydata.dispatch or {}
		local reward = csv.yunying.dispatch[id].award
		local actionPointKey = csv.yunying.yyhuodong[self.activityId].paramMap.item
		local cost = csv.yunying.dispatch[id].cost[actionPointKey]
		if dispatch[id] and dispatch[id].status == 2 then
			local content = string.format(gLanguageCsv.dispatchBoxTip1, cost)
			gGameUI:showDialog({content = content, btnType = 2,cb = function()
				local actionPointKey = csv.yunying.yyhuodong[self.activityId].paramMap.item
				local actionPoint = dataEasy.getNumByKey(actionPointKey)
				if actionPoint < cost then
					gGameUI:showTip(gLanguageCsv.actionPointNotEnough)
					return
				end
				gGameApp:requestServer("/game/yy/dispatch/begin", function (tb)
						gGameUI:showGainDisplay(tb)
				end, self.activityId, id)
			end})
		else
			gGameUI:showBoxDetail({
				data = reward,
				content = string.format(gLanguageCsv.dispatchBoxTip2, cost),
				state = 1
			})
		end
	else
		gGameUI:stackUI("city.activity.dispatch.sprite_select", nil, {clickClose = true, blackLayer = true}, self.activityId, id)
	end
	self:setSelEffect(id)
end

function DispatchView:countDown(panel, endTime, taskId)
	local function setLabel()
		local textTime = panel:get("text")
		local x,y = panel:getPosition()
		local remainTime = time.getCutDown(endTime - time.getTime())
		textTime:text(remainTime.str)
		panel:get("imgBg"):width(textTime:width() +20)
		if endTime - time.getTime() <= 0 then
			--可派遣状态
			self.gameCfg[taskId].item:get("cdPanel"):hide()
			self.gameCfg[taskId].item:get("lockPanel"):show()
			self:selEffect(self.selEffectId)
			return false
		end
		return true
	end
	setLabel()
	self:schedule(function(dt)
		if not setLabel() then
			return false
		end
	end, 1, 0, taskId)
end

function DispatchView:endTimeCountDown()
	self:enableSchedule():unSchedule(99)
	local yyEndtime = gGameModel.role:read("yy_endtime")
	local endTime = yyEndtime[self.activityId]
	if endTime - time.getTime() <= 0 then
		self.textCountDownNote:text(gLanguageCsv.activityOver)
		self.textCountDown:text("")
		return
	end
	bind.extend(self, self.textCountDown, {
		class = 'cutdown_label',
		props = {
			endTime = endTime,
			tag = 99,
			strFunc = function(t)
				return t.str
			end,
			endFunc = function()
				self:endTimeCountDown()
			end,
		}
	})
end

return DispatchView