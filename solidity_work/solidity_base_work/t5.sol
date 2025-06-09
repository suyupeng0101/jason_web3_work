// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;



contract MergeArr{


    function merge(uint256[] memory a, uint256[] memory b) public pure returns(uint256[] memory result){


        uint256 i = 0;  // a数组索引
        uint256 j = 0;  // b数组索引
        result = new uint256[](a.length + b.length); // 预分配结果数组

        // 单次循环处理所有元素
        for (uint256 k = 0; k < result.length; k++) {
            // 检查a数组是否还有元素，并且它比b当前元素小（或b已遍历完）
            if (i < a.length && (j >= b.length || a[i] <= b[j])) {
                result[k] = a[i];
                i++;
            } else {
                result[k] = b[j];
                j++;
            }
        }
    }
}