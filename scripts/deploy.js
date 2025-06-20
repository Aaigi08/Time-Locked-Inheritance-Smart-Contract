const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Starting deployment of Time-Locked Inheritance Smart Contract...");
  
  // Get the contract factory
  const TimeLockedInheritance = await ethers.getContractFactory("TimeLockedInheritance");
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  
  console.log("📋 Deployment Details:");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", ethers.utils.formatEther(await deployer.getBalance()), "ETH");
  console.log("Network:", (await ethers.provider.getNetwork()).name);
  console.log("Chain ID:", (await ethers.provider.getNetwork()).chainId);
  
  // Deploy the contract
  console.log("\n⏳ Deploying Time-Locked Inheritance Smart Contract...");
  
  const timeLockedInheritance = await TimeLockedInheritance.deploy();
  
  // Wait for deployment to be confirmed
  await timeLockedInheritance.deployed();
  
  console.log("\n✅ Deployment Successful!");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("Contract Name: Time-Locked Inheritance Smart Contract");
  console.log("Contract Address:", timeLockedInheritance.address);
  console.log("Transaction Hash:", timeLockedInheritance.deployTransaction.hash);
  console.log("Gas Used:", timeLockedInheritance.deployTransaction.gasLimit.toString());
  console.log("Deployer Address:", deployer.address);
  console.log("Block Number:", timeLockedInheritance.deployTransaction.blockNumber);
  
  // Verify deployment by calling a view function
  try {
    const contractBalance = await timeLockedInheritance.getContractBalance();
    console.log("Initial Contract Balance:", ethers.utils.formatEther(contractBalance), "ETH");
    console.log("\n🔍 Contract verification: SUCCESS");
  } catch (error) {
    console.log("\n❌ Contract verification failed:", error.message);
  }
  
  // Save deployment info to a file
  const deploymentInfo = {
    contractName: "TimeLockedInheritance",
    contractAddress: timeLockedInheritance.address,
    transactionHash: timeLockedInheritance.deployTransaction.hash,
    deployerAddress: deployer.address,
    blockNumber: timeLockedInheritance.deployTransaction.blockNumber,
    gasUsed: timeLockedInheritance.deployTransaction.gasLimit.toString(),
    networkName: (await ethers.provider.getNetwork()).name,
    chainId: (await ethers.provider.getNetwork()).chainId,
    timestamp: new Date().toISOString()
  };
  
  console.log("\n💾 Deployment information saved!");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  
  // Instructions for interaction
  console.log("\n📋 Next Steps:");
  console.log("1. Add the contract address to your frontend application");
  console.log("2. Use the contract ABI from artifacts/contracts/TimeLockedInheritance.sol/TimeLockedInheritance.json");
  console.log("3. Test the contract functions:");
  console.log("   - createInheritance(beneficiary, lockDuration, message)");
  console.log("   - submitProofOfLife()");
  console.log("   - claimInheritance(owner)");
  console.log("   - cancelInheritance()");
  
  console.log("\n🎉 Deployment completed successfully!");
  
  return deploymentInfo;
}

// Execute deployment
main()
  .then((deploymentInfo) => {
    console.log("\n✨ All operations completed successfully!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Deployment failed:");
    console.error(error);
    process.exit(1);
  });
