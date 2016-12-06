local pairs = pairs
local setmetatable = setmetatable

local mt = {}
mt.__index = mt

function mt:__pairs()
	local list = self._list
	local n = 0
	return function()
		n = n + 1
		local key = list[n]
		if key then
			return key, self[key]
		else
			return nil
		end
	end, self, nil
end

local function read_metadata(w3x2lni, file_name)
	local tbl, list = w3x2lni:read_slk(io.load(file_name))
	if not tbl then
		return
	end
	local meta = setmetatable({}, mt)
	meta._list = list

	local has_index = {}
	for k, v in pairs(tbl) do
		if meta[k] then
			message('meta表id重复', k)
		end
		meta[k] = v
		-- 进行部分预处理
		local name  = v['field']
		local index = v['index']
		if index and index >= 1 then
			has_index[name] = true
		end
	end
	for k, v in pairs(meta) do
		local name = v['field']
		if has_index[name] then
			v['_has_index'] = true
		end
	end
	for k, v in pairs(meta) do
		if v['repeat'] then
			meta._has_level = true
			break
		end
	end
	return meta
end

return read_metadata