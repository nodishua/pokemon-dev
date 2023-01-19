--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

csv = {}
iup = {}
sdk = {}

-- engine
-- require "lz4"
-- require "aes"
-- require "ffi"
require "ymrand"
-- require "ymasync"
-- require "socket"
-- require "socket.core"
-- require "mime.core"

require "3rd.MD5"
require "3rd.CRC32"
require "3rd.msgpack"
require "3rd.stringzutils"

-- cocos
require "defines"
-- require "cocos_init"
require "cocos.cocos2d.json"
require "cocos.cocos2d.Cocos2d"
require "cocos.cocos2d.functions"
display = require("cocos.framework.display")

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
require "util.saltnumber"
require "util.lazy_require"

require "luastl.vector"
require "luastl.list"
require "luastl.set"
require "luastl.map"
require "luastl.collection"

-- easy
-- require "easy.extends.Director"
-- require "easy.extends.Node"
-- require "easy.extends.UIButton"
-- require "easy.extends.UIImageView"
-- require "easy.extends.UISlider"
-- require "easy.extends.UILoadingBar"
-- require "easy.extends.UIListView"
-- require "easy.text"
-- require "easy.label"
require "easy.table"
-- require "easy.richtext"
-- require "easy.stream_richtext"
-- require "easy.sprite"
-- require "easy.transition"
-- require "easy.widget"
require "easy.idlerdebug"
require "easy.idlersystem"
require "easy.idler"
require "easy.idlercomputer"
require "easy.idlereasy"
-- require "easy.beauty"
-- require "easy.effect"
require "easy.vmproxy"
-- require "easy.dialog"
-- require "easy.touchtip"
-- require "easy.ui_bind"
-- require "easy.ui_adapter"
-- require "easy.ui_l10n"
-- require "easy.user_default"
-- require "easy.blacklist"

-- cache
require "cache.include"

require "config.csv"

-- app
require "app.defines.include"
require "app.easy.math"
require "app.easy.data"

-- packages
-- cc.load("mvc")
-- cc.load("components")