--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 应用相关全局变量
--

--
-- languagePlist
--

-- 地区码参考
-- http://www.lingoes.cn/zh/translator/langcode.htm
-- 简化定义参考csv_language.py
local languagePlist = cc.FileUtils:getInstance():getValueMapFromFile('res/language.plist')
globals.LOCAL_LANGUAGE = languagePlist.localization or 'cn'
printInfo('LOCAL_LANGUAGE %s', LOCAL_LANGUAGE)

--
-- versionPlist
--
local plistRes = 'res/version.plist'
local versionLanguage = {
	trial = "cn",
	test = "cn",
}
if dev.ONLINE_VERSION_LANGUAGE then
	local name = dev.ONLINE_VERSION_LANGUAGE
	if string.sub(name, 1, 1) == "_" then
		name = string.sub(name, 2)
		LOCAL_LANGUAGE = versionLanguage[name] or name
		printInfo('LOCAL_LANGUAGE change %s', LOCAL_LANGUAGE)
	end
	plistRes = string.format("res/version_%s.plist", name)
end

--默认东八区时间
globals.UNIVERSAL_TIMEDELTA = 8 * 3600
if LOCAL_LANGUAGE == 'en' then
	--西五区时间
	UNIVERSAL_TIMEDELTA = 8 * 3600
elseif LOCAL_LANGUAGE == 'vn' then
	--东七区时间
	UNIVERSAL_TIMEDELTA = 7 * 3600
elseif LOCAL_LANGUAGE == 'kr' then
	--东九区时间
	UNIVERSAL_TIMEDELTA = 9 * 3600
end
printInfo('UNIVERSAL_TIMEDELTA %d hours', UNIVERSAL_TIMEDELTA/3600)


local versionPlist = cc.FileUtils:getInstance():getValueMapFromFile(plistRes)
-- "http://192.168.1.125/game01/version_fake.conf" 控制读取服务器列表的url
globals.VERSION_CONF_URL = versionPlist.versionUrl
-- "http://um-game.com/game01/serv.conf" --控制读取服务器列表的url
globals.SERVER_CONF_URL = versionPlist.serverUrl
globals.NOTICE_CONF_URL = versionPlist.noticeUrl
-- "http://192.168.1.96:1104"
globals.REPORT_CONF_URL = versionPlist.reportUrl
globals.FEED_BACK_URL = versionPlist.feedBackUrl
globals.SUPPORT_URL = "https://www.facebook.com/PocketTrial"
globals.JUMP_SHOP_URL = "https://play.google.com/store/apps/details?id=com.bdqaa.fogjr.tdlhct.zwzfp" -- kr
globals.DISCORD_URL = "https://discord.gg/h9q8gQ2SjQ" -- en
globals.DISABLE_WORD_CHECK_URL = versionPlist.disableWordCheckUrl -- or "http://172.81.227.66:1144/check"
globals.FOR_SHENHE = string.lower(versionPlist.forShenhe or "") == "true"
globals.LOGIN_SERVRE_HOSTS_TABLE = {versionPlist.loginServer}
for i = 2, 10 do
	if versionPlist[string.format("loginServer%d",i)] then
		table.insert(LOGIN_SERVRE_HOSTS_TABLE, versionPlist[string.format("loginServer%d",i)])
	end
end
if next(LOGIN_SERVRE_HOSTS_TABLE) then
	globals.IPV6_TEST_HOST = string.gmatch(LOGIN_SERVRE_HOSTS_TABLE[1], '([-a-z0-9A-Z.]+):(%d+)')()
end

if ymdump then
	-- 获取最新plist中的reportUrl
	ymdump.setUserInfo("url", REPORT_CONF_URL)
	printInfo('REPORT_CONF_URL %s', REPORT_CONF_URL)
end

--userdefault里保存的app版本 只对前三位维护
globals.APP_VERSION = versionPlist.app_version
printInfo('APP_VERSION %s', APP_VERSION)

--
-- channelPlist
--
local channelPlist = cc.FileUtils:getInstance():getValueMapFromFile('res/channel.plist')
globals.APP_CHANNEL = channelPlist.channel
globals.APP_TAG = channelPlist.tag
printInfo('APP_CHANNEL %s', APP_CHANNEL)
printInfo('APP_TAG %s', APP_TAG)

if globals.APP_TAG == "com_weixiongguo" then
	-- en 包14 做特殊处理
	globals.SUPPORT_URL = "https://www.facebook.com/kdfcgame/"
elseif globals.APP_TAG == 'com_huan_xinli' then
	-- en 包26 做特殊处理
	globals.SUPPORT_URL = "https://www.facebook.com/petduelth"
end

--
-- .fake
--
globals.FAKE_APP = cc.FileUtils:getInstance():isFileExist('fake') or cc.FileUtils:getInstance():isFileExist('.fake')
printInfo('FAKE_APP %s', FAKE_APP)


--
-- dev.DEBUG_MODE
--
if APP_CHANNEL == "none" or APP_CHANNEL == "luo" then
	dev.DEBUG_MODE = true
end

-- 服务器信息全局缓存
globals.SERVERS_INFO = {}

-- 区服前缀显示
globals.SERVER_MAP = {
	-- dev
	dev = {
		name = "内网",
		order = 1,
	},
	shenhe = {
		name = "审核",
		order = 2,
	},
	beta = {
		name = "beta",
		order = 3,
	},
	-- cn
	cn = {
		name = "官方",
		order = 100,
	},
	cn_qd = {
		name = "渠道",
		order = 101,
	},
	cn_ht = {
		name = "双平台",
		order = 102,
	},
	cn_ly1 = {
		name = "联运",
		order = 103,
	},
	-- kr
	kr = {
		name = "S",
		order = 100,
	},
}
