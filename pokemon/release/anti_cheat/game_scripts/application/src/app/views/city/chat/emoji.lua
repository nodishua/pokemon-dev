-- @desc 表情

-- 一页显示的表情数量
local ONE_PAGE_COUNT = 10

local ChatEmojiView = class("ChatEmojiView", Dialog)
ChatEmojiView.RESOURCE_FILENAME = "chat_emoji.json"
ChatEmojiView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["bg1"] = "bg1",
	["btnItem"] = "btnItem",
	["btnList"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("btnDatas"),
				item = bindHelper.self("btnItem"),
				showTab = bindHelper.self("showTab"),
				onItem = function(list, node, k, v)
					idlereasy.when(list.showTab, function(_, showTab)
						local size = node:size()
						if showTab == k then
							node:get("normal"):hide()
							node:get("selected"):show()
							node:get("selected.txt"):text(v)
							adapt.oneLineCenterPos(cc.p(size.width/2, size.height/2 - 10), {node:get("selected.logo"), node:get("selected.txt")}, cc.p(10, 0))
						else
							node:get("normal"):show()
							node:get("selected"):hide()
							node:get("normal.txt"):text(v)
							adapt.oneLineCenterPos(cc.p(size.width/2, size.height/2 - 10), {node:get("normal.logo"), node:get("normal.txt")}, cc.p(10, 0))
							bind.touch(list, node:get("normal"), {methods = {ended = functools.partial(list.clickCell, k)}})
						end
					end)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBtnItemClick"),
			},
		},
	},
	["pagePanel"] = "pagePanel",
	["pageview"] = {
		varname = "pageview",
		binds = {
			event = "extend",
			class = "pageview",
			props = {
				data = bindHelper.self("pageDatas"),
				item = bindHelper.self("pagePanel"),
				onItem = function(list, node, k, v)
					list:setClippingEnabled(true)
					local childs = node:multiget("list", "subList", "item")
					childs.list:setScrollBarEnabled(false)
					childs.subList:setScrollBarEnabled(false)
					local count = #v
					local row, col = mathEasy.getRowCol(count, 5)
					for i = 1, row do
						local subList = childs.subList:clone():show()
						childs.list:pushBackCustomItem(subList)
						local col = i == row and col or 5
						for j = 1, col do
							local idx = j + (i - 1) * 5
							local item = childs.item:clone():show()
							local cfg = gEmojiCsv[v[idx].key]
							item:get("icon"):texture(cfg.resource)
							bind.click(self, item, {method = functools.partial(list.itemClick, k, v[idx])})
							subList:pushBackCustomItem(item)
						end
					end
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onSelPicture"),
			},
		},
	},
	["dot"] = "dot",
	["dotList"] = {
		varname = "dotList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("pointDatas"),
				item = bindHelper.self("dot"),
				onItem = function(list, node, k, v)
					local path = string.format("common/icon/logo_%s_fy.png", v.isCur == true and "highlight" or "normal")
					node:texture(path)
				end,
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
			},
		},
	},
}

function ChatEmojiView:onCreate(sendData, channel, freshList)
	self.sendData = sendData
	self.channel = channel

	self.freshList = freshList
	local worldPos = gGameUI:getConvertPos(self.freshList)
	self.unlockKey = gUnlockCsv.roleChat
	if channel == "role" then
		local x = worldPos.x + self.bg:size().width/2 - 15
		local y = worldPos.y + self.bg:size().height/2 - 50
		self:getResourceNode():xy(x, y)
	else
		self.unlockKey = gUnlockCsv.worldChat
		local width = 120
		self.bg:width(self.bg:width() - width)
		self.bg1:width(self.bg1:width() - width)
		self.btnList:width(self.btnList:width() - width)
			:x(self.btnList:x() + width/2)

		width = math.min(width, 80)
		self.pageview:width(self.pageview:width() - width)
			:x(self.pageview:x() + width/2)
		self.pagePanel:width(self.pagePanel:width() - width)
		local pageList = self.pagePanel:get("list")
		local pageSubList = self.pagePanel:get("subList")
		pageList:width(pageList:width() - width)
		pageSubList:width(pageSubList:width() - width)
		pageSubList:setItemsMargin(0)

		local x = worldPos.x + self.bg:size().width/2 - 20
		local y = worldPos.y + self.bg:size().height/2 - 32
		self:getResourceNode():xy(x, y)
	end

	local emojiCount = userDefault.getForeverLocalKey("chatEmoji", {})
	-- 1、常用；2-n 根据配置加页签
	local commonUseData = {}
	self.datas = {}
	for k, v in pairs(gEmojiCsv) do
		-- count, id 用于排序
		if emojiCount[k] and emojiCount[k] > 0 then
			table.insert(commonUseData, {key = k, count = emojiCount[k] or 0, id = v.id})
		end
		for _, tab in ipairs(v.tab) do
			for j = #self.datas + 1, tab do
				self.datas[j] = {}
			end
			table.insert(self.datas[tab], {key = k, id = v.id})
		end
	end
	for _, v in ipairs(self.datas) do
		table.sort(v, function (a,b)
			return a.id < b.id
		end)
	end
	self.btnDatas = {}
	for i = #self.datas, 1, -1 do
		if #self.datas[i] == 0 then
			table.remove(self.datas, i)
		else
			table.insert(self.btnDatas, 1, gLanguageCsv["emojiTab" .. i] or "")
		end
	end
	if #commonUseData ~= 0 then
		table.sort(commonUseData, function (a,b)
			if a.count ~= b.count then
				return a.count > b.count
			end
			return a.id < b.id
		end)
		table.insert(self.datas, 1, commonUseData)
		table.insert(self.btnDatas, 1, gLanguageCsv.commonUse)
	end

	self.showTab = idler.new(1)
	self.pageIndex = idler.new(1)
	self.pageview:addEventListener(function(ccc)
		self.pageIndex:set(math.min(self.pageview:getCurPageIndex() + 1, self.pointDatas:size()))
	end)

	self.pageDatas = idlers.new()
	self.pointDatas = idlers.new()
	idlereasy.when(self.showTab, function(_, showTab)
		local t = {}
		local pData = {}
		for i = 1, #self.datas[showTab], ONE_PAGE_COUNT do
			table.insert(t, arraytools.slice(self.datas[showTab], i, ONE_PAGE_COUNT))
			table.insert(pData, {isCur = (i == 1)})
		end
		self.pageDatas:update(t)
		self.pointDatas:update(pData)
		self.pageIndex:set(1)
		self.dotList:visible(#pData > 1)
	end)
	idlereasy.when(self.pageIndex, function(_, pageIndex)
		for k, v in self.pointDatas:ipairs() do
			v:proxy().isCur = (k == pageIndex)
		end
	end)

	Dialog.onCreate(self, {noBlackLayer = true, clickClose = true})
end

function ChatEmojiView:setReuseEmoji(data)
	local t = userDefault.getForeverLocalKey("chatEmoji", {})
	for k, v in pairs(data) do
		t[k] = v + (t[k] or 0)
	end
	userDefault.setForeverLocalKey("chatEmoji", t)
end

function ChatEmojiView:onSelPicture(list, k, v)
	if not dataEasy.isUnlock(self.unlockKey) then
		gGameUI:showTip(dataEasy.getUnlockTip(self.unlockKey))
		return
	end
	local key = v.key
	gGameApp:requestServer("/game/chat", function (tb)
		self:setReuseEmoji({[key] = 1})
		self.freshList:jumpToBottom()
		self:onClose()
	end,"["..key.."]", self.channel, self.sendData)
end

function ChatEmojiView:onBtnItemClick(list, index)
	self.showTab:set(index)
end

return ChatEmojiView