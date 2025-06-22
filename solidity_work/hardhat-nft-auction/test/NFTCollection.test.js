const { expect } = require('chai');
const { ethers, upgrades } = require('hardhat');

describe('NFTCollection', function () {
  let NFT, nft, owner, addr1;

  beforeEach(async () => {
    [owner, addr1] = await ethers.getSigners();
    NFT = await ethers.getContractFactory('NFTCollection');
    nft = await NFT.deploy('TestNFT', 'TNFT');
    await nft.deployed();
  });

  it('owner should mint and assign token', async () => {
    await expect(nft.connect(owner).mint(addr1.address))
      .to.emit(nft, 'Transfer')
      .withArgs(ethers.constants.AddressZero, addr1.address, 0);
    expect(await nft.balanceOf(addr1.address)).to.equal(1);
  });

  it('non-owner cannot mint', async () => {
    await expect(nft.connect(addr1).mint(addr1.address))
      .to.be.revertedWith('Ownable: caller is not the owner');
  });
});