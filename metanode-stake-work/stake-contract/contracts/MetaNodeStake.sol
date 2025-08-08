// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 引入OpenZeppelin的ERC20接口和安全库
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// 引入可升级、权限控制、可暂停等合约
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title MetaNodeStake
 * @dev 多池质押合约，支持ETH和ERC20代币质押，按区块奖励分配MetaNode代币，支持升级、权限控制和可暂停。
 */
contract MetaNodeStake is
    Initializable,              // 可升级合约初始化接口
    UUPSUpgradeable,            // UUPS升级模式
    PausableUpgradeable,        // 可暂停功能
    AccessControlUpgradeable    // 角色权限控制
{
    using SafeERC20 for IERC20;    // 安全ERC20操作
    using Address for address;     // 地址工具
    using Math for uint256;        // 安全数学运算

    // ************************************** INVARIANT **************************************

    // 管理员角色常量
    bytes32 public constant ADMIN_ROLE = keccak256("admin_role");
    // 升级角色常量
    bytes32 public constant UPGRADE_ROLE = keccak256("upgrade_role");

    // ETH池的ID，默认为0 这个池子专门是给 native token
    uint256 public constant ETH_PID = 0;
    
    // ************************************** DATA STRUCTURE **************************************
    /*
    质押奖励分配核心公式：
    任意时刻，用户待分配的MetaNode数量为：
    pending MetaNode = (user.stAmount * pool.accMetaNodePerST) - user.finishedMetaNode

    当用户存入或提取质押时，流程如下：
    1. 更新池的accMetaNodePerST和lastRewardBlock
    2. 结算并发放用户待领取的MetaNode奖励
    3. 更新用户的stAmount（质押数量）
    4. 更新用户的finishedMetaNode（已领取奖励）
    */
    struct Pool {
        // 质押代币的地址（ETH为0x0，表示ETH池）
        address stTokenAddress;
        // 池的权重，用于决定奖励分配比例
        uint256 poolWeight;
        // 上次分配奖励的区块号，收益结算的区块高度
        uint256 lastRewardBlock;
        // 每个质押代币累计的MetaNode奖励数量
        uint256 accMetaNodePerST;
        // 当前池中质押代币的总数量
        uint256 stTokenAmount;
        // 最小质押数量限制
        uint256 minDepositAmount;
        // 提现锁定的区块数量
        uint256 unstakeLockedBlocks;
    }

    // 用户的提现请求结构体
    struct UnstakeRequest {
        // 用户请求提现的数量
        uint256 amount;
        // 请求的提现数量可以解锁的区块号
        uint256 unlockBlocks;
    }

    struct User {
        // 用户已质押的代币数量（当前锁定在池中）
        uint256 stAmount;
        // 用户已领取的MetaNode奖励总量
        uint256 finishedMetaNode;
        // 用户当前可领取的MetaNode奖励数量
        uint256 pendingMetaNode;
        // 用户的提现请求列表
        UnstakeRequest[] requests;
    }

    // ************************************** STATE VARIABLES **************************************
    // 合约开始运行的区块号
    uint256 public startBlock;
    // 合约结束运行的区块号
    uint256 public endBlock;
    // 每个区块分配的MetaNode奖励数量
    uint256 public MetaNodePerBlock;

    // 提现功能是否暂停
    bool public withdrawPaused;
    // 领取奖励功能是否暂停
    bool public claimPaused;

    // MetaNode代币的合约实例
    IERC20 public MetaNode;

    // 所有池的总权重（用于奖励分配）
    uint256 public totalPoolWeight;
    // 所有池的数组
    Pool[] public pool;

    // 用户信息的映射，按池ID和用户地址存储
    mapping (uint256 => mapping (address => User)) public user;

    // ************************************** EVENT **************************************

    event SetMetaNode(IERC20 indexed MetaNode); // 设置MetaNode代币事件，记录MetaNode代币的地址

    event PauseWithdraw(); // 暂停提现功能事件

    event UnpauseWithdraw(); // 恢复提现功能事件

    event PauseClaim(); // 暂停领取奖励功能事件

    event UnpauseClaim(); // 恢复领取奖励功能事件

    event SetStartBlock(uint256 indexed startBlock); // 设置开始区块事件，记录新的开始区块号

    event SetEndBlock(uint256 indexed endBlock); // 设置结束区块事件，记录新的结束区块号

    event SetMetaNodePerBlock(uint256 indexed MetaNodePerBlock); // 设置每区块MetaNode奖励事件，记录新的奖励数量

    event AddPool(address indexed stTokenAddress, uint256 indexed poolWeight, uint256 indexed lastRewardBlock, uint256 minDepositAmount, uint256 unstakeLockedBlocks); // 添加新池事件，记录质押代币地址、池权重、上次奖励区块号、最小质押数量和提现锁定区块数

    event UpdatePoolInfo(uint256 indexed poolId, uint256 indexed minDepositAmount, uint256 indexed unstakeLockedBlocks); // 更新池信息事件，记录池ID、最小质押数量和提现锁定区块数

    event SetPoolWeight(uint256 indexed poolId, uint256 indexed poolWeight, uint256 totalPoolWeight); // 设置池权重事件，记录池ID、池权重和总权重

    event UpdatePool(uint256 indexed poolId, uint256 indexed lastRewardBlock, uint256 totalMetaNode); // 更新池奖励事件，记录池ID、上次奖励区块号和总奖励数量

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount); // 用户存入质押代币事件，记录用户地址、池ID和存入数量

    event RequestUnstake(address indexed user, uint256 indexed poolId, uint256 amount); // 用户请求提现事件，记录用户地址、池ID和请求数量

    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount, uint256 indexed blockNumber); // 用户提现事件，记录用户地址、池ID、提现数量和区块号

    event Claim(address indexed user, uint256 indexed poolId, uint256 MetaNodeReward); // 用户领取奖励事件，记录用户地址、池ID和领取的MetaNode奖励数量

    // ************************************** MODIFIER **************************************

    modifier checkPid(uint256 _pid) {
        require(_pid < pool.length, "invalid pid"); // 检查池ID是否有效，确保池ID在池数组范围内
        _; // 继续执行修饰的函数
    }

    modifier whenNotClaimPaused() {
        require(!claimPaused, "claim is paused"); // 确保领取奖励功能未暂停，如果暂停则抛出错误
        _; // 继续执行修饰的函数
    }

    modifier whenNotWithdrawPaused() {
        require(!withdrawPaused, "withdraw is paused"); // 确保提现功能未暂停，如果暂停则抛出错误
        _; // 继续执行修饰的函数
    }

    /**
     * @notice Set MetaNode token address. Set basic info when deploying.
     * @param _MetaNode MetaNode代币的合约地址
     * @param _startBlock 合约开始运行的区块号
     * @param _endBlock 合约结束运行的区块号
     * @param _MetaNodePerBlock 每个区块分配的MetaNode奖励数量
     */
    function initialize(
        IERC20 _MetaNode,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _MetaNodePerBlock
    ) public initializer {
        require(_startBlock <= _endBlock && _MetaNodePerBlock > 0, "invalid parameters"); // 确保参数有效

        __AccessControl_init(); // 初始化访问控制模块
        __UUPSUpgradeable_init(); // 初始化UUPS升级模块
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // 授予部署者默认管理员角色
        _grantRole(UPGRADE_ROLE, msg.sender); // 授予部署者升级角色
        _grantRole(ADMIN_ROLE, msg.sender); // 授予部署者管理员角色

        setMetaNode(_MetaNode); // 设置MetaNode代币地址

        startBlock = _startBlock; // 设置开始区块号
        endBlock = _endBlock; // 设置结束区块号
        MetaNodePerBlock = _MetaNodePerBlock; // 设置每区块奖励数量
    }

    /**
     * @notice 授权升级合约的内部函数
     * @param newImplementation 新的合约实现地址
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADE_ROLE) // 仅允许具有升级角色的用户调用
        override
    {

    }

    // ************************************** ADMIN FUNCTION **************************************

    /**
     * @notice 设置MetaNode代币地址，仅管理员可调用
     * @param _MetaNode MetaNode代币的合约地址
     */
    function setMetaNode(IERC20 _MetaNode) public onlyRole(ADMIN_ROLE) {
        MetaNode = _MetaNode; // 更新MetaNode代币地址

        emit SetMetaNode(MetaNode); // 触发事件，记录MetaNode地址的变更
    }

    /**
     * @notice 暂停提现功能，仅管理员可调用
     */
    function pauseWithdraw() public onlyRole(ADMIN_ROLE) {
        require(!withdrawPaused, "withdraw has been already paused"); // 确保提现功能未暂停

        withdrawPaused = true; // 设置提现功能为暂停状态

        emit PauseWithdraw(); // 触发事件，记录提现功能已暂停
    }

    /**
     * @notice 恢复提现功能，仅管理员可调用
     */
    function unpauseWithdraw() public onlyRole(ADMIN_ROLE) {
        require(withdrawPaused, "withdraw has been already unpaused"); // 确保提现功能已暂停

        withdrawPaused = false; // 设置提现功能为恢复状态

        emit UnpauseWithdraw(); // 触发事件，记录提现功能已恢复
    }

    /**
     * @notice 暂停领取奖励功能，仅管理员可调用
     */
    function pauseClaim() public onlyRole(ADMIN_ROLE) {
        require(!claimPaused, "claim has been already paused"); // 确保领取奖励功能未暂停

        claimPaused = true; // 设置领取奖励功能为暂停状态

        emit PauseClaim(); // 触发事件，记录领取奖励功能已暂停
    }

    /**
     * @notice 恢复领取奖励功能，仅管理员可调用
     */
    function unpauseClaim() public onlyRole(ADMIN_ROLE) {
        require(claimPaused, "claim has been already unpaused"); // 确保领取奖励功能已暂停

        claimPaused = false; // 设置领取奖励功能为恢复状态

        emit UnpauseClaim(); // 触发事件，记录领取奖励功能已恢复
    }

    /**
     * @notice 更新质押的开始区块号，仅管理员可调用
     * @param _startBlock 新的开始区块号
     */
    function setStartBlock(uint256 _startBlock) public onlyRole(ADMIN_ROLE) {
        require(_startBlock <= endBlock, "start block must be smaller than end block"); // 确保开始区块号小于等于结束区块号

        startBlock = _startBlock; // 更新开始区块号

        emit SetStartBlock(_startBlock); // 触发事件，记录开始区块号的变更
    }

    /**
     * @notice 更新质押的结束区块号，仅管理员可调用
     * @param _endBlock 新的结束区块号
     */
    function setEndBlock(uint256 _endBlock) public onlyRole(ADMIN_ROLE) {
        require(startBlock <= _endBlock, "start block must be smaller than end block"); // 确保开始区块号小于等于结束区块号

        endBlock = _endBlock; // 更新结束区块号

        emit SetEndBlock(_endBlock); // 触发事件，记录结束区块号的变更
    }

    /**
     * @notice 更新每区块的MetaNode奖励数量，仅管理员可调用
     * @param _MetaNodePerBlock 新的每区块奖励数量
     */
    function setMetaNodePerBlock(uint256 _MetaNodePerBlock) public onlyRole(ADMIN_ROLE) {
        require(_MetaNodePerBlock > 0, "invalid parameter"); // 确保奖励数量大于0

        MetaNodePerBlock = _MetaNodePerBlock; // 更新每区块奖励数量

        emit SetMetaNodePerBlock(_MetaNodePerBlock); // 触发事件，记录奖励数量的变更
    }

    /**
     * @notice 添加新的质押池，仅管理员可调用
     * @param _stTokenAddress 质押代币的地址
     * @param _poolWeight 池的权重
     * @param _minDepositAmount 最小质押数量
     * @param _unstakeLockedBlocks 提现锁定的区块数量
     * @param _withUpdate 是否更新所有池的奖励状态
     */
    function addPool(address _stTokenAddress, uint256 _poolWeight, uint256 _minDepositAmount, uint256 _unstakeLockedBlocks,  bool _withUpdate) public onlyRole(ADMIN_ROLE) {
        // Default the first pool to be ETH pool, so the first pool must be added with stTokenAddress = address(0x0)
        if (pool.length > 0) {
            require(_stTokenAddress != address(0x0), "invalid staking token address"); // 确保非第一个池的质押代币地址有效
        } else {
            require(_stTokenAddress == address(0x0), "invalid staking token address"); // 确保第一个池为ETH池
        }
        // allow the min deposit amount equal to 0
        //require(_minDepositAmount > 0, "invalid min deposit amount");
        require(_unstakeLockedBlocks > 0, "invalid withdraw locked blocks"); // 确保提现锁定区块数量大于0
        require(block.number < endBlock, "Already ended"); // 确保当前区块号小于结束区块号

        if (_withUpdate) {
            massUpdatePools(); // 如果需要，更新所有池的奖励状态
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock; // 确定上次奖励区块号
        totalPoolWeight = totalPoolWeight + _poolWeight; // 更新总权重

        pool.push(Pool({
            stTokenAddress: _stTokenAddress, // 设置质押代币地址
            poolWeight: _poolWeight, // 设置池权重
            lastRewardBlock: lastRewardBlock, // 设置上次奖励区块号
            accMetaNodePerST: 0, // 初始化每个质押代币累计奖励
            stTokenAmount: 0, // 初始化池中质押代币总量
            minDepositAmount: _minDepositAmount, // 设置最小质押数量
            unstakeLockedBlocks: _unstakeLockedBlocks // 设置提现锁定区块数量
        }));

        emit AddPool(_stTokenAddress, _poolWeight, lastRewardBlock, _minDepositAmount, _unstakeLockedBlocks); // 触发事件，记录新池的添加
    }

    /**
     * @notice 更新指定池的信息（最小质押数量和提现锁定区块数量），仅管理员可调用
     * @param _pid 池的ID
     * @param _minDepositAmount 新的最小质押数量
     * @param _unstakeLockedBlocks 新的提现锁定区块数量
     */
    function updatePool(uint256 _pid, uint256 _minDepositAmount, uint256 _unstakeLockedBlocks) public onlyRole(ADMIN_ROLE) checkPid(_pid) {
        pool[_pid].minDepositAmount = _minDepositAmount; // 更新最小质押数量
        pool[_pid].unstakeLockedBlocks = _unstakeLockedBlocks; // 更新提现锁定区块数量

        emit UpdatePoolInfo(_pid, _minDepositAmount, _unstakeLockedBlocks); // 触发事件，记录池信息的变更
    }

    /**
     * @notice 更新指定质押池的权重，仅限具备管理员角色的地址调用
     * @param _pid  目标池 ID
     * @param _poolWeight 新的权重值，必须大于 0
     * @param _withUpdate 是否在更新前执行 massUpdatePools 同步所有池子奖励
     */
    function setPoolWeight(
        uint256 _pid,
        uint256 _poolWeight,
        bool _withUpdate
    ) public onlyRole(ADMIN_ROLE) checkPid(_pid) {
        // 确保新的权重大于 0
        require(_poolWeight > 0, "invalid pool weight");

        // 如果需要，先批量更新所有质押池的奖励状态
        if (_withUpdate) {
            massUpdatePools();
        }

        // 调整总权重：减去旧权重，添加新权重
        totalPoolWeight = totalPoolWeight - pool[_pid].poolWeight + _poolWeight;
        // 更新指定池子的权重值
        pool[_pid].poolWeight = _poolWeight;

        // 触发事件记录本次更新操作
        emit SetPoolWeight(_pid, _poolWeight, totalPoolWeight);
    }


    // ************************************** QUERY FUNCTION **************************************

    /**
     * @notice 获取当前系统中配置的质押池数量
     * @return 池子总数
     */
    function poolLength() external view returns (uint256) {
        // 返回数组 pool 的长度
        return pool.length;
    }

    /**
     * @notice 计算从 _from 到 _to 区块期间的奖励倍数, 区间为 [_from, _to)
     * @param _from 开始区块 (包含)
     * @param _to   结束区块 (不包含)
     * @return multiplier 返回的倍数值
     */
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public view returns (uint256 multiplier) {
        // 保证起始区块不超过结束区块
        require(_from <= _to, "invalid block");
        // 如果起始区块小于活动开始块，则以 startBlock 作为起始
        if (_from < startBlock) {
            _from = startBlock;
        }
        // 如果结束区块大于活动结束块，则以 endBlock 作为结束
        if (_to > endBlock) {
            _to = endBlock;
        }
        // 再次保证起始 <= 结束
        require(_from <= _to, "end block must be greater than start block");
        // 安全计算 (_to - _from) * 每块发行量
        bool success;
        (success, multiplier) = (_to - _from).tryMul(MetaNodePerBlock);
        require(success, "multiplier overflow");
    }

    /**
     * @notice 查询用户在指定池子中截至当前区块的未领取奖励数
     * @param _pid  池子 ID
     * @param _user 用户地址
     */
    function pendingMetaNode(
        uint256 _pid,
        address _user
    ) external checkPid(_pid) view returns (uint256) {
        // 直接调用按区块号查询的通用函数，传入当前区块号
        return pendingMetaNodeByBlockNumber(_pid, _user, block.number);
    }

    /**
     * @notice 查询用户在指定区块号前的未领取奖励数
     * @param _pid         池子 ID
     * @param _user        用户地址
     * @param _blockNumber 查询到该区块号（包含）
     */
    function pendingMetaNodeByBlockNumber(
        uint256 _pid,
        address _user,
        uint256 _blockNumber
    ) public checkPid(_pid) view returns (uint256) {
        // 获取质押池信息
        Pool storage pool_ = pool[_pid];
        // 获取用户质押信息
        User storage user_ = user[_pid][_user];
        // 已累积的单位质押 токен 的奖励
        uint256 accMetaNodePerST = pool_.accMetaNodePerST;
        // 当前池中已质押的 токен 总量
        uint256 stSupply = pool_.stTokenAmount;

        // 如果目标区块比上次分配区块大，且池子有质押
        if (_blockNumber > pool_.lastRewardBlock && stSupply != 0) {
            // 计算区块区间奖励倍数
            uint256 multiplier = getMultiplier(pool_.lastRewardBlock, _blockNumber);
            // 计算本池在该周期应发放的总代币量
            uint256 MetaNodeForPool = multiplier * pool_.poolWeight / totalPoolWeight;
            // 更新累积单位奖励，乘以 1e18 做精度缩放
            accMetaNodePerST = accMetaNodePerST + (MetaNodeForPool * 1 ether) / stSupply;
        }

        // 计算用户可领取奖励：已质押量 * 累积单位奖励 - 已领取 + 存量待领取
        return (user_.stAmount * accMetaNodePerST) / 1 ether
               - user_.finishedMetaNode
               + user_.pendingMetaNode;
    }

    /**
     * @notice 查询用户在指定池子的质押余额
     * @param _pid  池子 ID
     * @param _user 用户地址
     */
    function stakingBalance(
        uint256 _pid,
        address _user
    ) external checkPid(_pid) view returns (uint256) {
        // 返回该用户的已质押量
        return user[_pid][_user].stAmount;
    }

    /**
     * @notice 查询用户在指定池子的所有提现请求总额及已解锁可提现金额
     * @param _pid  池子 ID
     * @param _user 用户地址
     * @return requestAmount      累计发起提现的数量
     * @return pendingWithdrawAmount 已解锁可提取数量
     */
    function withdrawAmount(
        uint256 _pid,
        address _user
    ) public checkPid(_pid) view returns (
        uint256 requestAmount,
        uint256 pendingWithdrawAmount
    ) {
        // 获取用户的提现请求列表
        User storage user_ = user[_pid][_user];

        // 遍历每个提现请求
        for (uint256 i = 0; i < user_.requests.length; i++) {
            // 如果请求达到或超过解锁区块，则累加到可提取金额
            if (user_.requests[i].unlockBlocks <= block.number) {
                pendingWithdrawAmount += user_.requests[i].amount;
            }
            // 累加总请求数量
            requestAmount += user_.requests[i].amount;
        }
    }

    // ************************************** PUBLIC FUNCTION **************************************

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @param _pid 池的ID
     */
    function updatePool(uint256 _pid) public checkPid(_pid) {
        Pool storage pool_ = pool[_pid]; // 获取指定池的存储引用

        // 如果当前区块号小于等于上次奖励分配区块，则无需更新
        if (block.number <= pool_.lastRewardBlock) {
            return;
        }

        // 计算从上次奖励分配到当前区块的总奖励（区块数*每区块奖励*池权重）
        (bool success1, uint256 totalMetaNode) = getMultiplier(pool_.lastRewardBlock, block.number).tryMul(pool_.poolWeight);
        require(success1, "overflow"); // 检查乘法溢出

        // 按总权重分摊到该池的实际奖励
        (success1, totalMetaNode) = totalMetaNode.tryDiv(totalPoolWeight);
        require(success1, "overflow"); // 检查除法溢出

        uint256 stSupply = pool_.stTokenAmount; // 当前池的总质押数量
        if (stSupply > 0) {
            // 将奖励精度提升到1e18，便于后续分配
            (bool success2, uint256 totalMetaNode_) = totalMetaNode.tryMul(1 ether);
            require(success2, "overflow");

            // 平均分配到每个质押代币上，得到每个代币新增的奖励
            (success2, totalMetaNode_) = totalMetaNode_.tryDiv(stSupply);
            require(success2, "overflow");

            // 累加到池的accMetaNodePerST（每个质押代币累计可获得的MetaNode数量）
            (bool success3, uint256 accMetaNodePerST) = pool_.accMetaNodePerST.tryAdd(totalMetaNode_);
            require(success3, "overflow");
            pool_.accMetaNodePerST = accMetaNodePerST;
        }

        // 更新池的lastRewardBlock为当前区块
        pool_.lastRewardBlock = block.number;

        // 触发事件，记录本次池奖励更新
        emit UpdatePool(_pid, pool_.lastRewardBlock, totalMetaNode);
    }

    /**
     * @notice Update reward variables for all pools. Be careful of gas spending!
     */
    function massUpdatePools() public {
        uint256 length = pool.length; // 获取池的总数
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid); // 依次更新每个池的奖励状态（注意：池数量多时gas消耗大）
        }
    }

    /**
     * @notice Deposit staking ETH for MetaNode rewards
     */
    function depositETH() public whenNotPaused() payable {
        Pool storage pool_ = pool[ETH_PID]; // 获取ETH池的存储引用
        require(pool_.stTokenAddress == address(0x0), "invalid staking token address"); // 确保ETH池的地址有效

        uint256 _amount = msg.value; // 获取用户存入的ETH数量
        require(_amount >= pool_.minDepositAmount, "deposit amount is too small"); // 确保存入数量大于最小质押数量

        _deposit(ETH_PID, _amount); // 调用内部函数完成存入操作
    }

    /**
     * @notice Deposit staking token for MetaNode rewards
     * Before depositing, user needs approve this contract to be able to spend or transfer their staking tokens
     * @param _pid 池的ID
     * @param _amount 存入的质押代币数量
     */
    function deposit(uint256 _pid, uint256 _amount) public whenNotPaused() checkPid(_pid) {
        require(_pid != 0, "deposit not support ETH staking"); // 确保不是ETH池
        Pool storage pool_ = pool[_pid]; // 获取指定池的存储引用
        require(_amount > pool_.minDepositAmount, "deposit amount is too small"); // 确保存入数量大于最小质押数量

        if(_amount > 0) {
            IERC20(pool_.stTokenAddress).safeTransferFrom(msg.sender, address(this), _amount); // 转移用户的质押代币到合约
        }

        _deposit(_pid, _amount); // 调用内部函数完成存入操作
    }

    /**
     * @notice Internal function to handle deposit logic
     * @param _pid 池的ID
     * @param _amount 存入的质押代币数量
     */
    function _deposit(uint256 _pid, uint256 _amount) internal {
        Pool storage pool_ = pool[_pid]; // 获取指定池的存储引用
        User storage user_ = user[_pid][msg.sender]; // 获取用户的存储引用

        updatePool(_pid); // 更新池的奖励状态

        if (user_.stAmount > 0) {
            // 计算用户待领取的奖励并更新
            (bool success1, uint256 accST) = user_.stAmount.tryMul(pool_.accMetaNodePerST);
            require(success1, "user stAmount mul accMetaNodePerST overflow");
            (success1, accST) = accST.tryDiv(1 ether);
            require(success1, "accST div 1 ether overflow");

            (bool success2, uint256 pendingMetaNode_) = accST.trySub(user_.finishedMetaNode);
            require(success2, "accST sub finishedMetaNode overflow");

            if(pendingMetaNode_ > 0) {
                (bool success3, uint256 _pendingMetaNode) = user_.pendingMetaNode.tryAdd(pendingMetaNode_);
                require(success3, "user pendingMetaNode overflow");
                user_.pendingMetaNode = _pendingMetaNode;
            }
        }

        if(_amount > 0) {
            (bool success4, uint256 stAmount) = user_.stAmount.tryAdd(_amount);
            require(success4, "user stAmount overflow");
            user_.stAmount = stAmount;
        }

        (bool success5, uint256 stTokenAmount) = pool_.stTokenAmount.tryAdd(_amount);
        require(success5, "pool stTokenAmount overflow");
        pool_.stTokenAmount = stTokenAmount;

        (bool success6, uint256 finishedMetaNode) = user_.stAmount.tryMul(pool_.accMetaNodePerST);
        require(success6, "user stAmount mul accMetaNodePerST overflow");

        (success6, finishedMetaNode) = finishedMetaNode.tryDiv(1 ether);
        require(success6, "finishedMetaNode div 1 ether overflow");

        user_.finishedMetaNode = finishedMetaNode; // 更新用户已领取的奖励

        emit Deposit(msg.sender, _pid, _amount); // 触发存入事件
    }

    /**
     * @notice Unstake staking tokens
     * @param _pid 池的ID
     * @param _amount 提现的质押代币数量
     */
    function unstake(uint256 _pid, uint256 _amount) public whenNotPaused() checkPid(_pid) whenNotWithdrawPaused() {
        Pool storage pool_ = pool[_pid]; // 获取指定池的存储引用
        User storage user_ = user[_pid][msg.sender]; // 获取用户的存储引用

        require(user_.stAmount >= _amount, "Not enough staking token balance"); // 确保用户的质押余额足够

        updatePool(_pid); // 更新池的奖励状态

        // 计算用户待领取的奖励
        uint256 pendingMetaNode_ = user_.stAmount * pool_.accMetaNodePerST / (1 ether) - user_.finishedMetaNode;

        if(pendingMetaNode_ > 0) {
            user_.pendingMetaNode = user_.pendingMetaNode + pendingMetaNode_; // 更新用户的待领取奖励
        }

        if(_amount > 0) {
            user_.stAmount = user_.stAmount - _amount; // 减少用户的质押余额
            user_.requests.push(UnstakeRequest({
                amount: _amount, // 设置提现请求的数量
                unlockBlocks: block.number + pool_.unstakeLockedBlocks // 设置提现解锁的区块号
            }));
        }

        pool_.stTokenAmount = pool_.stTokenAmount - _amount; // 减少池中的质押代币总量
        user_.finishedMetaNode = user_.stAmount * pool_.accMetaNodePerST / (1 ether); // 更新用户已领取的奖励

        emit RequestUnstake(msg.sender, _pid, _amount); // 触发提现请求事件
    }

    /**
     * @notice Withdraw the unlock unstake amount
     * @param _pid 池的ID
     */
    function withdraw(uint256 _pid) public whenNotPaused() checkPid(_pid) whenNotWithdrawPaused() {
        Pool storage pool_ = pool[_pid]; // 获取指定池的存储引用
        User storage user_ = user[_pid][msg.sender]; // 获取用户的存储引用

        uint256 pendingWithdraw_; // 待提现的总数量
        uint256 popNum_; // 需要移除的请求数量
        for (uint256 i = 0; i < user_.requests.length; i++) {
            if (user_.requests[i].unlockBlocks > block.number) {
                break; // 如果请求未解锁，停止循环
            }
            pendingWithdraw_ = pendingWithdraw_ + user_.requests[i].amount; // 累加已解锁的提现数量
            popNum_++; // 增加需要移除的请求计数
        }

        for (uint256 i = 0; i < user_.requests.length - popNum_; i++) {
            user_.requests[i] = user_.requests[i + popNum_]; // 移动未解锁的请求到数组前面
        }

        for (uint256 i = 0; i < popNum_; i++) {
            user_.requests.pop(); // 移除已处理的请求
        }

        if (pendingWithdraw_ > 0) {
            if (pool_.stTokenAddress == address(0x0)) {
                _safeETHTransfer(msg.sender, pendingWithdraw_); // 安全转账ETH
            } else {
                IERC20(pool_.stTokenAddress).safeTransfer(msg.sender, pendingWithdraw_); // 安全转账ERC20代币
            }
        }

        emit Withdraw(msg.sender, _pid, pendingWithdraw_, block.number); // 触发提现事件
    }

    /**
     * @notice Claim MetaNode tokens reward
     * @param _pid 池的ID
     */
    function claim(uint256 _pid) public whenNotPaused() checkPid(_pid) whenNotClaimPaused() {
        Pool storage pool_ = pool[_pid]; // 获取指定池的存储引用
        User storage user_ = user[_pid][msg.sender]; // 获取用户的存储引用

        updatePool(_pid); // 更新池的奖励状态

        // 计算用户待领取的奖励
        uint256 pendingMetaNode_ = user_.stAmount * pool_.accMetaNodePerST / (1 ether) - user_.finishedMetaNode + user_.pendingMetaNode;

        if(pendingMetaNode_ > 0) {
            user_.pendingMetaNode = 0; // 清空用户的待领取奖励
            _safeMetaNodeTransfer(msg.sender, pendingMetaNode_); // 安全转账MetaNode奖励
        }

        user_.finishedMetaNode = user_.stAmount * pool_.accMetaNodePerST / (1 ether); // 更新用户已领取的奖励

        emit Claim(msg.sender, _pid, pendingMetaNode_); // 触发领取奖励事件
    }

    /**
     * @notice Safe MetaNode transfer function, just in case if rounding error causes pool to not have enough MetaNodes
     * @param _to 接收MetaNode的地址
     * @param _amount 转账的MetaNode数量
     */
    function _safeMetaNodeTransfer(address _to, uint256 _amount) internal {
        uint256 MetaNodeBal = MetaNode.balanceOf(address(this)); // 获取合约中MetaNode的余额

        if (_amount > MetaNodeBal) {
            MetaNode.transfer(_to, MetaNodeBal); // 如果余额不足，转账所有余额
        } else {
            MetaNode.transfer(_to, _amount); // 否则转账指定数量
        }
    }

    /**
     * @notice Safe ETH transfer function
     * @param _to 接收ETH的地址
     * @param _amount 转账的ETH数量
     */
    function _safeETHTransfer(address _to, uint256 _amount) internal {
        (bool success, bytes memory data) = address(_to).call{
            value: _amount
        }(""); // 调用转账方法

        require(success, "ETH transfer call failed"); // 确保转账成功
        if (data.length > 0) {
            require(
                abi.decode(data, (bool)), // 解码返回值，确保操作成功
                "ETH transfer operation did not succeed"
            );
        }
    }
}