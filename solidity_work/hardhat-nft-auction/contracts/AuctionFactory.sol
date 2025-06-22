// SPDX-License-Identifier: MIT                                                         // 授权协议声明
pragma solidity ^0.8.20;                                                                // 指定 Solidity 版本

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";         // UUPS 升级工具
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";           // 可升级版权限管理
import "./Auction.sol";                                                               // 引入 Auction 合约

/// @title AuctionFactory
/// @notice 管理拍卖合约的创建与升级
contract AuctionFactory is UUPSUpgradeable, OwnableUpgradeable {
    address[] public auctions; // 存储所有拍卖实例地址
    event AuctionCreated(address auction); // 新拍卖创建事件

    /// @notice 初始化工厂合约
    function initialize() external initializer {
        __Ownable_init();          // 初始化权限管理
        __UUPSUpgradeable_init();   // 初始化 UUPS 升级功能
    }

    /// @notice 创建新的 Auction 实例代理
    function createAuction(
        address nft,
        uint256 tokenId,
        address bidToken,
        address feedETHUSD,
        address feedERC20USD,
        uint256 duration
    ) external {
        // 部署 Auction 实现并创建 UUPS 代理
        address proxy = address(
            new TransparentUpgradeableProxy(
                address(new Auction()),    // Auction 实现合约地址
                address(this),              // 代理管理员设为本工厂
                abi.encodeWithSelector(
                    Auction.initialize.selector, // 调用 initialize
                    nft,
                    tokenId,
                    bidToken,
                    feedETHUSD,
                    feedERC20USD,
                    duration
                )
            )
        );
        auctions.push(proxy);         // 记录代理地址
        emit AuctionCreated(proxy);   // 触发事件
    }

    /// @dev 升级授权，仅限拥有者
    function _authorizeUpgrade(address) internal override onlyOwner {}
}