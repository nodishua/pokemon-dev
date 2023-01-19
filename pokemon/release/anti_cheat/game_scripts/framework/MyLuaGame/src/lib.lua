--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

csv = {}
iup = {}
sdk = {}

--把jit关掉是因为android第一次进入都会很卡，且跑lua普通逻辑的性能也超级差
--估计和jit的compile(lua与c函数交互会几率flush luajit的cache)有关
--个别性能不是很好的android cpu很不稳定 时好时不好，战斗帧率可能会差个三四倍
--应该跟android本身系统有关,跟本身逻辑应该没关系
print('jit off', jit.off())

-- engine
require "lz4"
require "aes"
require "ffi"
require "ymrand"
require "ymasync"
require "ymdump"
require "socket"
require "socket.core"
require "mime.core"

require "3rd.MD5"
require "3rd.CRC32"
require "3rd.msgpack"
require "3rd.stringzutils"

-- cocos
require "defines"
require "cocos_init"

-- util
require "util.random"
require "util.itertools"
require "util.arraytools"
require "util.maptools"
require "util.functools"
require "util.nodetools"
require "util.callbacks"

require "util.str"
require "util.csv"
require "util.log"
require "util.helper"
require "util.print_r"
require "util.config"
require "util.language"
require "util.time"
require "util.env"
require "util.eval"
require "util.randname"
require "util.debug"
require "util.debug_ui"
require "util.stat"
require "util.saltnumber"

require "luastl.vector"
require "luastl.list"
require "luastl.set"
require "luastl.map"
require "luastl.collection"

-- easy
require "easy.extends.Director"
require "easy.extends.Node"
require "easy.extends.UIButton"
require "easy.extends.UIImageView"
require "easy.extends.UISlider"
require "easy.extends.UILoadingBar"
require "easy.extends.UIListView"
require "easy.extends.ParticleSystemQuad"
require "easy.text"
require "easy.label"
require "easy.table"
require "easy.richtext"
require "easy.stream_richtext"
require "easy.sprite"
require "easy.render_target"
require "easy.transition"
require "easy.widget"
require "easy.idlerdebug"
require "easy.idlersystem"
require "easy.idler"
require "easy.idlercomputer"
require "easy.idlereasy"
require "easy.beauty"
require "easy.effect"
require "easy.vmproxy"
require "easy.dialog"
require "easy.touchtip"
require "easy.ui_bind"
require "easy.ui_adapter"
require "easy.ui_l10n"
require "easy.user_default"
require "easy.blacklist"

-- cache
require "cache.include"

-- app
require "app.include"

-- packages
cc.load("mvc")
cc.load("components")