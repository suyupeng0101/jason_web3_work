// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


contract BinarySearch{


    // function binarySearch(uint256[] memory arr, uint256 target)public pure returns (int256){

    //     // 如果是空数组
    //     if(arr.length == 0){
    //         return -1;
    //     } 
        
    //     // 设置左右边界指针
    //     int256 left = 0;

    //     int right = int256(arr.length) - 1;


    //     //开始二分查找

    //     while(left <= right){
    //         //计算中间索引
    //         int256 mid = left + (right - left) / 2;

    //          // 获取中间值
    //         uint256 midVal = arr[uint256(mid)];

    //         // 比较目标值与中间值
    //         if (midVal == target) {
    //             return mid;          // 找到目标，返回索引
    //         } else if (midVal < target) {
    //             left = mid + 1;      // 目标在右半部分
    //         } else {
    //             right = mid - 1;     // 目标在左半部分
    //         }

    //     }

    //     // 未找到目标
    //     return -1;

    // }


    function binarySearch(string[] memory arr, string memory target) 
        public 
        pure 
        returns (int256) {

        // 空数组处理
        if (arr.length == 0) return -1;


                // 设置左右边界指针
        int256 left = 0;
        int256 right = int256(arr.length) - 1;
        
        // 开始二分查找
        while (left <= right) {
            // 计算中间索引（防止整数溢出）
            int256 mid = left + (right - left) / 2;
            
            // 获取中间字符串
            string memory midVal = arr[uint256(mid)];
            
            // 比较目标字符串和中间字符串
            int compareResult = _compareStrings(midVal, target);
            
            if (compareResult == 0) {
                return mid;          // 找到目标，返回索引
            } else if (compareResult < 0) {
                left = mid + 1;      // 目标字典序大于中间值
            } else {
                right = mid - 1;     // 目标字典序小于中间值
            }
        }
        
        // 未找到目标
        return -1;


    }

        // 内部函数：比较两个字符串
    function _compareStrings(string memory a, string memory b) 
        internal 
        pure 
        returns (int) 
    {
        // 转换为字节数组便于比较
        bytes memory bytesA = bytes(a);
        bytes memory bytesB = bytes(b);
        
        // 确定最小长度
        uint minLength = bytesA.length;
        if (bytesB.length < minLength) minLength = bytesB.length;
        
        // 逐个字符比较
        for (uint i = 0; i < minLength; i++) {
            if (bytesA[i] < bytesB[i]) {
                return -1;  // a < b
            } else if (bytesA[i] > bytesB[i]) {
                return 1;   // a > b
            }
        }
        
        // 公共前缀相同，比较长度
        if (bytesA.length < bytesB.length) {
            return -1;  // a < b（a是b的前缀）
        } else if (bytesA.length > bytesB.length) {
            return 1;   // a > b（b是a的前缀）
        } else {
            return 0;    // a == b
        }
    }

}