// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;




// 作业 1：ERC20 代币
// 任务：参考 openzeppelin-contracts/contracts/token/ERC20/IERC20.sol实现一个简单的 ERC20 代币合约。要求：
// 合约包含以下标准 ERC20 功能：
// balanceOf：查询账户余额。
// transfer：转账。
// approve 和 transferFrom：授权和代扣转账。
// 使用 event 记录转账和授权操作。
// 提供 mint 函数，允许合约所有者增发代币。
// 提示：
// 使用 mapping 存储账户余额和授权信息。
// 使用 event 定义 Transfer 和 Approval 事件。
// 部署到sepolia 测试网，导入到自己的钱包


contract MyERC20Contract {

    // 代币名称
    string private name;
    // 代币简称
    string private symbol;
    // 小数位数
    uint8 public decimals;
    // 代币总量
    uint256 private _totalSupply; 

    // 合约拥有者地址
    address public owner;


    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 initialSupply
    ) {                                                          // 构造函数，部署时初始化
        name = _name;                                            // 设置代币名称
        symbol = _symbol;                                        // 设置代币符号
        decimals = _decimals;                                    // 设置小数位数
        owner = msg.sender;                                      // 将部署者设为合约拥有者
        _mint(msg.sender, initialSupply);                        // 铸造初始代币到拥有者地址
    }
    
    // 账户余额映射
    mapping(address => uint256) private _balances;

    // 授权额度映射
    mapping(address => mapping(address => uint256)) private _allowances;


    // 检查调用者是否为拥有者
    modifier onlyOwner() {                                        
        require(msg.sender == owner, "Only owner can call");   
        _;                                                        
    }

    // 转账事件
    event Transfer(address indexed from, address indexed to, uint256 value);  
    // 授权事件
    event Approval(address indexed owner, address indexed spender, uint256 value); 

    // 返回代币总量
    function totalSupply() external view returns (uint256){
        return _totalSupply; 
    }


    // 账户余额
    function balanceOf(address account) external view returns (uint256){
        return _balances[account];
    }


    // 转账
    function transfer(address to, uint256 amount) external returns (bool){
        // 调用内部转账逻辑
        _transfer(msg.sender, to, amount);                       
        return true;   
    }




    // 返回授权额度
    function allowance(address _owner, address spender) external view  returns (uint256) {
        return _allowances[_owner][spender];                    
    }


    // 调用内部授权逻辑
    function approve(address spender, uint256 amount) external  returns (bool) {
        _approve(msg.sender, spender, amount);                  
        return true;                                             
    }

    // 铸币函数，仅拥有者可调用
    function mint(address to, uint256 amount) external onlyOwner { 
        // 调用内部铸币逻辑
        _mint(to, amount);                                       
    }


    // 授权转账
    function transferFrom(address from, address to, uint256 amount) external returns(bool){
        // 获取当前授权额度
        uint256 currentAllowance = _allowances[from][msg.sender]; 
        // 检查额度
        require(currentAllowance >= amount, "transfer amount exceeds allowance"); 
        // 扣减授权额度
        _approve(from, msg.sender, currentAllowance - amount);
        // 执行转账
        _transfer(from, to, amount);
        return true;
    }



    // 内部铸币实现
    function _mint(address account, uint256 amount) internal {
        // 非零地址检查
        require(account != address(0), "ERC20: mint to zero address");
        // 增加总供应量
        _totalSupply += amount;
        // 增加接收者余额
        _balances[account] += amount;
        // 触发铸币事件
        emit Transfer(address(0), account, amount);
    }

    // 内部转账实现
    function _transfer(address from, address to, uint256 amount) internal {
        // 非零地址检查
        require(from != address(0), "transfer from zero address");
        require(to != address(0), "transfer from zero address");

        // 发起者余额获取
        uint256 fromBalance = _balances[from];

        // 余额检查
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        // 扣减发起者余额
        _balances[from] = fromBalance - amount;
        // 增加接收者余额
        _balances[to] += amount;

        //触发转账事件
        emit Transfer(from, to, amount);
    }

    // 内部授权实现
    function _approve (address _owner, address spender, uint256 amount) internal {
        // 非零地址检查
        require(_owner != address(0), "approve from zero address");
        require(spender != address(0), "approve to zero address");
        // 设置授权额度
        _allowances[_owner][spender] = amount;
        // 授权事件触发
        emit Approval(_owner, spender, amount); 
    }


}

