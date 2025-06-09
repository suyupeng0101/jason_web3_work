// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30

contract StringReverser {

    // 反转字符串
    function reverse (string memory input) public pure returns (string memory) {

        bytes memory inputBytes = bytes(input)

        uint length =  inputBytes.length;

        // 字节数组
        bytes memory reversedBytes = new bytes(length)


        // 执行反转操作：将第一个字符与最后一个交换，第二个与倒数第二个交换，依此类推

        for(uint i = 0, i < length; i++){
            reversedBytes[i] = inputBytes[length - 1 - i];
        }

        return string(reversedBytes);

    }

}