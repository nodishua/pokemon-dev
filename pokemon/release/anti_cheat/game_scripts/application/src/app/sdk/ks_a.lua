--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ks_a
--

local ks_a = {}

-- 1.如果用户是第一次登录，则系统将进入登录界面。
-- 2.如果用户已经登录过则系统将根据前一次的设置信息判断是否自动登录:若自动登录则系统 将进行自动登录;若不是自动登录则系统将进入登录界面。
-- 3.用户可以选择输入已有的用户名和密码进行登录，也可以进入注册界面重新注册新账号，登 录及注册界面的具体功能和操作可以进入登录和注册界面查看。
function ks_a.login(cb)
	print("Lua ks_a.login")
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
	[1] = "SUBMIT_TYPE_ENTER",
	[2] = "SUBMIT_TYPE_UPGRADE",
	[4] = "SUBMIT_TYPE_CREATE",
	[8] = "SUBMIT_TYPE_UPDATE",
}
function ks_a.commitRoleInfo(ctype, cb)
	print("Lua ks_a.commitRoleInfo")
	local tmp = {
		ctype = ctype,
		area = gGameApp.serverInfo.name,
		level = tostring(gGameModel.role:read("level")),
		area_id = tostring(gGameModel.role:read("area")),
		role_id = stringz.bintohex(gGameModel.role:read("id")),
		role_name = gGameModel.role:read("name"),
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
function ks_a.trackEvent(ctype, data)
	print("Lua ks_a.trackEvent")
	if type(data) ~= "table" then
		data = {data = data}
	end
	data.ctype = ctype
	data.event = eventMap[ctype] or ""
	sdk.callPlatformFunc("trackEvent", json.encode(data), function(info)
		print("trackEvent ret = ", info)
	end)
end

function ks_a.logout(cb)
	print("Lua ks_a.logout")
	sdk.callPlatformFunc("logout", "game", function(info)
		print("logout ret = ", info)
		-- 有回调就是成功
		cb(0, "ok")
	end)
end

-- 1. 由于app store应用内支付功能的限制，越狱设备在进行应用内购买时无法支付成功， SDK将消除loading并返回支付失败。
-- 2. 网游支付务必以服务端支付结果为准。
-- 3. 母包包含自有渠道支付与appStore支付，支付方式按照包名，版本号，商品ID动态配置


-- 安卓 tag: com_jljxm_google 
-- 内购商品名称	内购商品ID	   美元    
-- 66 钻石       526           0.99
-- 140 钻石      527           1.99
-- 200 钻石      528           2.99
-- 260 钻石      529           3.99
-- 340 钻石      530           4.99
-- 580           531           8.99
-- 860           532           12.99
-- 980           533           14.99
-- 1340          534           19.99
-- 1740          535           25.99
-- 1980          536           29.99
-- 3380          537           49.99
-- 6580          538           99.99

-- 安卓#2	com.jljxm.google   com_jljxm_google  冒險啟程：z世代	  过包
-- 安卓#3	com.sbhx.google	   com_sbhx_google     神寶幻想        提审
-- 安卓#5	com.mcdzz.google   com_mcdzz_google  萌寵大作戰      过包
-- 安卓#6	com.mbdmx.google   com_mbdmx_google  萌寵大作戰      过包
-- 安卓#7	com.magiclk.google   com_magiclk_google  神寶裂空傳      提审
-- 安卓#8	com.sbxxs.google   com_sbxxs_google  神寶馴獸師      提审
-- 安卓#9	com.ssjxsmash.google   com_ssjxsmash_google  神獸覺醒：Smash!      提审
-- 安卓#10	com.ssqyjb.google      com_ssqyjb_google     神獸起源：羈絆        提审
-- 安卓#12	com.sbcnd.google       com_sbcnd_google      神寶超能隊            提审
-- 安卓#13	com.ssdsstorm.google   com_ssdsstorm_google  神獸導師：Storm       提审
-- 安卓#14	com.sbdljx.google      com_sbdljx_google     神寶超能隊            提审
-- 安卓#15	com.ssjfz.google       com_ssjfz_google      神獸傳奇：新篇章       提审
-- 安卓#16	com.sbqsl.google       com_sbqsl_google      神寶啟示錄       	  提审
-- 安卓#18	com.ssayqj.google      com_ssayqj_google     神獸奧義：奇跡         提审

local defaultPrefix = {"com.jljxm.google",538}

local productPrefixTagMap = {
	com_jljxm_google = {"com.jljxm.google",538},
	com_sbhx_google = {"com.sbhx.google",700},
	com_mcdzz_google = {"com.mcdzz.google",713},
	com_mbdmx_google = {"com.mbdmx.google",823},
	com_magiclk_google = {"com.magiclk.google",853},
	com_ssjxsmash_google = {"com.ssjxsmash.google",866},
	com_sbxxs_google = {"com.sbxxs.google",879},
	com_ssqyjb_google = {"com.ssqyjb.google",905},
	com_sbcnd_google = {"com.sbcnd.google",918},
	com_sbdljx_google = {"com.sbdljx.google",947},
	com_ssdsstorm_google = {"com.ssdsstorm.google",961},
	com_ssjfz_google = {"com.ssjfz.google",1021},
	com_sbqsl_google = {"com.sbqsl.google",1073},
	com_ssayqj_google = {"com.ssayqj.google",1099},
}

-- !!! 需要自己解决多次充值请求问题
-- sdk后续没有界面，是在等待苹果系统支付界面
-- 回调也是在支付成功或者失败后返回
-- 即使请求超时也会有回调，但是网络不好，可能苹果系统拉起支付比较慢
-- 为了不阻断用户操作，并没有锁死UI
function ks_a.pay(cpOrderId, extInfo, amount, rechargeId, productDesc, cb)
	print("Lua ks_a.pay")
	local roleInfo = gGameModel.role
	local productID
	local payInfo = csv.recharges[rechargeId]

	-- 相同channel不同包，根据tag来判断productID
	local prefix, startID = unpack(productPrefixTagMap[APP_TAG] or defaultPrefix)

	if rechargeId >= 1100 then
		productID = rechargeId - 1100 + startID
	elseif rechargeId >= 108 then
		productID = rechargeId - 100 + startID
	elseif rechargeId > 100 then
		productID = rechargeId - 101 + startID
	else
		productID = rechargeId * 2 + 3 + startID
	end


	local tmp = {
		roleId = stringz.bintohex(roleInfo:read("id")),
		roleName = roleInfo:read("name"),
		roleLevel = tostring(roleInfo:read("level")),
		area = gGameApp.serverInfo.name,
		area_id = tostring(roleInfo:read("area")),
		rmb = amount,
		rmbDisplay = payInfo.rmbDisplay,
		amount = amount/10,
		count = 1,
		extInfo = extInfo,
		productDesc = productDesc,
		currency = "cny", -- 人民币：cny
		productName = productDesc,
		-- productID = "com.gavegame.applepaytest.6", -- TEST:
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

return ks_a


