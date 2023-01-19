--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ks
--

local ks = {}

-- 1.如果用户是第一次登录，则系统将进入登录界面。
-- 2.如果用户已经登录过则系统将根据前一次的设置信息判断是否自动登录:若自动登录则系统 将进行自动登录;若不是自动登录则系统将进入登录界面。
-- 3.用户可以选择输入已有的用户名和密码进行登录，也可以进入注册界面重新注册新账号，登 录及注册界面的具体功能和操作可以进入登录和注册界面查看。
function ks.login(cb)
	print("Lua ks.login")
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
function ks.commitRoleInfo(ctype, cb)
	print("Lua ks.commitRoleInfo")
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
function ks.trackEvent(ctype, data)
	print("Lua ks.trackEvent")
	if type(data) ~= "table" then
		data = {data = data}
	end
	data.ctype = ctype
	data.event = eventMap[ctype] or ""
	sdk.callPlatformFunc("trackEvent", json.encode(data), function(info)
		print("trackEvent ret = ", info)
	end)
end

function ks.logout(cb)
	print("Lua ks.logout")
	sdk.callPlatformFunc("logout", "game", function(info)
		print("logout ret = ", info)
		-- 有回调就是成功
		cb(0, "ok")
	end)
end

-- 1. 由于app store应用内支付功能的限制，越狱设备在进行应用内购买时无法支付成功， SDK将消除loading并返回支付失败。
-- 2. 网游支付务必以服务端支付结果为准。
-- 3. 母包包含自有渠道支付与appStore支付，支付方式按照包名，版本号，商品ID动态配置


-- BundleID: com.jljxM.ios iOS
-- 内购商品名称	美金	    内购商品ID
-- 66鑽石		0.99	com.jljxM.ios.1
-- 140鑽石		1.99	com.jljxM.ios.2
-- 200鑽石		2.99	com.jljxM.ios.3
-- 260鑽石		3.99	com.jljxM.ios.4
-- 340鑽石		4.99	com.jljxM.ios.5
-- 580鑽石		8.99	com.jljxM.ios.6
-- 860鑽石		12.99	com.jljxM.ios.7
-- 980鑽石		14.99	com.jljxM.ios.8
-- 1340鑽石		19.99	com.jljxM.ios.9
-- 1740鑽石		25.99	com.jljxM.ios.10
-- 1980鑽石		29.99	com.jljxM.ios.11
-- 3380鑽石		49.99	com.jljxM.ios.12
-- 6580鑽石		99.99	com.jljxM.ios.13


-- BundleID: mx iOS
-- 内购商品名称	美金	    内购商品ID
-- 66鑽石		0.99	mx.1
-- 140鑽石		1.99	mx.2
-- 200鑽石		2.99	mx.3
-- 260鑽石		3.99	mx.4
-- 340鑽石		4.99	mx.5
-- 580鑽石		8.99	mx.6
-- 860鑽石		12.99	mx.7
-- 980鑽石		14.99	mx.8
-- 1340鑽石		19.99	mx.9
-- 1740鑽石		25.99	mx.10
-- 1980鑽石		29.99	mx.11
-- 3380鑽石		49.99	mx.12
-- 6580鑽石		99.99	mx.13


-- 包1 com.jljxM.ios    com_jljxM_ios               精灵觉醒M          被拒
-- 包2 mx               mx             				冒險啟程：z世代     过包
-- 包3 sbhx.sydj        sbhx_sydj             		神寶幻想           过包
-- 包4 Fire.n.Darkness  fire_n_darkness             火與暗之歌          提审
-- 包5 tj.mcdzz  	    con_mcdzz_mcdzz             萌宠大作战          提审
-- 包6 meng.BaodamaO.xian con_mbdmx_mbdmx     		萌寶大冒險		  提审
-- 包7 com.gp.sblkz     com_gp_sblkz     		    神寶裂空傳		  提审
-- 包9 com.ssjx.ios     com_ssjx_ios     		    神獸覺醒		  提审
-- 包10 sacred.Shou.Qi.source     com_ssqy_jiban    神獸起源	  提审
local defaultPrefix = {"com.jljxM.ios.",1100}

local productPrefixTagMap = {
	com_jljxM_ios = {"com.jljxM.ios.",1100},
	mx = {"mx.",1100},
	sbhx_sydj = {"sbhx.sydj.",1100},
	fire_n_darkness = {"FnD.",1100},
	con_mcdzz_mcdzz = {"mcdzz.",1100},
	con_mbdmx_mbdmx = {"mb.",1100},
	com_gp_sblkz = {"sblkz.",1100},
	com_ssqy_jiban = {"jiban.",1100},
	com_ssjx_ios = {"com.ssjx.ios.",1100},
}

-- !!! 需要自己解决多次充值请求问题
-- sdk后续没有界面，是在等待苹果系统支付界面
-- 回调也是在支付成功或者失败后返回
-- 即使请求超时也会有回调，但是网络不好，可能苹果系统拉起支付比较慢
-- 为了不阻断用户操作，并没有锁死UI
function ks.pay(cpOrderId, extInfo, amount, rechargeId, productDesc, cb)
	print("Lua ks.pay")
	local roleInfo = gGameModel.role
	local productID
	-- 相同channel不同包，根据tag来判断productID
	local prefix, startID = unpack(productPrefixTagMap[APP_TAG] or defaultPrefix)

	if rechargeId >= 1100 then
		productID = prefix .. (rechargeId - startID )
	elseif rechargeId >= 108 then
		productID = prefix .. (rechargeId - 100)
	elseif rechargeId > 100 then
		productID = prefix .. (rechargeId - 101)
	else
		productID = prefix .. (rechargeId * 2 + 3)
	end


	local payInfo = csv.recharges[rechargeId]
	
	--解决由于空格无法拉起iOS支付的问题，过滤空格
	--%s表示：空白符、空白字符一般包括空格、换行符\n、制表符\t以及回到行首符\r
	local roleName = roleInfo:read("name")
	roleName = string.gsub(roleName, "%s+", "")

	local tmp = {
		roleId = stringz.bintohex(roleInfo:read("id")),
		roleName = roleName,
		roleLevel = tostring(roleInfo:read("level")),
		area = gGameApp.serverInfo.name,
		area_id = tostring(roleInfo:read("area")),
		rmbDisplay = payInfo.rmbDisplay,
		rmb = amount,
		amount = amount/10,
		count = 1,
		extInfo = extInfo,
		productDesc = productDesc,
		currency = "cny", -- 人民币：cny
		productName = productDesc,
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

return ks


