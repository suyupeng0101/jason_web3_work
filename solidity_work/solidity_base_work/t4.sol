// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract IntegerToRoman {
    // 将整数转换为罗马数字
    function intToRoman(uint256 num) public pure returns (string memory) {
        // 验证输入范围（标准罗马数字最多支持3999）
        require(num > 0 && num < 4000, "Number must be between 1 and 3999");
        
        // 存储结果的字节数组（内存高效处理）
        bytes memory roman;
        
        // 定义所有可能的罗马数字组合（包含减法形式）
        string[13] memory symbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
        uint16[13] memory values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
        
        // 处理转换过程
        for (uint256 i = 0; i < values.length; i++) {
            // 当前值可被减去多少次
            while (num >= values[i]) {
                // 将符号追加到结果
                bytes memory symbolBytes = bytes(symbols[i]);
                for (uint256 j = 0; j < symbolBytes.length; j++) {
                    roman = abi.encodePacked(roman, symbolBytes[j]);
                }
                num -= values[i];
            }
        }
        
        return string(roman);
    }
}