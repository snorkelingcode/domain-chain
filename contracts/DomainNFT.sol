// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DomainNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    // Struct for Domain Metadata
    struct DomainMetadata {
        string domainName;
        address originalOwner;
        uint256 createdAt;
        uint256 price;
        bytes32 verificationHash;
    }

    // Mappings
    mapping(uint256 => DomainMetadata) public domainMetadata;
    mapping(string => bool) public domainExists;
    mapping(string => uint256) public domainToTokenId;

    // Events
    event DomainMinted(
        uint256 indexed tokenId, 
        string domainName, 
        address indexed owner
    );
    event DomainPriceUpdated(
        uint256 indexed tokenId, 
        uint256 newPrice
    );

    constructor() ERC721("DomainChain", "DCN") {}

    // Domain Minting with Verification
    function mintDomain(
        string memory domainName,
        uint256 initialPrice
    ) external returns (uint256) {
        require(!domainExists[domainName], "Domain already registered");
        require(bytes(domainName).length > 0 && bytes(domainName).length <= 255, "Invalid domain name");

        bytes32 verificationHash = keccak256(
            abi.encodePacked(domainName, msg.sender, block.timestamp)
        );

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);

        domainMetadata[newTokenId] = DomainMetadata({
            domainName: domainName,
            originalOwner: msg.sender,
            createdAt: block.timestamp,
            price: initialPrice,
            verificationHash: verificationHash
        });

        domainExists[domainName] = true;
        domainToTokenId[domainName] = newTokenId;

        emit DomainMinted(newTokenId, domainName, msg.sender);

        return newTokenId;
    }

    // Update domain price
    function updateDomainPrice(
        uint256 tokenId, 
        uint256 newPrice
    ) external {
        require(ownerOf(tokenId) == msg.sender, "Not domain owner");
        
        domainMetadata[tokenId].price = newPrice;
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