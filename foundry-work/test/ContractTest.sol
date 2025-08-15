// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, stdError,console} from "forge-std/Test.sol";


contract ContractTest is Test {
    uint256 a;
    uint256 b;

    function beforeTestSetup(
        bytes4 testSelector
    ) public pure returns (bytes[] memory beforeTestCalldata) {
        if (testSelector == this.testC.selector) {
            beforeTestCalldata = new bytes[](2);
            beforeTestCalldata[0] = abi.encodePacked(this.testA.selector);
            beforeTestCalldata[1] = abi.encodeWithSignature("setB(uint256)", 1);
        }
        console.log("beforeTestSetup==============");
    }

    function testA() public {
        require(a == 0);
        a += 1;
        console.log("testA==============");
    }

    function setB(uint256 value) public {
        b = value;
        console.log("setB==============");
    }

    function testC() public {
        assertEq(a, 1);
        assertEq(b, 1);
        console.log("testC==============");
    }
}