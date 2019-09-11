local res = '';
local code = KEYS[1];
local id = ARGV[1];
local price = ARGV[2];
local num = ARGV[3];
local lasthasleft = 0;
--最基本的原理，从哪个方向拿出来，从哪个方向塞回去
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



--排序方式为从大到小，从最价格最高到价格最低
local function insert_buylist()
    local i = 0;
    while (true)
    do
        local aa = redis.call('LINDEX', code .. 'buy', i);
        if (aa == false) then
            if (i == 0) then
                redis.call('LPUSH', code .. 'buy', id .. ',' .. price .. ',' .. num);
            else
                redis.call('RPUSH', code .. 'buy', id .. ',' .. price .. ',' .. num);
            end ;
            break ;
        end ;

        local content = split(aa, ',');
        if (tonumber(price) > tonumber(content[2])) then
            redis.call('LINSERT', code .. 'buy', 'BEFORE', aa, id .. ',' .. price .. ',' .. num);
            break ;
        end ;
        i = i + 1;
    end ;
end;

local function findnum(_id, _price, _num)
    if (tonumber(num) < tonumber(_num)) then
        local left = _num - num;
        redis.call('RPUSH', code .. 'sell', _id .. ',' .. _price .. ',' .. string.format("%.0f", left));
        res = res .. ',' .. _id .. ',' .. _price .. ',' .. string.format("%.0f", num);
        num = 0;
        lasthasleft = 1;
    else
        res = res .. ',' .. _id .. ',' .. _price .. ',' .. _num;
        num = num - _num;
    end ;

end;

local function findprice(_id, _price, _num)
    if (tonumber(price) >= tonumber(_price)) then
        findnum(_id, _price, _num);
    else
        redis.call('RPUSH', code .. 'sell', _id .. ',' .. _price .. ',' .. _num);
        insert_buylist();
        num = 0;
    end
end;

local function limit_buy()
    while true do
        local aa = redis.call('RPOP', code .. 'sell');
        if (aa == false) then
            insert_buylist();
            break ;
        end ;
        local bb = split(aa, ',');
        local _id = bb[1];
        local _price = bb[2];
        local _num = bb[3];
        bb = nil;
        findprice(_id, _price, _num);
        if (num == 0) then
            break ;
        end ;
    end ;
end;

limit_buy();
res = res .. ',' .. lasthasleft;
return res;