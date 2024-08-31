import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    // for testnet
    'lisk-sepolia': {
      url: "https://rpc.sepolia-api.lisk.com/",
      accounts: [process.env.WALLET_KEY as string],
      gasPrice: 1000000000,
    }
  }
};

export default config;
