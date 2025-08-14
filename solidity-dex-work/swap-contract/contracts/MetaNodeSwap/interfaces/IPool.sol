// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

// 回调接口，用于在铸造流动性时调用
interface IMintCallback {
    /**
     * @notice 在铸造流动性时调用的回调函数
     * @param amount0Owed 铸造后需要支付的 token0 数量
     * @param amount1Owed 铸造后需要支付的 token1 数量
     * @param data 附加数据，通常用于传递上下文信息
     */
    function mintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// 回调接口，用于在交换时调用
interface ISwapCallback {
    /**
     * @notice 在交换时调用的回调函数
     * @param amount0Delta 交换后 token0 的变化量（正数表示需要支付，负数表示接收）
     * @param amount1Delta 交换后 token1 的变化量（正数表示需要支付，负数表示接收）
     * @param data 附加数据，通常用于传递上下文信息
     */
    function swapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// 主池接口，定义了池的核心功能
interface IPool {
    /**
     * @notice 返回池的工厂地址
     * @return 工厂合约的地址 
     */
    function factory() external view returns (address);

    /**
     * @notice 返回池中 token0 的地址
     * @return token0 的合约地址
     */
    function token0() external view returns (address);

    /**
     * @notice 返回池中 token1 的地址
     * @return token1 的合约地址
     */
    function token1() external view returns (address);

    /**
     * @notice 返回池的手续费率
     * @return 手续费率，以百万分比表示（例如 3000 表示 0.3%）
     */
    function fee() external view returns (uint24);

    /**
     * @notice 返回池的最低 tick 值
     * @return 最低 tick 值
     */
    function tickLower() external view returns (int24);

    /**
     * @notice 返回池的最高 tick 值
     * @return 最高 tick 值
     */
    function tickUpper() external view returns (int24);

    /**
     * @notice 返回当前池的平方根价格，表示为 Q64.96 格式
     * @return 当前池的平方根价格
     */
    function sqrtPriceX96() external view returns (uint160);

    /**
     * @notice 返回当前池的 tick 值
     * @return 当前 tick 值
     */
    function tick() external view returns (int24);

    /**
     * @notice 返回当前池的流动性总量
     * @return 当前流动性总量
     */
    function liquidity() external view returns (uint128);

    /**
     * @notice 初始化池的价格
     * @param sqrtPriceX96 初始的平方根价格，表示为 Q64.96 格式
     */
    function initialize(uint160 sqrtPriceX96) external;

    /**
     * @notice 返回 token0 的全局手续费增长量，以 Q128.128 格式表示
     * @dev 记录从池创建到现在，每单位流动性累计产生的 token0 的手续费
     * @return 全局手续费增长量
     */
    function feeGrowthGlobal0X128() external view returns (uint256);

    /**
     * @notice 返回 token1 的全局手续费增长量，以 Q128.128 格式表示
     * @dev 记录从池创建到现在，每单位流动性累计产生的 token1 的手续费
     * @return 全局手续费增长量
     */
    function feeGrowthGlobal1X128() external view returns (uint256);

    /**
     * @notice 获取指定地址的流动性头寸信息
     * @param owner 流动性头寸的所有者地址
     * @return _liquidity 流动性数量
     * @return feeGrowthInside0LastX128 token0 的最后一次手续费增长量
     * @return feeGrowthInside1LastX128 token1 的最后一次手续费增长量
     * @return tokensOwed0 欠的 token0 数量
     * @return tokensOwed1 欠的 token1 数量
     */
    function getPosition(
        address owner
    )
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /**
     * @notice 铸造流动性事件
     * @param sender 调用者地址
     * @param owner 流动性接收者地址
     * @param amount 铸造的流动性数量
     * @param amount0 铸造时需要的 token0 数量
     * @param amount1 铸造时需要的 token1 数量
     */
    event Mint(
        address sender,
        address indexed owner,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice 铸造流动性
     * @param recipient 流动性接收者地址
     * @param amount 铸造的流动性数量
     * @param data 附加数据，通常用于传递上下文信息
     * @return amount0 铸造时需要的 token0 数量
     * @return amount1 铸造时需要的 token1 数量
     */
    function mint(
        address recipient,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /**
     * @notice 收集手续费事件
     * @param owner 流动性头寸的所有者地址
     * @param recipient 收集手续费的接收者地址
     * @param amount0 收集的 token0 数量
     * @param amount1 收集的 token1 数量
     */
    event Collect(
        address indexed owner,
        address recipient,
        uint128 amount0,
        uint128 amount1
    );

    /**
     * @notice 收集手续费
     * @param recipient 收集手续费的接收者地址
     * @param amount0Requested 请求收集的 token0 数量
     * @param amount1Requested 请求收集的 token1 数量
     * @return amount0 实际收集的 token0 数量
     * @return amount1 实际收集的 token1 数量
     */
    function collect(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /**
     * @notice 销毁流动性事件
     * @param owner 流动性头寸的所有者地址
     * @param amount 销毁的流动性数量
     * @param amount0 销毁时释放的 token0 数量
     * @param amount1 销毁时释放的 token1 数量
     */
    event Burn(
        address indexed owner,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice 销毁流动性
     * @param amount 销毁的流动性数量
     * @return amount0 销毁时释放的 token0 数量
     * @return amount1 销毁时释放的 token1 数量
     */
    function burn(
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /**
     * @notice 交换事件
     * @param sender 调用者地址
     * @param recipient 交换的接收者地址
     * @param amount0 交换的 token0 数量
     * @param amount1 交换的 token1 数量
     * @param sqrtPriceX96 交换后的平方根价格
     * @param liquidity 当前流动性
     * @param tick 当前 tick 值
     */
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /**
     * @notice 执行交换
     * @param recipient 交换的接收者地址
     * @param zeroForOne 交换方向，true 表示 token0 换 token1，false 表示 token1 换 token0
     * @param amountSpecified 交换的数量，正数表示输入，负数表示输出
     * @param sqrtPriceLimitX96 价格限制，表示为 Q64.96 格式
     * @param data 附加数据，通常用于传递上下文信息
     * @return amount0 交换的 token0 数量
     * @return amount1 交换的 token1 数量
     */
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}
