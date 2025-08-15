// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, stdError,console} from "forge-std/Test.sol";

contract CounterTest is Test {
    uint256 public counter;

    function beforeTestSetup(bytes4 testSelector) public returns (bytes[] memory beforeTestCalldata){
        beforeTestCalldata = new bytes[](1);
        beforeTestCalldata[0] = abi.encodeWithSelector(testSelector);
        vm.broadcast();
        return beforeTestCalldata;
    }


    function setUp() public {
        counter = 0;
        console.log("beforeTestSetup==============");
    }

      function testSomething() public {
          counter = 0;
        console.log("testSomething==============",counter++);
        console.log("testSomething==============",++counter);
    }

    function test_Increment() public {
        ++counter;
        assertEq(counter, 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter =x;
        assertEq(counter, x);
    }

//     uint256 public testNumber;
//     function testCannotSubtract43() public {
//        vm.expectRevert(stdError.arithmeticError);
//        testNumber -= 43;
//    }
}
