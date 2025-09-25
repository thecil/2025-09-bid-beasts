// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// @audit - low - incorrect use of Ownable constructor
// contract BidBeasts is ERC721, Ownable(msg.sender) {
contract BidBeasts is ERC721, Ownable {
    event BidBeastsMinted(address indexed to, uint256 indexed tokenId);
    event BidBeastsBurn(address indexed from, uint256 indexed tokenId);

    uint256 public CurrenTokenID;

    constructor() ERC721("Goddie_NFT", "GDNFT") {}

    // @audit - medium - reentrancy
    // @audit https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1
    function mint(address to) public onlyOwner returns (uint256) {
        uint256 _tokenId = CurrenTokenID;
        _safeMint(to, _tokenId);
        // @audit - low should follow CEI
        emit BidBeastsMinted(to, _tokenId);
        CurrenTokenID++;
        return _tokenId;
    }

    function burn(uint256 _tokenId) public {
        _burn(_tokenId);
        // @audit - low - should follow CEI
        emit BidBeastsBurn(msg.sender, _tokenId);
    }
}
