// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../Templates/Shipment.sol";
import "../../Templates/Stakeholders.sol";

/* 
The source code is fetched from https://github.com/fairouzK/NFTs-for-FCL-Digital-Twins/blob/main/Manager.sol

The transportation of the NFT container is refactored as MariSmart contracts, where

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

- shipper is the shipper
- receiver is the consignee
- agent and sea transporters are carrier
- exportCustoms and port transporters are export port operator
- importCustoms and port transporters are import port operator

The workflow is concluded as follows
- placeShipmentRequest is create, and ShipmentState.RequestPlaced is created
- assignContainerId is sign for carrier, and ShipmentState.BoLIssued is signed
- exportCustomsClearance and exportHaulage are export, and ShipmentState.InExportHaulage is exported
- oceanHaulage is depart, and ShipmentState.InOceanHaulage is departed
- importCustomsClearance and importHaulage are import, and ShipmentState.InImportHaulage is imported
- shipmentDeliveryConfirmation is receive and ShipmentState.Delivered is received
- 

- ShipmentState is the state in Shipment contract, where
- Requested is created
- ContainerIdAssigned and NFTMinted represent the state when the shipper and carrier confirm the shipment, so they are represented by signed
- The state BoLIssued and Departed are reached successively in the same function issueBoL. From user's perspective, the state is updated to BoLIssued and turns to Departed immediately. Therefore we represent them as departed.
- Notebaly, arrived is not directly defined in the original contract. Instead, the state is updated directly from Departed to Claimed in claimCargo, where consignee tries to receive the shipment. We represent the Claimed and DestinationReached as received.
- Auctioned and AuctionApproved are rearranged
- The shipment is closed when NFT is burnt

- requestShipment is create
- approveShipmentRequest and createNFT are sign
- issueBoL is depart
- claimCargo and shipmentDelivered are receive
- auctionCargo and auctionApproval are rearrange
- burnContainerNFT is close


- Payment is not implemented in this system. It is considered to be done offline and the BoL is stored, so the transportation_fee, down_payment and price is set to 0

- The original contract implements the reselling, but no receive valid period is assigned. The function claimCargo and auctionCargo are competing.

Several kinds of id are used in the contract, where
- shipmentId is the id of the shipment, which is replaced by UID in MariSmart
- containerID is assigned when requestapproved, which is replaced by container_id in shipment contract and accessed by getter and setter
- nftId is the id of the NFT, which is minted at creation, and accessed by getter and setter

*/

contract FormattedShipment is Shipment {
    string container_id;

    function setContainerId(
        string memory _container_id
    ) public onlyStakeholder {
        container_id = _container_id;
    }

    function getContainerId()
        public
        view
        onlyStakeholder
        returns (string memory)
    {
        return container_id;
    }

    constructor() payable {
        price = 0;
        down_payment = price;
        escrow_thresholds[shipper] = 0;
        escrow_thresholds[consignee] = 0;
        escrow_thresholds[carrier] = 0;
        signatures[msg.sender] = true;
        balances[msg.sender] += msg.value;
    }

    function sign() external payable override pre_sign {
        // only delete requirement for pre-shipment-inspector
        signatures[msg.sender] = true;
        emit StakeholderSign(msg.sender, block.timestamp);
        if (
            signatures[shipper] == true &&
            signatures[carrier] == true &&
            signatures[consignee] == true &&
            signatures[export_port_operator] == true &&
            signatures[import_port_operator] == true
        ) {
            state = State.signed;
            emit ShipmentSigned(msg.sender, block.timestamp);
        }
    }

    modifier pre_importShipment() override {
        require(state == State.departed, "Container not in Origin Port");
        _;
    }
    modifier pre_receiveShipment() override {
        require(state == State.imported, "Container not in Destination Port");
        _;
    }
    modifier pre_inspect() override {
        require(false, "deprecated");
        _;
    }
    modifier pre_exportShipment() override {
        require(state == State.signed, "Container not signed");
        _;
    }
    modifier pre_rearrange() override {
        require(false, "deprecated");
        _;
    }
    modifier pre_reportLoss() override {
        require(false, "deprecated");
        _;
    }
    modifier pre_reportDamage() override {
        require(false, "deprecated");
        _;
    }
    modifier pre_claim() override {
        require(false, "deprecated");
        _;
    }
    modifier pre_compensate() override {
        require(false, "deprecated");
        _;
    }
    modifier pre_close() override {
        require(
            state == State.rearranged ||
                state == State.received ||
                (state == State.created &&
                    block.timestamp > create_time + sign_valid)
        );
        _;
    }
}

contract FormattedShipper is Shipper {
    event ShipmentRequestPlaced(address requester, uint256 requestId);

    /* custom variable here */
    function create(
        uint _escrow_amount
    ) public override onlyOwner returns (uint) {
        // from requestShipment
        FormattedShipment shipment = new FormattedShipment{
            value: _escrow_amount
        }();
        uid_counter += 1;
        shipments[uid_counter] = address(shipment);
        emit ShipmentRequestPlaced(msg.sender, uid_counter);
        return uid_counter;
    }

    function withdraw(uint _UID) public override onlyOwner {
        FormattedShipment(shipments[_UID]).withdraw();
    }

    function close(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).close();
    }
    /* custom function here */
}

contract FormattedCarrier is Carrier {
    event BoLIssuedAndStored(address _shipper, uint256 requestId, string _bol);
    event ShipmentApproved(
        address requester,
        uint256 requestId,
        string containerId
    );
    event ContainerLoadedToVessel(
        address shipper,
        uint256 shipmentId,
        string _containerId
    );

    function sign(
        address _shipment,
        string memory containerid,
        string memory bol
    ) public onlyOwner returns (uint) {
        uint escrow_amount = FormattedShipment(_shipment).getEscrowThresholds(
            address(this)
        );
        FormattedShipment(_shipment).sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = _shipment;
        FormattedShipment(_shipment).setContainerId(containerid);
        emit ShipmentApproved(
            FormattedShipment(_shipment).getShipper(),
            uid_counter,
            containerid
        );
        emit BoLIssuedAndStored(
            FormattedShipment(_shipment).getShipper(),
            uid_counter,
            bol
        );

        return uid_counter;
    }

    function withdraw(uint _UID) public override onlyOwner {
        FormattedShipment(shipments[_UID]).withdraw();
    }

    function depart(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        emit ContainerLoadedToVessel(
            FormattedShipment(shipments[_UID]).getShipper(),
            _UID,
            FormattedShipment(shipments[_UID]).getContainerId()
        );
        FormattedShipment(shipments[_UID]).depart();
    }

    function close(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).close();
    }
}

contract FormattedConsignee is Consignee {
    event ShipmentDelivered(address shipper, uint256 shipmentId);

    function sign(address _shipment) public override onlyOwner returns (uint) {
        uint escrow_amount = FormattedShipment(_shipment).getEscrowThresholds(
            address(this)
        );
        FormattedShipment(_shipment).sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = _shipment;
        return uid_counter;
    }

    function withdraw(uint _UID) public override onlyOwner {
        FormattedShipment(shipments[_UID]).withdraw();
    }

    function receiveShipment(
        uint _UID,
        bool _is_passed
    ) public virtual override onlyOwner {
        /* custom logic here */
        emit ShipmentDelivered(
            FormattedShipment(shipments[_UID]).getShipper(),
            _UID
        );
        FormattedShipment(shipments[_UID]).receiveShipment(_is_passed);
    }
}

contract FormattedExportPortOperator is ExportPortOperator {
    event ShipmentExportCleared(address shipper, uint256 shipmentId);

    function sign(address _shipment) public override onlyOwner returns (uint) {
        uint escrow_amount = FormattedShipment(_shipment).getEscrowThresholds(
            address(this)
        );
        FormattedShipment(_shipment).sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = _shipment;
        return uid_counter;
    }

    function withdraw(uint _UID) public override onlyOwner {
        FormattedShipment(shipments[_UID]).withdraw();
    }

    function exportShipment(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).exportShipment();
        emit ShipmentExportCleared(
            FormattedShipment(shipments[_UID]).getShipper(),
            _UID
        );
    }
}

contract FormattedImportPortOperator is ImportPortOperator {
    event ShipmentImportCleared(address shipper, uint256 shipmentId);

    function sign(address _shipment) public override onlyOwner returns (uint) {
        uint escrow_amount = FormattedShipment(_shipment).getEscrowThresholds(
            address(this)
        );
        FormattedShipment(_shipment).sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = _shipment;
        return uid_counter;
    }

    function withdraw(uint _UID) public override onlyOwner {
        FormattedShipment(shipments[_UID]).withdraw();
    }

    function importShipment(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).importShipment();
        emit ShipmentImportCleared(
            FormattedShipment(shipments[_UID]).getShipper(),
            _UID
        );
    }
}
