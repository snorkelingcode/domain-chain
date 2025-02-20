import { ethers } from "hardhat";
import type { DomainChainToken } from "../typechain-types/contracts/DomainChainToken";
import type { DomainChainTreasury } from "../typechain-types/contracts/DomainChainTreasury";
import type { DomainEscrow } from "../typechain-types/contracts/DomainEscrow";
import type { DomainNFT } from "../typechain-types/contracts/DomainNFT";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Token Contract
  console.log("\nDeploying DomainChainToken...");
  const TokenContract = await ethers.getContractFactory("DomainChainToken");
  const domainChainToken = await TokenContract.deploy() as unknown as DomainChainToken;
  await domainChainToken.waitForDeployment();
  const tokenAddress = await domainChainToken.getAddress();
  console.log("DomainChainToken deployed to:", tokenAddress);

  // Deploy Treasury Contract
  console.log("\nDeploying DomainChainTreasury...");
  const TreasuryContract = await ethers.getContractFactory("DomainChainTreasury");
  const domainChainTreasury = await TreasuryContract.deploy() as unknown as DomainChainTreasury;
  await domainChainTreasury.waitForDeployment();
  const treasuryAddress = await domainChainTreasury.getAddress();
  console.log("DomainChainTreasury deployed to:", treasuryAddress);

  // Deploy DomainNFT Contract
  console.log("\nDeploying DomainNFT...");
  const DomainNFTContract = await ethers.getContractFactory("DomainNFT");
  const domainNFT = await DomainNFTContract.deploy() as unknown as DomainNFT;
  await domainNFT.waitForDeployment();
  const nftAddress = await domainNFT.getAddress();
  console.log("DomainNFT deployed to:", nftAddress);

  // Deploy DomainEscrow Contract
  console.log("\nDeploying DomainEscrow...");
  const EscrowContract = await ethers.getContractFactory("DomainEscrow");
  const escrow = await EscrowContract.deploy(
    tokenAddress,
    treasuryAddress,
    nftAddress
  ) as unknown as DomainEscrow;
  await escrow.waitForDeployment();
  const escrowAddress = await escrow.getAddress();
  console.log("DomainEscrow deployed to:", escrowAddress);

  // Additional setup steps
  console.log("\nPerforming additional setup...");
  try {
    // Get MINTER_ROLE bytes32 value directly
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
    
    // Grant minter role to Escrow contract
    await domainChainToken.grantRole(MINTER_ROLE, escrowAddress);
    console.log("Minter role granted to Escrow contract");

    // Authorize Escrow in Treasury
    await domainChainTreasury.addAPIProvider(escrowAddress);
    console.log("Escrow authorized in Treasury");

  } catch (setupError) {
    console.error("Setup error:", setupError);
    throw setupError;
  }

  // Log all addresses
  console.log("\nDeployed Contract Addresses:");
  console.log("--------------------");
  console.log("Token:", tokenAddress);
  console.log("Treasury:", treasuryAddress);
  console.log("NFT:", nftAddress);
  console.log("Escrow:", escrowAddress);

  // Return contract addresses for frontend integration
  return {
    tokenAddress,
    treasuryAddress,
    nftAddress,
    escrowAddress
  };
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });