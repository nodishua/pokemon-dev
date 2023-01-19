--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2018 TianJi Information Technology Inc.
--
-- session for login server
--

local Session = require('net.tcpsession')

local LoginSession = class('LoginSession', Session)

LoginSession.StepInitToLogin = Session.StepInitCustom
LoginSession.StepInitWaitLogin = Session.StepInitCustom + 1
LoginSession.StepInitLoginConfirm = Session.StepInitCustom + 2

function LoginSession:init(host, port, userName, cb)
	self.userName = userName
	self._initCB = cb

	self:initPwd()

	Session.init(self, host, port)
end

function LoginSession:setIDAndPwd(accountID, pwd)
	self.accountID = accountID
	if pwd then
		self:setNewPwd(pwd)
	end
end

function LoginSession:setInitStep(step)
	local old = self.initStep
	if old == self.StepInitConnected and step == self.StepInitOK then
		-- insert custom step
		self.initStep = self.StepInitToLogin
	else
		self.initStep = step
	end
end

function LoginSession:_initSession()
	local ret = Session._initSession(self)
	if not ret or self.initStep < self.StepInitConnected then
		return ret
	end

	if self.initStep == self.StepInitToLogin then
		printInfo('%s %s login to %s:%s', tostring(self), self.sockID, self.host, self.port)
		self:setInitStep(self.StepInitWaitLogin)
		self:_onSendLogin()

	elseif self.initStep == self.StepInitWaitLogin or self.initStep == self.StepInitLoginConfirm then
		return false, true
	end

	return false
end

local function getGuarderMD5()
	require "3rd.stringzutils"
	require "3rd.MD5"

	local fixer = "res/img/helper/70ba7e14140b0097.jpg"
	local guarder = require("util.guarder")
	local files = {
		-- "src/util.guarder", -- git had autocrlf problem
		"src/app.guarder.init",
		fixer,
	}

	local md5str, filesize
	local sum = 0
	for _, path in ipairs(files) do
		md5str, filesize = guarder.get_file_md5(path, md5str)
		sum = sum + filesize
	end


	-- NOTICE: 更新login配置,保持与GUARDER_MD5一致
	-- win下会自动关闭客户端, 线上不让登陆
	local GUARDER_MD5 = "1b5a8aa9e7660d317d1eada5c37d2429"
	if device.platform == "windows" then
		if md5str ~= GUARDER_MD5 then
			printError('GUARDER_MD5 err in login %s %s %s', GUARDER_MD5, md5str, sum)
			return display.director:endToLua()
		end
	end

	-- TODO: 需要处理32和gc64两个字节码版本
	-- local ret, err = safeLoad(fixer)
	-- if ret ~= true then
	-- 	if device.platform == "windows" then
	-- 		printError('FIXER_ERR in login %s', ret)
	-- 		return display.director:endToLua()
	-- 	end
	-- 	-- TODO: cn ios 统计用
	-- 	-- sendExceptionInMobile(string.format("fixer err: %s", err))
	-- 	-- return display.director:endToLua()
	-- end

	return md5str
end

-- sock连接成功
function LoginSession:_onSendLogin()
	local appVer = nil
	string.gsub(APP_VERSION, '%d+.%d+.%d+', function(s)
		appVer = appVer or s
	end)
	print("login channel", sdk.getChannel(self.userName))

	local guarderMD5 = getGuarderMD5()
	if type(guarderMD5) ~= "string" then
		return
	end

	self.net:sendPacket("/login/check", {
		name = self.userName,
		app = appVer,
		patch = PATCH_VERSION,
		minpatch = PATCH_MIN_VERSION,
		channel = sdk.getChannel(self.userName),
		language = LOCAL_LANGUAGE,
		tag = APP_TAG,
		fake = FAKE_APP,
		guarder = guarderMD5,
		platform = device.platform,
	})

	-- take over the recv control from update
	-- and gave timeout for this request
	self:asyncRecvUntilOnePacket(self.InitTimeout)
end

-- 逻辑登录成功
function LoginSession:_onInitOK()
	printInfo('%s %s login ok %s:%s', tostring(self), self.sockID, self.host, self.port)

	self.reconnTimes = 0

	-- 有过成功连接后，断线不再重连，token会过期无效
	if self._initCB then
		local ret, err = self._initData
		if not ret.ret then
			ret, err = nil, ret
		end
		self._initCB(ret, err)
		self._initCB, self._initData = nil, nil
	end
end

function LoginSession:_onInitErr()
	self.host = nil
	self:close()

	if self._initCB then
		self._initData.ret = false
		self._initData.err = self._initData.err or "lost"
		self._initCB(nil, self._initData)
		self._initCB, self._initData = nil, nil
	end
end

return LoginSession