const { expect } = require('chai');
const { ethers, upgrades, deployments } = require('hardhat');

describe('AuctionFactory', function () {
  let factory, owner;

  beforeEach(async () => {
    await deployments.fixture(['Factory']);
    const { deployer } = await getNamedAccounts();
    owner = await ethers.getSigner(deployer);
    factory = await ethers.getContract('AuctionFactory');
  });

  it('should create a new auction proxy', async () => {
    const NFT = await ethers.getContractFactory('NFTCollection');
    const nft = await NFT.deploy('FacNFT', 'FNFT');
    await nft.deployed();
    await nft.mint(owner.address);
    await nft.approve(factory.address, 0);

    // 创建拍卖
    await factory.createAuction(
      nft.address,
      0,
      ethers.constants.AddressZero,
      ethers.constants.AddressZero,
      ethers.constants.AddressZero,
      3600
    );

    const auctions = await factory.auctions(0);
    expect(auctions).to.properAddress;
  });
});