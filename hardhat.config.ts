import { task } from "hardhat/config";

import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";

import { HardhatUserConfig /* , NetworkUserConfig */ } from "hardhat/types";

import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";

import "hardhat-gas-reporter";
import "solidity-coverage";
import "hardhat-contract-sizer";

import "@nomiclabs/hardhat-etherscan";
// import "./deployment/index";
dotenvConfig({ path: resolve(__dirname, "./.env") });

// import "./scripts/index";

// const chainIds = {
//   ganache: 1337,
//   goerli: 5,
//   hardhat: 31337,
//   kovan: 42,
//   mainnet: 1,
//   rinkeby: 4,
//   ropsten: 3,
// };

// Ensure that we have all the environment variables we need.
const DEPLOYER_PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY;
if (!DEPLOYER_PRIVATE_KEY) {
  throw new Error("Please set your private key in a .env file");
}

const INFURA_API_KEY = process.env.INFURA_API_KEY;
if (!INFURA_API_KEY) {
  throw new Error("Please set your INFURA_API_KEY in a .env file");
}

const SPEEDY_API_KEY = process.env.SPEEDY_API_KEY;
if (!SPEEDY_API_KEY) {
  throw new Error("Please set your SPEEDY_API_KEY in a .env file");
}

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
if (!ETHERSCAN_API_KEY) {
  throw new Error("Please set your ETHERSCAN_API_KEY in a .env file");
}

const BSC_API_KEY = process.env.BSC_API_KEY;
if (!BSC_API_KEY) {
  throw new Error("Please set your BSC_API_KEY in a .env file");
}

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (args, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(await account.getAddress());
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    // coverage: {
    //   url: "http://127.0.0.1:8555",
    // },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
      chainId: 1,
      accounts: [`0x${DEPLOYER_PRIVATE_KEY}`],
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
      chainId: 5,
      accounts: [`0x${DEPLOYER_PRIVATE_KEY}`],
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.13",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  paths: {
    sources: "contracts",
    artifacts: "./build/artifacts",
    cache: "./build/cache",
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
    // apiKey: BSC_API_KEY,
    // Source: https://hardhat.org/plugins/nomiclabs-hardhat-etherscan.html#multiple-api-keys-and-alternative-block-explorers
    // apiKey: {
    //   mainnet: ETHERSCAN_API_KEY,
    //   rinkeby: ETHERSCAN_API_KEY,
    //   bsctestnet: ETHERSCAN_API_KEY,
    // },
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 20,
    enabled: !!process.env.REPORT_GAS,
  },
  typechain: {
    outDir: "./build/typechain/",
    target: "ethers-v5",
  },
};

export default config;
