local GameObject = require "app.views.city.test.model.gameobject"

local Gate = require "app.views.city.test.gate.gate"
local CrossArenaGate = class("CrossArenaGate",Gate)

function CrossArenaGate:init()
	for i=1,24 do
		self:addGameObject()
	end
end

function CrossArenaGate:parseRecord(record)
	self:cleanGameObject()

	-- for k,roleData in pairs(record) do
	-- 	if k < 13 then
	-- 		local index = self:indexToSeat(k)
	-- 		self:initGameObjectByRoleId(index,k,roleData.roleId,roleData)
	-- 	else
	-- 		local index = self:indexToSeat(k)
	-- 		self:initGameObjectByRoleId(k,index,roleData.roleId,roleData)
	-- 	end
	-- end

	for force, data in ipairs(record) do
		for group, v in ipairs(data) do
			for seat, roleData in pairs(v) do
				local baseIndex = group == 1 and 0 or 12
				self:initGameObjectByRoleId(baseIndex+seat, seat, roleData.roleId, roleData)
			end
		end
	end
end

function CrossArenaGate:parseScene(_scene)
	self:cleanGameObject()
	if _scene and next(_scene) then
		for k,_obj in pairs(_scene) do
			self:initGameObjectByRoleId(_obj.index,self:indexToSeat(k),_obj._prefab.roleId,_obj._prefab.data)
		end
	end
end

function Gate:indexToSeat(index)
	local seatMap = {4,5,6,1,2,3,7,8,9,10,11,12,4,5,6,1,2,3,7,8,9,10,11,12}
	-- local seatMap = {1,2,3,4,5,6,7,8,9,10,11,12,1,2,3,4,5,6,7,8,9,10,11,12}
	return seatMap[index] or index
end

-- 添加阵营单位
function CrossArenaGate:addGameObject(_prefab,seat)
	if _prefab then
		for _,_gameObject in ipairs(self.scene) do
            if not _gameObject:getRoleData() then
                seat = seat or _gameObject.seat
                _gameObject:init(_gameObject.index,seat,_prefab)
                break
            end
		end
		return
	end
	local lerpPos,limit = cc.p(10,2),3
    local _gameObject = GameObject.new(self.gameObject:clone())

    local itemNode = _gameObject.node
    local startPos = cc.p(-itemNode:size().width/2+lerpPos.x + 250 --往右边偏移一些，不然看不到
        ,itemNode:size().height/2-lerpPos.y)

	self.parent:addItemToScrollView(self.gameObjects,itemNode,lerpPos,startPos,limit)
	itemNode:onTouch(functools.handler(self,self.dragSprite,_gameObject))
    itemNode:addClickEventListener(functools.handler(self.parent,self.parent.onlyShowSelect,self.gameObjects,_gameObject))
    itemNode:get("del"):addClickEventListener(functools.handler(self,self.delGameObject,_gameObject))

	table.insert(self.scene,_gameObject)
	seat = seat or self:indexToSeat(#self.scene)
    _gameObject:init(#self.scene,seat,_prefab)
end

-- 删除阵营单位
function CrossArenaGate:delGameObject(_gameObject)
    if self.lastClickObj and self.lastClickObj.id == _gameObject.id then
        self.lastClickObj = nil
        self.parent:showAttr()
    end

    _gameObject:init(_gameObject.index)
end

-- 清除布阵
function CrossArenaGate:cleanGameObject()
	self.gameObjects:removeAllChildren()
    self.scene = {}
    for i=1,24 do
		self:addGameObject()
	end
end

-- 获取场上单位索引
function CrossArenaGate:getGameObjectIndex(count)
	count = count > 11 and count + 3 or count
	count = count > 20 and count + 3 or count
	return count > 5 and (count + 3) or count
end

function CrossArenaGate:getFightRoleData(args)
	local roleOut1 = {}
	local roleOut2 = {}
	local isCanOpen = {0,0}
	local _roleData
	for _,_gameObject in ipairs(self.scene) do
		_roleData = _gameObject:getRoleData()
		if _roleData then
			if _ < 13 then
				roleOut1[_gameObject.seat] = _roleData
			else
				roleOut2[_gameObject.seat] = _roleData
			end
			isCanOpen[_gameObject.force] = isCanOpen[_gameObject.force] + 1
		end
	end

	if isCanOpen[1] == 0 or isCanOpen[2] == 0 then
		roleOut1 = {}
		roleOut2 = {}
	end

	if args then
		roleOut1 = {}
		roleOut2 = {}
		for k, v in ipairs(args.left) do
			if v ~= 0 then
				local _prefab = Prefab.new()
				_prefab:init(v, clone(args.DefaultAttr))
				if k < 7 then roleOut1[k] = _prefab:getRoleData()
				else roleOut2[k - 6] = _prefab:getRoleData() end
			end
		end
		for k, v in ipairs(args.right) do
			if v ~= 0 then
				local _prefab = Prefab.new()
				_prefab:init(v, clone(args.DefaultAttr))
				if k < 7 then roleOut1[6 + k] = _prefab:getRoleData()
				else roleOut2[k] = _prefab:getRoleData() end
			end
		end
	end

	return {{{roleOut1, roleOut2},{roleOut1, roleOut2}}}
end

return CrossArenaGate