// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DomainChainTreasury is Ownable, ReentrancyGuard {
    // Fixed and dynamic fee structures
    uint256 public constant BASE_VERIFICATION_FEE = 0.001 ether;
    uint256 public platformFeePercentage = 250; // 2.5%

    // Tracking funds and providers
    mapping(address => bool) public authorizedAPIProviders;
    mapping(address => uint256) public providerFunds;
    mapping(address => uint256) public platformFees;

    // Events for transparency and tracking
    event VerificationFeePaid(address indexed payer, uint256 amount);
    event PlatformFeeCollected(address indexed collection, uint256 amount);
    event APIProviderAdded(address indexed provider);
    event APIProviderRemoved(address indexed provider);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // Collect verification fee with dynamic pricing potential
function collectVerificationFee() external payable nonReentrant {
    require(msg.value >= BASE_VERIFICATION_FEE, "Insufficient fee");
    
    // Calculate platform fee
    uint256 platformFeeAmount = (msg.value * platformFeePercentage) / 10000;

    // Distribute fees
    platformFees[owner()] += platformFeeAmount;
    
    emit VerificationFeePaid(msg.sender, msg.value);
    emit PlatformFeeCollected(owner(), platformFeeAmount);
}

    // Flexible provider fund allocation
    function allocateProviderFunds(address provider, uint256 amount) external onlyOwner {
        providerFunds[provider] += amount;
    }

    // Provider fund withdrawal
    function withdrawProviderFunds() external nonReentrant {
        uint256 funds = providerFunds[msg.sender];
        require(funds > 0, "No funds available");

        providerFunds[msg.sender] = 0;
        payable(msg.sender).transfer(funds);

        emit FundsWithdrawn(msg.sender, funds);
    }

    // Platform fee withdrawal
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        uint256 fees = platformFees[owner()];
        require(fees > 0, "No platform fees available");

        platformFees[owner()] = 0;
        payable(owner()).transfer(fees);

        emit FundsWithdrawn(owner(), fees);
    }

    // Manage API providers
    function addAPIProvider(address provider) external onlyOwner {
        authorizedAPIProviders[provider] = true;
        emit APIProviderAdded(provider);
    }

    function removeAPIProvider(address provider) external onlyOwner {
        authorizedAPIProviders[provider] = false;
        emit APIProviderRemoved(provider);
    }

    // Adjustable platform fee
    function updatePlatformFeePercentage(uint256 newFeePercentage) external onlyOwner {
        require(newFeePercentage <= 500, "Fee cannot exceed 5%");
        platformFeePercentage = newFeePercentage;
    }

    // Fallback and receive functions
    receive() external payable {}
    fallback() external payable {}
}