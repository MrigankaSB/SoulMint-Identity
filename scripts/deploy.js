const { ethers } = require("hardhat");

async function main() {
  const SoulMintIdentity = await ethers.getContractFactory("SoulMintIdentity");
  const soulMintIdentity = await SoulMintIdentity.deploy();

  await soulMintIdentity.deployed();

  console.log("SoulMintIdentity contract deployed to:", soulMintIdentity.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
