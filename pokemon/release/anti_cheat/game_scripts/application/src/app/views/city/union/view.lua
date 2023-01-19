-- @date:   2019-06-04
-- @desc:   公会主界面

local unionTools = require "app.views.city.union.tools"
local CrossUnionFightTools = require "app.views.city.union.cross_unionfight.tools"

local BUILDINGS = {
	"dailygift",  --每日礼包
	"redpacket",  --红包中心
	"training",   --训练中心
	"unionskill", --修炼中心
	"fuben",      --副本
	"unionFight", --公会战
	"contribute", -- 捐献中心
	"fragdonate", -- 许愿中心
	"unionqa", -- 精灵问答
	"crossunionfight" --跨服公会战
}

local DAILYNOTICEFUNC = {
	fragdonate = function(self, data)
		local canEnter = unionTools.canEnterBuilding("fragdonate", nil, true)
		if not canEnter then
			return false
		end
		return self.unionFragDonateStartTimes:read() == 0
	end,
	contribute = function(self, data)
		local canEnter = unionTools.canEnterBuilding("contribute", nil, true)
		if not canEnter then
			return false
		end
		local unionLv = self.unionLv:read()
		local contribMax = csv.union.union_level[unionLv].ContribMax
		return self.contribCount:read() < contribMax
	end,
	uniontask = function(self, data)
		local canEnter = unionTools.canEnterBuilding("contribute", nil, true)
		if not canEnter then
			return false
		end
		local hasTask = false
		local cache = {}
		-- k:csvID  v:[times, state]
		-- state 0:未完成 1:可领取 2:已完成
		for k,v in pairs(self.unionAllTasks:read()) do
			cache[k] = v[2]
		end
		for k,v in orderCsvPairs(csv.union.union_task) do
			-- 每日任务
			if v.type == 1 and (not cache[k] or cache[k] == 0) then
				hasTask = true
				break
			end
		end

		return hasTask
	end,
	dailygift = function(self, data)
		local canEnter = unionTools.canEnterBuilding("dailygift", nil, true)
		if not canEnter then
			return false
		end
		return self.dailyGiftTimes:read() <= 0
	end,
	speedup = function(self, data)
		local canEnter = unionTools.canEnterBuilding("training", nil, true)
		if not canEnter then
			return false
		end
		local leftNum = 0
		if data.tarhetArg then
			leftNum = math.max(6 - self.trainingSpeedup:read(), 0)
		end
		return self.trainingSpeedup:read() < 6, leftNum
	end,
	dailypacket = function(self, data)
		local canEnter = unionTools.canEnterBuilding("redpacket", nil, true)
		if not canEnter then
			return false
		end
		return self.systemRedPacket:read()
	end,
	fuben = function(self, data)
		local canEnter = unionTools.canEnterBuilding("fuben", nil, true)
		local isOpenTime = unionTools.currentOpenFuben()
		if not canEnter or isOpenTime ~= "open" then
			return false
		end
		local battleNum = self.unionFbTimes:read()
		local leftNum = 0
		if data.tarhetArg then
			leftNum = math.max(3 - battleNum, 0)
		end

		return math.max(3 - battleNum, 0) > 0, leftNum
	end,
	fightsign = function(self, data)
		return false
	end,
}

local function setEffect(parent, actionName)
	local effect = parent:get("effect")
	local size = parent:size()
	if not effect then
		effect = widget.addAnimationByKey(parent, "union/hongbaokeling.skel", "effect", actionName, 2)
			:xy(size.width/2 + 0, size.height/2 + 0)
	else
		effect:show():play(actionName)
	end
end
local JUMPFUNCS = {
	--每日礼包
	dailygift = function(self)
		local canEnter = unionTools.canEnterBuilding("dailygift")
		if not canEnter then
			return
		end
		if self.dailyGiftTimes:read() > 0 then
			gGameUI:showTip(gLanguageCsv.aleardyGetGift)
			return
		end
		local showOver = {false}
		gGameApp:requestServerCustom("/game/union/daily_gift")
			:params()
			:onResponse(function (tb)
				self.dailygift:get("effect"):play("dianji_houjing")
				local effct = self.effectPanel:get("effect")
				if not effct then
					effct = widget.addAnimationByKey(self.effectPanel, "union/gonghuimeiri.skel", "effect", "dianji_qianjing", 1)
						:xy(650, 260)
					effct:setSpriteEventHandler(function(event, eventArgs)
						effct:hide()
						self.dailygift:get("effect"):play("standby_loop")
						showOver[1] = true
					end, sp.EventType.ANIMATION_COMPLETE)
				else
					effct:show():play("dianji_qianjing")
				end
			end)
			:wait(showOver)
			:doit(function (tb)
				gGameUI:showGainDisplay(tb)
			end)
	end,
	--红包中心
	redpacket = function(self)
		local canEnter = unionTools.canEnterBuilding("redpacket", true)
		if not canEnter then
			return
		end
		gGameApp:requestServer("/game/union/redpacket/info",function (tb)
			gGameUI:stackUI("city.union.redpack.view", nil, {full = true}, tb.view)
		end)
	end,
	--训练中心
	training = function(self)
		local canEnter = unionTools.canEnterBuilding("training")
		if not canEnter then
			return
		end
		gGameApp:requestServer("/game/union/training/open",function (tb)
			gGameUI:stackUI("city.union.train.view", nil, nil, tb)
		end)
	end,
	--修炼中心
	unionskill = function(self)
		local canEnter = unionTools.canEnterBuilding("unionskill", true)
		if not canEnter then
			return
		end
		gGameUI:stackUI("city.union.skill.view")
	end,
	--副本
	fuben = function(self)
		local canEnter = unionTools.canEnterBuilding("fuben")
		if not canEnter then
			return
		end
		gGameApp:requestServer("/game/union/fuben/get",function (tb)
			gGameUI:stackUI("city.union.gate.view", nil, nil, tb.view)
		end)
	end,
	--公会战
	unionFight = function(self)
		if not dataEasy.isInServer("unionFight") then
			return
		end
		local canEnter = unionTools.canEnterBuilding("unionFight")
		if not canEnter then
			return
		end
		--判断unlock
		if not dataEasy.isUnlock(gUnlockCsv.unionFight) then
			local str = dataEasy.getUnlockTip(gUnlockCsv.unionFight)
			gGameUI:showTip(str)
			return
		end
		-- 判断开服天数
		for idx, v in csvPairs(csv.pvpandpve) do
			if v.unlockFeature == "unionFight" then
				local day = getCsv(v.serverDayInfo.sevCsv)
				local isUnionFightDay = dataEasy.serverOpenDaysLess(day)
				if isUnionFightDay then
					local str = string.format(gLanguageCsv.unlockServerOpen, day)
					gGameUI:showTip(str)
					return
				end
			end
		end
		gGameApp:requestServer("/game/union/fight/battle/main", function(tb)
			gGameUI:stackUI("city.union.union_fight.view", nil, {full = true})
		end)
	end,
	-- 捐献中心
	contribute = function(self)
		local canEnter = unionTools.canEnterBuilding("contribute")
		if not canEnter then
			return
		end
		gGameUI:stackUI("city.union.contrib.view")
	end,
	-- 许愿中心
	fragdonate = function(self)
		local canEnter = unionTools.canEnterBuilding("fragdonate")
		if not canEnter then
			return
		end
		gGameApp:requestServer("/game/union/get",function (tb)
			gGameUI:stackUI("city.union.frag_donate.view")
		end)
	end,
	-- 大厅
	lobby = function()
		gGameApp:requestServer("/game/union/get",function (tb)
			gGameUI:stackUI("city.union.lobby.view", nil, {full = true})
		end)
	end,
	-- 公告
	unionnotice = function(self)
		local params = {
			content = self.unionNoticeText:read(),
			title = gLanguageCsv.notice,
		}
		gGameUI:showDialog(params)
	end,
	unionshop = function (self)
		if not gGameUI:goBackInStackUI("city.shop") then
			gGameApp:requestServer("/game/union/shop/get", function(tb)
				gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.UNION_SHOP)
			end)
		end
	end,
	unionqa = function(self)
		local canEnter = unionTools.canEnterBuilding("unionqa")
		if not canEnter then
			return
		end
		--判断unlock
		if not dataEasy.isUnlock(gUnlockCsv.unionQA) then
			local str = dataEasy.getUnlockTip(gUnlockCsv.unionQA)
			gGameUI:showTip(str)
			return
		end
		local day = csv.cross.union_qa.base[1].servOpenDays
		local isUnionAnswerDay = dataEasy.serverOpenDaysLess(day)
		if isUnionAnswerDay then
			local str = string.format(gLanguageCsv.unlockServerOpen, day)
			gGameUI:showTip(str)
			return
		end
		gGameApp:requestServer("/game/union/qa/main",function (tb)
			gGameUI:stackUI("city.union.answer.view", nil, {full = true}, tb)
		end)
	end,
	--跨服公会战
	crossunionfight = function(self)
		if not dataEasy.isInServer("crossunionfight") then
			return
		end

		--判断unlock
		if not dataEasy.isUnlock(gUnlockCsv.crossunionfight) then
			local str = dataEasy.getUnlockTip(gUnlockCsv.crossunionfight)
			gGameUI:showTip(str)
			return
		end
		-- 判断开服天数
		for idx, v in csvPairs(csv.pvpandpve) do
			if v.unlockFeature == "crossunionfight" then
				local day = getCsv(v.serverDayInfo.sevCsv)
				local isUnionFightDay = dataEasy.serverOpenDaysLess(day)
				if isUnionFightDay then
					local str = string.format(gLanguageCsv.unlockServerOpen, day)
					gGameUI:showTip(str)
					return
				end
			end
		end
		if dataEasy.notUseUnionBuild() then
			gGameUI:showTip(gLanguageCsv.crossunionfightJionTimeUp)
			return
		end

		local unlock = gUnionFeatureCsv.crossunionfight or 0
		if self.unionLv:read() >= unlock then
		gGameApp:requestServer("/game/cross/union/fight/main", function ()
				gGameUI:stackUI("city.union.cross_unionfight.view", nil, nil, self:createHandler("crossUnionAnimaShow"))
			end)
		end
	end,
}

local UnionView = class("UnionView", cc.load("mvc").ViewBase)

UnionView.RESOURCE_FILENAME = "union_main.json"
UnionView.RESOURCE_BINDING = {
	["effectPanel"] = "effectPanel",
	["leftUp"] = {
		varname = "leftUp",
		binds = {
			event = "visible",
			idler = bindHelper.self("hasEnter")
		},
	},
	["redpacket"] = {
		varname = "redpacket",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onBuildingClick("redpacket")
				end)}
			},
			{
				event = "visible",
				idler = bindHelper.self("isShowRedPack"),
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("isShowRedPack"),
					specialTag = {
						"unionSystemRedPacket",
						"unionMemberRedPacket",
						"unionSendedRedPacket",
					},
					onNode = function(panel)
						panel:xy(171, 175)
					end,
				}
			},
		},
	},
	["redpacket.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["item"] = "item",
	["leftUp.list"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("quickDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					return a.csvId < b.csvId
				end,
				onItem = function(list, node, k, v)
					node:removeChildByName("content")
					local str = v.cfg.desc
					if v.cfg.tarhetArg then
						str =  string.format("%s(%d/%d)", str, v.leftNum, v.cfg.tarhetArg)
					end
					local richText = rich.createWithWidth("#L100#"..str, 40, nil, 400)
					richText:anchorPoint(0, 0.5)
					node:addChild(richText, 2, "content")
					node:height(richText:height())
					richText:xy(55, richText:height()/2)
					node:get("imgIcon"):y(richText:y())
					bind.touch(list, node, {methods = {
						ended = functools.partial(list.clickCell, k, v.cfg)
					}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["bgEffect"] = {
		binds = {
			event = "animation",
			res = "union/tiankongdi.skel",
			action = "effect_loop",
		}
	},
	["scrollCloud"] = {
		varname = "scrollCloud",
		binds = {
			{
				event = "animation",
				res = "union/yun.skel",
				action = "effect_loop",
			},{
				event = "scrollBarEnabled",
				data = false,
			}
		}
	},
	["scrollMont1"] = {
		varname = "scrollMont1",
		binds = {
			{
				event = "animation",
				res = "union/shan1.skel",
				action = "effect_loop",
			},{
				event = "scrollBarEnabled",
				data = false,
			}
		}
	},
	["scrollMont2"] = {
		varname = "scrollMont2",
		binds = {
			{
				event = "animation",
				res = "union/shan2.skel",
				action = "effect_loop",
			},{
				event = "scrollBarEnabled",
				data = false,
			}
		}
	},
	["scrollMont3"] = {
		varname = "scrollMont3",
		binds = {
			{
				event = "animation",
				res = "union/shan3.skel",
				action = "effect_loop",
			},{
				event = "scrollBarEnabled",
				data = false,
			}
		}
	},
	["scroll"] = {
		varname = "scroll",
		binds = {
			{
				event = "animation",
				res = "union/dimian.skel",
				action = "effect_loop",
			},{
				event = "scrollBarEnabled",
				data = false,
			}
		}
	},
	["scrollBuilding"] = {
		varname = "scrollBuilding",
		binds = {
			{
				event = "animation",
				res = "union/dimian2.skel",
				action = "effect_loop",
			},{
				event = "scrollBarEnabled",
				data = false,
			}
		}
	},
	["scrollPlant"] = {
		varname = "scrollPlant",
		binds = {
			{
				event = "animation",
				res = "union/zhibei.skel",
				name = "effect",
				action = "effect_loop",
			},{
				event = "scrollBarEnabled",
				data = false,
			}
		},
	},
	["scrollBuilding.contribute"] = {
		varname = "contribute",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onBuildingClick("contribute")
				end)}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("state"),
					specialTag  ="unionContribute",
					onNode = function(panel)
						panel:xy(171, 375)
					end,
				}
			}, {
				event = "animation",
				res = "union/yanjiusuo.skel",
				name = "effect",
				action = "effect_loop",
				pos = {x = 320, y = 190},
			},
		},
	},
	["scrollBuilding.fragdonate"] = {
		varname = "fragdonate",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onBuildingClick("fragdonate")
				end)}
			}, {
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("state"),
					specialTag  ="unionFragDonate",
					onNode = function(panel)
						panel:xy(46, 488)
					end,
				}
			}, {
				event = "animation",
				res = "union/beiyong3.skel",
				name = "effect",
				action = "effect_loop",
				pos = {x = 45, y = 170},
			},
		},
	},
	["scrollBuilding.lobby"] = {
		varname = "lobby",
		binds = {
			{
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("state"),
					specialTag  = "unionLobby",
					onNode = function(panel)
						panel:xy(175, 545)
					end,
				}
			}, {
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onBuildingClick("lobby")
				end)}
			}, {
				event = "animation",
				res = "union/gonghuidating.skel",
				name = "effect",
				action = "effect_loop",
				pos = {x = 390, y = 395},
			},
		},
	},
	["scrollBuilding.lobby.crossUnionAnima"] = {
		varname = "crossUnionAnima",
		binds = {
			event = "animation",
			res = "cross_union/jzgd.skel",
			action = "stanby_loop",
			scale = 2,
			zOrder = 10,
			pos = {x = 220, y = -160},
		}
	},
	["scrollBuilding.training"] = {
		varname = "training",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onBuildingClick("training")
				end)}
			}, {
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("trainingRedHint"),
					onNode = function(panel)
						panel:xy(334, 750)
					end,
				}
			}, {
				event = "animation",
				res = "union/xunlianzhongxin.skel",
				name = "effect",
				action = "effect_loop",
				pos = {x = 200, y = 705},
			},
		},
	},
	["scrollBuilding.unionskill"] = {
		varname = "unionskill",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onBuildingClick("unionskill")
				end)}
			}, {
				event = "animation",
				res = "union/xiulianzhongxin.skel",
				name = "effect",
				action = "effect_loop",
				pos = {x = 221, y = 225},
			},
		},
	},
	["scrollBuilding.fuben"] = {
		varname = "fuben",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onBuildingClick("fuben")
				end)}
			}, {
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("state"),
					specialTag  ="unionFuben",
					onNode = function(panel)
						panel:xy(339, 390)
					end,
				}
			}, {
				event = "animation",
				res = "union/gonghuifuben.skel",
				name = "effect",
				action = "effect_loop",
				pos = {x = 275, y = 165},
			},
		},
	},
	["scrollBuilding.dailygift"] = {
		varname = "dailygift",
		binds = {
			{
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("state"),
					specialTag  ="unionDailyGift",
					onNode = function(panel)
						panel:xy(423, 365)
					end,
				}
			},
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onBuildingClick("dailygift")
				end)}
			},
		},
	},
	["scrollBuilding.unionfight"] = {
		varname = "unionFight",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onBuildingClick("unionFight")
				end)}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = {
						"unionFightSignUp",
					},
					onNode = function(panel)
						panel:xy(52, 390)
					end,
				}
			}, {
				event = "animation",
				res = "union/gonghuizhan.skel",
				name = "effect",
				action = "effect_loop",
				pos = {x = 450, y = 258},
			},
		},
	},
	["scrollBuilding.unionNotice"] = {
		varname = "unionNotice",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onBuildingClick("unionnotice")
				end)}
			}, {
				event = "animation",
				res = "union/gonggaoban.skel",
				name = "effect",
				action = "effect_loop",
				pos = {x = 160, y = 125},
			},
		},
	},
	["scrollBuilding.unionAnswer"] = {
		varname = "unionqa",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onBuildingClick("unionqa")
				end)}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = {
						"unionAnswer",
					},
					onNode = function(panel)
						panel:xy(345, 320)
					end,
				}
			},
			{
				event = "animation",
				res = "union/renwu2.skel",
				name = "effect",
				action = "effect_loop",
				zOrder = 10,
				pos = {x = 150, y = 100},
			},
		},
	},
	["scrollBuilding.unionNotice.textNotice"] = {
		varname = "textNotice",
		binds = {
			event = "text",
			idler = bindHelper.self("unionNoticeText"),
		},
	},
	["scrollBuilding.unionNoName3"] = {
		varname = "unionNoName3",
		binds = {
			event = "animation",
			res = "union/beiyong1.skel",
			name = "effect",
			action = "effect_loop",
			pos = {x = 355, y = 315},
		},
	},
	["scrollBuilding.unionNoName2"] = "unionNoName2",
	["scrollBuilding.unionShop"] = {
		varname = "unionShop",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onBuildingClick("unionshop")
				end)}
			}, {
				event = "animation",
				res = "union/shangdian.skel",
				name = "effect",
				action = "effect_loop",
				pos = {x = 325, y = 165},
			},
		},
	},
	["scrollBuilding.unionFuli"] = {
		varname = "unionFuli",
		binds = {
			event = "animation",
			res = "union/shuiche.skel",
			name = "effect",
			action = "effect_loop",
			pos = {x = 215, y = 260},
		},
	},
	["scrollBuilding.icon"] = {
		varname = "icon",
		binds = {
			event = "animation",
			res = "union/beiyong2.skel",
			name = "effect",
			action = "effect_loop",
			pos = {x = 85, y = 90},
		},
	},
	["scrollBuilding.renwu1"] = {
		varname = "renwu1",
		binds = {
			event = "animation",
			res = "union/renwu1.skel",
			name = "effect",
			action = "effect_loop",
			zOrder = 10,
			pos = {x = 300, y = 200},
		},
	},
	-- ["scrollBuilding.renwu2"] = {
	-- 	varname = "unionAnswer",
	-- 	binds = {
	-- 		-- {
	-- 		-- 	event = "touch",
	-- 		-- 	methods = {ended = bindHelper.defer(function(view)
	-- 		-- 		view:onBuildingClick("unionAnswer")
	-- 		-- 	end)}
	-- 		-- },
	-- 		{
	-- 			event = "animation",
	-- 			res = "union/renwu2.skel",
	-- 			name = "effect",
	-- 			action = "effect_loop",
	-- 			zOrder = 10,
	-- 			pos = {x = 175, y = 100},
	-- 		},
	-- 	},
	-- },
	["scrollBuilding.renwu3"] = {
		varname = "renwu3",
		binds = {
			event = "animation",
			res = "union/renwu3.skel",
			name = "effect",
			action = "effect_loop",
			zOrder = 10,
			pos = {x = 50, y = 85},
		},
	},
	["scrollBuilding.renwu4"] = {
		varname = "renwu4",
		binds = {
			event = "animation",
			res = "union/renwu4.skel",
			name = "effect",
			action = "effect_loop",
			zOrder = 10,
			pos = {x = 175, y = 100},
		},
	},
	["scrollBuilding.crossunionfight"] = {
		varname = "crossunionfight",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onBuildingClick("crossunionfight")
				end)}
			},
			 {
			 	event = "extend",
			 	class = "red_hint",
			 	props = {
			 		specialTag = {
			 			"crossUnionFight",
			 		},
			 		onNode = function(panel)
						panel:xy(35, 330)
			 		end,
			 	}
			 },
			{
				event = "animation",
				name = "effect",
				res = "cross_union/byxj.skel",
				action = "stanby_loop",
				zOrder = 10,
				scale = 1.2,
				pos = {x = 195, y = 100},
			},
		},
	},
	["scrollBuilding.lobby.textNote"] = "textNote1",
	["scrollBuilding.training.textNote"] = "textNote2",
	["scrollBuilding.dailygift.textNote"] = "textNote3",
	["scrollBuilding.contribute.textNote"] = "textNote4",
	["scrollBuilding.unionskill.textNote"] = "textNote5",
	["scrollBuilding.fuben.textNote"] = "textNote6",
	["scrollBuilding.unionfight.textNote"] = "textNote7",
	["scrollBuilding.unionNotice.textNote"] = "textNote8",
	["scrollBuilding.unionFuli.textNote"] = "textNote9",
	["scrollBuilding.fragdonate.textNote"] = "textNote10",
	["scrollBuilding.unionShop.textNote"] = "textNote11",
	["scrollBuilding.unionNoName3.textNote"] = "textNote12",
	["scrollBuilding.unionAnswer.textNote"] = "textNote13",
	["scrollBuilding.crossunionfight.textNote"] = "textNote14",

	["scrollBuilding.lobby.imgTextBG"] = "imgTextBG1",
	["scrollBuilding.training.imgTextBG"] = "imgTextBG2",
	["scrollBuilding.dailygift.imgTextBG"] = "imgTextBG3",
	["scrollBuilding.contribute.imgTextBG"] = "imgTextBG4",
	["scrollBuilding.unionskill.imgTextBG"] = "imgTextBG5",
	["scrollBuilding.fuben.imgTextBG"] = "imgTextBG6",
	["scrollBuilding.unionfight.imgTextBG"] = "imgTextBG7",
	["scrollBuilding.unionNotice.imgTextBG"] = "imgTextBG8",
	["scrollBuilding.unionFuli.imgTextBG"] = "imgTextBG9",
	["scrollBuilding.fragdonate.imgTextBG"] = "imgTextBG10",
	["scrollBuilding.unionShop.imgTextBG"] = "imgTextBG11",
	["scrollBuilding.unionNoName3.imgTextBG"] = "imgTextBG12",
	["scrollBuilding.unionAnswer.imgTextBG"] = "imgTextBG13",
	["scrollBuilding.crossunionfight.imgTextBG"] = "imgTextBG14",
	["scrollBuilding.ribbon"] = "ribbon",
}

local FEATURES_FUNC = {
	unionFight = function(self, v, isLock, isRoleLock, item)
		local isOpen, day = dataEasy.judgeServerOpen("unionFight")
		isLock = isLock or not isOpen or not isRoleLock
		if not dataEasy.isInServer(v) then
			isLock = true
		end
		return isLock
	end,
	unionqa = function(self, v, isLock, isRoleLock, item)
		-- 未开放该功能
		if not gUnlockCsv.unionQA then
			item:setTouchEnabled(false)
			item:get("textNote"):visible(false)
			item:get("imgTextBG"):visible(false)
			item:get("imgTextBGMask"):visible(false)
			return
		end
		local day = csv.cross.union_qa.base[1].servOpenDays
		local isUnionAnswerDay = dataEasy.serverOpenDaysLess(day)
		if not dataEasy.isUnlock(gUnlockCsv.unionQA) or isUnionAnswerDay then
			isLock = true
		end
		return isLock
	end,
	dailygift = function (self, v, isLock, isRoleLock, item)
		local effectname = (self.dailyGiftTimes:read() >= 1 or isLock or dataEasy.notUseUnionBuild()) and "standby_loop" or "kelingqu_loop"
		self.dailygift:get("effect"):play(effectname)
		return isLock
	end,
	crossunionfight = function(self, v, isLock, isRoleLock, item)
		local isOpen, day = dataEasy.judgeServerOpen("crossunionfight")
		isLock = isLock or not isOpen or not isRoleLock
		if not dataEasy.isInServer(v) then
			isLock = true
		end
		return isLock
	end,
}

local LOCK_FEATURES_FUNC = {
	unionFight = function(self, unLockLv, unionLv, str, v, isLock, isRoleLock)
		local isOpen, day = dataEasy.judgeServerOpen("unionFight")
		if isLock or not isOpen or not isRoleLock then
			if not dataEasy.isInServer(v) then
				str = gLanguageCsv.pleaseWait
			elseif unLockLv == 0 or unLockLv > unionLv then
				str = string.format(gLanguageCsv.unionUnlockLevel, unLockLv)
			elseif not isOpen then
				str = string.format(gLanguageCsv.unlockServerOpen, day)
			elseif not isRoleLock then
				str = dataEasy.getUnlockTip(gUnlockCsv.unionFight)
			end
		else
			if gGameModel.role:read("union_fight_round") == "battle" then
				-- 播放入口动画
				local size = self.unionFight:size()
				local spinePath = "union_fight/gonghuizhan.skel"
				local ani = widget.addAnimationByKey(self.unionFight, spinePath, "main_ani", "effect_loop", 8)
					:xy(size.width / 2 + 40, size.height / 2 + 80)
			end
		end
		return str
	end,
	unionqa = function(self, unLockLv, unionLv, str, v, isLock, isRoleLock)
		local day = csv.cross.union_qa.base[1].servOpenDays
		local isUnionAnswerDay = dataEasy.serverOpenDaysLess(day)
		if not (unLockLv == 0 or unLockLv > unionLv) then
			if isUnionAnswerDay then
				str = string.format(gLanguageCsv.unlockServerOpen, day)
			end
			if not dataEasy.isUnlock(gUnlockCsv.unionQA) then
				str = dataEasy.getUnlockTip(gUnlockCsv.unionQA)
			end
		end
		return str
	end,
	crossunionfight = function(self, unLockLv, unionLv, str, v, isLock, isRoleLock)
		local isOpen, day = dataEasy.judgeServerOpen("crossunionfight")
		if isLock or not isOpen or not isRoleLock then
			if not dataEasy.isInServer(v) then
				str = gLanguageCsv.pleaseWait
			elseif unLockLv == 0 or unLockLv > unionLv then
				str = string.format(gLanguageCsv.unionUnlockLevel, unLockLv)
			elseif not isOpen then
				str = string.format(gLanguageCsv.unlockServerOpen, day)
			elseif not isRoleLock then
				str = dataEasy.getUnlockTip(gUnlockCsv.unionFight)
			end
		end
		return str
	end,
}

function UnionView:onCreate(_, crossUnionData)
	self.crossUnionData = crossUnionData
	self:initModel()
	self.crossunionfight:visible(dataEasy.isShow("crossunionfight"))

	-- 设备会有超过最大设计分辨率的，可见区域设置
	self.scrollBuilding:size(display.sizeInViewRect):x(display.sizeInViewRect.x):jumpToPercentHorizontal(50)
	self.scrollPlant:size(display.sizeInViewRect):x(display.sizeInViewRect.x)
	self.scroll:size(display.sizeInViewRect):x(display.sizeInViewRect.x)
	self.scrollCloud:size(display.sizeInViewRect):x(display.sizeInViewRect.x)
	self.scrollMont1:size(display.sizeInViewRect):x(display.sizeInViewRect.x)
	self.scrollMont2:size(display.sizeInViewRect):x(display.sizeInViewRect.x)
	self.scrollMont3:size(display.sizeInViewRect):x(display.sizeInViewRect.x)

	local function setScrollPercent(percent)
		self.scrollPlant:jumpToPercentHorizontal(percent)
		self.scroll:jumpToPercentHorizontal(percent)

		self.scrollMont1:jumpToPercentHorizontal(percent * 0.78)
		self.scrollMont2:jumpToPercentHorizontal(percent * 0.55)
		self.scrollMont3:jumpToPercentHorizontal(percent * 0.45)
		self.scrollCloud:jumpToPercentHorizontal(percent * 0.38)
	end
	setScrollPercent(50)

	self.scrollBuilding:onEvent(function(event)
		if event.name == "CONTAINER_MOVED" then
			local percent = self.scrollBuilding:getScrolledPercentHorizontal()
			setScrollPercent(percent)
		end
	end)

	-- lock
	local isLock = not gUnionFeatureCsv.dailygift or gUnionFeatureCsv.dailygift > self.unionLv:read()
	local effectName = (self.dailyGiftTimes:read() >= 1 or isLock or dataEasy.notUseUnionBuild()) and "standby_loop" or "kelingqu_loop"
	widget.addAnimationByKey(self.dailygift, "union/gonghuimeiri.skel", "effect", effectName, 1):xy(225, 40)

	self.isShowRedPack = dataEasy.getListenUnlock(gUnlockCsv.unionRedpacket)
	self.tarinRedHintState = false
	self.trainingRedHint = idler.new(false)

	gGameUI.topuiManager:createView("union", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.guild, subTitle = "CONSORTIA"})

	idlereasy.when(self.unionLv, function(_, unionLv)
		-- 增加锁住的状态
		for i,v in pairs(BUILDINGS) do
			local unLockLv = gUnionFeatureCsv[v] or 0
			local isLock = unLockLv == 0 or unLockLv > unionLv
			local isRoleLock = true
			local item = self[v]
			if FEATURES_FUNC[v] then
				isLock = FEATURES_FUNC[v](self, v, isLock, isRoleLock, item)
			end

			local lockInfo = item:get("lock")
			if lockInfo then
				-- mask:visible(isLock)
				cache.setShader(item:get("effect"), false, isLock and "gray" or "normal")
				-- mask:visible(false)
				lockInfo:visible(isLock)
				item:get("imgTextBGMask"):visible(isLock)
				-- if matchLanguage({"en"}) then
				-- 	item:get("imgTextBGMask"):height(320)
				-- 	item:get("imgTextBGMask"):y(item:get("imgTextBGMask"):y() - 45)
				-- end
				local str = string.format(gLanguageCsv.unionUnlockLevel, unLockLv)
				if LOCK_FEATURES_FUNC[v] then
					str = LOCK_FEATURES_FUNC[v](self, unLockLv, unionLv, str, v, isLock, isRoleLock)
				end
				lockInfo:get("textNote"):text(str)
			end

			local timeSchedule = isLock and 0 or 1
			local effect = item:get("effect")
			if effect then
				effect:setTimeScale(timeSchedule)
			end
		end
		self:setTrainingRedHint()
	end)

	local params = {
		self.unionLv,
		self.contribCount,
		self.unionAllTasks,
		self.unionTasks,
		self.dailyGiftTimes,
		self.trainingSpeedup,
		self.memberRedPacket,
		self.systemRedPacket,
		self.unionFbTimes,
		self.unionFragDonateStartTimes,
	}
	self.quickDatas = idlertable.new({})
	idlereasy.any(params, function(_, ... )
		local t = {}
		local count = 0
		for i,v in orderCsvPairs(csv.union.daily_notice) do
			local func = DAILYNOTICEFUNC[v.targetType]
			if func then
				local state, leftNum = func(self, v)
				if state then
					table.insert(t, {cfg = v, leftNum = leftNum, csvId = i})
					count = count + 1
					if count == 3 then
						break
					end
				end
			end
		end
		self.quickDatas:set(t)
		local itemSize = self.item:size()
		local margin = self.listview:getItemsMargin()
		local height = count * itemSize.height + margin * (count - 1)
		local size = self.leftUp:get("imgBg"):size()
		self.leftUp:get("imgBg"):size(size.width, height + 37 + 39)
		size = self.listview:size()
		self.listview:size(size.width, height)
		size = self.leftUp:size()
		local offy = (size.height - (height + 37 + 39)) / 2
		local bgy = size.height / 2 + offy
		self.leftUp:get("imgBg"):y(bgy)
		self.listview:y(bgy - (height + 37 + 39) / 2 + 37)
	end)
	self.hasEnter = idler.new(false)
	idlereasy.when(self.quickDatas, function(_, quickDatas)
		self.hasEnter:set(#quickDatas > 0)
	end)
	local redpacketData = {
		self.unionLv,
		self.memberRedPacket,
		self.systemRedPacket,
		self.redPacketRobCount,
		self.unionRedpackets,
		self.sendedRedPacket
	}
	idlereasy.any(redpacketData, function(_, unionLv, memberRedPacket, systemRedPacket, redPacketRobCount, unionRedpackets, sendedRedPacket)
		local unLockLv = gUnionFeatureCsv.redpacket or 0
		local isLock = unLockLv == 0 or unLockLv > unionLv
		local haveRedPacket = true
		local maxNum = gCommonConfigCsv.unionRobRedpacketDailyLimit
		if dataEasy.notUseUnionBuild() or isLock then
			haveRedPacket = false
		else
			haveRedPacket = (systemRedPacket and dataEasy.canSystemRedPacket()) or (memberRedPacket and maxNum > redPacketRobCount)
				or (not sendedRedPacket and itertools.size(unionRedpackets) > 0)
		end
		local actionName = haveRedPacket and "effect_loop" or "effect1_loop"
		setEffect(self.redpacket, actionName)
	end)

	if matchLanguage({"en"}) then
		for i = 1, math.huge do
			if not self["textNote"..i] then
				break
			end
			self["imgTextBG"..i]:height(320)
			adapt.setAutoText(self["textNote"..i], nil, 300)
			self["textNote"..i]:y(self["imgTextBG"..i]:y() - 165)
		end
	else
		for i = 1, math.huge do
			if not self["textNote"..i] then
				break
			end
			adapt.setAutoText(self["textNote"..i], nil, 244)
		end
	end

	self:crossUnionAnimaShow()
end

function UnionView:crossUnionAnimaShow()
	--跨服公会战开赛前三天展示
	local status = gGameModel.role:read("cross_union_fight_status")
	if status == nil then
		self.crossUnionAnima:hide()

	elseif status == "closed" then
		self.crossUnionAnima:hide()
		if self.crossUnionData and self.crossUnionData.union_db_id and 
			CrossUnionFightTools.whetherCloseShowUI() and not self.ribbon:get("panel"):get("rich") then
			self.ribbon:show()
			self.ribbon:get("imgIcon"):show()
			self.ribbon:get("panel"):show()
			self.ribbon:get("panel.name"):hide()
			local server = string.format(gLanguageCsv.brackets, getServerArea(self.crossUnionData.server_key, nil))
			local str = string.format(gLanguageCsv.getFirstPlace, server, self.crossUnionData.union_name)
			local richText = rich.createWithWidth(str, 32, nil, 240)
				:addTo(self.ribbon:get("panel"), 10, "rich")
				:anchorPoint(cc.p(0.5, 1))
				:xy(130, 66)
				:formatText()

			local width = (richText:height() / 36) * 67
			local animate = cc.Sequence:create(
				cc.MoveTo:create(gCommonConfigCsv["crossUnionFight"], cc.p(120, width)),
				cc.CallFunc:create(function()
					richText:xy(120, 20)
				end))
			local action = cc.RepeatForever:create(animate)
			richText:runAction(action)
		end
	else
		self.crossUnionAnima:show()
	end
end

function UnionView:initModel()
	self.roleLv = gGameModel.role:getIdler("level")
	self.id = gGameModel.role:getIdler("id")
	local unionInfo = gGameModel.union
	self.unionLv = unionInfo:getIdler("level")
	self.unionNoticeText = unionInfo:getIdler("intro")
	local dailyRecord = gGameModel.daily_record
	-- 每日礼包领取次数
	self.dailyGiftTimes = dailyRecord:getIdler("union_daily_gift_times")
	self.memberRedPacket = gGameModel.role:getIdler("union_role_packet_can_rob")
	self.systemRedPacket = gGameModel.role:getIdler("union_sys_packet_can_rob")
	self.contribCount = dailyRecord:getIdler("union_contrib_times")
	self.unionAllTasks = gGameModel.role:getIdler("union_contrib_tasks") -- 工会任务包括了工会任务的信息
	self.unionTasks = unionInfo:getIdler("contrib_tasks") -- 工会任务信息
	--成员列表 key长度24 ID长度12
	self.members = unionInfo:getIdler("members")
	-- 训练中心加速次数
	self.trainingSpeedup = dailyRecord:getIdler("union_training_speedup")
	-- 副本挑战次数
	self.unionFbTimes = dailyRecord:getIdler("union_fb_times")
	--抢红包数量
	self.redPacketRobCount = dailyRecord:getIdler("redPacket_rob_count")
	--可发红包数据
	self.unionRedpackets = gGameModel.role:getIdler("union_redpackets")
	--是否点击发红包页签
	self.sendedRedPacket = gGameModel.currday_dispatch:getIdler("sendedRedPacket")
	-- 公会碎片赠予发起次数
	self.unionFragDonateStartTimes = dailyRecord:getIdler("union_frag_donate_start_times")
end

function UnionView:setTrainingRedHint()
	local canUseTrain = unionTools.canEnterBuilding('training', nil, true)
	local unionTraining = gGameModel.union_training
	if not self.tarinRedHintState and canUseTrain and unionTraining then
		self.tarinRedHintState = true
		performWithDelay(self, function()
			gGameApp:requestServer("/game/union/training/list",function (tb)
				local count = 0
				local roleId = self.id:read()
				for i,v in ipairs(tb.view) do
					if roleId ~= v[1] and v[2] > 0 then
						count = count + 1
					end
				end

				self.opened = unionTraining:getIdler("opened")
				self.slots = unionTraining:getIdler("slots")
				self.trainSpeedUp = gGameModel.daily_record:getIdler("union_training_speedup")
				idlereasy.any({self.opened, self.slots, self.trainSpeedUp, self.roleLv}, function(_, opened, slots, speedUp, lv)
					local state = false
					if speedUp < 6 and count > 0 then
						state = true
					end
					for k,v in csvPairs(csv.union.training) do
						-- 栏位有空
						if opened[k] and not slots[k] then
							state = true
							break
						end
						if slots[k] and slots[k].level >= lv then
							state = true
							break
						end
					end
					self.trainingRedHint:set(state)
				end):anonyOnly(self, "setTrainingRedHint")
			end)
		end, 0)
	end
end

function UnionView:onBuildingClick(from)
	local jumpFunc = JUMPFUNCS[from]
	if jumpFunc then
		jumpFunc(self)
	end
end

-- 和onBuildingClick可以合并 是否合并看之后的逻辑
function UnionView:onItemClick(listview, k, v)
	if not v.goto then
		return
	end
	self:onBuildingClick(v.goto)
end

return UnionView