--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- TC
--

local tc = {}

-- 1.如果用户是第一次登录，则系统将进入登录界面。
-- 2.如果用户已经登录过则系统将根据前一次的设置信息判断是否自动登录:若自动登录则系统 将进行自动登录;若不是自动登录则系统将进入登录界面。
-- 3.用户可以选择输入已有的用户名和密码进行登录，也可以进入注册界面重新注册新账号，登 录及注册界面的具体功能和操作可以进入登录和注册界面查看。
function tc.login(cb)
	sdk.callPlatformFunc("login", "", function(info)
		print("login ret = ", info)
		sdk.loginInfo = info
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
function tc.commitRoleInfo(ctype, cb)
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
function tc.trackEvent(ctype, data)
	if type(data) ~= "table" then
		data = {data = data}
	end
	data.ctype = ctype
	data.event = eventMap[ctype] or ""
	sdk.callPlatformFunc("trackEvent", json.encode(data), function(info)
		print("trackEvent ret = ", info)
	end)
end

function tc.logout(cb)
	sdk.callPlatformFunc("logout", "game", function(info)
		print("logout ret = ", info)
		-- 有回调就是成功
		cb(0, "ok")
	end)
end

-- 1. 由于app store应用内支付功能的限制，越狱设备在进行应用内购买时无法支付成功， SDK将消除loading并返回支付失败。
-- 2. 网游支付务必以服务端支付结果为准。
-- 3. 母包包含自有渠道支付与appStore支付，支付方式按照包名，版本号，商品ID动态配置

-- BundleID：	com.meng.jingying iOS
-- 内购商品名称	内购商品ID	CNY
-- 60钻石	com.meng.jingying.1
-- 300钻石	com.meng.jingying.2
-- 600钻石	com.meng.jingying.3
-- 980钻石	com.meng.jingying.4
-- 1980钻石	com.meng.jingying.5
-- 3280钻石	com.meng.jingying.6
-- 6480钻石	com.meng.jingying.7

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
--
-- com.mccjh.mccjh.101	直购礼包1	"1"
-- com.mccjh.mccjh.102	直购礼包6	"6"
-- com.mccjh.mccjh.103	直购礼包12	"12"
-- com.mccjh.mccjh.104	直购礼包18	"18"
-- com.mccjh.mccjh.105	直购礼包25	"25"
-- com.mccjh.mccjh.106	直购礼包30	"30"
-- com.mccjh.mccjh.107	直购礼包60	"60"
-- com.mccjh.mccjh.108	直购礼包98	"98"
-- com.mccjh.mccjh.109	直购礼包128	"128"
-- com.mccjh.mccjh.110	直购礼包168	"168"
-- com.mccjh.mccjh.111	直购礼包198	"198"
-- com.mccjh.mccjh.112	直购礼包328	"328"
-- com.mccjh.mccjh.113	直购礼包648	"648"

-- BundleID：com.yg.xsd.spass  iOS
-- com.yg.xsd.spass.102       60钻石
-- com.yg.xsd.spass.103       120钻石
-- com.yg.xsd.spass.104       180钻石
-- com.yg.xsd.spass.105       250钻石
-- com.yg.xsd.spass.106       300钻石
-- com.yg.xsd.spass.107       600钻石
-- com.yg.xsd.spass.108       980钻石
-- com.yg.xsd.spass.109       1280钻石
-- com.yg.xsd.spass.110       1680钻石
-- com.yg.xsd.spass.111       3280钻石
-- com.yg.xsd.spass.112       6480钻石

--BundleID：com.lzl.jxjjb   iOS        CNY
-- com.lzl.jxjjb.1         60钻石       6
-- com.lzl.jxjjb.2         300钻石      30
-- com.lzl.jxjjb.3         600钻石      60
-- com.lzl.jxjjb.4         980钻石      98
-- com.lzl.jxjjb.5         1980钻石     198
-- com.lzl.jxjjb.6         3280钻石     328
-- com.lzl.jxjjb.7         6480钻石     648

--Bundle com.kkdd.mmxx    iOS          CNY
-- com.kkdd.mmxx.1        60钻石        6
-- com.kkdd.mmxx.2        300钻石       30
-- com.kkdd.mmxx.3        600钻石       60
-- com.kkdd.mmxx.4        980钻石       98
-- com.kkdd.mmxx.5        1980钻石      198
-- com.kkdd.mmxx.6        3280钻石      328
-- com.kkdd.mmxx.7        6480钻石      648

--Bundle com.xiaoyg.damx 商品项 同 com.kkdd.mmmxx/com.lzl.jxjjb

--   iOS bundleID      name          内购         备注#现名称#
-- com.lzl.jxjjb       口袋觉醒Pro     有
-- com.kkdd.mmxx       口袋大冒险       有
-- com.kpd.yga         妖怪大乱斗      无          精灵训练师
-- com.xiaoyg.damx     小妖怪大冒险    有          战斗吧妖怪
-- com.zdzdba.yaoguai  精灵对决        有
-- com.gfrgfh.ygjh     妖怪觉醒        有
-- com.jlcsd.jlcsd     精灵超世代      有
-- com.wdhbb.wdhbb     精灵契约        有
-- com.kdygdj.kdygdj   口袋精灵对决     有
-- com.kdsqmc.kdsqmc   口袋神奇萌宠     有
-- com.sqkdjl.sqkdjl   神奇萌宠进化     有
-- com.kdmcqy.kdmcqy   口袋萌宠起源     有
-- com.mengcjljh.mengcjljh   萌宠精灵进化     有
-- com.sqdmcm.sqdmcm   神奇萌宠大冒险     有
-- com.mmdcw.mmdcw     萌宠精灵集结    有
-- com.sqkdmc.sqkdmc   神奇口袋萌宠    有
-- com.wdhbb.wdhbb     精灵契约->口袋超进化        有
-- com_mcqiyue_mcqiyue   口袋萌宠契约    有
-- com_sqmc_duijue   神奇萌宠对决    有
-- com_kdmc_dalu   口袋萌宠大陆    有
-- com_sqjljh_sqjljh   神奇精灵进化    有
-- com_kdmcdmx_kdmcdmx   口袋萌宠大冒险    有
-- com_kdmcxls_kdmcxls   口袋萌宠训练师    有
-- com_mengchongxsd_mengchongxsd   萌宠新世代    有
-- com_shenqijljh_shenqijljh 神奇精灵进化 有
--49 com.mcxdl.mcxdl   萌宠新大陆    有
--50 com.sqjljuexing.sqjljuexing   神奇精灵觉醒    有
--51 com.shenqimc.mcsqmx   萌宠神奇冒险    有
local defaultPrefix = {"com.mccjh.mccjh.", 3}

local productPrefixTagMap = {
	com_mccjh_mccjh_1 = defaultPrefix,
	com_meng_jingying_1 = {"com.meng.jingying.", 1},
	com_meng_chongjy_1 = {"com.meng.chongjy.", 1},
	com_yg_xsd_spass = {"com.yg.xsd.spass.",1},
	com_lzl_jxjjb = {"com.lzl.jxjjb.",1},
	com_kkdd_mmxx = {"com.kkdd.mmxx.",1},
	com_xiaoyg_damx = {"com.xiaoyg.damx.",1},
	com_zdzdba_yaoguai = {"com.zdzdba.yaoguai.",1},
	com_gfrgfh_ygjh = {"com.gfrgfh.ygjh.",1},
	com_jlcsd_jlcsd = {"com.jlcsd.jlcsd.",1},
	com_yishan_ysysljj = {"com.yishan.ysysljj.",1},
	com_wdhbb_wdhbb = {"com.wdhbb.wdhbb.",1},
	com_kdygdj_kdygdj = {"com.kdygdj.kdygdj.",1},
	com_chaojh_chaojh = {"com.chaojh.chaojh.",1},
	com_kdsqmc_kdsqmc = {"com.kdsqmc.kdsqmc.",1},
	com_mengjldz_mengjldz = {"com.mengjldz.mengjldz.",1},
	com_sqkdjl_sqkdjl = {"com.sqkdjl.sqkdjl.",1},
	com_qgka_mcjl = {"com.qgka.mcjl.",1},
	com_jlzhs_jlzhs = {"com.jlzhs.jlzhs.",1},
	com_koudaiwp_koudaiwp = {"com.koudaiwp.koudaiwp.",1},
	com_jldmx_jldmx = {"com.jldmx.jldmx.",1},
	com_kdmcqy_kdmcqy = {"com.kdmcqy.kdmcqy.",1},
	com_shenqimc_shenqimc = {"com.shenqimc.shenqimc.",1},
	com_mengcjljh_mengcjljh = {"com.mengcjljh.mengcjljh.",1},
	com_sqdmcm_sqdmcm = {"com.sqdmcm.sqdmcm.",1},
	com_mmdcw_mmdcw = {"com.mmdcw.mmdcw.",1},
	com_sqkdmc_sqkdmc = {"com.sqkdmc.sqkdmc.",1},
	com_wdhbb_wdhbb_new = {"com.wdhbb.wdhbb.",1},
	com_mcwy_mcwy = {"com.mcwy.mcwy.",1},
	com_mcqiyue_mcqiyue = {"com.mcqiyue.mcqiyue.",1},
	com_sqmc_duijue = {"com.sqmc.duijue.",1},
	com_kdmc_dalu = {"com.kdmc.dalu.",1},
	com_sqjljh_sqjljh = {"com.sqjljh.sqjljh.",1},
	com_kdmcdmx_kdmcdmx = {"com.kdmcdmx.kdmcdmx.",1},
	com_kdmcxls_kdmcxls = {"com.kdmcxls.kdmcxls.",1},
	com_mengchongxsd_mengchongxsd = {"com.mengchongxsd.mengchongxsd.",1},
	com_shenqijljh_shenqijljh = {"com.shenqijljh.shenqijljh.",1},
	com_mcxdl_mcxdl = {"com.mcxdl.mcxdl.",1},
	com_sqjljuexing_sqjljuexing = {"com.sqjljuexing.sqjljuexing.",1},
	com_shenqimc_mcsqmx = {"com.shenqimc.mcsqmx.",1},

}

local specialProductTagMap = {
	com_lzl_jxjjb = "com.lzl.jxjjb.",
	com_kkdd_mmxx = "com.kkdd.mmxx.",
	com_xiaoyg_damx = "com.xiaoyg.damx.",
	com_zdzdba_yaoguai = "com.zdzdba.yaoguai.",
	com_gfrgfh_ygjh = "com.gfrgfh.ygjh.",
	com_jlcsd_jlcsd = "com.jlcsd.jlcsd.",
	com_wdhbb_wdhbb = "com.wdhbb.wdhbb.",
	com_kdygdj_kdygdj = "com.kdygdj.kdygdj.",
	com_kdsqmc_kdsqmc = "com.kdsqmc.kdsqmc.",
	com_sqkdjl_sqkdjl = "com.sqkdjl.sqkdjl.",
	com_kdmcqy_kdmcqy = "com.kdmcqy.kdmcqy.",
	com_mengcjljh_mengcjljh = "com.mengcjljh.mengcjljh.",
	com_sqdmcm_sqdmcm = "com.sqdmcm.sqdmcm.",
	com_mmdcw_mmdcw = "com.mmdcw.mmdcw.",
	com_sqkdmc_sqkdmc = "com.sqkdmc.sqkdmc.",
	com_wdhbb_wdhbb_new = "com.wdhbb.wdhbb.",
	com_mcwy_mcwy = "com.mcwy.mcwy.",
	com_mcqiyue_mcqiyue = "com.mcqiyue.mcqiyue.",
	com_sqmc_duijue = "com.sqmc.duijue.",
	com_kdmc_dalu = "com.kdmc.dalu.",
	com_sqjljh_sqjljh = "com.sqjljh.sqjljh.",
	com_kdmcdmx_kdmcdmx = "com.kdmcdmx.kdmcdmx.",
	com_kdmcxls_kdmcxls = "com.kdmcxls.kdmcxls.",
	com_mengchongxsd_mengchongxsd = "com.mengchongxsd.mengchongxsd.",
	com_shenqijljh_shenqijljh = "com.shenqijljh.shenqijljh.",
	com_mcxdl_mcxdl = "com.mcxdl.mcxdl.",
	com_sqjljuexing_sqjljuexing = "com.sqjljuexing.sqjljuexing.",
	com_shenqimc_mcsqmx = "com.shenqimc.mcsqmx.",

}

local function specialProductID(rechargeId)
	local specialPrefix = specialProductTagMap[APP_TAG]
	if specialPrefix == nil then return end
	local special = {
		[1] = specialPrefix .. "2",
		[2] = specialPrefix .. "12",
		-- ios <= 12 无法第三方支付
		[102] = specialPrefix .. "1",
		[106] = specialPrefix .. "2",
		[107] = specialPrefix .. "3",
		[108] = specialPrefix .. "4",
		[111] = specialPrefix .. "5",
		[112] = specialPrefix .. "6",
		[113] = specialPrefix .. "7",
	}
	return special[rechargeId]
end

-- !!! 需要自己解决多次充值请求问题
-- sdk后续没有界面，是在等待苹果系统支付界面
-- 回调也是在支付成功或者失败后返回
-- 即使请求超时也会有回调，但是网络不好，可能苹果系统拉起支付比较慢
-- 为了不阻断用户操作，并没有锁死UI
function tc.pay(cpOrderId, extInfo, amount, rechargeId, productDesc, cb)
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
	-- 只针对ios的com.lzl.jxjjb的包就行
	if specialProductTagMap[APP_TAG] ~= nil then
		if rechargeId >= 3 and rechargeId <= 10 then
			desc = 'gem'
		else
			desc = 'gift'
		end
	end

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
function tc.queryIdentity(cb, count)
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
				tc.queryIdentity(cb, count)
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
function tc.queryUserType(cb, count)
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
				tc.queryUserType(cb, count)
			end, 60)
		elseif typ == "closed" then
			cb(nil)
		else
			-- TODO: 游客转注册用户
			cb(tonumber(typ))
		end
	end)
end

function tc.openCustomerService()
	sdk.callPlatformFunc("openCustomerService", "", function(info)
		print("openCustomerService ret = ", info)
	end)
end

function tc.openPrivacyProtocols()
	sdk.callPlatformFunc("openPrivacyProtocols","",function(info)
		print("openPrivacyProtocols ret = ",info)
	end)
end

function tc.openPermissionSetting()
	sdk.callPlatformFunc("openPermissionSetting","",function(info)
		print("openPermissionSetting ret = ",info)
	end)
end

return tc


