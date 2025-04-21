# zkSync v29 Interop Proof of Concept

# Deploy contracts

L2-A (chain ID: 271):
```
forge script script/Scripts.s.sol:Deploy --zksync --rpc-url l2a --private-key=f12e28c0eb1ef4ff90478f6805b68d63737b7f33abfa091601140805da450d93 --broadcast
```

L2-B (chain ID: 260):
```
forge script script/Scripts.s.sol:Deploy  --zksync --rpc-url l2b --private-key=f12e28c0eb1ef4ff90478f6805b68d63737b7f33abfa091601140805da450d93 --broadcast
```

Which should deploy both contracts on different chains at the address `0x9E2d58E626e29641Cc5748007637Cc07D574228E`.

# Mint a Potato

On L2-A
```
forge script script/Scripts.s.sol:Mint --zksync --rpc-url l2a --private-key=f12e28c0eb1ef4ff90478f6805b68d63737b7f33abfa091601140805da450d93 --broadcast
```

On L2-B
```
forge script script/Scripts.s.sol:Mint --zksync --rpc-url l2b --private-key=f12e28c0eb1ef4ff90478f6805b68d63737b7f33abfa091601140805da450d93 --broadcast
```

# Throw a Potato

From L2-A to L2-B
```
forge script script/Scripts.s.sol:Throw --zksync --sig "run(uint256,uint32)" [potatoId] 260 --rpc-url l2a --private-key=f12e28c0eb1ef4ff90478f6805b68d63737b7f33abfa091601140805da450d93 --broadcast
```

From L2-B to L2-A
```
forge script script/Scripts.s.sol:Throw --zksync --sig "run(uint256,uint32)" [potatoId] 271 --rpc-url l2b --private-key=f12e28c0eb1ef4ff90478f6805b68d63737b7f33abfa091601140805da450d93 --broadcast
```

You must record the resulting transaction hash to later fetch the necessary interop Merkle proofs to catch the potato on the destination chain.

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
