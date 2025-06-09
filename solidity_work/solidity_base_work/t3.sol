// SPDX-License-Ientifier: MIT
pragma solidity ^0.8.30;

contract RomanNumCoverter{

    
    function charToValue(bytes1  char) private pure returns (uint256){
        if (char == 'I') return 1;
        else if (char == 'V') return 5;
        else if (char == 'X') return 10;
        else if (char == 'L') return 50;
        else if (char == 'C') return 100;
        else if (char == 'D') return 500;
        else if (char == 'M') return 1000;
        else return 0; // 不应该发生
    }

    // 将罗马数字字符转换为对应的数值
    function romanToInt(string memory s) public pure returns (uint256) {
        // 将输入字符串转换为字节数组便于处理
        bytes memory roman = bytes(s);
        uint256 total = 0;
        
        // 从右向左遍历罗马数字
        for (uint256 i = roman.length; i > 0; i--) {
            uint256 current = charToValue(roman[i - 1]);
            
            // 检查当前字符是否小于右侧字符（特殊情况处理）
            if (i < roman.length && current < charToValue(roman[i])) {
                total -= current; // 减去当前值（如 IV 中的 I）
            } else {
                total += current; // 加上当前值
            }
        }
        
        return total;
    }



}