import { ethers } from 'hardhat';

async function main() {
    const token = "0x50b57418882e18E2Eecc4FE6A2b0041E069db76D";
  const tokenStakingApp = await ethers.deployContract('StakingApp', [token, token]);

  await tokenStakingApp.waitForDeployment();

  console.log('Token Staking Contract Deployed at ' + tokenStakingApp.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});