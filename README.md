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
```

Then, spin up the local networks:

```
zkstack dev clean containers && zkstack up -o false
zkstack dev contracts

zkstack dev generate-genesis

zkstack ecosystem init --dev --observability=false --update-submodules false

zkstack chain convert-to-gateway --chain gateway --ignore-prerequisites
zkstack server --ignore-prerequisites --chain gateway &> ./gateway.log & 

zkstack server wait --ignore-prerequisites --verbose --chain gateway
zkstack chain migrate-to-gateway --chain era --gateway-chain-name gateway
zkstack chain migrate-to-gateway --chain second --gateway-chain-name gateway

zkstack server --ignore-prerequisites --chain era &> ./rollup.log &

zkstack server --ignore-prerequisites --chain second &> ./second.log &
```

> [!NOTE]
> You may need to run the above commands twice if you encounter some issues.

This will start three local networks: `gateway` (which will act as the settlement layer), `era` and `second`. Using interop, `era` (L2-A) and `second` (L2-B) will be able to communicate with each other.

### Deploying the contracts

We will deploy the same contract on both networks: L2-A and L2-B.

```
forge script script/Deploy.s.sol:Deploy -r l2a --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
forge script script/Deploy.s.sol:Deploy -r l2b --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Running the integration tests

```
yarn install
yarn test
```



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
