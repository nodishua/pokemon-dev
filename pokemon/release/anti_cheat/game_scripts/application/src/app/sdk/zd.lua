--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- zd
--

local zd = {}

-- 1.如果用户是第一次登录，则系统将进入登录界面。
-- 2.如果用户已经登录过则系统将根据前一次的设置信息判断是否自动登录:若自动登录则系统 将进行自动登录;若不是自动登录则系统将进入登录界面。
-- 3.用户可以选择输入已有的用户名和密码进行登录，也可以进入注册界面重新注册新账号，登 录及注册界面的具体功能和操作可以进入登录和注册界面查看。
function zd.login(cb)
	sdk.callPlatformFunc("login", "", function(info)
		print("login ret = ", info)
		if info == "error" then
			cb(-1, info)
		elseif info == "cancel" then
			cb(-1, info)
		else
			cb(0, info)
			-- 漂浮球退出监听
			sdk.callPlatformFunc("logout", "assist", function(info)
				print("logout in assist ret = ", info)
				-- 内部保证多次调用无误
				gGameApp:onBackLogin()
			end)
		end
	end)
end

local roleInfoMap = {
	[1] = "EnterServer",
	[2] = "LevelUp",
	[3] = "ExitGame",
	[4] = "CreateRole",
	[6] = "NewbieGuideEnd",
	[8] = "ChangeName",
}
function zd.commitRoleInfo(ctype, cb)
	print("cctest ctype is %d",ctype)
	local tmp = {
		ctype = ctype,
		area = gGameApp.serverInfo.name,
		level = tostring(gGameModel.role:read("level")),
        area_id = 999, -- TEST
		--area_id = tostring(gGameModel.role:read("area")),
		user_name = gGameModel.role:read("name"),
		user_id = tostring(gGameModel.role:read("uid")),
		vip = tostring(gGameModel.role:read("vip_level")),
		created_time = tostring(gGameModel.role:read("created_time")),
		upload_type = roleInfoMap[ctype],
	}
	if tmp.upload_type == nil then
		return cb(0, "ok")
	end

	sdk.callPlatformFunc("commitRoleInfo", json.encode(tmp), function(info)
		print("commitRoleInfo ret = ", info)
		-- 没有返回值，不管成功失败
		cb(0, "ok")
	end)
end

local eventMap = {
	[1] = "EVENTS_START_LOADING",
	[2] = "EVENTS_FINISHED_LOADING",
}
function zd.trackEvent(ctype, data)
	if type(data) ~= "table" then
		data = {data = data}
	end
	data.ctype = ctype
	data.event = eventMap[ctype] or ""
	sdk.callPlatformFunc("trackEvent", json.encode(data), function(info)
		print("trackEvent ret = ", info)
	end)
end

function zd.logout(cb)
	sdk.callPlatformFunc("logout", "game", function(info)
		print("logout ret = ", info)
		-- 有回调就是成功
		cb(0, "ok")
	end)
end

-- 1. 由于app store应用内支付功能的限制，越狱设备在进行应用内购买时无法支付成功， SDK将消除loading并返回支付失败。
-- 2. 网游支付务必以服务端支付结果为准。
-- 3. 母包包含自有渠道支付与appStore支付，支付方式按照包名，版本号，商品ID动态配置

-- BundleID：	com.tiji.kd 卓动
-- 内购商品名称	内购商品ID	CNY
-- 月卡		com.tiji.kd.mc		25
-- 终身月卡	com.tiji.kd.mc1		88
-- 6480钻石	com.tiji.kd.6480	648
-- 3280钻石	com.tiji.kd.3280	328
-- 1980钻石	com.tiji.kd.1980	198
-- 980钻石	com.tiji.kd.980		98
-- 680钻石	com.tiji.kd.600		60
-- 300钻石	com.tiji.kd.300		30
-- 60钻石	com.tiji.kd.60		6
--
-- ---------------	直购礼包1	"1"
-- com.tiji.kd.zg1	直购礼包6	"6"
-- com.tiji.kd.zg2	直购礼包12	"12"
-- com.tiji.kd.zg3	直购礼包18	"18"
-- com.tiji.kd.zg4	直购礼包25	"25"
-- com.tiji.kd.zg5	直购礼包30	"30"
-- com.tiji.kd.zg6	直购礼包60	"60"
-- com.tiji.kd.zg7	直购礼包98	"98"
-- com.tiji.kd.zg8	直购礼包128	"128"
-- com.tiji.kd.zg9	直购礼包168	"168"
-- com.tiji.kd.zg10	直购礼包198	"198"
-- com.tiji.kd.zg11	直购礼包328	"328"
-- com.tiji.kd.zg12	直购礼包648	"648"

local defaultPrefix = {"com.tiji.kd.", 3}

local productPrefixTagMap = {
	zd_en = defaultPrefix,
}

-- !!! 需要自己解决多次充值请求问题
-- sdk后续没有界面，是在等待苹果系统支付界面
-- 回调也是在支付成功或者失败后返回
-- 即使请求超时也会有回调，但是网络不好，可能苹果系统拉起支付比较慢
-- 为了不阻断用户操作，并没有锁死UI
function zd.pay(cpOrderId, extInfo, amount, rechargeId, productDesc, cb)
	local roleInfo = gGameModel.role
	local productID
	-- 相同channel不同包，根据tag来判断productID
	local prefix, startID = unpack(productPrefixTagMap[APP_TAG] or defaultPrefix)
	if rechargeId >= 101 then
		productID = prefix .. "zg" .. (rechargeId - 101)

	elseif rechargeId == 1 then
		productID = prefix .. "mc"

	elseif rechargeId == 2 then
		productID = prefix .. "mc1"
	else
		productID = prefix .. amount
	end
	print("!!!zd.pay:", rechargeId, "|", productID)
	local tmp = {
		-- roleId = stringz.bintohex(roleInfo:read("id")),
		roleId = tostring(roleInfo:read("uid")),
		roleName = roleInfo:read("name"),
		roleLevel = tostring(roleInfo:read("level")),
		area = gGameApp.serverInfo.name,
		area_id = tostring(roleInfo:read("area")),
		rmb = amount,
		amount = amount/10,
		count = 1,
		extInfo = extInfo,
		productDesc = productDesc,
		currency = "cny", -- 人民币：cny
		productName = productDesc,
		OrderId = cpOrderId,
		-- productID = "com.gavegame.applepaytest.6", -- TEST:
		productID = productID,
	}

	sdk.callPlatformFunc("pay", json.encode(tmp), function(info)
		print("pay ret = ", info)
		if info == "ok" then
			cb(0, info)
		else
			cb(-1, "error")
		end
	end)
end

return zd




