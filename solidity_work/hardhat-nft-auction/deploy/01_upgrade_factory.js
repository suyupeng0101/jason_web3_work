module.exports = async ({ getNamedAccounts, deployments, ethers, upgrades }) => {
  const { deployer } = await getNamedAccounts();
  const factoryAddress = (await deployments.get('AuctionFactory')).address;

  const FactoryV2 = await ethers.getContractFactory('AuctionFactoryV2');
  await upgrades.upgradeProxy(factoryAddress, FactoryV2);
  console.log('Factory upgraded');
};
module.exports.tags = ['FactoryUpgrade'];