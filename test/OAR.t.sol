// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {MockERC721} from "./util/MockERC721.sol";

// CUT
import {OAR} from "../src/OAR.sol";

contract OARTest is Test {
    /////////

    OAR private oar;

    string private constant NAME = "My App";
    string private constant DESCRIPTION = "My App Description";
    string private constant CATEGORY = "My App Category";
    string private constant URL = "https://myapp.com";
    string private constant IMAGE_URL = "https://myapp.com/image.png";

    string private constant VERB = "mint";
    address private CONTRACT_ADDRESS;
    bytes4 private constant FUNCTION_SELECTOR = bytes4(keccak256("mint(address,uint256)"));
    address private constant ASSET_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant ASSET_AMOUNT = 0.001 ether;
    uint256 private constant MAX_ACTIONS_PER_WALLET = 1;

    function setUp() public {
        // Given the OAR schema is registered with EAS
        //

        // And the OAR contract is deployed
        oar = new OAR();
    }

    ///////// Submit

    function test_submit() public {
        // When I deploy an NFT contract
        CONTRACT_ADDRESS = address(new MockERC721("Once Upon a Time in Shaolin", "WU"));

        // And I submit an app
        oar.submit({
            // App
            name: NAME,
            description: DESCRIPTION,
            category: CATEGORY,
            url: URL,
            imageUrl: IMAGE_URL,

            // Action
            verb: VERB,
            contractAddress: CONTRACT_ADDRESS,
            functionSelector: FUNCTION_SELECTOR,
            assetAddress: ASSET_ADDRESS,
            assetAmount: ASSET_AMOUNT,
            maxActionsPerWallet: MAX_ACTIONS_PER_WALLET
        });

        // Then I should see the app listed in OAR
        //
    }

    function test_submit_whenNotEnoughEtherButVerified() public {}

    function test_submit_many() public {}

    // Sad Paths

    function testRevert_submit_whenNotSufficientEtherAndNotVerified() public {}

    ///////// Sweep

    function test_sweep() public {
        // When I sweep OAR
        oar.sweep();

        // Then I should see the OAR balance in the wallet
        //
    }

    // Sad Paths

    function testRevert_sweep_whenNotOwner() public {}
}
