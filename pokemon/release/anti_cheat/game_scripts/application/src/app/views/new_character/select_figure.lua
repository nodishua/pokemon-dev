-- @Date:   2019-05-24

local SelectFigureView = class("SelectFigureView", cc.load("mvc").ViewBase)
SelectFigureView.RESOURCE_FILENAME = "character_select_figure.json"
SelectFigureView.RESOURCE_BINDING = {
	["leftPanel"] = {
		varname = "leftPanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:selectClick(1)
			end)}
		}
	},
	["leftPanel.figure"] = "leftFigure",
	["rightPanel"] = {
		varname = "rightPanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:selectClick(2)
			end)}
		}
	},
	["rightPanel.figure"] = "rightFigure",
	["leftPanel.select"] = "leftSelect",
	["rightPanel.select"] = "rightSelect",
	["btnRandom"] = {
		varname = "rightPanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRandom")}
		}
	},
	["input"] = "input",
	["btnSure"] = {
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.self("onSure")}
		}
	},
}

SelectFigureView.RESOURCE_STYLES = {
	full = true,
}

function SelectFigureView:onCreate(cb)
	self.cb = cb
	if not matchLanguage({"kr"}) then
		self:onRandom()
	end
	self.input:setPlaceHolderColor(ui.COLORS.DISABLED.WHITE)
	self.input:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)

	self.figures = csv.newbie_init[1].figures
	self.select = idler.new(0)
	self.leftFigureCfg = gRoleFigureCsv[self.figures[1]]
	self.rightFigureCfg = gRoleFigureCsv[self.figures[2]]
	self.leftSpine = widget.addAnimation(self.leftFigure, self.leftFigureCfg.resSpine, "standby_loop1")
		:scale(2.3)
		:xy(self.leftFigure:size().width/2, -100)
	self.rightSpine = widget.addAnimation(self.rightFigure, self.rightFigureCfg.resSpine, "standby_loop1")
		:scale(2.3)
		:xy(self.rightFigure:size().width/2, -100)
	idlereasy.when(self.select, function (_, val)
		if val ~= 0 then
			local id = self.figures[val]
			self.leftSelect:visible(val == 1)
			self.rightSelect:visible(val == 2)
			self.leftSelect:visible(val == 1)
			self.rightSelect:visible(val == 2)
			if val == 1 then
				self.leftSpine:x(self.leftFigure:size().width/2 + 200)
				self.leftSpine:play("standby_loop2")
				self.rightSpine:play("weixuanzhong")
				self.rightSpine:addPlay("standby_loop1")
				self.rightSpine:xy(self.rightFigure:size().width/2, -100)
			else
				self.leftSpine:xy(self.leftFigure:size().width/2, -100)
				self.leftSpine:play("weixuanzhong")
				self.leftSpine:addPlay("standby_loop1")
				self.rightSpine:play("standby_loop2")
				self.rightSpine:x(self.rightFigure:size().width/2 - 180)
			end
		else
			itertools.invoke({self.leftSelect, self.rightSelect}, "hide")
		end
		itertools.invoke({self.leftSelect, self.rightSelect}, "y", 100)
	end)
	blacklist:addListener(self.input, nil, functools.partial(self.nameAdapt, self))
end

function SelectFigureView:selectClick(index)
	self.select:set(index)
end

function SelectFigureView:onRandom()
	self.input:text(beauty.singleTextLimitWord(randomName(), {fontSize = 40}, {width = 300, replaceStr = "", onlyText = true}))
end

function SelectFigureView:nameAdapt(txt)
	txt = txt or self.input:text()
	local str = beauty.singleTextLimitWord(txt, {fontSize = 40}, {width = 300, replaceStr = "", onlyText = true})
	self.input:text(str)
end

function SelectFigureView:onSure()
	self:nameAdapt()
	if self.select:read() == 0 then
		gGameUI:showTip(gLanguageCsv.chooseFigure)
		return
	end
	local text = self.input:text()
	if uiEasy.checkText(text) then
		gGameApp:requestServer("/game/role/newbie/init", function(tb)
			self:addCallbackOnExit(self.cb)
			self:onClose()
		end, 1, text, self.figures[self.select:read()])
	end
end

return SelectFigureView
