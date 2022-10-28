import { ethers } from "hardhat";
import { Contract, ContractFactory /* , BigNumber */ } from "ethers";
import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";
dotenvConfig({ path: resolve(__dirname, "./.env") });

import { getCurrentBlockTimestamp } from "../test/testUtils";
import { ONE_DAY, THREE_WEEKS } from "../test/helper";

async function main(): Promise<void> {
  const [owner, owner2, alice, bob, charlie] = await ethers.getSigners();

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
  console.log("--\nAsset SC deployed to: ", genericERC20Contract.address);
  console.log(
    `Asset contract deployed with txn hash: ${genericERC20Contract.deployTransaction.hash}`
  );
  // -----------------------------------------------------
  // We get the AuctionRepository contract to deploy
  const AuctionRepoFactory: ContractFactory = await ethers.getContractFactory(
    "AuctionRepository"
  );
  const auctionRepoContract: Contract = await AuctionRepoFactory.deploy();
  await auctionRepoContract.deployed();
  console.log(
    "--\nAuction Repository SC deployed to: ",
    auctionRepoContract.address
  );
  console.log(
    `AuctionRepository SC deployed with txn hash: ${auctionRepoContract.deployTransaction.hash}`
  );

  // -----------------------------------------------------
  // We get the Auction contract to create
  // ------------------------------------------------------
  // approve the 'AuctionRepo SC' to transfer ownership to 'Auction SC'
  const startsAt: number = (await getCurrentBlockTimestamp()) + ONE_DAY;
  const endsAt: number = startsAt + THREE_WEEKS;

  await genericERC20Contract
    .connect(owner)
    .approveOwnership(auctionRepoContract.address);

  // create auction
  const receipt = await auctionRepoContract
    .connect(owner)
    .createAuction(genericERC20Contract.address, startsAt, endsAt);

  const auctionAddresses: Array<string> =
    await auctionRepoContract.getAllAuctions(genericERC20Contract.address);
  // ------------------------------------------------------
  const AuctionFactory: ContractFactory = await ethers.getContractFactory(
    "Auction"
  );
  const auctionContract = await AuctionFactory.attach(
    auctionAddresses[auctionAddresses.length - 1]
  );

  console.log("--\nAuction SC deployed to: ", auctionContract.address);
  console.log(`Auction SC deployed with txn hash: ${receipt.hash}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then()
  .catch((error: Error) => {
    console.error(error);
    throw new Error("Exit: 1");
  });
