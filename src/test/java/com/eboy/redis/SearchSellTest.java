package com.eboy.redis;

import com.google.common.collect.Lists;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Data;

/**
 * @author: eboy
 * @createTime: 19-9-10 下午4:09
 **/
public class SearchSellTest {


    public static void main(String[] args) {

        List<Sell> nums= Lists.newArrayList(




                new Sell(9,1),
                new Sell(9,0),
                new Sell(9,0),
                new Sell(9,0),
                new Sell(6,0),
                new Sell(5,2),
                new Sell(5,1),
                new Sell(5,0),
                new Sell(2,0),
                new Sell(2,0),
                new Sell(1,2),
                new Sell(1,1)
                );
        Sell target = new Sell(1, 0);
        int index = searchInsert(nums, target);
        System.out.println(index);

        if(index>=nums.size()){
            nums.add(target);
        }else {

            nums.add(index,target);
        }
        for (int i = 0; i < nums.size(); i++) {
            Sell sell =  nums.get(i);
            System.out.println(i+"-----"+sell);

        }


    }

    public static int searchInsert(List<Sell>  nums, Sell target) {
        if (nums == null || nums.size() == 0) {
            return 0;
        }
        int left = 0, right = nums.size() - 1;

        if(target.getPrice()>nums.get(left).getPrice()||(target.getPrice()==nums.get(left).getPrice()&&target.priority>=nums.get(left).getPriority())){
            return 0;
        }

        if(target.getPrice()<nums.get(right).getPrice()||(target.getPrice()==nums.get(right).getPrice()&&target.priority<nums.get(right).getPriority())){
            return right+1;
        }

        while (left <= right) {
            int mid = left + (right - left) / 2;
            if (nums.get(mid).getPrice() == target.getPrice()&&nums.get(mid).getPriority()==target.getPriority()) {

                while (mid>=1){
                    if(nums.get(mid-1).getPrice() == target.getPrice()&&nums.get(mid-1).getPriority()==target.getPriority()){
                        mid--;
                    }else{
                        break;
                    }
                }
                return mid;
            } else if (nums.get(mid).getPrice() > target.getPrice()||(nums.get(mid).getPrice()==target.getPrice()&&nums.get(mid).getPriority()>target.getPriority())) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }
        return left;
    }

    @Data
    @AllArgsConstructor
    public static class Sell{
        private int price;

        private int priority;
    }
}
