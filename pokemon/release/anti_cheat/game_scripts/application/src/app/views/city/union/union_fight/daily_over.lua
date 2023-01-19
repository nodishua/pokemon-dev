-- @date:   2020-02-25
-- @desc:   公会战界面

local unionTools = require "app.views.city.union.tools"
local UnionFightDailyOverView = class("UnionFightDailyOverView", cc.load("mvc").ViewBase)

UnionFightDailyOverView.RESOURCE_FILENAME = "union_fight_daily_over.json"
UnionFightDailyOverView.RESOURCE_BINDING = {
	["bg1"] = "bg1",
	["listTitle.text1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["listTitle.text2"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["listTitle.text3"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["listTitle.text4"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["title"] = "title",
	["item"] = "item",
	["item.lv"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(107, 82, 49, 255)}},
		},
	},
	["item.level"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(107, 82, 49, 255)}},
		},
	},
	["list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("unionData"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local opacity = {
						[0] = 0.3,
						[1] = 0.6,
					}
					local children = node:multiget("icon", "bg", "name", "num", "win", "score", "level")
					children.bg:setOpacity(255 * opacity[k % 2])

					children.icon:texture(gUnionLogoCsv[v.union_logo])
					children.name:text(v.union_name)
					children.score:text(v.point)
					children.win:text(v.kill_num)
					children.num:text(v.sign_num)
					children.level:text(v.union_level)
				end,
			},
		},
	}
}

function UnionFightDailyOverView:onCreate()
	local nowTime = time.getNowDate()
	print_r(nowTime)
	local wday = nowTime.wday -- 星期
	wday = wday == 1 and 7 or wday - 1

	local h, m = dataEasy.getTimeStrByKey("unionFight", "signUpStart", true)
	if nowTime.hour > h or (nowTime.hour == h and nowTime.min >= m) then
		wday = wday + 1 -- 显示明天
	end

	local data = gGameModel.union_fight:read("final_result") or {}
	self.unionData = data
	local str = string.format(gLanguageCsv.unionFightDaliyOver, gGameModel.union_fight:read("last_union_name"), gGameModel.union_fight:read("last_role_name"), gLanguageCsv["weekday"..wday])
	if matchLanguage({"en"}) then
		str = string.format(gLanguageCsv.unionFightDaliyOver1, gGameModel.union_fight:read("last_union_name"), gGameModel.union_fight:read("last_role_name"))
	end
	local richText = rich.createByStr(str, 44, nil, nil, cc.p(0, 0.5))
		:addTo(self.title, 10, "privilege")
		:anchorPoint(cc.p(0.5, 0.5))
		:xy(1280, 60)

	local x, y = self.bg1:xy()
	local node = self:getResourceNode()
	local parentSize = self.bg1:size()
	local spinePath = "effect/zuanshichouka.skel"
	widget.addAnimationByKey(node, spinePath, "Main_Ani", "effect_yhhh_loop", 99)
		:xy(x + 200, 30)
		:scale(2.1)
	self.bg1:hide()

	if matchLanguage({"en"}) then
		richText:x(1180)
		richText:formatText()
		self.leftTimeText = cc.Label:createWithTTF("", ui.FONT_PATH, 44)
			:color(cc.c4b(108, 233, 255, 255))
			:xy(richText:x() + 20 + richText:width()/2, richText:y())
			:anchorPoint(cc.p(0, 1))
			:addTo(self.title, 11, "time")

		self:startRefreshTime(wday)
	end

end
function UnionFightDailyOverView:startRefreshTime(wday)
	local function updateLeftTimeStr()
		local curTb = time.getNowDate()
		local curTime = time.getTimestamp(curTb)
		local signUpStartHour, signUpStartMin = dataEasy.getTimeStrByKey("unionFight", "signUpStart", true)
		local newWday = wday == 7 and 1 or wday + 1
		curTb.day = curTb.day + (newWday > curTb.wday and (newWday - curTb.wday) or (newWday + 7 - curTb.wday))
		curTb.wday = newWday
		curTb.hour = signUpStartHour
		curTb.min = signUpStartMin
		curTb.sec = 0
		local endTime = time.getTimestamp(curTb)
		local delta = endTime - curTime
		if delta < 1 then
			return true
		end
		self.leftTimeText:text(time.getCutDown(delta).str)
		return false
	end
	local tag = 20210519
	self:enableSchedule():unSchedule(tag)
	self:enableSchedule()
		:schedule(function(dt)
			updateLeftTimeStr()
		end, 1, 0, tag)
end
return UnionFightDailyOverView