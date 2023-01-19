-- @date:   2019-06-10
-- @desc:   公会发送红包界面

local UnionSendRedPackView = class("UnionSendRedPackView", Dialog)

UnionSendRedPackView.RESOURCE_FILENAME = "union_send_redpack.json"
UnionSendRedPackView.RESOURCE_BINDING = {
	["imgBg"]= "imgBg",
	["info1.imgBG"] = "info1Bg",
	["info2.imgBG"] = "info2Bg",
	["textTitle"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("title"),
		},
	},
	["info1.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("allNum"),
		},
	},
	["info2.textNum"] = {
		varname = "showNum",
		binds = {
			event = "text",
			idler = bindHelper.self("hasNum"),
		},
	},
	["info2.imgIcon"] = {
		varname = "imgIcon",
		binds = {
			event = "texture",
			idler = bindHelper.self("redPackType"),
			method = function(key)
				return dataEasy.getIconResByKey(key)
			end
		},
	},
	["btnSend"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnClick")}
		},
	},
}

function UnionSendRedPackView:onCreate(idx, info, handler)
	self.idx = idx
	self.info = info
	self.callBack = handler
	local showType = info.showType or 1
	if showType == 2 then
		self.imgBg:texture("city/union/redpack/img_hb2_h@.png")
		self.info1Bg:texture("city/union/redpack/box_d_h.png")
		self.info2Bg:texture("city/union/redpack/box_d_h.png")
	end

	self.title = idler.new(info.text)
	self.allNum = idler.new(info.total_count)
	self.hasNum = idler.new(info.total_val)
	self.redPackType = idler.new(info.key)
	performWithDelay(self, function()
		adapt.oneLinePos(self.showNum, self.imgIcon, cc.p(5, 0), "left")
	end, 1/60)

	Dialog.onCreate(self)
end

function UnionSendRedPackView:onBtnClick()
	gGameApp:requestServer("/game/union/redpacket/send",function (tb)
		self.callBack(tb.view)
		self:onClose()
	end, self.info.serIdx - 1, self.info.csv_id)
end

return UnionSendRedPackView