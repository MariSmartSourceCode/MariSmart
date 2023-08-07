// SPDX-License-Identifier: MIT
// implemented by Elmay et al. in https://github.com/fairouzK/Container-NFT/blob/main/containerNFT.sol
pragma solidity ^0.8.0;
import "./@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/utils/Counters.sol";

contract ContainerNFT is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Events
    event NFTmintedForContainer(uint256 id, address b);

    address managerContract = address(0);
    modifier onlyManagerContract() {
        require(msg.sender == managerContract);
        _;
    }

    constructor() ERC721("ContainerNFT", "CNFT") {}

    function setManagerContractAddr(address addr) public onlyOwner {
        managerContract = addr;
    }

    function safeMint(address to) public onlyManagerContract returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        emit NFTmintedForContainer(tokenId, to);
        return tokenId;
    }

    /*
     The first time, the owner will call this function 
     directly, but the second ownership transfer can happen 
     from the manager contract since it will be approved. 
    */
    function approveOperator(uint256 nftId) public {
        if (getApproved(nftId) != managerContract) {
            approve(managerContract, nftId);
        }
    }

    function burnNFT(uint256 tokenId) public onlyManagerContract {
        _burn(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}

interface IERC721Auc {
    function transfer(address, uint256) external;

    function transferFrom(address, address, uint256) external;

    function approve(address, uint256) external;
}

contract AuctionNFT {
    address public seller; // This is the Customs/Port/Warehouse/Shipping Line

    mapping(address => uint256) public bids;
    mapping(uint256 => bool) public started;
    mapping(uint256 => bool) public ended;
    mapping(uint256 => uint256) public endAt;
    mapping(uint256 => uint256) public highestBid;
    mapping(uint256 => address) public highestBidder;

    event AuctionStarted(uint256 NFTId);
    event AuctionEnded(
        uint256 NFTId,
        address winningBidder,
        uint256 highestBid
    );
    event Bid(uint256 tokenId, address indexed sender, uint256 highestBid);

    address containerNFT_addr;
    address Owner;

    constructor() {
        Owner = msg.sender;
        containerNFT_addr = address(7);
    }

    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    function start(uint256 NFTId, uint256 startingBid) external onlyOwner {
        require(!started[NFTId], "Aready Started!");
        require(!ended[NFTId], "Aready Ended!");
        highestBid[NFTId] = startingBid; // Starting Bid
        started[NFTId] = true;
        endAt[NFTId] = block.timestamp + 2 days; // Bidding Duration
        emit AuctionStarted(NFTId);
    }

    // Does not require the amount to be in ethers.
    function bid(uint256 NFTId, uint256 amount) external {
        require(started[NFTId], "Not started.");
        require(block.timestamp < endAt[NFTId], "Ended!");
        require(!ended[NFTId], "Auction already ended!");
        require(amount > highestBid[NFTId]);

        highestBid[NFTId] = amount;
        highestBidder[NFTId] = msg.sender;

        emit Bid(NFTId, highestBidder[NFTId], highestBid[NFTId]);
    }

    function end(uint256 NFTId) external onlyOwner {
        require(started[NFTId], "You  need to start the auction first!");
        require(block.timestamp >= endAt[NFTId], "Auction is still ongoing!");
        require(!ended[NFTId], "Auction already ended!");
        if (highestBidder[NFTId] != address(0)) {
            ContainerNFT(containerNFT_addr).transferFrom(
                address(this),
                highestBidder[NFTId],
                NFTId
            );
        }

        ended[NFTId] = true;
        emit AuctionEnded(NFTId, highestBidder[NFTId], highestBid[NFTId]);
    }

    // Getter functions
    function getHighestBidder(uint256 NFTId) external view returns (address) {
        return highestBidder[NFTId];
    }

    function getHighestBid(uint256 NFTId) external view returns (uint256) {
        return highestBid[NFTId];
    }
}
