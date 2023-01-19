--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

-- 管理战斗对象和资源
local ObjectManager = class('ObjectManager', battleModule.CBase)

function ObjectManager:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.gameLayer = self.parent.gameLayer
	self.deleteObjLayer = self.parent.deleteObjLayer
	self.units = {} -- 全部单位集合 只能通过指定seat来获取
	self.unitIds = {}
	self.unitsInSeat = {} -- 正常单位集合
	self.updateUnits = {}

	self.updateDirty = true
end

function ObjectManager:onClose()
	self.units = {}
	self.unitIds = {}
	self.unitsInSeat = {}
	self.updateUnits = {}

	self.updateDirty = true
end

function ObjectManager:onSceneAddObj(key, model, args)
	local spr, isNormalSprite
	if args.type == battle.SpriteType.Normal then
		spr = BattleSprite.new(self.parent, model, key, args)
		isNormalSprite = model.seat < 13
	elseif args.type == battle.SpriteType.Possess then
		spr = BattlePossessSprite.new(self.parent, model, key, args)
		isNormalSprite = false
	elseif args.type == battle.SpriteType.Follower then
		spr = BattleFollowerSprite.new(self.parent, model, key, args)
		isNormalSprite = false
	end

	spr:init()
	spr:onAddToScene()

	self.gameLayer:addChild(spr) -- 0, key

	self.units[key] = spr
    if isNormalSprite then
		self.unitIds[model.id] = spr
        self.unitsInSeat[key] = spr
    end

	if spr.onFixedUpdate then
		self.updateUnits[key] = spr
	end

	self.updateDirty = true

	-- spr:setDebugEnabled(true)
	return spr
end

function ObjectManager:onSceneDeadObj(key, model)
	local spr = self.units[key]
	if spr then
		-- 有攻击方的话，等攻击结束移除
		local delFunc = function()
			self:onSceneDelObj(key)
		end
		spr:onDead("effect/death.skel", delFunc)
	end
end

function ObjectManager:onSceneDelObj(key)
	local spr = self.units[key]
	if spr then
		self.units[key] = nil
		self.unitsInSeat[key] = nil
		self.updateUnits[key] = nil
		self.updateDirty = true

		local seatSpr = self.unitIds[spr.id]
		-- 有发生过重复ID误删的情况 详见KDYG-1283 因此多一层判断逻辑
		if seatSpr and seatSpr.key == key then
			self.unitIds[spr.id] = nil
		end
		-- keep model safe
		if spr.__vmproxy then
			-- getMovePosZ used in model
			spr.__vmproxy:modelOnly({
				getMovePosZ = function() return 0 end,
			})
			spr.__vmproxy = nil
		end

		spr:sceneDelObj(self.deleteObjLayer)
	end
end

-- 死亡时播放胜利或者失败的动画
function ObjectManager:onSceneEndPlayAni(result)
	local winForce = (result == 'win') and 1 or 2
	for key, obj in pairs(self.units) do
		if self.unitsInSeat[key] then
			if obj.force == winForce then
				obj:setActionState('win_loop')
			else
				obj:setActionState(battle.SpriteActionTable.standby)
			end
		else
			obj:setVisible(false)
		end
	end
end

-- objectManager通知到显示相关角色信息
-- @parm: typ: true显示，false隐藏
-- @parm: obj:相关显示需要对应的obj参数
function ObjectManager:onShowHero(args)
	if args then
		local isShow = (args.typ == "showAll")
		for key, spr in pairs(self.units) do
			spr:showHero(isShow, args)
		end
	end
end

function ObjectManager:onUpdate(delta)
	for _, obj in pairs(self.updateUnits) do
		obj:onFixedUpdate(delta)
	end

	if not self.updateDirty then return end

	-- 更新战斗对象的effectManager
	local cnt = 0
	for _, obj in pairs(self.units) do
		if obj then
			local updated = obj:onUpdate(delta)
			if updated then
				cnt = cnt + 1
			end
		end
	end

	self.updateDirty = cnt > 0
end

-- 减少没有effect时的遍历
function ObjectManager:onEffectUpdated()
	self.updateDirty = true
end

function ObjectManager:getSceneObjs()
	return self.unitsInSeat
end

function ObjectManager:getSceneAllObjs()
	return self.units
end


function ObjectManager:getSceneObj(key)
	return self.units[key]
end

function ObjectManager:getSceneObjBySeat(seat, type)
	-- 通过seat去拿unitIds, 用type去区分下, normal和follow都在里面
	type = type or battle.SpriteType.Normal
	for _,spr in pairs(self.unitIds) do
		if spr.seat == seat and spr.type == type then return spr end
	end
end

function ObjectManager:getSceneObjById(id)
	return self.unitIds[id]
end

function ObjectManager:isObjExisted(key)
	return self.units[key] ~= nil
end

function ObjectManager:onViewBeProxy(view, proxy)
	for k, v in pairs(self.units) do
		if v == view then
			view.__vmproxy = proxy
			return
		end
	end
end

function ObjectManager:onAddUnitsInSeat(key)
	if self.unitsInSeat[key] then return end
	self.unitsInSeat[key] = self.units[key]
end

function ObjectManager:onSceneClearAll()
	for key, _ in pairs(self.units) do
		self:onSceneDelObj(key)
	end
	self.units = {}
	self.unitIds = {}
	self.unitsInSeat = {}

	self.updateDirty = true
end

return ObjectManager