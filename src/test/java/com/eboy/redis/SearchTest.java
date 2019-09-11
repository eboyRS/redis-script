package com.eboy.redis;

import lombok.Data;

/**
 * @author: eboy
 * @createTime: 19-9-10 下午4:09
 **/
public class SearchTest {


    public static void main(String[] args) {

        int[] nums=new int[]{1,1,2,2,2,3,3,3,4,4,4,5,5,5,9,10,10};
        int i = searchInsert(nums, 10);
        System.out.println(i);

    }

    public static int searchInsert(int[] nums, int target) {
        if (nums == null || nums.length == 0) {
            return 0;
        }
        int left = 0, right = nums.length - 1;

        if(target<nums[left]){
            return 0;
        }

        if(target>nums[right]){
            return right+1;
        }

        while (left <= right) {
            int mid = left + (right - left) / 2;
            if (nums[mid] == target) {

                while (mid<right){
                    if(nums[mid+1]==target){
                        mid++;
                    }else{
                        break;
                    }
                }
                return mid;
            } else if (nums[mid] < target) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }
        return left;
    }

    @Data
    public static class Sell{
        private int price;

        private int priority;
    }
}
