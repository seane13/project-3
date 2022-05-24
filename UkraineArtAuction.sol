<<<<<<< HEAD
pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "./UkraineAuction.sol";

contract UkraineArtMarket is ERC721Full, Ownable {

    constructor() ERC721Full("UkraineArtMarket", "ART") public {}

    using Counters for Counters.Counter;

    Counters.Counter token_ids;

    address payable foundation_address = msg.sender;

    mapping(uint => UkraineAuction) public auctions;

    modifier artRegistered(uint token_id) {
        require(_exists(token_id), "Land not registered!");
        _;
    }

    function registerArt(string memory uri) public payable onlyOwner {
        token_ids.increment();
        uint token_id = token_ids.current();
        _mint(foundation_address, token_id);
        _setTokenURI(token_id, uri);
        createAuction(token_id);
    }

    function createAuction(uint token_id) public onlyOwner {
        auctions[token_id] = new UkraineAuction(foundation_address);
    }

    function endAuction(uint token_id) public onlyOwner artRegistered(token_id) {
        UkraineAuction auction = auctions[token_id];
        auction.auctionEnd();
        safeTransferFrom(owner(), auction.highestBidder(), token_id);
    }

    function auctionEnded(uint token_id) public view returns(bool) {
        UkraineAuction auction = auctions[token_id];
        return auction.ended();
    }

    function highestBid(uint token_id) public view artRegistered(token_id) returns(uint) {
        UkraineAuction auction = auctions[token_id];
        return auction.highestBid();
    }

    function pendingReturn(uint token_id, address sender) public view artRegistered(token_id) returns(uint) {
        UkraineAuction auction = auctions[token_id];
        return auction.pendingReturn(sender);
    }

    function bid(uint token_id) public payable artRegistered(token_id) {
        UkraineAuction auction = auctions[token_id];
        auction.bid.value(msg.value)(msg.sender);
    }

}
=======
pragma solidity >=0.4.22 <0.6.0;

contract MartianAuction {
    address deployer;
    address payable public beneficiary;

    // Current state of the auction.
    address public highestBidder;
    uint public highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;

    // Set to true at the end, disallows any change.
    // By default initialized to `false`.
    bool public ended;

    // Events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // The following is a so-called natspec comment,
    // recognizable by the three slashes.
    // It will be shown when the user is asked to
    // confirm a transaction.

    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    constructor(
        address payable _beneficiary
    ) public {
        deployer = msg.sender; // set as the MartianMarket
        beneficiary = _beneficiary;
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
    function bid(address payable sender) public payable {
        // If the bid is not higher, send the
        // money back.
        require(
            msg.value > highestBid,
            "There already is a higher bid."
        );

        require(!ended, "auctionEnd has already been called.");

        if (highestBid != 0) {
            // Sending back the money by simply using
            // highestBidder.send(highestBid) is a security risk
            // because it could execute an untrusted contract.
            // It is always safer to let the recipients
            // withdraw their money themselves.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = sender;
        highestBid = msg.value;
        emit HighestBidIncreased(sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function pendingReturn(address sender) public view returns (uint) {
        return pendingReturns[sender];
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public {
        // It is a good guideline to structure functions that interact
        // with other contracts (i.e. they call functions or send Ether)
        // into three phases:
        // 1. checking conditions
        // 2. performing actions (potentially changing conditions)
        // 3. interacting with other contracts
        // If these phases are mixed up, the other contract could call
        // back into the current contract and modify the state or cause
        // effects (ether payout) to be performed multiple times.
        // If functions called internally include interaction with external
        // contracts, they also have to be considered interaction with
        // external contracts.

        // 1. Conditions
        require(!ended, "auctionEnd has already been called.");
        require(msg.sender == deployer, "You are not the auction deployer!");

        // 2. Effects
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. Interaction
        beneficiary.transfer(highestBid);
    }
}
>>>>>>> trunk