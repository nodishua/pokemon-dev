

local FriendGate = class("FriendGate", battlePlay.ArenaGate)
battlePlay.FriendGate = FriendGate


function FriendGate:postEndResultToServer(cb)
	cb(self:makeEndViewInfos())
end