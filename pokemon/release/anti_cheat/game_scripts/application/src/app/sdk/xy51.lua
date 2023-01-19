--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- xy51
--

local xy51 = {}

-- 1.如果用户是第一次登录，则系统将进入登录界面。
-- 2.如果用户已经登录过则系统将根据前一次的设置信息判断是否自动登录:若自动登录则系统 将进行自动登录;若不是自动登录则系统将进入登录界面。
-- 3.用户可以选择输入已有的用户名和密码进行登录，也可以进入注册界面重新注册新账号，登 录及注册界面的具体功能和操作可以进入登录和注册界面查看。
function xy51.login(cb)
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
	[8] = "ChangeName",
}
function xy51.commitRoleInfo(ctype, cb)
	local tmp = {
		ctype = ctype,
		area = gGameApp.serverInfo.name,
		level = tostring(gGameModel.role:read("level")),
		area_id = tostring(gGameModel.role:read("area")),
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
function xy51.trackEvent(ctype, data)
	if type(data) ~= "table" then
		data = {data = data}
	end
	data.ctype = ctype
	data.event = eventMap[ctype] or ""
	sdk.callPlatformFunc("trackEvent", json.encode(data), function(info)
		print("trackEvent ret = ", info)
	end)
end

function xy51.logout(cb)
	sdk.callPlatformFunc("logout", "game", function(info)
		print("logout ret = ", info)
		-- 有回调就是成功
		cb(0, "ok")
	end)
end

-- 1. 由于app store应用内支付功能的限制，越狱设备在进行应用内购买时无法支付成功， SDK将消除loading并返回支付失败。
-- 2. 网游支付务必以服务端支付结果为准。
-- 3. 母包包含自有渠道支付与appStore支付，支付方式按照包名，版本号，商品ID动态配置


-- BundleID：	com.mccjh.mccjh 安卓
-- 内购商品名称	内购商品ID	CNY
-- 月卡	com.mccjh.mccjh.1	25
-- 终身月卡	com.mccjh.mccjh.2	88
-- 60钻石	com.mccjh.mccjh.3	6
-- 300钻石	com.mccjh.mccjh.4	30
-- 680钻石	com.mccjh.mccjh.5	60
-- 980钻石	com.mccjh.mccjh.6	98
-- 1980钻石	com.mccjh.mccjh.7	198
-- 3280钻石	com.mccjh.mccjh.8	328
-- 6480钻石	com.mccjh.mccjh.9	648


-- iOS
-- TF包 com.jiaowan.kdjx com_jiaowan_kdjx 口袋觉醒 企业签名
-- TF包 com.jiaowan.kdjxios com_jiaowan_kdjxios 口袋觉醒 企业签名

local defaultPrefix = {"com.mccjh.mccjh.", 3}

local productPrefixTagMap = {
	com_mccjh_mccjh_1 = defaultPrefix,
	com_jiaowan_kdjx = {"com.jiaowan.kdjx.", 3},
	com_jiaowan_kdjxios = {"com.jiaowan.kdjxios.", 3},
}

local specialProductTagMap = {

}


local function specialProductID(rechargeId)
	local special = specialProductTagMap[APP_TAG]
	if special == nil then return end
	return special[rechargeId]
end

-- !!! 需要自己解决多次充值请求问题
-- sdk后续没有界面，是在等待苹果系统支付界面
-- 回调也是在支付成功或者失败后返回
-- 即使请求超时也会有回调，但是网络不好，可能苹果系统拉起支付比较慢
-- 为了不阻断用户操作，并没有锁死UI
function xy51.pay(cpOrderId, extInfo, amount, rechargeId, productDesc, cb)
	-- 体验服
	if "tiyan_test" == APP_TAG then
		cb(-1, "error")
		return
	end

	local roleInfo = gGameModel.role

	-- 相同channel不同包，根据tag来判断productID
	local prefix, startID = unpack(productPrefixTagMap[APP_TAG] or defaultPrefix)
	local productID = specialProductID(rechargeId)

	local desc = productDesc
	-- productDescription字段的传值，礼包的描述修改为gift，钻石的描述修改为gem
	-- 我们通过这个值来区分是钻石还是礼包，因为现在商品id复用，需要用其他参数来区分



	if productID == nil then
		if rechargeId >= 101 then
			productID = prefix .. rechargeId
		elseif rechargeId >= 3 then
			productID = prefix .. (startID + 9 - rechargeId)
		else
			productID = prefix .. rechargeId
		end
	end

	local tmp = {
		-- roleId = stringz.bintohex(roleInfo:read("id")),
		roleId = tostring(roleInfo:read("uid")),
		roleName = roleInfo:read("name"),
		roleLevel = tostring(roleInfo:read("level")),
		vip = tostring(roleInfo:read("vip_level")),
		area = gGameApp.serverInfo.name,
		area_id = tostring(roleInfo:read("area")),
		rmb = amount,
		amount = amount/10,
		count = 1,
		extInfo = extInfo,
		productDesc = desc,
		currency = "cny", -- 人民币：cny
		productName = productDesc,
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

-- 1.检查账号类型接口返回失败的情况下，请重新调用接口3次，接口间隔建议为1分钟，如果3次请求都返回失败，则认为是游客账号
-- 2.实名认证接口，在未弹出实名认证界面的情况下返回 失败回调，请重新调用接口3次，接口间隔建议为1分钟，如果3次请求都返回失败，则认为未实名
-- 3.建议游戏也需要控制相关时长功能的限制开关

local SkipIdentityTag = {
	android_17849_20200218 = true,
	android_10054_20191230 = true,
	android_10054 = true,
}

-- 防沉迷，身份信息，成年/未成年
-- @return nil未实名，int年龄
function xy51.queryIdentity(cb, count)
	if SkipIdentityTag[APP_TAG] or device.platform ~= "android" then
		return cb(nil)
	end

	count = (count or 0) + 1
	if count > 3 then
		return cb(0)
	end

	-- TODO: 旧包没有相关接口不会报错，但逻辑上需要处理成已注册用户

	sdk.callPlatformFunc("queryIdentity", "", function(age)
		print("queryIdentity ret = ", age)
		if age == "error" then
			performWithDelay(gGameUI.scene, function()
				xy51.queryIdentity(cb, count)
			end, 60)
		elseif age == "closed" then
			cb(nil)
		else
			cb(tonumber(age))
		end
	end)
end

-- 防沉迷，用户类型, 游客/非游客
-- 实名注册后就是非游客
-- @return userType == 0 游客，userType == 1 非游客
function xy51.queryUserType(cb, count)
	if SkipIdentityTag[APP_TAG] or device.platform ~= "android" then
		return cb(nil)
	end

	count = (count or 0) + 1
	if count > 3 then
		return cb(0)
	end

	sdk.callPlatformFunc("queryUserType", "", function(typ)
		print("queryUserType ret = ", typ)
		if typ == "error" then
			performWithDelay(gGameUI.scene, function()
				xy51.queryUserType(cb, count)
			end, 60)
		elseif typ == "closed" then
			cb(nil)
		else
			-- TODO: 游客转注册用户
			cb(tonumber(typ))
		end
	end)
end

function xy51.openCustomerService()
	sdk.callPlatformFunc("openCustomerService", "", function(info)
		print("openCustomerService ret = ", info)
	end)
end

function xy51.openPrivacyProtocols()
	sdk.callPlatformFunc("openPrivacyProtocols","",function(info)
		print("openPrivacyProtocols ret = ",info)
	end)
end

function xy51.openPermissionSetting()
	sdk.callPlatformFunc("openPermissionSetting","",function(info)
		print("openPermissionSetting ret = ",info)
	end)
end

-- 小y，专服，用cn的version，代码里直接替换login ip
globals.VERSION_CONF_URL = "http://124.71.138.126:18080/version"
globals.SERVER_CONF_URL = "http://124.71.138.126:18080/servers"
globals.NOTICE_CONF_URL = "http://124.71.138.126:18080/notice"
globals.LOGIN_SERVRE_HOSTS_TABLE = {"124.71.138.126:16666"}
if next(LOGIN_SERVRE_HOSTS_TABLE) then
	globals.IPV6_TEST_HOST = string.gmatch(LOGIN_SERVRE_HOSTS_TABLE[1], '([-a-z0-9A-Z.]+):(%d+)')()
end

return xy51


