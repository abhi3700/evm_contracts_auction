import { ethers } from "hardhat";
import chai from "chai";
import { Contract, ContractFactory } from "ethers";
import { solidity } from "ethereum-waffle";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  ZERO_ADDRESS,
  getCurrentBlockTimestamp,
  setTimestamp,
} from "./testUtils";

import { ONE_DAY, TWO_DAYS, THREE_WEEKS } from "./helper";

chai.use(solidity);
const { expect } = chai;

export function testAuctionRepo(): void {
  describe("AuctionRepository contract", () => {
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

      it("Non-owner should not be able to transfer ownership", async () => {
        await expect(
          auctionRepoContract.connect(alice).transferOwnership(owner2.address)
        ).to.be.revertedWith("Ownable: caller is not the owner");
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
      it("An asset owner should not be able to create auction when paused", async () => {
        await auctionRepoContract.pause();

        // approve the 'AuctionRepo SC' to transfer ownership to 'Auction SC'
        assetContract
          .connect(owner)
          .approveOwnership(auctionRepoContract.address);

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

      it("Only asset owner should be able to create an auction", async () => {
        // approve the 'AuctionRepo SC' to transfer ownership to 'Auction SC'
        assetContract
          .connect(owner)
          .approveOwnership(auctionRepoContract.address);

        await auctionRepoContract
          .connect(owner)
          .createAuction(
            assetContract.address,
            (await getCurrentBlockTimestamp()) + ONE_DAY,
            (await getCurrentBlockTimestamp()) + THREE_WEEKS
          );
        const auctionAddresses: Array<string> =
          await auctionRepoContract.getLiveAuctions(assetContract.address);

        // verify the last pushed address is the same as the one we just created
        expect(auctionAddresses[auctionAddresses.length - 1]).to.not.equal(
          ZERO_ADDRESS
        );

        // verify that the asset's new owner is the Auction SC
        expect(await assetContract.owner()).to.equal(
          auctionAddresses[auctionAddresses.length - 1]
        );
      });

      it("asset owner should not be able to create multiple auctions for same asset", async () => {
        // approve the 'AuctionRepo SC' to transfer ownership to 'Auction SC'
        assetContract
          .connect(owner)
          .approveOwnership(auctionRepoContract.address);

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

        // verify that the asset's new owner is the Auction SC
        expect(await assetContract.owner()).to.equal(
          auctionAddresses[auctionAddresses.length - 1]
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
        ).to.be.revertedWith("Only asset owner can create auction");
      });

      it("An owner holding multiple assets can create auction for respective asset", async () => {
        const assetContract2: Contract = await GenericERC20Factory.deploy(
          "Rapid Innovation Token 2",
          "RAPIDO",
          9
        );
        await assetContract2.deployed();

        // approve the 'AuctionRepo SC' to transfer ownership to 'Auction SC'
        assetContract
          .connect(owner)
          .approveOwnership(auctionRepoContract.address);

        await auctionRepoContract
          .connect(owner)
          .createAuction(
            assetContract.address,
            (await getCurrentBlockTimestamp()) + ONE_DAY,
            (await getCurrentBlockTimestamp()) + THREE_WEEKS
          );

        // approve the 'AuctionRepo SC' to transfer ownership to 'Auction SC'
        assetContract2
          .connect(owner)
          .approveOwnership(auctionRepoContract.address);

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
        // verify that the asset's new owner is the Auction SC
        expect(await assetContract.owner()).to.equal(
          auctionAddresses[auctionAddresses.length - 1]
        );

        const auctionAddresses2: Array<string> =
          await auctionRepoContract.getAllAuctions(assetContract2.address);
        // verify the last pushed address is the same as the one we just created
        expect(auctionAddresses[auctionAddresses2.length - 1]).to.not.equal(
          ZERO_ADDRESS
        );
        // verify that the asset2's new owner is the Auction SC
        expect(await assetContract.owner()).to.equal(
          auctionAddresses[auctionAddresses.length - 1]
        );
      });

      it("Individual owner(s) should be able to create auction for their respective assets", async () => {
        const assetContract2: Contract = await GenericERC20Factory.connect(
          owner2
        ).deploy("Rapid Innovation Token 2", "RAPIDO", 9);
        await assetContract2.deployed();

        // approve the 'AuctionRepo SC' to transfer ownership to 'Auction SC'
        assetContract
          .connect(owner)
          .approveOwnership(auctionRepoContract.address);

        await auctionRepoContract
          .connect(owner)
          .createAuction(
            assetContract.address,
            (await getCurrentBlockTimestamp()) + ONE_DAY,
            (await getCurrentBlockTimestamp()) + THREE_WEEKS
          );

        // approve the 'AuctionRepo SC' to transfer ownership to 'Auction SC'
        assetContract2
          .connect(owner2)
          .approveOwnership(auctionRepoContract.address);

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

        // verify that the asset's new owner is the Auction SC
        expect(await assetContract.owner()).to.equal(
          auctionAddresses[auctionAddresses.length - 1]
        );

        // verify that the asset's new owner is the Auction SC
        expect(await assetContract.owner()).to.equal(
          auctionAddresses[auctionAddresses.length - 1]
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

    describe("updateLiveAuctions", () => {
      it("Only owner should be able to update live auctions", async () => {
        // approve the 'AuctionRepo SC' to transfer ownership to 'Auction SC'
        assetContract
          .connect(owner)
          .approveOwnership(auctionRepoContract.address);

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

        // console.log(`Before fast-forward: ${await getCurrentBlockTimestamp()}`);

        // fast forward the time to more than endsAt time
        setTimestamp((await getCurrentBlockTimestamp()) + THREE_WEEKS + 1);

        // console.log(`After fast-forward: ${await getCurrentBlockTimestamp()}`);

        const liveAuctionsBeforeUpdate: Array<string> =
          await auctionRepoContract.getLiveAuctions(assetContract.address);

        // update live auctions
        await auctionRepoContract.updateLiveAuctions(assetContract.address, 1);

        const liveAuctionsAfterUpdate: Array<string> =
          await auctionRepoContract.getLiveAuctions(assetContract.address);

        // verify that the 1st element (only 1 auction per ERC20) of the array after update is not same as before update
        expect(liveAuctionsBeforeUpdate[0]).to.not.equal(
          liveAuctionsAfterUpdate[0]
        );
      });

      it("Non-owner should not be able to update live auctions", async () => {});

      it("Owner should not be able to update live auctions when paused", async () => {});

      it("should fail when asset is not a contract address", async () => {
        await expect(
          auctionRepoContract.updateLiveAuctions(alice.address, 1)
        ).to.be.revertedWith("Asset not a contract");
      });

      it("should fail when no auction created", async () => {
        await expect(
          auctionRepoContract.updateLiveAuctions(assetContract.address, 1)
        ).to.be.revertedWith("loopCount > liveAuctions.length");
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

    describe("getLiveAuctions", () => {
      it("should return an empty array if no auctions exist", async () => {
        const auctionAddresses: Array<string> =
          await auctionRepoContract.getLiveAuctions(assetContract.address);
        expect(auctionAddresses).to.be.empty;
      });

      it("should fail when asset is not a contract address", async () => {
        await expect(
          auctionRepoContract.getLiveAuctions(alice.address)
        ).to.be.revertedWith("Asset not a contract");
      });
    });

    describe("fetchAuction", () => {
      it("should return auction details", async () => {
        const startAtBefore: number =
          (await getCurrentBlockTimestamp()) + ONE_DAY;
        const endAtBefore: number =
          (await getCurrentBlockTimestamp()) + THREE_WEEKS;

        // approve the 'AuctionRepo SC' to transfer ownership to 'Auction SC'
        assetContract
          .connect(owner)
          .approveOwnership(auctionRepoContract.address);

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
