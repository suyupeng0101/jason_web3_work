// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Counter{

    uint256 private count;

    event CounterChanged(uint256 newCount);

    constructor(uint256 _start) {
        count = _start;
    }

    function increment() external {
        count += 1;
        emit CounterChanged(count);
    }

    function get() external view returns (uint256) {
        return count;
    }

}