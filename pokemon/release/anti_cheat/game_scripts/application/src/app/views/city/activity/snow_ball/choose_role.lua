local SnowBallChooseRole = class('SnowBallChooseRole', cc.load("mvc").ViewBase)
SnowBallChooseRole.RESOURCE_FILENAME = 'snow_ball_choose_role.json'

SnowBallChooseRole.RESOURCE_BINDING = {
	["panel1"] = "panel1",
	["panel2"] = "panel2",
	["panel3"] = "panel3",
	["btnChoose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChooseClick")}
		},
	},
}

function SnowBallChooseRole:onCreate(id)
	self.activityId = id
	self.chooseCsvId = 0
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.snowBallGameChooseSprite, subTitle = "CHOOSE ELVES"})
	local tData = {}
	for i, v in csvPairs(csv.yunying.snowball_element) do
		local yyCfg = csv.yunying.yyhuodong[id]
		local huodongID = yyCfg.huodongID
		if v.belongs == 3 and v.huodongID == huodongID then
			local t = csvClone(v)
			t.csvId = i
			table.insert(tData, t)
		end
	end
	for i = 1, 3 do
		local panel = self["panel"..i]
		local data = tData[i]
		bind.touch(self, panel, {methods = {ended = function()
			self.chooseCsvId = data.csvId
			for j = 1, 3 do
				local imgSel = self["panel"..j]:get("imgSel")
				imgSel:setVisible(i == j)
			end
		end}})
		local cardName = data.attr.cardName or data.attr.careName --todoerror
		print(cardName)
		panel:get("imageSprite"):texture(string.format("activity/snow_ball/%s.png",cardName))
		local imgSm = panel:get("imgSm")
		local tImgSm = {}
		for i = 1 , data.attr.life - 1 do
			imgSm:clone():addTo(imgSm:getParent())
				:xy(imgSm:x() + 49 * i, imgSm:y())
		end

		local imgSd = panel:get("imgSd")
		for i = 1, data.attr.showSpeed - 1 do
			imgSd:clone():addTo(imgSd:getParent())
				:xy(imgSd:x() + 49 * i, imgSd:y())
		end

		local imgTx = panel:get("imgTx")
		for i = 1, data.attr.showWeight - 1 do
			imgTx:clone():addTo(imgTx:getParent())
				:xy(imgTx:x() + 49 * i, imgTx:y())
		end
	end
end

function SnowBallChooseRole:initModel()
	-- self.roleName = gGameModel.role:read("name")
end

function SnowBallChooseRole:onChooseClick()
	if self.chooseCsvId == 0 then
		gGameUI:showTip(gLanguageCsv.chooseSpriteTips)
		return
	end
	local activityId = self.activityId
	local csvId = self.chooseCsvId
	self:onClose()
	gGameUI:stackUI("city.activity.snow_ball.game", nil, nil, activityId, csvId)
end

return SnowBallChooseRole