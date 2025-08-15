// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


contract GasGolf {
    uint public total;
    // [1, 2, 3, 4, 5, 100]
    function sumIfEvenAndLessThan99(uint[] memory nums) public  {
        for (uint i = 0; i < nums.length; i += 1) {
            bool isEven = nums[i] % 2 == 0;
            bool isLessThan99 = nums[i] < 99;
            if (isEven && isLessThan99) {
                total += nums[i];
            }
        }
    }
}