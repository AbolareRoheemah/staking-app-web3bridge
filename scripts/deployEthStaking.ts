import { ethers } from 'hardhat';

async function main() {
  const stakingApp = await ethers.deployContract('EthStakingApp');

  await stakingApp.waitForDeployment();

  console.log('Ether Staking Contract Deployed at ' + stakingApp.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});