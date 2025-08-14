// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// 头寸管理器接口，继承自 ERC721 接口，用于管理流动性头寸
interface IPositionManager is IERC721 {
    /**
     * @notice 定义流动性头寸的详细信息
     * @param id 头寸的唯一标识符
     * @param owner 头寸的所有者地址
     * @param token0 头寸中第一个代币的地址
     * @param token1 头寸中第二个代币的地址
     * @param index 池的索引值，用于区分多个池
     * @param fee 池的手续费率，以百万分比表示（例如 3000 表示 0.3%）
     * @param liquidity 头寸的流动性数量
     * @param tickLower 头寸的最低 tick 值
     * @param tickUpper 头寸的最高 tick 值
     * @param tokensOwed0 头寸中欠的 token0 数量
     * @param tokensOwed1 头寸中欠的 token1 数量
     * @param feeGrowthInside0LastX128 token0 的最后一次手续费增长量，用于计算手续费
     * @param feeGrowthInside1LastX128 token1 的最后一次手续费增长量，用于计算手续费
     */
    struct PositionInfo {
        uint256 id;
        address owner;
        address token0;
        address token1;
        uint32 index;
        uint24 fee;
        uint128 liquidity;
        int24 tickLower;
        int24 tickUpper;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
    }

    /**
     * @notice 获取所有流动性头寸的信息
     * @return positionInfo 包含所有头寸信息的数组
     */
    function getAllPositions()
        external
        view
        returns (PositionInfo[] memory positionInfo);

    /**
     * @notice 定义铸造流动性头寸的参数
     * @param token0 头寸中第一个代币的地址
     * @param token1 头寸中第二个代币的地址
     * @param index 池的索引值
     * @param amount0Desired 希望提供的 token0 数量
     * @param amount1Desired 希望提供的 token1 数量
     * @param recipient 接收头寸的地址
     * @param deadline 交易的截止时间戳
     */
    struct MintParams {
        address token0;
        address token1;
        uint32 index;
        uint256 amount0Desired;
        uint256 amount1Desired;
        address recipient;
        uint256 deadline;
    }

    /**
     * @notice 铸造一个新的流动性头寸
     * @param params 包含铸造头寸所需的参数
     * @return positionId 新铸造头寸的唯一标识符
     * @return liquidity 铸造的流动性数量
     * @return amount0 实际使用的 token0 数量
     * @return amount1 实际使用的 token1 数量
     */
    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (
            uint256 positionId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /**
     * @notice 销毁一个流动性头寸
     * @param positionId 要销毁的头寸的唯一标识符
     * @return amount0 销毁时释放的 token0 数量
     * @return amount1 销毁时释放的 token1 数量
     */
    function burn(
        uint256 positionId
    ) external returns (uint256 amount0, uint256 amount1);

    /**
     * @notice 收集头寸的手续费
     * @param positionId 要收集手续费的头寸的唯一标识符
     * @param recipient 收集手续费的接收者地址
     * @return amount0 收集的 token0 数量
     * @return amount1 收集的 token1 数量
     */
    function collect(
        uint256 positionId,
        address recipient
    ) external returns (uint256 amount0, uint256 amount1);

    /**
     * @notice 铸造回调函数，用于在铸造流动性时调用
     * @param amount0 铸造时需要的 token0 数量
     * @param amount1 铸造时需要的 token1 数量
     * @param data 附加数据，通常用于传递上下文信息
     */
    function mintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}
