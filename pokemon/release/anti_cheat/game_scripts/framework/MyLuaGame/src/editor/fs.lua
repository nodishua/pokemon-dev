--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- win下file system函数
--

local bit = require 'bit'
local bnot, band, bor, bxor = bit.bnot, bit.band, bit.bor, bit.bxor
local lshift, rshift, rol = bit.lshift, bit.rshift, bit.rol

local ffi = require("ffi")

if not globals._fs_cdefined_ then
ffi.cdef [[
typedef struct _FILETIME {
	uint32_t dwLowDateTime;
	uint32_t dwHighDateTime;
} FILETIME, *PFILETIME, *LPFILETIME;

typedef struct _SYSTEMTIME {
	int16_t wYear;
	int16_t wMonth;
	int16_t wDayOfWeek;
	int16_t wDay;
	int16_t wHour;
	int16_t wMinute;
	int16_t wSecond;
	int16_t wMilliseconds;
} SYSTEMTIME, *PSYSTEMTIME, *LPSYSTEMTIME;

int32_t FileTimeToSystemTime(
  const FILETIME     *lpFileTime,
  LPSYSTEMTIME lpSystemTime
);

typedef struct _WIN32_FIND_DATAA {
	uint32_t dwFileAttributes;
	FILETIME ftCreationTime;
	FILETIME ftLastAccessTime;
	FILETIME ftLastWriteTime;
	uint32_t nFileSizeHigh;
	uint32_t nFileSizeLow;
	uint32_t dwReserved0;
	uint32_t dwReserved1;
	char   cFileName[ 260 ];
	char   cAlternateFileName[ 14 ];
} WIN32_FIND_DATAA, *PWIN32_FIND_DATAA, *LPWIN32_FIND_DATAA;

int32_t FindFirstFileA(
	char* lpFileName,
	LPWIN32_FIND_DATAA lpFindFileData
);

int32_t FindNextFileA(
	int32_t hFindFile,
	LPWIN32_FIND_DATAA lpFindFileData
);

int32_t FindClose(
	int32_t hFindFile
);

uint32_t GetLastError();

]]
globals._fs_cdefined_ = true
end

local fs = {}

function fs.listAllFiles(dir, filter, recursion)
	local pfind = ffi.new('WIN32_FIND_DATAA[1]', {})
	local ptime = ffi.new('SYSTEMTIME[1]', {})
	local find, time = pfind[0], ptime[0]
	local files = {}

	local hfind = ffi.C.FindFirstFileA(ffi.cast("char*", dir .. "/*"), pfind)
	if hfind == -1 then
		print('FindFirstFileA GetLastError', ffi.C.GetLastError())
		return files
	end

	while true do
		local ret = ffi.C.FindNextFileA(hfind, pfind)
		if ret == 0 then
			break
		end

		local name = ffi.string(find.cFileName)
		-- #define FILE_ATTRIBUTE_DIRECTORY 0x00000010
		if band(find.dwFileAttributes, 0x10) == 0x10 and recursion then
			if name == "." or name == ".." then
			else
				local subfiles = fs.listAllFiles(string.format("%s/%s", dir, name), filter, recursion)
				for name, time in pairs(subfiles) do
					files[name] = time
				end
			end

		elseif filter(name) then
			-- print(string.format("%s/%s", dir, name))

			files[string.format("%s/%s", dir, name)] = {find.ftLastWriteTime.dwLowDateTime, find.ftLastWriteTime.dwHighDateTime}

			-- ret = ffi.C.FileTimeToSystemTime(ffi.cast("FILETIME*", find.ftLastWriteTime), ptime)
			-- print(find.ftLastWriteTime.dwLowDateTime, find.ftLastWriteTime.dwHighDateTime, time.wYear, time.wMonth, time.wDay, time.wHour, time.wMinute)
		end
	end
	ffi.C.FindClose(hfind)
	return files
end

return fs
