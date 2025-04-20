// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title PotatoLib
/// @notice Library for managing potato IDs
library PotatoLib {
    /// @notice Get the potato ID
    /// @param originChainId The origin chain ID
    /// @param potatoNumber The potato number in the origin chain
    /// @param senderChainId The chain ID of the interop transaction sender
    /// @param receiverChainId The chain ID of the interop transaction receiver
    /// @param timebomb The timebomb
    function getPotatoId(
        uint256 originChainId,
        uint256 potatoNumber,
        uint256 senderChainId,
        uint256 receiverChainId,
        uint128 timebomb
    ) internal pure returns (uint256 result) {
        assembly {
            // Pack values directly in assembly:
            // originChainId (32) | potatoNumber (32) | senderChainId (32) | receiverChainId (32) | timebomb (128)
            result :=
                or(
                    shl(224, originChainId), // originChainId at bits 224-255
                    or(
                        shl(192, potatoNumber), // potatoNumber at bits 192-223
                        or(
                            shl(160, senderChainId), // senderChainId at bits 160-191
                            or(
                                shl(128, receiverChainId), // receiverChainId at bits 128-159
                                timebomb // timebomb at bits 0-127
                            )
                        )
                    )
                )
        }
    }

    /// @notice Get the receiver chain ID from the potato ID
    /// @param self The potato ID
    /// @return receiverChainId The receiver chain ID
    function getReceiverChainId(uint256 self) internal pure returns (uint256 receiverChainId) {
        assembly {
            receiverChainId := shr(128, and(self, 0x000000000000000000000000FFFFFFFF00000000000000000000000000000000))
        }
    }

    /// @notice Set the receiver chain ID in the potato ID
    /// @param self The potato ID
    /// @param newReceiverChainId The new receiver chain ID
    /// @return newPotatoId The new potato ID
    function setReceiverChainId(uint256 self, uint32 newReceiverChainId) internal pure returns (uint256 newPotatoId) {
        assembly {
            newPotatoId :=
                or(
                    and(self, 0xFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF),
                    shl(128, newReceiverChainId)
                )
        }
    }

    /// @notice Get the timebomb from the potato ID
    /// @param self The potato ID
    /// @return timebomb The timebomb
    function getTimebomb(uint256 self) internal pure returns (uint256 timebomb) {
        assembly {
            timebomb := and(self, 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @notice Set the timebomb in the potato ID
    /// @param self The potato ID
    /// @param newTimebomb The new timebomb
    /// @return newPotatoId The new potato ID
    function setTimebomb(uint256 self, uint128 newTimebomb) internal pure returns (uint256 newPotatoId) {
        assembly {
            newPotatoId :=
                or(and(self, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000), newTimebomb)
        }
    }
}
