import { ethers } from "hardhat";
import chai from "chai";
import { Contract, ContractFactory } from "ethers";
import { solidity } from "ethereum-waffle";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ZERO_ADDRESS, getCurrentBlockTimestamp } from "./testUtils";

import { ONE_DAY, TWO_DAYS, THREE_WEEKS } from "./helper";

chai.use(solidity);
const { expect } = chai;

export function testAuctionRepo(): void {
  describe("Auction Repository contract", () => {
    let owner: SignerWithAddress,
      owner2: SignerWithAddress,
      alice: SignerWithAddress,
      bob: SignerWithAddress,
      charlie: SignerWithAddress;
    let GenericERC20Factory: ContractFactory, AuctionFactory: ContractFactory;
    let assetContract: Contract, auctionRepoContract: Contract;

    beforeEach(async () => {
      [owner, owner2, alice, bob, charlie] = await ethers.getSigners();
      GenericERC20Factory = await ethers.getContractFactory("GenericERC20");
      assetContract = await GenericERC20Factory.deploy(
        "Rapid Innovation Token",
        "RAPID",
        18
      );
      await assetContract.deployed();

      // ------------------------------------------------------
      const AuctionRepositoryFactory: ContractFactory =
        await ethers.getContractFactory("AuctionRepository");
      auctionRepoContract = await AuctionRepositoryFactory.deploy();
      await auctionRepoContract.deployed();

      expect(await auctionRepoContract.owner()).to.equal(owner.address);
    });

    describe("Ownable", async () => {
      it("Should return the correct owner", async () => {
        expect(await auctionRepoContract.owner()).to.equal(owner.address);
      });

      it("Owner should be able to transfer ownership", async () => {
        await expect(auctionRepoContract.transferOwnership(owner2.address))
          .to.emit(auctionRepoContract, "OwnershipTransferred")
          .withArgs(owner.address, owner2.address);
      });
    });

    describe("Pausable", async () => {
      it("Owner should be able to pause when NOT paused", async () => {
        await expect(auctionRepoContract.pause())
          .to.emit(auctionRepoContract, "Paused")
          .withArgs(owner.address);
      });

      it("Owner should be able to unpause when already paused", async () => {
        auctionRepoContract.pause();

        await expect(auctionRepoContract.unpause())
          .to.emit(auctionRepoContract, "Unpaused")
          .withArgs(owner.address);
      });

      it("Owner should not be able to pause when already paused", async () => {
        auctionRepoContract.pause();

        await expect(auctionRepoContract.pause()).to.be.revertedWith(
          "Pausable: paused"
        );
      });

      it("Owner should not be able to unpause when already unpaused", async () => {
        auctionRepoContract.pause();

        auctionRepoContract.unpause();

        await expect(auctionRepoContract.unpause()).to.be.revertedWith(
          "Pausable: not paused"
        );
      });
    });

    describe("createAuction", () => {
      it("Should not be able to create auction when paused", async () => {
        await auctionRepoContract.pause();

        await expect(
          auctionRepoContract
            .connect(owner)
            .createAuction(
              assetContract.address,
              (await getCurrentBlockTimestamp()) + ONE_DAY,
              (await getCurrentBlockTimestamp()) + THREE_WEEKS
            )
        ).to.be.revertedWith("Pausable: paused");
      });

      it("Only owner should be able to create an auction", async () => {
        await auctionRepoContract
          .connect(owner)
          .createAuction(
            assetContract.address,
            (await getCurrentBlockTimestamp()) + ONE_DAY,
            (await getCurrentBlockTimestamp()) + THREE_WEEKS
          );
        const auctionAddresses: Array<string> =
          await auctionRepoContract.getAllAuctions(assetContract.address);

        // verify the last pushed address is the same as the one we just created
        expect(auctionAddresses[auctionAddresses.length - 1]).to.not.equal(
          ZERO_ADDRESS
        );
      });

      it("owner should not be able to create multiple auctions for same asset", async () => {
        await auctionRepoContract
          .connect(owner)
          .createAuction(
            assetContract.address,
            (await getCurrentBlockTimestamp()) + ONE_DAY,
            (await getCurrentBlockTimestamp()) + THREE_WEEKS
          );
        const auctionAddresses: Array<string> =
          await auctionRepoContract.getAllAuctions(assetContract.address);

        // verify the last pushed address is the same as the one we just created
        expect(auctionAddresses[auctionAddresses.length - 1]).to.not.equal(
          ZERO_ADDRESS
        );

        // create another auction for the same asset
        await expect(
          auctionRepoContract
            .connect(owner)
            .createAuction(
              assetContract.address,
              (await getCurrentBlockTimestamp()) + ONE_DAY,
              (await getCurrentBlockTimestamp()) + THREE_WEEKS
            )
        ).to.be.revertedWith("Auction already exists");
      });

      it("1 owner should be able to create multiple auctions for different assets", async () => {
        const assetContract2: Contract = await GenericERC20Factory.deploy(
          "Rapid Innovation Token 2",
          "RAPIDO",
          9
        );
        await assetContract2.deployed();

        await auctionRepoContract
          .connect(owner)
          .createAuction(
            assetContract.address,
            (await getCurrentBlockTimestamp()) + ONE_DAY,
            (await getCurrentBlockTimestamp()) + THREE_WEEKS
          );
        await auctionRepoContract
          .connect(owner)
          .createAuction(
            assetContract2.address,
            (await getCurrentBlockTimestamp()) + ONE_DAY,
            (await getCurrentBlockTimestamp()) + THREE_WEEKS
          );
        const auctionAddresses: Array<string> =
          await auctionRepoContract.getAllAuctions(assetContract.address);

        // verify the last pushed address is the same as the one we just created
        expect(auctionAddresses[auctionAddresses.length - 1]).to.not.equal(
          ZERO_ADDRESS
        );
        const auctionAddresses2: Array<string> =
          await auctionRepoContract.getAllAuctions(assetContract2.address);
        expect(auctionAddresses[auctionAddresses2.length - 1]).to.not.equal(
          ZERO_ADDRESS
        );
      });

      it("should be able to create multiple auctions for different assets by different owners", async () => {
        const assetContract2: Contract = await GenericERC20Factory.connect(
          owner2
        ).deploy("Rapid Innovation Token 2", "RAPIDO", 9);
        await assetContract2.deployed();

        await auctionRepoContract
          .connect(owner)
          .createAuction(
            assetContract.address,
            (await getCurrentBlockTimestamp()) + ONE_DAY,
            (await getCurrentBlockTimestamp()) + THREE_WEEKS
          );
        await auctionRepoContract
          .connect(owner2)
          .createAuction(
            assetContract2.address,
            (await getCurrentBlockTimestamp()) + ONE_DAY,
            (await getCurrentBlockTimestamp()) + THREE_WEEKS
          );
        const auctionAddresses: Array<string> =
          await auctionRepoContract.getAllAuctions(assetContract.address);

        // verify the last pushed address is the same as the one we just created
        expect(auctionAddresses[auctionAddresses.length - 1]).to.not.equal(
          ZERO_ADDRESS
        );
        const auctionAddresses2: Array<string> =
          await auctionRepoContract.getAllAuctions(assetContract2.address);
        expect(auctionAddresses[auctionAddresses2.length - 1]).to.not.equal(
          ZERO_ADDRESS
        );

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
      });

      it("should fail when asset is not a contract address", async () => {
        await expect(
          auctionRepoContract
            .connect(owner)
            .createAuction(
              alice.address,
              (await getCurrentBlockTimestamp()) + ONE_DAY,
              (await getCurrentBlockTimestamp()) + THREE_WEEKS
            )
        ).to.be.revertedWith("Asset not a contract");
      });

      it("should fail when startsAt < now", async () => {
        await expect(
          auctionRepoContract
            .connect(owner)
            .createAuction(
              assetContract.address,
              (await getCurrentBlockTimestamp()) - ONE_DAY,
              (await getCurrentBlockTimestamp()) + THREE_WEEKS
            )
        ).to.be.revertedWith("startsAt < now");
      });

      it("should fail when endsAt < startsAt", async () => {
        await expect(
          auctionRepoContract
            .connect(owner)
            .createAuction(
              assetContract.address,
              (await getCurrentBlockTimestamp()) + TWO_DAYS,
              (await getCurrentBlockTimestamp()) + ONE_DAY
            )
        ).to.be.revertedWith("endsAt < startsAt");
      });
    });

    describe("getAllAuctions", () => {
      it("should return an empty array if no auctions exist", async () => {
        const auctionAddresses: Array<string> =
          await auctionRepoContract.getAllAuctions(assetContract.address);
        expect(auctionAddresses).to.be.empty;
      });

      it("should fail when asset is not a contract address", async () => {
        await expect(
          auctionRepoContract.getAllAuctions(alice.address)
        ).to.be.revertedWith("Asset not a contract");
      });
    });

    describe("fetchAuction", () => {
      it("should return auction details", async () => {
        const startAtBefore: number =
          (await getCurrentBlockTimestamp()) + ONE_DAY;
        const endAtBefore: number =
          (await getCurrentBlockTimestamp()) + THREE_WEEKS;
        await auctionRepoContract
          .connect(owner)
          .createAuction(assetContract.address, startAtBefore, endAtBefore);

        const auctionAddresses: Array<string> =
          await auctionRepoContract.getAllAuctions(assetContract.address);
        const [asset, _, startAt, endAt] =
          await auctionRepoContract.fetchAuction(
            auctionAddresses[auctionAddresses.length - 1]
          );

        // verify the details of auction with the set input values
        expect(asset).to.equal(assetContract.address);
        expect(startAt).to.equal(startAtBefore);
        expect(endAt).to.equal(endAtBefore);
      });

      it("should fail when auction is not a contract address", async () => {
        await expect(
          auctionRepoContract.fetchAuction(alice.address)
        ).to.be.revertedWith("Auction not a contract");
      });
    });
  });
}
