// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ISwapRouter.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IPoolManager.sol";

/// @title SwapRouter
/// @notice 一个路由器合约示例：负责按路径在多个 Pool 上执行 swap，并提供报价（quote）能力
contract SwapRouter is ISwapRouter {
    // Pool 管理器，用于按 token pair + index 获取对应池合约地址
    IPoolManager public poolManager;

    // 构造函数：部署时注入 PoolManager 合约地址
    constructor(address _poolManager) {
        poolManager = IPoolManager(_poolManager); // 将传入地址强制转换为 IPoolManager 接口并保存
    }

    /// @dev 解析 revert 的 reason 数据，期望其包含两个 int256（报价返回的数值）
    ///      该函数用于在调用未成功时从回退数据中解析出数值（用于 Quoter 报价流程）
    function parseRevertReason(
        bytes memory reason
    ) private pure returns (int256, int256) {
        // 如果回退数据长度不是 64 字节（即两个 int256），则可能是字符串错误或其他异常
        if (reason.length != 64) {
            // 如果长度小于 68 字节，则没有标准的 Error(string) 编码，也无法解析
            if (reason.length < 68) revert("Unexpected error"); // 抛出通用错误
            // 标准 Error(string) 编码为: 4 bytes selector + abi.encode(string)
            // 为了提取 string，我们跳过前 4 字节 selector（0x08c379a0）
            assembly {
                reason := add(reason, 0x04) // 将 reason 指针向后移动 4 个字节，指向 abi.encode(string)
            }
            // 将跳过 selector 后的内容按 string 解码并 revert（以便把原始错误字符串回退出去）
            revert(abi.decode(reason, (string)));
        }
        // 如果长度恰好为 64 字节，按照 (int256, int256) 解码并返回（这是 Quoter 的约定）
        return abi.decode(reason, (int256, int256));
    }

    /// @notice 在指定的池子上执行一次 swap，并返回池子返回的两个 amount 值
    /// @param pool            要调用的池子实例
    /// @param recipient       兑换后接收 token 的地址
    /// @param zeroForOne      方向标志 ： true 表示 token0 -> token1，false 表示 token1 -> token0
    /// @param amountSpecified 指定的数量（正数或负数，意义见 Pool 接口）
    /// @param sqrtPriceLimitX96 价格限制参数（Uniswap V3 风格）
    /// @param data            回调时传给 pool 的 data（swapCallback 中会被解码）
    function swapInPool(
        IPool pool,
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1) {
        // 使用 try/catch 调用池的 swap，捕获回退信息以支持报价模式（Quoter）
        try
            pool.swap(
                recipient,
                zeroForOne,
                amountSpecified,
                sqrtPriceLimitX96,
                data
            )
        returns (int256 _amount0, int256 _amount1) {
            // 如果成功返回，则直接把池子返回的两个值透传出去
            return (_amount0, _amount1);
        } catch (bytes memory reason) {
            // 如果调用 pool.swap 回退，则尝试解析回退数据（也许是 Quoter 的自定义 revert 编码）
            return parseRevertReason(reason);
        }
    }

    /// @inheritdoc ISwapRouter
    /// @notice 按照指定的 exact-input 路径依次在多个 pool 上做 swap，返回最终得到的 amountOut
    function exactInput(
        ExactInputParams calldata params
    ) external payable override returns (uint256 amountOut) {
        // 记录输入 token 的数量（从 params 传入），会在循环中逐步减少
        uint256 amountIn = params.amountIn;

        // 根据 token 地址的字典序决定交换方向：tokenIn < tokenOut 表示 token0->token1
        bool zeroForOne = params.tokenIn < params.tokenOut;

        // 遍历 indexPath 数组，indexPath 指定了要使用的多个池的索引或路径片段
        for (uint256 i = 0; i < params.indexPath.length; i++) {
            // 通过 poolManager 根据 tokenIn, tokenOut 和当前索引获取对应池的地址
            address poolAddress = poolManager.getPool(
                params.tokenIn,
                params.tokenOut,
                params.indexPath[i]
            );

            // 如果没有找到池（地址为 0），则回退，表示路径中断
            require(poolAddress != address(0), "Pool not found");

            // 将地址转换为 IPool 接口
            IPool pool = IPool(poolAddress);

            // 构造传入 pool.swap 的 data，swapCallback 会解码该 data
            // data 中包含：tokenIn, tokenOut, index, payer（如果 recipient == address(0) 则 payer 为 address(0)）
            // 注意：当 recipient==address(0) 时，表示这是一次用于报价（quote）的调用，不会实际转移 token
            bytes memory data = abi.encode(
                params.tokenIn,
                params.tokenOut,
                params.indexPath[i],
                params.recipient == address(0) ? address(0) : msg.sender
            );

            // 调用本合约的 swapInPool（外部调用 this.swapInPool 会产生一次外部调用，用以捕获 pool 回退）
            (int256 amount0, int256 amount1) = this.swapInPool(
                pool,
                params.recipient,
                zeroForOne,
                int256(amountIn),
                params.sqrtPriceLimitX96,
                data
            );

            // 更新 amountIn（输入方实际消耗），以及累计的 amountOut（输出方实际获得）
            // 如果 zeroForOne == true，amount0 表示消耗的 token0（正为消耗），amount1 表示获得 token1（负为获得）
            // 所以消耗的数量为 amount0（或 amount1 取决于方向）。为保持数值为正，用 uint256 转换。
            amountIn -= uint256(zeroForOne ? amount0 : amount1); // 减去已消耗的输入
            amountOut += uint256(zeroForOne ? -amount1 : -amount0); // 增加已获得的输出

            // 如果所有输入都已经消耗完，提前退出循环
            if (amountIn == 0) {
                break;
            }
        }

        // 验证最终得到的输出不低于用户指定的最小值，避免滑点过大
        require(amountOut >= params.amountOutMinimum, "Slippage exceeded");

        // emit 事件记录本次 swap 的概要信息：发起者、方向、原始输入、剩余输入、最终输出
        emit Swap(msg.sender, zeroForOne, params.amountIn, amountIn, amountOut);

        // 返回最终的输出数量
        return amountOut;
    }

    /// @inheritdoc ISwapRouter
    /// @notice 按 exact-output 路径执行 swap，目标是获得指定数量的输出，返回消耗的输入 amountIn
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable override returns (uint256 amountIn) {
        // 记录目标输出量
        uint256 amountOut = params.amountOut;

        // 同样按照 token 地址大小关系决定 swap 方向
        bool zeroForOne = params.tokenIn < params.tokenOut;

        // 遍历路径中的每个 pool index
        for (uint256 i = 0; i < params.indexPath.length; i++) {
            // 通过 poolManager 获取池子地址
            address poolAddress = poolManager.getPool(
                params.tokenIn,
                params.tokenOut,
                params.indexPath[i]
            );

            // 池不存在则回退
            require(poolAddress != address(0), "Pool not found");

            // 转换为 IPool 接口
            IPool pool = IPool(poolAddress);

            // 构造 swapCallback 需要的 data，结构与 exactInput 相同
            bytes memory data = abi.encode(
                params.tokenIn,
                params.tokenOut,
                params.indexPath[i],
                params.recipient == address(0) ? address(0) : msg.sender
            );

            // 以负的 amountSpecified 调用 swap（exact output 模式通常以负值指定最终输出）
            (int256 amount0, int256 amount1) = this.swapInPool(
                pool,
                params.recipient,
                zeroForOne,
                -int256(amountOut),
                params.sqrtPriceLimitX96,
                data
            );

            // 更新剩余的 amountOut 目标和累计 amountIn
            // 依据方向，amount1 或 amount0 的符号和含义不同，故此处用负号和三目判断处理
            amountOut -= uint256(zeroForOne ? -amount1 : -amount0); // 减去在本池已满足的输出量
            amountIn += uint256(zeroForOne ? amount0 : amount1); // 增加为满足输出所消耗的输入量

            // 当目标输出已被完全满足时退出循环
            if (amountOut == 0) {
                break;
            }
        }

        // 最终消耗的输入不能超过用户设置的上限，超过则视为滑点或路径不优
        require(amountIn <= params.amountInMaximum, "Slippage exceeded");

        // 触发事件记录本次 exact output swap 的信息
        emit Swap(
            msg.sender,
            zeroForOne,
            params.amountOut,
            amountOut,
            amountIn
        );

        // 返回本次为获取目标输出实际消耗的输入量
        return amountIn;
    }

    /// @notice 报价接口：给定 tokenIn 的数量，返回估算能得到的 tokenOut 数量（不实际执行转账）
    /// @dev 通过调用 exactInput，但将 recipient 设置为 address(0) 以触发 Quoter 风格的回退并捕获内部计算结果
    function quoteExactInput(
        QuoteExactInputParams calldata params
    ) external override returns (uint256 amountOut) {
        // 直接调用本合约的 exactInput，并构造一个临时的 ExactInputParams
        // recipient = address(0) 表示这是一次仅用于报价的调用（不会把结果发送给真实用户）
        return
            this.exactInput(
                ExactInputParams({
                    tokenIn: params.tokenIn,
                    tokenOut: params.tokenOut,
                    indexPath: params.indexPath,
                    recipient: address(0), // 用 address(0) 标记为报价调用
                    deadline: block.timestamp + 1 hours,
                    amountIn: params.amountIn,
                    amountOutMinimum: 0, // 报价不需要最小输出限制
                    sqrtPriceLimitX96: params.sqrtPriceLimitX96
                })
            );
    }

    /// @notice 报价接口：给定想要获得的 tokenOut 数量，返回估算需要的 tokenIn 数量（不实际执行转账）
    /// @dev 同样通过 exactOutput 路径调用，并将 recipient 置为 address(0)
    function quoteExactOutput(
        QuoteExactOutputParams calldata params
    ) external override returns (uint256 amountIn) {
        return
            this.exactOutput(
                ExactOutputParams({
                    tokenIn: params.tokenIn,
                    tokenOut: params.tokenOut,
                    indexPath: params.indexPath,
                    recipient: address(0), // 报价调用
                    deadline: block.timestamp + 1 hours,
                    amountOut: params.amountOut,
                    amountInMaximum: type(uint256).max, // 设置最大输入为极大值以便计算真实消耗
                    sqrtPriceLimitX96: params.sqrtPriceLimitX96
                })
            );
    }

    /// @notice Pool 在 swap 过程中会回调到此函数，合约需要在此函数中完成 token 的支付
    /// @param amount0Delta 池子要求支付或应收取的 token0 的数量（可以为正或负，正表示合约需支付）
    /// @param amount1Delta 池子要求支付或应收取的 token1 的数量（可以为正或负）
    /// @param data          swap 时传入的 data，会在这里被解码（用于识别 payer 等信息）
    function swapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        // 解码 data 为 (tokenIn, tokenOut, index, payer)
        (address tokenIn, address tokenOut, uint32 index, address payer) = abi
            .decode(data, (address, address, uint32, address));
        // 从 poolManager 中获取对应的池子的地址（与 swap 调用时一致）
        address _pool = poolManager.getPool(tokenIn, tokenOut, index);

        // 检查当前回调调用者是不是池子合约本身，防止任意合约伪造回调
        require(_pool == msg.sender, "Invalid callback caller");

        // 计算需要支付的数量：如果 amount0Delta>0 则需要支付 amount0Delta，否则支付 amount1Delta（取正数）
        uint256 amountToPay = amount0Delta > 0
            ? uint256(amount0Delta)
            : uint256(amount1Delta);

        // 如果 payer == address(0)，说明这是一次仅用于报价的调用（Quoter 模式）
        // 此时不应该做实际转账，而是将 (amount0Delta, amount1Delta) 通过 revert 返回给上层调用方（见 Quoter 设计）
        // Quoter 的实现会捕获 revert，并解析出两个 int256 值作为报价结果
        // 参考 Uniswap V3 的 Quoter 合约实现
        if (payer == address(0)) {
            assembly {
                // 获取自由内存指针
                let ptr := mload(0x40)
                // 将 amount0Delta 写入内存 ptr（32 字节）
                mstore(ptr, amount0Delta)
                // 将 amount1Delta 写入内存 ptr + 32
                mstore(add(ptr, 0x20), amount1Delta)
                // 使用 revert 返回 64 字节（两个 int256）的数据，供上层捕获并解析
                revert(ptr, 64)
            }
        }

        // 对于正常交易场景（payer != address(0)），需要实际把 token 从 payer 转给池子
        if (amountToPay > 0) {
            // 通过 ERC20 transferFrom 将 tokenIn 从 payer 转给池合约（msg.sender == pool）
            IERC20(tokenIn).transferFrom(payer, _pool, amountToPay);
        }
    }
}
