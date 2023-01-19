-- @date:   2021-01-15
-- @desc:   摩天高楼
local ViewBase = cc.load("mvc").ViewBase
local SkyScraperView = class("SkyScraperView",ViewBase)

local BIND_EFFECT= {
	event = "effect",
	data = {outline = {color = cc.c4b(255, 252, 237, 255),  size = 4}}
}
--按钮状态
local function setBtnState(btn, state)
	btn:setTouchEnabled(state)
	cache.setShader(btn, false, state and "normal" or "hsl_gray")
	if state then
		text.addEffect(btn:get("textNote"), {glow={color=ui.COLORS.GLOW.WHITE}})
	else
		text.deleteAllEffect(btn:get("textNote"))
		text.addEffect(btn:get("textNote"), {color = ui.COLORS.DISABLED.WHITE})
	end
end
SkyScraperView.RESOURCE_FILENAME = "sky_scraper_view.json"
SkyScraperView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["icon"] = "icon",
	["centerPanel.btnGame"] = {
        varname = "btnGame",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlayGameClick")},
		},
	},
	["centerPanel.btnAdd"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddClick")},
		},
	},
	["centerPanel.btnGame.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["centerPanel.textTipTime"] = "textTipTime",
	["centerPanel.tipTime"] = "tipTime",
	["centerPanel"] = "centerPanel",
	["centerPanel.timeText"] = {
		varname = "timeText",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(91, 84, 91, 255),  size = 4}}
		},
	},
	["centerPanel.time"] = {
		varname = "time",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(91, 84, 91, 255),  size = 4}}
		},
	},
	["leftDownPanel.taskPanel.txt"] = {
		binds = BIND_EFFECT
	},
	["leftDownPanel.rankPanel.txt"] = {
		binds = BIND_EFFECT
	},
	["leftDownPanel.rulePanel.txt"] = {
		binds = BIND_EFFECT
	},
	["leftDownPanel.taskPanel"] = {
		binds = {
			{
			event = "touch",
			methods = {ended = bindHelper.self("onTaskClick")},
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "skyScraperTask",
					listenData = {
						activityId =  bindHelper.self("activityId")
					},
				}
			}
		},
	},
	["leftDownPanel.rankPanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankClick")},
		},
	},
	["leftDownPanel.rulePanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")},
		},
	},
}


function SkyScraperView:onCreate(activityId)
	self.activityId = activityId
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.skyScraper, subTitle = "SKY SCRAPER"})
	self:initModel()
	--时间
	self:updateTime()
end

function SkyScraperView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.cost = 0
	local yycfg = csv.yunying.yyhuodong[self.activityId]
	local paramMap = yycfg.paramMap or {}
	self.huodongId = yycfg.huodongID
	self.maxTimes = paramMap.times or 0
	self.buyCost = paramMap.buyCost or {}
	self.canBuy = false
	self.buyTimes = paramMap.buyTimes or 0
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yydata = yyhuodongs[self.activityId] or {}
		local info = yydata.info or {}
		local taskNum = info.task_points or 0
		local cfg = csv.yunying.skyscraper_medals
		local curLevelIndex = 0
		local cal = 0 --计算勋章值
        local mathcHuodongId = false --是否有符合的活动id
        local maxLevelIndex = 1
        for k, val in orderCsvPairs(cfg) do
            if val.huodongID == self.huodongId then
                maxLevelIndex = val.medalLevel > cfg[maxLevelIndex].medalLevel and k or maxLevelIndex
            end
        end
		for k, v in orderCsvPairs(cfg) do
			if v.huodongID == self.huodongId then
				mathcHuodongId = true
                cal = cal + v.points
                if cal > taskNum then
					curLevelIndex = k
					break
				end
			end
		end
		if not mathcHuodongId then
			curLevelIndex = 1
		else
			if curLevelIndex == 0 then
                curLevelIndex = maxLevelIndex
			end
		end
        --最大等级
		self.icon:texture(cfg[curLevelIndex].resource)
		self.icon:get("imgRank"):texture(cfg[curLevelIndex].resourceNum)
		self.icon:get("textRank"):text(gLanguageCsv[cfg[curLevelIndex].medalsName])
		self.icon:get("textRank"):setTextColor(cc.c3b(unpack(cfg[curLevelIndex].color)))
		self.times = self.maxTimes + info.buy_times - info.times or 0
        self.tipTime:text(self.times.."/"..self.maxTimes)
        --购买次数
        self.cost = info.buy_times + 1 <= itertools.size(self.buyCost) and self.buyCost[info.buy_times + 1] or self.buyCost[itertools.size(self.buyCost)]
        self.canBuy = info.buy_times < self.buyTimes
        self.btnAdd:visible(info.buy_times ~=  self.buyTimes)
		adapt.oneLineCenterPos(cc.p(self.centerPanel:size().width / 2, self.textTipTime:y()), {self.textTipTime, self.tipTime}, cc.p(0, 0))
	end)
end
function SkyScraperView:onTaskClick()
	gGameUI:stackUI("city.activity.sky_scraper.reward", nil, nil, self.activityId)
end

function SkyScraperView:onPlayGameClick()
	if self.times == 0 then
		gGameUI:showTip(gLanguageCsv.gameTimesLimit)
		return
	end
	local yyEndtime = gGameModel.role:read("yy_endtime")
	local endTime = yyEndtime[self.activityId]
	local spendTime = 0
	if endTime == nil or math.floor(endTime - time.getTime()) <= 0 then
		gGameUI:showTip(gLanguageCsv.flipCardFinishedClickTip)
		return
	end
	gGameApp:requestServer("/game/yy/skyscraper/start", function(tb)
			gGameUI:stackUI("city.activity.sky_scraper.game", nil, {full = true}, self.activityId)
	end, self.activityId)
end
function SkyScraperView:onRankClick()
	gGameApp:requestServer("/game/yy/skyscraper/ranking", function(tb)
		gGameUI:stackUI("city.activity.sky_scraper.rank", nil, nil, self.activityId, tb.view)
	end, self.activityId)
end
function SkyScraperView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function SkyScraperView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(161),
		c.noteText(116001, 116020),
	}
	return context
end

function SkyScraperView:onAddClick()
    local yyEndtime = gGameModel.role:read("yy_endtime")
	local endTime = yyEndtime[self.activityId]
	local spendTime = 0
	if endTime == nil or math.floor(endTime - time.getTime()) <= 0 then
		gGameUI:showTip(gLanguageCsv.flipCardFinishedClickTip)
		return
	end
    if self.canBuy == false then
        gGameUI:showTip(gLanguageCsv.buyTimesLimit)
        return
    end
    local strTips = gLanguageCsv.buyGameTimes
    gGameUI:showDialog({
        cb = function()
            if self.cost > gGameModel.role:read("rmb") then
                uiEasy.showDialog("rmb")
            else
                gGameApp:requestServer("/game/yy/skyscraper/buy", function(tb)
                    gGameUI:showTip(gLanguageCsv.buySuccess)
                end, self.activityId)
            end
        end,
		title = gLanguageCsv.spaceTips,
		content = string.format(strTips, self.cost),
		isRich = true,
		btnType = 2,
		clearFast = true,
		dialogParams = {clickClose = false},
	})
end
--活动倒计时
function SkyScraperView:updateTime()
	local yyEndtime = gGameModel.role:read("yy_endtime")
	local endTime = yyEndtime[self.activityId]
	bind.extend(self, self.time, {
		class = 'cutdown_label',
		props = {
			endTime = endTime,
			callFunc = function()
				adapt.oneLineCenterPos(cc.p(self.centerPanel:size().width / 2, self.timeText:y()), {self.timeText, self.time}, cc.p(0, 0))
			end,
			endFunc = function()
				self.time:text(gLanguageCsv.activityOver)
				self.time:x(self.time:x() - 180)
				self.timeText:visible(false)
			end,
		}
	})
end

return SkyScraperView