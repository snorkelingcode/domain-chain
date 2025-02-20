import { ethers } from "hardhat";
import { expect } from "chai";

describe("InstantDomainNFT", function () {
  let instantDomainNFT: any;
  let owner: any;
  let addr1: any;

  beforeEach(async function () {
    const InstantDomainNFT = await ethers.getContractFactory("InstantDomainNFT");
    [owner, addr1] = await ethers.getSigners();
    
    instantDomainNFT = await InstantDomainNFT.deploy();
    await instantDomainNFT.waitForDeployment();
  });

  it("Should mint a new domain", async function () {
    const domainName = "example.com";
    const price = ethers.parseEther("0.1");
    const verificationHash = ethers.keccak256(ethers.toUtf8Bytes(domainName));

    await instantDomainNFT.mintDomain(domainName, price, verificationHash);
    
    const tokenId = await instantDomainNFT.domainToTokenId(domainName);
    const metadata = await instantDomainNFT.getDomainMetadata(tokenId);

    expect(metadata.domainName).to.equal(domainName);
    expect(metadata.originalOwner).to.equal(owner.address);
  });

  it("Should prevent duplicate domain registration", async function () {
    const domainName = "example.com";
    const price = ethers.parseEther("0.1");
    const verificationHash = ethers.keccak256(ethers.toUtf8Bytes(domainName));

    await instantDomainNFT.mintDomain(domainName, price, verificationHash);
    
    await expect(
      instantDomainNFT.mintDomain(domainName, price, verificationHash)
    ).to.be.revertedWith("Domain already registered");
  });
});