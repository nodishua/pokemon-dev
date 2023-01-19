local ViewBase = cc.load("mvc").ViewBase
local TalentResetView = class("TalentResetView", Dialog)

TalentResetView.RESOURCE_FILENAME = "talent_reset.json"
TalentResetView.RESOURCE_BINDING = {
    ["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["btnNo"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["btnOk"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSureBtnClick")},
		},
	},
    ["title"] = "title",
    ["icon"] = "rmbIcon",
    ["num"] = "rmbNum",
    ["txt1"] = "txt1",
    ["txt2"] = "txt2",
}
function TalentResetView:onCreate(params)
    self:initModel()
    self.params = params or {}
    self.from = self.params.from or "talent"
    self.cost = self.params.cost or (self.params.treeID and gCommonConfigCsv.talentResetCost or gCommonConfigCsv.talentResetAllCost)
    self.rmbNum:text("X"..self.cost)
    if self.from == "dispatch_task" then
        self.title:text(self.params.title)
        self.txt1:text(self.params.txt1)
        self.txt2:text(self.params.txt2)
        adapt.oneLineCenterPos(cc.p(self.title:x(), self.txt1:y()), {self.txt1, self.rmbNum, self.rmbIcon}, cc.p(15, 0))
    end
    if self.params.treeID then
        self.txt1:text(gLanguageCsv.talentTreeOneCost)
        adapt.oneLineCenterPos(cc.p(self.title:x(), self.txt1:y()), {self.txt1, self.rmbIcon, self.rmbNum}, cc.p(15, 0))
    elseif matchLanguage({"kr"}) then
        --kr 居中显示
        adapt.oneLineCenterPos(cc.p(self.title:x(), self.txt1:y()), {self.txt1, self.rmbIcon, self.rmbNum}, cc.p(15, 0))
    end
    adapt.setTextAdaptWithSize(self.txt2, {size = cc.size(850, 200), vertical = "top", horizontal = "center"})
    self.txt2:setAnchorPoint(0.5, 1)
    self.txt2:x(self.title:x())
    Dialog.onCreate(self)
end

function TalentResetView:initModel()
    self.rmb = gGameModel.role:getIdler("rmb")
    self.level = gGameModel.role:read("level")
    self.talentTree = gGameModel.role:getIdler("talent_trees")
end

function TalentResetView:onSureBtnClick()
    if self.rmb:read() < self.cost then
        gGameUI:showTip(gLanguageCsv.buyRMBNotEnough)
        return
    end
    local isCost = false
    if self.params.treeID then
        if self.talentTree:read()[self.params.treeID] and self.talentTree:read()[self.params.treeID].cost > 0 then
            isCost = true
        end
    else
        for i,v in csvMapPairs(csv.talent_tree) do
            if matchLanguage(v.languages) and self.level >= v.showLevel then
                if self.talentTree:read()[i] and self.talentTree:read()[i].cost > 0 then
                    isCost = true
                    break
                end
            end
        end
    end

    if not isCost and self.from == "talent" then
        gGameUI:showTip(gLanguageCsv.talentResetNoIDs)
        return
    end
    if self.from == "talent" then
        gGameApp:requestServer("/game/talent/reset", function (tb)
            self:onClose()
        end, self.params.treeID)
    end
    if self.from == "dispatch_task" then
        if self.params.typ == "end" then
            gGameApp:requestServer("/game/dispatch/task/award", function (tb)
                local cb = self.params.cb
                ViewBase.onClose(self)
                cb(tb)
            end, unpack(self.params.requestParams or {}))
        else
            gGameApp:requestServer("/game/dispatch/task/refresh", function (tb)
                self:onClose()
            end, true)
        end
    end
end

return TalentResetView
