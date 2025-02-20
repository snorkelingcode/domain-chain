// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./DomainChainToken.sol";
import "./DomainChainTreasury.sol";

contract UltraFastDomainEscrow is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    // External Contracts
    OptimizedDomainChainToken public rewardsToken;
    DomainChainTreasury public treasury;
    IERC721 public domainNFT;

    // Meta-Transaction Support
    mapping(bytes32 => bool) public processedTransactions;

    // Instant Transaction Struct
    struct InstantTransaction {
        uint256 tokenId;
        address seller;
        address buyer;
        uint256 price;
        uint256 timestamp;
    }

    // Constants
    uint256 public constant TRANSACTION_VALIDITY_PERIOD = 15 minutes;
    uint256 public constant PLATFORM_FEE_RATE = 250; // 2.5%

    // Events
    event InstantDomainTransfer(
        uint256 indexed tokenId, 
        address indexed seller, 
        address indexed buyer, 
        uint256 price
    );
    event MetaTransactionProcessed(
        bytes32 transactionHash, 
        address seller, 
        address buyer
    );

    constructor(
        address _rewardsTokenAddress,
        address _treasuryAddress,
        address _domainNFTAddress
    ) {
        rewardsToken = OptimizedDomainChainToken(_rewardsTokenAddress);
        treasury = DomainChainTreasury(payable(_treasuryAddress));
        domainNFT = IERC721(_domainNFTAddress);
    }

    // Instant Domain Transfer with Meta-Transaction Support
    function instantDomainTransfer(
        InstantTransaction memory transaction,
        bytes memory sellerSignature,
        bytes memory buyerSignature
    ) external payable nonReentrant {
        // Validate transaction parameters
        require(msg.value == transaction.price, "Incorrect payment");
        
        // Generate unique transaction hash
        bytes32 transactionHash = keccak256(
            abi.encodePacked(
                transaction.tokenId,
                transaction.seller,
                transaction.buyer,
                transaction.price,
                transaction.timestamp
            )
        );
        
        // Prevent replay attacks
        require(!processedTransactions[transactionHash], "Transaction already processed");
        require(
            block.timestamp <= transaction.timestamp + TRANSACTION_VALIDITY_PERIOD, 
            "Transaction expired"
        );

        // Verify seller's signature
        address recoveredSeller = transactionHash
            .toEthSignedMessageHash()
            .recover(sellerSignature);
        require(recoveredSeller == transaction.seller, "Invalid seller signature");

        // Verify buyer's signature
        address recoveredBuyer = transactionHash
            .toEthSignedMessageHash()
            .recover(buyerSignature);
        require(recoveredBuyer == transaction.buyer, "Invalid buyer signature");

        // Mark transaction as processed
        processedTransactions[transactionHash] = true;

        // Calculate platform fee
        uint256 platformFee = (transaction.price * PLATFORM_FEE_RATE) / 10000;
        uint256 sellerAmount = transaction.price - platformFee;

        // Transfer platform fee to treasury
        treasury.collectVerificationFee{value: platformFee}();

        // Transfer funds to seller
        (bool sellerPaid, ) = payable(transaction.seller).call{value: sellerAmount}("");
        require(sellerPaid, "Seller payment failed");

        // Transfer NFT to buyer
        domainNFT.transferFrom(transaction.seller, transaction.buyer, transaction.tokenId);

        // Mint rewards for buyer and seller
        rewardsToken.batchMintRewards(
            new address[](2), 
            new uint256[](2)
        );

        // Emit transfer event
        emit InstantDomainTransfer(
            transaction.tokenId, 
            transaction.seller, 
            transaction.buyer, 
            transaction.price
        );
    }

    // Fallback function
    receive() external payable {}
}