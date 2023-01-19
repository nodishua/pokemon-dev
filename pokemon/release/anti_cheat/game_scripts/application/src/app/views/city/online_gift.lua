-- @date: 2019-6-25 16:10:59
-- @desc: 在线礼包预览

local function getCountTime(totalTime, starttime, idx)
	local currtentTime = time.getTime()
	local periods = csv.online_gift[idx+1].periods*60
	local finalTime = periods - (currtentTime - starttime + totalTime)
	return finalTime
end

local OnlineGiftView = class("OnlineGiftView", Dialog)
OnlineGiftView.RESOURCE_FILENAME = "online_gift.json"
OnlineGiftView.RESOURCE_BINDING = {
	["labelTime"] = {		-- 倒计时
		varname = "labelTime",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(250, 240, 208, 255)}}
		}
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["list"] = "list",
}

function OnlineGiftView:onCreate(params)
	self.giftData = {}
	local data = gGameModel.daily_record:read("online_gift")
	local idx = data.idx + 1
	uiEasy.createItemsToList(self, self.list, csv.online_gift[idx].awardShow, {margin = 11, scale = 0.9, onAfterBuild = function()
		self.list:setItemAlignCenter()
	end})

	-- 倒计时
	self:enableSchedule()
	OnlineGiftView.setCountdown(self, self.labelTime, {data = data})

	-- 刷新主界面倒计时，与预览界面同步
	OnlineGiftView.setCountdown(params.view, params.uiTime, {data = data, tag = params.tag, cb = params.cb})

	Dialog.onCreate(self, {blackType = 1})
end

-- @desc 设置倒计时
-- @param params {data, tag, cb}
function OnlineGiftView.setCountdown(view, uiTime, params)
	local data = params.data
	local tag = params.tag or 1

	local starttime = data.starttime or 0
	local totalTime = data.totaltime or 0
	local idx = data.idx or 0
	local currtentTime = time.getTime()
	local periods = csv.online_gift[idx+1].periods*60
	local endTime = periods + starttime - totalTime

	bind.extend(view, uiTime, {
		class = 'cutdown_label',
		props = {
			delay = 1,
			endTime = endTime + 1,
			tag = tag,
			endFunc = function()
				if params.cb then
					params.cb()
				else
					uiTime:text(time.getCutDown(0).str)
				end
			end,
		}
	})
end

return OnlineGiftView