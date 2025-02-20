// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDomainVerificationOracle {
    function verifyDomainOwnership(
        string memory domainName, 
        address owner
    ) external view returns (
        bool isValid,
        uint256 verificationTimestamp,
        bytes32 verificationProof
    );
}