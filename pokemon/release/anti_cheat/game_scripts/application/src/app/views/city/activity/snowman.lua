
-- @date:   202020-11-26
-- @desc:   堆雪人活动
local CLOTH_TYPE = {
  shoutao = 1,
  weijin = 2,
  maozi = 3,
}

local BIND_EFFECT= {
	event = "effect",
	data = {outline = {color = cc.c4b(116,59,29,255),  size = 3}}
}
local ViewBase = cc.load("mvc").ViewBase
local ActivitySnowmanView = class("ActivitySnowmanView",ViewBase)

ActivitySnowmanView.RESOURCE_FILENAME = "activity_snowman.json"
ActivitySnowmanView.RESOURCE_BINDING = {
    ["bg"] = "bg",
    ["time"] = "time",
    ["timeText"] = "timeText",
    ["leftList"] = "leftList",
    ["btnClose"] = {
      binds = {
        event = "touch",
        methods = {ended = bindHelper.self("onClose")}
      },
    },
    ["snowmanPanel"] = "snowmanPanel",
    ------------------------------bottomPanel----------------------------------
    ["bottomPanel"] = "bottomPanel",
    ["bottomPanel.progress"] = {
      varname = "progressBar",
      binds = {
        event = "extend",
        class = "loadingbar",
        props = {
          data = bindHelper.self("curPagePro"),
        },
      }
    },
    ["bottomPanel.progressNum"] = "progressNum",
    ["bottomPanel.degreeText"] = {
      varname = "degreeText",
      binds = BIND_EFFECT,
    },
    ["bottomPanel.degreeNum"] = {
      varname = "degreeNum",
      binds = BIND_EFFECT,
    },
    ["bottomPanel.haveText"] = {
      varname = "haveText",
      binds = BIND_EFFECT,
    },
    ["bottomPanel.haveNum"] = {
      varname = "haveNum",
      binds = BIND_EFFECT,
    },
    ["bottomPanel.icon"] = "snowIcon",
    ["bottomPanel.btnUpgrade.txt"] = {
      binds = BIND_EFFECT,
    },
    ["bottomPanel.btnUpgrade"] = {
      binds = {
        {
          event = "touch",
        methods = {ended = bindHelper.self("onUpgrade")}
        },
        {
          event = "extend",
          class = "red_hint",
          props = {
            state = bindHelper.self("upgradeRedHint"),
            onNode = function(node)
              node:xy(295, 145)
            end,
          }
        }
      }
    },
    -------------------------------leftPanel-----------------------------------
    ["leftPanel.mainList"] = {
      varname = "mainList",
      binds = {
        event = "extend",
        class = "listview",
        props = {
          data = bindHelper.self("mainClothDatas"),
          item = bindHelper.self("mainItem"),
          itemAction = {isAction = true},
          onItem = function(list, node, k, v)
            local childs = node:multiget("selected","cloth","Mask")
            childs.selected:visible(v.isSel == true)
            for id,val in orderCsvPairs(v) do
              if val.isSel == true then
                childs.cloth:texture(val.icon)
              end
              childs.Mask:visible(val.isUnlock)
              bind.touch(list, node, {methods = {
                ended = functools.partial(list.clickCell, k, v,val.isUnlock,val.needLevel)
              }})
            end

          end,
        },
        handlers = {
          clickCell = bindHelper.self("onMainItemClick"),
        },
      },
    },
    ["leftPanel.mainItem"] = "mainItem",
    ["leftPanel.subPanel"] = "subPanel",
    ["leftPanel.subPanel.subList"] = {
      varname = "subList",
      binds = {
        event = "extend",
        class = "listview",
        props = {
          data = bindHelper.self("subClothDatas"),
          item = bindHelper.self("subItem"),
          itemAction = {isAction = true},
          onItem = function(list, node, k, v)
            local childs = node:multiget("subIcon","line")
            childs.subIcon:texture(v.icon)
            bind.touch(list, node, {methods = {
              ended = functools.partial(list.clickCell, v)
            }})
          end,
        },
        handlers = {
          clickCell = bindHelper.self("onSubItemClick"),
        },
      },
    },
    ["leftPanel.subPanel.subItem"] = "subItem",
    -------------------------------rightPanel---------------------------------
    ["btnRule"] = {
      binds = {
        event = "touch",
        methods = {ended = bindHelper.self("onRules")}
      }
    },
    ["btnAward"] = {
      binds = {
        {
          event = "touch",
          methods = {ended = bindHelper.self("onAward")}
        },
        {
          event = "extend",
          class = "red_hint",
          props = {
            state = bindHelper.self("awardRedHint"),
            onNode = function(node)
              node:xy(330, 140)
            end,
          }
        }
      }
    },
}

function ActivitySnowmanView:onCreate(activityId)
  self:initModel()
  self.activityId = activityId
  local yyCfg = csv.yunying.yyhuodong[activityId]
  local huodongID = yyCfg.huodongID
  self.huodongID = huodongID
  self.snowBallId = yyCfg.paramMap.items[1]
  self.yyCfg = yyCfg
  self.subListVisible = false
  self.subPanel:visible(self.subListVisible)
  for _,val in ipairs(yyCfg.paramMap.items) do
    if val then
      self.snowBallId = val
      break
    end
  end
  self.selIdx:addListener(function(val, oldval)
    if self.mainClothDatas:atproxy(oldval) then
      self.mainClothDatas:atproxy(oldval).isSel = false
		end
		if self.mainClothDatas:atproxy(val) then
      self.mainClothDatas:atproxy(val).isSel = true
		end
	end)
  --时间
  self:updateTime()
  --雪花icon点击
  bind.click(self, self.snowIcon, {method = function()
    local params = {key = self.snowBallId}
    gGameUI:showItemDetail(self.snowIcon, params)
        end})
  idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
    local yyData = self.yyhuodongs:read()[activityId] or {}
    self.yyData = yyData
    self.info = yyData.info
    self.snowLevel:set(self.info.level)
    self.degreeNum:text(self.info.level)
    self.haveNum:text(dataEasy.getNumByKey(self.snowBallId))
    --红点
    if dataEasy.getNumByKey(self.snowBallId) > 0 then
      self.upgradeRedHint:set(true)
    else
      self.upgradeRedHint:set(false)
    end
    self.awardRedHint:set(false)
    for _,v in pairs(yyData.stamps) do
      if v == 1 then
        self.awardRedHint:set(true)
        break
      end
    end
    adapt.oneLinePos(self.degreeText, self.degreeNum, cc.p(5,0))
    adapt.oneLinePos(self.haveText, {self.haveNum,self.snowIcon}, {cc.p(-15,0),cc.p(5,0)})
    --进度条
    for id,v in orderCsvPairs(csv.yunying.huodongcloth_level) do
      if v.huodongID == huodongID and v.level == self.info.level then
        self.curLevelMax = v.needExp
        break
      end
    end
    if self.info.exp > self.curLevelMax then
      self.progressNum:text(self.curLevelMax.."/"..self.curLevelMax)
    else
      self.progressNum:text(self.info.exp.."/"..self.curLevelMax)
    end
    self.curPagePro:set(math.min(100, self.info.exp / self.curLevelMax * 100))
    self:initClothDatas()
  end)
end

function ActivitySnowmanView:initModel()
  self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
  -- 进度条进度
  self.curPagePro = idler.new(0)
  self.snowLevel = idler.new(0)
  self.mainClothDatas = idlers.newWithMap({})
  self.subClothDatas = idlers.newWithMap({})
  self.selIdx = idler.new(1)
  self.upgradeRedHint = idler.new(false)
  self.awardRedHint = idler.new(false)
end
function ActivitySnowmanView:initClothDatas()
  local mainClothDatas = {}
  local targets = self.yyData.targets
  for k,v in orderCsvPairs(csv.yunying.huodongcloth_level) do
    if v.huodongID == self.huodongID and v.unlockPart then
      --衣服
      if v.unlockPart > 0 and v.unlockPart <= 100 then
        mainClothDatas[v.unlockPart] = {}
        for id,val in orderCsvPairs(csv.yunying.huodongcloth_part) do
          if val.huodongID == self.huodongID and val.belongPart == v.unlockPart then
            local isSel = val.isDefault
            if targets[tostring(v.unlockPart)] then
              if targets[tostring(v.unlockPart)] == id then
                isSel = true
              else
                isSel = false
              end
            end
            table.insert(mainClothDatas[v.unlockPart], {
              id = id,
              icon = val.icon,
              showType = val.showType,
              res = val.res,
              isSel = isSel,
              lookPos = val.lookPos,
              needLevel = v.level,
              isUnlock = self.snowLevel:read() < v.level,
            })
            if self.snowLevel:read() < v.level then
                if v.unlockPart == CLOTH_TYPE.maozi then
                  self.snowmanPanel:get("maozi"):visible(false)
                elseif v.unlockPart == CLOTH_TYPE.shoutao then
                  self.snowmanPanel:get("shoutao"):visible(false)
                elseif v.unlockPart == CLOTH_TYPE.weijin then
                  self.snowmanPanel:get("weijin"):visible(false)
                end
            else
              if v.unlockPart == CLOTH_TYPE.maozi and isSel then
                self.snowmanPanel:get("maozi"):visible(true)
                self.snowmanPanel:get("maozi"):texture(val.res)
              elseif v.unlockPart == CLOTH_TYPE.shoutao and isSel then
                self.snowmanPanel:get("shoutao"):visible(true)
                self.snowmanPanel:get("shoutao"):texture(val.res)
              elseif v.unlockPart == CLOTH_TYPE.weijin and isSel then
                self.snowmanPanel:get("weijin"):visible(true)
                self.snowmanPanel:get("weijin"):texture(val.res)
              end
            end
          end
        end
      else
        --装饰
        for id,val in orderCsvPairs(csv.yunying.huodongcloth_part) do
          if self.snowLevel:read() >= v.level and val.huodongID == self.huodongID and val.belongPart == v.unlockPart then
            local panel = self.snowmanPanel:get("decoration"..id)
            local xPos = val.lookPos.x
            local yPos = val.lookPos.y
            if not panel then
              panel = ccui.Layout:create()
                :xy(cc.p(750,400))
                :size(650, 350)
                :addTo(self.snowmanPanel, val.zOrder, "decoration"..id)
              if val.showType == "pic" then
                ccui.ImageView:create(val.res)
                  :xy(xPos,yPos)
                  :addTo(panel, 4, "decoration")
                  :scale(2)
              else
                  widget.addAnimationByKey(panel, val.res, "decoration", "night_loop", 120)
                    :scale(2)
                    :xy(xPos, yPos)
              end
              else
                panel:xy(cc.p(750,400))
            end
          end
        end
      end
    end
  end
  if #mainClothDatas ~= 0 then
		local curIdx = math.min(#mainClothDatas, self.selIdx:read())
    self.selIdx:set(curIdx, true)
    mainClothDatas[self.selIdx:read()].isSel = true
  end
  self.mainClothDatas:update(mainClothDatas)
end
-- 规则
function ActivitySnowmanView:onRules()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end
function ActivitySnowmanView:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.rules)
        end),
        c.noteText(153),
        c.noteText(109001, 109020),
    }
    return context
end
--升级
function ActivitySnowmanView:onUpgrade()
  if dataEasy.getNumByKey(self.snowBallId) == 0 then
    gGameUI:showTip(gLanguageCsv.inadequateProps)
    return
  end
  gGameApp:requestServer("/game/yy/cloth/item/use", function(tb)
    gGameUI:showGainDisplay(tb.view.result)
  end, self.activityId)
end
--等级奖励
function ActivitySnowmanView:onAward()
  gGameUI:stackUI("city.activity.snowman_reward", nil, nil,self.activityId)
end
--活动倒计时
function ActivitySnowmanView:updateTime()
	local yyEndtime = gGameModel.role:read("yy_endtime")
		local countdown = yyEndtime[self.activityId] - time.getTime()
		bind.extend(self, self.time, {
			class = 'cutdown_label',
			props = {
				time = countdown,
				endFunc = function()
					self.time:text(gLanguageCsv.activityOver)
				end,
			}
		})
end

function ActivitySnowmanView:onMainItemClick(list, k, v,isUnlock,needLevel)
  if isUnlock then
    gGameUI:showTip(string.format(gLanguageCsv.snowNeedLevel,needLevel))
    return
  end
  if self.selIdx:read() == k then
    self.subListVisible = not self.subListVisible
  else
    self.subListVisible = true
    self.selIdx:set(k)
  end
  self.subPanel:visible(self.subListVisible)
  local result = {}
  local t = self.mainClothDatas:atproxy(k)
  for i, log in pairs(t) do
    if type(log) == "table" and i ~=  "__sorted" then
      local log = table.shallowcopy(log)
      table.insert(result, table.shallowcopy(log))
    end
	end
  self.subClothDatas:update(result)
end

function ActivitySnowmanView:onSubItemClick(list, v)
  local targets = self.yyData.targets
  if targets[tostring(self.selIdx:read())] == v.id then
    return
  end
  gGameApp:requestServer("/game/yy/cloth/decorate", function(tb)
  end, self.activityId,self.selIdx:read(),v.id)
end

function ActivitySnowmanView:onClose()
	ViewBase.onClose(self)
end

return ActivitySnowmanView
