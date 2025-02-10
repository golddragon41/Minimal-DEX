import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ignition";
import dotenv from "dotenv";

dotenv.config();

const accounts = [process.env.PRIVATE_KEY ?? ''];

const config: HardhatUserConfig = {
  solidity: "0.8.28",

  networks: {
    hardhat: {
      chainId: 31337
    },
    sepoliaTestnet: {
      url: 'https://sepolia.gateway.tenderly.co',
      chainId: 11155111,
      accounts,
    },
  },
  etherscan: {
    apiKey: {
      sepolia: "DE2RFURK3FQCGYQNB85MCI5MKCCCFV73P2"
    }
  }
};

export default config;
