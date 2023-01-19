--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- lp
--

local lp_kr = {}

-- 1.如果用户是第一次登录，则系统将进入登录界面。
-- 2.如果用户已经登录过则系统将根据前一次的设置信息判断是否自动登录:若自动登录则系统 将进行自动登录;若不是自动登录则系统将进入登录界面。
-- 3.用户可以选择输入已有的用户名和密码进行登录，也可以进入注册界面重新注册新账号，登 录及注册界面的具体功能和操作可以进入登录和注册界面查看。
function lp_kr.login(cb)
	print("Lua lp.login")
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
function lp_kr.commitRoleInfo(ctype, cb)
	print("Lua lp.commitRoleInfo")
	-- ctype > 50 为韩国的额外的接口,只需要ctype 值
	local tmp = {}
	if ctype < 50 then
		tmp = {
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
	else
		tmp = {
			ctype = ctype
		}
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
function lp_kr.trackEvent(ctype, data)
	print("Lua lp.trackEvent")
	if type(data) ~= "table" then
		data = {data = data}
	end
	data.ctype = ctype
	data.event = eventMap[ctype] or ""
	sdk.callPlatformFunc("trackEvent", json.encode(data), function(info)
		print("trackEvent ret = ", info)
	end)
end

function lp_kr.logout(cb)
	print("Lua lp.logout")
	sdk.callPlatformFunc("logout", "game", function(info)
		print("logout ret = ", info)
		-- 有回调就是成功
		cb(0, "ok")
	end)
end

-- 1. 由于app store应用内支付功能的限制，越狱设备在进行应用内购买时无法支付成功， SDK将消除loading并返回支付失败。
-- 2. 网游支付务必以服务端支付结果为准。
-- 3. 母包包含自有渠道支付与appStore支付，支付方式按照包名，版本号，商品ID动态配置


-- lp_kr Android
-- 内购商品名称	内购商品ID	   韩币
-- 66钻石	jxkrfc_money_1     1300
-- 140钻石	jxkrfc_money_2     2800
-- 200钻石	jxkrfc_money_3     4000
-- 260钻石	jxkrfc_money_4     5300
-- 340钻石	jxkrfc_money_5     7000
-- 580钻石	jxkrfc_money_6     12000
-- 860钻石	jxkrfc_money_7     17000
-- 980钻石   jxkrfc_money_8     20000
-- 1340钻石  jxkrfc_money_9     26000
-- 1740钻石  jxkrfc_money_10    34000
-- 1980钻石  jxkrfc_money_11    40000
-- 3380钻石  jxkrfc_money_12    70000
-- 6580钻石  jxkrfc_money_13    130000

-- 安卓
-- B1   com.jka.jxkr.first 		 com_jka_jxkr_first         포켓 트레이너			提审
-- B2   com.ptjx.krmp.two 		 com_ptjx_krmp_two          포켓 트레이너			提审

local defaultPrefix = {"jxkrfc_money_", 1}

local productPrefixTagMap = {
	com_mccjh_mccjh_1 = defaultPrefix,
	lp_kr = {"jxkrfc_money_", 1},
	com_jka_jxkr_first = {"com.jka.jxkr.first_", 1},
	com_ptjx_krmp_two = {"com.ptjx.krmp.two_", 1},
}

-- !!! 需要自己解决多次充值请求问题
-- sdk后续没有界面，是在等待苹果系统支付界面
-- 回调也是在支付成功或者失败后返回
-- 即使请求超时也会有回调，但是网络不好，可能苹果系统拉起支付比较慢
-- 为了不阻断用户操作，并没有锁死UI
function lp_kr.pay(cpOrderId, extInfo, amount, rechargeId, productDesc, cb)
	print("Lua lp.pay")
	local roleInfo = gGameModel.role
	local productID

	-- 相同channel不同包，根据tag来判断productID
	local prefix, startID = unpack(productPrefixTagMap[APP_TAG] or defaultPrefix)
	if rechargeId >= 4100 then
		productID = prefix .. (rechargeId - 4100)
	elseif rechargeId >= 108 then
		productID = prefix .. (rechargeId - 100)
	elseif rechargeId > 100 then
		productID = prefix .. (rechargeId - 101)
	elseif rechargeId >= 3 then
		productID = prefix .. (startID + 9 - rechargeId)
	else
		productID = prefix .. (2 * rechargeId + 3)
	end
	local tmp = {
		roleId = stringz.bintohex(roleInfo:read("id")),
		roleName = roleInfo:read("name"),
		roleLevel = tostring(roleInfo:read("level")),
		area = gGameApp.serverInfo.name,
		area_id = tostring(roleInfo:read("area")),
		rmb = amount,
		amount = amount/10,
		count = 1,
		extInfo = extInfo,
		productDesc = productDesc,
		currency = "₩",
		productName = productDesc,
		-- productID = "com.de.dgf"   --TEST
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

return lp_kr


