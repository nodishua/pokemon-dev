-- @desc 主城界面

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

local CHANNELS = {
	news = {name = gLanguageCsv.system, color = cc.c4b(238, 115, 143, 255)},
	world = {name = gLanguageCsv.world, color = cc.c4b(139, 175, 223, 255)},
	union = {name = gLanguageCsv.guild, color = cc.c4b(204, 143, 223, 255)},
	team = {name = gLanguageCsv.formTeam, color = cc.c4b(236, 183, 43, 255)},
	huodong = {name = gLanguageCsv.activity, color = cc.c4b(255, 94, 66, 255)},
	private = {name = gLanguageCsv.privateChat, color = cc.c4b(204, 143, 223, 255)},
}
local CHAT_PAGE_IDX = {
	news = 1,
	world = 2,
	union = 3,
	team = 4,
	huodong = 5,
	private = 6,
}
local SCHEDULE_TAG_SYSOPEN_TAG = 1000

local function isClickToday(key)
	local flag = userDefault.getForeverLocalKey(key, "")
	local today = time.getTodayStr()
	return flag == today
end

local function isClickVal(key, val)
	local flag = userDefault.getForeverLocalKey(key, "")
	return flag == tostring(val)
end

-- 判断这个二进制是否包含了2^4
local function delURLConfig(str)
	local result = false
	local flags = tonumber(string.sub(str, 2), 2)
	if not flags then
		return str
	end
	local len = string.len(str)
	if len < 5 then
		return str
	end

	local idx = len - 5 + 1
	if string.sub(str, idx, idx) == "0" then
		return str
	end

	local result = string.sub(str, 1, idx - 1) .. "0"
	result = result .. string.sub(str, idx + 1)

	return result
end

-- 定义数据放开头, 方便阅读，修改
local function getLeftBtnsData()
	return {
		{
			key = "signIn",
			icon = "city/main/icon_qd.png",
			name = gLanguageCsv.signIn,
			viewName = "city.sign_in",
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "signIn",
					onNode = function(node)
						node:xy(162, 162)
					end,
				}
			}
		},{
			key = "friend",
			icon = "city/main/icon_hy.png",
			name = gLanguageCsv.friend,
			viewName = "city.friend",
			func = function(cb)
				local friendView = require("app.views.city.friend")
				local showType, param = friendView.initFriendShowType()
				friendView.sendProtocol(showType, param, cb)
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"friendStaminaRecv",
						"friendReqs",
					},
					onNode = function(node)
						node:xy(162, 162)
					end,
				}
			}
		},{
			key = "rank",
			unlockKey = "rank",
			icon = "city/main/icon_ph@.png",
			name = gLanguageCsv.rank,
			viewName = "city.rank",
			styles = {full = true},
			func = function (cb)
				gGameApp:requestServer("/game/rank",function (tb)
					cb(tb.view.rank)
				end, "fight", 0, 10)
			end
		},{
			key = "union",
			unlockKey = "union",
			icon = "city/main/icon_gh@.png",
			name = gLanguageCsv.guild,
			func = function ()
				jumpEasy.jumpTo("union")
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"unionTraining",
						"unionSystemRedPacket",
						"unionMemberRedPacket",
						"unionSendedRedPacket",
						"unionDailyGift",
						"unionLobby",
						"unionContribute",
						"unionFuben",
						"unionFragDonate",
						"unionFightSignUp",
						"unionAnswer",
					},
					onNode = function(node)
						node:xy(162, 162)
					end,
				}
			}
		},
	}
end

local function getLeftBottomBtnsData()
	return {
		{
			key = "chatPrivataly",
			icon = "city/icon_xinxi.png",
			viewName = "city.chat.privataly",
			func = function(cb)
				local msg = gGameModel.messages:read('private')
				if itertools.isempty(msg) then
					gGameUI:showTip(gLanguageCsv.noPrivateChatList)
					return
				end
				cb()
			end,
		},{
			key = "mail",
			viewName = "city.mail",
		},{
			key = "setting",
			viewName = "city.setting.view",
		},
	}
end

local function getMainBtnsData()
	return {
		{
			key = "pvp",
			name = gLanguageCsv.pvp,
			viewName = "city.adventure.pvp",
			styles = {full = true},
			func = function(cb)
				cb("pvp")
			end,
		},{
			key = "pve",
			name = gLanguageCsv.adventure,
			viewName = "city.adventure.pve",
			styles = {full = true},
			func = function(cb)
				cb("pve")
			end,
		},{
			key = "gate",
			name = gLanguageCsv.gate,
			viewName = "city.gate.view",
			styles = {full = true}
		},
	}
end

local ViewBase = cc.load("mvc").ViewBase
local CityView = class("CityView", ViewBase)

CityView.RESOURCE_FILENAME = "city.json"
CityView.RESOURCE_BINDING = {
	["bgPanel"] = "bgPanel",
	["item"] = "item",
	["activityItem"] = "activityItem",  -- 运动活动图标item
	["leftTopPanel"] = "leftTopPanel",
	["leftTopPanel.head"] = {
		binds = {
			{
				event = "click",
				method = bindHelper.self("onPersonalInfo"),
			},
			{
				event = "extend",
				class = "role_logo",
				props = {
					logoId = bindHelper.self("logo"),
					frameId = bindHelper.self("frame"),
					level = false,
					vip = false,
				},
			},

		}
	},
	["leftTopPanel.name"] = "nameTxt",
	["leftTopPanel.level"] = "levelTxt",
	["leftTopPanel.vip"] = "roleVip",
	["leftTopPanel.vipNum"] = {
		varname = "vipNum",
		binds = {
			event = "text",
			idler = bindHelper.model("role", "vip_level"),
		},
	},
	["leftTopPanel.powerNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", "top6_fighting_point"),
		},
	},
	["leftTopPanel.yeartime"] = "yeartime",
	["leftTopPanel.daytime"] = "daytime",
	["rightPanel"] = "rightPanel",
	["rightPanel.titlePanel"] = "titlePanel",
	["rightPanel.achievementPanel"] = "achievementPanel",
	["rightPanel.achievementPanel.txt"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(109, 54, 186, 255), size = 4}}
			},
		}
	},
	["rightPanel.achievementPanel.txt1"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(109, 54, 186, 255), size = 4}}
			},
		}
	},
	["rightPanel.achievementPanel.bg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onClickAchievement()
			end)}
		},
	},
	["rightPanel.titlePanel.txt"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.PINK, size = 4}}
			},
		}
	},
	["rightPanel.titlePanel.txt1"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.PINK, size = 4}}
			},
		}
	},
	["rightPanel.titlePanel.bg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				idlereasy.do_(function (val)
					for i,v in ipairs(val) do
						if v.key == "title_book" then
							return view:onItemClick(nil, v)
						end
					end
				end, view.developBtns)
			end)}
		},
	},
	["leftTopPanel.rechargeItem"] = {
		varname = "rechargeItem",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onRechargeClick")}
			},{
				event = "extend",
				class = "multi_text_effect",
				props = {
					data = gLanguageCsv.recharge,
					effects = {
						{outline = {color=cc.c4b(54,66,82,255), size=6}},
						{outline = {color=cc.c4b(255,255,255,255), size=12}},
					},
					onNode = function(node)
						node:xy(140, 72):z(5)
					end,
				},
			},
		},
	},
	["leftPanel.list"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftBtns"),
				item = bindHelper.self("item"),
				margin = 12,
				onItem = function(list, node, k, v)
					node:name(v.key)
					node:get("icon"):texture(v.icon)
					node:removeChildByName("name")
					local name = label.create(v.name, {
						color = ui.COLORS.NORMAL.DEFAULT,
						fontSize = 42,
						fontPath = "font/youmi1.ttf",
					})
					text.addEffect(name, {outline = {color=ui.COLORS.NORMAL.WHITE, size=4}})
					name:addTo(node, 5, "name")
						:xy(90, 20)
					if v.redHint and (v.key ~= "union" or gGameModel.union_training) then
						bind.extend(list, node, v.redHint)
					end

					bind.touch(list, node, {methods = {
						ended = functools.partial(list.clickCell, v)
					}})
					uiEasy.updateUnlockRes(v.unlockKey, node, {justRemove = not v.unlockKey, pos = cc.p(140, 140)})
						:anonyOnly(list, list:getIdx(k))
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["leftBottomPanel.panel"] = "leftBottomBtnPanel",
	["leftBottomPanel.panel.btnTalk"] = {
		varname = "btnTalk",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					return view:onItemClick(nil, view.leftBottomBtns[1])
				end)}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("talkRedHint"),
					onNode = function(node)
						node:xy(120, 116)
					end,
				}
			}
		},
	},
	["leftBottomPanel.panel.btnMsg"] = {
		varname = "btnMsg",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					gGameApp:slientRequestServer("/game/sync")
					return view:onItemClick(nil, view.leftBottomBtns[2])
				end)}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "mail",
					onNode = function(node)
						node:xy(120, 116)
					end,
				}
			}
		},
	},
	["leftBottomPanel.panel.btnSet"] = {
		varname = "btnSetting",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onItemClick(nil, view.leftBottomBtns[3])
			end)}
		},
	},
	["leftBottomPanel.talkPanel.baseTalkPanel"] = "baseTalkPanel",
	["leftBottomPanel.talkPanel.baseTalkPanel.list"] = "talkList",
	["leftBottomPanel.talkPanel.baseTalkPanel.textPos"] = "textPos",
	["leftBottomPanel.talkPanel.talkbg"] = {
		varname = "talkbg",
		binds = {
			event = "click",
			method = bindHelper.self("onTalkClick"),
		},
	},
	["rightPanel.showList"] = "topShowList",
	["rightPanel.btnExpand"] = {
		varname = "activityExpandBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onActivityExpandClick")}
		},
	},
	["rightPanel.panel"] = "activityPanel",
	["rightPanel.panel.list"] = {
		varname = "activityList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("activityBtns"),
				dataOrderCmp = function(a, b)
					return a.sortWeight > b.sortWeight -- list从左往右加载，界面显示要求从右往左按照sortWeight排序，故按从大到小重新排序加载
				end,
				item = bindHelper.self("activityItem"),
				margin = ACTIVITY_LIST_MARGIN,
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list:enableSchedule():unScheduleAll()
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "labelTime")
					childs.icon:texture(v.icon)
					text.addEffect(childs.labelTime, {outline={color=ui.COLORS.OUTLINE.DEFAULT, size=3}})
					if v.endTime then 	-- 判断是否有截止日期，去决定是否要处理倒计时逻辑（显示逻辑在倒计时通用方法里）
						CityView.setCountdown(list, childs.labelTime, {endTime = v.endTime, tag = v.tag})
					else
						childs.labelTime:hide()
					end
					if v.redHint then
						bind.extend(list, node, v.redHint)
					end
					bind.touch(list, node, {methods = {
						ended = functools.partial(list.clickCell, v)
					}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["rightPanel.panel2"] = "activityPanel2",	-- 第二行活动panel，第一行活动图标达到上限后，剩余活动图标放在第二行
	["rightPanel.panel2.list"] = {
		varname = "activityList2",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("activityBtns2"),
				dataOrderCmp = function(a, b)
					return a.sortWeight > b.sortWeight -- list从左往右加载，界面显示要求从右往左按照sortWeight排序，故按从大到小重新排序加载
				end,
				item = bindHelper.self("activityItem"),
				margin = ACTIVITY_LIST_MARGIN,
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list:enableSchedule():unScheduleAll()
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "labelTime")
					childs.icon:texture(v.icon)
					text.addEffect(childs.labelTime, {outline={color=ui.COLORS.OUTLINE.DEFAULT, size=3}})
					if v.endTime then 	-- 判断是否有截止日期，去决定是否要处理倒计时逻辑（显示逻辑在倒计时通用方法里）
						CityView.setCountdown(list, childs.labelTime, {endTime = v.endTime, tag = v.tag})
					else
						childs.labelTime:hide()
					end
					if v.redHint then
						bind.extend(list, node, v.redHint)
					end
					bind.touch(list, node, {methods = {
						ended = functools.partial(list.clickCell, v)
					}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["centerBottomPanel.actionList"] = {
		varname = "actionList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("actionBtns"),
				item = bindHelper.self("item"),
				margin = 3,
				onItem = function(list, node, k, v)
					node:name(v.key)
					node:get("icon"):texture(v.icon)
					node:get("bg"):texture("city/main/panel_icon.png")
					node:get("bg"):scale(0.9)
					node:removeChildByName("name")
					local fontSize = 40
					if matchLanguage({"cn", "tw"}) then
						fontSize = 50
					end
					local name = label.create(v.name, {
						color = ui.COLORS.NORMAL.DEFAULT,
						fontSize = fontSize,
						fontPath = "font/youmi1.ttf",
					})
					text.addEffect(name, {outline = {color=ui.COLORS.NORMAL.WHITE, size=4}})
					name:addTo(node, 5, "name")
						:xy(84, 20)
					if v.redHint then
						bind.extend(list, node, v.redHint)
					end
					if v.actionExpandName then
						bind.touch(list, node, {methods = {
							ended = functools.partial(list.clickDevelop, node, v)
						}})
					else
						bind.touch(list, node, {methods = {
							ended = functools.partial(list.clickCell, v)
						}})
					end
					uiEasy.updateUnlockRes(v.unlockKey, node, {justRemove = not v.unlockKey,pos = cc.p(144, 144)})
						:anonyOnly(list, list:getIdx(k))
				end,
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
				clickDevelop = bindHelper.self("onItemDevelopClick"),
			},
		},
	},
	["developPanel"] = {
		varname = "developPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("actionExpandName"),
			method = function(name)
				return name ~= ""
			end,
		}
	},
	["developPanel.listItem"] = "listItem",
	["developPanel.bg"] = "developBg",
	["developPanel.developList"] = {
		varname = "developList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("developBtns"),
				item = bindHelper.self("listItem"),
				cell = bindHelper.self("item"),
				columnSize = 4,
				backupCached = false,
				onCell = function(list, node, k, v)
					node:scaleY(-1)
					node:name(v.key)
					node:get("icon"):texture(v.icon)
						:y(84)
					node:get("bg"):hide()
					bind.touch(list, node, {methods = {
						ended = functools.partial(list.clickCell, v)
					}})
					node:removeChildByName("name")
					local name = label.create(v.name, {
						color = ui.COLORS.NORMAL.DEFAULT,
						fontSize = matchLanguage({"kr"}) and 34 or 40,
						fontPath = "font/youmi1.ttf",
					})
					text.addEffect(name, {outline = {color=ui.COLORS.NORMAL.WHITE, size=4}})
					name:addTo(node, 5, "name")
						:xy(90, 20)

					if name:width() > 180 then
						name:scale(180 / name:width())
					end
					if v.key == 'mega' then
						node:get("icon"):scale(0.85)
					end
					if v.redHint then
						bind.extend(list, node, v.redHint)
					end
					v.unlockRes = uiEasy.updateUnlockRes(v.unlockKey, node, {justRemove = not v.unlockKey, pos = cc.p(140, 140)})
										:anonyOnly(list, list:getIdx(k))
				end,
				dataOrderCmp = function (a, b)
					local keyA = gUnlockCsv[a.unlockKey]
					local keyB = gUnlockCsv[b.unlockKey]
					if keyA and keyB then
						if csv.unlock[keyA].startLevel == csv.unlock[keyB].startLevel then
							return keyA < keyB
						end
						return csv.unlock[keyA].startLevel < csv.unlock[keyB].startLevel
					elseif not keyA and not keyB then
						return false
					else
						return keyA == nil
					end
				end,
				onAfterBuild = function (list)
					list:adaptTouchEnabled()
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["rightBottomPanel"] = "rightBottomPanel",
	["rightBottomPanel.mainList"] = "mainList",
	["rightBottomPanel.btnPvp"] = {
		varname = "itemPvp",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					return view:onItemClick(nil, view.mainBtns[1])
				end)}
			},{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = {
						"arenaAward",
						"crossArenaAward",
						"onlineFightAward",
					},
					onNode = function(node)
						node:xy(244, 244)
					end,
				}
			}
		},
	},
	["rightBottomPanel.btnPvp.namePanel"] = {
		binds = {
			event = "extend",
			class = "multi_text_effect",
			props = {
				data = gLanguageCsv.pvp,
				effects = {
					{outline = {color = ui.COLORS.NORMAL.WHITE, size = 4}}
				},
				labelParams = {
					color = ui.COLORS.NORMAL.DEFAULT,
					fontSize = 60,
					fontPath = "font/youmi1.ttf",
				},
				onNode = function(node)
					node:xy(95, 50):z(5)
				end
			}

		}
	},
	["rightBottomPanel.btnAdventure"] = {
		varname = "itemAdventure",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					return view:onItemClick(nil, view.mainBtns[2])
				end)}
			},{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = {
						"dispatchTask",
						"randomTower",
						"randomTowerPoint",
						"gymChallenge",
						"cloneBattle",
						"braveChallengeAch",
					},
					listenData = {
						sign = game.BRAVE_CHALLENGE_TYPE.common,
					},
					onNode = function(node)
						node:xy(244, 244)
					end,
				}
			}
		},
	},
	["rightBottomPanel.btnAdventure.namePanel"] = {
		binds = {
			event = "extend",
			class = "multi_text_effect",
			props = {
				data = gLanguageCsv.adventure,
				effects = {
					{outline = {color = ui.COLORS.NORMAL.WHITE, size = 4}}
				},
				labelParams = {
					color = ui.COLORS.NORMAL.DEFAULT,
					fontSize = 60,
					fontPath = "font/youmi1.ttf",
				},
				onNode = function(node)
					node:xy(95, 50):z(5)
				end
			},
		}
	},
	["rightBottomPanel.btnPve"] = {
		varname = "itemPve",
		binds = {
			{
				event = "touch",
				clicksafe = true,
				methods = {ended = bindHelper.defer(function(view)
					return view:onItemClick(nil, view.mainBtns[3])
				end)}
			},{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "pve",
					onNode = function(node)
						node:xy(244, 244)
					end,
				}
			}
		},
	},
	["rightBottomPanel.btnPve.namePanel"] = {
		binds = {
			event = "extend",
			class = "multi_text_effect",
			props = {
				data = gLanguageCsv.gate,
				effects = {
					{outline = {color = ui.COLORS.NORMAL.WHITE, size = 4}}
				},
				labelParams = {
					color = ui.COLORS.NORMAL.DEFAULT,
					fontSize = 60,
					fontPath = "font/youmi1.ttf",
				},
				onNode = function(node)
					node:xy(95, 50):z(5)
				end
			},
		}
	},
	-- 在线礼包相关
	["rightPanel.onlineGiftPanel"] = "onlineGiftPanelItem",		-- 在线奖励宝箱按钮
	["activityTip"] = "activityTip",
	["rightPanel.go"] = "go",
	["activityTip.textNote1"] = "textNote1",
	["activityTip.textNote2"] = "textNote2",
	["growGuide"] = "growGuide",
	["growGuide.textNote1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 4}}
		},
	},
	["marqueePanel"] = {
		varname = "marqueePanel",
		binds = {
			event = "extend",
			class = "marquee",
		}
	}
}

function CityView:onCreate()
	gGameUI.topuiManager:createView("city", self):init()
	self:enableSchedule()
	self:initModel()

	local subInject = {
		"app.views.city.view_scene",
		"app.views.city.view_action",
		"app.views.city.view_activity",
	}
	for _, name in ipairs(subInject) do
		local inject = require(name)
		inject(CityView)
	end

	idlereasy.when(self.vipHide, function(_, vipHide)
		self.roleVip:visible(not vipHide)
		self.vipNum:visible(not vipHide)
	end)

	self.baseTalkPanel:get("list"):setScrollBarEnabled(false)
	idlereasy.any({self.level, self.roleName}, function (obj, level, name)
		self.levelTxt:text(level)
		self.nameTxt:text(name)
		text.addEffect(self.nameTxt, {color=cc.c4b(255,255,255,255)})
		adapt.oneLinePos(self.levelTxt, self.nameTxt, cc.p(15, 0), "left")
		local width = math.max(630, self.nameTxt:x() + self.nameTxt:width() + 40)
		self.leftTopPanel:get("bg"):width(width)
	end)

	-- self.mainList:setScrollBarEnabled(false)
	self.topShowList:setScrollBarEnabled(false)

	self.actionExpandName = idler.new("")
	-- 自动弹出新手福利id, 0 表示未加入，-1表示加入并已显示
	self.autoNewPlayerWealId = idler.new(0)

	self:initData()
	self:initTitlePanel()
	self:initTalkPanel()
	self:initGrowPanel()
	self:achievementTip()

	self.autoPopBoxInfo = {}
	self:initPoster()
	-- 自动签到
	local lastSignInDay = gGameModel.monthly_record:read("last_sign_in_day")
	if lastSignInDay < time.getNowDate().day then
		table.insert(self.autoPopBoxInfo, {viewName = "city.sign_in", params = {true}})
	end
	-- 新手福利
	self:initAutoNewPlayerWeal()
	self:checkPopBox(true)

	local curMusicIdx = userDefault.getForeverLocalKey("musicIdx", 1)
	local cfg = csv.citysound[curMusicIdx]
	if cfg then
		audio.playMusic(cfg.path)
	else
		printWarn("music index not exist",curMusicIdx)
	end

	self.isRefresh = idler.new(false)
	idlereasy.any({self.level, self.isRefresh}, function(_, level, isRefresh)
		self:unSchedule(SCHEDULE_TAG_SYSOPEN_TAG)
		local cfgT = {}
		local date = time.getNowDate()
		local curTime = date.hour * 100 + date.min
		local wday = date.wday
		wday = wday == 1 and 7 or wday - 1 -- Sunday is 1
		local nextTime = math.huge
		local function isOK(v)
			if v.reminder ~= 2 and v.roundKey then
				-- 判断是否在对应服务器状态
				local roundState = gGameModel.role:read(v.roundKey)
				if roundState ~= v.roundState then
					return false
				end
			elseif v.reminder == 2 then
				local roundState = gGameModel.role:read(v.roundKey)
				if roundState == nil or tostring(roundState) == v.roundState then
					return false
				end
			end
			--判断公会
			if v.unionlevel then
				local unionId = gGameModel.role:read("union_db_id")
				local unionLv = gGameModel.union:read("level")
				if not unionId or unionLv < v.unionlevel then
					return false
				end
			end
			--判断开服天数
			if dataEasy.serverOpenDaysLess(v.serverday) then
				return false
			end
			if not itertools.include(v.openseq, wday) then
				return false
			end
			--判断开放时间
			if curTime < v.startTime or curTime >= v.endTime then
				return false
			end
			return true
		end
		-- 配表数量不会很多暂时不做缓存
		for k,v in orderCsvPairs(csv.sysopen) do
			if v.feature == "" or dataEasy.isUnlock(v.feature) then
				if v.reminder == 0
					or (v.reminder == 1 and not isClickToday("sysOpen" .. v.sighid))
					or (v.reminder == 2 and not isClickVal("sysOpen" .. v.sighid, gGameModel.role:read(v.roundKey))) then
					if isOK(v) then
						table.insert(cfgT, v)
					end
				end
				-- 简单处理，未开放，下个startTime重新计算
				local todayNum = tonumber(time.getTodayStr())
				if csvSize(v.startTimes) > 0 then
					for _, startTime in csvMapPairs(v.startTimes) do
						local dt = time.getNumTimestamp(todayNum, startTime/100, startTime%100) - time.getTime()
						if dt < 0 then
							dt = dt + 3600 * 24
						end
						nextTime = math.min(nextTime, dt)
					end
				else
					local dt = time.getNumTimestamp(todayNum, v.startTime/100, v.startTime%100) - time.getTime()
					if dt < 0 then
						dt = dt + 3600 * 24
					end
					nextTime = math.min(nextTime, dt)
				end
			end
		end

		table.sort(cfgT, function(a, b)
			return a.priority > b.priority
		end)

		self:initActivityTip(cfgT[1])
		self:schedule(function()
			self.isRefresh:notify()
			return false
		end, nextTime, nextTime, SCHEDULE_TAG_SYSOPEN_TAG)
	end)

	self:enableMessage():registerMessage("adapterNotchScreen", function(flag)
		adaptUI(self:getResourceNode(), "city.json", flag)
	end)

	-- 关闭到当前界面时触发
	self:registerMessage("stackUIViewExit", function(_, parentName)
		if parentName == "city.view" then
			performWithDelay(self, function()
				self:checkPopBox()
				self:refreshBaibian()
				self:refreshMysteryShop()
				self:refreshHuodongBoss()
				self:checkAchievementForGameUI()
				self.isRefresh:notify()
			end, 0)
		end
	end)

	self:setGameSyncTimer()

	self:setHorseRaceTimer()

	self:specialGiftLink()

	self:setTimeLabel()

	self:setSecialSupport()

	if device.platform == "windows" then
		-- 检测是否有异常卡牌
		for _, card in gGameModel.cards:pairs() do
			local cardId = card:read("card_id")
			if not csv.cards[cardId] then
				gGameUI:showDialog({content = string.format("数据中包含未开放的卡牌%d, 检查本地 language 与服务器是否一致", cardId)})
				break
			end
		end
	end
end

function CityView:onClose()
	-- 关闭前先注销事件，如进战斗暂存时
	self:unregisterMessage("stackUIViewExit")
	-- 清理在线礼包标记
	self.onlineGiftPanel = nil

	ViewBase.onClose(self)
end

function CityView:initModel()
	self.level = gGameModel.role:getIdler("level")
	self.roleName = gGameModel.role:getIdler("name")
	self.levelExp = gGameModel.role:getIdler("level_exp")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.vipHide = gGameModel.role:getIdler("vip_hide")
	self.logo = gGameModel.role:getIdler("logo")
	self.frame = gGameModel.role:getIdler("frame")
	self.allChannel = gGameModel.messages:getIdler("all")
	self.friendMessage = gGameModel.messages:getIdler('private')
	self.id = gGameModel.role:getIdler('id')
	self.figure = gGameModel.role:getIdler("figure")
	self.title = gGameModel.role:getIdler('title_id')
	self.titles = gGameModel.role:getIdler('titles')
	self.yyOpen = gGameModel.role:getIdler('yy_open')
	self.yyhuodongs = gGameModel.role:getIdler('yyhuodongs')
	self.yy_endtime = gGameModel.role:read("yy_endtime") 	-- 运营活动结束时间集合
	self.citySprites = gGameModel.role:getIdler("city_sprites")
	self.spriteGiftTimes =  gGameModel.daily_record:getIdler("city_sprite_gift_times")
	self.mysteryShopLastTime = gGameModel.mystery_shop:getIdler("last_active_time")
	--  {csv_id: (flag, count)} flag=1可领取, flag=0已领取
	-- count 就是对应的任务计数，如果是奖励的话，count就为0
	self.growGuideData = gGameModel.role:getIdler("grow_guide")
	-- {csvId:{[1] = flag, [2] = count}}
	self.tasks = gGameModel.role:getIdler("achievement_tasks")
	self.achiBoxes = gGameModel.role:getIdler("achievement_box_awards")
	self.redHintRefresh = idler.new(true) -- 用于刷新红点
	self.crossFishingRound = gGameModel.role:getIdler("cross_fishing_round") -- 钓鱼大赛是否开启
	self.fishingSelectScene = gGameModel.fishing:getIdler("select_scene")
	self.fishingIsAuto = gGameModel.fishing:getIdler("is_auto")
	self.reunion = gGameModel.role:getIdler("reunion")
end

function CityView:stackUI(name, handlers, styles, ...)
	gGameUI:stackUI(name, handlers, styles, ...)
end

-- 固定界面功能
function CityView:initData()
	self.leftBtns = getLeftBtnsData()
	self.leftBottomBtns = getLeftBottomBtnsData()
	self.mainBtns = getMainBtnsData()
	self:initActionData()
	self:initSceneData()
	self:initActivityData()
end

function CityView:onPersonalInfo()
	self:stackUI("city.personal.info", nil, {full = true})
end

-- 称号获得显示
function CityView:initTitlePanel()
	local originX = self.titlePanel:x()
	idlereasy.when(self.titles, function (_, val)
		if gGameModel.role.title_queue then
			self.titlePanel:show()
			transition.executeSequence(self.titlePanel, true)
				:moveTo(2, originX - self.titlePanel:width())
				:delay(1)
				:moveTo(2, originX)
				:done()
			gGameModel.role.title_queue = nil
		else
			self.titlePanel:hide()
		end
	end)
end

function CityView:onItemClick(list, v)
	if v.unlockKey and not dataEasy.isUnlock(v.unlockKey) then
		gGameUI:showTip(dataEasy.getUnlockTip(v.unlockKey))
		return
	end

	if v.func then
		v.func(function(...)
			local params = {}
			if v.independent == 4 or  v.independent == 5 then
				if v.independent == 4 then
					params = {"main", v.params[1]}
				else
					params = {"award", v.params[1]}
				end
			else
				params = clone(v.params or {})
				for _,v in ipairs({...}) do
					table.insert(params, v)
				end
			end
			self:stackUI(v.viewName, nil, v.styles, unpack(params))
		end, v.params or {})

	elseif v.viewName then
		self:stackUI(v.viewName, nil, v.styles, unpack(v.params or {}))
	end
	self.actionExpandName:set("")
end

function CityView:onItemDevelopClick(list, node, v)
	local x, y = node:xy()
	local pos = list:convertToWorldSpace(cc.p(x, y))
	self.developPanel:x(pos.x)
	self.actionExpandName:modify(function(name)
		if v.actionExpandName ~= name then
			return true, v.actionExpandName
		end
		return true, ""
	end)
end

function CityView:onRechargeClick()
	self:stackUI("city.recharge", nil, {full = true})
end

function CityView:onTalkClick()
	self:stackUI("city.chat.view", nil, {clickClose = true}, self.charIdx)
end

function CityView:onTalkExpandClick()
	self.talkExpand:modify(function(val)
		return true, not val
	end)
end

function CityView:onActivityExpandClick()
	self.activityExpand:modify(function(val)
		return true, not val
	end)
end

-- 聊天区数据
function CityView:initTalkPanel()
	self.charIdx = CHAT_PAGE_IDX.world
	self.talkRedHint = idler.new(false)
	idlereasy.when(self.allChannel,function (obj, messages)
		if messages and #messages > 0 then
			for i=#messages, 1, -1 do
				if messages[i].channel ~= "private" then
					local message = messages[i]
					self.charIdx = CHAT_PAGE_IDX[message.channel]
					local childs = self.baseTalkPanel:multiget("textChannel", "bg", "textPos", "list")
					childs.textChannel:text(CHANNELS[message.channel].name)
					text.addEffect(childs.textChannel, {color = CHANNELS[message.channel].color})
					local emojiKey = string.match(message.msg,"%[(%w+)%]")
					local newText = message.msg
					if gEmojiCsv[emojiKey] then
						newText = "#C0xA7F247#["..gEmojiCsv[emojiKey].text.."]"
					end

					local showText
					if itertools.first(game.MESSAGE_SHOW_TYPE[message.type], 3) then
						showText = message.args and message.args.name or message.role.name
						showText = showText and showText..": "..newText or newText
					else
						showText = message.msg
					end
					for i,v in csvMapPairs(csv.color) do
						showText = string.gsub(showText, v.key, v.exchange)
					end
					childs.textPos:removeAllChildren()
					childs.list:removeAllChildren()
					-- 去掉url的配置 即使配置了url也无效
					local p1, p2, s1 = string.find(showText, "#(L[^#]+)#")
					while p1 do
						local s2 = delURLConfig(s1)
						local str = string.sub(showText, 1, p1)
						showText = str .. s2 .. string.sub(showText, p2)
						p1, p2, s1 = string.find(showText, "#(L[^#]+)#", p2 + 1)
					end
					beauty.singleTextAutoScroll({
						strs = showText,
						fontSize = 36,
						speed = 36 * 3,
						style = 1,
						isRich = true,
						list = childs.list,
						align = "left",
						waitTimeSt = 2,
						waitTimeEnd = 2,
						anchor = cc.p(0, 0.5),
						vertical = cc.VERTICAL_TEXT_ALIGNMENT_CENTER
					})
					self.baseTalkPanel:show()
					return
				end
			end
		end
		self.baseTalkPanel:hide()
	end)
	local listPositionX = self.talkList:getInnerContainer():getPositionX()
	local deltaX = 0
	local boundX = 5.0 -- 超过2像素就认为是滑动了
	local function openTalkView(sender, eventType)
		if eventType == ccui.TouchEventType.began then
			deltaX = 0
		elseif eventType == ccui.TouchEventType.moved then
			if deltaX <= boundX then
				local newPositionX = self.talkList:getInnerContainer():getPositionX()
				deltaX = deltaX + math.abs(newPositionX - listPositionX)
				listPositionX = newPositionX
			end
		elseif eventType == ccui.TouchEventType.ended then
			if deltaX < boundX then
				self:onTalkClick()
			end
			deltaX = 0
			listPositionX = self.talkList:getInnerContainer():getPositionX()
		end
	end
	self.talkList:addTouchEventListener(function(sender, eventType)
		openTalkView(sender, eventType)
	end)

	self.chatPrivatalyLastId = gGameModel.forever_dispatch:getIdlerOrigin("chatPrivatalyLastId")
	idlereasy.any({self.friendMessage, self.chatPrivatalyLastId}, function (_, msg, chatPrivatalyLastId)
		local msgSize = itertools.size(msg)
		local lastMsg = msg[msgSize]
		if msg and msgSize ~= 0 and lastMsg.id > chatPrivatalyLastId and not lastMsg.isMine then
			self.talkRedHint:set(true, true)
		else
			self.talkRedHint:set(false)
		end
	end)
end

--@desc 初始化需要弹出的海报信息
function CityView:initPoster()
	-- 一次登录只弹出一次
	local posterShow = userDefault.getForeverLocalKey("posterLoginShow", false, {rawKey = true})
	if posterShow then
		return
	end

	self.posterState = idler.new(false)
	local data = {}
	self.posterIds = {}
	-- 本地存储 今日不再显示海报信息汇总
	local posterNotShowInfo = userDefault.getCurrDayKey("posterNotShowInfo", {})
	local newPlayerWeffare = gGameModel.currday_dispatch:getIdlerOrigin("newPlayerWeffare"):read()
	for _, id in ipairs(self.yyOpen:read()) do
		local cfg = csv.yunying.yyhuodong[id]
		if cfg.type == YY_TYPE.clientShow and cfg.independent == -1 then
			if not posterNotShowInfo[id] then
				local function insertPoster()
					self.posterIds[id] = true
					table.insert(data, {
						viewName = "city.activity.poster",
						id = id,
						sortWeight = cfg.sortWeight,
						params = {{cfg = cfg, state = self:createHandler("posterState")}},
					})
				end
				-- 重聚活动需单独判断
				if cfg.clientParam.isReunion then
					local reunion = self.reunion:read()
					if reunion and reunion.role_type == 1 then
						for k, v in ipairs(self.yyOpen:read()) do
							if v == reunion.info.yyID and reunion.info.end_time > time.getTime() then
								insertPoster()
							end
						end
					end
				else
					insertPoster()
				end
			end
		end
	end
	if not itertools.isempty(data) then
		table.sort(data, function (a, b)
			if a.sortWeight ~= b.sortWeight then
				return a.sortWeight < b.sortWeight
			end
			return a.id < b.id
		end)
		data[#data].params[1].cb = self:createHandler("onPosterCb")
		arraytools.merge_inplace(self.autoPopBoxInfo, {data})
	end
end

function CityView:onPosterCb()
	if self.posterState:read() then
		userDefault.setCurrDayKey("posterNotShowInfo", self.posterIds)
	end
end

-- 检测是否有自动弹出的，并弹出对应界面
function CityView:checkPopBox(isFirst)
	local function normalPopBox()
		if dev.IGNORE_POPUP_BOX then
			return
		end
		if isFirst and self.hasCheckPopBoxFirst then
			return
		end
		self.hasCheckPopBoxFirst = true
		-- 延迟一帧，先检测是否有新手引导
		performWithDelay(self, function()
			if gGameUI.guideManager:isInGuiding() then
				return
			end
			if itertools.isempty(self.autoPopBoxInfo) then
				-- 华为 临时运营策略调整提示框
				-- sdk.loginInfo = '{"userId":"8439676","token":"eafe754c59cfe08ff87cb1ac9bf1ec4f","displayName":"zxdzxd","channelId":"10005"}'
				if sdk.loginInfo then
					local t = json.decode(sdk.loginInfo)
					sdk.loginInfo = nil
					if t and t.channelId == "39" then
						gGameUI:showDialog({
							title = "提示",
							content = string.format("由于平台运营策略调整，《口袋觉醒》华为平台返利代金券活动将会暂停2-3周时间，已有的代金券不受影响，调整结束后返利代金券活动将恢复正常。\n\n感谢您对游戏的支持和喜爱，祝您游戏愉快。"),
							align = "left",
							fontSize = 40,
							dialogParams = {clickClose = true},
						})
					end
				end
				return
			end
			local data = self.autoPopBoxInfo[1]
			if data.viewName == "city.activity.poster" then
				userDefault.setForeverLocalKey("posterLoginShow", true, {rawKey = true})
			end
			table.remove(self.autoPopBoxInfo, 1)
			if data.func then
				data.func(function()
					self:stackUI(data.viewName, nil, data.styles, unpack(data.params or {}))
				end)
			else
				self:stackUI(data.viewName, nil, data.styles, unpack(data.params or {}))
			end
		end, 0)
	end

	-- 检测是否有实时对战断线重连, 若取消，则本次登录界面不再提示
	if not game.hasCheckOnlineFight and gGameModel.role:read("in_cross_online_fight_battle") then
		game.hasCheckOnlineFight = true
		gGameUI:showDialog({
			content = "#C0x5B545B#" .. gLanguageCsv.onlineFightReconnection,
			isRich = true,
			cb = function()
				dataEasy.onlineFightLoginServer(self, normalPopBox)
			end,
			closeCb = normalPopBox,
			btnType = 2,
			clearFast = true,
		})
	else
		normalPopBox()
	end
end

-- 新手福利自动弹出
function CityView:initAutoNewPlayerWeal()
	--当天弹出过
	local newPlayerWeffare = gGameModel.currday_dispatch:getIdlerOrigin("newPlayerWeffare"):read()
	if newPlayerWeffare == true then
		return
	end
	idlereasy.when(self.autoNewPlayerWealId, function(_, id)
		if id > 0 then
			table.insert(self.autoPopBoxInfo, {
				viewName = "city.activity.recharge_feedback.new_player_welfare",
				params = {id},
				func = function(cb)
					gGameApp:requestServer("/game/yy/active/get", function(tb)
						cb()
					end)
				end,
			})
			self.autoNewPlayerWealId:set(-1)
		end
	end)
end

function CityView:initActivityTip(data)
	if not data then
		self.activityTip:hide()
		self.activityTip:removeChildByName("gojt")
		return
	end

	widget.addAnimationByKey(self.activityTip, "huodongtixing/huodongtixing.skel", "gojt", "effect_loop", 1)
		:alignCenter(self.activityTip:size())
	local name = data.name or csv.unlock[gUnlockCsv[data.feature]].name
	adapt.setTextScaleWithWidth(self.activityTip:get("textNote1"), name, 180)
	adapt.setTextScaleWithWidth(self.activityTip:get("textNote2"), data.txt, 180)

	bind.touch(self, self.activityTip, {methods = {ended = function()
		if data.reminder == 2 then
			userDefault.setForeverLocalKey("sysOpen" .. data.sighid, tostring(gGameModel.role:read(data.roundKey)))
		else
			userDefault.setForeverLocalKey("sysOpen" .. data.sighid, time.getTodayStr())
		end
		jumpEasy.jumpTo(data.goto)
		if data.reminder ~= 0 then
			self.isRefresh:notify()
		end
	end}})

	self.activityTip:show()
end

function CityView:initGrowPanel()
	local growGuideListen = {self.growGuideData}
	for _, v in ipairs(gGrowGuideCsv) do
		table.insert(growGuideListen, dataEasy.getListenUnlock(v.feature))
	end
	idlereasy.any(growGuideListen, function(_, growGuideData, ...)
		local unlocks = {...}
		local itemDatas = {}
		local count = 0
		for _, v in ipairs(gGrowGuideCsv) do
			local csvId = v.id
			count = count + 1
			if not growGuideData or not growGuideData[csvId] or growGuideData[csvId][1] ~= 0 then
				local data = {}
				data.cfg = v
				data.csvId = csvId
				-- 1 :可领取 2: 未解锁 3:进行中
				local state = 3
				if growGuideData and growGuideData[csvId] and growGuideData[csvId][1] == 1 then
					state = 1
				elseif not unlocks[count] then
					state = 2
				end
				-- 石英大会需要判断开服时间
				if v.feature == "craft" and state ~= 2 then
					local state1, day = dataEasy.judgeServerOpen("craft")
					if not state1 and day then
						state = 2
						data.serverDay = day
					end
				end
				data.state = state
				table.insert(itemDatas, data)
			end
		end
		table.sort(itemDatas, function(a, b)
			local csvTab = csv.unlock
			local cfgA = csvTab[gUnlockCsv[a.cfg.feature]]
			local unLockLvA = cfgA.startLevel
			local cfgB = csvTab[gUnlockCsv[b.cfg.feature]]
			local unLockLvB = cfgB.startLevel

			if unLockLvA ~= unLockLvB then
				return unLockLvA < unLockLvB
			end
			return a.csvId < b.csvId
		end)
		local useData, selIdx
		-- 选取一个与选项 state从小到大
		local target = 999
		for i,v in ipairs(itemDatas) do
			if v.state < target then
				useData = v
				target = v.state
				selIdx = i
			end
			if target == 1 then
				break
			end
		end
		if not useData then
			self.growGuide:hide()
			return
		end

		self.growGuide:get("textNote1"):text(useData.cfg.name)
		self.growGuide:removeChildByName("getEffect")
		self.growGuide:get("imgBg"):show()
		local str = ""
		-- 1 可领取 2锁住 3进行中
		if useData.state == 1  then
			str = gLanguageCsv.rewardCanGet
			self.growGuide:get("imgBg"):hide()
			widget.addAnimationByKey(self.growGuide, "effect/xiangdao.skel", "getEffect", "effect_loop", 3)
				:xy(-1078, 143)
		elseif useData.state == 2 then
			local key = gUnlockCsv[useData.cfg.feature]
			local cfg = csv.unlock[key]
			str = string.format(gLanguageCsv.arrivalLevelOpen, cfg.startLevel)
			if useData.serverDay then
				str = string.format(gLanguageCsv.unlockServerOpen, useData.serverDay)
			end
		elseif useData.state == 3 then
			str = gLanguageCsv.stateFighting
		end
		self.growGuide:get("textNote2"):text(str)
		adapt.setTextScaleWithWidth(self.growGuide:get("textNote2"), nil, 170)
		self.growGuide:show()

		bind.touch(self, self.growGuide, {methods = {ended = function()
			gGameUI:stackUI("city.grow_guide", nil, nil, selIdx)
		end}})
	end)
end

function CityView:achievementTip()
	local width = self.achievementPanel:width()
	local originX = self.rightPanel:size().width + width
	idlereasy.any({self.tasks, self.achiBoxes}, function(_, tasks, box)
		self:checkAchievementForGameUI()
	end):anonyOnly(self, "achievementTasks")
end

function CityView:checkAchievementForGameUI()
	if not dataEasy.isUnlock(gUnlockCsv.achievement) then
		return
	end

	if not gGameUI:findStackUI("city.view") or not gGameModel.role.achievement_queue then
		return
	end

	for csvId, state in pairs(gGameModel.role.achievement_queue) do
		gGameUI:showAchievement(csvId)
	end

	gGameModel.role.achievement_queue = nil
end

function CityView:onClickAchievement()
	if not dataEasy.isUnlock(gUnlockCsv.achievement) then
		return
	end
	self:stackUI("city.achievement", nil, {full = true})
end

-- @desc 运营活动通用设置倒计时方法
-- @params{info 倒计时信息, tag 定时器标签，cb 回调方法}
function CityView.setCountdown(view, uiTime, params)
	view:enableSchedule()
	view:unSchedule(params.tag)
	local countTime = params.endTime - time.getTime() -- 倒计时
	if countTime <= 0 then
		uiTime:hide()
		if params.cb then
			params.cb()
		end
		return
	end
	view:schedule(function()
		countTime = params.endTime - time.getTime()
		local times = time.getCutDown(countTime)
		local hour = times.day*24 + times.hour
		if times.day and times.day > 0 then
			uiTime:text(string.format("%s" .. gLanguageCsv.day,gLanguageCsv.exclusiveIconTime,times.day))
		else
	 	    uiTime:text(string.format("%02d:%02d:%02d",times.hour, times.min, times.sec))
	 	end

		if countTime <= 0 then
			CityView.setCountdown(view, uiTime, params)
		end
	end, 1, 0, params.tag)
end

function CityView:onReFreshRedHint()
	self.redHintRefresh:modify(function(val)
		return true, not val
	end)
end

function CityView:setGameSyncTimer()
	local timer = {5*3600, 21*3600}
	timer[#timer + 1] = timer[1] + 24 * 3600
	local currTime = time.getNowDate()
	local currSec = currTime.hour * 3600 + currTime.min*60 + currTime.sec
	local delta = 1
	for i = 1, #timer do
		if timer[i] > currSec then
			delta = timer[i] - currSec + 1
			break
		end
	end
	performWithDelay(self, function()
		gGameApp:slientRequestServer("/game/sync", functools.handler(self, "setGameSyncTimer"))
	end, delta)
end

function CityView:setFishingGameTimer()
	-- 钓鱼大赛固定每天的5点刷新, 15 秒准备之间; 23点结束
	local timer = {5*3600+15, 23*3600}
	timer[#timer + 1] = timer[1] + 24 * 3600
	local currTime = time.getNowDate()
	local currSec = currTime.hour * 3600 + currTime.min*60 + currTime.sec
	local delta = 1
	for i = 1, #timer do
		if timer[i] > currSec then
			delta = timer[i] - currSec + 1
			break
		end
	end
	performWithDelay(self, function()
		gGameApp:slientRequestServer("/game/sync", functools.handler(self, "setFishingGameTimer"))
	end, delta)
end

function CityView:specialGiftLink()
	if matchLanguage({"kr"}) then
		-- kr外链
		local btn = ccui.ImageView:create("city/main/icon_krgift.png")
			:setTouchEnabled(true)
			:scale(0.95)
			:xy(128, 410)
		bind.touch(self, btn, {methods = { ended = function()
			gGameUI:stackUI("city.kr_gift_link_view")
		end}})
		self.rightBottomPanel:addChild(btn, 2, "krGift")
	end
end

function CityView:setSecialSupport()
	if matchLanguage({"en"}) then
		local btn = ccui.ImageView:create("login/icon_kfzx.png")
			:setTouchEnabled(true)
			:scale(0.86)
			:xy(443, 55)
		bind.touch(self, btn, {methods = {ended = function()
			cc.Application:getInstance():openURL(SUPPORT_URL)
		end}})
		self.leftBottomBtnPanel:addChild(btn, 2, "enSupport")

		local x, y = 443, 55
		if display.sizeInView.width / display.sizeInView.height >= 2.0 then
			x = x + 120
		else
			y = y - 120
		end

		local btnDiscord = ccui.ImageView:create("login/icon_discord.png")
			:setTouchEnabled(true)
			:scale(0.86)
			:xy(x, y)
		bind.touch(self, btnDiscord, {methods = {ended = function()
			cc.Application:getInstance():openURL(DISCORD_URL)
		end}})
		self.leftBottomBtnPanel:addChild(btnDiscord, 2, "enDiscord")
	end
end

-- for en timeLabel
function CityView:setTimeLabel()
	if matchLanguage({"en"}) then
		self.daytime:visible(true)
		self.yeartime:visible(true)
		local Month = {"Jan.","Feb.","Mar.","Apr.","May.","Jun.","Jul.","Aug.","Sep.","Oct.","Nov.","Dec.",}
		self:enableSchedule():schedule(function()
			local T = time.getTimeTable()
			self.yeartime:text(string.format("%s/%02d/%04d",Month[T.month],T.day,T.year))
			self.daytime:text(string.format("%02d:%02d",T.hour, T.min))
		end, 1, 0)
	else
		self.daytime:visible(false)
		self.yeartime:visible(false)
	end
end

return CityView
