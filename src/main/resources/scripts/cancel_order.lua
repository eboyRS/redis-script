local res = '';
local code = KEYS[1];
local type = ARGV[1];
local id = ARGV[2];
local i = 0;

local function split(str, delimiter)
    if str == nil or str == '' or delimiter == nil then
        return nil
    end

    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

local ret = -100;

while true do
    local indexNode = redis.call('LINDEX', code .. type, i);
    i = i + 1;
    if (indexNode == false) then
        return '-1';  -- buy order isn't exist
    end ;
    local indexContent = split(indexNode, ',');
    local _id = indexContent[1];
    indexContent = nil;
    if (_id == id)
    then
        ret = redis.call('LREM', code .. type, 1, indexNode);
        return string.format("%d,%s", ret, indexNode); -- num buy order deleted
    end ;
end ;
