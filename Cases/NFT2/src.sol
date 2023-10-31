// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./NFTMinter.sol";

contract Manager {
    using Counters for Counters.Counter;

    Counters.Counter private _shipmentID;

    enum ShipmentState {
        RequestPlaced,
        ContainerIdAssigned,
        DTCreated,
        BoLIssued,
        NFTMinted,
        InExportHaulage,
        ExportCustomsCleared,
        InOceanHaulage,
        ImportCustomsCleared,
        Claimed,
        ClaimApproved,
        InImportHaulage,
        Delivered
    }

    struct ContainerDetails {
        uint256 containerNFTId;
        string containerId;
        // mapping(uint256 => address) shipments;
        // mapping(address => uint256) shipmentsNFTs;
        ShipmentState cStatus;
    }

    mapping(address => mapping(uint256 => ContainerDetails)) shipment;

    event ShipmentRequestPlaced(address requester, uint256 requestId);
    event ShipmentApproved(
        address requester,
        uint256 requestId,
        string containerId
    );
    event BoLIssuedAndStored(
        address shipper,
        uint256 shipmentId,
        string _bolLink
    );
    event ShipmentExportCleared(address shipper, uint256 shipmentId);
    event ShipmentImportCleared(address shipper, uint256 shipmentId);
    event ShipmentClaimed(
        address shipper,
        address _receiver,
        uint256 shipmentId,
        string bolLink
    );
    event ShipmentClaimApproved(
        address shipper,
        address _receiver,
        uint256 shipmentId
    );
    event ShipmentDelivered(address shipper, uint256 shipmentId);
    event DTDataStoredInIPFS(
        address shipper,
        uint256 shipmentId,
        string _dtData
    );
    event DTApprovedAndCreated(
        address _invoker,
        address shipper,
        uint256 shipmentId
    );
    event ChildNFTAdded(uint256 _shipmentNFTId);
    event ContainerMetadataUpdated(string _containerId);
    event ContainerLoadedToVessel(
        address shipper,
        uint256 shipmentId,
        string _containerId
    );

    // address private contractOwner;
    address agent;
    address shipper;
    address receiver;
    address vesselOwner;
    address truckDriver;
    address private companyAddr;
    address minterContract;
    address exportCustoms;
    address importCustoms;
    address designManager;

    constructor() {
        companyAddr = msg.sender; //0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C
        agent = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        designManager = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
        shipper = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        receiver = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        vesselOwner = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;
        truckDriver = 0x17F6AD8Ef982297579C203069C1DbfFE4348c372;
        exportCustoms = 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678;
        importCustoms = 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7;
    }

    // Modifiers
    modifier onlyCompany() {
        require(msg.sender == companyAddr);
        _;
    }
    modifier onlyAgent() {
        require(msg.sender == agent);
        _;
    }
    modifier onlyMinter() {
        require(msg.sender == agent || msg.sender == shipper);
        _;
    }
    modifier onlyReceiver() {
        require(msg.sender == receiver);
        _;
    }
    modifier onlyTransporter() {
        require(msg.sender == vesselOwner || msg.sender == truckDriver);
        _;
    }
    modifier onlyExportCustoms() {
        require(msg.sender == exportCustoms);
        _;
    }
    modifier onlyImportCustoms() {
        require(msg.sender == importCustoms);
        _;
    }
    modifier onlyDesignManager() {
        require(msg.sender == designManager);
        _;
    }

    function setMinterContractAddr(address addr) public onlyCompany {
        minterContract = addr;
    }

    function placeShipmentRequest() public {
        uint256 requestId = _shipmentID.current();
        shipment[msg.sender][requestId].cStatus = ShipmentState.RequestPlaced;

        _shipmentID.increment();
        emit ShipmentRequestPlaced(msg.sender, requestId);
    }

    // Where documents are verified, and container ID is assigned
    function assignContainerId(
        address requester,
        uint256 requestID,
        string memory _containerId,
        string memory bol
    ) public onlyAgent {
        shipment[requester][requestID].containerId = _containerId;
        shipment[requester][requestID].cStatus = ShipmentState
            .ContainerIdAssigned;

        emit ShipmentApproved(requester, requestID, _containerId);

        require(
            shipment[requester][requestID].cStatus ==
                ShipmentState.ContainerIdAssigned,
            "Shipment is not approved!"
        );

        shipment[requester][requestID].cStatus = ShipmentState.BoLIssued;
        emit BoLIssuedAndStored(shipper, requestID, bol);
    }

    /*
    This request can be submitted any time, before bol issuance or after, 
    and either by shipper or agent
    */
    function createDTRequest(
        string memory _dtData,
        address _shipper,
        uint256 _shipmentId
    ) public onlyMinter {
        emit DTDataStoredInIPFS(_shipper, _shipmentId, _dtData);
    }

    function approveDT(
        address _shipper,
        uint256 _shipmentId
    ) public onlyDesignManager {
        require(
            shipment[_shipper][_shipmentId].cStatus == ShipmentState.BoLIssued,
            "Invalid Request, BoL not issued!"
        );

        shipment[_shipper][_shipmentId].cStatus = ShipmentState.DTCreated;
        emit DTApprovedAndCreated(msg.sender, _shipper, _shipmentId);
    }

    function exportCustomsClearance(
        address _shipper,
        uint256 _shipmentId
    ) public onlyExportCustoms {
        require(
            shipment[_shipper][_shipmentId].cStatus == ShipmentState.DTCreated,
            "Shipment DT not approved"
        );

        shipment[_shipper][_shipmentId].cStatus = ShipmentState
            .ExportCustomsCleared;

        emit ShipmentExportCleared(_shipper, _shipmentId);
    }

    function createContainerNFT(
        address _shipper,
        uint256 _shipmentId,
        string memory metadatauri
    ) public onlyAgent {
        require(
            shipment[_shipper][_shipmentId].cStatus ==
                ShipmentState.ExportCustomsCleared,
            "Shipment not Cleared for Export!"
        );

        // shipment[_shipper][requestID].cStatus = ShipmentState.ContainerExportCleared;

        shipment[_shipper][_shipmentId].containerNFTId = NFTMinter(
            minterContract
        ).safeMint(companyAddr, metadatauri);
        shipment[_shipper][_shipmentId].cStatus = ShipmentState.NFTMinted;
    }

    function exportHaulage(
        address _shipper,
        uint256 _shipmentId
    ) public onlyTransporter {
        require(
            shipment[_shipper][_shipmentId].cStatus == ShipmentState.NFTMinted,
            "Container Shipment NFT not minted!"
        );
        shipment[_shipper][_shipmentId].cStatus = ShipmentState.InExportHaulage;
    }

    function oceanHaulage(
        address _shipper,
        uint256 _shipmentId,
        string memory _containerId
    ) public onlyTransporter {
        require(
            shipment[_shipper][_shipmentId].cStatus ==
                ShipmentState.InExportHaulage,
            "Container not in Origin Port"
        );
        shipment[_shipper][_shipmentId].cStatus = ShipmentState.InOceanHaulage;
        emit ContainerLoadedToVessel(_shipper, _shipmentId, _containerId);
    }

    function importCustomsClearance(
        address _shipper,
        uint256 _shipmentId
    ) public onlyImportCustoms {
        require(
            shipment[_shipper][_shipmentId].cStatus ==
                ShipmentState.InOceanHaulage,
            "Container not in Destination Port"
        );
        shipment[_shipper][_shipmentId].cStatus = ShipmentState
            .ImportCustomsCleared;
        emit ShipmentImportCleared(_shipper, _shipmentId);
    }

    function claimShipment(
        address _shipper,
        uint256 _shipmentId,
        string memory bolLink
    ) public onlyReceiver {
        require(
            shipment[_shipper][_shipmentId].cStatus ==
                ShipmentState.ImportCustomsCleared,
            "Shipment not yet cleared for import!"
        );

        shipment[_shipper][_shipmentId].cStatus = ShipmentState.Claimed;
        emit ShipmentClaimed(_shipper, msg.sender, _shipmentId, bolLink);
    }

    function shipmentClaimApproval(
        address _shipper,
        uint256 _shipmentId
    ) public onlyAgent {
        require(
            shipment[_shipper][_shipmentId].cStatus == ShipmentState.Claimed,
            "Shipment not claimed!"
        );

        shipment[_shipper][_shipmentId].cStatus = ShipmentState.ClaimApproved;
        emit ShipmentClaimApproved(_shipper, msg.sender, _shipmentId);
    }

    function importHaulage(
        address _shipper,
        uint256 _requestID
    ) public onlyTransporter {
        require(
            shipment[_shipper][_requestID].cStatus ==
                ShipmentState.ClaimApproved,
            "Shipment claim not approved!"
        );
        shipment[_shipper][_requestID].cStatus = ShipmentState.InImportHaulage;
    }

    function shipmentDeliveryConfirmation(
        address _shipper,
        uint256 _shipmentId
    ) public onlyReceiver {
        require(
            shipment[_shipper][_shipmentId].cStatus ==
                ShipmentState.InImportHaulage
        );
        shipment[_shipper][_shipmentId].cStatus = ShipmentState.Delivered;

        emit ShipmentDelivered(_shipper, _shipmentId);
    }
}

/*
    FCL Container Metadata Template
    {
        Container Number:  
        Type: FCL 
        DigitalTwin data: (Exported Graph data)
        3D model: (link)
        Image:
        Bill Of Lading:                
    }

*/
