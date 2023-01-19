--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 裸包
-- 裸包相关代码放在这
--

local ButtonNormal = "img/editor/btn_1.png"
local ButtonClick = "img/editor/btn.png"

local none = {}

function none.commitRoleInfo(ctype, cb)
	return cb()
end

function none._payOnline(cpOrderId, extInfo, amount, rechargeId, productDesc, cb)
	-- payment不统计测试充值
	-- [payment.cn.1 I 200417 16:18:34 payqueue:97] channel `tjgame` account `5e5372e6bb0b082c679c969f` server `game.cn.6` role `5e9581147942ed54859bb139` recharge `9` order (`tjgame_5e9581147942ed54859bb1391587111504`, `5e996659bb0b084194af44e4`) 0.00 ext (0, 0) recharge ok
	amount = 0

	local accountId = stringz.bintohex(gGameModel.role:read("account_id"))
	local params = string.format("accountId=%s&orderStatus=1&orderId=%s&amount=%.2f&game_extra=%s",
		accountId, cpOrderId, amount, extInfo)

	local paybacks = {
		cn = "http://212.64.58.151:28081",
		kr = "http://119.28.235.28:28081",
	}

	gGameApp.net:sendHttpRequest("POST", paybacks[dev.ONLINE_VERSION_LANGUAGE] .. "/tjgame/create",
		params,
		cc.XMLHTTPREQUEST_RESPONSE_STRING,
		function(xhr)
			if xhr.status == 200 then
				local node = cc.Node:create()
				local blackLayer = ccui.Layout:create()
					:size(display.sizeInView)
					:xy(-display.sizeInView.width/2, -display.sizeInView.height/2)
				blackLayer:setBackGroundColorType(1)
				blackLayer:setBackGroundColor(cc.c3b(91, 84, 91))
				blackLayer:setBackGroundColorOpacity(204)
				blackLayer:setTouchEnabled(true)
				local box = ccui.EditBox:create(cc.size(400, 100), "")
				box:setText("12345678")
				box:setFontColor(ui.COLORS.RED)
				local btn = ccui.Button:create(ButtonNormal, ButtonClick)
				btn:setTitleText("支付码OK")
				btn:setTitleColor(cc.c3b(0, 0, 0))
				btn:setTitleFontSize(30)
				btn:setOpacity(100)
				btn:setPressedActionEnabled(true)
				btn:xy(0, -100):show()
				btn:addClickEventListener(function()
					local code = box:getText()
					print('enter pay code', code)
					if #code ~= 8 then
						gGameUI:showTip("支付码错误")
						return
					end
					params = params .. string.format("&code=%s", code)
					gGameApp.net:sendHttpRequest("POST", paybacks[dev.ONLINE_VERSION_LANGUAGE] .. "/tjgame/payment",
						params,
						cc.XMLHTTPREQUEST_RESPONSE_STRING,
						function(xhr)
							if xhr.status == 200 then
								gGameUI:showTip("测试支付成功，稍后到账")
								cb(0)
							else
								print('POST none.pay order Error', APP_CHANNEL, xhr.status, xhr.statusText)
								cb(-1)
							end
						end
					)
					node:removeSelf()
				end)
				node:add(blackLayer, -99):add(box):add(btn):xy(display.sizeInView.width/2, display.sizeInView.height/2):addTo(gGameUI.scene, 999)
			else
				print('POST none.create order Error', APP_CHANNEL, xhr.status, xhr.statusText)
				cb(-1)
			end
		end
	)
end

function none.pay(cpOrderId, extInfo, amount, rechargeId, productDesc, cb)
	if dev.ONLINE_VERSION_LANGUAGE then
		return none._payOnline(cpOrderId, extInfo, amount, rechargeId, productDesc, cb)
	end

	local accountId = stringz.bintohex(gGameModel.role:read("account_id"))
	local params = string.format("accountId=%s&orderStatus=1&orderId=%s&amount=%.2f&game_extra=%s",
		accountId, cpOrderId, amount, extInfo)

	gGameApp.net:sendHttpRequest("POST", "http://192.168.1.96:28081/test/payment",
		params,
		cc.XMLHTTPREQUEST_RESPONSE_STRING,
		function(xhr)
			if xhr.status == 200 then
				gGameUI:showTip("测试支付成功，稍后到账")
				cb(0)
			else
				print('POST none.pay order Error', APP_CHANNEL, xhr.status, xhr.statusText)
				cb(-1)
			end
		end
	)
end

function none.logout(cb)
	return cb()
end

-- TEST: 实名认证
-- function none.login(cb)
-- 	print('!!! none.login')
-- 	sdk.getUserTypeAndIdentity()
-- 	return cb()
-- end

-- function none.queryIdentity(cb)
-- 	print('!!! none.queryIdentity')
-- 	return cb(1)
-- end

-- function none.queryUserType(cb)
-- 	print('!!! none.queryUserType')
-- 	return cb(1)
-- end

return none