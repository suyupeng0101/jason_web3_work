// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


contract GasGolf {
    uint public total;
// [1, 2, 3, 4, 5, 100]
    function sumIfEvenAndLessThan99(uint[] calldata nums) public {
        uint _total = total;
        uint len = nums.length;
        for (uint i = 0; i < len; ++i) {
            uint num = nums[i];
            if (num % 2 == 0 && num < 99) {
                _total += num;
            }
        }
        total = _total;
    }
}