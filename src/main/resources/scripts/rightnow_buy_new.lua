local res = '';
local code = KEYS[1];
--用户订单id
local id = ARGV[1];
--用户买单数量
local num = ARGV[2];
local priority = ARGV[3];

local lasthasleft = 0;

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

local function getContent(_index)
    local index = redis.call('LINDEX', code .. '_market_buy', _index);
    local content = split(index, ',');
    return content;
end

local function getIndex(_start, _end)
    local maxIndex = _end;
    local content = getContent(_start);
    if (tonumber(priority) < tonumber(content[3])) then
        return _start;
    end
    local endContent = getContent(_end);
    if (tonumber(priority) >= tonumber(endContent[3])) then
        return _end + 1;
    end

    while (_start <= _end) do
        local mid = _start + math.floor((_end - _start) / 2)

        local midContent = getContent(mid)
        if (tonumber(midContent[3]) == tonumber(priority)) then
            while (mid < maxIndex) do
                local next = getContent(mid + 1)
                if (tonumber(next[3]) == tonumber(priority)) then
                    mid = mid + 1;
                else
                    break ;
                end
            end
            return mid+1;
        else
            if (tonumber(midContent[3]) < tonumber(priority)) then
                _start = mid + 1;
            else
                _end = mid - 1;
            end
        end
    end
    return _start;
end

--依次排列 从左到右 优先级 由高到底 时间由先到后
local function insertMarketBuy()
    local startIndex = 0;
    --获取买单队列长度
    local len = redis.call('LLEN', code .. '_market_buy');
    local endIndex = len - 1
    if (len == 0) then
        redis.call('LPUSH', code .. '_market_buy', id .. ',' .. string.format("%.0f", num) .. ',' .. priority);
    else
        --使用二分查找，确定卖单位置
        local index = getIndex(startIndex, endIndex)
        if (index >= len) then
            --超出当前最大位置，直接插入到队尾
            redis.call('RPUSH', code .. '_market_buy', id .. ',' .. string.format("%.0f", num) .. ',' .. priority);
        else
            --位置在范围内，直接插入到制定位置
            local aa = redis.call('LINDEX', code .. '_market_buy', index);
            redis.call('LINSERT', code .. '_market_buy', 'BEFORE', aa, id .. ',' .. string.format("%.0f", num) .. ',' .. priority);
        end
    end
end

local function dealPerMatch(_id, _price, _num, _priority)
    if (tonumber(num) < _num * _price) then
        --当限价卖单交易额大于市价买单额度
        local volume = math.floor(num / _price)
        if (volume == 0) then
            --当前额度已不满足交易精度，中止交易，并退回限价卖单
            redis.call('RPUSH', code .. '_sell', _id .. ',' .. _price .. ',' .. string.format("%.0f", _num) .. ',' .. _priority);
        else
            --当前额度满足交易精度，扣减交易量，并将剩余量退回限价卖队列
            redis.call('RPUSH', code .. '_sell', _id .. ',' .. _price .. ',' .. string.format("%.0f", _num - volume) .. ',' .. _priority);
            res = res .. ',' .. _id .. ',' .. _price .. ',' .. string.format("%.0f", volume);
            lasthasleft = 1;
        end
        num = 0;
    else
        --当限价卖单交易额小于市价买单额度 直接成交
        res = res .. ',' .. _id .. ',' .. _price .. ',' .. string.format("%.0f", _num);
        num = num - _num * _price;
    end
end;

local function matchMarketBuy()
    while true do
        --获取市价卖单
        local limitSellNode = redis.call('RPOP', code .. '_sell');
        if (limitSellNode == false) then
            --如果限价卖单不存在，存入市价买单数据库
            insertMarketBuy();
            break ;
        end ;

        local limitSellContent = split(limitSellNode, ',');
        local _id = limitSellContent[1];
        local _price = limitSellContent[2];
        local _num = limitSellContent[3];
        local _priority = limitSellContent[4];
        limitSellContent = nil;

        dealPerMatch(_id, _price, _num, _priority)

        if (num == 0) then
            break ;
        end ;
    end ;
end;

matchMarketBuy();
res = res .. ',' .. lasthasleft;
return res;
