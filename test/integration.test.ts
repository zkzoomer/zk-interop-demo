import * as zksync from 'zksync-ethers-interop-support';
import 'ethers';

// Import the HotPotato ABI
import HotPotatoABI from '../zkout/HotPotato.sol/HotPotato.json';

const ETH_ADDRESS_IN_CONTRACTS = '0x0000000000000000000000000000000000000001';
const HOT_POTATO_ADDRESS = '0x9E2d58E626e29641Cc5748007637Cc07D574228E';
const PRIVATE_KEY = '0xf12e28c0eb1ef4ff90478f6805b68d63737b7f33abfa091601140805da450d93';
const L2A_CHAIN_ID = 271
const L2B_CHAIN_ID = 260

describe('Integration', () => {
    let l1_provider: zksync.Provider;
    let l2a_provider: zksync.Provider;
    let l2b_provider: zksync.Provider;
    let aliceA: zksync.Wallet;
    let aliceB: zksync.Wallet;
    let hotPotatoA: zksync.Contract;
    let hotPotatoB: zksync.Contract;

    beforeAll(async () => {
        l1_provider = new zksync.Provider(
            'http://localhost:8545',
            undefined,
        );
        l2a_provider = new zksync.Provider(
            'http://localhost:3050',
            undefined,
        );
        l2b_provider = new zksync.Provider(
            'http://localhost:3150',
            undefined,
        );

        // Create wallets using the same private key but different providers
        aliceA = new zksync.Wallet(PRIVATE_KEY, l2a_provider);
        aliceB = new zksync.Wallet(PRIVATE_KEY, l2b_provider);

        hotPotatoA = new zksync.Contract(
            HOT_POTATO_ADDRESS,
            HotPotatoABI.abi,
            l2a_provider,
        );
        hotPotatoB = new zksync.Contract(
            HOT_POTATO_ADDRESS,
            HotPotatoABI.abi,
            l2b_provider,
        );
    });

    let potatoId: string;
    it('should mint a potato', async () => {
        const tx = await aliceA.sendTransaction({
            to: HOT_POTATO_ADDRESS,
            data: hotPotatoA.interface.encodeFunctionData('mintPotato'),
        });
        const receipt = await tx.wait();

        // Filter for the Transfer event from our HotPotato contract specifically
        const transferLog = receipt.logs.find(
            log => log.topics[0] === hotPotatoA.interface.getEvent('Transfer')?.topicHash &&
                log.address.toLowerCase() === HOT_POTATO_ADDRESS.toLowerCase()
        );
        if (!transferLog) throw new Error('Transfer event not found');
        potatoId = transferLog.topics[3]; // Fourth topic contains the potato ID
        console.log('Minted potato ID:', potatoId);
    });

    let thrownPotatoId: string;
    let txHash: string;
    it('should burn and throw a potato', async () => {
        const tx = await aliceA.sendTransaction({
            to: HOT_POTATO_ADDRESS,
            data: hotPotatoA.interface.encodeFunctionData('burnAndThrowPotato', [potatoId, L2B_CHAIN_ID]),
        });
        const receipt = await tx.wait();
        txHash = tx.hash;
        console.log('Tx hash:', txHash);

        // Filter for the PotatoThrown event from our HotPotato contract specifically
        const transferLog = receipt.logs.find(
            log => log.topics[0] === hotPotatoA.interface.getEvent('PotatoThrown')?.topicHash &&
                log.address.toLowerCase() === HOT_POTATO_ADDRESS.toLowerCase()
        );
        if (!transferLog) throw new Error('PotatoThrown event not found');
        thrownPotatoId = transferLog.topics[1]; // Second topic contains the thrown potato ID
        console.log('Thrown potato ID:', thrownPotatoId);

        // Filler transaction and break, this will _hopefully_ make the server execute the previous call
        await delay(10000);
        const fillerTx = await aliceA.sendTransaction({
            to: HOT_POTATO_ADDRESS,
            data: hotPotatoA.interface.encodeFunctionData('mintPotato'),
        });
        await fillerTx.wait();
        await delay(10000);
    });

    it('should catch and mint a potato', async () => {
        // Imports proof until GW's message root, needed for proof based interop.
        const params = await aliceA.getFinalizeWithdrawalParams(txHash, undefined, undefined, "gw_message_root");
        expect(params).toBeDefined();

        // Needed else the L2's view of GW's MessageRoot won't be updated
        await delay(10000);
        await (
            await aliceB.connectToL1(l1_provider).deposit({
                token: ETH_ADDRESS_IN_CONTRACTS,
                to: aliceB.address,
                amount: 1
            })
        ).wait();
        await delay(5000);

        const tx = await aliceB.sendTransaction({
            to: HOT_POTATO_ADDRESS,
            data: hotPotatoB.interface.encodeFunctionData('catchAndMintPotato', [
                L2A_CHAIN_ID,
                params.l1BatchNumber,
                params.l2MessageIndex,
                { txNumberInBatch: params.l2TxNumberInBlock, sender: params.sender, data: params.message },
                params.proof
            ]),
        });
        txHash = tx.hash;
        console.log('Tx hash:', txHash);
    });

    function delay(ms: number) {
        return new Promise((resolve) => setTimeout(resolve, ms));
    }
});
