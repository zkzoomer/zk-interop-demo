# zkSync v29 Interop Proof of Concept

This repo is a simple proof of concept and first application using zkSync v29's interop feature: an interop game of _hot potato_.

## Building the contracts

```
forge build --zksync
``` 

Optionally run unit tests:

```
forge test --zksync
```

## Integration tests

### Local networks
As of writing, interop is not yet live on zkSync, meaning you will have to spin up your own local networks. First, clone the repo and checkout the branch with reduced interop support:

```
git clone https://github.com/matter-labs/zksync-era --recurse-submodules
cd zksync-era
git checkout kl/reduced-interop-support
git submodule update

# You will also need to install `zkstack` from source
./zkstack_cli/zkstackup/install -g --path ./zkstack_cli/zkstackup/zkstackup || true
env "PATH=$PATH" zkstackup -g --local
```

Then, spin up the local networks:

```
zkstack dev clean containers && zkstack up -o false
zkstack dev contracts

zkstack ecosystem init --dev --observability=false --update-submodules false
zkstack dev generate-genesis
rm -rf ./chains/era/configs/*
rm -rf ./chains/second/configs/*
rm -rf ./chains/gateway/configs/*
cat ./etc/env/file_based/genesis.yaml
zkstack ecosystem init --dev --observability=false --update-submodules false

zkstack chain gateway convert-to-gateway --chain gateway --ignore-prerequisites
zkstack server --ignore-prerequisites --chain gateway &> ./gateway.log & 
zkstack server wait --ignore-prerequisites --verbose --chain gateway

zkstack chain gateway migrate-to-gateway --chain era --gateway-chain-name gateway
zkstack chain gateway migrate-to-gateway --chain second --gateway-chain-name gateway

zkstack server --ignore-prerequisites --chain era &> ./rollup.log &
zkstack server --ignore-prerequisites --chain second &> ./second.log &
```

> [!NOTE]
> You may need to run the above commands twice if you encounter some issues.

This will start three local networks: `gateway` (which will act as the settlement layer), `era` and `second`. Using interop, `era` (L2-A) and `second` (L2-B) will be able to communicate with each other.

### Deploying the contracts

We will deploy the same contract on both networks: L2-A and L2-B.

```
forge script script/Deploy.s.sol:Deploy --rpc-url l2a --zksync --broadcast --private-key 0xf12e28c0eb1ef4ff90478f6805b68d63737b7f33abfa091601140805da450d93
forge script script/Deploy.s.sol:Deploy --rpc-url l2b --zksync --broadcast --private-key 0xf12e28c0eb1ef4ff90478f6805b68d63737b7f33abfa091601140805da450d93
```

Which should deploy the contract on both networks at the same address: `0x9E2d58E626e29641Cc5748007637Cc07D574228E`.

### Running the integration tests

```
yarn install
yarn test
```

> [!NOTE]
> Tests are flaky and may fail. Run them multiple times if they fail.


<!-- ## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
``` -->
