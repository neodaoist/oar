// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {
    IEAS,
    AttestationRequest,
    AttestationRequestData,
    RevocationRequest,
    RevocationRequestData
} from "eas-contracts/IEAS.sol";
import {NO_EXPIRATION_TIME, EMPTY_UID} from "eas-contracts/Common.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract OAR is Owned {
    /////////

    using SafeTransferLib for address;

    ///////// Events

    //

    ///////// Errors

    error InvalidAddress();

    error InsufficientEtherOrNotVerified();

    ///////// Structs

    struct SubmissionParams {
        string name;
        string description;
        string category;
        string url;
        address contractAddress;
        bytes4 functionSelector;
        address assetAddress;
        uint256 assetAmount;
        uint256 maxActionsPerWallet;
    }

    ///////// State

    // The address of the global EAS contract
    IEAS private immutable eas;

    // The schema ID of the OAR schema
    bytes32 private immutable schemaId;

    ///////// Construction

    /// @notice Creates a new OAR instance
    /// @param _eas The address of the global EAS contract
    constructor(address _eas, bytes32 _schemaId) Owned(msg.sender) {
        if (_eas == address(0)) {
            revert InvalidAddress();
        }

        eas = IEAS(_eas);
        schemaId = _schemaId;
    }

    ///////// Submit

    function submit(SubmissionParams memory params) public payable returns (bytes32 uid) {
        // Check sufficient ether
        // TODO add VerifiedAddress check
        if (msg.value < 0.001 ether) {
            revert InsufficientEtherOrNotVerified();
        }

        // Submit to registry
        uid = eas.attest(
            AttestationRequest({
                schema: schemaId,
                data: AttestationRequestData({
                    recipient: params.contractAddress,
                    expirationTime: NO_EXPIRATION_TIME,
                    revocable: false,
                    refUID: EMPTY_UID,
                    data: abi.encode(
                        params.name,
                        params.description,
                        params.category,
                        params.url,
                        params.contractAddress,
                        params.functionSelector,
                        params.assetAddress,
                        params.assetAmount,
                        params.maxActionsPerWallet
                    ),
                    value: 0
                })
            })
        );
    }

    ///////// Sweep

    function sweep() public onlyOwner {
        // Sweep funds to owner
        owner.safeTransferETH(address(this).balance);
    }
}
