local aa = redis.call('hmget',KEYS[1],KEYS[2])[1];
if(aa==nil or aa==false)
then
return redis.call('hmset',KEYS[1],KEYS[2],ARGV[1]);
else
local bb = aa + ARGV[1];
return redis.call('hmset',KEYS[1],KEYS[2],bb)

end;


