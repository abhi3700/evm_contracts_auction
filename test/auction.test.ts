import { ethers } from "hardhat";
import chai from "chai";
import {
  BigNumber,
  Contract /* , Signer */ /* , Wallet */,
  ContractFactory,
} from "ethers";
import { /* deployContract, */ solidity } from "ethereum-waffle";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  // MAX_UINT256,
  // TIME,
  ZERO_ADDRESS,
  // asyncForEach,
  // deployContractWithLibraries,
  getCurrentBlockTimestamp,
  // getUserTokenBalance,
  // getUserTokenBalances,
  setNextTimestamp,
  // setTimestamp,
} from "./testUtils";

import { ONE_DAY, THREE_WEEKS } from "./helper";

chai.use(solidity);
const { expect } = chai;

export function testAuction(): void {
  describe("Auction contract", () => {
    describe("", () => {});

    /* 
      // verify that the auction is not live
        AuctionFactory = await ethers.getContractFactory("Auction");
        const auctionContract: Contract = AuctionFactory.attach(
          auctionAddresses[auctionAddresses.length - 1]
        );
        expect(await auctionContract.isLive()).to.be.false;    */

    /* 
        // verify that the owner of the first auction is not the same as the owner of the second auction
        AuctionFactory = await ethers.getContractFactory("Auction");
        const auctionContract1: Contract = AuctionFactory.attach(
          auctionAddresses[auctionAddresses.length - 1]
        );
        const auctionContract2: Contract = AuctionFactory.attach(
          auctionAddresses[auctionAddresses2.length - 1]
        );

        expect(await auctionContract1.owner()).to.equal(
          await auctionContract2.owner()
        );
        */
  });
}
