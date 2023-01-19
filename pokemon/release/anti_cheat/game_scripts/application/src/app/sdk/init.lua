--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- sdk相关
-- 不同sdk，通过spec实现
--

require "app.sdk.helper"

-- 回调在渠道后台固定配置
sdk.ORDER_URL = "http://123.207.108.22:28081"
sdk.ORDER_SIGN_SECRET = 'tianji'

-- 实名注册信息缓存
local AgeCached
local UserTypeCached

function sdk.login(cb)
	if not sdk.spec then
		return cb()
	end
	-- 切换账号，清理实名信息缓存
	AgeCached, UserTypeCached = nil, nil
	return sdk.spec.login(function(code, info)
		cb(code, info)

		if code == 0 then
			-- 获取实名信息
			sdk.getUserTypeAndIdentity()
		end
	end)
end

-- sdk login获得token，并不是uid
-- 等/login/check返回后拿到account model之后处理
function sdk.onLogin(accountName)
	-- 暂时先不管
	do return end

	local flag = userDefault.getForeverLocalKey(accountName .. "_guestDisable", "no", {rawKey = true})
	if flag == os.date("%Y%m%d") then
		printWarn("you was guest, plz register and identify yourself")
		gGameUI:showTip("you was guest, plz register and identify yourself")
		performWithDelay(gGameUI.scene, function()
			gGameApp:onBackLogin()
		end, 1)
	end
end

-- type类型
-- 进入游戏：1
-- 等级提升：2
-- 退出游戏：3
-- 创建角色：4
-- 登出游戏：5
-- 新手引导结束：6
-- 其他需求：7
-- 修改角色名：8
function sdk.commitRoleInfo(ctype, cb)
	if not sdk.spec then
		return cb()
	end
	return sdk.spec.commitRoleInfo(ctype, cb)
end

-- 事件上报
-- 游戏加载资源之前：1
-- 游戏加载资源完成：2
function sdk.trackEvent(ctype, data)
	if device.platform == "windows" then
		return
	end
	if not sdk.spec or not sdk.spec.trackEvent then
		return
	end
	return sdk.spec.trackEvent(ctype, data)
end

-- 生成随机订单
local function getCpOrderId()
	local roleId = stringz.bintohex(gGameModel.role:read("id"))
	return string.format("%s%s", roleId, os.time())
end

-- 非注册用户：体验不超过1小时，不能充值不能付费
-- 注册用户：未成年不提供游戏服务付费限制
local function getUserRechargeLimit(typ, age)
	if typ == 0 or age <= 8 then
		return 0
	end
	if age < 16 then
		return 50
	end
	if age < 18 then
		return 100
	end
	return 1e99
end

-- 订单的创建也转移到 java 那一层
-- @params {rechargeId, yyID, csvID, name}
-- function sdk.pay(cpOrderId, extInfo, amount, rechargeId, productDesc, cb)
function sdk.pay(params, cb)
	cb = cb or function() end
	if not sdk.spec then
		return cb()
	end

	local rechargeId = params.rechargeId
	local yyID = params.yyID or 0
	local csvID = params.csvID or 0
	local accountId = stringz.bintohex(gGameModel.role:read("account_id"))
	local roleId = stringz.bintohex(gGameModel.role:read("id"))
	local payInfo = csv.recharges[rechargeId]
	local extInfo = json.encode({
		accountId,
		roleId,
		gGameApp.serverInfo.key,
		rechargeId,
		yyID,
		csvID,
	})

	return sdk.spec.pay(getCpOrderId(), extInfo, tonumber(payInfo.rmb), rechargeId, params.name or payInfo.name, cb)

	-- 暂时先不管
	-- sdk.queryUserType(function(typ)
	-- 	sdk.queryIdentity(function(age)
	-- 		-- 非注册用户：体验不超过1小时，不能充值不能付费
	-- 		if typ == 0 then
	-- 			printWarn("you was guest, plz register and identify yourself")
	-- 			gGameUI:showTip("you was guest, plz register and identify yourself")
	-- 			return cb(-1, "error")
	-- 		end

	-- 		local limit = getUserRechargeLimit(typ, age)
	-- 		local recharges = gGameModel.role:read("recharges")
	-- 		local rmb = 0
	-- 		for idx, t in pairs(recharges) do
	-- 			local cfg = csv.recharges[idx]
	-- 			if cfg then
	-- 				local cnt = t.cnt or 0
	-- 				-- 简单用了rmbDisplay，只有国内才有限制
	-- 				rmb = rmb + cnt * tonumber(cfg.rmbDisplay or "0")
	-- 			end
	-- 		end
	-- 		print('!!!! rmb limit', rmb, limit)
	-- 		if rmb > limit then
	-- 			printWarn("you recharge too much, young man")
	-- 			gGameUI:showTip("you recharge too much, young man")
	-- 			return cb(-1, "error")
	-- 		end

	-- 		return sdk.spec.pay(getCpOrderId(), extInfo, tonumber(payInfo.rmb), rechargeId, params.name or payInfo.name, cb)
	-- 	end)
	-- end)
end

-- 主动注销退出账号
-- 被动通知需放在sdk.login，参考tc
function sdk.logout(cb)
	if not sdk.spec then
		return cb()
	end
	return sdk.spec.logout(cb)
end

function sdk.exit(cb)
	if not sdk.spec then
		return cb()
	end

	display.director:endToLua()

	-- if exits[APP_CHANNEL] then exits[APP_CHANNEL](cb) return end

	-- local pp = g_gameUI:showVerifyPanel(function()
	-- 	cc.Director:getInstance():endToLua()
	-- end,gLanguageCsv.make_sure_exit_game)

	-- createTKAction(pp)
end

-- TODO: 存在第三方sdk，所以接入的sdk和渠道不一定相同
function sdk.getChannel(userName)
	if not sdk.spec or not sdk.spec.getChannel then
		return APP_CHANNEL
	end
	return sdk.spec.getChannel(userName)
end

-- 防沉迷，身份信息，成年/未成年
-- @return int年龄
local MaxAge = 999
function sdk.queryIdentity(cb)
	if AgeCached then
		return cb(AgeCached)
	end

	if not sdk.spec or not sdk.spec.queryIdentity then
		-- AgeCached = MaxAge
		return cb(MaxAge)
	end

	return sdk.spec.queryIdentity(function(age)
		if age and age > 0 then
			AgeCached = age
		end
		return cb(AgeCached)
	end)
end

-- 防沉迷，用户类型, 游客/非游客
-- 实名注册后就是非游客
-- @return userType == 0 游客，userType == 1 非游客
function sdk.queryUserType(cb)
	if UserTypeCached then
		return cb(UserTypeCached)
	end

	if not sdk.spec or not sdk.spec.queryUserType then
		UserTypeCached = 1
		return cb(UserTypeCached)
	end

	return sdk.spec.queryUserType(function(typ)
		-- 暂时先不管
		do return cb(UserTypeCached) end

		UserTypeCached = typ or 1
		-- 游客体验不能超过1个小时，不能充值付费
		if UserTypeCached == 0 then
			performWithDelay(gGameUI.scene, function()
				-- check again
				sdk.spec.queryUserType(function(typ)
					UserTypeCached = typ or 1
					if UserTypeCached == 0 then
						local accountName = gGameModel.account:read("name")
						userDefault.setForeverLocalKey(accountName .. "_guestDisable", os.date("%Y%m%d"), {rawKey = true})

						printWarn("you was guest, plz register and identify yourself")
						gGameUI:showTip("you was guest, plz register and identify yourself")
						performWithDelay(gGameUI.scene, function()
							gGameApp:onBackLogin()
						end, 5)
					end
				end)
			end, 50*60) -- 50*60
		end
		return cb(UserTypeCached)
	end)
end

-- query接口在login时异步获取
-- get接口是给后续逻辑直接同步获得用
function sdk.getUserTypeAndIdentity()
	if UserTypeCached == nil then
		sdk.queryUserType(function()end)
	end
	if AgeCached == nil then
		sdk.queryIdentity(function()end)
	end
	return UserTypeCached, AgeCached
end

function sdk.openCustomerService()
	if not sdk.spec or not sdk.spec.openCustomerService then
		return
	end
	return sdk.spec.openCustomerService()
end

function sdk.openPrivacyProtocols()
	if not sdk.spec or not sdk.spec.openPrivacyProtocols then
		return
	end
	return sdk.spec.openPrivacyProtocols()
end

function sdk.openPermissionSetting()
	if not sdk.spec or not sdk.spec.openPermissionSetting then
		return
	end
	return sdk.spec.openPermissionSetting()
end

local function init()
	if device.platform ~= "windows" and device.platform ~= "mac" then
		sdk.isHasNotchScreen(function(info)
			if info == 1 then
				display.notchSceenSafeArea = display.fullScreenSafeArea
				display.notchSceenDiffX = display.fullScreenDiffX
				printInfo("# display.notchSceenSafeArea changed   = %d", display.notchSceenSafeArea)
				printInfo("# display.notchSceenDiffX changed      = %d", display.notchSceenDiffX)
			end
		end)
	end

	if APP_CHANNEL == nil then return end

	local ok, ret = pcall(require, "app.sdk." .. string.lower(APP_CHANNEL))
	if ok then
		sdk.spec = ret
		printInfo(string.lower(APP_CHANNEL), "sdk inited")
	else
		printWarn(ret)
	end
end

init()
