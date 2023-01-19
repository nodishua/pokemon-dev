-- @Date: 2019-01-8
-- @Desc: 升级提升
local ViewBase = cc.load("mvc").ViewBase
local UpgradeNoticeView = class("UpgradeNoticeView", ViewBase)

UpgradeNoticeView.RESOURCE_FILENAME = "common_upgrade_notice.json"
UpgradeNoticeView.RESOURCE_BINDING = {
	["back"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["top"] = "top",
	["top.imgInfo"] = {
		varname = "imgInfo",
		binds = {
			event = "extend",
			class = "text_atlas",
			props = {
				data = bindHelper.self("roleLv"),
				align = "center",
				pathName = "lv_big",
				isEqualDist = false,
				onNode = function(panel)
					panel:xy(415, 200)
				end,
			}
		}
	},
	["top.limitItem.textOldNum"] = "oldLimit",
	["top.limitItem.textNum"] = "newLimit",
	["top.revertItem.textNum"] = "staminaGive",
	["top.limitItem"] = "limitItem",
	["top.revertItem"] = "revertItem",
	["item"] = "noticeItem",
	["list"] = {
		varname = "noticeList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				data = bindHelper.self("noticeDatas"),
				item = bindHelper.self("noticeItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgBG", "imgIconBG", "imgIcon", "lockPanel", "textName", "textDesc", "imgUnLock", "lock", "btnJump")
					local isOpened = v.isOpened
					local path = "common/box/box_panel.png"
					if not isOpened then
						path = "common/box/box_panel_2.png"
					end
					childs.imgBG:texture(path)
					childs.imgIcon:texture(v.icon)
					childs.lockPanel:visible(not isOpened)
					childs.textName:text(v.name)
					childs.textDesc:text(v.desc)
					childs.imgUnLock:visible(v.isOpened)
					childs.lock:get("textLvNum"):text(v.openLv)
					childs.lock:visible(not v.isOpened)
					childs.btnJump:visible(v.isOpened and string.len(v.goToPanel) > 0)

					childs.lockPanel:get("imgBg"):hide()
					local grayState = isOpened and cc.c3b(255, 255, 255) or cc.c3b(128, 128, 128)
					childs.imgIconBG:color(grayState)
					childs.imgIcon:color(grayState)

					text.addEffect(childs.btnJump:get("textNote"), {glow={color=ui.COLORS.GLOW.WHITE}})
					bind.touch(list, childs.btnJump, {methods = {ended = functools.partial(list.clickCell, k, v)}})

					adapt.oneLinePos(childs.textName, childs.imgUnLock, cc.p(50, 0))
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onGoClick"),
			},
		},
	},
}

function UpgradeNoticeView:onCreate(oldLevel)
	audio.playEffectWithWeekBGM("role_levelup.mp3")
	self:initModel()
	sdk.commitRoleInfo(2,function()
		print("commitRoleInfo level up callback")
	end)
	local roleLv = self.roleLv:read()
	local trainerLv = gGameModel.role:read("trainer_level")
	-- self.roleLvTxt:text(roleLv)
	local staminaGive = gRoleLevelCsv[roleLv].staminaGive
	self.oldLimit:text(gRoleLevelCsv[oldLevel].staminaMax)
	self.newLimit:text(gRoleLevelCsv[roleLv].staminaMax)
	self.staminaGive:text(staminaGive)

	local noticeDatas = {}
	local i = 0
	for k,v in orderCsvPairs(csv.notice) do
		if roleLv >= v.noticeLv and roleLv <= v.openLv then
			i = i + 1
			local isOpened = roleLv >= v.openLv --已开启
			local priority = (roleLv == v.openLv) and -1 or v.type --优先级
			table.insert(noticeDatas, {
				csvId = k,
				name = v.name,
				icon = v.icon,
				desc = v.desc,
				openLv = v.openLv,
				isOpened = isOpened,
				priority = priority,
				goToPanel = v.goToPanel,
			})
		end
		if i == 3 then
			break
		end
	end
	self.noticeDatas = noticeDatas
	if next(noticeDatas) == nil then
		self.top:y(760)
		local y = self.imgInfo:y()
		self.imgInfo:y(y + 74)
		self.noticeList:visible(false)
	elseif #noticeDatas < 3 then
		self.top:y(988)
		self.noticeList:size(1605, 495)
		local y = self.noticeList:y()
		self.noticeList:y(y + 94)
	end

	-- 升级特效
	local pnode = self.imgInfo
	widget.addAnimationByKey(pnode, "level/jiesuanshengli.skel", 'jiesuanshengli', "shengji", 1)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(pnode:width()/2 + 15, -340)   -- 位置修正
		:addPlay("shengji_loop")
end

function UpgradeNoticeView:initModel()
	self.roleLv = gGameModel.role:getIdler("level")
end

function UpgradeNoticeView:onGoClick(list, k, v)
	jumpEasy.jumpTo(v.goToPanel)
end

function UpgradeNoticeView:onSortCards(list)
	return function(a, b)
		if a.priority ~= b.priority then
			return a.priority < b.priority
		end
		if a.openLv ~= b.openLv then
			return a.openLv < b.openLv
		end
		return a.csvId < b.csvId
	end
end

return UpgradeNoticeView
