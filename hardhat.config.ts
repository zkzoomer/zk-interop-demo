import '@matterlabs/hardhat-zksync-solc';

export default {
  zksolc: {
    version: '1.5.10',
    compilerSource: 'binary',
    settings: {
      enableEraVMExtensions: true
    }
  },
  networks: {
    hardhat: {
      zksync: true
    }
  },
  solidity: {
    version: '0.8.26',
    eraVersion: '1.0.1',
    settings: {
      evmVersion: 'cancun'
    }
  }
};
