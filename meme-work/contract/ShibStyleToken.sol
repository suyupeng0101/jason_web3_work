// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


// 引入 OpenZeppelin 库的 ERC20 实现、所有权管理和重入保护模块
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract ShibStyleToken is ERC20, Ownable, ReentrancyGuard  {

    // 每笔交易收取的税费百分比，初始为 5%
    uint256 public taxRate = 5; 

    // 税费汇总的地址（资金池）
    address public taxPool;

    // 单笔交易最大额度
    uint256 public maxTxAmount; 

    // 交易冷却时间，防止高频交易
    uint256 public cooldownTime = 1 hours;

    // 记录每个地址上次交易的时间戳
    mapping(address => uint256) private _lastTx;


    // ========== 构造函数 ==========
    /// @param name_  代币名称
    /// @param symbol_ 代币符号
    /// @param totalSupply_ 初始总发行量（单位最小单位）
    /// @param taxPool_ 税费接收地址
    /// @param maxTxAmt_ 单笔交易最大金额
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address taxPool_,
        uint256 maxTxAmt_
    ) ERC20(name_, symbol_) {
        // 部署者 mint 全量代币
        _mint(msg.sender, totalSupply_ ); // 初始化总发行量
        taxPool = taxPool_;
        maxTxAmount = maxTxAmt_;
    }


    // ========== 管理员函数 ==========
    // 设置交易税率（%），上限 10%
    function setTaxRate(uint256 rate) external onlyOwner {
        require(rate <= 10, "Tax too high");
        taxRate = rate;
    }

    // 设置单笔最大交易额度
    function setMaxTx(uint256 amt) external onlyOwner {
        maxTxAmount = amt;
    }

    // 设置交易冷却时间（秒）
    function setCooldown(uint256 secs) external onlyOwner {
        cooldownTime = secs;
    }

    // ========== 核心转账逻辑 ==========
        /**
     * 重写 ERC20 的 _transfer，添加税费和交易限制逻辑：
     * 1. 限制单笔交易额度
     * 2. 检查交易是否满足冷却时间
     * 3. 计算税费并转入 taxPool
     * 4. 执行剩余金额的转账
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // 限制单笔最大额度
        require(amount <= maxTxAmount, "Exceeds maxTx");
        // 冷却期检查
        require(block.timestamp - _lastTx[from] >= cooldownTime, "Cooldown");
        // 更新上次交易时间
        _lastTx[from] = block.timestamp;

        // 计算税费金额
        uint256 taxFee = amount * taxRate / 100;
        // 实际发送金额
        uint256 sendAmt = amount - taxFee;
        // 将税费部分转账到专用税费池
        super._transfer(from, taxPool, taxFee);
        // 将剩余代币转给接收者
        super._transfer(from, to, sendAmt);
    }


    // ========== 流动性管理示例 ==========
    /**
     * @notice 向指定 AMM 路由器添加流动性，合约需事先持有足够代币并发送 ETH
     * @param router UniswapV2Router02 合约地址
     * @param tokenAmt 要注入的代币数量
     * @dev 仅合约拥有者可调用
     */
    function addLiquidity(address router, uint256 tokenAmt) external payable onlyOwner {
        // 授权 Router 转移本合约的 tokenAmt 数量
        _approve(address(this), router, tokenAmt);
        // 调用路由器的 addLiquidityETH 方法，自动将 ETH 与代币组成 LP
        IUniswapV2Router02(router).addLiquidityETH{value: msg.value}(
            address(this),    // 要注入流动性的代币地址
            tokenAmt,          // 要注入的代币数量
            0,                 // 最小代币数量（滑点保护，可设置>0）
            0,                 // 最小 ETH 数量（滑点保护，可设置>0）
            owner(),           // LP 代币接收者，一般锁定或多签
            block.timestamp    // 交易截止时间
        );
    }

} 