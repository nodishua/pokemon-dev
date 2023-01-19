-- @date:   2019-10-16
-- @desc:   克隆战(元素挑战)底层页面

local ViewBase = cc.load("mvc").ViewBase
local CloneBattleBaseView = class("CloneBattleBaseView", ViewBase)

CloneBattleBaseView.RESOURCE_FILENAME = "clone_battle_base.json"
CloneBattleBaseView.RESOURCE_BINDING = {
}

function CloneBattleBaseView:onCreate(data)
	-- userDefault.setCurrDayKey("cloneBattleRedHint",true)
	local pnode = self:getResourceNode()
	local size = pnode:size()
	self.bgAni = widget.addAnimation(pnode, "huizhangbeijing/yuansudizuo.skel", "effect_1_loop", 12)
		:scale(2)
		:xy(size.width / 2, size.height / 2)
		:hide()
	self.bgAniB = widget.addAnimation(pnode, "huizhangbeijing/yuansubeijing.skel", "effect_loop", 11)
		:scale(2)
		:xy(size.width / 2, size.height / 2)
	self.bgAniF = widget.addAnimation(pnode, "huizhangbeijing/yuansu_qianjing.skel", "effect_loop", 13)
		:scale(2)
		:xy(size.width / 2, size.height / 2)

	if data then
		self.data = data
		self:refreshView()
	else
		self:refresh()
	end
end

function CloneBattleBaseView:onCleanup()
	if self.view then
		-- 因为战斗前暂存会保留 ViewBase, Node:removeSelf() 不会把该节点移出
		self.view:removeFromParent()
		self.view = nil
	end

	ViewBase.onCleanup(self)
end

function CloneBattleBaseView:refresh()
	gGameApp:requestServer("/game/clone/get", function (tb)
		self.data = tb.view
		self:refreshView()
	end)
end

function CloneBattleBaseView:refreshView(data)
	self.data = data or self.data
	if self.view then
		self.view:onClose()
		self.view = nil
		self.bgAni:hide()
	end

	local dbId = gGameModel.role:read("clone_room_db_id")
	if dbId then
		self.bgAniB:visible(false)
		self.bgAniF:visible(false)
		self.view = gGameUI:createView("city.adventure.clone_battle.room", self):init(self)
	else
		self:playBgAni(nil)
		self.bgAniB:visible(true)
		self.bgAniF:visible(true)
		self.view = gGameUI:createView("city.adventure.clone_battle.view", self):init(self.data, self)
	end

	gGameUI.topuiManager:createView("default", self.view, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.clone, subTitle = "CloneBattle"})
end

function CloneBattleBaseView:playBgAni(natureId)
	if natureId then
		self.bgAni:show()
		self.bgAni:play("effect_"..natureId.."_loop")
	else
		self.bgAni:hide()
	end
end

return CloneBattleBaseView





