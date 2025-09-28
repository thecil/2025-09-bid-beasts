// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {BidBeasts} from "./BidBeasts_NFT_ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// @audit - low - incorrect use of Ownable constructor
// contract BidBeastsNFTMarket is Ownable(msg.sender) {
contract BidBeastsNFTMarket is Ownable {
    BidBeasts public BBERC721;

    // --- Events ---
    // @audit - [L-1] - Missing indexed event.
    event NftListed(uint256 tokenId, address seller, uint256 minPrice, uint256 buyNowPrice);
    event NftUnlisted(uint256 tokenId);
    // @audit - [L-1] - Missing indexed event.
    event BidPlaced(uint256 tokenId, address bidder, uint256 amount);
    event AuctionExtended(uint256 tokenId, uint256 newDeadline);
    // @audit - [L-1] - Missing indexed event.
    event AuctionSettled(uint256 tokenId, address winner, address seller, uint256 price);
    event FeeWithdrawn(uint256 amount);

    // --- Structs ---.
    struct Listing {
        address seller;
        uint256 minPrice;
        uint256 buyNowPrice;
        uint256 auctionEnd;
        bool listed;
    }

    struct Bid {
        address bidder;
        uint256 amount;
    }

    // --- Constants ---
    uint256 public constant S_AUCTION_EXTENSION_DURATION = 15 minutes;
    uint256 public constant S_MIN_NFT_PRICE = 0.01 ether;
    // @audit - low - percentage should be basis points for better precision
    uint256 public constant S_FEE_PERCENTAGE = 5;
    uint256 public constant S_MIN_BID_INCREMENT_PERCENTAGE = 5;

    // --- State Variables ---
    uint256 public s_totalFee;
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Bid) public bids;
    mapping(address => uint256) public failedTransferCredits;

    // --- Modifiers ---
    modifier isListed(uint256 tokenId) {
        require(listings[tokenId].listed, "NFT is not listed");
        _;
    }

    modifier isSeller(uint256 tokenId, address account) {
        require(listings[tokenId].seller == account, "Not the seller");
        _;
    }

    constructor(address _BidBeastsNFT) {
        BBERC721 = BidBeasts(_BidBeastsNFT);
    }

    // --- Core Auction Functions ---

    /**
     * @notice Lists an NFT for auction.
     * @param tokenId The ID of the token to list.
     * @param _minPrice The starting price for the auction.
     * @param _buyNowPrice The price for immediate purchase (set to 0 to disable).
     */
    // @audit - [L-2] - S - `BidBeastsNFTMarket::listNFT` function should follow CEI Pattern to Avoid Reentrancy Risk.
    function listNFT(uint256 tokenId, uint256 _minPrice, uint256 _buyNowPrice) external {
        require(BBERC721.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(_minPrice >= S_MIN_NFT_PRICE, "Min price too low");
        if (_buyNowPrice > 0) {
            require(_minPrice <= _buyNowPrice, "Min price cannot exceed buy now price");
        }

        BBERC721.transferFrom(msg.sender, address(this), tokenId);

        listings[tokenId] = Listing({
            seller: msg.sender,
            minPrice: _minPrice,
            buyNowPrice: _buyNowPrice,
            auctionEnd: 0, // Timer starts only after the first valid bid.
            listed: true
        });

        emit NftListed(tokenId, msg.sender, _minPrice, _buyNowPrice);
    }

    /**
     * @notice Allows the seller to unlist an NFT if no bids have been made.
     */
    function unlistNFT(uint256 tokenId) external isListed(tokenId) isSeller(tokenId, msg.sender) {
        require(bids[tokenId].bidder == address(0), "Cannot unlist, a bid has been placed");

        Listing storage listing = listings[tokenId];
        listing.listed = false;

        BBERC721.transferFrom(address(this), msg.sender, tokenId);

        emit NftUnlisted(tokenId);
    }

    /**
     * @notice Places a bid on a listed NFT. Extends the auction on each new bid.
     */
    // @audit - high - reentrancy attack
    // @audit https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities
    function placeBid(uint256 tokenId) external payable isListed(tokenId) {
        Listing storage listing = listings[tokenId];
        address previousBidder = bids[tokenId].bidder;
        uint256 previousBidAmount = bids[tokenId].amount;

        require(listing.seller != msg.sender, "Seller cannot bid");

        // auctionEnd == 0 => no bids yet => allowed
        // auctionEnd > 0 and block.timestamp >= auctionEnd => auction ended => block
        require(listing.auctionEnd == 0 || block.timestamp < listing.auctionEnd, "Auction ended");

        // --- Buy Now Logic ---
        // @audit - conditional should be a 'require' statement, when conditional fail, it will continue the logic
        if (listing.buyNowPrice > 0 && msg.value >= listing.buyNowPrice) {
            uint256 salePrice = listing.buyNowPrice;
            uint256 overpay = msg.value - salePrice;

            // EFFECT: set winner bid to exact sale price (keep consistent)
            bids[tokenId] = Bid(msg.sender, salePrice);
            // @audit - this is being set at `_executeSale`, which is being call below this codeline
            listing.listed = false;

            if (previousBidder != address(0)) {
                _payout(previousBidder, previousBidAmount);
            }

            // NOTE: using internal finalize to do transfer/payouts. _executeSale will assume bids[tokenId] is the final winner.
            _executeSale(tokenId);

            // Refund overpay (if any) to buyer
            if (overpay > 0) {
                _payout(msg.sender, overpay);
            }

            return;
        }

        // @audit - low - should follow CEI
        require(msg.sender != previousBidder, "Already highest bidder");
        // @audit - [L-4] - S - `BidBeastsNFTMarket::placeBid` emitting `AuctionSettled` event incorrectly, causing confusion when placing a bid.
        emit AuctionSettled(tokenId, msg.sender, listing.seller, msg.value);

        // --- Regular Bidding Logic ---
        uint256 requiredAmount;

        if (previousBidAmount == 0) {
            requiredAmount = listing.minPrice;
            require(msg.value > requiredAmount, "First bid must be > min price");
            listing.auctionEnd = block.timestamp + S_AUCTION_EXTENSION_DURATION;
            emit AuctionExtended(tokenId, listing.auctionEnd);
        } else {
            // @audit - [M-1] - S - `BidBeastsNFTMarket::placeBid` dDivide before multiply cause precision loss for the `requiredAmount` calculation.
            requiredAmount = (previousBidAmount / 100) * (100 + S_MIN_BID_INCREMENT_PERCENTAGE);
            require(msg.value >= requiredAmount, "Bid not high enough");

            uint256 timeLeft = 0;
            if (listing.auctionEnd > block.timestamp) {
                timeLeft = listing.auctionEnd - block.timestamp;
            }
            if (timeLeft < S_AUCTION_EXTENSION_DURATION) {
                listing.auctionEnd = listing.auctionEnd + S_AUCTION_EXTENSION_DURATION;
                emit AuctionExtended(tokenId, listing.auctionEnd);
            }
        }

        // EFFECT: update highest bid
        bids[tokenId] = Bid(msg.sender, msg.value);

        if (previousBidder != address(0)) {
            _payout(previousBidder, previousBidAmount);
        }

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    /**
     * @notice Settles the auction after it has ended. Can be called by anyone.
     */
    function settleAuction(uint256 tokenId) external isListed(tokenId) {
        Listing storage listing = listings[tokenId];
        require(listing.auctionEnd > 0, "Auction has not started (no bids)");
        require(block.timestamp >= listing.auctionEnd, "Auction has not ended");
        require(bids[tokenId].amount >= listing.minPrice, "Highest bid did not meet min price");

        _executeSale(tokenId);
    }

    /**
     * @notice Allows the seller to accept the current highest bid before the auction ends.
     */
    function takeHighestBid(uint256 tokenId) external isListed(tokenId) isSeller(tokenId, msg.sender) {
        Bid storage bid = bids[tokenId];
        require(bid.amount >= listings[tokenId].minPrice, "Highest bid is below min price");

        _executeSale(tokenId);
    }

    // --- Internal & Helper Functions ---

    /**
     * @notice Internal function to handle the final NFT transfer and payment distribution.
     */
    // @audit - [L-3] - S - `BidBeastsNFTMarket::_executeSale` function should follow CEI Pattern to Avoid Reentrancy Risk.
    function _executeSale(uint256 tokenId) internal {
        Listing storage listing = listings[tokenId];
        Bid memory bid = bids[tokenId];

        listing.listed = false;
        delete bids[tokenId];

        BBERC721.transferFrom(address(this), bid.bidder, tokenId);

        uint256 fee = (bid.amount * S_FEE_PERCENTAGE) / 100;
        s_totalFee += fee;
        uint256 sellerProceeds = bid.amount - fee;
        _payout(listing.seller, sellerProceeds);

        emit AuctionSettled(tokenId, bid.bidder, listing.seller, bid.amount);
    }

    /**
     * @notice A payout function that credits users if a direct transfer fails.
     */
    function _payout(address recipient, uint256 amount) internal {
        if (amount == 0) return;
        (bool success,) = payable(recipient).call{value: amount}("");
        if (!success) {
            failedTransferCredits[recipient] += amount;
        }
    }

    /**
     * @notice Allows users to withdraw funds that failed to be transferred directly.
     */
    // @audit - [H-1] - S - Funds can be drain through `BidBeastsNFTMarket::withdrawAllFailedCredits` function.
    function withdrawAllFailedCredits(address _receiver) external {
        uint256 amount = failedTransferCredits[_receiver];
        require(amount > 0, "No credits to withdraw");

        failedTransferCredits[msg.sender] = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw failed");
    }

    // @audit - should follow CEI
    function withdrawFee() external onlyOwner {
        uint256 feeToWithdraw = s_totalFee;
        require(feeToWithdraw > 0, "No fees to withdraw");
        s_totalFee = 0;
        _payout(owner(), feeToWithdraw);
        emit FeeWithdrawn(feeToWithdraw);
    }

    // --- View Functions ---
    function getListing(uint256 tokenId) public view returns (Listing memory) {
        return listings[tokenId];
    }

    function getHighestBid(uint256 tokenId) public view returns (Bid memory) {
        return bids[tokenId];
    }

    function getOwner() public view returns (address) {
        return owner();
    }
}
