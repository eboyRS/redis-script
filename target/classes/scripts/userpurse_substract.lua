local purse = redis.call('hmget', KEYS[1], KEYS[2])[1]
if purse == false then
    purse = 0
end
local aa = purse - ARGV[1]
if aa > 0 or aa == 0
then
    redis.call('hmset', KEYS[1], KEYS[2], aa)
    return '1';
else
    return '0';
end