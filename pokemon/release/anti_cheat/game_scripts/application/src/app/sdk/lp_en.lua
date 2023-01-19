--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- lp_en
--

local lp_en = {}

-- 1.如果用户是第一次登录，则系统将进入登录界面。
-- 2.如果用户已经登录过则系统将根据前一次的设置信息判断是否自动登录:若自动登录则系统 将进行自动登录;若不是自动登录则系统将进入登录界面。
-- 3.用户可以选择输入已有的用户名和密码进行登录，也可以进入注册界面重新注册新账号，登 录及注册界面的具体功能和操作可以进入登录和注册界面查看。
function lp_en.login(cb)
	print("Lua lp_en.login")
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
function lp_en.commitRoleInfo(ctype, cb)
	print("Lua lp_en.commitRoleInfo")
	local tmp = {
		ctype = ctype,
		area = gGameApp.serverInfo.name,
		level = tostring(gGameModel.role:read("level")),
		area_id = tostring(gGameModel.role:read("area")),
		user_name = gGameModel.role:read("name"),
		user_id = tostring(gGameModel.role:read("uid")),
		role_id = stringz.bintohex(gGameModel.role:read("id")),
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
	[11] = "PULL_VERSION",
	[12] = "START_CDN",
	[13] = "CDN_30",
	[14] = "CDN_60",
	[15] = "CDN_FINISH",
	[16] = "NOTNETWORK_CLICK",
	[17] = "PULL_GAMESHOW",
	[18] = "CLICK_OK",
	[19] = "START_LOGIN",
	[20] = "START_GAME",
}
function lp_en.trackEvent(ctype, data)
	print("Lua lp_en.trackEvent")

	if ctype == 2 or ctype == 1 then
		return
	end

	if type(data) ~= "table" then
		data = {data = data}
	end
	data.ctype = ctype
	data.event = eventMap[ctype] or ""
	sdk.callPlatformFunc("trackEvent", json.encode(data), function(info)
		print("trackEvent ret = ", info)
	end)
end

function lp_en.logout(cb)
	print("Lua lp_en.logout")
	sdk.callPlatformFunc("logout", "game", function(info)
		print("logout ret = ", info)
		-- 有回调就是成功
		cb(0, "ok")
	end)
end

-- 1. 由于app store应用内支付功能的限制，越狱设备在进行应用内购买时无法支付成功， SDK将消除loading并返回支付失败。
-- 2. 网游支付务必以服务端支付结果为准。
-- 3. 母包包含自有渠道支付与appStore支付，支付方式按照包名，版本号，商品ID动态配置


-- BundleID: com.de.dgf/com.doyea.uekas iOS     测试账号
-- 内购商品名称	内购商品ID	           美金
-- 66 钻石       jxqqfc_money_1         0.99
-- 140 钻石      jxqqfc_money_2         1.99
-- 200 钻石      jxqqfc_money_3         2.99
-- 260 钻石      jxqqfc_money_4         3.99
-- 340 钻石      jxqqfc_money_5         4.99
-- 580           jxqqfc_money_6         8.99
-- 860           jxqqfc_money_7        12.99
-- 980           jxqqfc_money_8        14.99
-- 1340          jxqqfc_money_9        19.99
-- 1740          jxqqfc_money_10       25.99
-- 1980          jxqqfc_money_11       29.99
-- 3380          jxqqfc_money_12       49.99
-- 6580          jxqqfc_money_13       99.99

-- BundleID:com.kjdedew      iOS            Pocket Incoming
-- 内购商品名称   内购商品ID         美金
-- 66 Diamond    com.kjdedew_1     0.99
-- 140 Diamond   com.kjdedew_2     1.99
-- 200 Diamond   com.kjdedew_3     2.99
-- 260           com.kjdedew_4     3.99
-- 340           com.kjdedew_5     4.99
-- 580           com.kjdedew_6     8.99
-- 860           com.kjdedew_7     12.99
-- 980           com.kjdedew_8     14.99
-- 1340          com.kjdedew_9     19.99
-- 1740          com.kjdedew_10    25.99
-- 1980          com.kjdedew_11    29.99
-- 3380          com.kjdedew_12    49.99
-- 6580          com.kjdedew_13    99.99


-- 包7 com.kjdedew        com_kjdedew                 Pocket Incoming		 过包
-- 包9 com.fq.ch          com_fq_ch                   Adventure Land		 过包
-- 包10 com.fengc.hen     com_fengc_hen               Pocket Trial           过包
-- 包14 com.weixiongguo   com_weixiongguo             Legend Beast Origin    过包
-- 包15 com.pocketworld   com_pocketworld             Pocket World   		 提审
-- 包16 com.changhuailong com_changhuailong           Pocket Smash   		 提审
-- 包19 com.lvxinglin     com_lvxinglin               Pocket Generation   	 过包
-- 包20 com.weinong.liang com_weinong_liang           Pocket Return   	     过包
-- 包21 com.ming.weiliang com_ming_weiliang           Path of Awake   	     过包
-- 包22 com.song.liang    com_song_liang              Travel of Gym   	     提审
-- 包23 com.su.jing       com_su_jing                 Senior Trainer   	     过包
-- 包24 com.jieneilin     com_jieneilin               Crazy Beast   	     未过
-- 包25 com.dake.wang     com_dake_wang               Infinite Pet Adventure 未过
-- 包26 com.huan.xinli    com_huan_xinli              Pet Duel   	    	 过包



-- 安卓
-- 包10 com.fengc.hen 		 com_fengc_hen_aos         Pocket Trial			下架
-- 包14 com.weixiongguo 	 	 com_weixiongguo_aos       Pocket Trial			未过
-- B2   com.dake.wang 		 com_dake_wang_aos         Pocket Trial			未过
-- B3   com.huan.xinli 	   	 com_huan_xinli_aos        Pocket Trial			未过
-- B4   com.jieneilin 	     com_jieneilin_aos         Pocket Trial			过包
-- B5   com.kjdx.five.qlyr 	 com_kjdx_five_qlyr_aos    Pocket Trial	        提审
-- B6   com.pyjx.six.lhyq 	 com_pyjx_six_lhyq_aos     Pocket Trial	        提审

local defaultPrefix = {"com.kjdedew_", 2100}

local productPrefixTagMap = {
	com_doyea_uekas = {"jxqqfc_money_",2100},
	com_pisxas_luwuf = {"qyywfc_money_",2100},
	com_male_pices = {"com.male.pices_",2100},
	com_hueka_uejsd = {"com.hueka.uejsd_",2100},
	com_hongling_luo = {"com.hongling.luo_",2100},
	com_kjdedew = {"com.kjdedew_",2100},
	com_lianglixue = {"com.lianglixue_",2100},
	com_fq_ch = {"com.fq.ch_",2100},
	com_fengc_hen = {"com.fengc.hen_",2100},
	com_xinshuaisun = {"com.xinshuaisun_",2100},
	com_zenzuozuo = {"com.zenzuozuo_",2100},
	com_changjishu = {"com.changjishu_",2100},
	com_xchaniaobing = {"com.xchaniaobing_",2100},
	com_weixiongguo = {"com.weixiongguo_",2100},
	com_pocketworld = {"com.pocketworld_",2100},
	com_pocketsmash = {"com.lulushi_",2100},
	com_changjishu = {"com.changjishu_",2100},
	com_changhuailong = {"com.changhuailong_",2100},
	com_xiaohuiguo = {"com.xiaohuiguo_",2100},
	com_wenchangdeng = {"com.wenchangdeng_",2100},
	com_lvxinglin = {"com.lvxinglin_",2100},
	com_weinong_liang = {"com.weinong.liang_",2100},
	com_ming_weiliang = {"com.ming.weiliang_",2100},
	com_song_liang = {"com.song.liang_",2100},
	com_su_jing = {"com.su.jing_",2100},
	com_jieneilin = {"com.jieneilin_",2100},
	com_dake_wang = {"com.dake.wang_",2100},
	com_huan_xinli = {"com.huan.xinli_",2100},


	com_fengc_hen_aos = {"com.fengc.hen_",2100},
	com_weixiongguo_aos = {"com.weixiongguo_",2100},
	com_dake_wang_aos = {"com.dake.wang_",2100},
	com_huan_xinli_aos = {"com.huan.xinli_",2100},
	com_jieneilin_aos = {"com.jieneilin_",2100},
	com_kjdx_five_qlyr_aos = {"com.kjdx.five.qlyr_",2100},
	com_pyjx_six_lhyq_aos = {"com.pyjx.six.lhyq_",2100},
}

-- !!! 需要自己解决多次充值请求问题
-- sdk后续没有界面，是在等待苹果系统支付界面
-- 回调也是在支付成功或者失败后返回
-- 即使请求超时也会有回调，但是网络不好，可能苹果系统拉起支付比较慢
-- 为了不阻断用户操作，并没有锁死UI
function lp_en.pay(cpOrderId, extInfo, amount, rechargeId, productDesc, cb)
	print("Lua lp.pay")
	local roleInfo = gGameModel.role
	local productID
	-- 相同channel不同包，根据tag来判断productID
	local prefix, startID = unpack(productPrefixTagMap[APP_TAG] or defaultPrefix)

	if rechargeId >= 2100 then
		productID = prefix .. (rechargeId - startID )
	elseif rechargeId >= 108 then
		productID = prefix .. (rechargeId - 100)
	elseif rechargeId > 100 then
	    productID = prefix .. (rechargeId - 101)
	else
	    productID = prefix .. (2 * rechargeId + 3)
	end

	local tmp = {
		roleId = stringz.bintohex(roleInfo:read("id")),
		roleName = roleInfo:read("name"),
		roleLevel = tostring(roleInfo:read("level")),
		area = gGameApp.serverInfo.name,
		area_id = tostring(roleInfo:read("area")),
		rmb = amount/10,
		amount = amount,
		count = 1,
		extInfo = extInfo,
		productDesc = productDesc,
		currency = "usd", -- 美元
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

return lp_en


