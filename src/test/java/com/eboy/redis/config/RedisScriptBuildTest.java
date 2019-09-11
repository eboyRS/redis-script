package com.eboy.redis.config;

import com.eboy.redis.config.RedisScriptConfig.RedisScriptBuilder;
import com.google.common.collect.Lists;
import java.math.BigDecimal;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.test.context.junit4.SpringRunner;

/**
 * @author: eboy
 * @createTime: 19-9-10 下午2:11
 **/
@RunWith(SpringRunner.class)
@SpringBootTest
public class RedisScriptBuildTest {

    @Autowired
    private RedisScriptBuilder redisScriptBuilder;

    @Autowired
    private StringRedisTemplate redisTemplate;



    @Test
    public void testLimitSell(){
        String id = String.valueOf(System.currentTimeMillis());
        String price = new BigDecimal("10010.02").multiply(BigDecimal.valueOf(100)).stripTrailingZeros().toPlainString();
        String amount = new BigDecimal("0.000003").multiply(BigDecimal.valueOf(1000000)).stripTrailingZeros().toPlainString();
        String priority="1";
        String execute = redisTemplate
                .execute(redisScriptBuilder.build("limit_sell_new"), Lists.newArrayList("btc_usdt"),
                        Lists.newArrayList(
                                id, price, amount,priority).toArray());

        System.out.println(execute);
    }

}
