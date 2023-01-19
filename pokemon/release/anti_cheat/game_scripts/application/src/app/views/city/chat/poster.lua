-- @Date:   2019-7-9 18:21:21
-- @Desc:	海报界面

local ViewBase = cc.load("mvc").ViewBase
local ChatPoster = class("ChatPoster", Dialog)
ChatPoster.RESOURCE_FILENAME = "chat_poster.json"
ChatPoster.RESOURCE_BINDING = {
	["btnClose"] = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["pos0"] = "pos0",
	["pos1"] = "pos1",
	["pos2"] = "pos2"

}
function ChatPoster:onCreate()
	Dialog.onCreate(self, {blackType = 1})

	local rich0 = rich.createByStr("#C0x000000#"..gLanguageCsv.preventFraudPosterTitle, 70)
	rich0:setAnchorPoint(0.5, 0.5)
	rich0:formatText()
	rich0:addTo(self:getResourceNode(), 10)
			:xy(self.pos0:xy())

	local rich1 = rich.createWithWidth("#C0x5b545b#"..gLanguageCsv.preventFraudPosterDes1, 50, nil, 600)
	rich1:setAnchorPoint(0, 0.5)
	rich1:formatText()
	rich1:addTo(self:getResourceNode(), 10)
			:xy(self.pos1:xy())

	local rich2 = rich.createWithWidth("#C0x5b545b#"..gLanguageCsv.preventFraudPosterDes2, 50, nil, 600)
	rich2:formatText()
	rich2:setAnchorPoint(0, 0.5)
	rich2:addTo(self:getResourceNode(), 10)
			:xy(self.pos2:xy())
end

return ChatPoster