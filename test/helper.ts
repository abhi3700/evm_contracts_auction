import { HardhatEthersHelpers } from "@nomiclabs/hardhat-ethers/types";
import { ethers as hEthers } from "hardhat";
import { BigNumber } from "ethers";

export function getTimestamp(date: Date) {
  return Math.floor(date.getTime() / 1000);
}

export async function travelTime(ethers: HardhatEthersHelpers, time: number) {
  await ethers.provider.send("evm_increaseTime", [time]);
  await ethers.provider.send("evm_mine", []);
}

export async function resetBlockTimestamp(ethers: HardhatEthersHelpers) {
  const blockNumber = ethers.provider.getBlockNumber();
  const block = await ethers.provider.getBlock(blockNumber);
  const currentTimestamp = Math.floor(new Date().getTime() / 1000);
  const secondsDiff = currentTimestamp - block.timestamp;
  await ethers.provider.send("evm_increaseTime", [secondsDiff]);
  await ethers.provider.send("evm_mine", []);
}

export function parseWithDecimals(amount: number) {
  return hEthers.utils.parseUnits(Math.floor(amount).toString(), 18);
}

export function formatWithDecimals(amount: BigNumber) {
  return hEthers.utils.formatUnits(amount, 18);
}

export const ONE_DAY = 3600 * 24;
export const TWO_DAYS = 3600 * 24 * 2;
export const ONE_WEEK = 3600 * 24 * 7;
export const TWO_WEEKS = 3600 * 24 * 7 * 2;
export const THREE_WEEKS = 3600 * 24 * 7 * 3;
export const TWELVE_WEEKS = 3600 * 24 * 7 * 12;
