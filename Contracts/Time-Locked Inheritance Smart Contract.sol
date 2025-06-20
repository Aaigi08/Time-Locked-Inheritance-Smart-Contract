// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Time-Locked Inheritance Smart Contract
 * @dev A comprehensive smart contract that enables digital inheritance with time-based locks and proof-of-life mechanisms
 * @author Digital Inheritance Development Team
 * @notice This contract allows users to create secure inheritance plans that automatically distribute assets to beneficiaries
 */
contract TimeLockedInheritance {
    
    // Custom errors for better gas efficiency
    error InsufficientFunds();
    error UnauthorizedAccess();
    error InvalidParameters();
    error InheritanceNotFound();
    error TimeLockNotExpired();
    error EmergencyModeActive();
    
    // Struct to store comprehensive inheritance details
    struct Inheritance {
        address owner;                    // Original owner of the inheritance
        address[] beneficiaries;          // List of beneficiary addresses
        uint256[] shares;                // Percentage shares for each beneficiary (sum = 100)
        uint256 lockDuration;            // Time in seconds after which inheritance can be claimed
        uint256 lastProofOfLife;         // Timestamp of the last proof of life submission
        uint256 totalAmount;             // Total ETH stored in the inheritance
        uint256 creationTime;            // Timestamp when inheritance was created
        bool isActive;                   // Whether the inheritance is currently active
        bool emergencyMode;              // Emergency recovery mode status
        address emergencyContact;        // Emergency contact for recovery situations
        string description;              // Optional description or message for beneficiaries
    }
    
    // State variables
    mapping(address => Inheritance) public inheritances;
    mapping(address => mapping(address => bool)) public authorizedBeneficiaries;
    mapping(address => uint256) public claimedAmounts;
    
    uint256 public constant MIN_LOCK_DURATION = 30 days;
    uint256 public constant MAX_LOCK_DURATION = 10 * 365 days; // 10 years
    uint256 public constant MAX_BENEFICIARIES = 20;
    
    // Events for transparency and logging
    event InheritanceCreated(
        address indexed owner, 
        uint256 amount, 
        uint256 lockDuration, 
        uint256 beneficiaryCount
    );
    event ProofOfLifeSubmitted(address indexed owner, uint256 timestamp);
    event InheritanceClaimed(address indexed beneficiary, address indexed owner, uint256 amount);
    event EmergencyRecoveryActivated(address indexed owner, address indexed emergencyContact);
    event EmergencyRecoveryDeactivated(address indexed owner);
    event InheritanceUpdated(address indexed owner, string updateType);
    event FundsAdded(address indexed owner, uint256 amount);
    
    // Modifiers for access control and validation
    modifier onlyInheritanceOwner(address _owner) {
        if (msg.sender != _owner) revert UnauthorizedAccess();
        _;
    }
    
    modifier validBeneficiary(address _owner) {
        if (!authorizedBeneficiaries[_owner][msg.sender]) revert UnauthorizedAccess();
        _;
    }
    
    modifier inheritanceExists(address _owner) {
        if (inheritances[_owner].owner == address(0)) revert InheritanceNotFound();
        _;
    }
    
    modifier notInEmergencyMode(address _owner) {
        if (inheritances[_owner].emergencyMode) revert EmergencyModeActive();
        _;
    }
    
    /**
     * @dev Core Function 1: Create and fund an inheritance with comprehensive time-lock mechanism
     * @param _beneficiaries Array of beneficiary addresses who will receive the inheritance
     * @param _shares Array of percentage shares for each beneficiary (must sum to 100)
     * @param _lockDuration Time in seconds after which inheritance can be claimed if no proof of life
     * @param _emergencyContact Address designated for emergency recovery operations
     * @param _description Optional description or message for beneficiaries
     * @notice Requires sending ETH with the transaction to fund the inheritance
     * @notice Lock duration must be between 30 days and 10 years
     */
    function createInheritance(
        address[] calldata _beneficiaries,
        uint256[] calldata _shares,
        uint256 _lockDuration,
        address _emergencyContact,
        string calldata _description
    ) external payable {
        // Input validation
        if (msg.value == 0) revert InsufficientFunds();
        if (_beneficiaries.length == 0 || _beneficiaries.length > MAX_BENEFICIARIES) {
            revert InvalidParameters();
        }
        if (_beneficiaries.length != _shares.length) revert InvalidParameters();
        if (_lockDuration < MIN_LOCK_DURATION || _lockDuration > MAX_LOCK_DURATION) {
            revert InvalidParameters();
        }
        if (_emergencyContact == address(0)) revert InvalidParameters();
        if (inheritances[msg.sender].owner != address(0)) revert InvalidParameters();
        
        // Validate shares sum to 100 and authorize beneficiaries
        uint256 totalShares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            if (_beneficiaries[i] == address(0)) revert InvalidParameters();
            if (_shares[i] == 0) revert InvalidParameters();
            totalShares += _shares[i];
            authorizedBeneficiaries[msg.sender][_beneficiaries[i]] = true;
        }
        if (totalShares != 100) revert InvalidParameters();
        
        // Create inheritance with comprehensive details
        inheritances[msg.sender] = Inheritance({
            owner: msg.sender,
            beneficiaries: _beneficiaries,
            shares: _shares,
            lockDuration: _lockDuration,
            lastProofOfLife: block.timestamp,
            totalAmount: msg.value,
            creationTime: block.timestamp,
            isActive: true,
            emergencyMode: false,
            emergencyContact: _emergencyContact,
            description: _description
        });
        
        // Update contract statistics
        totalActiveInheritances++;
        totalValueLocked += msg.value;
        
        emit InheritanceCreated(msg.sender, msg.value, _lockDuration, _beneficiaries.length);
    }
    
    /**
     * @dev Core Function 2: Submit proof of life to reset the inheritance timer
     * @notice Owner must call this function periodically to prevent inheritance from being claimed
     * @notice Resets the lastProofOfLife timestamp to current block timestamp
     */
    function submitProofOfLife() external {
        Inheritance storage inheritance = inheritances[msg.sender];
        
        if (inheritance.owner != msg.sender) revert InheritanceNotFound();
        if (!inheritance.isActive) revert InvalidParameters();
        if (inheritance.emergencyMode) revert EmergencyModeActive();
        
        inheritance.lastProofOfLife = block.timestamp;
        
        emit ProofOfLifeSubmitted(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Core Function 3: Claim inheritance after time lock expires
     * @param _owner Address of the inheritance owner whose assets are being claimed
     * @notice Can only be called by authorized beneficiaries after the time lock period
     * @notice Automatically calculates and transfers the beneficiary's designated share
     */
    function claimInheritance(address _owner) external 
        inheritanceExists(_owner) 
        validBeneficiary(_owner) 
        notInEmergencyMode(_owner)
    {
        Inheritance storage inheritance = inheritances[_owner];
        
        if (!inheritance.isActive) revert InvalidParameters();
        if (block.timestamp < inheritance.lastProofOfLife + inheritance.lockDuration) {
            revert TimeLockNotExpired();
        }
        if (claimedAmounts[msg.sender] > 0) revert InvalidParameters(); // Prevent double claiming
        
        // Find beneficiary's share
        uint256 beneficiaryShare = 0;
        for (uint256 i = 0; i < inheritance.beneficiaries.length; i++) {
            if (inheritance.beneficiaries[i] == msg.sender) {
                beneficiaryShare = inheritance.shares[i];
                break;
            }
        }
        
        if (beneficiaryShare == 0) revert InvalidParameters();
        
        // Calculate amount to transfer
        uint256 claimAmount = (inheritance.totalAmount * beneficiaryShare) / 100;
        
        // Update state before transfer (CEI pattern)
        claimedAmounts[msg.sender] = claimAmount;
        inheritance.totalAmount -= claimAmount;
        totalValueLocked -= claimAmount;
        
        // Remove beneficiary authorization to prevent future claims
        authorizedBeneficiaries[_owner][msg.sender] = false;
        
        // Check if all funds have been claimed
        if (inheritance.totalAmount == 0) {
            inheritance.isActive = false;
            totalActiveInheritances--;
        }
        
        // Transfer funds (interaction last)
        (bool success, ) = payable(msg.sender).call{value: claimAmount}("");
        if (!success) revert InsufficientFunds();
        
        emit InheritanceClaimed(msg.sender, _owner, claimAmount);
    }
    
    /**
     * @dev Add additional funds to an existing inheritance
     * @notice Only the inheritance owner can add more funds
     */
    function addFunds() external payable inheritanceExists(msg.sender) {
        if (msg.value == 0) revert InsufficientFunds();
        
        Inheritance storage inheritance = inheritances[msg.sender];
        if (!inheritance.isActive) revert InvalidParameters();
        
        inheritance.totalAmount += msg.value;
        totalValueLocked += msg.value;
        
        emit FundsAdded(msg.sender, msg.value);
    }
    
    /**
     * @dev Emergency recovery activation - can only be called by emergency contact
     * @param _owner Address of the inheritance owner
     * @notice Activates emergency mode to pause all inheritance claiming
     */
    function activateEmergencyRecovery(address _owner) external inheritanceExists(_owner) {
        Inheritance storage inheritance = inheritances[_owner];
        
        if (msg.sender != inheritance.emergencyContact) revert UnauthorizedAccess();
        if (!inheritance.isActive) revert InvalidParameters();
        if (inheritance.emergencyMode) revert EmergencyModeActive();
        
        inheritance.emergencyMode = true;
        
        emit EmergencyRecoveryActivated(_owner, msg.sender);
    }
    
    /**
     * @dev Deactivate emergency recovery mode
     * @notice Can be called by either the owner or emergency contact
     */
    function deactivateEmergencyRecovery() external inheritanceExists(msg.sender) {
        Inheritance storage inheritance = inheritances[msg.sender];
        
        if (msg.sender != inheritance.owner && msg.sender != inheritance.emergencyContact) {
            revert UnauthorizedAccess();
        }
        if (!inheritance.emergencyMode) revert InvalidParameters();
        
        inheritance.emergencyMode = false;
        
        emit EmergencyRecoveryDeactivated(msg.sender);
    }
    
    /**
     * @dev Get comprehensive inheritance details for a specific owner
     * @param _owner Address of the inheritance owner
     * @return owner Address of the inheritance owner
     * @return beneficiaries Array of beneficiary addresses
     * @return shares Array of percentage shares for each beneficiary
     * @return lockDuration Time in seconds for the inheritance lock period
     * @return lastProofOfLife Timestamp of the last proof of life submission
     * @return totalAmount Total ETH amount currently stored in the inheritance
     * @return creationTime Timestamp when the inheritance was created
     * @return isActive Whether the inheritance is currently active and operational
     * @return emergencyMode Whether emergency recovery mode is currently activated
     * @return emergencyContact Address of the designated emergency contact
     * @return description Optional description or message for beneficiaries
     */
    function getInheritanceDetails(address _owner) external view returns (
        address owner,
        address[] memory beneficiaries,
        uint256[] memory shares,
        uint256 lockDuration,
        uint256 lastProofOfLife,
        uint256 totalAmount,
        uint256 creationTime,
        bool isActive,
        bool emergencyMode,
        address emergencyContact,
        string memory description
    ) {
        Inheritance memory inheritance = inheritances[_owner];
        return (
            inheritance.owner,
            inheritance.beneficiaries,
            inheritance.shares,
            inheritance.lockDuration,
            inheritance.lastProofOfLife,
            inheritance.totalAmount,
            inheritance.creationTime,
            inheritance.isActive,
            inheritance.emergencyMode,
            inheritance.emergencyContact,
            inheritance.description
        );
    }
    
    /**
     * @dev Check if inheritance can currently be claimed by beneficiaries
     * @param _owner Address of the inheritance owner
     * @return claimable Boolean indicating if inheritance can be claimed now
     */
    function canClaimInheritance(address _owner) external view returns (bool claimable) {
        Inheritance memory inheritance = inheritances[_owner];
        
        if (!inheritance.isActive || inheritance.emergencyMode || inheritance.totalAmount == 0) {
            return false;
        }
        
        return block.timestamp >= inheritance.lastProofOfLife + inheritance.lockDuration;
    }
    
    /**
     * @dev Get time remaining until inheritance becomes claimable
     * @param _owner Address of the inheritance owner
     * @return timeRemaining Seconds remaining until claimable, 0 if can be claimed now
     */
    function getTimeUntilClaimable(address _owner) external view returns (uint256 timeRemaining) {
        Inheritance memory inheritance = inheritances[_owner];
        
        if (!inheritance.isActive || inheritance.totalAmount == 0) {
            return 0;
        }
        
        uint256 claimableTime = inheritance.lastProofOfLife + inheritance.lockDuration;
        
        if (block.timestamp >= claimableTime) {
            return 0;
        }
        
        return claimableTime - block.timestamp;
    }
    
    /**
     * @dev Get the share percentage for a specific beneficiary
     * @param _owner Address of the inheritance owner
     * @param _beneficiary Address of the beneficiary
     * @return sharePercentage Percentage share of the beneficiary (0-100)
     */
    function getBeneficiaryShare(address _owner, address _beneficiary) external view returns (uint256 sharePercentage) {
        Inheritance memory inheritance = inheritances[_owner];
        
        for (uint256 i = 0; i < inheritance.beneficiaries.length; i++) {
            if (inheritance.beneficiaries[i] == _beneficiary) {
                return inheritance.shares[i];
            }
        }
        
        return 0;
    }
    
    /**
     * @dev Emergency withdrawal function - only for contract owner in extreme cases
     * @notice This function should only be used in case of critical bugs or security issues
     */
    function emergencyWithdraw() external {
        // This function would typically be restricted to contract owner/admin
        // Implementation depends on your specific security requirements
        // For now, it's left as a placeholder for future security enhancements
    }
    
    // State variables for contract statistics
    uint256 public totalActiveInheritances;
    uint256 public totalValueLocked;
    
    /**
     * @dev Get contract statistics for transparency
     * @return activeInheritances Total number of currently active inheritances
     * @return valueLocked Total ETH currently locked in all inheritances
     */
    function getContractStats() external view returns (uint256 activeInheritances, uint256 valueLocked) {
        return (totalActiveInheritances, totalValueLocked);
    }
}
