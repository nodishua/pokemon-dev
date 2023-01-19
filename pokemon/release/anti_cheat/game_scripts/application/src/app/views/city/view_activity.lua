-- 主城 - 运营活动子模块

local CityView = {}

local ActivityView = require("app.views.city.activity.view")
local OnlineGiftView = require("app.views.city.online_gift")
local helper = require "easy.bind.helper"
local redHintHelper = require "app.easy.bind.helper.red_hint"

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE
-- 运营活动定时器为 10000 + yyid
local SCHEDULE_TAG_YY_BASE = 10000
-- 定时器tag集合，防止重复
local SCHEDULE_TAG = {
	-- sceneSet = 1,
	-- cityMan = 2,
	-- mysteryShop = 3,
	onlineGift = 4,
	limitBuyGift = 5,
	-- dispatchTaskRefresh = 6,
}

-- 活动list item间距
local ACTIVITY_LIST_MARGIN = 12
-- 活动list第一行上限，理论上只有两行, 若超过，目前处理在加在第二行尾部（注：活动list从右往左为从头到尾）
local ACTIVITY_ONELINE_LIMIT = 8

local function always_true()
	return true
end

-- 运营活动常驻入口
local function getActivityDefaultData()
	-- sortWeight 小的在右侧
	return {
		{
			-- 福利入口 independent = 3
			icon = "city/main/icon_fl@.png",
			viewName = "city.activity.view",
			styles = {full = true},
			independentStyle = "award",
			func = function(cb)
				gGameApp:requestServer("/game/yy/active/get", function(tb)
					cb("award")
				end)
			end,
			sortWeight = -11,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "totalActivityShow",
					listenData = {
						independent = 3,
					},
				},
			}
		},
		{
			-- 限时活动入口 independent = 0
			icon = "city/main/icon_xshd.png",
			viewName = "city.activity.view",
			styles = {full = true},
			independentStyle = "main",
			func = function(cb)
				gGameApp:requestServer("/game/yy/active/get", function(tb)
					cb()
				end)
			end,
			sortWeight = -10,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "totalActivityShow",
					listenData = {
						independent = 0,
					},
				},
			}
		},
		{
			icon = "city/main/icon_tqlb.png",
			viewName = "city.recharge",
			styles = {full = true},
			params = {{showPrivilege = true}},
			sortWeight = -9,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"vipGift",
						"onHonourableVip"
					},
				}
			}
		},
		{
			-- 周年庆整合入口
			cityTheme = "anniversary",
			icon = "city/main/icon_znq.png",
			viewName = "city.activity.anniversary",
			styles = {full = true},
			sortWeight = -8,
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/active/get", function(tb)
					cb(params)
				end)
			end,
		},
		{
			-- 夏日祭整合入口
			cityTheme = "summerOffering",
			icon = "city/main/icon_xrj.png",
			viewName = "city.activity.summer_offering",
			styles = {full = true},
			sortWeight = -7,
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/active/get", function(tb)
					cb(params)
				end)
			end,
		},
	}
end

-- 运营id外置入口活动
local function getActivityInfoData(self)
	local defaultFunc = function(cb)
		gGameApp:requestServer("/game/yy/active/get", function(tb)
			cb(tb)
		end)
	end
	return {
		--首充
		[YY_TYPE.firstRecharge] = {
			viewName = "city.activity.first_recharge",
			sortWeight = -9,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "firstRecharge",
				}
			}
		},
		--开服嘉年华
		[YY_TYPE.serverOpen] = {
			viewName = "city.activity.server_open.view",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "serverOpen",
				},
			}
		},
		--战力排行
		[YY_TYPE.fightRank] = {
			viewName = "city.activity.activity_fight_rank",
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/fightrank/get", function(tb)
					cb(tb)
				end, params[1])
			end,
		},
		--招财猫
		[YY_TYPE.luckyCat] = {
			viewName = "city.activity.lucky_cat",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "luckyCat",
				},
			}
		},
		--返利活动
		[YY_TYPE.rmbgoldReward] = {
			viewName = "city.activity.rmbgold_reward",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "rmbgoldReward",
				},
			}
		},
		-- 通行证
		[YY_TYPE.passport] = {
			viewName = "city.activity.passport.view",
			func = defaultFunc,
			styles = {full = true},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"passportCurrDay",
						"passportReward",
						"passportTask",
					},
				}
			}
		},
		-- 玩法通行证
		[YY_TYPE.playPassport] = {
			viewName = "city.activity.passport.game_view",
			func = defaultFunc,
			styles = {full = true},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"playPassport",
					},
				}
			}
		},
		-- 限时神兽
		[YY_TYPE.timeLimitBox] = {
			viewName = "city.activity.limit_sprite",
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/limit/box/get", function (tb)
					cb(tb.view, self:createHandler("onReFreshRedHint"))
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"limitSpritesHasFreeDrawCard",
						"limitSpritesHasBoxAward",
					},
					listenData = {
						refresh = bindHelper.self("redHintRefresh"),
					},
					onNode = function(node)
						node:xy(156, 236)
					end,
				}
			}
		},
		-- 充值回馈 新手活动
		[YY_TYPE.loginWeal] = {
			viewName = "city.activity.recharge_feedback.new_player_welfare",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "loginWealRedHint",
				}
			}
		},
		-- 充值回馈 七天登陆
		[YY_TYPE.LoginGift] = {
			viewName = "city.activity.recharge_feedback.normal_view",
			icon = "city/main/icon_xshd.png",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "loginGiftRedHint",
				}
			}
		},
		-- 充值回馈 充值大转盘(又名充值夺宝)
		[YY_TYPE.rechargeWheel] = {
			viewName = "city.activity.recharge_wheel",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"rechargeWheel",
						"rechargeWheelFree",
					}
				}
			}
		},
		-- 活跃夺宝
		[YY_TYPE.livenessWheel] = {
			viewName = "city.activity.liveness_wheel",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "livenessWheel",
				}
			}
		},
		-- 单笔充钻石返还
		[YY_TYPE.onceRechageAward] = {
			viewName = "city.activity.once_recharge_award",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "onceRechargeAward",
				}
			}
		},
		-- 限时直购礼包
		[YY_TYPE.limitBuyGift] = {
			viewName = "city.activity.limit_buy_gift",
			tag = true,
			func = defaultFunc,
			timeLabelFunc = function(yyId, huodong, cb, item)
				-- yyId 无用，显示为统一入口
				-- 限时直购礼包，倒计时限时集合, 用于判断图标显示/隐藏及倒计时限时
				local times = {}
				for _, yyId in ipairs(self.yyOpen:read()) do
					local cfg = csv.yunying.yyhuodong[yyId]
					if cfg.type == YY_TYPE.limitBuyGift then
						for i,v in orderCsvPairs(csv.yunying.limitbuygift) do
							if v.huodongID == cfg.huodongID then
								-- 第一步判断，是否有正处在时间内的活动
								-- 1、时间戳存在用于判断已激活，2、当前时间-激活时间戳<持续时间，用于判断是否已过期
								if huodong.valinfo[i] and (time.getTime() - huodong.valinfo[i].time < v.duration*60) then
									-- 第二步判断，活动是否有未完成活动
									local leftTimes = huodong.stamps[i] or 1
									local buyTimes = 1 - leftTimes
									buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", yyId, i, buyTimes)
									if buyTimes == 0 then
										table.insert(times, {startTime = huodong.valinfo[i].time, cfg = v})
									end
								end
							end
						end
					end
				end
				if #times > 0 then
					if item then
						self:setLimitBuyGiftCountTime(item, times, cb)
					end
					return true
				end
				return false
			end,
		},
		-- 春节活动
		[YY_TYPE.festival] = {
			viewName = "city.activity.chinese_new_year",
			func = function(cb)
				gGameApp:requestServer("/game/yy/red/packet/list", function(data)
					for k,v in pairs(data.view.packets) do
						v.roleId = self.id:read()
					end
					cb(clone(data.view.packets))
				end)
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "festivalRedHint",
				}
			}
		},
		-- 跨服春节红包
		[YY_TYPE.huodongCrossRedPacket] = {
			viewName = "city.activity.chinese_new_year",
			func = function(cb)
				gGameApp:requestServer("/game/yy/cross/red/packet/list", function(data)
					for k,v in pairs(data.view.packets) do
						v.roleId = self.id:read()
					end
					cb(clone(data.view.packets))
				end)
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "crossFestivalRedHint",
				}
			}
		},
		--扭蛋机
		[YY_TYPE.luckyEgg] = {
			viewName = "city.activity.recharge_feedback.activity_lucky_egg",
			styles = {full = true},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"luckyEggDrawCardFree",
					},
				}
			}
		},
		-- 直购礼包
		[YY_TYPE.directBuyGift] = {
			viewName = "city.activity.direct_buy_gift",
			styles = {full = true},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "activityDirectBuyGift",
				},
			},
		},
		-- 每日充值活动
		[YY_TYPE.generalTask] = {
			viewName = "city.activity.first_recharge_daily",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "firstRechargeDaily",
				},
			},
		},
		--周卡 独立图标和活动界面都显示f
		[YY_TYPE.weeklyCard] = {
			viewName = "city.activity.view",
			styles = {full = true},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/active/get", function(tb)
					cb("main")
				end)
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "activityWeeklyCard",
				},
			},
		},
		-- 世界Boss
		[YY_TYPE.worldBoss] = {
			viewName = "city.activity.world_boss.view",
			styles = {full = true},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/world/boss/main", function(tb)
					cb(tb)
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "activityWorldBoss",
				},
			},
		},
		-- 符石抽卡up
		[YY_TYPE.gemUp] = {
			viewName = "city.activity.gem_up.view",
			tag = true,
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "gemUp",
				},
			},
		},
		-- 端午节活动
		[YY_TYPE.baoZongzi] = {
			viewName = "city.activity.duan_wu_festival.view",
			tag = true,
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "zongZiActivity",
				},
			},
		},
		-- 限时碎片转换
		[YY_TYPE.qualityExchange] = {
			viewName = "city.activity.quality_exchange_fragment",
			func = defaultFunc,
		},
		-- 幸运乐翻天
		[YY_TYPE.flipCard] = {
			viewName = "city.activity.flip_card",
			tag = true,
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "flipCardActivity",
				},
			},
		},
		--节日Boss
		[YY_TYPE.huoDongBoss] = {
			viewName = "city.activity.activity_boss.view",
			styles = {full = true},
			func = function(cb)
				local huodongId
				for _, id in ipairs(self.yyOpen:read()) do
					local cfg = csv.yunying.yyhuodong[id]
					if cfg.type == YY_TYPE.huoDongBoss then
						huodongId = id
						break
					end
				end

				gGameApp:requestServer("/game/yy/huodongboss/list", function(tb)
					cb(tb)
				end, huodongId,gCommonConfigCsv.huodongbossMaxNumber)
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "activityBoss",
				},
			},
		},
		-- 训练家重聚
		[YY_TYPE.reunion] = {
			viewName = "city.activity.reunion.view",
			styles = {full = true},
			func = function (cb)
				local reunion = self.reunion:read()
				if reunion.info.end_time - time.getTime() < 0 or reunion.role_type == 0 then
					self.updateActivity:notify()
					gGameUI:showTip(gLanguageCsv.activityOver)
					return
				end
				local bind_role_db_id = gGameModel.reunion_record:read("bind_role_db_id")
				local roleID = ""
				if reunion.role_type == 1 then
					roleID = bind_role_db_id or ""
				elseif reunion.role_type == 2 then
					roleID = reunion.info.role_id
				end
				if roleID ~= "" then
					gGameApp:requestServer("/game/role_info", function (tb)
						local info = tb.view
						local params = {info = info}
						if reunion.role_type == 2 then
							gGameApp:requestServer("/game/yy/reunion/record/get", function(tb)
								params = {info = info, reunionRecord = tb.view.reunion_record}
								if cb then
									cb(params)
								end
							end, roleID)
						else
							if cb then
								cb(params)
							end
						end
					end, roleID)
				else
					cb({})
				end
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "reunionActivity",
				},
			},
		},
		-- 双十一
		[YY_TYPE.double11] = {
			viewName = "city.activity.double11.view",
			styles = {full = true},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/double11/main", function(tb)
					cb(tb)
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "double11",
				},
			},
		},
		-- 圣诞雪球游戏
		[YY_TYPE.snowBall] = {
			viewName = "city.activity.snow_ball.view",
			styles = {full = true},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/snowball/main", function(tb)
					cb(tb)
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "snowBall",
				},
			},
		},
		-- 集福赢新年
		[YY_TYPE.flipNewYear] = {
			viewName = "city.activity.new_year_flip_card",
			tag = true,
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "flipNewYear",
				},
			},
		},
		-- 摩天大楼
		[YY_TYPE.skyScraper] = {
			viewName = "city.activity.sky_scraper.view",
			styles = {full = true},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "skyScraper",
				},
			},
		},
		-- 走格子
		[YY_TYPE.gridWalk] = {
			viewName = "city.activity.grid_walk.view",
			styles = {full = true},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/gridwalk/main",function (tb)
					cc.SpriteFrameCache:getInstance():addSpriteFrames('activity/grid_walk/gezi.plist')
					cb()
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "gridWalkMain",
				},
			},
		},
		-- 勇者挑战
		[YY_TYPE.braveChallenge] = {
			viewName = "city.activity.brave_challenge.view",
			styles = {full = true},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/brave_challenge/main", function(tb)
					cb(1)
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "braveChallengeAch",
					listenData = {
						sign = game.BRAVE_CHALLENGE_TYPE.anniversary,
					},
				},

			},
		},
		-- 赛马
		[YY_TYPE.horseRace] = {
			viewName = "city.activity.horse_race.view",
			styles = {full = true},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/horse/race/main", function(tb)
					cb(tb)
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "horseRaceMain",
				},
			},
		},
		-- 礼券商店
		[YY_TYPE.itemBuy2] = {
			viewName = "city.activity.coupon_shop",
			styles = {full = true},
			func = defaultFunc,
		},
		-- 尊享限定
		[YY_TYPE.exclusiveLimit] = {
			viewName = "city.activity.exclusive_limit",
			tag = true,
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "exclusiveLimit",
				},
			},
		},

		--派遣活动
		[YY_TYPE.dispatch] = {
			viewName = "city.activity.dispatch.view",
			styles = {full = true},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "activityDispatch",
				},
			},
		},
		--夏日挑战
		[YY_TYPE.summerChallenge] = {
			viewName = "city.activity.summer_challenge.view",
			styles = {full = true},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "summerChallenge",
				},
			},
		},

		--沙滩刨冰
		[YY_TYPE.shavedIce] = {
			viewName = "city.activity.beach_ice.view",
			styles = {full = true},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "shavedIce",
				},
			},
		},
		-- 沙滩排球
		[YY_TYPE.volleyball] = {
			viewName = "city.activity.volleyball.view",
			styles = {full = true},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "volleyball",
				},
			},
		},
		-- 中秋祈福
		[YY_TYPE.midAutumnDraw] = {
			viewName = "city.activity.mid_autumn_draw",
			styles = {full = true},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "midAutumnDraw",
				},
			},
		},
		-- 定制礼包
		[YY_TYPE.customizeGift] = {
			viewName = "city.activity.customize_gift",
			styles = {full = false},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "customizeGift",
				},
			},
		}
	}
end

-- 活动数据
function CityView:initActivityData()
	local activityInfo = getActivityInfoData(self)
	local activityDatas = getActivityDefaultData()
	self.activityExpand = idler.new(false)
	self.activityBtns = idlereasy.new({}) 	-- 第一行list
	self.activityBtns2 = idlereasy.new({})	-- 第二行list

	-- 活动列表刷新标识
	self.updateActivity = idler.new(0)
	idlereasy.any({self.yyOpen, self.yyhuodongs, self.reunion, self.updateActivity}, function (_, yyOpen, yyhuodongs, reunion, updateActivity)
		self:dropSate()
		self:showMXIcon()
		local expendRedHintData = {}
		local expendRedHintSpecialTag = {}
		local expendRedHintListenData = {}
		-- 活动图标目前仅支持两行显示，总数理论上不超过16个，若有超过16个，目前暂添加在第二行的尾部
		local storeTotalDatas = {} -- 收纳图标-总数
		local storeDatas1 = {} -- 收纳图标-第一行
		local storeDatas2 = {} -- 收纳图标-第二行
		local showDatas = {} -- 不收纳图标
		local cityThemeDatas = {} -- 主题整合界面
		for _, v in ipairs(activityDatas) do
			if not v.showTheme and not v.cityTheme and (not v.independentStyle or ActivityView.isDataExist(v.independentStyle)) then
				table.insert(storeTotalDatas, v)
				-- 活动扩展按钮数据记录
				if v.redHint then
					local data = v.redHint.props
					if type(data.specialTag) == "string" then
						expendRedHintSpecialTag = arraytools.merge_inplace(expendRedHintSpecialTag, {{data.specialTag}})
					else
						expendRedHintSpecialTag = arraytools.merge_inplace(expendRedHintSpecialTag, {data.specialTag or {}})
					end
					expendRedHintListenData = maptools.extend({expendRedHintListenData, data.listenData or {}})
					table.insert(expendRedHintData, {
						data = data,
					})
				end
			end
		end

		-- 该类型的活动仅显示一个, 标记为false，显示后为true
		local onlyShowOne = {
			[YY_TYPE.firstRecharge] = false,
			[YY_TYPE.limitBuyGift] = false,
			[YY_TYPE.directBuyGift] = {
				noraml = false,
				double11 = false,
			},
		}
		for _, id in ipairs(yyOpen) do
			local huodong = yyhuodongs[id] or {}
			local cfg = csv.yunying.yyhuodong[id]
			local function isOK()
				if cfg.type == YY_TYPE.directBuyGift then
					local key = cfg.clientParam.double11 and "double11" or "normal"
					if onlyShowOne[cfg.type][key] == true then
						return false
					end
				end
				if onlyShowOne[cfg.type] == true then
					return false
				end
				if not self:isActivityShow(id, huodong, activityInfo) then
					return false
				end
				return true
			end
			if isOK() then
				if onlyShowOne[cfg.type] == false then
					onlyShowOne[cfg.type] = true
				end
				if cfg.type == YY_TYPE.directBuyGift then
					local key = cfg.clientParam.double11 and "double11" or "normal"
					onlyShowOne[cfg.type][key] = true
				end

				-- 同一个type的两个活动 不clone的话会被前一个覆盖
				local t = clone(activityInfo[cfg.type])
				if cfg.type == YY_TYPE.reunion then
					t.params = {}
				else
					t.params = {id} -- 打开界面默认参数
				end
				t.icon = cfg.icon
				t.sortWeight = cfg.sortWeight

				if cfg.type == YY_TYPE.luckyCat then
					-- 招财猫有两种界面 金币招财猫和钻石招财猫
					if cfg.paramMap.type == "rmb" or cfg.paramMap.type == nil then--策划要求为rmb时和不配置参数时默认为钻石招财猫
						t.viewName = "city.activity.lucky_cat"
					elseif cfg.paramMap.type == "gold" then
						t.viewName = "city.activity.gold_lucky_cat"
						-- 两种招财猫显示不同红点
						t.redHint = {
							class = "red_hint",
							props = {
								specialTag = "goldLuckyCat",
							},
						}
					end
				end

				if cfg.type == YY_TYPE.directBuyGift then
					if cfg.clientParam.double11 then
						t.redHint = nil
						t.viewName = "city.activity.double11.shop"
					else
						t.viewName = "city.activity.direct_buy_gift"
					end
				end

				if cfg.type == YY_TYPE.itemBuy2 then
					if cfg.clientParam.cityTheme == "summerOffering" then
						t.viewName = "city.activity.summer_shop"
					else
						t.viewName = "city.activity.coupon_shop"
					end
				end

				if t.redHint then
					local data = t.redHint.props
					data.listenData = maptools.extend({
						data.listenData or {},
						{
							activityId = id,
						},
					})
					-- 活动扩展按钮数据记录
					if type(data.specialTag) == "string" then
						expendRedHintSpecialTag = arraytools.merge_inplace(expendRedHintSpecialTag, {{data.specialTag}})
					else
						expendRedHintSpecialTag = arraytools.merge_inplace(expendRedHintSpecialTag, {data.specialTag or {}})
					end
					expendRedHintListenData = maptools.extend({expendRedHintListenData, data.listenData or {}})
					table.insert(expendRedHintData, {
						id = id,
						data = data,
					})
				end

				if cfg.type == YY_TYPE.LoginGift then
					-- 七日登陆有两种界面展示 春节和普通
					if cfg.clientParam.springFestival then
						t.viewName = "city.activity.recharge_feedback.spring_festival_view"
					end
				end

				if cfg.type == YY_TYPE.serverOpen then
					-- 嘉年华有三种界面展示 鼠年春节和普通还有五一
					if cfg.clientParam.type == "springFestival" then
						t.viewName = "city.activity.server_open.view_spring_festival"
					elseif cfg.clientParam.type == "mayDay" or cfg.clientParam.type == "vacation" or cfg.clientParam.type == "national" then
						t.viewName = "city.activity.server_open.view_may_day"
					elseif cfg.clientParam.type == "doubleYearsDay" then
						t.viewName = "city.activity.server_open.view_double_years_day"
					elseif cfg.clientParam.type == "anniversary" then
						t.viewName = "city.activity.server_open.view_anniversary"
					end
				end

				if cfg.type == YY_TYPE.playPassport then
					-- 主题通行证 -> 登录通行证
					if cfg.paramMap.type == 1 then
						t.viewName = "city.activity.passport.record_game_view"
						t.styles = nil
					end
				end

				if cfg.type == YY_TYPE.horseRace then
					t.redHint = {
						class = "red_hint",
						props = {
							specialTag = "horseRaceMain",
							listenData = {
								activityId = id,
								refresh = bindHelper.defer(function()
									return self.redHintRefresh
								end),
							},
						},
					}
				end

				-- 配表客户端字段中配置showCountTime字段后，显示倒计时
				if t.tag and cfg.clientParam.showCountTime then
					t.endTime = self.yy_endtime[id]
					-- 同类型活动多开，要设置不同定时器
					t.tag = SCHEDULE_TAG_YY_BASE + id
				end

				-- 当前第一排不收纳进去图标最多四个, 其余都收纳
				t.id = id
				t.independent = cfg.independent
				local cityTheme = cfg.clientParam.cityTheme
				if cityTheme then
					cityThemeDatas[cityTheme] = cityThemeDatas[cityTheme] or {}
					table.insert(cityThemeDatas[cityTheme], t)

				elseif cfg.independent == 2 and itertools.size(showDatas) < 4 then
					table.insert(showDatas, t)
				else
					table.insert(storeTotalDatas, t)
				end
			end
		end

		-- 整合主题入口
		for _, datas in ipairs(activityDatas) do
			if datas.cityTheme and cityThemeDatas[datas.cityTheme] then
				local t = clone(datas)
				table.insert(storeTotalDatas, t)
				t.params = {cityThemeDatas[datas.cityTheme]}

				local cityThemeRedHintData = {}
				local cityThemeRedHintSpecialTag = {}
				local cityThemeRedHintListenData = {}
				for _, v in ipairs(cityThemeDatas[datas.cityTheme]) do
					if v.redHint then
						local data = v.redHint.props
						if type(data.specialTag) == "string" then
							cityThemeRedHintSpecialTag = arraytools.merge_inplace(cityThemeRedHintSpecialTag, {{data.specialTag}})
						else
							cityThemeRedHintSpecialTag = arraytools.merge_inplace(cityThemeRedHintSpecialTag, {data.specialTag or {}})
						end
						cityThemeRedHintListenData = maptools.extend({cityThemeRedHintListenData, data.listenData or {}})
						table.insert(cityThemeRedHintData, {
							data = data,
							id = v.id,
						})
					end
				end
				if not itertools.isempty(cityThemeRedHintSpecialTag) then
					t.redHint = {
						class = "red_hint",
						props = {
							specialTag = cityThemeRedHintSpecialTag,
							listenData = cityThemeRedHintListenData,
							func = function(datas)
								local yyOpen = gGameModel.role:read('yy_open')
								local hash = arraytools.hash(yyOpen)
								for _, t in ipairs(cityThemeRedHintData) do
									if hash[t.id] then
										-- 赋静态值
										for k, v in pairs(t.data.listenData or {}) do
											if not helper.isHelper(v) and not helper.isIdler(v) then
												datas[k] = v
											end
										end
										local tags = t.data.specialTag
										if type(tags) ~= "table" then
											tags = {tags}
										end
										for _, specialTag in pairs(tags) do
											local f = redHintHelper[specialTag] or always_true
											if f(datas) then
												return true
											end
										end
									end
								end
								return false
							end,
						},
					}
				end
			end
		end

		table.sort(showDatas, function(a, b)
			if a.sortWeight ~= b.sortWeight then
				return a.sortWeight < b.sortWeight
			end
			return a.id < b.id
		end)
		table.sort(storeTotalDatas, function(a, b)
			if a.sortWeight ~= b.sortWeight then
				return a.sortWeight < b.sortWeight
			end
			return a.id < b.id
		end)
		self:resetShowList(yyhuodongs, showDatas)

		-- 这里的1是在线礼包，第一行最多显示8个图标
		if itertools.size(storeTotalDatas) + itertools.size(showDatas) + 1 > ACTIVITY_ONELINE_LIMIT then
			local count = ACTIVITY_ONELINE_LIMIT - (itertools.size(showDatas) + 1)
			for i = 1, count do
				table.insert(storeDatas1, storeTotalDatas[i])
			end
			-- 超过8个显示在第二行
			for i = count+1, itertools.size(storeTotalDatas) do
				table.insert(storeDatas2, storeTotalDatas[i])
			end
		else
			for i = 1, itertools.size(storeTotalDatas) do
				table.insert(storeDatas1, storeTotalDatas[i])
			end
		end
		self.activityBtns:set(storeDatas1)
		self.activityBtns2:set(storeDatas2)

		-- 活动扩展按钮数据记录
		bind.extend(self, self.activityExpandBtn, {
			class = "red_hint",
			props = {
				state = bindHelper.self("activityExpand"),
				specialTag = expendRedHintSpecialTag,
				listenData = maptools.extend({
					expendRedHintListenData,
					{
						activityId = id,
					},
				}),
				func = function(datas)
					for _, t in ipairs(expendRedHintData) do
						-- 赋静态值
						for k, v in pairs(t.data.listenData or {}) do
							if not helper.isHelper(v) and not helper.isIdler(v) then
								datas[k] = v
							end
						end
						local tags = t.data.specialTag
						if type(tags) ~= "table" then
							tags = {tags}
						end
						for _, specialTag in pairs(tags) do
							local f = redHintHelper[specialTag] or always_true
							if f(datas) then
								return true
							end
						end
					end
					return false
				end,
				onNode = function(panel)
					panel:xy(45, 120)
				end,
			}
		})
	end)

	self.activityList:setItemsMargin(ACTIVITY_LIST_MARGIN)
	self.activityList2:setItemsMargin(ACTIVITY_LIST_MARGIN)
	local size = self.item:size()
	local count = self.activityBtns:size()
	local count2 = self.activityBtns2:size()
	local width = size.width * count + ACTIVITY_LIST_MARGIN * (count - 1)
	local width2 = size.width * count2 + ACTIVITY_LIST_MARGIN * (count2 - 1)
	self.activityList:x(width)
	self.activityList2:x(width2)
	local isFirst = true
	local dv = 1500 -- 变化速度
	local function sizeChange()
		local count = self.activityBtns:size()
		local lastWidth = self.activityPanel:width()
		local lastX = self.activityList:x()
		local width = size.width * count  + ACTIVITY_LIST_MARGIN * (count - 1)
		self.activityPanel:size(width, self.activityPanel:height())
		self.activityList:size(width, self.activityList:height())
			:x(width - lastWidth + lastX)
		return width
	end

	local function sizeChange2()
		local count2 = self.activityBtns2:size()
		local lastWidth2 = self.activityPanel2:width()
		local lastX2 = self.activityList2:x()
		local width2 = size.width * count2  + ACTIVITY_LIST_MARGIN * (count2 - 1)
		width2 = math.min(width2, size.width * 10.5  + ACTIVITY_LIST_MARGIN * 9)
		self.activityPanel2:size(width2, self.activityPanel2:height())
		self.activityList2:size(width2, self.activityList2:height())
			:x(width2 - lastWidth2 + lastX2)
		return width2
	end
	idlereasy.any({self.activityBtns,self.activityBtns2}, function()
		self.activityExpand:notify()
	end)
	idlereasy.if_not(self.activityExpand, function()
		sizeChange()
		sizeChange2()
		local dt = math.abs(self.activityList:x() - 0) / dv
		local dt2 = math.abs(self.activityList2:x() - 0) / dv
		local showListX = self.activityPanel:x() - self.activityPanel:width()
		self.activityExpandBtn:setFlippedX(false)
		if isFirst then
			isFirst = false
			self.activityList:x(0)
			self.activityList2:x(0)
			self.topShowList:x(showListX)
		else
			transition.executeSequence(self.activityList, true)
				:easeBegin("EXPONENTIALOUT")
				:moveTo(dt, 0)
				:easeEnd()
				:done()
			transition.executeSequence(self.activityList2, true)
				:easeBegin("EXPONENTIALOUT")
				:moveTo(dt2, 0)
				:easeEnd()
				:done()
			transition.executeSequence(self.topShowList, true)	-- 跟随活动列表飞出
				:easeBegin("EXPONENTIALOUT")
				:moveTo(dt, showListX)
				:easeEnd()
				:done()
		end
	end)
	idlereasy.if_(self.activityExpand, function()
		local width = sizeChange()
		local width2 = sizeChange2()
		local dt = math.abs(self.activityList:x() - width) / dv
		local dt2 = math.abs(self.activityList2:x() - width2) / dv
		local showListX = self.activityPanel:x()
		self.activityExpandBtn:setFlippedX(true)
		transition.executeSequence(self.activityList, true)
			:easeBegin("EXPONENTIALOUT")
			:moveTo(dt, width)
			:easeEnd()
			:done()
		transition.executeSequence(self.activityList2, true)
			:easeBegin("EXPONENTIALOUT")
			:moveTo(dt2, width2)
			:easeEnd()
			:done()
		transition.executeSequence(self.topShowList, true)
			:easeBegin("EXPONENTIALOUT")
			:moveTo(dt, showListX)
			:easeEnd()
			:done()
	end)

	self:initOnlineGift()
	self:refreshHuodongBoss()
end

function CityView:isActivityShow(id, huodong, activityInfo)
	local cfg = csv.yunying.yyhuodong[id]
	-- 只需要独立显示图标（1、不收纳 2、收纳 4、外部收纳+活动 5、外部收纳+福利）
	if cfg.independent ~= 1 and cfg.independent ~= 2 and cfg.independent ~= 4 and cfg.independent ~= 5 then
		return false
	end
	-- 首充已领取的不显示
	if cfg.type == YY_TYPE.firstRecharge and huodong.flag == 2 then
		return false
	end
	if not activityInfo[cfg.type] then
		local hash = itertools.map(YY_TYPE, function(k, v) return v, k end)
		printWarn("activityInfo 中没有支持 type(%d:%s) 的独立活动", cfg.type, hash[cfg.type])
		return false
	end
	-- 新手福利领取完成不显示
	if cfg.type == YY_TYPE.loginWeal then
		local receivedCount = 0
		for actId, state in pairs(huodong.stamps) do
			if state == 0 then
				receivedCount = receivedCount + 1
			end
		end
		local isShow = receivedCount < 7
		if isShow and self.autoNewPlayerWealId:read() == 0 then
			self.autoNewPlayerWealId:set(id)
		end
		return isShow
	end

	-- 训练家重聚
	if cfg.type == YY_TYPE.reunion then
		local huodong = self.reunion:read()
		local currentTime = time.getTime()
		if huodong and huodong.info and huodong.info.yyID == id and huodong.role_type ~= 0 and huodong.info.end_time - time.getTime() > 0  then
			return true
		end
		return false
	end

	-- 周卡显示
	if cfg.type == YY_TYPE.weeklyCard then
		if huodong.buy == nil then
			local hour, min = time.getHourAndMin(cfg.beginTime)
			local buyDay = cfg.paramMap.buyDay
			local endTime = time.getNumTimestamp(cfg.beginDate,hour,min) + buyDay*24*60*60
			if endTime - time.getTime() <= 0 then
				return false
			end
		else
			local hour, min = time.getHourAndMin(cfg.endTime)
			local endTime = time.getNumTimestamp(cfg.endDate,hour,min)
			if endTime - time.getTime() <= 0 then
				return false
			end
		end
		return true
	end

	local t = activityInfo[cfg.type]
	if t.timeLabelFunc then
		-- 检查倒计时内是否有可以显示的信息，没有隐藏图标
		if not t.timeLabelFunc(id, huodong) then
			return false
		end
	end

	return true
end

-- 剧情关卡双倍掉落
function CityView:dropSate()
	local dropSate, paramMaps, count = dataEasy.isDoubleHuodong("gateDrop")
	local sceneConf = csv.scene_conf
	if dropSate then
		dropSate = false -- 先置为false
		for _, paramMap in pairs(paramMaps) do
			local startId = paramMap["start"]
			local endId = paramMap["end"]
			local startConf = sceneConf[startId]
			if startConf.gateType == game.GATE_TYPE.normal then -- 关卡类型为 1
				dropSate = true
				break
			end
		end
	end

	if dropSate then
		if not self.itemPve.spr then
			local spr = cc.Sprite:create("common/icon/double/label_sb.png")
			spr:addTo(self.itemPve, 1, "doubleImg")
				:xy(30, 230)
			self.itemPve.spr = spr
		end
	else
		if self.itemPve.spr then
			self.itemPve:removeChildByName("doubleImg")
			self.itemPve.spr = nil
		end
	end
end

function CityView:showMXIcon()
	local state, cfg = dataEasy.isShowDailyActivityIcon()
	if state then
		local panel = self.itemAdventure:getChildByName("_icon_")
		if panel then
			return
		end
		--	添加帽子和气泡
		panel = ccui.Layout:create()
			:size(self.itemAdventure:size())
			:addTo(self.itemAdventure, 1, "_icon_")
		local info = cfg.paramMap
		ccui.ImageView:create(info.mxRes)
			:xy(65, 220)
			:addTo(panel, 1 ,"_maozi_")

		local tips = ccui.ImageView:create(info.tipsRes)
			:anchorPoint(0.9, 0)
			:xy(35, 190)
			:addTo(panel, 2, "_tips_")
		local animate = cc.Sequence:create(
			cc.ScaleTo:create(0.3, 1.1),
			cc.ScaleTo:create(0.06, 0.95),
			cc.ScaleTo:create(0.03, 1.0),
			cc.DelayTime:create(2),
			cc.ScaleTo:create(0.1, 0.01),
			cc.DelayTime:create(1.0))
		local action = cc.RepeatForever:create(animate)
		tips:runAction(action)
	else
		local panel = self.itemAdventure:getChildByName("_icon_")
		if panel then
			panel:removeFromParent()
		end
	end
end

-- 对不收进去的图标 在此整理, onlineGiftPanel 特殊处理
function CityView:resetShowList(yyhuodongs, showDatas)
	for i = self.topShowList:getChildrenCount(), 1, -1 do
		local item = self.topShowList:getItem(i-1)
		if item:name() ~= "onlineGiftPanel" then
			item:removeFromParent()
		end
	end
	for i, v in ipairs(showDatas) do
		local item = self.rightPanel:get("item"):clone():scaleX(-1)
		self.topShowList:insertCustomItem(item, i-1)

		local labelTime = item:get("labelTime")
		item:get("icon"):texture(v.icon)
		text.addEffect(labelTime, {outline={color=ui.COLORS.OUTLINE.DEFAULT, size=3}})
		-- 判断是否有截止日期，去决定是否要处理倒计时逻辑（显示逻辑在倒计时通用方法里）
		if v.endTime then
			if v.timeLabelFunc then
				v.timeLabelFunc(v.id, yyhuodongs[v.id] or {}, nil, item)
			else
				CityView.setCountdown(self, labelTime, {endTime = v.endTime, tag = v.tag})
			end
		else
			labelTime:hide()
		end
		if v.redHint then
			bind.extend(self, item, v.redHint)
		end
		bind.touch(self, item, {methods = {
			ended = functools.partial(self.onItemClick, self, nil, v)
		}})
	end
end

-- 在线礼包
function CityView:initOnlineGift()
	self.onlineGift = gGameModel.daily_record:getIdler("online_gift")
	self.onlineGiftState = idler.new(1) -- 1可查看奖励 2可领取奖励

	local function setItemShow(flag)
		local name = "onlineGiftPanel"
		local item = self.onlineGiftPanelItem
		if flag and not self.topShowList:getChildByName(name) then
			item = item:clone()
				:show()
				:name(name)
				:scaleX(-1)

			bind.touch(self.topShowList, item, {methods = {ended = function()
				self:onOnlineGift()
			end}})
			local count = self.topShowList:getChildrenCount()
			self.topShowList:insertCustomItem(item, count)
			self.onlineGiftPanel = item

		elseif not flag and self.onlineGiftPanel then
			self.onlineGiftPanel:removeFromParent()
			self.onlineGiftPanel = nil
		end
	end

	-- 领取特效
	idlereasy.any({self.onlineGift, self.level, dataEasy.getListenUnlock(gUnlockCsv.onlineGift)}, function (obj, val, level, isUnlock)
		-- 达到最高在线奖励等级后, 隐藏在线奖励图标
		local max = csvSize(csv.online_gift)
		local idx = val.idx or max
		if idx >= max then
			setItemShow(false)
			return
		end

		-- 未解锁状态下隐藏
		if isUnlock then
			setItemShow(true)
		else
			return
		end

		if not self.onlineGiftPanel then return end

		self.onlineGiftState:set(1, true)
		OnlineGiftView.setCountdown(self, self.onlineGiftPanel:get("labelTime"), {data = self.onlineGift:read(), tag = SCHEDULE_TAG.onlineGift, cb = function()
			self.onlineGiftState:set(2, true)
		end})
	end)

	idlereasy.when(self.onlineGiftState, function (_, onlineGiftState)
		if not self.onlineGiftPanel then return end
		self.onlineGiftPanel:get("icon"):setVisible(onlineGiftState == 1)
		if onlineGiftState == 1 then
			text.addEffect(self.onlineGiftPanel:get("labelTime"), {color=ui.COLORS.NORMAL.WHITE})
			text.addEffect(self.onlineGiftPanel:get("labelTime"), {outline = {color=ui.COLORS.NORMAL.DEFAULT, size = 3}})
			local img = self.onlineGiftPanel:get("xiaohupa")
			if img then
				img:removeSelf()
			end
		elseif onlineGiftState == 2 then
			text.addEffect(self.onlineGiftPanel:get("labelTime"), {color=ui.COLORS.NORMAL.LIGHT_GREEN})
			text.addEffect(self.onlineGiftPanel:get("labelTime"), {outline = {color=ui.COLORS.NORMAL.DEFAULT, size = 3}})
			self.onlineGiftPanel:get("labelTime"):text(gLanguageCsv.onlineGiftGet)
			local onlineGiftSpine = widget.addAnimationByKey(self.onlineGiftPanel, "xiaohupa/xiaohupa.skel", 'xiaohupa', "effect_loop", 99)
				:anchorPoint(cc.p(0.5,0.5))
				:xy(self.onlineGiftPanel:width()/2, self.onlineGiftPanel:height()/2 - 8) -- 8为位置修正参数
		end
	end)
end

--@desc 在线礼包点击, onlineGiftState = 1时可预览奖励, onlineGiftState = 2 时可领取奖励
function CityView:onOnlineGift()
	if self.onlineGiftState:read() == 1 then
		local data = {view = self, uiTime = self.onlineGiftPanel:get("labelTime"), tag = SCHEDULE_TAG.onlineGift, cb = function()
			self.onlineGiftState:set(2)
		end}
		self:stackUI("city.online_gift", nil, nil, data)
	elseif self.onlineGiftState:read() == 2 then
		gGameApp:requestServer("/game/role/online_gift/award",function (tb)
			self:stackUI("city.online_gift_gain", nil, nil, tb)
		end)
	end
end

-- @desc 设置限时直购礼包的倒计时
function CityView:setLimitBuyGiftCountTime(item, times, cb)
	self:enableSchedule():schedule(function()
		local currentCountTime      -- 当前限时直购礼包限时倒计时时长
		for i,v in ipairs(times) do
			local countTime = v.cfg.duration*60 - (time.getTime() - v.startTime) -- 计算剩余倒计时
			if countTime > 0 then
				if not currentCountTime then       -- 获取最小倒计时，显示出来
					currentCountTime = countTime
				elseif countTime < currentCountTime  then
					currentCountTime = countTime
				end
			end
		end

		if currentCountTime then
			-- 这里要改造成最大只显示到小时，如1天01:23:23 要显示成25:23:23
			local countTimes = time.getCutDown(currentCountTime)
			local str = countTimes.str
			item:get("labelTime"):text(str)
			item:get("labelTime"):visible(countTimes.day == 0)  	-- 倒计时大于24小时不显示
		else
			if cb then
				cb()
			end
			return false
		end
	end, 1, 0, SCHEDULE_TAG.limitBuyGift)
end

function CityView:refreshHuodongBoss()
	local oldBossTimes = userDefault.getForeverLocalKey("activityBossCount", 0)
	local yyhuodongs = self.yyhuodongs:read()
	local huodongId
	for _, id in ipairs(self.yyOpen:read()) do
		local cfg = csv.yunying.yyhuodong[id]
		if cfg.type == YY_TYPE.huoDongBoss then
			huodongId = id
			break
		end
	end
	if yyhuodongs[huodongId] and yyhuodongs[huodongId].info then
		local myBossTimes = yyhuodongs[huodongId].info.huodong_boss_count
		if myBossTimes then
			userDefault.setForeverLocalKey("activityBossCount", myBossTimes)
			return true
		end
	end
end

-- @desc 赛马阶段倒计时
function CityView:setHorseRaceTimer()
	local times = csv.cross.horse_race.base[1].time
	local today = tonumber(time.getTodayStr())
	-- 5:00 , 11:57, 13:00, 19:57
	local mins = 60 * 3
	local timeData = {times[1] * 3600, times[2]* 3600- mins, times[3] * 3600, times[4] * 3600 - mins}
	timeData[#timeData + 1] = timeData[1] + 86400
	local currTime = time.getNowDate()
	local currSec = currTime.hour * 3600 + currTime.min*60 + currTime.sec
	local delta = 1
	for i = 1, #timeData do
		if timeData[i] > currSec then
			delta = timeData[i] - currSec + 1
			break
		end
	end
	performWithDelay(self, function()
		self:onReFreshRedHint()
	end, delta)
end

return function(cls)
	for k, v in pairs(CityView) do
		cls[k] = v
	end
end