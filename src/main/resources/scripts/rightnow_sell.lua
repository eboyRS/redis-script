local res = '';
local code = KEYS[1];
local num = ARGV[1];
local lasthasleft=0;

local function split(str, delimiter)
  if str==nil or str=='' or delimiter==nil then
    return nil
  end

  local result = {}
  for match in (str..delimiter):gmatch("(.-)"..delimiter) do
    table.insert(result, match)
  end
  return result
end

local function findprice_num(_id,_price,_num)
  local left = num-_num;
  if(left>=0) then
  res = res..','.._id..','.._price..','..string.format("%.0f", _num);
  num = left;
  else
  res = res..','.._id..','.._price..','..string.format("%.0f", num);
  num = 0;
  redis.call('LPUSH',code..'buy',_id..','.._price..','..string.format("%.0f", (0-left)));
  lasthasleft = 1;
  end;
end;


local function findfit()
while true do
    local aa = redis.call('LPOP',code..'buy');
    if(aa == false) then
      break;
    end;
    local bb = split(aa,',');
    local _id = bb[1];
    local _price = bb[2];
    local _num = bb[3];
    bb = nil;
    findprice_num(_id,_price,_num);
    if(num==0) then
    break;
    end;
end;
end;
findfit();
res = res..','..lasthasleft;
return res;
