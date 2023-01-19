-- @Date:   2019-05-28
-- @Desc:
-- @Last Modified time: 2019-08-22
local activityTexture = {
	vacation = {
		bg = "activity/server_open/summer_vacation/img_sqqtl_hb.png",
		title = "activity/server_open/summer_vacation/txt_sqqtl_1.png",
		icon = "activity/server_open/summer_vacation/icon_sqqtl_2.png",
	},
}
local ServerOpenPlacardView = class("ServerOpenPlacardView", cc.load("mvc").ViewBase)
ServerOpenPlacardView.RESOURCE_FILENAME = "activity_server_open_placard.json"
ServerOpenPlacardView.RESOURCE_BINDING = {
	["bar"] = {
		varname = "bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("barPoint"),
				maskImg = "activity/server_open/bar_red.png"
			},
		}
	},
	["barBg"] = "barBg",
	["num"] = "num",
	["placard"] = "placard",
	["desc"] = "desc",
}

function ServerOpenPlacardView:onCreate(activityId)
	self.activityId = activityId
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.barPoint = idler.new(0)

	idlereasy.when(self.yyhuodongs, function (_, yyhuodongs)
		local yydata = yyhuodongs[self.activityId] or {}
		local targets = yydata.targets or {}
		local cur = targets.cur or 0
		self.num:text(cur.."/"..targets.all)
		self.barPoint:set(cur/targets.all * 100)
	end)
	local cfg = csv.yunying.yyhuodong[self.activityId]
	if cfg.clientParam.type then
		self.clientType = cfg.clientParam.type
	end
	if self.clientType == "springFestival" and self.clientType == "mayDay" then
		bind.extend(self, self.num, {
			class = "icon_key",
			props = {
				data = {key =  cfg.paramMap.itemId},
				simpleShow = true,
				onNode = function (panel)
					panel:setTouchEnabled(false)
					panel:scale(0.8)
						:x(-300)
				end
			},
		})
	end
	self:updateData(activityId)

	--虽然只是迭代界面但是每个不同ui给的材料都有差异，还是要处理位置差异，比较麻烦，下次最好确定下样式
	for k,v in pairs(activityTexture) do
		if self.clientType == k then
			self.placard:texture(v.bg)
			local spr1 = CSprite.new(v.title)
			local parent = self:getResourceNode()
			spr1:addTo(parent, 10)
			spr1:setAnchorPoint(cc.p(0.5,0.5))
			local sprX, sprY = self.desc:x(), self.desc:y()
			spr1:xy(sprX - 60, sprY)
			self.desc:hide()
			local spr2 = CSprite.new(v.icon)
			spr2:addTo(parent, 11)
			spr2:setAnchorPoint(cc.p(0.5,0.5))
			spr2:xy(self.num:x() - 440, self.num:y())
			spr2:scale(0.8)
			self.bar:x(self.bar:x() - 60)
			self.barBg:x(self.barBg:x() - 60)
			self.num:x(self.num:x() - 60)
		end
	end

	-- 鼠年嘉年华特殊处理 TODO 特殊在继承view里处理
	if self.clientType == "springFestival" then
		text.addEffect(self.num, {outline={color=ui.COLORS.BLACK, size = 3}})
		text.addEffect(self.desc, {outline={color=cc.c4b(244, 77, 87, 255), size = 3}})
	end
	-- 五一嘉年华特殊处理(mayDay)
	-- 暑假七天乐(vacation),只是在五一嘉年华上更改资源，内容不变
	if self.clientType == "mayDay" or self.clientType == "vacation"then
		text.addEffect(self.num, {outline={color=ui.COLORS.BLACK, size = 3}})
		text.addEffect(self:getResourceNode():get("desc"), {outline={color=cc.c4b(243, 110, 80, 255)}})
	end

	if self.clientType == "national" then
		text.addEffect(self.num, {outline = {color = ui.COLORS.BLACK, size = 3}})
		text.addEffect(self:getResourceNode():get("desc"), {outline = {color = cc.c4b(244, 77, 87, 255)}})
	end

	if self.clientType == "doubleYearsDay" then
		text.addEffect(self.num, {outline = {color = ui.COLORS.BLACK, size = 3}})
		text.addEffect(self:getResourceNode():get("desc"), {outline = {color = cc.c4b(114, 188, 62, 255)}})
	end

	if self.clientType == "anniversary" then
		text.addEffect(self.num, {outline = {color = ui.COLORS.BLACK, size = 3}})
		text.addEffect(self:getResourceNode():get("desc"), {outline = {color = cc.c4b(255, 252, 237, 255)}})
	end
end

function ServerOpenPlacardView:updateData(activityId)
	self.activityId = activityId
end

return ServerOpenPlacardView