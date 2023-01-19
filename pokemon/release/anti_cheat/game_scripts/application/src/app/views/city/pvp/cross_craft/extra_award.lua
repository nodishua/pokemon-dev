local ViewBase = cc.load("mvc").ViewBase
local CrossExtraAward = class("CrossExtraAward", ViewBase)
CrossExtraAward.RESOURCE_FILENAME = "cross_craft_bet_result.json"
CrossExtraAward.RESOURCE_BINDING = {
	["imgBG"] = "imgBG",
	["imgJc"] = "imgJc",
	["rolePanel1"] = "rolePanel1",
	["rolePanel2"] = "rolePanel2",
	["rolePanel3"] = "rolePanel3",
	["list"] = "list",
	["innerList"] = "innerList",
	["item"] = "item",
}

function CrossExtraAward:initRoleData(roleData,panel)
	if not roleData then
		return
	end
	panel:get("txtName"):text(roleData.role.name)
	bind.extend(self, panel:get("trainerIcon"), {
		class = "role_logo",
		props = {
			logoId =  roleData.role.logo,
			level = false,
			vip = false,
			frameId =  roleData.role.frame,
			onNode = function(node)
				node:xy(96, 100)
					:z(6)
			end,
		}
	})
end

function CrossExtraAward:initAward()
	local awardData = {}
	if self.type  == 1 then
		awardData = csv.cross.craft.base[1].preBetExtraAward
	else
		awardData = csv.cross.craft.base[1].top4BetExtraAward
	end

	bind.extend(self, self.list, {
		class = "listview",
		props = {
			data = dataEasy.getItemData(awardData),
			item = self.item,
			dataOrderCmp = dataEasy.sortItemCmp,
			onAfterBuild = function()
				self.list:setItemAlignCenter()
			end,
			onItem = function(list, node, k, v)
				bind.extend(list, node, {
					class = "icon_key",
					props = {
						data = v,
						grayState = v.grayState,
						onNode = function(panel)
							panel:y(160)
							local name = dataEasy.getCfgByKey(v.key).name
							adapt.setTextScaleWithWidth(node:get("txtName"), name, panel:width() + 80)
						end
					},
				})
			end,
		}
	})
	self.list:adaptTouchEnabled()
end

function CrossExtraAward:onCreate(data)
	local pnode = self:getResourceNode()
	widget.addAnimation(pnode, "kuafushiying/jccg.skel", "effect_loop", 10)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(pnode:width()/2, pnode:height() - 280)
		:scale(2)

	self.type = data.type
	for i = 1, 3 do
		self:initRoleData(data.roleData[i],self["rolePanel"..i])
	end
	local path = {[1] = "txt_yxjc.png",[2] = "txt_4qjc.png", [3] ="txt_gjjc.png"}
	self.imgJc:texture("city/pvp/cross_craft/txt/"..path[self.type])
	self:initAward()
end
return CrossExtraAward
