import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy Token Contract
  const TokenContract = await ethers.getContractFactory("DomainChainToken");
  const domainChainToken = await TokenContract.deploy();
  await domainChainToken.waitForDeployment();
  const tokenAddress = await domainChainToken.getAddress();
  console.log("DomainChain Token deployed to:", tokenAddress);

  // Deploy Treasury Contract
  const TreasuryContract = await ethers.getContractFactory("DomainChainTreasury");
  const domainChainTreasury = await TreasuryContract.deploy();
  await domainChainTreasury.waitForDeployment();
  const treasuryAddress = await domainChainTreasury.getAddress();
  console.log("DomainChain Treasury deployed to:", treasuryAddress);

  // Deploy InstantDomainNFT Contract
  const DomainNFTContract = await ethers.getContractFactory("InstantDomainNFT");
  const instantDomainNFT = await DomainNFTContract.deploy();
  await instantDomainNFT.waitForDeployment();
  const nftAddress = await instantDomainNFT.getAddress();
  console.log("Instant Domain NFT deployed to:", nftAddress);

  // Deploy Escrow Contract
  const EscrowContract = await ethers.getContractFactory("ImprovedDomainEscrow");
  const improvedDomainEscrow = await EscrowContract.deploy(
    tokenAddress,
    treasuryAddress,
    nftAddress
  );
  await improvedDomainEscrow.waitForDeployment();
  const escrowAddress = await improvedDomainEscrow.getAddress();
  console.log("Improved Domain Escrow deployed to:", escrowAddress);

  // Additional setup steps
  try {
    // Transfer initial tokens to Escrow contract
    const initialTokenAllocation = ethers.parseEther("100000");
    await domainChainToken.transfer(escrowAddress, initialTokenAllocation);
    console.log("Initial token allocation transferred to Escrow contract");

    // Add Escrow contract as a minter/authorized contract for token
    console.log("Deployment complete!");
  } catch (setupError) {
    console.error("Setup error:", setupError);
  }

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