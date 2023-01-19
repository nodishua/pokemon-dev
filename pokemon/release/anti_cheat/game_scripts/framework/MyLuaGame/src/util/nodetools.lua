--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

-- node相关库函数
local nodetools = {}
globals.nodetools = nodetools

local tinsert = table.insert

-- get('a.b.c')
-- get(112)
-- get('a', 112, 'c')
function nodetools.get(node, ...)
	local vargs = {...}
	local only = #vargs == 1
	for _, path in ipairs(vargs) do
		if type(path) == 'number' then
			node = node:getChildByTag(path)
		else
			if only then
				local flag = false
				for k in path:gmatch("([^.]+)") do
					local ik = tonumber(k)
					if ik then
						node = node:getChildByTag(ik)
					else
						node = node:getChildByName(k)
					end
					if node == nil then return nil end
					flag = true
				end
				node = flag and node or nil
			else
				node = node:getChildByName(path)
			end
		end
		if node == nil then return nil end
	end
	return node
end

-- multiget('a.b', 112, 'c')
-- {b=get('a.b'), 112=get(112), c=get('c')}
--
-- multiget({'a.b', 112, 'c'})
-- {get('a.b'), get(112), get('c')}
function nodetools.multiget(node, ...)
	local vargs = {...}
	local ret = {}
	if #vargs == 1 and type(vargs[1]) == "table" then
		ret = vargs[1]
		for i, path in ipairs(ret) do
			ret[i] = nodetools.get(node, path)
		end
	else
		for _, path in ipairs(vargs) do
			ret[path] = nodetools.get(node, path)
		end
	end
	return ret
end

-- invoke(node, {"btn1", "btn2"}, "hide")
function nodetools.invoke(node, t, fname, ...)
	for _, path in ipairs(t) do
		local object = nodetools.get(node, path)
		object[fname](object, ...)
	end
end

-- map({btn1, btn2}, "getPosition")
-- better than itertools.map({btn1, btn2}, function(k, v) return k, v:getPosition() end)
function nodetools.map(nodes, fname, ...)
	local ret = {}
	for k, node in ipairs(nodes) do
		local f = node[fname]
		if f then
			ret[k] = f(node, ...)
		end
	end
	return ret
end

-- path(node)
-- root.panel1.btn1
function nodetools.path(node)
	local ret = {}
	while node do
		table.insert(ret, node:name())
		node = node:parent()
	end
	local n = #ret
	for i = 1, n/2 do
		ret[i], ret[n-i+1] = ret[n-i+1], ret[i]
	end
	return table.concat(ret, "/")
end