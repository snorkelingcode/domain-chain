// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ImprovedInstantDomainNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;

    // Struct for Domain Metadata
    struct DomainMetadata {
        string domainName;
        address originalOwner;
        uint256 createdAt;
        uint256 price;
        bytes32 verificationHash;
    }

    // Pricing Oracle Simulation
    struct PricingData {
        uint256 basePrice;
        uint256 lastSalePrice;
        uint256 totalTransactions;
    }

    // Mappings
    mapping(uint256 => DomainMetadata) public domainMetadata;
    mapping(string => bool) public domainExists;
    mapping(string => uint256) public domainToTokenId;
    mapping(string => PricingData) public domainPricing;

    // Events
    event DomainMinted(
        uint256 indexed tokenId, 
        string domainName, 
        address indexed owner, 
        uint256 price
    );
    event DomainPriceUpdated(
        uint256 indexed tokenId, 
        uint256 newPrice
    );
    event PriceRecommended(
        string domainName, 
        uint256 recommendedPrice
    );

    constructor() ERC721("InstantDomain", "IDMN") {}

    // Instant Domain Minting with Simplified Verification
    function mintDomain(
        string memory domainName
    ) external returns (uint256) {
        // Prevent duplicate domain registration
        require(!domainExists[domainName], "Domain already registered");
        
        // Validate domain name (basic checks)
        require(bytes(domainName).length > 0 && bytes(domainName).length <= 255, "Invalid domain name");

        // Generate verification hash using dynamic inputs
        bytes32 verificationHash = keccak256(
            abi.encodePacked(domainName, msg.sender, block.timestamp)
        );

        // Suggest initial price based on simple market algorithm
        uint256 initialPrice = suggestPrice(domainName);

        // Increment token ID
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Mint NFT to sender
        _safeMint(msg.sender, newTokenId);

        // Store domain metadata
        domainMetadata[newTokenId] = DomainMetadata({
            domainName: domainName,
            originalOwner: msg.sender,
            createdAt: block.timestamp,
            price: initialPrice,
            verificationHash: verificationHash
        });

        // Update pricing data
        domainPricing[domainName] = PricingData({
            basePrice: initialPrice,
            lastSalePrice: 0,
            totalTransactions: 0
        });

        // Mark domain as existing
        domainExists[domainName] = true;
        domainToTokenId[domainName] = newTokenId;

        // Emit minting event
        emit DomainMinted(newTokenId, domainName, msg.sender, initialPrice);

        return newTokenId;
    }

    // Intelligent Price Suggestion Algorithm
    function suggestPrice(string memory domainName) public view returns (uint256) {
        PricingData memory pricing = domainPricing[domainName];
        
        // Base pricing logic
        uint256 basePrice = 0.01 ether;
        
        // If domain has previous transaction history
        if (pricing.totalTransactions > 0) {
            // Use last sale price with some dynamic adjustment
            basePrice = pricing.lastSalePrice.mul(110).div(100); // 10% increase
        }
        
        // Additional factors (simplified)
        uint256 lengthFactor = bytes(domainName).length <= 10 ? 2 : 1;
        
        uint256 recommendedPrice = basePrice.mul(lengthFactor);
        
        emit PriceRecommended(domainName, recommendedPrice);
        
        return recommendedPrice;
    }

    // Update domain price with more flexible mechanism
    function updateDomainPrice(
        uint256 tokenId, 
        uint256 newPrice
    ) external {
        // Ensure only token owner can update price
        require(ownerOf(tokenId) == msg.sender, "Not domain owner");
        
        DomainMetadata storage metadata = domainMetadata[tokenId];
        string memory domainName = metadata.domainName;
        
        // Update price
        metadata.price = newPrice;
        
        // Update pricing data
        domainPricing[domainName].basePrice = newPrice;
        
        // Emit price update event
        emit DomainPriceUpdated(tokenId, newPrice);
    }

    // Get domain metadata by token ID
    function getDomainMetadata(
        uint256 tokenId
    ) external view returns (DomainMetadata memory) {
        require(_exists(tokenId), "Token does not exist");
        return domainMetadata[tokenId];
    }

    // Get domain metadata by domain name
    function getDomainByName(
        string memory domainName
    ) external view returns (DomainMetadata memory) {
        require(domainExists[domainName], "Domain not found");
        uint256 tokenId = domainToTokenId[domainName];
        return domainMetadata[tokenId];
    }
}