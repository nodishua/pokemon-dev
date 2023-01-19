local MultiForce = {}

local _msgpack = require '3rd.msgpack'
local msgpack = _msgpack.pack
local msgunpack = _msgpack.unpack

local url = 'http://192.168.1.96:4455'

local parms = {
    ['card_id']= 11,
    ['advance'] =  5,
    ['star']= 10,
    ['level']= 60,
}



local function readAndUnpack(filename)
	local fp = io.open(filename, 'rb')
	local data = fp:read('*a')
	fp:close()
	return msgunpack(data)
end

local function removeInternalTable(t)
	--data读出来会加上__raw和__proxy 这里修下型
	local ret = {}
	for k,v in pairs(t) do
		local hasRaw = false
		local newTb = {}
		if type(v) == "table" then
			for k2,v2 in pairs(v) do
				if k2 == "__raw" then
					hasRaw = true
					for k3,v3 in pairs(v2) do
						if type(v3) == "table" then
							newTb[k3] = removeInternalTable(v3)
						else
							newTb[k3] = v3
						end
					end
				end
			end
		end

		if not hasRaw then
			ret[k] = v
		else
			ret[k] = newTb
		end
	end
	print("###########")
	print_r(ret)
	return ret
end

function MultiForce.requestFight(self,fightRoleOut,idx,cb )
	local data = self.arenaData or readAndUnpack("arena_qiangdu.play")
	local play = msgunpack(data[2])

	play.cards = {}
	play.card_attrs = {}
	play.defence_cards = {}
	play.defence_card_attrs = {}

	play.rand_seed = math.random(1,1000000)
	
	for i = 1,6 do
		local id = fightRoleOut[i].id
		play.cards[i] = id
		play.card_attrs[id] = fightRoleOut[i]
	end
	for j = 1,6 do
		local id = fightRoleOut[j+6].id
		play.defence_cards[j] = id
		play.defence_card_attrs[id] = fightRoleOut[j+6]
	end

	data[2] = msgpack(play)

	-- data = msgpack(data)
	-- local fp = io.open("aaa.play", 'wb')
	-- fp:write(data)
	-- fp:close()

    MultiForce.sendHttpRequest(self,"POST", url .. "/send_to_agent", msgpack(data), cc.XMLHTTPREQUEST_RESPONSE_JSON, function(xhr)
        -- print('postDisableWordCheck', xhr, xhr.status, xhr.response)
        -- dump(xhr,nil,99)
        if xhr.status == 200 then
            local t = json.decode(xhr.response)
			-- dump(t,nil,99)
			return cb({ret = true}, t,fightRoleOut,idx)
        end
        return cb({ret = false}, nil,fightRoleOut,idx)
    end)
end

function MultiForce.requestFightSolo(self,fightRoleOut,idx,cb )
	local data = self.craftData or readAndUnpack("craft_qiangdu.play")
	local play = msgunpack(data[2])

	play.cards = {}
	play.card_attrs = {}
	play.defence_cards = {}
	play.defence_card_attrs = {}

	play.rand_seed = math.random(1,1000000)
	
	for i = 1,3 do
		local id = fightRoleOut[1].id
		play.cards[i] = id
		play.card_attrs[id] = fightRoleOut[1]
	end
	for j = 1,3 do
		local id = fightRoleOut[7].id
		play.defence_cards[j] = id
		play.defence_card_attrs[id] = fightRoleOut[7]
	end

	data[2] = msgpack(play)

    MultiForce.sendHttpRequest(self,"POST", url .. "/send_to_agent", msgpack(data), cc.XMLHTTPREQUEST_RESPONSE_JSON, function(xhr)
        -- print('postDisableWordCheck', xhr, xhr.status, xhr.response)
        -- dump(xhr,nil,99)
        if xhr.status == 200 then
            local t = json.decode(xhr.response)
			-- dump(t,nil,99)
			return cb({ret = true}, t,fightRoleOut,idx)
        end
        return cb({ret = false}, nil,fightRoleOut,idx)
    end)
end

function MultiForce.fillDataTb( self,unitTb,dataTb )
	local forceStr = {"left_front","left_back","right_front","right_back"}

	for _,str in ipairs(forceStr) do
		local forceTb = unitTb[str.."_tb"]
		dataTb[str.."_tb"] = {}
		for j = 1,#forceTb do
			MultiForce.requestCardData(self,forceTb[j],function(ret,data)
				dataTb[str.."_tb"][j] = data
			end)
		end
	end
end

function MultiForce.requestCardData(self,unitTb,cb )
	local parms = {
		['card_id']= unitTb.cardID,
		['advance'] =  unitTb.advance,
		['star']= unitTb.star,
		['level']= unitTb.level,
	}
	MultiForce.sendHttpRequest(self,"POST", url .. "/calc_card", msgpack(parms), cc.XMLHTTPREQUEST_RESPONSE_JSON, function(xhr)
		-- print('postDisableWordCheck', xhr, xhr.status, xhr.response)
		-- dump(xhr,nil,99)
		if xhr.status == 200 then
			local t = msgunpack(xhr.response)

			return cb({ret = true}, t)
		end
		return cb({ret = false}, nil)
	end)
end

function MultiForce.loadFiles(self)
	self.arenaData = readAndUnpack(".\\src\\app\\views\\city\\test\\arena_qiangdu.play")
	self.craftData = readAndUnpack(".\\src\\app\\views\\city\\test\\craft_qiangdu.play")
end

function MultiForce.sendHttpRequest(self,reqType, reqUrl, reqBody, resType, cb)
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = resType
	xhr.timeout = 20
	xhr:open(reqType, reqUrl)
	if reqType == 'GET' then
		xhr:setRequestHeader("Accept-Encoding", "gzip")
	end
	local function _onReadyStateChange(...)
		local encode = string.match(xhr:getAllResponseHeaders(), "Content%-Encoding:%s*(gzip)")
		if encode == 'gzip' then
			xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_BLOB
			xhr.response = zuncompress(xhr.response)
		end
		cb(xhr)
	end
	if cb then xhr:registerScriptHandler(_onReadyStateChange) end
	if reqBody then xhr:send(reqBody)
	else xhr:send() end
end

return MultiForce