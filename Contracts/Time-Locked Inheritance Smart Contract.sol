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
        address owner;
        address[] beneficiaries;
        uint256[] shares;
        uint256 lockDuration;
        uint256 lastProofOfLife;
        uint256 totalAmount;
        uint256 creationTime;
        bool isActive;
        bool emergencyMode;
        address emergencyContact;
        string description;
    }
    
    // State variables
    mapping(address => Inheritance) public inheritances;
    mapping(address => mapping(address => bool)) public authorizedBeneficiaries;
    mapping(address => uint256) public claimedAmounts;
    
    uint256 public constant MIN_LOCK_DURATION = 30 days;
    uint256 public constant MAX_LOCK_DURATION = 10 * 365 days; // 10 years
    uint256 public constant MAX_BENEFICIARIES = 20;
    
    uint256 public totalActiveInheritances;
    uint256 public totalValueLocked;
    
    // Events
    event InheritanceCreated(address indexed owner, uint256 amount, uint256 lockDuration, uint256 beneficiaryCount);
    event ProofOfLifeSubmitted(address indexed owner, uint256 timestamp);
    event InheritanceClaimed(address indexed beneficiary, address indexed owner, uint256 amount);
    event EmergencyRecoveryActivated(address indexed owner, address indexed emergencyContact);
    event EmergencyRecoveryDeactivated(address indexed owner);
    event InheritanceUpdated(address indexed owner, string updateType);
    event FundsAdded(address indexed owner, uint256 amount);
    
    // Modifiers
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

    function createInheritance(
        address[] calldata _beneficiaries,
        uint256[] calldata _shares,
        uint256 _lockDuration,
        address _emergencyContact,
        string calldata _description
    ) external payable {
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
        
        uint256 totalShares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            if (_beneficiaries[i] == address(0)) revert InvalidParameters();
            if (_shares[i] == 0) revert InvalidParameters();
            totalShares += _shares[i];
            authorizedBeneficiaries[msg.sender][_beneficiaries[i]] = true;
        }
        if (totalShares != 100) revert InvalidParameters();
        
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
        
        totalActiveInheritances++;
        totalValueLocked += msg.value;
        
        emit InheritanceCreated(msg.sender, msg.value, _lockDuration, _beneficiaries.length);
    }

    function submitProofOfLife() external {
        Inheritance storage inheritance = inheritances[msg.sender];
        
        if (inheritance.owner != msg.sender) revert InheritanceNotFound();
        if (!inheritance.isActive) revert InvalidParameters();
        if (inheritance.emergencyMode) revert EmergencyModeActive();
        
        inheritance.lastProofOfLife = block.timestamp;
        
        emit ProofOfLifeSubmitted(msg.sender, block.timestamp);
    }

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
        if (claimedAmounts[msg.sender] > 0) revert InvalidParameters();
        
        uint256 beneficiaryShare = 0;
        for (uint256 i = 0; i < inheritance.beneficiaries.length; i++) {
            if (inheritance.beneficiaries[i] == msg.sender) {
                beneficiaryShare = inheritance.shares[i];
                break;
            }
        }
        
        if (beneficiaryShare == 0) revert InvalidParameters();
        
        uint256 claimAmount = (inheritance.totalAmount * beneficiaryShare) / 100;
        
        claimedAmounts[msg.sender] = claimAmount;
        inheritance.totalAmount -= claimAmount;
        totalValueLocked -= claimAmount;
        
        authorizedBeneficiaries[_owner][msg.sender] = false;
        
        if (inheritance.totalAmount == 0) {
            inheritance.isActive = false;
            totalActiveInheritances--;
        }
        
        (bool success, ) = payable(msg.sender).call{value: claimAmount}("");
        if (!success) revert InsufficientFunds();
        
        emit InheritanceClaimed(msg.sender, _owner, claimAmount);
    }

    function addFunds() external payable inheritanceExists(msg.sender) {
        if (msg.value == 0) revert InsufficientFunds();
        
        Inheritance storage inheritance = inheritances[msg.sender];
        if (!inheritance.isActive) revert InvalidParameters();
        
        inheritance.totalAmount += msg.value;
        totalValueLocked += msg.value;
        
        emit FundsAdded(msg.sender, msg.value);
    }

    function activateEmergencyRecovery(address _owner) external inheritanceExists(_owner) {
        Inheritance storage inheritance = inheritances[_owner];
        
        if (msg.sender != inheritance.emergencyContact) revert UnauthorizedAccess();
        if (!inheritance.isActive) revert InvalidParameters();
        if (inheritance.emergencyMode) revert EmergencyModeActive();
        
        inheritance.emergencyMode = true;
        
        emit EmergencyRecoveryActivated(_owner, msg.sender);
    }

    function deactivateEmergencyRecovery() external inheritanceExists(msg.sender) {
        Inheritance storage inheritance = inheritances[msg.sender];
        
        if (msg.sender != inheritance.owner && msg.sender != inheritance.emergencyContact) {
            revert UnauthorizedAccess();
        }
        if (!inheritance.emergencyMode) revert InvalidParameters();
        
        inheritance.emergencyMode = false;
        
        emit EmergencyRecoveryDeactivated(msg.sender);
    }

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

    function canClaimInheritance(address _owner) external view returns (bool claimable) {
        Inheritance memory inheritance = inheritances[_owner];
        
        if (!inheritance.isActive || inheritance.emergencyMode || inheritance.totalAmount == 0) {
            return false;
        }
        
        return block.timestamp >= inheritance.lastProofOfLife + inheritance.lockDuration;
    }

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

    function getBeneficiaryShare(address _owner, address _beneficiary) external view returns (uint256 sharePercentage) {
        Inheritance memory inheritance = inheritances[_owner];
        
        for (uint256 i = 0; i < inheritance.beneficiaries.length; i++) {
            if (inheritance.beneficiaries[i] == _beneficiary) {
                return inheritance.shares[i];
            }
        }
        
        return 0;
    }

    function getContractStats() external view returns (uint256 activeInheritances, uint256 valueLocked) {
        return (totalActiveInheritances, totalValueLocked);
    }

    // 🔥 NEW FUNCTION: Update beneficiaries and their shares
    function updateBeneficiaries(
        address[] calldata _newBeneficiaries,
        uint256[] calldata _newShares
    ) external inheritanceExists(msg.sender) onlyInheritanceOwner(msg.sender) notInEmergencyMode(msg.sender) {
        if (_newBeneficiaries.length == 0 || _newBeneficiaries.length > MAX_BENEFICIARIES) {
            revert InvalidParameters();
        }
        if (_newBeneficiaries.length != _newShares.length) {
            revert InvalidParameters();
        }

        uint256 totalShares = 0;
        Inheritance storage inheritance = inheritances[msg.sender];

        // Revoke old beneficiary access
        for (uint256 i = 0; i < inheritance.beneficiaries.length; i++) {
            authorizedBeneficiaries[msg.sender][inheritance.beneficiaries[i]] = false;
        }

        // Authorize new beneficiaries
        for (uint256 i = 0; i < _newBeneficiaries.length; i++) {
            if (_newBeneficiaries[i] == address(0) || _newShares[i] == 0) {
                revert InvalidParameters();
            }
            totalShares += _newShares[i];
            authorizedBeneficiaries[msg.sender][_newBeneficiaries[i]] = true;
        }

        if (totalShares != 100) revert InvalidParameters();

        inheritance.beneficiaries = _newBeneficiaries;
        inheritance.shares = _newShares;

        emit InheritanceUpdated(msg.sender, "BeneficiariesUpdated");
    }

    // Emergency withdraw placeholder
    function emergencyWithdraw() external {
        // Placeholder for critical admin recovery logic
    }
}
