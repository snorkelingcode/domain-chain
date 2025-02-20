import { ethers } from "hardhat";

async function main() {
  console.log("Deploying DomainChain Token...");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const TokenContract = await ethers.getContractFactory("DomainChainToken");
  const token = await TokenContract.deploy();
  await token.waitForDeployment();

  console.log("DomainChain Token deployed to:", await token.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });