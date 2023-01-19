local ViewBase = cc.load("mvc").ViewBase
local VolleyballView = class("VolleyballView",ViewBase)

local function getMonthInEn(month)
	local monthArr = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sept","Oct","Nov","Dec"}
	return monthArr[tonumber(month)]
end

VolleyballView.RESOURCE_FILENAME = "volleyball_main.json"
VolleyballView.RESOURCE_BINDING = {
	["prepareBg"] = "prepareBg",
	["rightPanel.btnStart"] = {
		varname = "btnStart",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlayGameClick")},
		},
	},
	["textTipTime"] = {
		varname = "textTipTime",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(82, 76, 85, 255), size = 4}}
		}
	},

	["leftPanel.btnAward"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onRewardClick")},
			}, {
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("awardRedHint"),
					onNode = function(node)
						node:xy(150, 150)
					end,
				}
			}
		},
	},
	["leftPanel.btnRank"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankClick")},
		},
	},
	["leftPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")},
		},
	},
	["leftPanel.btnAward.award"] = {
		varname = "award",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 4}, color = ui.COLORS.NORMAL.DEFAULT}
		}
	},
	["leftPanel.btnRank.rank"] = {
		varname = "rank",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 4}, color = ui.COLORS.NORMAL.DEFAULT}
		}
	},
	["leftPanel.btnRule.rule"] = {
		varname = "rule",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 4}, color = ui.COLORS.NORMAL.DEFAULT}
		}
	},
	["ruleItem"] = "ruleItem",
}

function VolleyballView:onCreate(activityId, data)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.volleyballGame, subTitle = "VOLLEYBALL GAME"})

	self.prepareBg:hide()
	self:initModel()
	self.activityId = activityId
	self.yyCfg = csv.yunying.yyhuodong[self.activityId]


	local beginDate = string.format("%s.%s.%s", time.getYearMonthDay(self.yyCfg.beginDate))
	local endDate = string.format("%s.%s.%s", time.getYearMonthDay(self.yyCfg.endDate))
	if matchLanguage({"en"}) then
		local startYear, startMonth, startDay = time.getYearMonthDay(self.yyCfg.beginDate)
		local endYear, endMonth, endDay = time.getYearMonthDay(self.yyCfg.endDate)
		startMonth = getMonthInEn(startMonth)
		endMonth = getMonthInEn(endMonth)
		beginDate = string.format("%s.%s.%s",startYear,startMonth,startDay)
		endDate = string.format("%s.%s.%s",endYear, endMonth, endDay)
	end
	self.textTipTime:text(string.format("%s %s-%s",gLanguageCsv.volleyballOpenTime ,beginDate, endDate))

	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yydata = yyhuodongs[self.activityId] or {}
		self.roleData = yydata.valsums and yydata.valsums[201] or 0
		for _,v in pairs(yydata.stamps or {}) do
			if v == 1 then
				self.awardRedHint:set(true)
				return
			end
		end
		self.awardRedHint:set(false)
	end)
end

function VolleyballView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.awardRedHint = idler.new(false)
end

function VolleyballView:onPlayGameClick()
	gGameUI:stackUI("city.activity.volleyball.game", nil, nil, self.activityId, self.roleData)
end
function VolleyballView:onRewardClick()
	gGameUI:stackUI("city.activity.volleyball.reward", nil, {blackLayer = true}, self.activityId)
end
function VolleyballView:onRankClick()
	gGameApp:requestServer("/game/yy/volleyball/rank", function(tb)
		gGameUI:stackUI("city.activity.volleyball.rank", nil, nil, tb.view, self.roleData)
	end, self.activityId)
end

function VolleyballView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function VolleyballView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(124901, 124907),
	}
	local imgData = {"btn_t.png", "btn_xl.png", "btn_jn.png", "btn_jn_3.png", "btn_jn_m.png"}
	for i, v in pairs(imgData) do
		table.insert(context, c.clone(self.ruleItem, function(item)
			local childs = item:multiget("skill", "textDesc")
			childs.skill:texture("activity/volleyball/" .. v)
			local richText = rich.createWithWidth(gLanguageCsv["volleyballSkill" .. i], 40, nil, 1000, 0)
				:anchorPoint(0,0.5)
			richText:addTo(item)
				:y(item:height()/2)
				:x(350)
		end))
	end
	table.insert(context,c.noteText(124908, 125000))
	return context
end

return VolleyballView