// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Handler} from "./Handler.t.sol";

import {BidBeastsNFTMarket} from "../../src/BidBeastsNFTMarketPlace.sol";
import {BidBeasts} from "../../src/BidBeasts_NFT_ERC721.sol";

contract Invariant is StdInvariant, Test {
    BidBeastsNFTMarket market;
    BidBeasts nft;
    Handler handler;
    address owner = makeAddr("owner");
    uint64 constant ACTORS_LIMIT = 10;
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        // actors management
        address[] memory actors = new address[](ACTORS_LIMIT);
        for (uint256 i = 0; i < ACTORS_LIMIT; i++) {
            actors[i] = makeAddr(vm.toString(i));
            vm.deal(actors[i], STARTING_BALANCE);
        }
        // deploy contracts
        vm.deal(owner, STARTING_BALANCE);
        vm.startPrank(owner);
        nft = new BidBeasts();
        market = new BidBeastsNFTMarket(address(nft));
        handler = new Handler(market, nft, owner, actors);
        vm.stopPrank();

        targetContract(address(handler));
    }

    function invariant_protocol() external view {
        console.log("Handler Mints:", handler.s_totalMints());
        console.log("NFT current tokenId:", nft.CurrenTokenID());
        assertEq(handler.s_totalMints(), nft.CurrenTokenID(), "Total minted tokens should match the current token ID");
    }

    function invariant_correctDeployment() external view {
        assertEq(nft.name(), "Goddie_NFT", "NFT contract should be deployed with the correct name: Goddie_NFT");
        assertEq(
            address(market.BBERC721()),
            address(nft),
            "Market contract should be deployed with the correct BBERC721 address"
        );
    }
}
