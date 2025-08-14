// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import "./interfaces/IFactory.sol";
import "./Pool.sol";

// 工厂合约，用于创建和管理流动性池
contract Factory is IFactory {
    // 存储所有池的映射，按 token0 和 token1 分类，每个分类下有一个池地址数组
    mapping(address => mapping(address => address[])) public pools;

    // 当前池的初始化参数
    Parameters public override parameters;

    /**
     * @notice 对两个代币地址进行排序，确保 token0 的地址小于 token1
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @return token0 排序后的第一个代币地址
     * @return token1 排序后的第二个代币地址
     */
    function sortToken(
        address tokenA,
        address tokenB
    ) private pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /**
     * @notice 获取指定代币对和索引的池地址
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
     * @param index 池的索引值
     * @return 池的地址
     */
    function getPool(
        address tokenA,
        address tokenB,
        uint32 index
    ) external view override returns (address) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        require(tokenA != address(0) && tokenB != address(0), "ZERO_ADDRESS");

        // 对代币地址进行排序
        address token0;
        address token1;
        (token0, token1) = sortToken(tokenA, tokenB);

        return pools[token0][token1][index];
    }

    /**
     * @notice 创建一个新的流动性池
     * @param tokenA 第一个代币地址
     * @param tokenB 第二个代币地址
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
    ) external override returns (address pool) {
        // 验证代币地址是否相同
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");

        // 对代币地址进行排序
        address token0;
        address token1;
        (token0, token1) = sortToken(tokenA, tokenB);

        // 获取当前代币对的所有池
        address[] memory existingPools = pools[token0][token1];

        // 检查是否已存在相同参数的池
        for (uint256 i = 0; i < existingPools.length; i++) {
            IPool currentPool = IPool(existingPools[i]);

            if (
                currentPool.tickLower() == tickLower &&
                currentPool.tickUpper() == tickUpper &&
                currentPool.fee() == fee
            ) {
                return existingPools[i];
            }
        }

        // 保存池的初始化参数
        parameters = Parameters(
            address(this),
            token0,
            token1,
            tickLower,
            tickUpper,
            fee
        );

        // 使用 create2 生成唯一的盐值
        bytes32 salt = keccak256(
            abi.encode(token0, token1, tickLower, tickUpper, fee)
        );

        // 创建新的池合约
        pool = address(new Pool{salt: salt}());

        // 将新创建的池地址保存到映射中
        pools[token0][token1].push(pool);

        // 删除池的初始化参数
        delete parameters;

        // 触发池创建事件
        emit PoolCreated(
            token0,
            token1,
            uint32(existingPools.length),
            tickLower,
            tickUpper,
            fee,
            pool
        );
    }
}
