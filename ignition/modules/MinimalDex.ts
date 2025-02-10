// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const MinimalDex = buildModule("MinimalDex", (m) => {
  const deployer = m.getAccount(0);
  const minimalDex = m.contract("MinimalDex", [deployer], {});

  return { minimalDex };
});

export default MinimalDex;
