--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- GameProtocol
-- 处理c->s的请求
--


local GameProtocol = class("GameProtocol")

local null_data = {}

local function showCheatError(cb)
	return cb(nil, {err = gLanguageCsv.cheat_error})
end

local function postDisableWordCheck(msg, msgType, cb)
	if DISABLE_WORD_CHECK_URL == nil then
		return cb({ret = true}, nil)
	end

	local accountID = stringz.bintohex(gGameModel.role:read("account_id"))
	local roleID = stringz.bintohex(gGameModel.role:read("id"))
	local level = gGameModel.role:read("level")
	local vip = gGameModel.role:read("vip_level")
	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
	local reqUrl = string.format("%s?account=%s&server=%s&role=%s&type=%s&level=%d&vip=%d", DISABLE_WORD_CHECK_URL, accountID, gameKey, roleID, msgType, level, vip)

	-- it will timeout if http service down
	gGameApp.net:sendHttpRequest("POST", reqUrl, msg, cc.XMLHTTPREQUEST_RESPONSE_STRING, function(xhr)
		-- print('postDisableWordCheck', xhr.status, xhr.response)
		if xhr.status == 200 and #xhr.response > 0 then
			local t = json.decode(xhr.response)
			if not t.ret then
				printWarn('%s disabled check by http', msg)
				if t.ban then
					printWarn('account disabled')
					gGameUI:onBan()
				end
				return cb(nil, {err = "msgInvalid"})
			end
		end
		return cb({ret = true}, nil)
	end)
end

function GameProtocol:ctor(game)
	self.game = game
	self.net = game.net
end

function GameProtocol:login(url, cb, userName)
	-- userName = 'tc_2854956' --me
	return self.net:doLogin(userName, cb)
end

GameProtocol["/login/enter_server"] = function(self, url, cb, server)
	local userType, userAge = sdk.getUserTypeAndIdentity()
	server.age = userAge
	return self.net:sendPacket(url, server, cb)
end

GameProtocol["/game/login"] = function(self, url, cb)
	local data = {
		channel = APP_CHANNEL,
		language = LOCAL_LANGUAGE,
		tag = APP_TAG,
	}
	return self.net:sendPacket(url, data, function(ret, err)
		if err == nil then
			-- 告知login可以清理本次登录记录
			self.net:sendPacket("/login/ok", null_data, nil, function()
				self.net:doLoginEnd()
				self.game:onLoginOK()
			end)
			-- TODO: test
			-- self.net:sendPacket("/game/ok", null_data)
			-- self.net:sendPacket("/game/chat", {msg="hello,test"})
		end
		return cb(ret, err)
	end)
end

GameProtocol["/game/sync"] = function(self, url, cb)
	return self.net:sendPacket(url, null_data, cb)
end

-- 内容开发作弊请求
GameProtocol["/game/cheat"] = function(self, url, cb, msg)
	local data={msg = msg}
	return self.net:sendPacket(url, data, cb)
end

-- 开始战斗
GameProtocol["/game/start_gate"] = function(self, url, cb, gateID)
	local data={gateID = gateID}
	return self.net:sendPacket(url, data, cb)
end

-- 结束战斗
GameProtocol["/game/end_gate"] = function(self, url, cb, battleID, gateID, result, star)
	local data={battleID = battleID, gateID = gateID, result = result, star = star}
	return self.net:sendPacket(url, data, cb)
end

-- 卡牌进化
GameProtocol["/game/card/develop"] = function(self, url, cb, cardID, branch)
	local data={cardID = cardID, branch = branch}
	return self.net:sendPacket(url, data, cb)
end

-- 卡牌切换分支
GameProtocol["/game/card/switch/branch"] = function(self, url, cb, cardID, branch)
	local data={cardID = cardID, branch = branch}
	return self.net:sendPacket(url, data, cb)
end

-- 获取 卡牌强化界面 显示数据
GameProtocol["/game/card/show/advance"] = function(self, url, cb, cardID)
	local data={cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- 对卡牌使用经验药水
GameProtocol["/game/card/exp/use_item"] = function(self, url, cb, cardID, itemID, itemCount)
	if itemCount and itemCount < 0 then
		return showCheatError(cb)
	end
	local data={cardID = cardID, itemID = itemID, itemCount = itemCount}
	return self.net:sendPacket(url, data, cb)
end

-- 对卡牌使用经验药水
GameProtocol["/game/card/exp/use_items"] = function(self, url, cb, cardID, items)
	local data={cardID = cardID, items = items}
	return self.net:sendPacket(url, data, cb)
end

-- 对卡牌使用性格道具
GameProtocol["/game/card/character/use_items"] = function(self, url, cb, cardID, itemID)
	local data={cardID = cardID, itemID = itemID}
	return self.net:sendPacket(url, data, cb)
end

-- 卡牌进阶
GameProtocol["/game/card/advance"] = function(self, url, cb, cardID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={cardID = cardID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 卡牌技能升级
GameProtocol["/game/card/skill/level/up"] = function(self, url, cb, cardID, skillID, addLevel)
	local data={cardID = cardID, skillID = skillID, addLevel = addLevel}
	return self.net:sendPacket(url, data, cb)
end

-- 购买技能点数
GameProtocol["/game/role/skill/point/buy"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 装备进阶
GameProtocol["/game/equip/advance"] = function(self, url, cb, cardID, equipPos)
	local data={cardID = cardID, equipPos = equipPos}
	return self.net:sendPacket(url, data, cb)
end

-- 装备强化
GameProtocol["/game/equip/strength"] = function(self, url, cb, cardID, equipPos, upLevel, oneKey)
	local data={cardID = cardID, equipPos = equipPos, upLevel = upLevel, oneKey = oneKey}
	return self.net:sendPacket(url, data, cb)
end

-- 装备经验强化
GameProtocol["/game/equip/strength/exp"] = function(self, url, cb, cardID, equipPos, costItemIDs, upLevel, oneKey)
	local data={cardID = cardID, equipPos = equipPos, costItemIDs = costItemIDs, upLevel = upLevel, oneKey = oneKey}
	return self.net:sendPacket(url, data, cb)
end

-- 装备升星
GameProtocol["/game/equip/star"] = function(self, url, cb, cardID, equipPos)
	local data={cardID = cardID, equipPos = equipPos}
	return self.net:sendPacket(url, data, cb)
end

-- 装备降星
GameProtocol["/game/equip/star/drop"] = function(self, url, cb, cardID, equipPos)
	local data={cardID = cardID, equipPos = equipPos}
	return self.net:sendPacket(url, data, cb)
end

-- 装备觉醒
GameProtocol["/game/equip/awake"] = function(self, url, cb, cardID, equipPos)
	local data={cardID = cardID, equipPos = equipPos}
	return self.net:sendPacket(url, data, cb)
end

-- 装备觉醒降阶
GameProtocol["/game/equip/awake/drop"] = function(self, url, cb, cardID, equipPos)
	local data={cardID = cardID, equipPos = equipPos}
	return self.net:sendPacket(url, data, cb)
end

-- 出售道具
GameProtocol["/game/role/item/sell"] = function(self, url, cb, itemsD)
	local data={itemsD = itemsD}
	return self.net:sendPacket(url, data, cb)
end

-- 使用体力药水
GameProtocol["/game/role/stamina/use_item"] = function(self, url, cb, itemID, itemCount)
	if itemCount and itemCount < 0 then
		return showCheatError(cb)
	end
	local data={itemID = itemID, itemCount = itemCount}
	return self.net:sendPacket(url, data, cb)
end

-- 使用道具（礼包类）
GameProtocol["/game/role/item/use"] = function(self, url, cb, itemsD)
	local data={itemsD = itemsD}
	return self.net:sendPacket(url, data, cb)
end

-- 出售碎片
GameProtocol["/game/role/frag/sell_many"] = function(self, url, cb, fragsD)
	local data={fragsD = fragsD}
	return self.net:sendPacket(url, data, cb)
end

-- 碎片合成
GameProtocol["/game/role/frag/comb"] = function(self, url, cb, fragID)
	local data={fragID = fragID}
	return self.net:sendPacket(url, data, cb)
end

-- 领取关卡星级奖励
GameProtocol["/game/role/map/star_award"] = function(self, url, cb, mapID, awardLevel)
	local data={mapID = mapID, awardLevel = awardLevel - 1}
	return self.net:sendPacket(url, data, cb)
end

-- 领取活跃度节点奖励
GameProtocol["/game/role/liveness/stageaward"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 领取日常任务奖励
GameProtocol["/game/role/daily_task/gain"] = function(self, url, cb, taskID)
	local data={taskID = taskID}
	return self.net:sendPacket(url, data, cb)
end

-- 一键领取所有日常任务奖励
GameProtocol["/game/role/daily_task/allgain"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 领取主线任务奖励
GameProtocol["/game/role/main_task/gain"] = function(self, url, cb, taskID)
	local data={taskID = taskID}
	return self.net:sendPacket(url, data, cb)
end

-- needRefresh 0: 默认; 1: 表示强制刷新(换一批)
GameProtocol["/game/pw/battle/get"] = function(self, url, cb, needRefresh)
	local data={needRefresh = needRefresh or 0}
	return self.net:sendPacket(url, data, cb)
end

-- 排位赛开始战斗
GameProtocol["/game/pw/battle/start"] = function(self, url, cb, myRank, battleRank, enemyRoleID, enemyRecordID)
	local data={myRank = myRank, battleRank = battleRank, enemyRoleID = enemyRoleID, enemyRecordID = enemyRecordID}
	return self.net:sendPacket(url, data, cb)
end

-- @param result 胜利 win 失败 fail 退出 exit
GameProtocol["/game/pw/battle/end"] = function(self, url, cb, rank, result)
	local data={rank = rank, result = result}
	return self.net:sendPacket(url, data, cb)
end

-- 获取排位赛录像数据
GameProtocol["/game/pw/playrecord/get"] = function(self, url, cb, recordID)
	local data={recordID = recordID}
	return self.net:sendPacket(url, data, cb)
end

-- 竞技场积分商店购买
GameProtocol["/game/pw/shop/buy"] = function(self, url, cb, csvID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={csvID = csvID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 领取竞技场排名奖励
GameProtocol["/game/pw/battle/rank/award"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 领取竞技场积分奖励
GameProtocol["/game/pw/battle/point/award"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 竞技场一键挑战
GameProtocol["/game/pw/battle/onekey"] = function(self, url, cb, myRank, battleRank, enemyRoleID)
	local data={myRank = myRank, battleRank = battleRank, enemyRoleID = enemyRoleID}
	return self.net:sendPacket(url, data, cb)
end

-- 竞技场选择展示卡牌
GameProtocol["/game/pw/display"] = function(self, url, cb, card_id)
	local data={card_id=card_id}
	return self.net:sendPacket(url, data, cb)
end

-- 排位赛布阵 cards-攻击阵容, defenceCards 防御阵容，若传nil，则不进行相应项数据保存
GameProtocol["/game/pw/battle/deploy"] = function(self, url, cb, cards, defenceCards)
	local data={cards=cards, defenceCards=defenceCards}
	return self.net:sendPacket(url, data, cb)
end

-- 竞技场查看玩家信息
GameProtocol["/game/pw/role/info"] = function(self, url, cb, recordID)
	local data={recordID=recordID}
	return self.net:sendPacket(url, data, cb)
end

-- 竞技场排名查看
GameProtocol["/game/pw/rank"] = function(self, url, cb, offest, size)
	local data={offest=offest, size=size}
	return self.net:sendPacket(url, data, cb)
end

-- 'free_gold1'金币免费单抽
GameProtocol["/game/lottery/card/draw"] = function(self, url, cb, drawType)
	local data={drawType = drawType}
	return self.net:sendPacket(url, data, cb)
end

-- 'free1'免费单抽
GameProtocol["/game/lottery/equip/draw"] = function(self, url, cb, drawType)
	local data={drawType = drawType}
	return self.net:sendPacket(url, data, cb)
end

-- 限时神兽
GameProtocol["/game/yy/limit/box/get"] = function(self, url, cb, yyID)
	local data={yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 限时神兽抽卡
GameProtocol["/game/yy/limit/box/draw"] = function(self, url, cb, yyID, drawType)
	local data={yyID = yyID, drawType = drawType}
	return self.net:sendPacket(url, data, cb)
end

-- 限时神兽积分
GameProtocol["/game/yy/limit/box/point"] = function(self, url, cb, yyID, csvID)
	local data={yyID = yyID, csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 购买排位赛次数
GameProtocol["/game/pw/battle/buy"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 竞技挑战券道具增加排位赛次数
GameProtocol["/game/pw/battle/item/use"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 购买体力
GameProtocol["/game/role/stamina/buy"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 购买重置英雄关卡
GameProtocol["/game/role/hero_gate/buy"] = function(self, url, cb, gateID)
	local data={gateID = gateID}
	return self.net:sendPacket(url, data, cb)
end

-- 充值
GameProtocol["/game/role/recharge/buy"] = function(self, url, cb, rechargeID, yyID, csvID)
	local data={rechargeID = rechargeID, yyID = yyID, csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 获取阅读邮件内容
GameProtocol["/game/role/mail/get"] = function(self, url, cb, mailID)
	local data={mailID = mailID}
	return self.net:sendPacket(url, data, cb)
end

-- 领取邮件奖励或者已阅读邮件
GameProtocol["/game/role/mail/read"] = function(self, url, cb, mailID)
	local data={mailID = mailID}
	return self.net:sendPacket(url, data, cb)
end

-- 打开活动界面
GameProtocol["/game/huodong/show"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 开始活动
GameProtocol["/game/huodong/start"] = function(self, url, cb, battleCardIDs, huodongID, gateID)
	local data={battleCardIDs = battleCardIDs, huodongID = huodongID, gateID = gateID}
	return self.net:sendPacket(url, data, cb)
end

-- 结束活动
GameProtocol["/game/huodong/end"] = function(self, url, cb, battleID, gateID, result, star, percent, score)
	local data={battleID = battleID, gateID = gateID, result = result, star = star, percent = percent, score = score}
	return self.net:sendPacket(url, data, cb)
end

-- 签到
GameProtocol["/game/role/sign_in"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 累积签到 领取奖励
GameProtocol["/game/role/sign_in/total_award"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 购买排位赛冷却时间
GameProtocol["/game/pw/battle/cd/buy"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 炼金
GameProtocol["/game/role/lianjin"] = function(self, url, cb, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 炼金每日累计奖励
GameProtocol["/game/role/lianjin/total_award"] = function(self, url, cb, times)
	local data={times = times}
	return self.net:sendPacket(url, data, cb)
end

-- 新手改名,选择形象
GameProtocol["/game/role/newbie/init"] = function(self, url, cb, guideID, name, figure)
	local data={guideID = guideID, name = name, figure = figure}
	return self.net:sendPacket(url, data, cb)
end

-- 新手选择卡牌
GameProtocol["/game/role/newbie/card/choose"] = function(self, url, cb,  guideID, cardID)
	local data={guideID = guideID, cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- 新手引导
GameProtocol["/game/role/guide/newbie"] = function(self, url, cb, guideID)
	local data={guideID = guideID}
	return self.net:sendPacket(url, data, cb)
end

-- 新手引导默默塞奖励
GameProtocol["/game/role/guide/newbie/award"] = function(self, url, cb, guideCsvID)
	local data={guideCsvID = guideCsvID}
	return self.net:sendPacket(url, data, cb)
end

-- 扫荡
GameProtocol["/game/saodang"] = function(self, url, cb, gateID, times, itemID, targetNum)
	local data={gateID = gateID, times = times, itemID = itemID, targetNum = targetNum}
	return self.net:sendPacket(url, data, cb)
end

-- 快速扫荡扫荡
GameProtocol["/game/saodang/batch"] = function(self, url, cb, gateIDs)
	local data={gateIDs = gateIDs}
	return self.net:sendPacket(url, data, cb)
end

-- slots = {0,1,5,-1,-1} 0表示未配置,-1表示未解锁,>0表示Rune CSV ID
GameProtocol["/game/role/rune_slots/set"] = function(self, url, cb, slots)
	local data={slots = slots}
	return self.net:sendPacket(url, data, cb)
end

-- 获取激活的活动
GameProtocol["/game/yy/active/get"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 获取战力排行
GameProtocol["/game/yy/fightrank/get"] = function(self, url, cb, yyID)
	local data={yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 砸金蛋
GameProtocol["/game/yy/breakegg/break"] = function(self, url, cb, yyID, pos)
	local data={yyID = yyID, pos = pos}
	return self.net:sendPacket(url, data, cb)
end

-- 获取活动奖励
GameProtocol["/game/yy/award/get"] = function(self, url, cb, yyID, csvID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={yyID = yyID, csvID = csvID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 一键获取活动奖励
GameProtocol["/game/yy/award/get/onekey"] = function(self, url, cb, yyID)
	local data={yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 'limit_free1'免费单抽
-- 'limit_rmb5'魂匣钻石五连抽
GameProtocol["/game/yy/award/draw"] = function(self, url, cb, yyID, drawType)
	local data={yyID = yyID, drawType = drawType}
	return self.net:sendPacket(url, data, cb)
end

-- limit up符石: 单抽 limit_up_gem_rmb1、十连 limit_up_gem_rmb10、免费单抽 limit_up_gem_free1
GameProtocol["/game/yy/limit/gem/draw"] = function(self, url, cb, yyID, drawType, decompose)
	local data={yyID = yyID, drawType = drawType, decompose = decompose}
	return self.net:sendPacket(url, data, cb)
end

-- 获取开服活动全目标奖励
GameProtocol["/game/yy/targets/award/get"] = function(self, url, cb, yyID)
	local data={yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 角色重命名
GameProtocol["/game/role/rename"] = function(self, url, cb, name)
	return postDisableWordCheck(name, "role_rename", function(ret, err)
		if err then
			return cb(nil, err)
		end

		local data = {name = name}
		return self.net:sendPacket(url, data, cb)
	end)
end

-- 角色个性签名
GameProtocol["/game/role/personal/sign"] = function(self, url, cb, sign)
	return postDisableWordCheck(sign, "personal_sign", function(ret, err)
		if err then
			return cb(nil, err)
		end

		local data = {sign = sign}
		return self.net:sendPacket(url, data, cb)
	end)
end

-- 角色展示更换 display {logo=1, frame=1}
GameProtocol["/game/role/display"] = function(self, url, cb, display)
	local data={display = display}
	return self.net:sendPacket(url, data, cb)
end

-- 更换头像
GameProtocol["/game/role/logo"] = function(self, url, cb, logo)
	local data={logo = logo}
	return self.net:sendPacket(url, data, cb)
end

-- 更换头像框
GameProtocol["/game/role/frame"] = function(self, url, cb, frame)
	local data={frame = frame}
	return self.net:sendPacket(url, data, cb)
end

-- 更换形象
GameProtocol["/game/role/figure"] = function(self, url, cb, figure)
	local data={figure = figure}
	return self.net:sendPacket(url, data, cb)
end

-- 激活形象
GameProtocol["/game/role/figure_active"] = function(self, url, cb, figureID)
	local data={figureID = figureID}
	return self.net:sendPacket(url, data, cb)
end

-- 更换形象技能
GameProtocol["/game/role/figure/skill/switch"] = function(self, url, cb, figureID, skillFigureID, idx)
	local data={figureID = figureID, skillFigureID = skillFigureID, idx = idx}
	return self.net:sendPacket(url, data, cb)
end

-- 形象技能栏位解锁
GameProtocol["/game/role/figure/skill/unlock"] = function(self, url, cb, idx)
	local data={idx = idx}
	return self.net:sendPacket(url, data, cb)
end

-- 图鉴突破
GameProtocol["/game/role/pokedex_advance"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- type: fight union pokedex endless huodong_N random_tower
GameProtocol["/game/rank"] = function(self, url, cb, type, offest, size)
	local data={type = type, offest = offest, size = size}
	return self.net:sendPacket(url, data, cb)
end

-- 领取礼包
GameProtocol["/game/gift"] = function(self, url, cb, key)
	local data={key = key}
	return self.net:sendPacket(url, data, cb)
end

-- 获取公会信息
GameProtocol["/game/union/get"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 创建公会
GameProtocol["/game/union/create"] = function(self, url, cb, name, logo, joinType)
	local data={name = name, logo = logo, joinType = joinType}
	return self.net:sendPacket(url, data, cb)
end

-- 公会改名
GameProtocol["/game/union/rename"] = function(self, url, cb, name)
	return postDisableWordCheck(name, "union_rename", function(ret, err)
		if err then
			return cb(nil, err)
		end

		local data = {name = name}
		return self.net:sendPacket(url, data, cb)
	end)
end

-- 公会发邮件
GameProtocol["/game/union/send/mail"] = function(self, url, cb, content)
	return postDisableWordCheck(content, "union_mail", function(ret, err)
		if err then
			return cb(nil, err)
		end

		local data = {content = content}
		return self.net:sendPacket(url, data, cb)
	end)
end

-- 公会快速加入
GameProtocol["/game/union/fast/join"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 公会招募
GameProtocol["/game/union/joinup"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 公会列表(以日捐献排行)
GameProtocol["/game/union/list"] = function(self, url, cb, offest, size)
	local data={offest = offest, size = size}
	return self.net:sendPacket(url, data, cb)
end

-- 公会排行(以总捐献排行)
GameProtocol["/game/union/rank"] = function(self, url, cb, offest, size)
	local data={offest = offest, size = size}
	return self.net:sendPacket(url, data, cb)
end

-- 申请加入公会
GameProtocol["/game/union/join"] = function(self, url, cb, unionID)
	local data={unionID = unionID}
	return self.net:sendPacket(url, data, cb)
end

-- 取消加入公会
GameProtocol["/game/union/join/cancel"] = function(self, url, cb, unionID)
	local data={unionID = unionID}
	return self.net:sendPacket(url, data, cb)
end

-- 会长或副会长批准入会
GameProtocol["/game/union/join/accept"] = function(self, url, cb, roleID)
	local data={roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 会长或副会长拒绝入会
GameProtocol["/game/union/join/refuse"] = function(self, url, cb, roleID)
	local data={roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 会长或副会长拒绝所有入会
GameProtocol["/game/union/join/refuse/all"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 玩家退会
GameProtocol["/game/union/quit"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 会长或副会长踢人
GameProtocol["/game/union/kick"] = function(self, url, cb, roleID)
	local data={roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 会长提拔会员为副会长
GameProtocol["/game/union/chairman/promote"] = function(self, url, cb, roleID)
	local data={roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 会长将副会长降级为成员
GameProtocol["/game/union/chairman/demote"] = function(self, url, cb, roleID)
	local data={roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 会长转让
GameProtocol["/game/union/chairman/swap"] = function(self, url, cb, roleID)
	local data={roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 公会解散
GameProtocol["/game/union/destroy"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 公会检索
GameProtocol["/game/union/find"] = function(self, url, cb, unionID)
	local data={unionID = unionID}
	return self.net:sendPacket(url, data, cb)
end

-- 公告不能多于20个字
GameProtocol["/game/union/intro/modify"] = function(self, url, cb, intro)
	return postDisableWordCheck(intro, "union_intro_modify", function(ret, err)
		if err then
			return cb(nil, err)
		end

		local data = {intro = intro}
		return self.net:sendPacket(url, data, cb)
	end)
end

-- 公会修改加入等级条件
GameProtocol["/game/union/join/modify"] = function(self, url, cb, joinType, joinLevel, joinDesc)
	local data={joinType = joinType, joinLevel = joinLevel, joinDesc = joinDesc}
	return self.net:sendPacket(url, data, cb)
end

-- 公会修改logo
GameProtocol["/game/union/logo/modify"] = function(self, url, cb, logo)
	local data = {logo=logo}
	return self.net:sendPacket(url, data, cb)
end

-- 公会红包信息
GameProtocol["/game/union/redpacket/info"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 公会发红包 idx从0开始
GameProtocol["/game/union/redpacket/send"] = function(self, url, cb, idx, csvID)
	local data={idx=idx, csvID=csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 公会抢红包
GameProtocol["/game/union/redpacket/rob"] = function(self, url, cb, packetDBID)
	local data={packetDBID = packetDBID}
	return self.net:sendPacket(url, data, cb)
end

-- 公会红包detail 用于排行榜
GameProtocol["/game/union/redpacket/detail"] = function(self, url, cb, packetDBID)
	local data={packetDBID = packetDBID}
	return self.net:sendPacket(url, data, cb)
end

-- 获取公会副本
GameProtocol["/game/union/fuben/get"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 领取公会副本奖励
GameProtocol["/game/union/fuben/award"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 获取公会副本进度数据 csvID为nil，即全副本数据
GameProtocol["/game/union/fuben/progress"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 挑战公会副本
GameProtocol["/game/union/fuben/start"] = function(self, url, cb, csvID, gateID)
	local data={csvID = csvID, gateID = gateID}
	return self.net:sendPacket(url, data, cb)
end

-- hpMax下取整数，保证服务器判断不会受精度误差干扰
GameProtocol["/game/union/fuben/end"] = function(self, url, cb, battleID, gateID, result, damage, hpMax)
	local data={battleID = battleID, gateID = gateID, result = result, damage = math.floor(damage), hpMax = math.floor(hpMax)}
	return self.net:sendPacket(url, data, cb)
end

-- 获取固定商店数据
GameProtocol["/game/fixshop/get"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 固定商店数据购买
GameProtocol["/game/fixshop/buy"] = function(self, url, cb, idx, shopID, itemID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={idx = idx, shopID = shopID, itemID = itemID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 刷新固定商店 （进货券刷新itemRefresh传True，钻石刷新可不传）
GameProtocol["/game/fixshop/refresh"] = function(self, url, cb, itemRefresh)
	local data={itemRefresh = itemRefresh}
	return self.net:sendPacket(url, data, cb)
end

-- 卡牌升星
GameProtocol["/game/card/star"] = function(self, url, cb, cardID, costCardIDs)
	local data={cardID = cardID, costCardIDs = costCardIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 刷新公会积分商店 （进货券刷新itemRefresh传True，钻石刷新可不传）
GameProtocol["/game/union/shop/refresh"] = function(self, url, cb, itemRefresh)
	local data={itemRefresh = itemRefresh}
	return self.net:sendPacket(url, data, cb)
end

-- 公会积分商店购买
GameProtocol["/game/union/shop/buy"] = function(self, url, cb, idx, shopID, itemID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={idx = idx, shopID = shopID, itemID = itemID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 获取公会积分商店数据
GameProtocol["/game/union/shop/get"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 世界boss主界面
GameProtocol["/game/yy/world/boss/main"] = function(self, url, cb, yyID)
	local data={yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 开始世界boss活动
GameProtocol["/game/yy/world/boss/start"] = function(self, url, cb, battleCardIDs, yyID)
	local data={battleCardIDs = battleCardIDs, yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 结束世界boss活动
GameProtocol["/game/yy/world/boss/end"] = function(self, url, cb, battleID, yyID, damage)
	local data={battleID = battleID, yyID = yyID, damage = damage}
	return self.net:sendPacket(url, data, cb)
end

-- 购买世界boss挑战次数
GameProtocol["/game/yy/world/boss/buy"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 世界boss排名
GameProtocol["/game/yy/world/boss/rank"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 符石置换
GameProtocol["/game/yy/gem/exchange"] = function(self, url, cb, yyID, gemIDs, flag)
	local data={yyID = yyID, gemIDs = gemIDs, flag = flag}
	return self.net:sendPacket(url, data, cb)
end

-- 活动扫荡
GameProtocol["/game/huodong/saodang"] = function(self, url, cb, huodongID, gateID, times)
	local data={huodongID = huodongID, gateID = gateID, times = times}
	return self.net:sendPacket(url, data, cb)
end

-- 保存布阵位置阵容
GameProtocol["/game/battle/card"] = function(self, url, cb, battleCardIDs)
	local data={battleCardIDs = battleCardIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 保存活动布阵位置阵容
GameProtocol["/game/huodong/card"] = function(self, url, cb, huodongID, battleCardIDs)
	local data={huodongID = huodongID, battleCardIDs = battleCardIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 领取关卡奖励
GameProtocol["/game/role/gate/award"] = function(self, url, cb, gateID, type)
	local data={gateID = gateID, type = type}
	return self.net:sendPacket(url, data, cb)
end

-- 申请好友请求
GameProtocol["/game/society/friend/askfor"] = function(self, url, cb, roleIDs)
	local data={roleIDs = roleIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 接受好友请求
GameProtocol["/game/society/friend/accept"] = function(self, url, cb, roleID, auto)
	local data={roleID = roleID, auto = auto}
	return self.net:sendPacket(url, data, cb)
end

-- 拒绝好友请求
GameProtocol["/game/society/friend/reject"] = function(self, url, cb, roleID, auto)
	local data={roleID = roleID, auto = auto}
	return self.net:sendPacket(url, data, cb)
end

-- 删除好友
GameProtocol["/game/society/friend/delete"] = function(self, url, cb, roleID)
	local data={roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 赠送好友体力
GameProtocol["/game/society/friend/stamina/send"] = function(self, url, cb, roleID, auto)
	local data={roleID = roleID, auto = auto}
	return self.net:sendPacket(url, data, cb)
end

-- 领取好友体力
GameProtocol["/game/society/friend/stamina/recv"] = function(self, url, cb, roleID, auto)
	local data={roleID = roleID, auto = auto}
	return self.net:sendPacket(url, data, cb)
end

-- 换一批申请列表
GameProtocol["/game/society/friend/list"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 在线好友列表
GameProtocol["/game/society/friend/online/list"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 搜索申请好友
GameProtocol["/game/society/friend/search"] = function(self, url, cb, roleID, roleName, roleIDs, uid)
	local data={roleID = roleID, roleName = roleName, roleIDs = roleIDs, uid=uid}
	return self.net:sendPacket(url, data, cb)
end

-- 好友挑战
GameProtocol["/game/society/friend/fight"] = function(self, url, cb, roleID, recordID)
	local data={roleID = roleID, recordID = recordID}
	return self.net:sendPacket(url, data, cb)
end

-- 加入黑名单
GameProtocol["/game/society/blacklist/add"] = function(self, url, cb, roleID)
	local data={roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 移除黑名单
GameProtocol["/game/society/blacklist/remove"] = function(self, url, cb, roleID)
	local data={roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 全部领取或阅读邮件
GameProtocol["/game/role/mail/read/all"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 购买vip礼包
GameProtocol["/game/role/vipgift/buy"] = function(self, url, cb, vipLevel)
	local data={vipLevel = vipLevel}
	return self.net:sendPacket(url, data, cb)
end

-- 购买道具
GameProtocol["/game/buy_item"] = function(self, url, cb, itemID, itemCount)
	if itemCount and itemCount < 0 then
		return showCheatError(cb)
	end
	local data={itemID = itemID, itemCount = itemCount}
	return self.net:sendPacket(url, data, cb)
end

-- 购买经验药水
GameProtocol["/game/exp/buy_item"] = function(self, url, cb, itemID, itemCount)
	if itemCount and itemCount < 0 then
		return showCheatError(cb)
	end
	local data={itemID = itemID, itemCount = itemCount}
	return self.net:sendPacket(url, data, cb)
end

-- 购买精灵球
GameProtocol["/game/ball/buy_item"] = function(self, url, cb, itemID, itemCount)
	if itemCount and itemCount < 0 then
		return showCheatError(cb)
	end
	local data={itemID = itemID, itemCount = itemCount}
	return self.net:sendPacket(url, data, cb)
end

-- 天赋升级 返回数据不包含卡牌数据的刷新
GameProtocol["/game/talent/levelup_ready"] = function(self, url, cb, talentID)
	local data={talentID = talentID}
	return self.net:sendPacket(url, data, cb)
end

-- 天赋刷新卡牌所有属性
GameProtocol["/game/talent/levelup_end"] = function(self, url, cb, talentIDs)
	local data={talentIDs = talentIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 天赋重置 treeID不传时重置全部天赋页
GameProtocol["/game/talent/reset"] = function(self, url, cb, treeID)
	local data={}
	if treeID then
		data={treeID = treeID}
	end
	return self.net:sendPacket(url, data, cb)
end

-- 对卡牌使用好感度经验药水 {[151]=10,[152]=5}
GameProtocol["/game/card/feel/use_items"] = function(self, url, cb, markID, items)
	local data={markID = markID, items = items}
	return self.net:sendPacket(url, data, cb)
end

-- 对卡牌好感度一键送礼 flag为true的话，表示只使用通用礼物
GameProtocol["/game/card/feel/tomax"] = function(self, url, cb, markID, flag)
	local data={markID = markID, flag = flag}
	return self.net:sendPacket(url, data, cb)
end

-- 已经是通用接口
GameProtocol["/game/role_info"] = function(self, url, cb, roleID)
	local data={roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 已经是通用接口
GameProtocol["/game/card_info"] = function(self, url, cb, cardID)
	local data={cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- 卡牌重生
GameProtocol["/game/card/rebirth"] = function(self, url, cb, cardID)
	local data={cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- 卡牌分解
GameProtocol["/game/card/decompose"] = function(self, url, cb, cardIDs)
	local data={cardIDs = cardIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 万能碎片转换  (fragID 不传为 普通万能碎片 ==> 神兽万能碎片，传为 万能碎片 ==> 精灵碎片)
GameProtocol["/game/role/acitem/switch"] = function(self, url, cb, count, fragID)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={fragID = fragID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 公会贡献 任务领取
GameProtocol["/game/union/contrib/task"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- idx 是union.contrib里的csv id
GameProtocol["/game/union/contrib"] = function(self, url, cb, idx)
	local data={idx = idx}
	return self.net:sendPacket(url, data, cb)
end

-- idx 指训练所位置，下标从1开始
GameProtocol["/game/union/training/open"] = function(self, url, cb, idx)
	local data={idx = idx}
	return self.net:sendPacket(url, data, cb)
end

-- idx 指训练所位置，下标从1开始
GameProtocol["/game/union/training/start"] = function(self, url, cb, idx, cardID)
	local data={idx = idx, cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- idx 指训练所位置，下标从1开始
GameProtocol["/game/union/training/replace"] = function(self, url, cb, idx, cardID)
	local data={idx = idx, cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- idx 指训练所位置，下标从1开始
GameProtocol["/game/union/training/speedup"] = function(self, url, cb, roleID, idx)
	local data={roleID = roleID, idx = idx}
	return self.net:sendPacket(url, data, cb)
end

-- 公会训练所社团营地列表
GameProtocol["/game/union/training/list"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 公会训练所查看他人营地
GameProtocol["/game/union/training/see"] = function(self, url, cb, roleID)
	local data={roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 获取神秘商店数据
GameProtocol["/game/mystery/get"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 刷新神秘商店
GameProtocol["/game/mystery/refresh"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 神秘商店购买
GameProtocol["/game/mystery/buy"] = function(self, url, cb, idx, shopID, itemID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={idx = idx, shopID = shopID, itemID = itemID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 等级基金购买
GameProtocol["/game/yy/levelfund/buy"] = function(self, url, cb, yyID)
	local data={yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 获取元素实验列表
GameProtocol["/game/clone/get"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 快速加入房间
GameProtocol["/game/clone/room/join/fast"] = function(self, url, cb, natureID)
	local data={natureID = natureID}
	return self.net:sendPacket(url, data, cb)
end

-- 加入房间
GameProtocol["/game/clone/room/join"] = function(self, url, cb, roomID)
	local data={roomID = roomID}
	return self.net:sendPacket(url, data, cb)
end

-- 退出房间
GameProtocol["/game/clone/room/quit"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 房主踢人
GameProtocol["/game/clone/room/kick"] = function(self, url, cb, roleID)
	local data={roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 投票
GameProtocol["/game/clone/room/vote"] = function(self, url, cb, vote)
	local data={vote = vote}
	return self.net:sendPacket(url, data, cb)
end

-- 创建房间
GameProtocol["/game/clone/room/create"] = function(self, url, cb, natureID)
	local data={natureID = natureID}
	return self.net:sendPacket(url, data, cb)
end

-- 快速加入房间
GameProtocol["/game/clone/room/join/fast/enable"] = function(self, url, cb, enable)
	local data={enable = enable}
	return self.net:sendPacket(url, data, cb)
end

-- gateID默认就是5000
GameProtocol["/game/clone/battle/start"] = function(self, url, cb, csvID, battleCardIDs)
	local data={csvID = csvID, battleCardIDs = battleCardIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 结束战斗
GameProtocol["/game/clone/battle/end"] = function(self, url, cb, result)
	local data={result = result}
	return self.net:sendPacket(url, data, cb)
end

-- 部署元素实验上阵卡牌
GameProtocol["/game/clone/battle/deploy"] = function(self, url, cb, cardID)
	local data={cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- 挑战胜利宝箱
GameProtocol["/game/clone/box/draw"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 元素实验战邀请
GameProtocol["/game/clone/invite"] = function(self, url, cb, msgType, friend)
	local data={msgType = msgType, friend = friend}
	return self.net:sendPacket(url, data, cb)
end

-- 元素挑战邀请时的在线好友
GameProtocol["/game/clone/friend/online/list"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 元素挑战进入布阵界面
GameProtocol["/game/clone/battle/deploy/enter"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 元素挑战设置是否需要机器人
GameProtocol["/game/clone/room/robot/enable"] = function(self, url, cb, enable)
	local data={enable = enable}
	return self.net:sendPacket(url, data, cb)
end

-- 补领体力
GameProtocol["/game/role/stamina/regain"] = function(self, url, cb, taskId)
	local data={taskId = taskId}
	return self.net:sendPacket(url, data, cb)
end

-- 1拳皇争霸报名
GameProtocol["/game/craft/signup"] = function(self, url, cb, cards)
	local data={cards = cards}
	return self.net:sendPacket(url, data, cb)
end

-- 进入拳皇争霸功能一定要先请求该接口
GameProtocol["/game/craft/battle/main"] = function(self, url, cb, refresh_time, vsid)
	local data={refresh_time = refresh_time, vsid = vsid}
	return self.net:sendPacket(url, data, cb)
end

-- 5拳皇争霸我的下注
GameProtocol["/game/craft/bet/info"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 6拳皇争霸下注
GameProtocol["/game/craft/bet"] = function(self, url, cb, roleID, gold)
	local data={roleID = roleID, gold = gold}
	return self.net:sendPacket(url, data, cb)
end

-- 7拳皇争霸获取对方参赛信息
GameProtocol["/game/craft/battle/enemy/get"] = function(self, url, cb, roleID, recordID)
	local data={roleID = roleID, recordID = recordID}
	return self.net:sendPacket(url, data, cb)
end

-- 8拳皇争霸挑战部署
GameProtocol["/game/craft/battle/deploy"] = function(self, url, cb, battleCardIDs)
	local data={battleCardIDs = battleCardIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 拳皇争霸获取录像数据
GameProtocol["/game/craft/playrecord/get"] = function(self, url, cb, recordID)
	local data={recordID = recordID}
	return self.net:sendPacket(url, data, cb)
end

-- 拳皇争霸商店兑换
GameProtocol["/game/craft/shop/buy"] = function(self, url, cb, csvID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={csvID = csvID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 'free_gold1'金币免费单抽
GameProtocol["/game/lottery/metal/draw"] = function(self, url, cb, drawType)
	local data={drawType = drawType}
	return self.net:sendPacket(url, data, cb)
end

-- 领取在线礼包
GameProtocol["/game/role/online_gift/award"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 切换头衔
GameProtocol["/game/role/title/switch"] = function(self, url, cb, titleID)
	local data={titleID = titleID}
	return self.net:sendPacket(url, data, cb)
end

-- 使用可选择道具（礼包类）
GameProtocol["/game/role/gift/choose"] = function(self, url, cb, itemID, count, choose, isShowMsg)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={itemID = itemID, count = count, choose = choose, isShowMsg = isShowMsg}
	return self.net:sendPacket(url, data, cb)
end

-- type: free, rmb
GameProtocol["/game/vip/week_gift/award"] = function(self, url, cb, type)
	local data={type = type}
	return self.net:sendPacket(url, data, cb)
end

-- 聊天
GameProtocol["/game/chat"] = function(self, url, cb, msg, msgType, roleID)
	return postDisableWordCheck(msg, msgType, function(ret, err)
		if err then
			return cb(nil, err)
		end

		local data = {msg = msg, msgType = msgType, role = roleID}
		return self.net:sendPacket(url, data, cb)
	end)
end

-- 删除聊天
GameProtocol["/game/chat/del"] = function(self, url, cb, roleID)
	local data = {roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 签到补签
GameProtocol["/game/role/sign_in/buy"] = function(self, url, cb, csvID)
	local data = {csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 签到月累积领取奖励
GameProtocol["/game/role/sign_in/month/total_award"] = function(self, url, cb, csvID)
	local data = {csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 删除已读邮件
GameProtocol["/game/role/mail/delete"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 卡牌重命名
GameProtocol["/game/card/rename"] = function(self, url, cb, cardID, name)
	return postDisableWordCheck(name, "card_rename", function(ret, err)
		if err then
			return cb(nil, err)
		end

		local data = {cardID = cardID, name = name}
		return self.net:sendPacket(url, data, cb)
	end)
end

-- 卡牌锁定切换
GameProtocol["/game/card/locked/switch"] = function(self, url, cb, cardID)
	local data={cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- 溢出经验兑换
GameProtocol["/game/role/overflow_exp_exchange"] = function(self, url, cb, csvID, count)
	local data={csvID = csvID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 卡牌个体值锁定状态切换 (attr 可为 speed, defence, specialDefence, hp, damage, specialDamage)
GameProtocol["/game/card/nvalue/locked/switch"] = function(self, url, cb, cardID, attr)
	local data={cardID = cardID, attr = attr}
	return self.net:sendPacket(url, data, cb)
end

-- 卡牌个体值洗炼
GameProtocol["/game/card/nvalue/recast"] = function(self, url, cb, cardID)
	local data={cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- 精灵背包容量购买
GameProtocol["/game/role/card_capacity/buy"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 运营活动查询购买资格
GameProtocol["/game/yy/award/canbuy"] = function(self, url, cb, yyID, csvID)
	local data={yyID = yyID, csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 战报分享(crossKey跨服专用，非必传)
GameProtocol["/game/battle/share"] = function(self, url, cb, battleID, enemyName, from, crossKey)
	local data={battleID=battleID, enemyName=enemyName, from=from, crossKey=crossKey}
	return self.net:sendPacket(url, data, cb)
end

-- 无限塔关卡战斗开始
GameProtocol["/game/endless/battle/start"] = function(self, url, cb, gateID, cardIDs)
	local data={gateID=gateID, cardIDs=cardIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 无限塔关卡战斗结束
GameProtocol["/game/endless/battle/end"] = function(self, url, cb, battleID, gateID, result, round, actions)
	local data={battleID=battleID, gateID=gateID, result=result, round=round, actions=actions}
	return self.net:sendPacket(url, data, cb)
end

-- 无限塔 扫荡
GameProtocol["/game/endless/saodang"] = function(self, url, cb, gateID)
	local data={gateID=gateID}
	return self.net:sendPacket(url, data, cb)
end

-- 无限塔 重置
GameProtocol["/game/endless/reset"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 无限塔 战报列表
GameProtocol["/game/endless/plays/list"] = function(self, url, cb, gateID)
	local data={gateID=gateID}
	return self.net:sendPacket(url, data, cb)
end

-- 无限塔 战报详情
GameProtocol["/game/endless/play/detail"] = function(self, url, cb, playID)
	local data={playID=playID}
	return self.net:sendPacket(url, data, cb)
end

-- 阵容同步设置 flag should be true or false, key can be arena_defence_cards
GameProtocol["/game/deployment/sync"] = function(self, url, cb, key, flag)
	local data = {key=key, flag=flag}
	return self.net:sendPacket(url, data, cb)
end

-- 努力值 随机培养
GameProtocol["/game/card/effort/train"] = function(self, url, cb, cardID, trainType, trainTime)
	local data={cardID=cardID, trainType=trainType, trainTime=trainTime}
	return self.net:sendPacket(url, data, cb)
end

-- 努力值 培养保存
GameProtocol["/game/card/effort/save"] = function(self, url, cb, cardID, effortIndexs)
	local data={cardID=cardID, effortIndexs=effortIndexs}
	return self.net:sendPacket(url, data, cb)
end

-- 公会修炼中心 修炼
GameProtocol["/game/union/skill"] = function(self, url, cb, skillID)
	local data={skillID=skillID}
	return self.net:sendPacket(url, data, cb)
end

-- 公会每日礼包
GameProtocol["/game/union/daily_gift"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 公会碎片赠予发起
GameProtocol["/game/union/frag/donate/start"] = function(self, url, cb, cardID)
	local data={cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- 公会碎片赠予
GameProtocol["/game/union/frag/donate"] = function(self, url, cb, roleID, fragID)
	local data={roleID = roleID, fragID = fragID}
	return self.net:sendPacket(url, data, cb)
end

-- 公会碎片赠予热心人奖励
GameProtocol["/game/union/frag/donate/award"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 携带道具装备
GameProtocol["/game/helditem/equip"] = function(self, url, cb, cardID, heldItemID, isVice)
	local data={cardID=cardID, heldItemID=heldItemID, vice=isVice}
	return self.net:sendPacket(url, data, cb)
end

-- 携带道具脱下
GameProtocol["/game/helditem/unload"] = function(self, url, cb, heldItemID)
	local data={heldItemID=heldItemID}
	return self.net:sendPacket(url, data, cb)
end

-- 携带道具强化
GameProtocol["/game/helditem/strength"] = function(self, url, cb, csvIDs, heldItemID)
	local data={csvIDs=csvIDs, heldItemID=heldItemID}
	return self.net:sendPacket(url, data, cb)
end

-- 携带道具突破
GameProtocol["/game/helditem/advance"] = function(self, url, cb, heldItemID, costHeldItemIDs, itemsD)
	local data={heldItemID=heldItemID, costHeldItemIDs=costHeldItemIDs, itemsD=itemsD}
	return self.net:sendPacket(url, data, cb)
end

-- 携带道具重生
GameProtocol["/game/helditem/rebirth"] = function(self, url, cb, heldItemID)
	local data={heldItemID=heldItemID}
	return self.net:sendPacket(url, data, cb)
end

-- 训练师等级每日奖励
GameProtocol["/game/trainer/daily/award"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 训练师特权技能提升
GameProtocol["/game/trainer/skill/levelup"] = function(self, url, cb, csvID)
	local data = {csvID=csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 训练师属性技能提升 skills {csvid: levelup}
GameProtocol["/game/trainer/attr_skill/levelup"] = function(self, url, cb, skills)
	local data = {skills=skills}
	return self.net:sendPacket(url, data, cb)
end

-- 训练师属性技能重置
GameProtocol["/game/trainer/attr_skill/reset"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 训练师等级进阶
GameProtocol["/game/trainer/advance"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 精灵继承
GameProtocol["/game/card/property/swap"] = function(self, url, cb, cardID, targetCardID, swapType)
	local data={cardID=cardID, targetCardID=targetCardID, swapType=swapType}
	return self.net:sendPacket(url, data, cb)
end

-- 精灵好感度交换
GameProtocol["/game/card/feel/swap"] = function(self, url, cb, cardID, targetCardID)
	local data={cardID=cardID, targetCardID=targetCardID}
	return self.net:sendPacket(url, data, cb)
end

-- 刷新 派遣任务列表
GameProtocol["/game/dispatch/task/refresh"] = function(self, url, cb, flag)
	local data={flag=flag}
	return self.net:sendPacket(url, data, cb)
end

-- 开始任务派遣
GameProtocol["/game/dispatch/task/begin"] = function(self, url, cb, cardIDs, taskIndex)
	local data={cardIDs=cardIDs, taskIndex=taskIndex-1}
	return self.net:sendPacket(url, data, cb)
end


-- 领取奖励
GameProtocol["/game/dispatch/task/award"] = function(self, url, cb, taskIndex, flag)
	local data={taskIndex=taskIndex-1, flag=flag}
	return self.net:sendPacket(url, data, cb)
end

-- 探险器 组件激活/升级
GameProtocol["/game/explorer/component/strength"] = function(self, url, cb, componentCsvID)
	local data={componentCsvID=componentCsvID}
	return self.net:sendPacket(url, data, cb)
end

-- 探险器 激活/进阶
GameProtocol["/game/explorer/advance"] = function(self, url, cb, explorerCsvID)
	local data={explorerCsvID=explorerCsvID}
	return self.net:sendPacket(url, data, cb)
end

-- 探险器 组件分解 {itemID: count}
GameProtocol["/game/explorer/component/decompose"] = function(self, url, cb, componentItems)
	local data={componentItems=componentItems}
	return self.net:sendPacket(url, data, cb)
end

-- 刷新寻宝商店商店 （进货券刷新itemRefresh传True，钻石刷新可不传）
GameProtocol["/game/explorer/shop/refresh"] = function(self, url, cb, itemRefresh)
	local data={itemRefresh = itemRefresh}
	return self.net:sendPacket(url, data, cb)
end

-- 寻宝商店商店购买
GameProtocol["/game/explorer/shop/buy"] = function(self, url, cb, idx, shopID, itemID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={idx = idx, shopID = shopID, itemID = itemID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 获取寻宝商店商店数据
GameProtocol["/game/explorer/shop/get"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 主城彩蛋奖励领取
GameProtocol["/game/role/city/sprite/gift"] = function(self, url, cb, csvID)
	local data = {csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 主城百变怪/谜拟Q触发 type: 1-百变怪; 2-谜拟Q
GameProtocol["/game/role/city/sprite/active"] = function(self, url, cb, type)
	local data = {type = type}
	return self.net:sendPacket(url, data, cb)
end

-- 探险器 寻宝（抽道具）
GameProtocol["/game/lottery/item/draw"] = function(self, url, cb, drawType)
	local data={drawType=drawType}
	return self.net:sendPacket(url, data, cb)
end

-- 刷新碎片商店商店 （进货券刷新itemRefresh传True，钻石刷新可不传）
GameProtocol["/game/frag/shop/refresh"] = function(self, url, cb, itemRefresh)
	local data={itemRefresh = itemRefresh}
	return self.net:sendPacket(url, data, cb)
end

-- 碎片商店商店购买
GameProtocol["/game/frag/shop/buy"] = function(self, url, cb, idx, shopID, itemID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={idx = idx, shopID = shopID, itemID = itemID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 获取碎片商店商店数据
GameProtocol["/game/frag/shop/get"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 精灵分享 from = 'world' or 'union'
GameProtocol["/game/card/share"] = function(self, url, cb, cardID, from)
	local data={cardID=cardID, from=from}
	return self.net:sendPacket(url, data, cb)
end

-- 试炼塔 每次进入都要调用
GameProtocol["/game/random_tower/prepare"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 试炼塔 选择卡面（若请求 则会确定下该房间卡面）
GameProtocol["/game/random_tower/board"] = function(self, url, cb, boardID)
	local data={boardID=boardID}
	return self.net:sendPacket(url, data, cb)
end

-- 试炼塔 试炼战斗开始
GameProtocol["/game/random_tower/start"] = function(self, url, cb, battleCardIDs, boardID)
	local data={battleCardIDs=battleCardIDs, boardID=boardID}
	return self.net:sendPacket(url, data, cb)
end

-- 试炼塔 试炼战斗结束
GameProtocol["/game/random_tower/end"] = function(self, url, cb, battleID, result, star, cardStates, enemyStates, battleRound)
	local data={battleID=battleID, result=result, star=star, cardStates=cardStates, enemyStates=enemyStates, battleRound=battleRound}
	return self.net:sendPacket(url, data, cb)
end

-- 试炼塔 手动跳下一房间（只有宝箱用）
GameProtocol["/game/random_tower/next"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 试炼塔 战斗碾压（战斗跳过）
GameProtocol["/game/random_tower/pass"] = function(self, url, cb, boardID)
	local data={boardID=boardID}
	return self.net:sendPacket(url, data, cb)
end

-- 试炼塔 buff 补给使用（前需调过board 请求）cards 只有可选择时发,并兼容单个cardID或数组
GameProtocol["/game/random_tower/buff/used"] = function(self, url, cb, cards)
	local data={cards=cards}
	return self.net:sendPacket(url, data, cb)
end

-- 试炼塔 随机事件结果选择（若 只有一个选择则不请求）（前需调过board 请求）
GameProtocol["/game/random_tower/event/choose"] = function(self, url, cb, choice)
	local data={choice=choice}
	return self.net:sendPacket(url, data, cb)
end

-- 试炼塔 试炼商店获得
GameProtocol["/game/random_tower/shop/get"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 试炼塔 试炼商店刷新 （itemRefresh 表示是否代金券刷新 钻石刷新可不传）
GameProtocol["/game/random_tower/shop/refresh"] = function(self, url, cb, itemRefresh)
	local data={itemRefresh=itemRefresh}
	return self.net:sendPacket(url, data, cb)
end

-- 试炼塔 试炼商店购买
GameProtocol["/game/random_tower/shop/buy"] = function(self, url, cb, idx, shopID, itemID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={idx=idx, shopID=shopID, itemID=itemID, count=count}
	return self.net:sendPacket(url, data, cb)
end

-- 试炼塔 领取积分奖励
GameProtocol["/game/random_tower/point/award"] = function(self, url, cb, csvID)
	local data={csvID=csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 试炼塔 开启宝箱（前需调过board 请求）
GameProtocol["/game/random_tower/box/open"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 通行证 领取奖励/一键领取
GameProtocol["/game/yy/passport/award/get_onekey"] = function(self, url, cb, yyID)
	local data={yyID=yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 通行证 任务经验领取
GameProtocol["/game/yy/passport/task/get_exp"] = function(self, url, cb, yyID, csvID)
	local data={yyID=yyID, csvID=csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 通行证商店兑换
GameProtocol["/game/yy/passport/shop/buy"] = function(self, url, cb, yyID, csvID, count)
	local data={yyID=yyID, csvID=csvID, count=count}
	return self.net:sendPacket(url, data, cb)
end

-- 成长向导奖励领取
GameProtocol["/game/role/growguide/award/get"] = function(self, url, cb, csvID)
	local data={csvID=csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 精灵特性 激活或强化  upLevel：提升的等级（不传默认1）
GameProtocol["/game/card/ability/strength"] = function(self, url, cb, cardID, position, upLevel)
	local data={cardID=cardID, position=position, upLevel=upLevel}
	return self.net:sendPacket(url, data, cb)
end

-- 进入捕捉
GameProtocol["/game/capture/enter"] = function(self, url, cb, captureType, index)
	local data={captureType=captureType, index=index}
	return self.net:sendPacket(url, data, cb)
end

-- 捕捉精灵
GameProtocol["/game/capture"] = function(self, url, cb, captureType, index, itemID)
	local data={captureType=captureType, index=index, itemID=itemID}
	return self.net:sendPacket(url, data, cb)
end

-- 饰品商店打开
GameProtocol["/game/equipshop/get"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 饰品商店购买
GameProtocol["/game/equipshop/buy"] = function(self, url, cb, idx, shopID, itemID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={idx = idx, shopID = shopID, itemID = itemID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 抽卡累计宝箱
GameProtocol["/game/draw/sum/box/get"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 成就宝箱奖励领取
GameProtocol["/game/role/achievement/box/award/get"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 成就任务奖励领取
GameProtocol["/game/role/achievement/task/award/get"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- vip是否显示切换
GameProtocol["/game/role/vip/display/switch"] = function(self, url, cb, flag)
	local data={flag=flag}
	return self.net:sendPacket(url, data, cb)
end

-- vip 月度礼包
GameProtocol["/game/role/vip/month/gift"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 资源找回
GameProtocol["/game/yy/retrieve/get"] = function(self, url, cb, yyID, type, tab)
	local data={yyID = yyID, type = type, tab = tab}
	return self.net:sendPacket(url, data, cb)
end

-- 扭蛋机扭蛋
GameProtocol["/game/yy/lucky/egg/draw"] = function(self, url, cb, yyID, drawType)
	local data={yyID = yyID, drawType = drawType}
	return self.net:sendPacket(url, data, cb)
end

-- 活动红包列表
GameProtocol["/game/yy/red/packet/list"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 发活动红包
GameProtocol["/game/yy/red/packet/send"] = function(self, url, cb, message)
	local data={message = message}
	return self.net:sendPacket(url, data, cb)
end

-- 抢活动红包
GameProtocol["/game/yy/red/packet/rob"] = function(self, url, cb, idx)
	local data={idx = idx}
	return self.net:sendPacket(url, data, cb)
end

-- 包粽子
GameProtocol["/game/yy/bao/zongzi"] = function(self, url, cb, yyID, plans)
	local data={yyID = yyID, plans = plans}
	return self.net:sendPacket(url, data, cb)
end

-- 努力值突破
GameProtocol["/game/card/effort/advance"] = function(self, url, cb, cardID)
	local data={cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- 卡牌选择自然属性, choose 1-第一属性, 2-第二属性
GameProtocol["/game/card/nature/choose"] = function(self, url, cb, cardID, choose)
	local data={cardID = cardID, choose = choose}
	return self.net:sendPacket(url, data, cb)
end

-- 满星技能卡牌兑换
GameProtocol["/game/card/star/skill/card/exchange"] = function(self, url, cb, cardID, costCardIDs)
	local data={cardID = cardID, costCardIDs = costCardIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 满星技能碎片兑换
GameProtocol["/game/card/star/skill/frag/exchange"] = function(self, url, cb, cardID, costFragID, costFragNum)
	local data={cardID = cardID, costFragID = costFragID, costFragNum = costFragNum}
	return self.net:sendPacket(url, data, cb)
end

-- 满星技能重置
GameProtocol["/game/card/star/skill/reset"] = function(self, url, cb, cardID)
	local data={cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- 精灵评论列表
GameProtocol["/game/card/comment/list"] = function(self, url, cb, cardID, offset, size)
	local data={cardID = cardID, offset = offset, size = size}
	return self.net:sendPacket(url, data, cb)
end

-- 发表精灵评论
GameProtocol["/game/card/comment/send"] = function(self, url, cb, cardID, content)
	return postDisableWordCheck(content, "card_comment", function(ret, err)
		if err then
			return cb(nil, err)
		end

		local data = {cardID = cardID, content = content}
		return self.net:sendPacket(url, data, cb)
	end)
end

-- 删除精灵评论
GameProtocol["/game/card/comment/del"] = function(self, url, cb, commentID)
	local data={commentID = commentID}
	return self.net:sendPacket(url, data, cb)
end

-- 对精灵评论进行评价
GameProtocol["/game/card/comment/evaluate"] = function(self, url, cb, commentID, evaluateType)
	local data={commentID = commentID, evaluateType = evaluateType}
	return self.net:sendPacket(url, data, cb)
end

-- 获取精灵评分
GameProtocol["/game/card/score/get"] = function(self, url, cb, cardID)
	local data={cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- 对精灵评分
GameProtocol["/game/card/score/send"] = function(self, url, cb, cardID, score)
	local data={cardID = cardID, score = score}
	return self.net:sendPacket(url, data, cb)
end

-- 精灵评分排名
GameProtocol["/game/card/score/rank"] = function(self, url, cb, offset, size)
	local data={offset = offset, size = size}
	return self.net:sendPacket(url, data, cb)
end

-- 精灵战力榜
GameProtocol["/game/card/fight/rank"] = function(self, url, cb, cardID, offset, size)
	local data={cardID = cardID, offset = offset, size = size}
	return self.net:sendPacket(url, data, cb)
end

-- 公会战报名
GameProtocol["/game/union/fight/signup"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 公会战主赛场
GameProtocol["/game/union/fight/battle/main"] = function(self, url, cb, roundKey)
	local data={roundKey = roundKey}
	return self.net:sendPacket(url, data, cb)
end

-- 公会战 top8 战斗列表
GameProtocol["/game/union/fight/top8/round/results"] = function(self, url, cb, roundKey)
	local data={roundKey = roundKey}
	return self.net:sendPacket(url, data, cb)
end

-- 公会战战报
GameProtocol["/game/union/fight/playrecord/get"] = function(self, url, cb, playID)
	local data={playID = playID}
	return self.net:sendPacket(url, data, cb)
end

-- 公会战布阵
GameProtocol["/game/union/fight/battle/deploy"] = function(self, url, cb, weekday, battleCardIDs)
	local data={weekday = weekday, battleCardIDs = battleCardIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 公会战 top8 布阵
GameProtocol["/game/union/fight/top8/deploy"] = function(self, url, cb, roles)
	local data={roles = roles}
	return self.net:sendPacket(url, data, cb)
end

-- 公会战排名
GameProtocol["/game/union/fight/rank"] = function(self, url, cb, weekday, randType)
	local data={weekday = weekday, rankType = rankType}
	return self.net:sendPacket(url, data, cb)
end

-- 公会战昨日战况
GameProtocol["/game/union/fight/yesterday/battle"] = function(self, url, cb, roundKey)
	local data={roundKey = roundKey}
	return self.net:sendPacket(url, data, cb)
end

-- 公会战战斗之星
GameProtocol["/game/union/fight/battle/star/set"] = function(self, url, cb, nature, attr, effectType)
	local data={nature = nature, attr = attr, effectType = effectType}
	return self.net:sendPacket(url, data, cb)
end

-- 公会战我的押注
GameProtocol["/game/union/fight/bet/info"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 公会战下注
GameProtocol["/game/union/fight/bet"] = function(self, url, cb, unionID, gold)
	local data={unionID = unionID, gold = gold}
	return self.net:sendPacket(url, data, cb)
end

-- 公会战商店
GameProtocol["/game/union/fight/shop/buy"] = function(self, url, cb, csvID, count)
	local data={csvID = csvID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服石英大会主赛场，我的赛场
GameProtocol["/game/cross/craft/battle/main"] = function(self, url, cb, refresh_time)
	local data={refresh_time = refresh_time}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服石英大会报名
GameProtocol["/game/cross/craft/signup"] = function(self, url, cb, cards)
	local data={cards = cards}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服石英大会获取对方参赛信息 key: game.cn.1, 区服key
GameProtocol["/game/cross/craft/battle/enemy/get"] = function(self, url, cb, key, roleID, recordID)
	local data={key = key, roleID = roleID, recordID = recordID}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服石英大会挑战部署
GameProtocol["/game/cross/craft/battle/deploy"] = function(self, url, cb, cards)
	local data={cards = cards}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服石英大会我的下注
GameProtocol["/game/cross/craft/bet/info"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服石英大会下注 key: game.cn.1, 区服key, type 1-预选押注 2-top4押注 3-冠军押注
GameProtocol["/game/cross/craft/bet"] = function(self, url, cb, type, key, roleID, coin)
	local data={type = type, key = key, roleID = roleID, coin = coin}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服石英大会查看战报
GameProtocol["/game/cross/craft/playrecord/get"] = function(self, url, cb, recordID, crossKey)
	local data={recordID = recordID, crossKey = crossKey}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服石英大会商店兑换
GameProtocol["/game/cross/craft/shop/buy"] = function(self, url, cb, csvID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={csvID = csvID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服石英大会排行榜
GameProtocol["/game/cross/craft/rank"] = function(self, url, cb, offest, size)
	local data={offest = offest, size = size}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服石英大会预选赛积分排行榜
GameProtocol["/game/cross/craft/pre/point/rank"] = function(self, url, cb, offest, size)
	local data={offest = offest, size = size}
	return self.net:sendPacket(url, data, cb)
end

-- 以太乐园跳过 下一步（包含开始）
GameProtocol["/game/random_tower/jump/next"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 以太乐园跳过 打开豪华宝箱 （boardID全开传0；openType = "open1" "open5"）
GameProtocol["/game/random_tower/jump/box_open"] = function(self, url, cb, boardID, openType)
	local data={boardID = boardID, openType = openType}
	return self.net:sendPacket(url, data, cb)
end

-- 以太乐园跳过 选择buff （boardID随机传0）
GameProtocol["/game/random_tower/jump/buff"] = function(self, url, cb, boardID)
	local data={boardID = boardID}
	return self.net:sendPacket(url, data, cb)
end

-- 以太乐园跳过 选择事件
GameProtocol["/game/random_tower/jump/event"] = function(self, url, cb, boardID, choice)
	local data={boardID = boardID, choice = choice}
	return self.net:sendPacket(url, data, cb)
end


-- 宝石 镶嵌
GameProtocol["/game/gem/equip"] = function(self, url, cb, cardID, gemID, pos)
	local data={cardID = cardID, gemID = gemID, pos = pos}
	return self.net:sendPacket(url, data, cb)
end

-- 宝石 卸下（含一键卸下 多个） gemIDs = [dbIds]
GameProtocol["/game/gem/unload"] = function(self, url, cb, gemIDs)
	local data={gemIDs = gemIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 宝石 更换
GameProtocol["/game/gem/swap"] = function(self, url, cb, oldGemID, newGemID)
	local data={oldGemID = oldGemID, newGemID = newGemID}
	return self.net:sendPacket(url, data, cb)
end

-- 宝石 强化（一键强化 需传level）
GameProtocol["/game/gem/strength"] = function(self, url, cb, gemID, level)
	local data={gemID = gemID, level = level}
	return self.net:sendPacket(url, data, cb)
end

-- 宝石 分解 gemIDs = [gemID]
GameProtocol["/game/gem/decompose"] = function(self, url, cb, gemIDs)
	local data={gemIDs = gemIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 宝石 重生 gemIDs = [gemID]
GameProtocol["/game/gem/rebirth"] = function(self, url, cb, gemIDs)
	local data={gemIDs = gemIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 抽宝石 (rmb1, rmb10, free1, gold1, gold10, free_gold1) decompose=1 代表分解，0代表不分解
GameProtocol["/game/lottery/gem/draw"] = function(self, url, cb, drawType, decompose)
	local data={drawType = drawType, decompose = decompose}
	return self.net:sendPacket(url, data, cb)
end

-- 宝石槽内移位置
GameProtocol["/game/gem/pos/change"] = function(self, url, cb, gemID, pos)
	local data={gemID = gemID, pos = pos}
	return self.net:sendPacket(url, data, cb)
end

-- 宝石 一键镶嵌
GameProtocol["/game/gem/onekey/equip"] = function(self, url, cb, cardID, gemIDs)
	local data={cardID = cardID, gemIDs = gemIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 竞技场 5次碾压
GameProtocol["/game/pw/battle/pass"] = function(self, url, cb, battleRank)
	local data={battleRank = battleRank}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服竞技场 主界面
GameProtocol["/game/cross/arena/battle/main"] = function(self, url, cb, needRefresh)
	local data={needRefresh = needRefresh}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服竞技场 队伍布阵（两个队伍）包含防守
GameProtocol["/game/cross/arena/battle/deploy"] = function(self, url, cb, cards, defenceCards)
	local data={cards = cards, defenceCards = defenceCards}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服竞技场 开始战斗
GameProtocol["/game/cross/arena/battle/start"] = function(self, url, cb, myRank, battleRank, enemyRoleID, enemyRecordID)
	local versionPlist = cc.FileUtils:getInstance():getValueMapFromFile('res/version.plist')
	local data={myRank = myRank, battleRank = battleRank, enemyRoleID = enemyRoleID, enemyRecordID = enemyRecordID, patch = tonumber(versionPlist.patch)}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服竞技场 结束战斗
GameProtocol["/game/cross/arena/battle/end"] = function(self, url, cb, rank, result, isTopBattle)
	local data={rank = rank, result = result, isTopBattle = isTopBattle}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服竞技场 对战情报录像回放
GameProtocol["/game/cross/arena/playrecord/get"] = function(self, url, cb, recordID, crossKey)
	local data={recordID = recordID, crossKey = crossKey}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服竞技场 领取每日次数奖励
GameProtocol["/game/cross/arena/daily/award"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服竞技场 领取段位奖励
GameProtocol["/game/cross/arena/stage/award"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服竞技场 获取排行榜
GameProtocol["/game/cross/arena/rank"] = function(self, url, cb, offest, size)
	local data={offest = offest, size = size}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服竞技场 购买挑战次数
GameProtocol["/game/cross/arena/battle/buy"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服竞技场 查看玩家详情
GameProtocol["/game/cross/arena/role/info"] = function(self, url, cb, recordID, gameKey, rank)
	local data={recordID = recordID, gameKey = gameKey, rank = rank}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服竞技场 更换展示卡牌 csv_id
GameProtocol["/game/cross/arena/display"] = function(self, url, cb, cardID)
	local data={cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服竞技场商店兑换
GameProtocol["/game/cross/arena/shop/buy"] = function(self, url, cb, csvID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={csvID = csvID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服竞技场5次碾压
GameProtocol["/game/cross/arena/battle/pass"] = function(self, url, cb, battleRank)
	local data={battleRank = battleRank}
	return self.net:sendPacket(url, data, cb)
end

-- 钓鱼主界面接口
GameProtocol["/game/fishing/main"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 钓鱼单次开始
GameProtocol["/game/fishing/once/start"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 钓鱼单次开始操作
GameProtocol["/game/fishing/once/doing"] = function(self, url, cb, fish)
	local data={fish = fish}
	return self.net:sendPacket(url, data, cb)
end

-- 钓鱼单次结束
GameProtocol["/game/fishing/once/end"] = function(self, url, cb, fish, result)
	local data={fish = fish, result = result}
	return self.net:sendPacket(url, data, cb)
end

-- 自动钓鱼开始
GameProtocol["/game/fishing/auto/start"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 自动钓鱼结束
GameProtocol["/game/fishing/auto/end"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 钓鱼捕捞（一键）
GameProtocol["/game/fishing/onekey"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 钓鱼大赛排名信息
GameProtocol["/game/cross/fishing/rank"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 钓鱼准备 itemType: scene、rod、bait、partner  itemID: itemType为partner时传-1表示不带钓鱼陪伴
GameProtocol["/game/fishing/prepare"] = function(self, url, cb, itemType, itemID)
	local data={itemType = itemType, itemID = itemID}
	return self.net:sendPacket(url, data, cb)
end

-- 钓鱼相关解锁 itemType: rod、partner
GameProtocol["/game/fishing/item/unlock"] = function(self, url, cb, itemType, itemID)
	local data={itemType = itemType, itemID = itemID}
	return self.net:sendPacket(url, data, cb)
end

-- 钓鱼 鱼饵购买
GameProtocol["/game/fishing/bait/buy"] = function(self, url, cb, baitID, count)
	local data={baitID = baitID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 钓鱼商店 获取
GameProtocol["/game/fishing/shop/get"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 钓鱼商店 刷新
GameProtocol["/game/fishing/shop/refresh"] = function(self, url, cb, itemRefresh)
	local data={itemRefresh = itemRefresh}
	return self.net:sendPacket(url, data, cb)
end

-- 钓鱼商店 购买
GameProtocol["/game/fishing/shop/buy"] = function(self, url, cb, idx, shopID, itemID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={idx = idx, shopID = shopID, itemID = itemID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 超进化
GameProtocol["/game/develop/mega"] = function(self, url, cb, cardID, branch, costCardIDs)
	local data={cardID = cardID, branch = branch, costCardIDs = costCardIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 精灵 转化 进化石/钥石 costCardID=cardID
GameProtocol["/game/develop/mega/convert/card"] = function(self, url, cb, csvID, costCardID)
	local data={csvID = csvID,  costCardID = costCardID}
	return self.net:sendPacket(url, data, cb)
end

-- 碎片 转化 进化石/钥石 costFragID = fragCsvID
GameProtocol["/game/develop/mega/convert/frag"] = function(self, url, cb, csvID, num, costFragID)
	local data={csvID = csvID, num = num, costFragID = costFragID}
	return self.net:sendPacket(url, data, cb)
end

-- 转化 进化石/钥石 次数购买
GameProtocol["/game/develop/mega/convert/buy"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 实时对战进主界面
GameProtocol["/game/cross/online/main"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 实时对战开始匹配
GameProtocol["/game/cross/online/matching"] = function(self, url, cb, pattern, patch, longtimeout)
	local data={pattern = pattern, patch = patch, longtimeout = longtimeout}
	return self.net:sendPacket(url, data, cb)
end

-- 实时对战取消匹配
GameProtocol["/game/cross/online/cancel"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 实时对战获取战斗结果
GameProtocol["/game/cross/online/battle/end"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 实时对战部署
GameProtocol["/game/cross/online/deploy"] = function(self, url, cb, cards, pattern)
	local data={cards = cards, pattern = pattern}
	return self.net:sendPacket(url, data, cb)
end

-- 实时对战录像数据
GameProtocol["/game/cross/online/playrecord/get"] = function(self, url, cb, recordID, crossKey)
	local data={recordID = recordID, crossKey = crossKey}
	return self.net:sendPacket(url, data, cb)
end

-- 实时对战排行榜 pattern: 1-无限制; 2-公平赛
GameProtocol["/game/cross/online/rank"] = function(self, url, cb, pattern, offest, size)
	local data={pattern = pattern, offest = offest, size = size}
	return self.net:sendPacket(url, data, cb)
end

-- 实时对战每周目标奖励
GameProtocol["/game/cross/online/weekly/target"] = function(self, url, cb, csvID)
	local data={csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 实时对战商店兑换
GameProtocol["/game/cross/online/shop/buy"] = function(self, url, cb, csvID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={csvID = csvID, count = count}
	return self.net:sendPacket(url, data, cb)
end

--快速扫荡收藏
GameProtocol["/game/saodang/batch/favorites"] = function(self, url, cb, gateID)
	local data={gateID = gateID}
	return self.net:sendPacket(url, data, cb)
end

--道馆main请求
GameProtocol["/game/gym/main"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

--荣誉馆主 开始战斗
GameProtocol["/game/gym/leader/battle/start"] = function(self, url, cb, cards, gymID, enemyRecordID)
	local data={cards = cards, gymID = gymID, enemyRecordID = enemyRecordID}
	return self.net:sendPacket(url, data, cb)
end

--荣誉馆主 结束战斗
GameProtocol["/game/gym/leader/battle/end"] = function(self, url, cb, result, gymID)
	local data={result = result, gymID = gymID}
	return self.net:sendPacket(url, data, cb)
end

--跨服道馆位置空 直接占领
GameProtocol["/game/cross/gym/battle/occupy"] = function(self, url, cb, cards, gymID, pos)
	local data={cards = cards, gymID = gymID, pos = pos}
	return self.net:sendPacket(url, data, cb)
end

--跨服道馆 开始战斗
GameProtocol["/game/cross/gym/battle/start"] = function(self, url, cb, cards, gymID, pos, enemyRoleKey, enemyRecordID)
	local data={cards = cards, gymID = gymID, pos = pos, enemyRoleKey = enemyRoleKey, enemyRecordID = enemyRecordID}
	return self.net:sendPacket(url, data, cb)
end

--跨服道馆 结束战斗
GameProtocol["/game/cross/gym/battle/end"] = function(self, url, cb, result, gymID, pos)
	local data={result = result, gymID = gymID, pos = pos}
	return self.net:sendPacket(url, data, cb)
end

--道馆 查看玩家详情
GameProtocol["/game/gym/role/info"] = function(self, url, cb, recordID, gameKey)
	local data={recordID = recordID, gameKey = gameKey}
	return self.net:sendPacket(url, data, cb)
end

--道馆关卡 开始战斗
GameProtocol["/game/gym/gate/start"] = function(self, url, cb, gateID, gymID, cardIDs)
	local data={gateID = gateID, gymID = gymID, cardIDs = cardIDs}
	return self.net:sendPacket(url, data, cb)
end

--道馆关卡 结束战斗
GameProtocol["/game/gym/gate/end"] = function(self, url, cb, battleID, gateID, result, damage)
	local data={battleID = battleID, result = result, gateID = gateID, damage = damage}
	return self.net:sendPacket(url, data, cb)
end

--道馆关卡 扫荡
GameProtocol["/game/gym/gate/pass"] = function(self, url, cb, gymID, gateID)
	local data={gymID = gymID, gateID = gateID}
	return self.net:sendPacket(url, data, cb)
end

--道馆 副本挑战次数购买
GameProtocol["/game/gym/battle/buy"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

--道馆 领取通关奖励
GameProtocol["/game/gym/gate/award"] = function(self, url, cb, gymID)
	local data={gymID = gymID}
	return self.net:sendPacket(url, data, cb)
end

--道馆 天赋点数购买
GameProtocol["/game/gym/talent/point/buy"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

--道馆 天赋升级
GameProtocol["/game/gym/talent/level/up"] = function(self, url, cb, talentID)
	local data={talentID = talentID}
	return self.net:sendPacket(url, data, cb)
end

--道馆 天赋重置
GameProtocol["/game/gym/talent/reset"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

--道馆PVP战斗回放 crossKey不传为本服，传为跨服
GameProtocol["/game/gym/playrecord/get"] = function(self, url, cb, recordID, crossKey)
	local data = {crossKey = crossKey, recordID = recordID}
	return self.net:sendPacket(url, data, cb)
end

--勋章 天赋升级
GameProtocol["/game/badge/talent/level/up"] = function(self, url, cb, badgeID, count)
	local data={badgeID = badgeID, count = count}
	return self.net:sendPacket(url, data, cb)
end

--勋章 勋章觉醒
GameProtocol["/game/badge/awake"] = function(self, url, cb, badgeID)
	local data={badgeID = badgeID}
	return self.net:sendPacket(url, data, cb)
end

--勋章 守护设置\下阵\更换 cardID = -1时表示下阵
GameProtocol["/game/badge/guard/setup"] = function(self, url, cb, badgeID, guardID, cardID)
	local data={badgeID = badgeID, guardID = guardID, cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

--勋章 守护位置解锁
GameProtocol["/game/badge/guard/unlock"] = function(self, url, cb, badgeID, guardID)
	local data={badgeID = badgeID, guardID = guardID}
	return self.net:sendPacket(url, data, cb)
end

--勋章 勋章加成刷新
GameProtocol["/game/badge/refresh"] = function(self, url, cb)
	local data={}
	return self.net:sendPacket(url, data, cb)
end

-- 装备升星潜能
GameProtocol["/game/equip/ability"] = function(self, url, cb, cardID, equipPos, level)
	local data={cardID = cardID, equipPos = equipPos, level = level}
	return self.net:sendPacket(url, data, cb)
end

-- 装备刻印
GameProtocol["/game/equip/signet"] = function(self, url, cb, cardID, equipPos, upLevel, oneKey, advanceLevel)
	local data={cardID = cardID, equipPos = equipPos, upLevel = upLevel, oneKey = oneKey, advanceLevel = advanceLevel}
	return self.net:sendPacket(url, data, cb)
end

-- 装备刻印突破
GameProtocol["/game/equip/signet/advance"] = function(self, url, cb, cardID, equipPos)
	local data={cardID = cardID, equipPos = equipPos}
	return self.net:sendPacket(url, data, cb)
end

-- 装备刻印降阶
GameProtocol["/game/equip/signet/drop"] = function(self, url, cb, cardID, equipPos)
	local data={cardID = cardID, equipPos = equipPos}
	return self.net:sendPacket(url, data, cb)
end

--重聚 推荐绑定列表 listType 1-好友, 2-推荐
GameProtocol["/game/yy/reunion/bind/list"] = function(self, url, cb, listType)
	local data={listType = listType}
	return self.net:sendPacket(url, data, cb)
end

--重聚 绑定邀请 msgType = world 、recommend
GameProtocol["/game/yy/reunion/bind/invite"] = function(self, url, cb, msgType, role)
	local data = {msgType = msgType}
	if msgType == "recommend" then
		data={msgType = msgType, role = role}
	end
	return self.net:sendPacket(url, data, cb)
end

--重聚 接受绑定邀请
GameProtocol["/game/yy/reunion/bind/join"] = function(self, url, cb, yyID, roleID, endTime)
	local data = {yyID = yyID, roleID = roleID, endTime = endTime}
	return self.net:sendPacket(url, data, cb)
end

--重聚 奖励领取 awardType = 1重聚礼包 2绑定奖励 3任务奖励 4积分奖励
GameProtocol["/game/yy/reunion/award/get"] = function(self, url, cb, yyID, csvID, awardType)
	local data = {yyID = yyID, csvID = csvID, awardType = awardType}
	return self.net:sendPacket(url, data, cb)
end

--重聚 活动记录获取
GameProtocol["/game/yy/reunion/record/get"] = function(self, url, cb, roleID)
	local data = {roleID = roleID}
	return self.net:sendPacket(url, data, cb)
end

-- 获取活动兑换奖励
GameProtocol["/game/yy/award/exchange"] = function(self, url, cb, yyID, csvID, costID, targetIdx, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data = {yyID = yyID, csvID = csvID, costID = costID, targetID = targetIdx-1, count = count or 1}
	return self.net:sendPacket(url, data, cb)
end

-- 活动Boss开始战斗
GameProtocol["/game/yy/huodongboss/battle/start"] = function(self, url, cb, cardIDs, idx, yyID)
	local data = {cardIDs = cardIDs, idx = idx, yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 活动Boss结束战斗
GameProtocol["/game/yy/huodongboss/battle/end"] = function(self, url, cb, battleID, result, yyID, idx, damage)
	local data = {battleID = battleID, result = result, yyID = yyID, idx = idx, damage = damage}
	return self.net:sendPacket(url, data, cb)
end

-- 活动Boss列表
GameProtocol["/game/yy/huodongboss/list"] = function(self, url, cb, yyID, size)
	local data = {yyID = yyID, size = size}
	return self.net:sendPacket(url, data, cb)
end

--双十一活动主界面
GameProtocol["/game/yy/double11/main"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

--双十一小游戏开始
GameProtocol["/game/yy/double11/game/start"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

--双十一小游戏开始
GameProtocol["/game/yy/double11/game/end"] = function(self, url, cb, yyID, count)
	local data = {yyID = yyID, count = count}
	return self.net:sendPacket(url, data, cb)
end

--双十一刮卡
GameProtocol["/game/yy/double11/card/open"] = function(self, url, cb, yyID, gameCsvID)
	local data = {yyID = yyID, gameCsvID = gameCsvID}
	return self.net:sendPacket(url, data, cb)
end

--预设队伍修改名字
GameProtocol["/game/ready/card/rename"] = function(self, url, cb, idx, name)
	local data = {idx = idx, name = name}
	return self.net:sendPacket(url, data, cb)
end

--预设队伍布阵保存
GameProtocol["/game/ready/card/deploy"] = function(self, url, cb, idx, cardIDs)
	local data = {idx = idx, cardIDs = cardIDs}
	return self.net:sendPacket(url, data, cb)
end

--购买皮肤
GameProtocol["/game/card/skin/buy"] = function(self, url, cb, skinID)
	local data = {skinID = skinID}
	return self.net:sendPacket(url, data, cb)
end

--使用皮肤
GameProtocol["/game/card/skin/use"] = function(self, url, cb, skinID, cardID)
	local data = {skinID = skinID, cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

--皮肤商店购买
GameProtocol["/game/card/skin/shop/buy"] = function(self, url, cb, csvID, count)
	if count and count < 0 then
		return showCheatError(cb)
	end
	local data={csvID = csvID, count = count}
	return self.net:sendPacket(url, data, cb)
end

--活动装扮 主界面
GameProtocol["/game/yy/cloth/main"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

--活动装扮 一键升级
GameProtocol["/game/yy/cloth/item/use"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

--活动装扮 换装
GameProtocol["/game/yy/cloth/decorate"] = function(self, url, cb, yyID, part, csvID)
	local data = {yyID = yyID, part = part, csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

--躲雪球 主界面
GameProtocol["/game/yy/snowball/main"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

--躲雪球 开始游戏
GameProtocol["/game/yy/snowball/start"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

--躲雪球 结束游戏
GameProtocol["/game/yy/snowball/end"] = function(self, url, cb, yyID, point, playTime, guide, role)
	local data = {yyID = yyID, point = point, playTime = playTime, guide = guide, role = role}
	return self.net:sendPacket(url, data, cb)
end

--躲雪球 购买次数
GameProtocol["/game/yy/snowball/buy"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

--碎片合成道具/携带道具
GameProtocol["/game/role/frag/comb/item"] = function(self, url, cb, fragID, count)
	local data = {fragID = fragID, count = count}
	return self.net:sendPacket(url, data, cb)
end

--跨服资源战主界面
GameProtocol["/game/cross/mine/main"] = function(self, url, cb, refresh)
	local data = {refresh = refresh}
	return self.net:sendPacket(url, data, cb)
end

--跨服资源战布阵
GameProtocol["/game/cross/mine/battle/deploy"] = function(self, url, cb, cards, defenceCards)
	local data = {cards = cards, defenceCards = defenceCards}
	return self.net:sendPacket(url, data, cb)
end

--跨服资源战战斗开始
GameProtocol["/game/cross/mine/battle/start"] = function(self, url, cb, flag, myRank, enemyRank, enemyRoleID, enemyRecordID)
	local versionPlist = cc.FileUtils:getInstance():getValueMapFromFile('res/version.plist')
	local data = {flag = flag, myRank = myRank, enemyRank = enemyRank, enemyRoleID = enemyRoleID, enemyRecordID = enemyRecordID, patch = tonumber(versionPlist.patch)}
	return self.net:sendPacket(url, data, cb)
end

--跨服资源战战斗结束
GameProtocol["/game/cross/mine/battle/end"] = function(self, url, cb, result, stats, isTopBattle)
	local data = {result = result, stats = stats, isTopBattle = isTopBattle}
	return self.net:sendPacket(url, data, cb)
end

--跨服资源战 Boss战斗开始
GameProtocol["/game/cross/mine/boss/battle/start"] = function(self, url, cb, bossID)
	local data = {bossID = bossID}
	return self.net:sendPacket(url, data, cb)
end

--跨服资源战 Boss 战斗结束
GameProtocol["/game/cross/mine/boss/battle/end"] = function(self, url, cb, battleID, damages, actions)
	local floorDamages = {}
	for k, v in pairs(damages) do
		floorDamages[k] = math.floor(v)
	end
	local data = {battleID = battleID, damages = floorDamages, actions = actions}
	return self.net:sendPacket(url, data, cb)
end

--跨服资源战购买次数
GameProtocol["/cross/mine/times/buy"] = function(self, url, cb, flag)
	local data = {flag = flag}
	return self.net:sendPacket(url, data, cb)
end

--跨服资源战购买 Boss 挑战次数
GameProtocol["/cross/mine/boss/times/buy"] = function(self, url, cb, bossID)
	local data = {bossID = bossID}
	return self.net:sendPacket(url, data, cb)
end

--跨服资源战 buff 喂养
GameProtocol["/cross/mine/buff/feed"] = function(self, url, cb, flag, csvID)
	local data = {flag = flag, csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

--跨服资源战排行榜
GameProtocol["/game/cross/mine/rank"] = function(self, url, cb, flag, offset, size)
	local data = {flag = flag, offset = offset, size = size}
	return self.net:sendPacket(url, data, cb)
end

--跨服资源战 Boss 排行榜
GameProtocol["/game/cross/mine/boss/rank"] = function(self, url, cb, bossID, offset, size)
	local data = {bossID = bossID, offset = offset, size = size}
	return self.net:sendPacket(url, data, cb)
end

--跨服资源战战斗回放
GameProtocol["/game/cross/mine/playrecord/get"] = function(self, url, cb, recordID, crossKey)
	local data = {recordID = recordID, crossKey = crossKey}
	return self.net:sendPacket(url, data, cb)
end

--查看玩家详情
GameProtocol["/game/cross/mine/role/info"] = function(self, url, cb, recordID, gameKey, rank, flag)
	local data = {recordID = recordID, gameKey = gameKey, rank = rank, flag = flag}
	return self.net:sendPacket(url, data, cb)
end

--跨服资源战商店
GameProtocol["/game/cross/mine/shop"] = function(self, url, cb, csvID, count)
	local data = {csvID = csvID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 装备觉醒潜能
GameProtocol["/game/equip/awake/ability"] = function(self, url, cb, cardID, equipPos, level)
	local data={cardID = cardID, equipPos = equipPos, level = level}
	return self.net:sendPacket(url, data, cb)
end

-- 公会问答 界面
GameProtocol["/game/union/qa/main"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 公会问答 准备
GameProtocol["/game/union/qa/prepare"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 公会问答 开始答题
GameProtocol["/game/union/qa/answer/start"] = function(self, url, cb, idx)
	local data = {idx = idx}
	return self.net:sendPacket(url, data, cb)
end

-- 公会问答 提交答案
GameProtocol["/game/union/qa/answer/submit"] = function(self, url, cb, idx, answer)
	local data = {idx = idx, answer = answer}
	return self.net:sendPacket(url, data, cb)
end

-- 公会问答 结束/退出
GameProtocol["/game/union/qa/settle"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 公会问答 购买次数
GameProtocol["/game/union/qa/buy"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 公会问答 排行榜
GameProtocol["/game/union/qa/rank"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

--摩天大楼 排行榜
GameProtocol["/game/yy/skyscraper/ranking"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

--摩天大楼 开始游戏
GameProtocol["/game/yy/skyscraper/start"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

--摩天大楼 结束游戏
GameProtocol["/game/yy/skyscraper/end"] = function(self, url, cb, yyID, points, floors, perfections, playTime, numAwards)
	local data = {yyID = yyID, points = points, floors = floors, perfections = perfections, playTime = playTime, numAwards = numAwards}
	return self.net:sendPacket(url, data, cb)
end

--摩天大楼 奖励领取
GameProtocol["/game/yy/skyscraper/awards"] = function(self, url, cb, yyID, csvID, awardType)
	local data = {yyID = yyID, csvID = csvID, awardType = awardType}
	return self.net:sendPacket(url, data, cb)
end

--摩天大楼 购买
GameProtocol["/game/yy/skyscraper/buy"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

--日常小助手 一键 filterKeys为过滤的list flag弹窗选择
GameProtocol["/game/daily/assistant/onekey"] = function(self, url, cb, type, filterKeys, flags)
	local data = {type = type, filterKeys = filterKeys, flags = flags}
	return self.net:sendPacket(url, data, cb)
end

--日常小助手 选择
GameProtocol["/game/daily/assistant/set"] = function(self, url, cb, csvID, value)
	local data = {csvID = csvID, value = value}
	return self.net:sendPacket(url, data, cb)
end

--日常小助手 pvp部分数据同步
GameProtocol["/game/daily/assistant/sync"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 集福迎新年 春节活动 领取连线奖励
GameProtocol["/game/yy/link/award/get"] = function(self, url, cb, yyID, awardID)
	local data={yyID = yyID, awardID = awardID}
	return self.net:sendPacket(url, data, cb)
end

--春节返利 利息领取
GameProtocol["/yy/rmbgold/return"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

--跨服红包 获取列表
GameProtocol["/game/yy/cross/red/packet/list"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

--跨服红包 发红包
GameProtocol["/game/yy/cross/red/packet/send"] = function(self, url, cb, message)
	local data={message = message}
	return self.net:sendPacket(url, data, cb)
end

--跨服红包 抢红包
GameProtocol["/game/yy/cross/red/packet/rob"] = function(self, url, cb, idx)
	local data={idx = idx}
	return self.net:sendPacket(url, data, cb)
end

--公会系统红包 (一键领取)
GameProtocol["/game/union/redpacket/onekey"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

--玩法通行证 (购买等级)
GameProtocol["/game/yy/playpassport/exp/buy"] = function(self, url, cb, yyID, level)
	local data = {yyID = yyID, level = level}
	return self.net:sendPacket(url, data, cb)
end

--赛马主界面
GameProtocol["/game/yy/horse/race/main"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

--赛马押注
GameProtocol["/game/yy/horse/race/bet"] = function(self, url, cb, yyID, date, play, csvID)
	local data = {yyID = yyID, date = date, play = play, csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

--赛马积分奖励
GameProtocol["/game/yy/horse/race/point/award"] = function(self, url, cb, yyID, csvID)
	local data = {yyID = yyID, csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

GameProtocol["/game/yy/horse/race/result/test"] = function(self, url, cb, yyID, csvIDs, times)
	local data = {yyID = yyID, csvIDs = csvIDs, times = times}
	return self.net:sendPacket(url, data, cb)
end

--赛马押注奖励
GameProtocol["/game/yy/horse/race/bet/award"] = function(self, url, cb, yyID, date, play)
	local data = {yyID = yyID, date = date, play = play}
	return self.net:sendPacket(url, data, cb)
end

--赛马排行榜
GameProtocol["/game/yy/horse/race/rank"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

--赛马回放
GameProtocol["/game/yy/horse/race/playback"] = function(self, url, cb, yyID, date, play)
	local data = {yyID = yyID, date = date, play = play}
	return self.net:sendPacket(url, data, cb)
end

--走格子使用道具
GameProtocol["/game/yy/gridwalk/itemuse"] = function(self, url, cb, yyID, itemID)
	local data = {yyID = yyID, itemID = itemID}
	return self.net:sendPacket(url, data, cb)
end

--走格子商店购买
GameProtocol["/game/yy/gridwalk/shop"] = function(self, url, cb, yyID, itemID, coupon_used, index)
	local data = {yyID = yyID, itemID = itemID, coupon_used = coupon_used, index = index}
	return self.net:sendPacket(url, data, cb)
end

--走格子主界面
GameProtocol["/game/yy/gridwalk/main"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 勇者挑战 主界面
GameProtocol["/game/yy/brave_challenge/main"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 勇者挑战 排行榜
GameProtocol["/game/yy/brave_challenge/rank"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 勇者挑战 开始准备
GameProtocol["/game/yy/brave_challenge/prepare/start"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 勇者挑战 结束准备
GameProtocol["/game/yy/brave_challenge/prepare/end"] = function(self, url, cb, cards,  yyID)
	local data = {yyID = yyID, cards = cards}
	return self.net:sendPacket(url, data, cb)
end

-- 勇者挑战 布阵
GameProtocol["/game/yy/brave_challenge/deploy"] = function(self, url, cb, cards, yyID)
	local data = {yyID = yyID, cards = cards}
	return self.net:sendPacket(url, data, cb)
end

-- 勇者挑战 开始挑战
GameProtocol["/game/yy/brave_challenge/battle/start"] = function(self, url, cb, floorID, monsterID, cards, yyID)
	local data = {yyID = yyID, floorID = floorID, monsterID = monsterID, cards = cards}
	return self.net:sendPacket(url, data, cb)
end

-- 勇者挑战 结束挑战
GameProtocol["/game/yy/brave_challenge/battle/end"] = function(self, url, cb, battleID, floorID, result, cardStates, monsterStates, battleRound, damage, actions)
	local data = {battleID = battleID, floorID = floorID, result = result, cardStates = cardStates, monsterStates = monsterStates, battleRound = battleRound, damage = damage, actions = actions}
	return self.net:sendPacket(url, data, cb)
end

-- 勇者挑战 选择勋章
GameProtocol["/game/yy/brave_challenge/badge/choose"] = function(self, url, cb, badgeID, yyID)
	local data = {yyID = yyID, badgeID = badgeID}
	return self.net:sendPacket(url, data, cb)
end

-- 勇者挑战 认输
GameProtocol["/game/yy/brave_challenge/quit"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 勇者挑战 购买挑战次数
GameProtocol["/game/yy/brave_challenge/buy"] = function(self, url, cb, yyID)
	local data = {yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 普通勇者挑战 主界面
GameProtocol["/game/brave_challenge/main"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 普通勇者挑战 排行榜
GameProtocol["/game/brave_challenge/rank"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 普通勇者挑战 领取奖励
GameProtocol["/game/brave_challenge/award/get"] = function(self, url, cb, yyID, csvID)
	local data = {csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

-- 普通勇者挑战 开始准备
GameProtocol["/game/brave_challenge/prepare/start"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 普通勇者挑战 结束准备
GameProtocol["/game/brave_challenge/prepare/end"] = function(self, url, cb, cards)
	local data = {cards = cards}
	return self.net:sendPacket(url, data, cb)
end

-- 普通勇者挑战 布阵
GameProtocol["/game/brave_challenge/deploy"] = function(self, url, cb, cards)
	local data = {cards = cards}
	return self.net:sendPacket(url, data, cb)
end

-- 普通勇者挑战 开始挑战
GameProtocol["/game/brave_challenge/battle/start"] = function(self, url, cb, floorID, monsterID, cards)
	local data = {floorID = floorID, monsterID = monsterID, cards = cards}
	return self.net:sendPacket(url, data, cb)
end

-- 普通勇者挑战 结束挑战
GameProtocol["/game/brave_challenge/battle/end"] = function(self, url, cb, battleID, floorID, result, cardStates, monsterStates, battleRound, damage, actions)
	local data = {battleID = battleID, floorID = floorID, result = result, cardStates = cardStates, monsterStates = monsterStates, battleRound = battleRound, damage = damage, actions = actions}
	return self.net:sendPacket(url, data, cb)
end

-- 普通勇者挑战 选择勋章
GameProtocol["/game/brave_challenge/badge/choose"] = function(self, url, cb, badgeID)
	local data = {badgeID = badgeID}
	return self.net:sendPacket(url, data, cb)
end

-- 普通勇者挑战 认输
GameProtocol["/game/brave_challenge/quit"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 普通勇者挑战 购买挑战次数
GameProtocol["/game/brave_challenge/buy"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- Z觉醒 培养
GameProtocol["/game/card/zawake/strength"] = function(self, url, cb, zawakeID, stage, level)
	local data = {zawakeID = zawakeID, stage = stage, level = level}
	return self.net:sendPacket(url, data, cb)
end

-- Z觉醒 重置
GameProtocol["/game/card/zawake/reset"] = function(self, url, cb, zawakeID)
	local data = {zawakeID = zawakeID}
	return self.net:sendPacket(url, data, cb)
end

-- Z觉醒 兑换
GameProtocol["/game/card/zawake/exchange"] = function(self, url, cb, csvID, cardID, fragID, num)
	local data = {csvID = csvID, cardID = cardID, fragID = fragID, num = num}
	return self.net:sendPacket(url, data, cb)
end

-- Z觉醒 退出
GameProtocol["/game/card/zawake/quit"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 五一派遣 开始
GameProtocol["/game/yy/dispatch/begin"] = function(self, url, cb, yyID, csvID, cards)
	local data = {yyID = yyID, csvID = csvID, cards = cards}
	return self.net:sendPacket(url, data, cb)
end

-- 五一派遣 结束
GameProtocol["/game/yy/dispatch/end"] = function(self, url, cb, yyID, csvID, flag)
	local data = {yyID = yyID, csvID = csvID, flag = flag}
	return self.net:sendPacket(url, data, cb)
end

-- 远征 main请求 （同步model客户端)
GameProtocol["/game/hunting/main"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 远征 选择线路开始
GameProtocol["/game/hunting/route/begin"] = function(self, url, cb, route)
	local data = {route = route}
	return self.net:sendPacket(url, data, cb)
end

-- 远征 手动结束线路
GameProtocol["/game/hunting/route/end"] = function(self, url, cb, route)
	local data = {route = route}
	return self.net:sendPacket(url, data, cb)
end

-- 远征 战斗关查看详情
GameProtocol["/game/hunting/battle/info"] = function(self, url, cb, route, node, gateID)
	local data = {route = route, node = node, gateID = gateID}
	return self.net:sendPacket(url, data, cb)
end

-- 远征 战斗关布阵
GameProtocol["/game/hunting/battle/deploy"] = function(self, url, cb, route, node, cardIDs)
	local data = {route = route, node = node, cardIDs = cardIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 远征 战斗关开始挑战
GameProtocol["/game/hunting/battle/start"] = function(self, url, cb, route, node, gateID, cardIDs)
	local data = {route = route, node = node, gateID = gateID, cardIDs = cardIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 远征 战斗关结束挑战
GameProtocol["/game/hunting/battle/end"] = function(self, url, cb, battleID, result, cardStates, enemyStates, damage)
	local data = {battleID = battleID, result = result, cardStates = cardStates, enemyStates = enemyStates, damage = damage}
	return self.net:sendPacket(url, data, cb)
end

-- 远征 战斗关选择buff（三选一）
GameProtocol["/game/hunting/battle/choose"] = function(self, url, cb, route, node, boardID)
	local data = {route = route, node = node, boardID = boardID}
	return self.net:sendPacket(url, data, cb)
end

-- 远征 宝箱关打开宝箱
GameProtocol["/game/hunting/box/open"] = function(self, url, cb, route, node)
	local data = {route = route, node = node}
	return self.net:sendPacket(url, data, cb)
end

-- 远征 手动往下一节点走（提供宝箱使用）
GameProtocol["/game/hunting/next"] = function(self, url, cb, route)
	local data = {route = route}
	return self.net:sendPacket(url, data, cb)
end


-- 远征 救援关补给
GameProtocol["/game/hunting/supply"] = function(self, url, cb, route, node, csvID, cardID)
	local data = {route = route, node = node, csvID = csvID, cardID = cardID}
	return self.net:sendPacket(url, data, cb)
end

-- 远征 组合关选择
GameProtocol["/game/hunting/board/choose"] = function(self, url, cb, route, node, boardID)
	local data = {route = route, node = node, boardID = boardID}
	return self.net:sendPacket(url, data, cb)
end

-- 远征 商店
GameProtocol["/game/hunting/shop"] = function(self, url, cb, csvID, count)
	local data = {csvID = csvID, count = count}
	return self.net:sendPacket(url, data, cb)
end

-- 芯片 洗练
GameProtocol["/game/card/chip/recast"] = function(self, url, cb, chip, pos1, pos2)
	local data = {chip = chip, pos1 = pos1 and (pos1-1), pos2 = pos2 and (pos2-1)}
	return self.net:sendPacket(url, data, cb)
end

-- 芯片 洗练重置
GameProtocol["/game/card/chip/recast/reset"] = function(self, url, cb, chip)
	local data = {chip = chip}
	return self.net:sendPacket(url, data, cb)
end

-- 芯片 抽取
GameProtocol["/game/lottery/chip/draw"] = function(self, url, cb, drawType, up)
	local data = {drawType = drawType, up = up}
	return self.net:sendPacket(url, data, cb)
end

-- 芯片 强化
GameProtocol["/game/card/chip/strength"] = function(self, url, cb, chip, costChips, costCsvIDs)
	local data = {chip = chip, costChips = costChips, costCsvIDs = costCsvIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 芯片 镶嵌更改
GameProtocol["/game/card/chip/change"] = function(self, url, cb, cardID, config)
	local data = {cardID = cardID, config = config}
	return self.net:sendPacket(url, data, cb)
end

-- 芯片锁定切换
GameProtocol["/game/card/chip/locked/switch"] = function(self, url, cb, chipID)
	local data={chipID = chipID}
	return self.net:sendPacket(url, data, cb)
end

-- 芯片重生
GameProtocol["/game/chip/rebirth"] = function(self, url, cb, chipIDs)
	local data={chipIDs = chipIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 芯片方案 新增
GameProtocol["/game/chip/plan/new"] = function(self, url, cb, chips, name)
	local data={chips = chips, name = name}
	return self.net:sendPacket(url, data, cb)
end

-- 芯片方案 编辑
GameProtocol["/game/chip/plan/edit"] = function(self, url, cb, id, chips, name, top)
	local data={id = id, chips = chips, name = name, top = top}
	return self.net:sendPacket(url, data, cb)
end

-- 芯片方案 删除
GameProtocol["/game/chip/plan/delete"] = function(self, url, cb, id)
	local data={id = id}
	return self.net:sendPacket(url, data, cb)
end

-- 刨冰 准备
GameProtocol["/game/yy/shaved_ice/prepare"] = function(self, url, cb, yyID)
	local data={yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 刨冰 开始需求
GameProtocol["/game/yy/shaved_ice/start"] = function(self, url, cb, yyID, idx)
	local data={yyID = yyID, idx = idx}
	return self.net:sendPacket(url, data, cb)
end

-- 刨冰 提交需求
GameProtocol["/game/yy/shaved_ice/end"] = function(self, url, cb, yyID, idx, choices, time)
	local data={yyID = yyID, idx = idx, choices = choices, time = time}
	return self.net:sendPacket(url, data, cb)
end

-- 刨冰 退出/结束
GameProtocol["/game/yy/shaved_ice/quit"] = function(self, url, cb, yyID)
	local data={yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 刨冰 购买次数
GameProtocol["/game/yy/shaved_ice/buy"] = function(self, url, cb, yyID)
	local data={yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 刨冰 排行
GameProtocol["/game/yy/shaved_ice/rank"] = function(self, url, cb, yyID)
	local data={yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 自选限定抽卡
GameProtocol["/game/lottery/card/up/draw"] = function(self, url, cb, drawType, choose)
	local data={drawType = drawType, choose = choose}
	return self.net:sendPacket(url, data, cb)
end

-- 自选限定抽卡up选择
GameProtocol["/game/lottery/card/up/choose"] = function(self, url, cb, choose)
	local data={choose = choose}
	return self.net:sendPacket(url, data, cb)
end

-- 战斗关碾压
GameProtocol["/game/hunting/battle/pass"] = function(self, url, cb, route, node, gateID)
	local data={route = route, node = node, gateID = gateID}
	return self.net:sendPacket(url, data, cb)
end

-- 沙滩排球开始战斗
GameProtocol["/game/yy/volleyball/start"] = function(self, url, cb, yyID)
	local data={yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 沙滩排球结束战斗
GameProtocol["/game/yy/volleyball/end"] = function(self, url, cb, yyID, result, duration, tasks)
	local data={yyID = yyID, result = result, duration = duration, tasks = tasks}
	return self.net:sendPacket(url, data, cb)
end

-- 沙滩排球排行榜
GameProtocol["/game/yy/volleyball/rank"] = function(self, url, cb, yyID)
	local data={yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 夏日挑战 开始挑战
GameProtocol["/game/yy/summer_challenge/battle/start"] = function(self, url, cb, yyID, gateID, cards)
	local data = {yyID = yyID, gateID = gateID, cards = cards}
	return self.net:sendPacket(url, data, cb)
end

-- 夏日挑战 结束挑战
GameProtocol["/game/yy/summer_challenge/battle/end"] = function(self, url, cb, battleID, gateID, result, actions, skills, choices)
	local data = {battleID = battleID, gateID = gateID, result = result, actions = actions, skills = skills, choices = choices}
	return self.net:sendPacket(url, data, cb)
end

-- 夏日挑战 选择buff
GameProtocol["/game/yy/summer_challenge/choose"] = function(self, url, cb, yyID, choiceID)
	local data = {yyID = yyID, choiceID = choiceID}
	return self.net:sendPacket(url, data, cb)
end


-- 打开家园
GameProtocol["/town/get"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 各建筑刷新
GameProtocol["/town/building/refresh"] = function(self, url, cb, buildingID)
	local data = {buildingID = buildingID}
	return self.net:sendPacket(url, data, cb)
end

-- 家园建筑升级
GameProtocol["/town/building/level/up"] = function(self, url, cb, buildingID)
	local data = {buildingID = buildingID}
	return self.net:sendPacket(url, data, cb)
end

-- 家园建筑立即完成
GameProtocol["/town/building/finish/atonce"] = function(self, url, cb, buildingID)
	local data = {buildingID = buildingID}
	return self.net:sendPacket(url, data, cb)
end

-- 家园小屋改名
GameProtocol["/town/home/rename"] = function(self, url, cb, name)
	local data = {name = name}
	return self.net:sendPacket(url, data, cb)
end

-- 家园应用小屋布局
GameProtocol["/town/home/layout/apply"] = function(self, url, cb, floor, layout)
	local data = {floor = floor, layout = layout}
	return self.net:sendPacket(url, data, cb)
end


-- 家园新增小屋布局方案
GameProtocol["/town/home/layout/save"] = function(self, url, cb, layout)
	local data = {layout = layout}
	return self.net:sendPacket(url, data, cb)
end

-- 家园更新小屋布局方案
GameProtocol["/town/home/layout/update"] = function(self, url, cb, layoutId, layout)
	local data = {layoutId = layoutId, layout = layout}
	return self.net:sendPacket(url, data, cb)
end

-- 家园删除小屋布局方案
GameProtocol["/town/home/layout/delete"] = function(self, url, cb, layoutId)
	local data = {layoutId = layoutId}
	return self.net:sendPacket(url, data, cb)
end

-- 家园小屋方案改名
GameProtocol["/town/home/layout/rename"] = function(self, url, cb, layoutId, name)
	local data = {layoutId = layoutId, name = name}
	return self.net:sendPacket(url, data, cb)
end

-- 家园卡牌休息
GameProtocol["/town/home/card/rest"] = function(self, url, cb, cardIds)
	local data = {cardIds = cardIds}
	return self.net:sendPacket(url, data, cb)
end

-- 家园卡牌从休息移除
GameProtocol["/town/home/card/remove"] = function(self, url, cb, cardIds)
	local data = {cardIds = cardIds}
	return self.net:sendPacket(url, data, cb)
end

-- 家园家具商店购买
GameProtocol["/town/home/shop/buy"] = function(self, url, cb, csvID, count)
	local data = {csvID = csvID, count = count}
	return self.net:sendPacket(url, data, cb)
end

GameProtocol["/game/yy/mid_autumn_draw/task_award/get"] = function(self, url, cb, yyID, csvID)
	local data={yyID = yyID, csvID = csvID}
	return self.net:sendPacket(url, data, cb)
end

GameProtocol["/game/yy/mid_autumn_draw/task_award/get/onekey"] = function(self, url, cb, yyID)
	local data={yyID = yyID}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服部屋 主界面main请求 
GameProtocol["/game/cross/union/fight/main"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服部屋 比赛中战报 获取  battleTypes={1: start, 2: start} 1=6V6  2=4V4  3=1V1
GameProtocol["/game/cross/union/fight/battle/result"] = function(self, url, cb, group, battleTypes)
	local data = {group = group, battleTypes = battleTypes}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服部屋 公会积分排行榜
GameProtocol["/game/cross/union/fight/point/rank"] = function(self, url, cb, offest, size)
	local data = {offest = offest, size = size}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服部屋 获取玩家阵容详情
GameProtocol["/game/cross/union/fight/role/info"] = function(self, url, cb, recordID)
	local data = {recordID = recordID}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服部屋 战斗布阵 (1=初赛 2=决赛) (1=6V6  2=4V4  3=1V1)
GameProtocol["/game/cross/union/fight/battle/deploy"] = function(self, url, cb, stage, deployType, battleCardIDs)
	local data = {stage = stage, deployType = deployType, battleCardIDs = battleCardIDs}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服部屋 战报回放
GameProtocol["/game/cross/union/fight/playrecord/get"] = function(self, url, cb, playID, crossKey)
	local data = {playID = playID, crossKey = crossKey}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服部屋 排行榜
GameProtocol["/game/cross/union/fight/rank"] = function(self, url, cb)
	local data = {}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服部屋 上期回顾 
GameProtocol["/game/cross/union/fight/last/battle"] = function(self, url, cb, group)
	local data = {group = group}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服部屋 竞猜界面信息 (1=初赛 2=决赛)
GameProtocol["/game/cross/union/fight/bet/info"] = function(self, url, cb, type)
	local data = {type = type}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服部屋 竞猜 （group组别，决赛用5）
GameProtocol["/game/cross/union/fight/bet"] = function(self, url, cb, group, unionID)
	local data = {group = group, unionID = unionID}
	return self.net:sendPacket(url, data, cb)
end

-- 跨服部屋 获取战场分布
GameProtocol["/game/cross/union/fight/deploy/roles"] = function(self, url, cb, stage, unionID)
	local data = {stage = stage, unionID = unionID}
	return self.net:sendPacket(url, data, cb)
end

-- 定制礼包
GameProtocol["/game/yy/customize/gift"] = function(self, url, cb, yyID, csvID, choose)
	local data = {yyID = yyID, csvID = csvID, choose = choose}
	return self.net:sendPacket(url, data, cb)
end

return GameProtocol