import * as zksync from 'zksync-ethers-interop-support';
import 'ethers';

// Import the HotPotato ABI
import HotPotatoABI from '../zkout/HotPotato.sol/HotPotato.json';

const HOT_POTATO_ADDRESS = '0x9E2d58E626e29641Cc5748007637Cc07D574228E';
const PRIVATE_KEY = '0xf12e28c0eb1ef4ff90478f6805b68d63737b7f33abfa091601140805da450d93';
const L2A_CHAIN_ID = 271
const L2B_CHAIN_ID = 260

describe('Integration', () => {
    let l2a_provider: zksync.Provider;
    let l2b_provider: zksync.Provider;
    let aliceA: zksync.Wallet;
    let aliceB: zksync.Wallet;
    let hotPotatoA: zksync.Contract;
    let hotPotatoB: zksync.Contract;

    beforeAll(async () => {
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

        // Get the NFT Transfer event (second log, index 1)
        const transferLog = receipt.logs[1];
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

        // Get the PotatoThrown event (sixth log, index 5)
        const potatoThrownLog = receipt.logs[5];
        thrownPotatoId = potatoThrownLog.topics[1]; // Second topic contains the thrown potato ID
        console.log('Thrown potato ID:', thrownPotatoId);
        console.log('Tx hash:', txHash);
    });

    it('should catch and mint a potato', async () => {
        // Imports proof until GW's message root, needed for proof based interop.
        const params = await aliceA.getFinalizeWithdrawalParams(txHash, undefined, undefined, 'gw_message_root');
        const tx = await aliceB.sendTransaction({
            to: HOT_POTATO_ADDRESS,
            data: hotPotatoB.interface.encodeFunctionData(
                'catchAndMintPotato',
                [
                    L2A_CHAIN_ID,
                    params.l1BatchNumber,
                    params.l2MessageIndex,
                    { txNumberInBatch: params.l2TxNumberInBlock, sender: params.sender, data: params.message },
                    params.proof
                ]
            ),
        });
        const receipt = await tx.wait();
        console.log(receipt);
    });
});
