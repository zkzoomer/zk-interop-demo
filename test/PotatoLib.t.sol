// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PotatoLib} from "../src/PotatoLib.sol";

contract PotatoLibTest is Test {
    using PotatoLib for uint256;

    function test_getPotatoId(
        uint32 originChainId,
        uint32 potatoNumber,
        uint32 senderChainId,
        uint32 receiverChainId,
        uint128 timebomb
    ) public pure {
        uint256 potatoId = PotatoLib.getPotatoId(originChainId, potatoNumber, senderChainId, receiverChainId, timebomb);
        uint256 expectedPotatoId =
            uint256(bytes32(abi.encodePacked(originChainId, potatoNumber, senderChainId, receiverChainId, timebomb)));
        vm.assertEq(potatoId, expectedPotatoId);
    }

    function test_getReceiverChainId(
        uint32 originChainId,
        uint32 potatoNumber,
        uint32 senderChainId,
        uint32 receiverChainId,
        uint128 timebomb
    ) public pure {
        uint256 potatoId = PotatoLib.getPotatoId(originChainId, potatoNumber, senderChainId, receiverChainId, timebomb);
        assertEq(potatoId.getReceiverChainId(), receiverChainId);
    }

    function test_setReceiverChainId(
        uint32 originChainId,
        uint32 potatoNumber,
        uint32 senderChainId,
        uint32 receiverChainId,
        uint32 newReceiverChainId,
        uint128 timebomb
    ) public pure {
        uint256 potatoId = PotatoLib.getPotatoId(originChainId, potatoNumber, senderChainId, receiverChainId, timebomb);
        uint256 newPotatoId = potatoId.setReceiverChainId(newReceiverChainId);
        assertEq(newPotatoId.getReceiverChainId(), newReceiverChainId);
        uint256 expectedPotatoId =
            PotatoLib.getPotatoId(originChainId, potatoNumber, senderChainId, newReceiverChainId, timebomb);
        assertEq(newPotatoId, expectedPotatoId);
    }

    function test_getTimebomb(
        uint32 originChainId,
        uint32 potatoNumber,
        uint32 senderChainId,
        uint32 receiverChainId,
        uint128 timebomb
    ) public pure {
        uint256 potatoId = PotatoLib.getPotatoId(originChainId, potatoNumber, senderChainId, receiverChainId, timebomb);
        assertEq(potatoId.getTimebomb(), timebomb);
    }

    function test_setTimebomb(
        uint32 originChainId,
        uint32 potatoNumber,
        uint32 senderChainId,
        uint32 receiverChainId,
        uint128 timebomb,
        uint128 newTimebomb
    ) public pure {
        uint256 potatoId = PotatoLib.getPotatoId(originChainId, potatoNumber, senderChainId, receiverChainId, timebomb);
        uint256 newPotatoId = potatoId.setTimebomb(newTimebomb);
        assertEq(newPotatoId.getTimebomb(), newTimebomb);
        uint256 expectedPotatoId =
            PotatoLib.getPotatoId(originChainId, potatoNumber, senderChainId, receiverChainId, newTimebomb);
        assertEq(newPotatoId, expectedPotatoId);
    }
}
