local GameObject = require "app.views.city.test.model.gameobject"
local Prefab = require "app.views.city.test.model.prefab"

local Gate = require "app.views.city.test.gate.gate"
local NormalGate = class("NormalGate",Gate)

function NormalGate:init()
	for i=1,12 do
		self:addGameObject()
	end
end

function NormalGate:parseRecord(record)
	self:cleanGameObject()
	for k,roleData in pairs(record) do
		if k < 13 then
			local index = self:indexToSeat(k)
			self:initGameObjectByRoleId(index,k,roleData.roleId,roleData)
		end
	end
end

function NormalGate:parseScene(_scene)
	self:cleanGameObject()
	if _scene and next(_scene) then
		for k,_obj in pairs(_scene) do
			if k < 13 then
				self:initGameObjectByRoleId(_obj.index,self:indexToSeat(k),_obj._prefab.roleId,_obj._prefab.data)
			end
		end
	end
end

-- 添加阵营单位
function NormalGate:addGameObject(_prefab,seat)
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
    local startPos = cc.p(itemNode:size().width/2+lerpPos.x
        ,itemNode:size().height/2-lerpPos.y)

    self.parent:addItemToScrollView(self.gameObjects,itemNode,lerpPos,startPos,limit)
	itemNode:onTouch(functools.handler(self,self.dragSprite,_gameObject))
    itemNode:addClickEventListener(functools.handler(self.parent,self.parent.onlyShowSelect,self.gameObjects,_gameObject))
    itemNode:get("del"):addClickEventListener(functools.handler(self,self.delGameObject,_gameObject))

	table.insert(self.scene,_gameObject)
	seat = seat or self:indexToSeat(#self.scene)
    _gameObject:init(#self.scene,seat,_prefab)
end

function NormalGate:exchange()
	local cloneData = {}
	for _, _gameObj in pairs(self.scene) do
		cloneData[self:exchangeSeat(_gameObj.seat)] = _gameObj:getRoleData()
	end
	self:cleanGameObject()

	for k,_gameObject in pairs(self.scene) do
		if cloneData[_gameObject.seat] then
			_gameObject:initByRoleData(_gameObject.index, _gameObject.seat, cloneData[_gameObject.seat])
		end
	end
end

-- 删除阵营单位
function NormalGate:delGameObject(_gameObject)
    if self.lastClickObj and self.lastClickObj.id == _gameObject.id then
        self.lastClickObj = nil
        self.parent:showAttr()
    end

    _gameObject:init(_gameObject.index,_gameObject.seat)
end

-- 清除布阵
function NormalGate:cleanGameObject()
	self.gameObjects:removeAllChildren()
    self.scene = {}
    for i=1,12 do
		self:addGameObject()
	end
end

-- 获取场上单位索引
function NormalGate:getGameObjectIndex(count)
	return count > 5 and (count + 3) or count
end

function NormalGate:getFightRoleData(args)
	local roleOut = {}
	local isCanOpen = {0,0}
	local _roleData
	if self.scene then 
		for _,_gameObject in ipairs(self.scene) do
			_roleData = _gameObject:getRoleData()
			if _roleData then
				roleOut[_gameObject.seat] = _roleData
				isCanOpen[_gameObject.force] = isCanOpen[_gameObject.force] + 1
			end
		end
	end
	if isCanOpen[1] == 0 or isCanOpen[2] == 0 then
		roleOut = {}
	end

	if args then
		roleOut = {}
		for k, v in ipairs(args.left) do
			if v ~= 0 then
				local _prefab = Prefab.new()
				_prefab:init(v, clone(args.DefaultAttr))
				roleOut[k] = _prefab:getRoleData()
			end
		end
		for k, v in ipairs(args.right) do
			if v ~= 0 then
				local _prefab = Prefab.new()
				_prefab:init(v, clone(args.DefaultAttr))
				roleOut[6 + k] = _prefab:getRoleData()
			end
		end
	end
	return {roleOut}
end

return NormalGate