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
  ZERO_ADDRESS,
  getCurrentBlockTimestamp,
  setTimestamp,
} from "./testUtils";

import { ONE_DAY, THREE_WEEKS } from "./helper";
import { beforeEach } from "mocha";

chai.use(solidity);
const { expect } = chai;

export function testAuction(): void {
  describe("Auction contract", () => {
    let owner: SignerWithAddress,
      owner2: SignerWithAddress,
      alice: SignerWithAddress,
      bob: SignerWithAddress,
      charlie: SignerWithAddress;
    let GenericERC20Factory: ContractFactory, AuctionFactory: ContractFactory;
    let assetContract: Contract,
      auctionRepoContract: Contract,
      auctionContract: Contract;
    let startsAt: number, endsAt: number;

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

      // ------------------------------------------------------
      // approve the 'AuctionRepo SC' to transfer ownership to 'Auction SC'
      startsAt = (await getCurrentBlockTimestamp()) + ONE_DAY;
      endsAt = startsAt + THREE_WEEKS;

      assetContract
        .connect(owner)
        .approveOwnership(auctionRepoContract.address);

      // create auction
      await auctionRepoContract
        .connect(owner)
        .createAuction(assetContract.address, startsAt, endsAt);

      const auctionAddresses: Array<string> =
        await auctionRepoContract.getAllAuctions(assetContract.address);
      // ------------------------------------------------------
      AuctionFactory = await ethers.getContractFactory("Auction");
      auctionContract = await AuctionFactory.attach(
        auctionAddresses[auctionAddresses.length - 1]
      );
    });

    describe("Ownable", async () => {
      it("Should return the correct owner", async () => {
        expect(await auctionContract.owner()).to.equal(owner.address);
      });

      it("Owner should be able to transfer ownership", async () => {
        await expect(auctionContract.transferOwnership(owner2.address))
          .to.emit(auctionContract, "OwnershipTransferred")
          .withArgs(owner.address, owner2.address);
      });

      it("Non-owner should not be able to transfer ownership", async () => {
        await expect(
          auctionContract.connect(alice).transferOwnership(owner2.address)
        ).to.be.revertedWith("Ownable: caller is not the owner");
      });
    });

    describe("Pausable", async () => {
      it("Owner should be able to pause when NOT paused", async () => {
        await expect(auctionContract.pause())
          .to.emit(auctionContract, "Paused")
          .withArgs(owner.address);
      });

      it("Owner should be able to unpause when already paused", async () => {
        auctionContract.pause();

        await expect(auctionContract.unpause())
          .to.emit(auctionContract, "Unpaused")
          .withArgs(owner.address);
      });

      it("Owner should not be able to pause when already paused", async () => {
        auctionContract.pause();

        await expect(auctionContract.pause()).to.be.revertedWith(
          "Pausable: paused"
        );
      });

      it("Owner should not be able to unpause when already unpaused", async () => {
        auctionContract.pause();

        auctionContract.unpause();

        await expect(auctionContract.unpause()).to.be.revertedWith(
          "Pausable: not paused"
        );
      });
    });

    describe("read values", async () => {
      it("Should return the correct auctionRepository", async () => {
        expect(await auctionContract.auctionRepository()).to.equal(
          auctionRepoContract.address
        );
      });

      it("Should return the correct asset", async () => {
        expect(await auctionContract.asset()).to.equal(assetContract.address);
      });

      it("Should return the correct startsAt", async () => {
        expect(await auctionContract.startsAt()).to.equal(startsAt);
      });

      it("Should return the correct endsAt", async () => {
        expect(await auctionContract.endsAt()).to.equal(endsAt);
      });

      it("Should return the correct highestBid so far", async () => {
        expect(await auctionContract.highestBid()).to.equal(0);
      });

      it("Should return the correct highestBidder so far", async () => {
        expect(await auctionContract.highestBidder()).to.equal(ZERO_ADDRESS);
      });
    });

    describe("initialize", async () => {
      it("Should fail if called", async () => {
        await expect(
          auctionContract.initialize(
            owner.address,
            owner.address,
            assetContract.address,
            startsAt,
            endsAt
          )
        ).to.be.revertedWith("only auctionRepository");
      });
    });

    describe("Place Bid", async () => {
      it("Should not be able to bid if paused", async () => {
        auctionContract.pause();

        await expect(
          auctionContract.connect(alice).placeBid({ value: 100 })
        ).to.be.revertedWith("Pausable: paused");
      });

      it("Should not be able to bid before auction starts", async () => {
        setTimestamp(startsAt - 1);
        await expect(
          auctionContract.connect(alice).placeBid({ value: 100 })
        ).to.be.revertedWith("Auction not started");
      });

      it("Should not be able to bid after auction ends", async () => {
        setTimestamp(endsAt + 1);
        await expect(
          auctionContract.connect(alice).placeBid({ value: 100 })
        ).to.be.revertedWith("Auction ended");
      });

      it("Should not be able to bid if lesser than the highestBid so far", async () => {
        setTimestamp(startsAt + 1);
        await expect(auctionContract.connect(alice).placeBid({ value: 100 }))
          .to.emit(auctionContract, "Bid")
          .withArgs(alice.address, 100);

        await expect(
          auctionContract.connect(bob).placeBid({ value: 99 })
        ).to.be.revertedWith("Bid < highest bid");
      });

      it("Should be able to place bid", async () => {
        const provider = ethers.provider;
        const balanceInEthBefore = await provider.getBalance(alice.address);

        setTimestamp(startsAt + 1);
        await expect(auctionContract.connect(alice).placeBid({ value: 100 }))
          .to.emit(auctionContract, "Bid")
          .withArgs(alice.address, 100);

        const balanceInEthAfter = await provider.getBalance(alice.address);

        // verify eth balance of bidder reduced
        await expect(balanceInEthBefore).to.be.gt(balanceInEthAfter);
      });

      it("Should not be able to bid in succession", async () => {
        setTimestamp(startsAt + 1);
        await expect(auctionContract.connect(alice).placeBid({ value: 100 }))
          .to.emit(auctionContract, "Bid")
          .withArgs(alice.address, 100);

        await expect(
          auctionContract.connect(alice).placeBid({ value: 101 })
        ).to.be.revertedWith("can bid only once");
      });

      it("Should not be able to bid more than once", async () => {
        setTimestamp(startsAt + 1);
        await expect(auctionContract.connect(alice).placeBid({ value: 100 }))
          .to.emit(auctionContract, "Bid")
          .withArgs(alice.address, 100);

        await expect(auctionContract.connect(bob).placeBid({ value: 101 }))
          .to.emit(auctionContract, "Bid")
          .withArgs(bob.address, 101);

        await expect(
          auctionContract.connect(alice).placeBid({ value: 102 })
        ).to.be.revertedWith("can bid only once");
      });
    });

    describe("Withdraw Bid", async () => {
      it("Should not be able to withdraw bid if paused", async () => {
        auctionContract.pause();

        await expect(
          auctionContract.connect(alice).withdrawBid()
        ).to.be.revertedWith("Pausable: paused");
      });

      it("Should not be able to withdraw bid before auction starts", async () => {
        setTimestamp(startsAt - 1);
        await expect(
          auctionContract.connect(alice).withdrawBid()
        ).to.be.revertedWith("Auction not ended");
      });

      describe("After auction ends", async () => {
        beforeEach(async () => {
          setTimestamp(startsAt + 1);
          await expect(auctionContract.connect(alice).placeBid({ value: 100 }))
            .to.emit(auctionContract, "Bid")
            .withArgs(alice.address, 100);
        });

        it("Should not be able to withdraw bid as only/highest bidder", async () => {
          setTimestamp(endsAt + 1);
          await expect(
            auctionContract.connect(alice).withdrawBid()
          ).to.be.revertedWith("Highest bidder cannot withdraw");
        });

        it("Should be able to withdraw bid when someone else is highest bidder", async () => {
          await expect(auctionContract.connect(bob).placeBid({ value: 101 }))
            .to.emit(auctionContract, "Bid")
            .withArgs(bob.address, 101);

          setTimestamp(endsAt + 1);
          await expect(auctionContract.connect(alice).withdrawBid())
            .to.emit(auctionContract, "BidWithdrawn")
            .withArgs(alice.address, 100);
        });
      });
    });

    describe("claim Possession", async () => {
      it("Should not be able to claim possession if paused", async () => {
        auctionContract.pause();

        await expect(
          auctionContract.connect(alice).claimPossession()
        ).to.be.revertedWith("Pausable: paused");
      });

      it("Should not be able to claim possession before auction starts", async () => {
        setTimestamp(startsAt - 1);
        await expect(
          auctionContract.connect(alice).claimPossession()
        ).to.be.revertedWith("Auction not ended");
      });

      describe("After auction ends", async () => {
        beforeEach(async () => {
          setTimestamp(startsAt + 1);
          await expect(auctionContract.connect(alice).placeBid({ value: 100 }))
            .to.emit(auctionContract, "Bid")
            .withArgs(alice.address, 100);
        });

        it("Should be able to claim possession as only/highest bidder", async () => {
          setTimestamp(endsAt + 1);
          await expect(auctionContract.connect(alice).claimPossession())
            .to.emit(auctionContract, "BidClaimed")
            .withArgs(alice.address);
        });

        it("Should not be able to claim possession unless one is highest bidder", async () => {
          await expect(auctionContract.connect(bob).placeBid({ value: 101 }))
            .to.emit(auctionContract, "Bid")
            .withArgs(bob.address, 101);

          setTimestamp(endsAt + 1);
          await expect(
            auctionContract.connect(alice).claimPossession()
          ).to.be.revertedWith("Only highest bidder can claim");
        });

        it("Should be able to claim possession as highest bidder in case of multiple bids", async () => {
          await expect(auctionContract.connect(bob).placeBid({ value: 101 }))
            .to.emit(auctionContract, "Bid")
            .withArgs(bob.address, 101);

          await expect(
            auctionContract.connect(charlie).placeBid({ value: 102 })
          )
            .to.emit(auctionContract, "Bid")
            .withArgs(charlie.address, 102);

          setTimestamp(endsAt + 1);
          await expect(auctionContract.connect(charlie).claimPossession())
            .to.emit(auctionContract, "BidClaimed")
            .withArgs(charlie.address);
        });

        it("Should not be able to claim possession if already claimed", async () => {
          setTimestamp(endsAt + 1);
          await expect(auctionContract.connect(alice).claimPossession())
            .to.emit(auctionContract, "BidClaimed")
            .withArgs(alice.address);

          await expect(
            auctionContract.connect(alice).claimPossession()
          ).to.be.revertedWith("Bid already claimed");
        });
      });
    });

    describe("Reclaim Asset", async () => {
      it("Should not be able to reclaim asset if paused", async () => {
        auctionContract.pause();

        await expect(
          auctionContract.connect(alice).reclaimAsset()
        ).to.be.revertedWith("Pausable: paused");
      });

      it("Should not be able to reclaim asset before auction starts", async () => {
        setTimestamp(startsAt - 1);
        await expect(
          auctionContract.connect(alice).reclaimAsset()
        ).to.be.revertedWith("Auction not ended");
      });

      it("Should not be able to reclaim asset if not original asset owner", async () => {
        setTimestamp(endsAt + 1);
        await expect(
          auctionContract.connect(alice).reclaimAsset()
        ).to.be.revertedWith("Only original asset owner can reclaim");
      });

      it("Should not be able to reclaim asset if bid is placed", async () => {
        setTimestamp(startsAt + 1);
        await expect(auctionContract.connect(alice).placeBid({ value: 100 }))
          .to.emit(auctionContract, "Bid")
          .withArgs(alice.address, 100);

        setTimestamp(endsAt + 1);
        await expect(
          auctionContract.connect(owner).reclaimAsset()
        ).to.be.revertedWith("Bid placed, cannot reclaim");
      });

      it("Should be able to reclaim asset if no bid is placed", async () => {
        setTimestamp(endsAt + 1);
        await expect(auctionContract.connect(owner).reclaimAsset())
          .to.emit(auctionContract, "AssetReclaimed")
          .withArgs(owner.address);
      });
    });
  });
}
