'forge clean' running (wd: /workspaces/2025-09-bid-beasts)
'forge config --json' running
'forge build --build-info --skip */test/** */script/** --force' running (wd: /workspaces/2025-09-bid-beasts)
INFO:Detectors:[91m
Reentrancy in BidBeastsNFTMarket.placeBid(uint256) (src/BidBeastsNFTMarketPlace.sol#106-175):
	External calls:
	- _payout(previousBidder,previousBidAmount) (src/BidBeastsNFTMarketPlace.sol#128)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	- _executeSale(tokenId) (src/BidBeastsNFTMarketPlace.sol#132)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
		- BBERC721.transferFrom(address(this),bid.bidder,tokenId) (src/BidBeastsNFTMarketPlace.sol#211)
	External calls sending eth:
	- _payout(previousBidder,previousBidAmount) (src/BidBeastsNFTMarketPlace.sol#128)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	- _executeSale(tokenId) (src/BidBeastsNFTMarketPlace.sol#132)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	State variables written after the call(s):
	- _executeSale(tokenId) (src/BidBeastsNFTMarketPlace.sol#132)
		- delete bids[tokenId] (src/BidBeastsNFTMarketPlace.sol#209)
	BidBeastsNFTMarket.bids (src/BidBeastsNFTMarketPlace.sol#43) can be used in cross function reentrancies:
	- BidBeastsNFTMarket._executeSale(uint256) (src/BidBeastsNFTMarketPlace.sol#204-220)
	- BidBeastsNFTMarket.bids (src/BidBeastsNFTMarketPlace.sol#43)
	- BidBeastsNFTMarket.getHighestBid(uint256) (src/BidBeastsNFTMarketPlace.sol#259-261)
	- BidBeastsNFTMarket.placeBid(uint256) (src/BidBeastsNFTMarketPlace.sol#106-175)
	- BidBeastsNFTMarket.settleAuction(uint256) (src/BidBeastsNFTMarketPlace.sol#180-187)
	- BidBeastsNFTMarket.takeHighestBid(uint256) (src/BidBeastsNFTMarketPlace.sol#192-197)
	- BidBeastsNFTMarket.unlistNFT(uint256) (src/BidBeastsNFTMarketPlace.sol#92-101)
	- _executeSale(tokenId) (src/BidBeastsNFTMarketPlace.sol#132)
		- failedTransferCredits[recipient] += amount (src/BidBeastsNFTMarketPlace.sol#229)
	BidBeastsNFTMarket.failedTransferCredits (src/BidBeastsNFTMarketPlace.sol#44) can be used in cross function reentrancies:
	- BidBeastsNFTMarket._payout(address,uint256) (src/BidBeastsNFTMarketPlace.sol#225-231)
	- BidBeastsNFTMarket.failedTransferCredits (src/BidBeastsNFTMarketPlace.sol#44)
	- BidBeastsNFTMarket.withdrawAllFailedCredits(address) (src/BidBeastsNFTMarketPlace.sol#236-244)
	- _executeSale(tokenId) (src/BidBeastsNFTMarketPlace.sol#132)
		- listing.listed = false (src/BidBeastsNFTMarketPlace.sol#208)
	BidBeastsNFTMarket.listings (src/BidBeastsNFTMarketPlace.sol#42) can be used in cross function reentrancies:
	- BidBeastsNFTMarket._executeSale(uint256) (src/BidBeastsNFTMarketPlace.sol#204-220)
	- BidBeastsNFTMarket.getListing(uint256) (src/BidBeastsNFTMarketPlace.sol#255-257)
	- BidBeastsNFTMarket.isListed(uint256) (src/BidBeastsNFTMarketPlace.sol#47-50)
	- BidBeastsNFTMarket.isSeller(uint256,address) (src/BidBeastsNFTMarketPlace.sol#52-55)
	- BidBeastsNFTMarket.listNFT(uint256,uint256,uint256) (src/BidBeastsNFTMarketPlace.sol#69-87)
	- BidBeastsNFTMarket.listings (src/BidBeastsNFTMarketPlace.sol#42)
	- BidBeastsNFTMarket.placeBid(uint256) (src/BidBeastsNFTMarketPlace.sol#106-175)
	- BidBeastsNFTMarket.settleAuction(uint256) (src/BidBeastsNFTMarketPlace.sol#180-187)
	- BidBeastsNFTMarket.takeHighestBid(uint256) (src/BidBeastsNFTMarketPlace.sol#192-197)
	- BidBeastsNFTMarket.unlistNFT(uint256) (src/BidBeastsNFTMarketPlace.sol#92-101)
Reentrancy in BidBeastsNFTMarket.placeBid(uint256) (src/BidBeastsNFTMarketPlace.sol#106-175):
	External calls:
	- _payout(previousBidder,previousBidAmount) (src/BidBeastsNFTMarketPlace.sol#128)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	- _executeSale(tokenId) (src/BidBeastsNFTMarketPlace.sol#132)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
		- BBERC721.transferFrom(address(this),bid.bidder,tokenId) (src/BidBeastsNFTMarketPlace.sol#211)
	- _payout(msg.sender,overpay) (src/BidBeastsNFTMarketPlace.sol#136)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	External calls sending eth:
	- _payout(previousBidder,previousBidAmount) (src/BidBeastsNFTMarketPlace.sol#128)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	- _executeSale(tokenId) (src/BidBeastsNFTMarketPlace.sol#132)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	- _payout(msg.sender,overpay) (src/BidBeastsNFTMarketPlace.sol#136)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	State variables written after the call(s):
	- _payout(msg.sender,overpay) (src/BidBeastsNFTMarketPlace.sol#136)
		- failedTransferCredits[recipient] += amount (src/BidBeastsNFTMarketPlace.sol#229)
	BidBeastsNFTMarket.failedTransferCredits (src/BidBeastsNFTMarketPlace.sol#44) can be used in cross function reentrancies:
	- BidBeastsNFTMarket._payout(address,uint256) (src/BidBeastsNFTMarketPlace.sol#225-231)
	- BidBeastsNFTMarket.failedTransferCredits (src/BidBeastsNFTMarketPlace.sol#44)
	- BidBeastsNFTMarket.withdrawAllFailedCredits(address) (src/BidBeastsNFTMarketPlace.sol#236-244)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities[0m
INFO:Detectors:[93m
BidBeastsNFTMarket.placeBid(uint256) (src/BidBeastsNFTMarketPlace.sol#106-175) performs a multiplication on the result of a division:
	- requiredAmount = (previousBidAmount / 100) * (100 + S_MIN_BID_INCREMENT_PERCENTAGE) (src/BidBeastsNFTMarketPlace.sol#154)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply[0m
INFO:Detectors:[93m
Reentrancy in BidBeasts.mint(address) (src/BidBeasts_NFT_ERC721.sol#17-23):
	External calls:
	- _safeMint(to,_tokenId) (src/BidBeasts_NFT_ERC721.sol#19)
		- retval = IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data) (lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#406-417)
	State variables written after the call(s):
	- CurrenTokenID ++ (src/BidBeasts_NFT_ERC721.sol#21)
	BidBeasts.CurrenTokenID (src/BidBeasts_NFT_ERC721.sol#13) can be used in cross function reentrancies:
	- BidBeasts.CurrenTokenID (src/BidBeasts_NFT_ERC721.sol#13)
	- BidBeasts.mint(address) (src/BidBeasts_NFT_ERC721.sol#17-23)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1[0m
INFO:Detectors:[92m
Reentrancy in BidBeastsNFTMarket._executeSale(uint256) (src/BidBeastsNFTMarketPlace.sol#204-220):
	External calls:
	- BBERC721.transferFrom(address(this),bid.bidder,tokenId) (src/BidBeastsNFTMarketPlace.sol#211)
	State variables written after the call(s):
	- s_totalFee += fee (src/BidBeastsNFTMarketPlace.sol#214)
Reentrancy in BidBeastsNFTMarket._payout(address,uint256) (src/BidBeastsNFTMarketPlace.sol#225-231):
	External calls:
	- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	State variables written after the call(s):
	- failedTransferCredits[recipient] += amount (src/BidBeastsNFTMarketPlace.sol#229)
Reentrancy in BidBeastsNFTMarket.listNFT(uint256,uint256,uint256) (src/BidBeastsNFTMarketPlace.sol#69-87):
	External calls:
	- BBERC721.transferFrom(msg.sender,address(this),tokenId) (src/BidBeastsNFTMarketPlace.sol#76)
	State variables written after the call(s):
	- listings[tokenId] = Listing({seller:msg.sender,minPrice:_minPrice,buyNowPrice:_buyNowPrice,auctionEnd:0,listed:true}) (src/BidBeastsNFTMarketPlace.sol#78-84)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-2[0m
INFO:Detectors:[92m
Reentrancy in BidBeastsNFTMarket._executeSale(uint256) (src/BidBeastsNFTMarketPlace.sol#204-220):
	External calls:
	- BBERC721.transferFrom(address(this),bid.bidder,tokenId) (src/BidBeastsNFTMarketPlace.sol#211)
	- _payout(listing.seller,sellerProceeds) (src/BidBeastsNFTMarketPlace.sol#217)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	External calls sending eth:
	- _payout(listing.seller,sellerProceeds) (src/BidBeastsNFTMarketPlace.sol#217)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	Event emitted after the call(s):
	- AuctionSettled(tokenId,bid.bidder,listing.seller,bid.amount) (src/BidBeastsNFTMarketPlace.sol#219)
Reentrancy in BidBeastsNFTMarket.listNFT(uint256,uint256,uint256) (src/BidBeastsNFTMarketPlace.sol#69-87):
	External calls:
	- BBERC721.transferFrom(msg.sender,address(this),tokenId) (src/BidBeastsNFTMarketPlace.sol#76)
	Event emitted after the call(s):
	- NftListed(tokenId,msg.sender,_minPrice,_buyNowPrice) (src/BidBeastsNFTMarketPlace.sol#86)
Reentrancy in BidBeasts.mint(address) (src/BidBeasts_NFT_ERC721.sol#17-23):
	External calls:
	- _safeMint(to,_tokenId) (src/BidBeasts_NFT_ERC721.sol#19)
		- retval = IERC721Receiver(to).onERC721Received(_msgSender(),from,tokenId,data) (lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#406-417)
	Event emitted after the call(s):
	- BidBeastsMinted(to,_tokenId) (src/BidBeasts_NFT_ERC721.sol#20)
Reentrancy in BidBeastsNFTMarket.placeBid(uint256) (src/BidBeastsNFTMarketPlace.sol#106-175):
	External calls:
	- _payout(previousBidder,previousBidAmount) (src/BidBeastsNFTMarketPlace.sol#128)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	- _executeSale(tokenId) (src/BidBeastsNFTMarketPlace.sol#132)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
		- BBERC721.transferFrom(address(this),bid.bidder,tokenId) (src/BidBeastsNFTMarketPlace.sol#211)
	External calls sending eth:
	- _payout(previousBidder,previousBidAmount) (src/BidBeastsNFTMarketPlace.sol#128)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	- _executeSale(tokenId) (src/BidBeastsNFTMarketPlace.sol#132)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	Event emitted after the call(s):
	- AuctionSettled(tokenId,bid.bidder,listing.seller,bid.amount) (src/BidBeastsNFTMarketPlace.sol#219)
		- _executeSale(tokenId) (src/BidBeastsNFTMarketPlace.sol#132)
Reentrancy in BidBeastsNFTMarket.placeBid(uint256) (src/BidBeastsNFTMarketPlace.sol#106-175):
	External calls:
	- _payout(previousBidder,previousBidAmount) (src/BidBeastsNFTMarketPlace.sol#171)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	Event emitted after the call(s):
	- BidPlaced(tokenId,msg.sender,msg.value) (src/BidBeastsNFTMarketPlace.sol#174)
Reentrancy in BidBeastsNFTMarket.unlistNFT(uint256) (src/BidBeastsNFTMarketPlace.sol#92-101):
	External calls:
	- BBERC721.transferFrom(address(this),msg.sender,tokenId) (src/BidBeastsNFTMarketPlace.sol#98)
	Event emitted after the call(s):
	- NftUnlisted(tokenId) (src/BidBeastsNFTMarketPlace.sol#100)
Reentrancy in BidBeastsNFTMarket.withdrawFee() (src/BidBeastsNFTMarketPlace.sol#246-252):
	External calls:
	- _payout(owner(),feeToWithdraw) (src/BidBeastsNFTMarketPlace.sol#250)
		- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
	Event emitted after the call(s):
	- FeeWithdrawn(feeToWithdraw) (src/BidBeastsNFTMarketPlace.sol#251)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3[0m
INFO:Detectors:[92m
BidBeastsNFTMarket.placeBid(uint256) (src/BidBeastsNFTMarketPlace.sol#106-175) uses timestamp for comparisons
	Dangerous comparisons:
	- require(bool,string)(listing.seller != msg.sender,Seller cannot bid) (src/BidBeastsNFTMarketPlace.sol#111)
	- require(bool,string)(listing.auctionEnd == 0 || block.timestamp < listing.auctionEnd,Auction ended) (src/BidBeastsNFTMarketPlace.sol#115)
	- listing.auctionEnd > block.timestamp (src/BidBeastsNFTMarketPlace.sol#158)
	- timeLeft < S_AUCTION_EXTENSION_DURATION (src/BidBeastsNFTMarketPlace.sol#161)
BidBeastsNFTMarket.settleAuction(uint256) (src/BidBeastsNFTMarketPlace.sol#180-187) uses timestamp for comparisons
	Dangerous comparisons:
	- require(bool,string)(listing.auctionEnd > 0,Auction has not started (no bids)) (src/BidBeastsNFTMarketPlace.sol#182)
	- require(bool,string)(block.timestamp >= listing.auctionEnd,Auction has not ended) (src/BidBeastsNFTMarketPlace.sol#183)
	- require(bool,string)(bids[tokenId].amount >= listing.minPrice,Highest bid did not meet min price) (src/BidBeastsNFTMarketPlace.sol#184)
BidBeastsNFTMarket.takeHighestBid(uint256) (src/BidBeastsNFTMarketPlace.sol#192-197) uses timestamp for comparisons
	Dangerous comparisons:
	- require(bool,string)(bid.amount >= listings[tokenId].minPrice,Highest bid is below min price) (src/BidBeastsNFTMarketPlace.sol#194)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#block-timestamp[0m
INFO:Detectors:[92m
3 different versions of Solidity are used:
	- Version constraint ^0.8.0 is used by:
		-^0.8.0 (lib/openzeppelin-contracts/contracts/access/Ownable.sol#4)
		-^0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol#4)
		-^0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol#4)
		-^0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol#4)
		-^0.8.0 (lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol#4)
		-^0.8.0 (lib/openzeppelin-contracts/contracts/utils/Context.sol#4)
		-^0.8.0 (lib/openzeppelin-contracts/contracts/utils/Strings.sol#4)
		-^0.8.0 (lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol#4)
		-^0.8.0 (lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#4)
		-^0.8.0 (lib/openzeppelin-contracts/contracts/utils/math/Math.sol#4)
		-^0.8.0 (lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol#4)
	- Version constraint ^0.8.1 is used by:
		-^0.8.1 (lib/openzeppelin-contracts/contracts/utils/Address.sol#4)
	- Version constraint 0.8.20 is used by:
		-0.8.20 (src/BidBeastsNFTMarketPlace.sol#2)
		-0.8.20 (src/BidBeasts_NFT_ERC721.sol#2)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#different-pragma-directives-are-used[0m
INFO:Detectors:[92m
Version constraint 0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
	- VerbatimInvalidDeduplication
	- FullInlinerNonExpressionSplitArgumentEvaluationOrder
	- MissingSideEffectsOnSelectorAccess.
It is used by:
	- 0.8.20 (src/BidBeastsNFTMarketPlace.sol#2)
	- 0.8.20 (src/BidBeasts_NFT_ERC721.sol#2)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity[0m
INFO:Detectors:[92m
Low level call in BidBeastsNFTMarket._payout(address,uint256) (src/BidBeastsNFTMarketPlace.sol#225-231):
	- (success,None) = address(recipient).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#227)
Low level call in BidBeastsNFTMarket.withdrawAllFailedCredits(address) (src/BidBeastsNFTMarketPlace.sol#236-244):
	- (success,None) = address(msg.sender).call{value: amount}() (src/BidBeastsNFTMarketPlace.sol#242)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#low-level-calls[0m
INFO:Detectors:[92m
BidBeastsNFTMarket.BBERC721 (src/BidBeastsNFTMarketPlace.sol#10) should be immutable 
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#state-variables-that-could-be-declared-immutable[0m
INFO:Slither:. analyzed (14 contracts with 99 detectors), 22 result(s) found
