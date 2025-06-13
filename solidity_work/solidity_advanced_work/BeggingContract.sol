// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// 作业3：编写一个讨饭合约
// 任务目标
// 使用 Solidity 编写一个合约，允许用户向合约地址发送以太币。
// 记录每个捐赠者的地址和捐赠金额。
// 允许合约所有者提取所有捐赠的资金。

contract BeggingContract{

    // 合约拥有者
    address public owner;

    // 部署合约时设置拥有者
    constructor(){
        owner = msg.sender;
    }

    // 捐赠事件
    event Donation(address indexed donor, uint256 amount); 



    // 一个 mapping 来记录每个捐赠者的捐赠金额。
    mapping(address => uint256) private donations;


    // 一个 donate 函数，允许用户向合约发送以太币，并记录捐赠信息。
    function donate(uint256 amount) external payable {
        require(amount > 0, "Donation must be positive");
        donations[msg.sender] += amount;
        emit Donation(msg.sender, amount);
    }


    // 一个 withdraw 函数，允许合约所有者提取所有资金。
    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable (owner).transfer(balance);
    }

    // 一个 getDonation 函数，允许查询某个地址的捐赠金额。
    function getDonation (address donor) external view returns(uint256){
        return donations[donor];
    }

}