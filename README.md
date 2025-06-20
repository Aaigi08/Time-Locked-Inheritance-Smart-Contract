# Time-Locked Inheritance Smart Contract

## Project Description

The Time-Locked Inheritance Smart Contract is a revolutionary blockchain-based solution that enables secure digital inheritance management. This smart contract allows users to create inheritance plans that automatically distribute their digital assets to designated beneficiaries after a specified period of inactivity, eliminating the need for traditional legal processes while ensuring asset security and proper distribution.

The contract implements a "proof of life" mechanism where the owner must periodically interact with the contract to prove they are still active. If the owner fails to submit proof of life within the specified time frame, beneficiaries can claim their designated shares of the inheritance.

## Project Vision

Our vision is to democratize and modernize inheritance planning by leveraging blockchain technology to create a trustless, transparent, and automated inheritance system. We aim to:

- **Eliminate Traditional Barriers**: Remove the need for expensive legal processes and intermediaries
- **Ensure Asset Security**: Provide cryptographic security for digital assets during the inheritance process
- **Enable Global Access**: Make inheritance planning accessible to anyone with an internet connection
- **Promote Financial Inclusion**: Extend inheritance planning to underbanked populations worldwide
- **Foster Trust**: Create a transparent system where all parties can verify the inheritance terms

## Key Features

### 🔐 **Time-Locked Security**
- Configurable time-lock periods (minimum 30 days) before inheritance can be claimed
- Automatic inheritance activation when proof of life expires
- Secure fund storage with smart contract escrow mechanism

### 👥 **Multi-Beneficiary Support**
- Support for multiple beneficiaries with customizable percentage shares
- Proportional distribution ensuring total shares equal 100%
- Individual claiming mechanism for each beneficiary

### 💓 **Proof of Life Mechanism**
- Regular proof of life submissions to reset inheritance timers
- Flexible timing allowing owners to maintain control of their assets
- Simple one-click proof of life submission process

### 🚨 **Emergency Recovery System**
- Designated emergency contacts for crisis situations
- Emergency mode activation to pause inheritance claiming
- Additional security layer for unexpected circumstances

### 📊 **Transparent Tracking**
- Real-time inheritance status monitoring
- Detailed event logging for all contract interactions
- Public verification of inheritance terms and conditions

### 🔍 **Query Functions**
- Check inheritance claimability status
- Calculate time remaining until assets become claimable
- Retrieve complete inheritance details and beneficiary information

## Future Scope

### Phase 1: Enhanced Security Features
- **Multi-Signature Requirements**: Implement multi-sig wallets for large inheritances
- **Biometric Integration**: Add biometric proof of life verification
- **Legal Document Storage**: IPFS integration for storing legal documents and wills

### Phase 2: Advanced Asset Management
- **ERC-20 Token Support**: Extend support to various cryptocurrency tokens
- **NFT Inheritance**: Enable inheritance of non-fungible tokens and digital collectibles
- **Real Estate Tokenization**: Support for tokenized real estate and physical assets

### Phase 3: Governance and Community Features
- **Dispute Resolution**: Implement decentralized arbitration for inheritance disputes
- **Community Validation**: Peer-to-peer proof of life validation systems
- **Inheritance Insurance**: Optional insurance coverage for inheritance contracts

### Phase 4: Enterprise and Institutional Adoption
- **Corporate Succession Planning**: Enterprise-grade solutions for business succession
- **Integration APIs**: RESTful APIs for integration with existing financial systems
- **Regulatory Compliance**: KYC/AML integration for institutional adoption

### Phase 5: Global Expansion
- **Multi-Chain Support**: Deploy across multiple blockchain networks
- **Localization**: Support for multiple languages and regional legal requirements
- **Mobile Applications**: Native mobile apps for easier accessibility

### Technology Enhancements
- **Layer 2 Integration**: Reduce gas costs through Layer 2 solutions
- **Oracle Integration**: Real-world data feeds for enhanced functionality
- **AI-Powered Insights**: Machine learning for inheritance planning optimization

## Getting Started

### Prerequisites
- Node.js (v14 or higher)
- Hardhat or Truffle development environment
- MetaMask or similar Web3 wallet

### Installation
```bash
git clone https://github.com/your-repo/time-locked-inheritance
cd time-locked-inheritance
npm install
```

### Deployment
```bash
npx hardhat compile
npx hardhat deploy --network <your-network>
```

### Usage Examples
```javascript
// Create inheritance
await contract.createInheritance(
    [beneficiary1, beneficiary2], 
    [60, 40], 
    2592000, // 30 days
    emergencyContact,
    { value: ethers.utils.parseEther("1.0") }
);

// Submit proof of life

await contract.submitProofOfLife();

// Claim inheritance (as beneficiary)
await contract.claimInheritance(ownerAddress);
```

## Contributing
We welcome contributions from the community! Please read our contributing guidelines and submit pull requests for any improvements.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer
This smart contract is for educational and experimental purposes. Please conduct thorough testing and security audits before using in production environments. Always consult with legal professionals for inheritance planning.


Contract address: 0x039effc5da60056b9870d717ae3d39a3c03543d5


![Screenshot 2025-06-20 144915](https://github.com/user-attachments/assets/c62bb31c-9e94-49eb-a715-d2fa22bcf271)
![Screenshot 2025-06-20 144801](https://github.com/user-attachments/assets/236a2c26-c5c0-45cb-b7cf-69086fb0be37)

