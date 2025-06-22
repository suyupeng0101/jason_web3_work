// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// ERC721 合约，支持铸造
contract NFTCollection is ERC721, Ownable {

    uint256 public nextTokenId;

    constructor(string memory name_, string memory symbol_)ERC721(name_, symbol_) {
    }

    // 铸造NFT
    function mint(address to) external onlyOwner(
        _safeMint(to, nextTokenId);
        nextTokenId++;
    )
}