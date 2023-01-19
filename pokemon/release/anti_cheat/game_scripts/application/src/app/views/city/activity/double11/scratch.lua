--刮奖
local Double11Scratch = class("Double11Scratch", Dialog)

Double11Scratch.RESOURCE_FILENAME = "double_11_scratch.json"
Double11Scratch.RESOURCE_BINDING = {
    ["imgBG.imgGJ"] = {
		varname = "imgGJ",
		binds = {
			event = "touch",
			method = bindHelper.self("onScratchClick"),
			scaletype = 0,
		},
	},
	["imgBG.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("num"),
		},
	},
	["btnClose"] = {
		binds = {
			{
				event = "touch",
				method = bindHelper.self("onClose"),
			},
			{
				event = "visible",
				idler = bindHelper.self("opened"),
			},
		},
	},
	["textNote"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("opened"),
		},
	},
}

function Double11Scratch:onCreate(activityId, csvId, num)
	self.opened = idler.new(false)
	self.csvId = csvId
	self.num = idler.new(string.format(gLanguageCsv.double11Num,num))
	Dialog.onCreate(self)
	self.activityId = activityId
	self.moveLength = 0
	self.lastX = 0
	self.lastY = 0
end

function Double11Scratch:onScratchClick(sender, event)
	if event.name == "began" then
		self.lastX = event.x
		self.lastY = event.y
	elseif event.name == "moved" then
		self.moveLength = self.moveLength + math.sqrt(math.pow((self.lastX - event.x), 2) +  math.pow((self.lastY - event.y), 2))
		self.lastX = event.x
		self.lastY = event.y
		if self.moveLength > 2000 then
			sender:texture("activity/double_11/img_guakai_3.png")
		elseif self.moveLength > 1350 then
			sender:texture("activity/double_11/img_guakai_2.png")
		elseif self.moveLength > 600 then
			sender:texture("activity/double_11/img_guakai_1.png")
		end
	elseif event.name == "ended" then
		if self.moveLength > 2000 then
			gGameApp:requestServer("/game/yy/double11/card/open",function (tb)
				self.opened:set(true)
				sender:hide()
			end, self.activityId, self.csvId)
		end
	end
end

function Double11Scratch:onClose()
	if self.opened:read() == true then
		Dialog.onClose(self)
	end
end

return Double11Scratch