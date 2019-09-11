local res = '';
local code = KEYS[1];
--用户余额
local allprice = ARGV[1];
--用户买单数量
local targetnumber = ARGV[2];
local canbuynum = 0;
local lasthasleft = 0;
local numunit = ARGV[3];

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

local function findprice_num(_id, _price, _num)
    local actualnum = canbuynum;

    if (tonumber(targetnumber) < actualnum) then
        actualnum = tonumber(targetnumber);
    end ;
    if (actualnum < tonumber(_num)) then
        local left = _num - actualnum;
        redis.call('RPUSH', code .. 'sell', _id .. ',' .. _price .. ',' .. string.format("%.0f", left));
        res = res .. ',' .. _id .. ',' .. _price .. ',' .. string.format("%.0f", actualnum);
        allprice = allprice - actualnum * _price;
        targetnumber = targetnumber - actualnum;
        lasthasleft = 1;
    else
        res = res .. ',' .. _id .. ',' .. _price .. ',' .. _num;
        allprice = allprice - _num * _price;
        targetnumber = targetnumber - _num;
    end ;
end;

local function findfit()
    while true do
        local aa = redis.call('RPOP', code .. 'sell');
        if (aa == false) then
            break ;
        end ;

        local bb = split(aa, ',');
        local _id = bb[1];
        local _price = bb[2];
        local _num = bb[3];
        bb = nil;
        canbuynum = math.floor(math.floor(allprice / _price) / numunit) * numunit;
        if (canbuynum <= 0) then
            redis.call('RPUSH', code .. 'sell', _id .. ',' .. _price .. ',' .. _num);
            break ;
        end ;

        findprice_num(_id, _price, _num);

        if (allprice <= 0 or targetnumber <= 0) then
            break ;
        end ;
    end ;
end;

findfit();
res = res .. ',' .. lasthasleft;
return res;
