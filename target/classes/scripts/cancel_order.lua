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

if (type == 'buy')
then
    while true do
        local aa = redis.call('LINDEX', code .. 'buy', i);
        i = i + 1;
        if (aa == false) then
            return '-1';  -- buy order isn't exist
        end;
        local bb = split(aa, ',');
        local _id = bb[1];
        bb = nil;
        if (_id == id)
        then
            ret = redis.call('LREM', code .. 'buy', 1, aa);
            return string.format("%d,%s", ret, aa); -- num buy order deleted
        end;
    end;
elseif (type == 'sell')
then
    while true do
        
        local aa = redis.call('LINDEX', code .. 'sell', i);
        i = i + 1;
        if (aa == false) then
            return '-2';  -- sell order isn't exist
        end;
        local bb = split(aa, ',');
        local _id = bb[1];
        bb = nil;
        if (_id == id)
        then
            ret = redis.call('LREM', code .. 'sell', 1, aa);
            return string.format("%d,%s", ret, aa); -- num sell order deleted
        end;
    end;
else
  return '-100';  -- invalid type (not 'buy' and 'sell')
end;
