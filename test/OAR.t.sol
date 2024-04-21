// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Test
import {Test, console} from "forge-std/Test.sol";
import {MockERC721} from "./util/MockERC721.sol";

// EAS
import {
    IEAS,
    Attestation,
    AttestationRequest,
    AttestationRequestData,
    RevocationRequest,
    RevocationRequestData
} from "eas-contracts/IEAS.sol";
import {ISchemaRegistry, SchemaRecord, ISchemaResolver} from "eas-contracts/ISchemaRegistry.sol";
import {NO_EXPIRATION_TIME, EMPTY_UID} from "eas-contracts/Common.sol";

// CUT
import {OAR} from "../src/OAR.sol";

contract OARTest is Test {
    /////////

    OAR private oar;

    ///////// State

    address private contractAddress;
    bytes32 private schemaId;

    ///////// Constants

    address private constant ME = address(0xCAFE);

    IEAS private constant EAS = IEAS(0x4200000000000000000000000000000000000021);
    address private constant SCHEMA_REGISTRY = 0x4200000000000000000000000000000000000020;

    string private constant SCHEMA =
        "string name, string description, string category, string url, string imageUrl, address contractAddress, bytes4 functionSelector, address assetAddress, uint256 assetAmount, uint256 maxActionsPerWallet, uint256 startDate, uint256 endDate";

    string private constant NAME = "My App";
    string private constant DESCRIPTION = "My App Description";
    string private constant CATEGORY = "My App Category";
    string private constant URL = "https://myapp.com";
    string private constant IMAGE_URL = "https://myapp.com/image.png";

    bytes4 private constant FUNCTION_SELECTOR = bytes4(keccak256("mint(address,uint256)"));
    address private constant ASSET_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant ASSET_AMOUNT = 0.0022 ether;
    uint256 private constant MAX_ACTIONS_PER_WALLET = 1;
    uint256 private constant START_DATE = 7 days;
    uint256 private constant END_DATE = 14 days;

    function setUp() public {
        vm.createSelectFork("base_sepolia");

        // Background:
        // Given the OAR schema is registered with EAS
        schemaId = ISchemaRegistry(SCHEMA_REGISTRY).register({
            schema: SCHEMA,
            resolver: ISchemaResolver(address(0)),
            revocable: false
        });

        // And the OAR contract is deployed
        vm.prank(ME);
        oar = new OAR(address(EAS), schemaId);
    }

    ///////// function submit(SubmissionParams memory params) public payable returns (bytes32 uid);

    function test_submit() public {
        // When I deploy an NFT contract
        contractAddress = address(new MockERC721("Once Upon a Time in Shaolin", "WU"));

        // And I submit it to OAR
        bytes32 uid = oar.submit{value: 0.001 ether}(OAR.SubmissionParams({
            name: NAME,
            description: DESCRIPTION,
            category: CATEGORY,
            url: URL,
            contractAddress: contractAddress,
            functionSelector: FUNCTION_SELECTOR,
            assetAddress: ASSET_ADDRESS,
            assetAmount: ASSET_AMOUNT,
            maxActionsPerWallet: MAX_ACTIONS_PER_WALLET
        }));

        // Then I should see my NFT contract listed in OAR
        Attestation memory attestation = EAS.getAttestation(uid);

        assertEq(attestation.uid, uid, "uid mismatch");
        assertEq(attestation.recipient, contractAddress, "recipient mismatch");
        assertEq(attestation.attester, address(oar), "attester mismatch");
        assertEq(attestation.schema, schemaId, "schema mismatch");
        // TODO assert data
    }

    // function test_submit_many() public {
    //     // TODO
    // }

    // function test_submit_whenInsufficientEtherButVerified() public {
    //     // TODO
    // }

    // Sad Paths

    function testRevert_submit_whenInsufficientEther() public {
        // Then the function should revert
        vm.expectRevert(OAR.InsufficientEtherOrNotVerified.selector);

        // When I submit to OAR with insufficient ether
        oar.submit(OAR.SubmissionParams({
            name: NAME,
            description: DESCRIPTION,
            category: CATEGORY,
            url: URL,
            contractAddress: contractAddress,
            functionSelector: FUNCTION_SELECTOR,
            assetAddress: ASSET_ADDRESS,
            assetAmount: ASSET_AMOUNT,
            maxActionsPerWallet: MAX_ACTIONS_PER_WALLET
        }));
    }

    ///////// function sweep() public;

    function test_sweep() public {
        uint256 balance = ME.balance;

        // Given there are multiple submissions
        oar.submit{value: 0.001 ether}(OAR.SubmissionParams({
            name: "name 1",
            description: DESCRIPTION,
            category: CATEGORY,
            url: URL,
            contractAddress: contractAddress,
            functionSelector: FUNCTION_SELECTOR,
            assetAddress: ASSET_ADDRESS,
            assetAmount: ASSET_AMOUNT,
            maxActionsPerWallet: MAX_ACTIONS_PER_WALLET
        }));
        oar.submit{value: 0.001 ether}(OAR.SubmissionParams({
            name: "name 2",
            description: DESCRIPTION,
            category: CATEGORY,
            url: URL,
            contractAddress: contractAddress,
            functionSelector: FUNCTION_SELECTOR,
            assetAddress: ASSET_ADDRESS,
            assetAmount: ASSET_AMOUNT,
            maxActionsPerWallet: MAX_ACTIONS_PER_WALLET
        }));
        oar.submit{value: 0.001 ether}(OAR.SubmissionParams({
            name: "name 3",
            description: DESCRIPTION,
            category: CATEGORY,
            url: URL,
            contractAddress: contractAddress,
            functionSelector: FUNCTION_SELECTOR,
            assetAddress: ASSET_ADDRESS,
            assetAmount: ASSET_AMOUNT,
            maxActionsPerWallet: MAX_ACTIONS_PER_WALLET
        }));

        // When I sweep the OAR balance
        vm.prank(ME);
        oar.sweep();

        // Then I should see the OAR balance in the wallet
        assertEq(ME.balance, balance + 0.003 ether, "balance mismatch");
    }

    // Sad Paths

    function testRevert_sweep_whenNotOwner() public {
        // Then the function should revert
        vm.expectRevert("UNAUTHORIZED");

        // When I sweep the OAR balance as a non-owner
        oar.sweep();
    }
}
