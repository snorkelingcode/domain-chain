// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DomainChainToken is ERC20, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Reward configurations with more flexible parameters
    uint256 public constant BASE_REWARD_PERCENTAGE = 5; // 0.05%
    uint256 public constant MAX_SUPPLY = 100_000_000 * 10**18; // 100 million tokens

    // Staking and governance parameters
    uint256 public rewardMultiplier = 1;

    constructor() ERC20("DomainChain", "DCH") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        // Initial mint to contract owner
        _mint(msg.sender, 1_000_000 * 10**18);
    }

    // Simplified and more gas-efficient reward calculation
    function calculateReward(
        uint256 transactionAmount
    ) public view returns (uint256) {
        return transactionAmount
            .mul(BASE_REWARD_PERCENTAGE)
            .mul(rewardMultiplier)
            .div(10000);
    }

    // Batch reward minting to reduce individual transaction costs
    function batchMintRewards(
        address[] memory recipients, 
        uint256[] memory amounts
    ) external onlyRole(MINTER_ROLE) {
        require(
            recipients.length == amounts.length, 
            "Mismatched array lengths"
        );
        
        uint256 totalRewardAmount = 0;
        
        for (uint i = 0; i < recipients.length; i++) {
            uint256 rewardAmount = calculateReward(amounts[i]);
            
            // Validate total supply before minting
            require(
                totalSupply().add(rewardAmount) <= MAX_SUPPLY, 
                "Exceeds maximum token supply"
            );
            
            totalRewardAmount += rewardAmount;
            _mint(recipients[i], rewardAmount);
        }
    }

    // Flexible reward minting for single transactions
    function mintRewards(
        address recipient, 
        uint256 transactionAmount
    ) external onlyRole(MINTER_ROLE) {
        uint256 rewardAmount = calculateReward(transactionAmount);
        
        // Check total supply before minting
        require(
            totalSupply().add(rewardAmount) <= MAX_SUPPLY, 
            "Exceeds maximum token supply"
        );
        
        _mint(recipient, rewardAmount);
    }

    // Adjust reward multiplier for dynamic incentives
    function updateRewardMultiplier(
        uint256 newMultiplier
    ) external onlyRole(ADMIN_ROLE) {
        require(newMultiplier > 0, "Invalid multiplier");
        rewardMultiplier = newMultiplier;
    }

    // Allow burning of tokens for governance or special benefits
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}