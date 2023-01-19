--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- Texture缓存和预加载
--

local TexCache = {}

local guiReader = ccs.GUIReader:getInstance()
local textureCache = display.director:getTextureCache()


local loading = {}
local preloadMap = table.defaulttable(function() return {} end)

function TexCache.getAsync(path, cb)
	local needLoad = false
	if loading[path] == nil then
		loading[path] = {}
		needLoad = true
	end
	if cb then
		table.insert(loading[path], cb)
	end

	if needLoad then
		textureCache:addImageAsync(path, function(tex)
			for _, cb in ipairs(loading[path]) do
				cb(tex)
			end
			loading[path] = nil
		end, path, false)
	end
end

function TexCache.get(path)
	textureCache:unbindImageAsync(path)
	local tex = textureCache:addImage(path)
	if loading[path] then
		for _, cb in ipairs(loading[path]) do
			cb(tex)
		end
		loading[path] = nil
	end
	return tex
end

function TexCache.resetPreload(key)
	key = key or ""
	preloadMap[key] = nil
end

function TexCache.addPreload(tOrPath, key, filter)
	key = key or ""
	if type(tOrPath) == "string" then
		preloadMap[key][tOrPath] = preloadMap[key][tOrPath] or false
	else
		local preloads = preloadMap[key]
		for k, v in pairs(tOrPath) do
			if filter then v = filter(v) end
			if v then
				-- local path = display.textureCache:checkFullPath(v)
				local path = v
				preloads[path] = preloads[path] or false
			end
		end
	end
end

function TexCache.preload(key)
	key = key or ""
	local t = preloadMap[key] or {}
	for path, flag in pairs(t) do
		-- if not flag then
		if true then
			TexCache.getAsync(path, function ( ... )
				-- print('preload texture ok', path)
				t[path] = true
			end)
		end
	end
end

return TexCache