// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BidBeastsNFTMarket} from "../src/BidBeastsNFTMarketPlace.sol";
import {BidBeasts} from "../src/BidBeasts_NFT_ERC721.sol";

// A mock contract that cannot receive Ether, to test the payout failure logic.
contract RejectEther {
    // Intentionally has no payable receive or fallback
}

contract BidBeastsNFTMarketTest is Test {
    // --- State Variables ---
    BidBeastsNFTMarket market;
    BidBeasts nft;
    RejectEther rejector;

    // --- Users ---
    address public constant OWNER = address(0x1); // Contract deployer/owner
    address public constant SELLER = address(0x2);
    address public constant BIDDER_1 = address(0x3);
    address public constant BIDDER_2 = address(0x4);

    // --- Constants ---
    uint256 public constant STARTING_BALANCE = 100 ether;
    uint256 public constant TOKEN_ID = 0;
    uint256 public constant MIN_PRICE = 1 ether;
    uint256 public constant BUY_NOW_PRICE = 5 ether;

    function setUp() public {
        // Deploy contracts
        vm.prank(OWNER);
        nft = new BidBeasts();
        market = new BidBeastsNFTMarket(address(nft));
        rejector = new RejectEther();

        vm.stopPrank();

        // Fund users
        vm.deal(SELLER, STARTING_BALANCE);
        vm.deal(BIDDER_1, STARTING_BALANCE);
        vm.deal(BIDDER_2, STARTING_BALANCE);
    }

    // --- Helper function to list an NFT ---
    function _listNFT() internal {
        vm.startPrank(SELLER);
        nft.approve(address(market), TOKEN_ID);
        market.listNFT(TOKEN_ID, MIN_PRICE, BUY_NOW_PRICE);
        vm.stopPrank();
    }

    // -- Helper function to mint an NFT ---
    function _mintNFT() internal {
        vm.startPrank(OWNER);
        nft.mint(SELLER);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            LISTING TESTS
    //////////////////////////////////////////////////////////////*/
    function test_listNFT() public {

        _mintNFT();
        _listNFT();

        assertEq(nft.ownerOf(TOKEN_ID), address(market), "NFT should be held by the market");
        BidBeastsNFTMarket.Listing memory listing = market.getListing(TOKEN_ID);
        assertEq(listing.seller, SELLER);
        assertEq(listing.minPrice, MIN_PRICE);
    }

    function test_fail_listNFT_notOwner() public {
        vm.prank(BIDDER_1);
        vm.expectRevert("Not the owner");
        market.listNFT(TOKEN_ID, MIN_PRICE, BUY_NOW_PRICE);
    }
    

    function test_unlistNFT() public {
        _mintNFT();
        _listNFT();

        vm.prank(SELLER);
        market.unlistNFT(TOKEN_ID);
        
        assertEq(nft.ownerOf(TOKEN_ID), SELLER, "NFT should be returned to seller");
        assertFalse(market.getListing(TOKEN_ID).listed, "Listing should be marked as unlisted");
    }

    /*//////////////////////////////////////////////////////////////
                            BIDDING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_placeFirstBid() public {
        _mintNFT();
        _listNFT();

        vm.prank(BIDDER_1);
        market.placeBid{value: MIN_PRICE}(TOKEN_ID);

        BidBeastsNFTMarket.Bid memory highestBid = market.getHighestBid(TOKEN_ID);
        assertEq(highestBid.bidder, BIDDER_1);
        assertEq(highestBid.amount, MIN_PRICE);
        assertEq(market.getListing(TOKEN_ID).auctionEnd, block.timestamp + market.S_AUCTION_EXTENSION_DURATION());
    }

    function test_placeSubsequentBid_RefundsPrevious() public {
        _mintNFT();
        _listNFT();

        vm.prank(BIDDER_1);
        market.placeBid{value: MIN_PRICE}(TOKEN_ID);

        uint256 bidder1BalanceBefore = BIDDER_1.balance;
        
        uint256 secondBidAmount = MIN_PRICE * 120 / 100; // 20% increase
        vm.prank(BIDDER_2);
        market.placeBid{value: secondBidAmount}(TOKEN_ID);

        // Check if bidder 1 was refunded
        assertEq(BIDDER_1.balance, bidder1BalanceBefore + MIN_PRICE, "Bidder 1 was not refunded");
        
        BidBeastsNFTMarket.Bid memory highestBid = market.getHighestBid(TOKEN_ID);
        assertEq(highestBid.bidder, BIDDER_2, "Bidder 2 should be the new highest bidder");
        assertEq(highestBid.amount, secondBidAmount, "New highest bid amount is incorrect");
    }
}