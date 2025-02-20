import { ethers } from "hardhat";

async function main() {
  console.log("Deploying ImprovedDomainEscrow contract...");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const domainEscrow = await ethers.deployContract("ImprovedDomainEscrow");
  await domainEscrow.waitForDeployment();

  console.log("ImprovedDomainEscrow deployed to:", await domainEscrow.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });