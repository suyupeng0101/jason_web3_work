// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";                         

contract SimpleImageNFT is ERC721URIStorage, Ownable {
    // 私有变量：下一个要铸造的 Token ID         
    uint256 private _nextTokenId;                                 

    /// @param name_   NFT 的名称
    /// @param symbol_ NFT 的符号
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)      // 初始化 ERC721 实例，设置名称和符号
        Ownable(msg.sender)         // 初始化 Ownable，将部署者设置为合约拥有者
    {
        // 不在此铸造任何 Token
    }

    /// @notice 铸造新的 NFT，并关联 metadata URI
    /// @param to 接收者地址
    /// @param tokenURI_ 指向 IPFS 上 JSON 元数据的完整 URL
    function mintNFT(address to, string calldata tokenURI_) external onlyOwner {
        // 取当前 Token ID
        uint256 tokenId = _nextTokenId;                            
        _nextTokenId += 1;                                         
        // 安全铸造 NFT
        _safeMint(to, tokenId);
        // 设置 Token 对应的 metadata URI                                   
        _setTokenURI(tokenId, tokenURI_);                         
    }
}