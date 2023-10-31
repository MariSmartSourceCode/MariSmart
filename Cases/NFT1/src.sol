// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ShipmentManager {
    using Counters for Counters.Counter;

    Counters.Counter private _shipmentRequestID;

    enum ShipmentState {
        Requested,
        ContainerIdAssigned,
        NFTMinted,
        BoLIssued,
        Departed,
        Claimed,
        ClaimApproved,
        DestinationReached,
        Auctioned,
        AuctionApproved
    }

    struct ShipmentDetails {
        uint256 NFTId;
        string containerId;
        string metadataLink;
        ShipmentState sStatus;
        string bolLink;
        mapping(string => string) relatedDocuments; // Map document name with its ipfs link
    }

    // Map the shipper, requestId and shipment details struct
    mapping(address => mapping(uint256 => ShipmentDetails)) shipmentRequest;

    // Events
    event ShipmentRequested(
        uint256 requestId,
        address requester,
        string destination
    );
    event ShipmentApprovedAndContainerIDAssigned(
        address a,
        uint256 id,
        string containerId
    );
    event BoLIssuedAndStored(address _shipper, uint256 requestId, string _bol);
    event DocumentIssuedAndStored(
        address _shipper,
        uint256 requestId,
        string _bol
    );
    event CargoClaimRequested(
        address receiver,
        address sender,
        uint256 shipmentId,
        string metadataLink
    );
    event CargoAuctionRequested(
        address receiver,
        address sender,
        uint256 shipmentId,
        uint256 tokenId
    );
    event shipmentDeliveredSuccessfully(address sender, uint256 shipmentId);
    event ContainerNFTBurnt(address burner, uint256 tokenId);
    event AuctionApprovedAndNFTTransferredToAuctionSC(uint256 tokenId);

    // IERC721Man public containerNFT;
    address private contractOwner;
    address agent;
    address shipper;
    address receiver;
    address transporter;

    constructor() {
        contractOwner = msg.sender;
        agent = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        shipper = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        receiver = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
        transporter = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;
    }

    // Modifiers
    modifier onlyContractOwner() {
        require(msg.sender == contractOwner);
        _;
    }
    modifier onlyAgent() {
        require(msg.sender == agent);
        _;
    }
    modifier onlyShipper() {
        require(msg.sender == shipper);
        _;
    }
    modifier onlyReceiver() {
        require(msg.sender == receiver);
        _;
    }
    modifier onlyAuctioners() {
        require(msg.sender == receiver || msg.sender == agent);
        _;
    }

    // Set the minter contract address
    address minterContract;

    function setMinterContractAddr(address addr) public onlyContractOwner {
        minterContract = addr;
    }

    // Set the auction contract address
    // address auctionContract;

    // function setAuctionContractAddr(address addr) public onlyContractOwner {
    //     auctionContract = addr;
    // }

    function getContainerState(
        address requester,
        uint256 requestId
    ) public view returns (ShipmentState) {
        return shipmentRequest[requester][requestId].sStatus;
    }

    /*
     For this function, the origin and destination are not 
     necessary to be implemented in smart contract, 
     but are included for the sake of logic flow only 
    */
    function requestShipment(string memory s_destination) public {
        uint256 requestId = _shipmentRequestID.current();
        shipmentRequest[msg.sender][requestId].sStatus = ShipmentState
            .Requested;
        // ContainerNFT(minterContract).setApprovalForAll(Agent, true);
        emit ShipmentRequested(requestId, msg.sender, s_destination);

        _shipmentRequestID.increment();
    }

    // The shipping agent approves the required documents and assigns the shipping container number
    function approveShipmentRequest(
        address requester,
        uint256 requestID,
        string memory containerid
    ) public onlyAgent {
        shipmentRequest[requester][requestID].sStatus = ShipmentState
            .ContainerIdAssigned;
        shipmentRequest[requester][requestID].containerId = containerid; //can be set using js
        emit ShipmentApprovedAndContainerIDAssigned(
            requester,
            requestID,
            containerid
        );
    }

    // The shipper mints the NFT to his address including the assigned shipping container number
    function createNFT(
        uint256 requestID,
        string memory uri
    ) public onlyShipper {
        require(
            shipmentRequest[msg.sender][requestID].sStatus ==
                ShipmentState.ContainerIdAssigned,
            "Invalid Request. Container number not assigned!"
        );

        shipmentRequest[msg.sender][requestID].NFTId = ContainerNFT(
            minterContract
        ).safeMint(msg.sender, uri);

        shipmentRequest[msg.sender][requestID].sStatus = ShipmentState
            .NFTMinted;
        // An "NFT minted" event is emitted from the minter contract
    }

    /* 
        The shipper aproves this contract to manage the token using ApproveOperator() 
        from ContainerNFT SC
    */

    // After the NFT is minted, the agent issues the BoL and store it on the IPFS
    function issueBoL(
        address _shipper,
        uint256 requestID,
        address _transporter,
        string memory bol
    ) public onlyAgent {
        require(
            shipmentRequest[_shipper][requestID].sStatus ==
                ShipmentState.NFTMinted,
            "Container NFT not minted!"
        );
        uint256 tokenId = shipmentRequest[_shipper][requestID].NFTId;
        require(
            ContainerNFT(minterContract).getApproved(tokenId) == address(this),
            "Agent not approved as operator"
        );

        shipmentRequest[_shipper][requestID].bolLink = bol; // can be set through js or json
        shipmentRequest[_shipper][requestID].sStatus = ShipmentState.BoLIssued;
        emit BoLIssuedAndStored(_shipper, requestID, bol);

        ContainerNFT(minterContract).safeTransferFrom(
            Owner(tokenId),
            _transporter,
            tokenId
        );
        shipmentRequest[_shipper][requestID].sStatus = ShipmentState.Departed;
    }

    /*
        The Container NFT ownership transfer can be done using safeTransferFrom() 
        function in the ContainerNFT smart contract.  
    */

    // function issueDocuments(address _shipper, uint256 requestID, string memory doc, string memory link) public {
    //     shipmentRequest[_shipper][requestID].relatedDocuments[doc] = link;
    //     emit DocumentIssuedAndStored(_shipper, requestID, doc);
    // }

    // To check the current owner of the NFT
    function Owner(uint256 tokenId) public view returns (address) {
        return (ContainerNFT(minterContract).ownerOf(tokenId));
    }

    /*
        For the second ownership transfer only, from the sender to the export hauler
        To make the BoL and physical container exchange smoother, 
        by having the shipping agent take care of the digital process flow
    */
    function transferContainerNFTOwnerShip(
        address shipper,
        uint256 shipmentID,
        address to,
        uint256 tokenId
    ) public {
        require(
            shipmentRequest[shipper][shipmentID].sStatus ==
                ShipmentState.BoLIssued
        );

        ContainerNFT(minterContract).safeTransferFrom(
            Owner(tokenId),
            to,
            tokenId
        );
        // safeTransferFrom emits Transfer(from, to, tokenid) event
    }

    function claimCargo(
        address sender,
        uint256 shipmentId,
        string memory bolLink
    ) public onlyReceiver {
        //onlyReceiver
        require(
            shipmentRequest[sender][shipmentId].sStatus ==
                ShipmentState.Departed,
            "Cargo not yet departed!"
        );

        shipmentRequest[sender][shipmentId].sStatus = ShipmentState.Claimed;
        emit CargoClaimRequested(msg.sender, sender, shipmentId, bolLink);
    }

    function cargoClaimDocumentsApproval(
        address sender,
        uint256 shipmentId
    ) public onlyAgent {
        require(
            shipmentRequest[sender][shipmentId].sStatus ==
                ShipmentState.Claimed,
            "Cargo not claimed!"
        );

        shipmentRequest[sender][shipmentId].sStatus = ShipmentState
            .ClaimApproved;
    }

    function shipmentDelivered(
        address sender,
        uint256 shipmentId
    ) public onlyReceiver {
        require(
            shipmentRequest[sender][shipmentId].sStatus ==
                ShipmentState.ClaimApproved
        );
        shipmentRequest[sender][shipmentId].sStatus = ShipmentState
            .DestinationReached;
        emit shipmentDeliveredSuccessfully(sender, shipmentId);
    }

    function auctionCargo(
        address sender,
        uint256 shipmentId
    ) public onlyAuctioners {
        require(
            shipmentRequest[sender][shipmentId].sStatus != ShipmentState.Claimed
        );
        require(
            shipmentRequest[sender][shipmentId].sStatus !=
                ShipmentState.ClaimApproved
        );

        shipmentRequest[sender][shipmentId].sStatus = ShipmentState.Auctioned;
        uint256 tokenId = shipmentRequest[sender][shipmentId].NFTId;

        emit CargoAuctionRequested(msg.sender, sender, shipmentId, tokenId);
    }

    // When the NFT is auctioned, the transporter or the current owner can transfer the NFT to the customs/ whoever is responsible
    function auctionApproval(
        address sender,
        uint256 shipmentId,
        address auctionSC
    ) public onlyAgent {
        require(
            shipmentRequest[sender][shipmentId].sStatus ==
                ShipmentState.Auctioned
        );
        uint256 tokenId = shipmentRequest[sender][shipmentId].NFTId;
        require(
            ContainerNFT(minterContract).getApproved(tokenId) == address(this),
            "Manager SC is not approved operator yet"
        );

        ContainerNFT(minterContract).transferFrom(
            Owner(tokenId),
            auctionSC,
            tokenId
        );

        shipmentRequest[sender][shipmentId].sStatus = ShipmentState
            .AuctionApproved;
        emit AuctionApprovedAndNFTTransferredToAuctionSC(tokenId);
    }

    function burnContainerNFT(
        address sender,
        uint256 shipmentId,
        uint256 tokenId
    ) public {
        require(
            shipmentRequest[sender][shipmentId].sStatus ==
                ShipmentState.DestinationReached ||
                shipmentRequest[sender][shipmentId].sStatus ==
                ShipmentState.AuctionApproved
        );
        ContainerNFT(minterContract).burnNFT(tokenId);
        emit ContainerNFTBurnt(msg.sender, tokenId);
    }
}

contract ContainerNFT is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Events
    event NFTmintedForContainer(uint256 id, address b);

    address managerContract;
    modifier onlyManagerContract() {
        require(msg.sender == managerContract);
        _;
    }

    constructor() ERC721("ContainerNFT", "CNFT") {}

    function setManagerContractAddr(address addr) public onlyOwner {
        managerContract = addr;
    }

    function safeMint(
        address to,
        string memory uri
    ) public onlyManagerContract returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        // ManageShipment(managerContract).setContainerNFTId(to, requestID, tokenId);
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

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
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

    IERC721Auc public containerNFT;
    address Agent;

    constructor() {
        seller = msg.sender;
        Agent = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    }

    modifier onlyAgent() {
        require(msg.sender == Agent);
        _;
    }
    modifier onlySeller() {
        require(msg.sender == seller);
        _;
    }

    function start(
        IERC721Auc _nft,
        uint256 NFTId,
        uint256 startingBid
    ) external onlyAgent {
        require(!started[NFTId], "Aready Started!");

        containerNFT = _nft;

        highestBid[NFTId] = startingBid; // Staring Bid
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

    function end(uint256 NFTId) external onlyAgent {
        require(started[NFTId], "You  need to start the auction first!");
        require(block.timestamp >= endAt[NFTId], "Auction is still ongoing!");
        require(!ended[NFTId], "Auction already ended!");
        containerNFT.approve(Agent, NFTId);
        if (highestBidder[NFTId] != address(0)) {
            containerNFT.transferFrom(
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

/*
    Metadata Template
    {
        Container Number:  
        Ownership transfer point?
        Shipment Owner:
        Shipment Receiver:
        Shipment Content: 
        Image:
        Bill Of Lading:          
    }
*/
