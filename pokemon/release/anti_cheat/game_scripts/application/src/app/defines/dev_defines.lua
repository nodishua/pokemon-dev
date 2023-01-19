--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- dev开发配置
--

globals = globals or _G

local dev = {}
globals.dev = dev

local targetPlatform = cc.Application:getInstance():getTargetPlatform()
if cc.PLATFORM_OS_WINDOWS == targetPlatform then
	-- 客户端修改改这边，防止误提交影响线上
	--  windows 环境，默认关闭引导、登录弹框，显示内置编辑器
	dev.GUIDE_CLOSED = true -- 关闭引导
	dev.IGNORE_POPUP_BOX = true  -- 忽略弹出框，如登录的活动及自动签到
	-- 线上版本语言，如"cn"连国内官方和渠道服; "en" 连en外网; "trial" 为cn体验服
	dev.ONLINE_VERSION_LANGUAGE = nil
	-- dev.ONLINE_VERSION_LANGUAGE = 'cn'
	dev.REQUEST_LOG_IGNORE = { -- 忽略log
		['/login/check'] = true,
		['/game/login'] = true,
	}
	dev.DEBUG_MODE = true
	dev.DEV_PATH = 'dev/xxx' -- 自建分支dev/yourname_feature，需配合dev.DEBUG_MODE生效
	dev.CLOSE_PVP_PRECHECK = false -- 关闭战斗预校验

	-- 内部使用，显示碎片卡牌上当前精灵拥有最高星级
	-- dev.SHOW_MAX_STAR = true

	-- 外网号登录，dev.ONLINE_VERSION_LANGUAGE 需设置为对应外网才生效
	-- dev.ONLINE_USER_NAME = "tc_qd_8934870" -- zxd cn_qd 5

	-- 内网号登录
	-- dev.LOGIN_ACCOUNT = "zxd"
	-- dev.LOGIN_SERVER_KEY = "game.dev.2"

else
	dev.GUIDE_CLOSED = false
	dev.IGNORE_POPUP_BOX = false
	dev.ONLINE_VERSION_LANGUAGE = nil
	dev.REQUEST_LOG_IGNORE = {
		['/login/check'] = true,
		['/game/login'] = true,
	}
	dev.DEBUG_MODE = false
end
