local res = '';
local code = KEYS[1];
local id = ARGV[1];
local price = ARGV[2];
local num = ARGV[3];
local priority = ARGV[4];
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
    local index = redis.call('LINDEX', code .. '_sell', _index);
    local content = split(index, ',');
    return content;
end

local function getIndex(_start,_end)
    local content = getContent(_start);
    if(tonumber(price)>tonumber(content[2]) or (tonumber(price)==tonumber(content[2]) and tonumber(priority)>=tonumber(content[4])))then
        return _start;
    end
    local endContent = getContent(_end);
    if(tonumber(price)<tonumber(endContent[2]) or (tonumber(price)==tonumber(endContent[2]) and tonumber(priority)<tonumber(endContent[4])))then
        return _end+1;
    end

    while(_start<=_end) do
        local mid= _start + math.floor((_end -_start)/2)

        local midContent=getContent(mid)
        if(tonumber(midContent[2])==tonumber(price) and tonumber(midContent[4]) == tonumber(priority))then
            while(mid>=1) do
                local next=getContent(mid-1)
                if(tonumber(next[2])==tonumber(price) and tonumber(next[4]) == tonumber(priority))then
                    mid=mid-1;
                else
                    break;
                end
            end
            return mid;
        else
            if(tonumber(midContent[2])>tonumber(price) or (tonumber(midContent[2])==tonumber(price) and tonumber(midContent[4]) > tonumber(priority)))then
                _start=mid+1;
            else
                _end=mid-1;
            end
        end
    end
    return _start;
end

--排序方式为从大到小，从最价格最高到价格最低
local function insertSellList()
    local startIndex = 0;
    --获取卖单队列长度
    local len = redis.call('LLEN', code .. '_sell');
    local endIndex=len-1
    if(len==0)then
        redis.call('LPUSH', code .. '_sell', id .. ',' .. price .. ',' ..  string.format("%.0f", num) ..',' .. priority);
    else
        --使用二分查找，确定卖单位置
        local index=getIndex(startIndex,endIndex)
        if(index>=len)then
            --超出当前最大位置，直接插入到队尾
            redis.call('RPUSH', code .. '_sell', id .. ',' .. price .. ',' .. string.format("%.0f", num) ..',' .. priority);
        else
            --位置在范围内，直接插入到制定位置
            local aa = redis.call('LINDEX', code .. '_sell', index);
            redis.call('LINSERT', code .. '_sell', 'BEFORE', aa, id .. ',' .. price .. ',' .. string.format("%.0f", num)..',' .. priority);
        end
    end
end;





local function matchSuccess(_id, _price, _num, _priority)
    if (tonumber(num) < tonumber(_num)) then
        --当前卖单数据小于当前买单数量，则卖单完成，并且将买单剩余量存回去
        local left = _num - num;
        redis.call('LPUSH', code .. '_buy', _id .. ',' .. _price .. ',' .. string.format("%.0f", left)..',' .. _priority);
        res = res .. ',' .. _id .. ',' .. _price .. ',' .. string.format("%.0f", num);
        num = 0;
        lasthasleft = 1;
    else
        --当前卖单数据大于当前买单数量，则吃掉买单
        res = res .. ',' .. _id .. ',' .. _price .. ',' .. _num;
        num = num - _num;
    end ;

end;

local function matchMarketBuy()
    while true do
        local marketBuyNode = redis.call('LPOP', code .. '_market_buy');
        if (marketBuyNode == false) then
            --如果没有市价买单，则存储卖单数据
            insertSellList();
            break ;
        end ;
        local marketBuyContent = split(marketBuyNode, ',');
        local _id = marketBuyContent[1];
        local _num = marketBuyContent[2];
        local _priority= marketBuyContent[3];
        marketBuyContent = nil;
        if(tonumber(_num)<=num*price)then
            --如果市价买单购买量小于当前限价卖单，则把买单全部吃掉，但是由于存在极小值问题，市价买单会存在一定精度外额度未成交
            local volume=math.floor(_num/price)
            res = res .. ',' .. _id ..',' .. price .. ',' ..  string.format("%.0f", volume);
            num = num - volume;
        else
            --如果市价买单购买量大于当前限价卖单，则卖单完成，并且将买单剩余量存回去
            local left = _num - num*price;
            redis.call('LPUSH', code .. '_market_buy', _id .. ',' .. string.format("%.0f", left)..',' .. _priority);
            res = res .. ',' .. _id .. ',' .. price .. ',' .. string.format("%.0f", num);
            num = 0;
            lasthasleft = 1;
        end

        if (tonumber(num)<=0) then
            break;
        end
    end;
end;


local function dealPerMatch(_id, _price, _num, _priority)
    if (tonumber(price) <= tonumber(_price)) then
        -- 如果当前卖单价格小于等于买单价格,则成交
        matchSuccess(_id, _price, _num,_priority);
    else
        -- 如果当前卖单价格大于买单价格,则匹配市价单
        redis.call('LPUSH', code .. '_buy', _id .. ',' .. _price .. ',' .. _num..',' .. _priority);
        matchMarketBuy();
        num = 0;
    end
end;

local function limitSell()
    while true do
        --先匹配限价单
        local limitBuyNode = redis.call('LPOP', code .. '_buy');
        if (limitBuyNode == false) then
            --无限价单，匹配市价单
            matchMarketBuy();
            break ;
        end ;
        local limitBuyContent = split(limitBuyNode, ',');
        local _id = limitBuyContent[1];
        local _price = limitBuyContent[2];
        local _num = limitBuyContent[3];
        local _priority= limitBuyContent[4];
        limitBuyContent = nil;
        --比较限价买单  和当前限价卖单的价格
        dealPerMatch(_id, _price, _num,_priority);
        if (num == 0) then
            break ;
        end ;
    end ;
end;


limitSell();
res = res .. ',' .. lasthasleft;
return res;
