--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
local ffi = require("ffi")

ffi.cdef [[
    typedef struct _MEMORYSTATUSEX {
      uint32_t     dwLength;
      uint32_t     dwMemoryLoad;
      uint64_t ullTotalPhys;
      uint64_t ullAvailPhys;
      uint64_t ullTotalPageFile;
      uint64_t ullAvailPageFile;
      uint64_t ullTotalVirtual;
      uint64_t ullAvailVirtual;
      uint64_t ullAvailExtendedVirtual;
    } MEMORYSTATUSEX, *LPMEMORYSTATUSEX;

    int32_t GlobalMemoryStatusEx(
      LPMEMORYSTATUSEX lpBuffer
    );

    uint32_t GetLastError();

    int32_t getpid(void);

    typedef struct _PROCESS_MEMORY_COUNTERS_EX {
      uint32_t  cb;
      uint32_t  PageFaultCount;
      uint32_t PeakWorkingSetSize;
      uint32_t WorkingSetSize;
      uint32_t QuotaPeakPagedPoolUsage;
      uint32_t QuotaPagedPoolUsage;
      uint32_t QuotaPeakNonPagedPoolUsage;
      uint32_t QuotaNonPagedPoolUsage;
      uint32_t PagefileUsage;
      uint32_t PeakPagefileUsage;
      uint32_t PrivateUsage;
    } PROCESS_MEMORY_COUNTERS_EX, *PPROCESS_MEMORY_COUNTERS_EX;

    uint32_t GetCurrentProcess(void);

    int32_t GetProcessMemoryInfo(
      uint32_t                   Process,
      PPROCESS_MEMORY_COUNTERS_EX ppsmemCounters,
      uint32_t                    cb
    );
]]

local function trim(s)
    local from = s:match"^%s*()"
    return from > #s and "" or s:match(".*%S", from)
end

local function andoridMeminfo()
    local f, err = io.open("/proc/meminfo", "r")
    local str
    local tb = {}
    if f then
        str = f:read('*a')
        f:close()
    else
        print('read meminfo err:', err)
        return nil
    end
    -- if str then
    -- 	print(str)
    -- end

    for k, v in string.gmatch(str, "([^:]+):%s+(%S+)%s+kB") do
    	tb[trim(k)] = tonumber(v) / 1024.0 -- MB
    end
    -- print_r(tb)

	-- * MemTotal: Total usable ram (i.e. physical ram minus a few reserved bits and the kernel binary code)
	-- * MemFree: Is sum of LowFree+HighFree (overall stat)
	-- * MemShared: 0; is here for compat reasons but always zero.
	-- * Buffers: Memory in buffer cache. mostly useless as metric nowadays
	-- * Cached: Memory in the pagecache (diskcache) minus SwapCached
	-- * SwapCached: Memory that once was swapped out,is swapped back in but still also is in the swapfile (if memory is needed it doesn't need to be swapped out AGAIN because it is already in the swapfile. This saves I/O)
	-- * MemAvailable: An estimate of how much memory is available for starting new applications, without swapping.

	-- MemAvailable(3.14内核)
	if tb.MemAvailable == nil then
		tb.MemAvailable = tb.MemFree + tb.Cached + tb.SReclaimable
	end
	return tb.MemAvailable
end

local function winMeminfo()
    local pmem = ffi.new('MEMORYSTATUSEX[1]', {})
    local mem = pmem[0]
    -- print('sizeof', ffi.sizeof(mem))
    mem.dwLength = ffi.sizeof(mem)
    local ret = ffi.C.GlobalMemoryStatusEx(pmem)
    if ret == 0 then
        print('winMeminfo GetLastError', ffi.C.GetLastError())
        return nil
    end

    -- print('ret', ret)
    -- print('dwMemoryLoad', mem.dwMemoryLoad)
    -- print('ullTotalPhys', mem.ullTotalPhys, tonumber(mem.ullTotalPhys))
    -- print('ullAvailPhys', mem.ullAvailPhys, tonumber(mem.ullAvailPhys))
    -- print('ullTotalPageFile', mem.ullTotalPageFile, tonumber(mem.ullTotalPageFile))
    -- print('ullAvailPageFile', mem.ullAvailPageFile, tonumber(mem.ullAvailPageFile))
    -- print('ullTotalVirtual', mem.ullTotalVirtual, tonumber(mem.ullTotalVirtual))
    -- print('ullAvailVirtual', mem.ullAvailVirtual, tonumber(mem.ullAvailVirtual))
    -- print('ullAvailExtendedVirtual', mem.ullAvailExtendedVirtual, tonumber(mem.ullAvailExtendedVirtual))

    return tonumber(mem.ullAvailPhys) / 1024.0 / 1024.0
end

-- 返回可用内存，单位MB
local ismemok = true
function getMeminfo()
    if not ismemok then
        return 0
    end
    local ret
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if cc.PLATFORM_OS_ANDROID == targetPlatform then
        ret = andoridMeminfo()
    elseif cc.PLATFORM_OS_WINDOWS == targetPlatform then
        ret = winMeminfo()
    end
    return ret or 0
end

-- android下非常不准确
local function andoridProcMeminfo()
    local pid = ffi.C.getpid()
    local f, err = io.open(string.format("/proc/%s/status", pid), "r")
    local str
    local tb = {}
    if f then
        str = f:read('*a')
        f:close()
    else
        print('read proc status err:', err)
        return nil
    end
    -- if str then
    --     print(str)
    -- end

    for k, v in string.gmatch(str, "([^:]+):%s+(%S+)%s+kB") do
        tb[trim(k)] = tonumber(v) / 1024.0 -- MB
    end
    -- print_r(tb)

    -- 字段  说明
    -- VmPeak  进程所使用的虚拟内存的峰值
    -- VmSize  进程当前使用的虚拟内存的大小
    -- VmLck   已经锁住的物理内存的大小（锁住的物理内存不能交换到硬盘）
    -- VmHWM   进程所使用的物理内存的峰值
    -- VmRSS   进程当前使用的物理内存的大小
    -- VmData  进程占用的数据段大小
    -- VmStk   进程占用的栈大小
    -- VmExe   进程占用的代码段大小（不包括库）
    -- VmLib   进程所加载的动态库所占用的内存大小（可能与其它进程共享）
    -- VmPTE   进程占用的页表大小（交换表项数量）
    -- VmSwap  进程所使用的交换区的大小

    return tb.VmRSS
end


-- 格式系统版本各异，需要注意
-- 1:
--                         Shared  Private     Heap     Heap     Heap
--                   Pss    Dirty    Dirty     Size    Alloc     Free
--                ------   ------   ------   ------   ------   ------
--  Native Heap        0        0        0        0    12832     6826     1377
--  Dalvik Heap    20418    20360        0     9044    31752    17587    14165
-- Dalvik Other     6129     6040        0     1536
--        TOTAL    16407    11792    12860    22275    18459     2003

-- 2:
--                   Shared  Private     Heap     Heap     Heap
--             Pss    Dirty    Dirty     Size    Alloc     Free
--          ------   ------   ------   ------   ------   ------
-- Native     2144      988     2040     8636     5124     1699
-- Dalvik     9481     8292     8644    13639    13335      304
--  TOTAL    16407    11792    12860    22275    18459     2003

-- 3:
--              native   dalvik    other    total
--      size:    10940     7047      N/A    17987
-- allocated:     8943     5516      N/A    14459
--      free:      336     1531      N/A     1867
--     (Pss):     4585     9282    11916    25783

-- 权限有问题，DUMP不一定开放
local function andoridProcMeminfo2()
    local pid = ffi.C.getpid()
    local fp = io.popen("dumpsys meminfo "..pid)
    local str
    print('!!! andoridProcMeminfo2 pid=', pid, ', fp=', fp)
    if fp then
        str = fp:read("*a")
        fp:close()
        print(str)
    else
        return nil
    end

    local tb = {}
    local line1 = str:match('TOTAL([^\n]+)\n')
    local line2 = str:match('(Pss):([^\n]+)\n')
    if line1 then
        for v in string.gmatch(line1, "(%S+)") do
            table.insert(tb, v)
        end
        -- TOTAL Pss
        return tonumber(tb[1]) / 1024.0
    elseif line2 then
        for v in string.gmatch(line1, "(%S+)") do
            table.insert(tb, v)
        end
        -- total (Pss)
        return tonumber(tb[#tb]) / 1024.0
    end
    return nil
end

local function winProcMeminfo()
    local psapi = ffi.load('Psapi')
    local pmem = ffi.new('PROCESS_MEMORY_COUNTERS_EX[1]', {})
    local mem = pmem[0]
    mem.cb = ffi.sizeof(mem)
    local handle = ffi.C.GetCurrentProcess()
    local ret = psapi.GetProcessMemoryInfo(handle, pmem, ffi.sizeof(mem))
    if ret == 0 then
        print('winProcMeminfo GetLastError', ffi.C.GetLastError())
        return nil
    end

    -- print('ret', ret)
    -- print('PageFaultCount', mem.PageFaultCount)
    -- print('PeakWorkingSetSize', mem.PeakWorkingSetSize, tonumber(mem.PeakWorkingSetSize))
    -- print('WorkingSetSize', mem.WorkingSetSize, tonumber(mem.WorkingSetSize))
    -- print('QuotaPeakPagedPoolUsage', mem.QuotaPeakPagedPoolUsage, tonumber(mem.QuotaPeakPagedPoolUsage))
    -- print('QuotaPagedPoolUsage', mem.QuotaPagedPoolUsage, tonumber(mem.QuotaPagedPoolUsage))
    -- print('QuotaPeakNonPagedPoolUsage', mem.QuotaPeakNonPagedPoolUsage, tonumber(mem.QuotaPeakNonPagedPoolUsage))
    -- print('QuotaNonPagedPoolUsage', mem.QuotaNonPagedPoolUsage, tonumber(mem.QuotaNonPagedPoolUsage))
    -- print('PagefileUsage', mem.PagefileUsage, tonumber(mem.PagefileUsage))
    -- print('PeakPagefileUsage', mem.PeakPagefileUsage, tonumber(mem.PeakPagefileUsage))
    -- print('PrivateUsage', mem.PrivateUsage, tonumber(mem.PrivateUsage))

    return tonumber(mem.WorkingSetSize) / 1024.0 / 1024.0
end

-- 返回当前进程内存，单位MB
local isprocok = true
function getProcMeminfo()
    if not isprocok then
        return 0
    end
    local ret
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if cc.PLATFORM_OS_ANDROID == targetPlatform then
        ret = andoridProcMeminfo()
    elseif cc.PLATFORM_OS_WINDOWS == targetPlatform then
        ret = winProcMeminfo()
    end
    return ret or 0
end


-- test is work
if getMeminfo() == 0 then
    ismemok = false
end
if getProcMeminfo() == 0 then
    isprocok = false
end
