// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

// 工厂接口，负责创建和管理流动性池
interface IFactory {
    /**
     * @notice 定义池的初始化参数
     * @param factory 工厂合约的地址
     * @param tokenA 池中第一个代币的地址
     * @param tokenB 池中第二个代币的地址
     * @param tickLower 池的最低 tick 值
     * @param tickUpper 池的最高 tick 值
     * @param fee 池的手续费率，以百万分比表示（例如 3000 表示 0.3%）
     */
    struct Parameters {
        address factory;
        address tokenA;
        address tokenB;
        int24 tickLower;
        int24 tickUpper;
        uint24 fee;
    }

    /**
     * @notice 返回当前池的初始化参数
     * @return factory 工厂合约的地址
     * @return tokenA 池中第一个代币的地址
     * @return tokenB 池中第二个代币的地址
     * @return tickLower 池的最低 tick 值
     * @return tickUpper 池的最高 tick 值
     * @return fee 池的手续费率
     */
    function parameters()
        external
        view
        returns (
            address factory,
            address tokenA,
            address tokenB,
            int24 tickLower,
            int24 tickUpper,
            uint24 fee
        );

    /**
     * @notice 创建池的事件
     * @param token0 池中第一个代币的地址（排序后）
     * @param token1 池中第二个代币的地址（排序后）
     * @param index 池的索引值，用于区分多个池
     * @param tickLower 池的最低 tick 值
     * @param tickUpper 池的最高 tick 值
     * @param fee 池的手续费率
     * @param pool 新创建的池的地址
     */
    event PoolCreated(
        address token0,
        address token1,
        uint32 index,
        int24 tickLower,
        int24 tickUpper,
        uint24 fee,
        address pool
    );

    /**
     * @notice 获取指定代币对和索引的池地址
     * @param tokenA 池中第一个代币的地址
     * @param tokenB 池中第二个代币的地址
     * @param index 池的索引值
     * @return pool 池的地址
     */
    function getPool(
        address tokenA,
        address tokenB,
        uint32 index
    ) external view returns (address pool);

    /**
     * @notice 创建一个新的流动性池
     * @param tokenA 池中第一个代币的地址
     * @param tokenB 池中第二个代币的地址
     * @param tickLower 池的最低 tick 值
     * @param tickUpper 池的最高 tick 值
     * @param fee 池的手续费率
     * @return pool 新创建的池的地址
     */
    function createPool(
        address tokenA,
        address tokenB,
        int24 tickLower,
        int24 tickUpper,
        uint24 fee
    ) external returns (address pool);
}
