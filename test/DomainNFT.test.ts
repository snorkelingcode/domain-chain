import { ethers } from "hardhat";
import { expect } from "chai";
import { DomainNFT } from "../typechain-types";

describe("DomainNFT", function () {
  let domainNFT: DomainNFT;
  let owner: any;
  let addr1: any;

  beforeEach(async function () {
    const DomainNFTFactory = await ethers.getContractFactory("DomainNFT");
    [owner, addr1] = await ethers.getSigners();
    
    domainNFT = await DomainNFTFactory.deploy();
    await domainNFT.waitForDeployment();
  });

  it("Should mint a new domain", async function () {
    const domainName = "example.com";
    const price = ethers.parseEther("0.1");
    
    await domainNFT.mintDomain(domainName, price);
    
    const tokenId = await domainNFT.domainToTokenId(domainName);
    const metadata = await domainNFT.getDomainMetadata(tokenId);

    expect(metadata.domainName).to.equal(domainName);
    expect(metadata.originalOwner).to.equal(owner.address);
  });

  it("Should prevent duplicate domain registration", async function () {
    const domainName = "example.com";
    const price = ethers.parseEther("0.1");

    await domainNFT.mintDomain(domainName, price);
    
    await expect(
      domainNFT.mintDomain(domainName, price)
    ).to.be.revertedWith("Domain already registered");
  });
});