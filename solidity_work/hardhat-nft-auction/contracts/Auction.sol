// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";



contract Auction is UUPSUpgradeable, OwnableUpgradeable {

    IERC721 public nft;                      // 拍卖的 NFT 合约实例
    uint256 public tokenId;                  // 拍卖的 NFT tokenId
    address public seller;                   // 卖家地址
    uint256 public endTime;                  // 拍卖结束时间戳

    address public highestBidder;            // 当前最高出价者
    uint256 public highestBid;               // 当前最高出价（以美元计价）
    IERC20 public bidToken;                  // 可选 ERC20 出价代币

    AggregatorV3Interface public priceFeedETHUSD;    // ETH/USD 预言机
    AggregatorV3Interface public priceFeedERC20USD; // ERC20/USD 预言机

    mapping(address => uint256) public bids; // 存储各地址出价原始金额

    event BidPlaced(address bidder, uint256 amount, bool isETH);  // 出价事件
    event AuctionEnded(address winner, uint256 winningBid);       // 拍卖结束事件


        /// @notice 初始化拍卖合约
    /// @param _nft NFT 合约地址
    /// @param _tokenId 要拍卖的 NFT ID
    /// @param _bidToken ERC20 出价代币地址
    /// @param _priceFeedETHUSD ETH/USD 预言机
    /// @param _priceFeedERC20USD ERC20/USD 预言机
    /// @param duration 拍卖持续时长（秒）
    function initialize(
        address _nft,
        uint256 _tokenId,
        address _bidToken,
        address _priceFeedETHUSD,
        address _priceFeedERC20USD,
        uint256 duration
    ) public initializer {
        __Ownable_init();            // 初始化 OwnableUpgradeable
        __UUPSUpgradeable_init();     // 初始化 UUPSUpgradeable

        nft = IERC721(_nft];         // 设置 NFT 实例
        tokenId = _tokenId;           // 设置拍卖 tokenId
        seller = msg.sender;          // 卖家为初始化调用者
        bidToken = IERC20(_bidToken); // 设置 ERC20 出价代币
        priceFeedETHUSD = AggregatorV3Interface(_priceFeedETHUSD);    // 链接 ETH 预言机
        priceFeedERC20USD = AggregatorV3Interface(_priceFeedERC20USD);// 链接 ERC20 预言机
        endTime = block.timestamp + duration; // 计算结束时间
        nft.transferFrom(msg.sender, address(this), tokenId); // 将 NFT 转入合约托管
    }

    modifier onlyBeforeEnd() { require(block.timestamp < endTime, "Auction ended"); _; } // 出价前置条件
    modifier onlyAfterEnd()  { require(block.timestamp >= endTime, "Auction not ended"); _; } // 结束前不可结算

    /// @notice 获取 Chainlink 最新价格（8 位精度）
    function getLatestPrice(AggregatorV3Interface feed) internal view returns (uint256) {
        (, int price,,,) = feed.latestRoundData();
        return uint256(price);    // 返回 uint256 类型价格
    }

    /// @notice 用户出价
    /// @param amount   ERC20 出价时的金额，ETH 出价忽略
    /// @param isETH    是否使用 ETH 出价
    function placeBid(uint256 amount, bool isETH) external payable onlyBeforeEnd {
        uint256 bidValueUSD;
        if (isETH) {
            require(msg.value > 0, "ETH bid must >0");
            bidValueUSD = (msg.value * getLatestPrice(priceFeedETHUSD)) / 1e8; // ETH -> USD
        } else {
            require(bidToken.transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");
            bidValueUSD = (amount * getLatestPrice(priceFeedERC20USD)) / 1e8;   // ERC20 -> USD
        }
        require(bidValueUSD > highestBid, "Bid too low");
        // 退回旧最高出价
        if (highestBidder != address(0)) {
            uint256 prev = bids[highestBidder];
            if (prev > 0) payable(highestBidder).transfer(prev);
        }
        bids[msg.sender] = isETH ? msg.value : amount; // 存储原始出价
        highestBidder = msg.sender;
        highestBid = bidValueUSD;
        emit BidPlaced(msg.sender, bidValueUSD, isETH);
    }

    /// @notice 结束拍卖并分发资产
    function endAuction() external onlyAfterEnd {
        require(msg.sender == seller, "Only seller");
        nft.transferFrom(address(this), highestBidder, tokenId); // 转 NFT 给赢家
        uint256 finalAmt = bids[highestBidder];                 // 获取赢家出价原始金额
        if (finalAmt > 0) {
            if (bidToken.balanceOf(address(this)) >= finalAmt) {
                bidToken.transfer(seller, finalAmt);          // ERC20 支付卖家
            } else {
                payable(seller).transfer(finalAmt);           // ETH 支付卖家
            }
        }
        emit AuctionEnded(highestBidder, highestBid);
    }

    /// @dev 授权升级，仅限拥有者
    function _authorizeUpgrade(address) internal override onlyOwner {}

}