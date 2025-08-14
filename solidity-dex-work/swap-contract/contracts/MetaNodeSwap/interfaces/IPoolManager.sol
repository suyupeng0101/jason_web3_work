// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;
pragma abicoder v2;

import "./IFactory.sol";

// 池管理器接口，继承自工厂接口，扩展了池的管理功能
interface IPoolManager is IFactory {
    /**
     * @notice 定义池的详细信息
     * @param pool 池的地址
     * @param token0 池中第一个代币的地址
     * @param token1 池中第二个代币的地址
     * @param index 池的索引值，用于区分多个池
     * @param fee 池的手续费率，以百万分比表示（例如 3000 表示 0.3%）
     * @param feeProtocol 协议手续费的比例
     * @param tickLower 池的最低 tick 值
     * @param tickUpper 池的最高 tick 值
     * @param tick 当前 tick 值
     * @param sqrtPriceX96 当前池的平方根价格，表示为 Q64.96 格式
     * @param liquidity 当前池的流动性总量
     */
    struct PoolInfo {
        address pool;
        address token0;
        address token1;
        uint32 index;
        uint24 fee;
        uint8 feeProtocol;
        int24 tickLower;
        int24 tickUpper;
        int24 tick;
        uint160 sqrtPriceX96;
        uint128 liquidity;
    }

    /**
     * @notice 定义代币对信息
     * @param token0 代币对中的第一个代币地址
     * @param token1 代币对中的第二个代币地址
     */
    struct Pair {
        address token0;
        address token1;
    }

    /**
     * @notice 获取所有代币对信息
     * @return 包含所有代币对的数组
     */
    function getPairs() external view returns (Pair[] memory);

    /**
     * @notice 获取所有池的详细信息
     * @return poolsInfo 包含所有池信息的数组
     */
    function getAllPools() external view returns (PoolInfo[] memory poolsInfo);

    /**
     * @notice 定义创建并初始化池的参数
     * @param token0 池中第一个代币的地址
     * @param token1 池中第二个代币的地址
     * @param fee 池的手续费率
     * @param tickLower 池的最低 tick 值
     * @param tickUpper 池的最高 tick 值
     * @param sqrtPriceX96 初始的平方根价格，表示为 Q64.96 格式
     */
    struct CreateAndInitializeParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint160 sqrtPriceX96;
    }

    /**
     * @notice 如果必要，创建并初始化一个新的流动性池
     * @param params 包含创建和初始化池所需的参数
     * @return pool 新创建的池的地址
     */
    function createAndInitializePoolIfNecessary(
        CreateAndInitializeParams calldata params
    ) external payable returns (address pool);
}
