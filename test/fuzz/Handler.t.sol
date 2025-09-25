// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BidBeastsNFTMarket} from "../../src/BidBeastsNFTMarketPlace.sol";
import {BidBeasts} from "../../src/BidBeasts_NFT_ERC721.sol";

contract Handler is Test {
    error Handler__ZeroActors();
    error Handler__IncorrectOwnedTokenId(uint256 tokenId);
    // --- State Variables ---

    BidBeastsNFTMarket market;
    BidBeasts nft;
    // users
    address public owner;
    address[] public actors;
    address internal currentActor;

    uint256 public s_totalMints;

    constructor(BidBeastsNFTMarket _market, BidBeasts _nft, address _owner, address[] memory _actors) {
        if (_actors.length == 0) {
            revert Handler__ZeroActors();
        }
        owner = _owner;
        market = _market;
        nft = _nft;
        actors = _actors;
    }

    function _mintNft(address user) private returns (uint256 tokenId) {
        vm.startPrank(owner);
        tokenId = nft.mint(user);
        vm.stopPrank();
        s_totalMints++;
    }

    function mintAndListNFT(uint256 actorIndexSeed, uint256 minPrice) external {
        // select random user
        currentActor = actors[bound(actorIndexSeed, 0, actors.length - 1)];
        // mint nft
        uint256 tokenIdToList = _mintNft(currentActor);
        // set price and max price
        minPrice = bound(minPrice, market.S_MIN_NFT_PRICE(), 10 ether);
        uint256 maxPrice;
        maxPrice = bound(maxPrice, minPrice * 2, 50 ether);
        // user approve and list nft
        vm.startPrank(currentActor);
        nft.approve(address(market), tokenIdToList);
        market.listNFT(tokenIdToList, minPrice, maxPrice);
        vm.stopPrank();
    }

    function placeBidOnListedNFT(uint256 actorIndexSeed, uint256 tokenIdSeed) external {}

    function buyNowOnListedNFT(uint256 actorIndexSeed, uint256 tokenIdSeed) external {}
}
