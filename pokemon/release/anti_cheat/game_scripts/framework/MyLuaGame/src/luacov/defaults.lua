--- Default values for configuration options.
-- For project specific configuration create '.luacov' file in your project
-- folder. It should be a Lua script setting various options as globals
-- or returning table of options.
-- @class module
-- @name luacov.defaults
return {

  --- Filename to store collected stats. Default: "luacov.stats.out".
  statsfile = "luacov.stats.out",

  --- Filename to store report. Default: "luacov.report.out".
  reportfile = "luacov.report.out",

  --- Enable saving coverage data after every `savestepsize` lines?
  -- Setting this flag to `true` in config is equivalent to running LuaCov
  -- using `luacov.tick` module. Default: false.
  tick = true,

  --- Stats file updating frequency for `luacov.tick`.
  -- The lower this value - the more frequently results will be written out to the stats file.
  -- You may want to reduce this value (to, for example, 2) to avoid losing coverage data in
  -- case your program may terminate without triggering luacov exit hooks that are supposed
  -- to save the data. Default: 100.
  savestepsize = 1000,
  savetick = 5,

  --- Run reporter on completion? Default: false.
  runreport = true,

  --- Delete stats file after reporting? Default: false.
  deletestats = false,

  --- Process Lua code loaded from raw strings?
  -- That is, when the 'source' field in the debug info
  -- does not start with '@'. Default: false.
  codefromstrings = false,

  --- Lua patterns for files to include when reporting.
  -- All will be included if nothing is listed.
  -- Do not include the '.lua' extension. Path separator is always '/'.
  -- Overruled by `exclude`.
  include = {},

  --- Lua patterns for files to exclude when reporting.
  -- Nothing will be excluded if nothing is listed.
  -- Do not include the '.lua' extension. Path separator is always '/'.
  -- Overrules `include`.
  exclude = {"net/", "3rd/", "config/", "luastl/", "util/", "editor/", "luacov/", "cocos/"},

  --- Table mapping names of modules to be included to their filenames.
  -- Has no effect if empty.
  -- Real filenames mentioned here will be used for reporting
  -- even if the modules have been installed elsewhere.
  -- Module name can contain '*' wildcard to match groups of modules,
  -- in this case corresponding path will be used as a prefix directory
  -- where modules from the group are located.
  -- @usage
  -- modules = {
  --    ["some_rock"] = "src/some_rock.lua",
  --    ["some_rock.*"] = "src"
  -- }
  modules = {},

  -- luacov will cost many memory lead to crash when 2G under win32
  csmode = false,

  onlysummary = false,
}
