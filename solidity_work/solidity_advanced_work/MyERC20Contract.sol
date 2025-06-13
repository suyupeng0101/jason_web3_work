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



    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    // 账户余额
    mapping (address account => uint256) private _balances;

    // 授权信息
    mapping(address account => mapping(address spender => uint256)) private _allowances;



    // 账户管理者地址
    address private owner;
    // 代币名称
    string private name;
    // 代币简称
    string private symbol;


    // 获取余额
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }


    //转账
    function transfer(address to, uint256 val)public returns(bool){
        require(msg.sender == to, "Not owner");
        (bool success, ) = payable(to).call{value: val}("");
        require(success, "Withdraw failed");
        return success;
    }



    

}

