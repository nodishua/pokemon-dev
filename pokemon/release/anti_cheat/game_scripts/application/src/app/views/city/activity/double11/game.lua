--红包雨
local ViewBase = cc.load("mvc").ViewBase
local Double11Game = class("Double11Game", ViewBase)

Double11Game.RESOURCE_FILENAME = "double_11_game.json"
Double11Game.RESOURCE_BINDING = {
    ["panelCountDown"] = "panelCountDown",
	["panelGame"] = {
		varname = "panelGame",
		binds = {
			event = "animation",
			res = "shuang11/diaohongbao.skel",
			name = "effectDiaohongbao",
			action = "effect_loop",
			pos = {x = 3120/2, y = 720},
		}
	},
	["panelGame.textCountDown"]= {
		varname = "textCountDown",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(148, 31, 36), size = 8}}
		}
	},
	["redPacketItem"] = "redPacketItem",
	["panelGame.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("count"),
			method = function(val)
				return "x"..val
			end,
		},
	}
}

function Double11Game:onCreate(activityId, nowIndex)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.double11, subTitle = gLanguageCsv.double11Subtitle})
	self.panelCountDown:globalZ(1)
	self.activityId = activityId
	self.nowIndex = nowIndex
	self:startCount()
	self.count = idler.new(0)
	self.gaming = false
	self:initUI()
end

function Double11Game:initUI( )
	local gameCfg = {}
    for k, cfg in orderCsvPairs(csv.yunying.double11_game) do
        if cfg.huodongID == csv.yunying.yyhuodong[self.activityId].huodongID then
            gameCfg[cfg.game] = cfg.itemID
        end
	end
	self.panelGame:get("imgRedPacket"):texture(dataEasy.getCfgByKey(gameCfg[self.nowIndex]).icon)
	self.redPacketItem:get("imgRedPacket"):texture(dataEasy.getCfgByKey(gameCfg[self.nowIndex]).icon)
end

function Double11Game:gameStart()
	gGameApp:requestServer("/game/yy/double11/game/start",function (tb)
		self.gaming = true
		self.panelCountDown:hide()
		self.panelGame:show()
		self:initCountDown()
		self:initRedPacketAction()
	end, self.activityId)
end
--倒计时
function Double11Game:startCount()
	self.panelCountDown:show()
	self.panelGame:hide()
	local num = 3
	self:enableSchedule():schedule(function (dt)
		if num > 0 then
			self.panelCountDown:get("textNum"):text(num)
			adapt.oneLineCenterPos(cc.p(self.panelCountDown:width() / 2, self.panelCountDown:height() / 2), {self.panelCountDown:get("textNote"), self.panelCountDown:get("textNum")})
			num = num - 1
		else
			self:gameStart()
			return false
		end
	end, 1, 0, 666)
end

--倒计时
function Double11Game:initCountDown()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local playTime = yyCfg.paramMap.playTime
    bind.extend(self, self.textCountDown, {
		class = 'cutdown_label',
		props = {
			endTime = time.getTime() + playTime,
			str_key = "short_clock_str",
			endFunc = function()
				self.gaming = false
				gGameApp:requestServer("/game/yy/double11/game/end",function (tb)
					local view = gGameUI:stackUI("common.gain_display", nil, nil, tb, {cb = self:createHandler("onClose")})
					rich.createByStr(gLanguageCsv.double11GainDisplayTitle, 40)
						:addTo(view:getResourceNode(), 10)
						:xy(view:getResourceNode():width()/2, 900)
						:anchorPoint(cc.p(0.5, 0.5))
						:formatText()
					self.panelGame:get("effectDiaohongbao"):hide()
				end, self.activityId, self.count:read())
			end,
		}
	})
end


function Double11Game:initRedPacketAction()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local redPacketMax = yyCfg.paramMap.redPacketMax

	local playTime = yyCfg.paramMap.playTime
	local max = yyCfg.paramMap.timeMax
	local min = yyCfg.paramMap.timeMin
	for i = 1, redPacketMax do
		local moveTime = math.random(min, max) / 1000
		local redPacket = self.redPacketItem:clone()
			:addTo(self.panelGame)
			:hide()
			:scale(1.7)
		local delyaTime = math.random(1, (playTime - moveTime) * 10)/10
		local x = math.random(self.panelCountDown:width()/2 - 800, self.panelCountDown:width()/2 + 800)
		redPacket:xy(x,1000)
		local delayAction = cc.DelayTime:create(delyaTime)
		local move1 = cc.MoveTo:create(moveTime, cc.p(x, -200))
		redPacket:runAction(cc.Sequence:create(delayAction, cc.Show:create(), move1, cc.RemoveSelf:create()))
		redPacket:addClickEventListener(function()
			redPacket:setTouchEnabled(false)
			self.count:modify(function(num)
				return true, num + 1
			end,true)
			redPacket:get("imgRedPacket"):hide()
			local effect = widget.addAnimationByKey(redPacket, "shuang11/diaohongbao.skel", "effect1", "effect", 3)
				:xy(redPacket:size().width / 2, redPacket:size().height / 2)
				:scale(0.8)
				performWithDelay(redPacket,
					function()
						redPacket:stopAllActions()
						redPacket:removeFromParent()
					end,0.5)
		end)
	end
end

function Double11Game:onClose(  )
	if not self.gaming then
		ViewBase.onClose(self)
	end
end

return Double11Game