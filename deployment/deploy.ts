import { ethers } from "hardhat";
import { Contract, ContractFactory /* , BigNumber */ } from "ethers";
import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";
dotenvConfig({ path: resolve(__dirname, "./.env") });

async function main(): Promise<void> {
  // ==============================================================================
  // We get the asset (ERC20) contract to deploy
  const GenericERC20Factory: ContractFactory = await ethers.getContractFactory(
    "GenericERC20"
  );
  const genericERC20Contract: Contract = await GenericERC20Factory.deploy(
    "Rapid Innovation Token",
    "RAPID",
    18
  );
  await genericERC20Contract.deployed();
  console.log("Asset SC deployed to: ", genericERC20Contract.address);
  console.log(
    `The transaction that was sent to the network to deploy the Asset contract: ${genericERC20Contract.deployTransaction.hash}`
  );
  // -----------------------------------------------------
  // We get the AuctionRepository contract to deploy
  const AuctionRepositoryFactory: ContractFactory =
    await ethers.getContractFactory("AuctionRepository");
  const auctionRepositoryContract: Contract =
    await AuctionRepositoryFactory.deploy();
  await auctionRepositoryContract.deployed();
  console.log(
    "Auction Repository SC deployed to: ",
    auctionRepositoryContract.address
  );
  console.log(
    `The transaction that was sent to the network to deploy the auction repository contract: ${auctionRepositoryContract.deployTransaction.hash}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then()
  .catch((error: Error) => {
    console.error(error);
    throw new Error("Exit: 1");
  });
