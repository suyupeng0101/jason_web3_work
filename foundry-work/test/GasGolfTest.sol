// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
//import "../src/GasGolf1.sol";
import "../src/GasGolf2.sol";

contract GasGolfTest is Test {
    GasGolf public gasGolf;

    function setUp() public {
        gasGolf = new GasGolf();
    }

    function testSumIfEvenAndLessThan99() public {
        uint[] memory nums = new uint[](6);
        nums[0] = 1;
        nums[1] = 2;
        nums[2] = 3;
        nums[3] = 4;
        nums[4] = 5;
        nums[5] = 100;

        gasGolf.sumIfEvenAndLessThan99(nums);

        // 符合条件的数字是 2 和 4，它们的和为 6
        assertEq(gasGolf.total(), 6);
    }
}
