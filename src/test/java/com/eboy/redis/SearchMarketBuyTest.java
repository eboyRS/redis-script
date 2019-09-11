package com.eboy.redis;

import com.google.common.collect.Lists;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Data;

/**
 * @author: eboy
 * @createTime: 19-9-10 下午4:09
 **/
public class SearchMarketBuyTest {


    public static void main(String[] args) {

        List<Sell> nums = Lists.newArrayList(
                new Sell(1),
                new Sell(1),
                new Sell(2),
                new Sell(2),
                new Sell(5),
                new Sell(5),
                new Sell(5),
                new Sell(6),
                new Sell(9),
                new Sell(9),
                new Sell(9),
                new Sell(9)




        );
        Sell target = new Sell(1);
        int index = searchInsert(nums, target);
        System.out.println(index);

        if (index >= nums.size()) {
            nums.add(target);
        } else {

            nums.add(index, target);
        }
        for (int i = 0; i < nums.size(); i++) {
            Sell sell = nums.get(i);
            System.out.println(i + "-----" + sell);

        }


    }

    public static int searchInsert(List<Sell> nums, Sell target) {

        if (nums == null || nums.size() == 0) {
            return 0;
        }
        int left = 0, right = nums.size() - 1, len = nums.size();

        if (target.getPriority() < nums.get(left).getPriority()) {
            return 0;
        }

        if (target.priority >= nums.get(right).getPriority()) {
            return right + 1;
        }

        while (left <= right) {
            int mid = left + (right - left) / 2;
            if (nums.get(mid).getPriority() == target.getPriority()) {

                while (mid < len - 1) {
                    if (nums.get(mid + 1).getPriority() == target.getPriority()) {
                        mid++;
                    } else {
                        break;
                    }
                }
                return mid+1;
            } else if ( nums.get(mid).getPriority() < target.getPriority()) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }
        return left;
    }

    @Data
    @AllArgsConstructor
    public static class Sell {

        private int priority;
    }
}
