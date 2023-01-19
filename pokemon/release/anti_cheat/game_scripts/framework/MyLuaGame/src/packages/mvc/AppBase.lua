--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
local AppBase = class("AppBase")

function AppBase:ctor(configs)
	globals.gGameApp = self

	self.scene = display.newScene("main") -- 现在scene是唯一，创建后不再改变
	self.configs_ = {
		viewsRoot = {
			"battle.app_views",
			"app.views",
		},
		modelsRoot = "app.models",
		defaultSceneName = "MainScene",
	}

	for k, v in pairs(configs or {}) do
		self.configs_[k] = v
	end

	if type(self.configs_.viewsRoot) ~= "table" then
		self.configs_.viewsRoot = {self.configs_.viewsRoot}
	end
	if type(self.configs_.modelsRoot) ~= "table" then
		self.configs_.modelsRoot = {self.configs_.modelsRoot}
	end

	self:onCreate()
end

function AppBase:run(initSceneName)
	initSceneName = initSceneName or self.configs_.defaultSceneName
	self:enterScene(initSceneName)
end

function AppBase:enterScene(sceneName, transition, time, more)
	local view = self:createView(sceneName)
	view:onCreate()
	view:setVisible(true)
	self.scene:addChild(view)
	return view
end

function AppBase:createView(name, parent, handlers)
	local viewCls = self:getViewClass(name)
	if viewCls == nil then
		error(string.format("'%s' not found in views root:", name))
	end
	return viewCls:create(self, parent, handlers)
end

function AppBase:getViewClass(name)
	for _, root in ipairs(self.configs_.viewsRoot) do
		local packageName = string.format("%s.%s", root, name):gsub("/", ".")
		local ok, cls = pcall(require, packageName)
		if ok then return cls end
		-- if other error, re-raise
		local err = cls
		if not err:find("not found") or err:find("expected") then
			printError(err)
			require(packageName)
		end
	end
end

function AppBase:onCreate()
end

return AppBase
