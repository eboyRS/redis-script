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
    local index = redis.call('LINDEX', code .. '_buy', _index);
    local content = split(index, ',');
    return content;
end

local function getIndex(_start,_end)
    local maxIndex = _end;
    local content = getContent(_start);
    if(tonumber(price)>tonumber(content[2]) or (tonumber(price)==tonumber(content[2]) and tonumber(priority)< tonumber(content[4])))then
        return _start;
    end
    local endContent = getContent(_end);
    if(tonumber(price)<tonumber(endContent[2]) or (tonumber(price)==tonumber(endContent[2]) and tonumber(priority) >= tonumber(endContent[4])))then
        return _end+1;
    end

    while(_start<=_end) do
        local mid= _start + math.floor((_end -_start)/2)

        local midContent=getContent(mid)
        if(tonumber(midContent[2])==tonumber(price) and tonumber(midContent[4]) == tonumber(priority))then
            while(mid < maxIndex) do
                local next=getContent(mid+1)
                if(tonumber(next[2])==tonumber(price) and tonumber(next[4]) == tonumber(priority))then
                    mid=mid+1;
                else
                    break;
                end
            end
            return mid+1;
        else
            if(tonumber(midContent[2])>tonumber(price) or (tonumber(midContent[2])==tonumber(price) and tonumber(midContent[4]) <= tonumber(priority)))then
                _start=mid+1;
            else
                _end=mid-1;
            end
        end
    end
    return _start;
end

--排序方式为从大到小，从最价格最高到价格最低
local function insertBuyList()
    local startIndex = 0;
    --获取卖单队列长度
    local len = redis.call('LLEN', code .. '_buy');
    local endIndex=len-1
    if(len==0)then
        redis.call('LPUSH', code .. '_buy', id .. ',' .. price .. ',' ..  string.format("%.0f", num) ..',' .. priority);
    else
        --使用二分查找，确定卖单位置
        local index=getIndex(startIndex,endIndex)
        if(index>=len)then
            --超出当前最大位置，直接插入到队尾
            redis.call('RPUSH', code .. '_buy', id .. ',' .. price .. ',' .. string.format("%.0f", num) ..',' .. priority);
        else
            --位置在范围内，直接插入到制定位置
            local aa = redis.call('LINDEX', code .. '_buy', index);
            redis.call('LINSERT', code .. '_buy', 'BEFORE', aa, id .. ',' .. price .. ',' .. string.format("%.0f", num)..',' .. priority);
        end
    end
end;





local function matchSuccess(_id, _price, _num, _priority)
    if (tonumber(num) < tonumber(_num)) then
        --当前卖单数据小于当前买单数量，则卖单完成，并且将买单剩余量存回去
        local left = _num - num;
        redis.call('RPUSH', code .. '_sell', _id .. ',' .. _price .. ',' .. string.format("%.0f", left)..',' .. _priority);
        res = res .. ',' .. _id .. ',' .. _price .. ',' .. string.format("%.0f", num);
        num = 0;
        lasthasleft = 1;
    else
        --当前卖单数据大于当前买单数量，则吃掉买单
        res = res .. ',' .. _id .. ',' .. _price .. ',' .. _num;
        num = num - _num;
    end ;

end;

local function matchMarketSell()
    while true do
        local marketSellNode = redis.call('LPOP', code .. '_market_sell');
        if (marketSellNode == false) then
            --如果没有市价买单，则存储卖单数据
            insertBuyList();
            break ;
        end ;
        local marketSellContent = split(marketSellNode, ',');
        local _id = marketSellContent[1];
        local _num = marketSellContent[2];
        local _priority= marketSellContent[3];
        marketSellContent = nil;
        if(tonumber(_num)<=tonumber(num))then
            --如果市价买单购买量小于当前限价卖单，则把买单全部吃掉，但是由于存在极小值问题，市价买单会存在一定精度外额度未成交

            res = res .. ',' .. _id ..',' .. price .. ',' ..  string.format("%.0f", _num);
            num = num - _num;
        else
            --如果市价买单购买量大于当前限价卖单，则卖单完成，并且将买单剩余量存回去
            local left = num - _num;
            redis.call('LPUSH', code .. '_market_sell', _id .. ',' .. string.format("%.0f", left)..',' .. _priority);
            res = res .. ',' .. _id .. ',' .. price .. ',' .. string.format("%.0f", num);
            num = 0;
            lasthasleft = 1;
        end
    end;
end;


local function dealPerMatch(_id, _price, _num, _priority)
    if (tonumber(price) >= tonumber(_price)) then
        -- 如果当前卖单价格大于等于买单价格,则成交
        matchSuccess(_id, _price, _num,_priority);
    else
        -- 如果当前卖单价格大于买单价格,则匹配市价单
        redis.call('RPUSH', code .. '_sell', _id .. ',' .. _price .. ',' .. _num..',' .. _priority);
        matchMarketSell();
        num = 0;
    end
end;

local function limitBuy()
    while true do
        --先匹配限价单
        local limitSellNode = redis.call('RPOP', code .. '_sell');
        if (limitSellNode == false) then
            --无限价单，匹配市价单
            matchMarketSell();
            break ;
        end ;
        local limitSellContent = split(limitSellNode, ',');
        local _id = limitSellContent[1];
        local _price = limitSellContent[2];
        local _num = limitSellContent[3];
        local _priority= limitSellContent[4];
        limitSellContent = nil;
        --比较限价买单  和当前限价卖单的价格
        dealPerMatch(_id, _price, _num,_priority);
        if (num == 0) then
            break ;
        end ;
    end ;
end;


limitBuy();
res = res .. ',' .. lasthasleft;
return res;
