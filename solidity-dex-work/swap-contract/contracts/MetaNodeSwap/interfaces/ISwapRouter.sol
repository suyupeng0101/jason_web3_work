// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;
pragma abicoder v2;

import "./IPool.sol";

// 交换路由器接口，继承自 ISwapCallback，用于处理代币交换逻辑
interface ISwapRouter is ISwapCallback {
    /**
     * @notice 交换事件
     * @param sender 调用者地址
     * @param zeroForOne 交换方向，true 表示 token0 换 token1，false 表示 token1 换 token0
     * @param amountIn 输入的代币数量
     * @param amountInRemaining 剩余未使用的输入代币数量
     * @param amountOut 输出的代币数量
     */
    event Swap(
        address indexed sender,
        bool zeroForOne,
        uint256 amountIn,
        uint256 amountInRemaining,
        uint256 amountOut
    );

    /**
     * @notice 定义精确输入交换的参数
     * @param tokenIn 输入代币的地址
     * @param tokenOut 输出代币的地址
     * @param indexPath 交换路径的索引数组
     * @param recipient 接收输出代币的地址
     * @param deadline 交易的截止时间戳
     * @param amountIn 输入代币的数量
     * @param amountOutMinimum 最小可接受的输出代币数量
     * @param sqrtPriceLimitX96 价格限制，表示为 Q64.96 格式
     */
    struct ExactInputParams {
        address tokenIn;
        address tokenOut;
        uint32[] indexPath;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /**
     * @notice 执行精确输入的代币交换
     * @param params 包含交换所需的参数
     * @return amountOut 实际输出的代币数量
     */
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    /**
     * @notice 定义精确输出交换的参数
     * @param tokenIn 输入代币的地址
     * @param tokenOut 输出代币的地址
     * @param indexPath 交换路径的索引数组
     * @param recipient 接收输出代币的地址
     * @param deadline 交易的截止时间戳
     * @param amountOut 输出代币的数量
     * @param amountInMaximum 最大可接受的输入代币数量
     * @param sqrtPriceLimitX96 价格限制，表示为 Q64.96 格式
     */
    struct ExactOutputParams {
        address tokenIn;
        address tokenOut;
        uint32[] indexPath;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /**
     * @notice 执行精确输出的代币交换
     * @param params 包含交换所需的参数
     * @return amountIn 实际使用的输入代币数量
     */
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);

    /**
     * @notice 定义精确输入报价的参数
     * @param tokenIn 输入代币的地址
     * @param tokenOut 输出代币的地址
     * @param indexPath 交换路径的索引数组
     * @param amountIn 输入代币的数量
     * @param sqrtPriceLimitX96 价格限制，表示为 Q64.96 格式
     */
    struct QuoteExactInputParams {
        address tokenIn;
        address tokenOut;
        uint32[] indexPath;
        uint256 amountIn;
        uint160 sqrtPriceLimitX96;
    }

    /**
     * @notice 获取精确输入的报价
     * @param params 包含报价所需的参数
     * @return amountOut 预期的输出代币数量
     */
    function quoteExactInput(
        QuoteExactInputParams calldata params
    ) external returns (uint256 amountOut);

    /**
     * @notice 定义精确输出报价的参数
     * @param tokenIn 输入代币的地址
     * @param tokenOut 输出代币的地址
     * @param indexPath 交换路径的索引数组
     * @param amountOut 输出代币的数量
     * @param sqrtPriceLimitX96 价格限制，表示为 Q64.96 格式
     */
    struct QuoteExactOutputParams {
        address tokenIn;
        address tokenOut;
        uint32[] indexPath;
        uint256 amountOut;
        uint160 sqrtPriceLimitX96;
    }

    /**
     * @notice 获取精确输出的报价
     * @param params 包含报价所需的参数
     * @return amountIn 预期的输入代币数量
     */
    function quoteExactOutput(
        QuoteExactOutputParams calldata params
    ) external returns (uint256 amountIn);
}
