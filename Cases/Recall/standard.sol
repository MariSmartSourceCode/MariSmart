// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../Templates/Stakeholders.sol";
import "../../Templates/Shipment.sol";

/* 
The source code is fetched from https://github.com/PratyushKumarPatro/Automotive-Recall/blob/main/Automotive_Recall.sol

The contract mainly implements a recall system for automotive industry, including reporting defect, inspecting, requiring automobile parts, and sending service vehicle. We mainly focus on the transportation from automobile parts supplier to the automaker in contract Correctiveactionhandler.

- Automaker is consignee
- AutomobilePartsSupplier is shipper and carrier

- The contract contains different structs for events, such as PlacePurchaseOrder. Each structs contains 5 states, namely Pending, Accepted, Rejected, Received, Shipped.
- PlacePurchaseOrder.Pending is created
- PlacePurchaseOrder.Accepted is signed
- PlacePurchaseOrder.Rejected is closed
- ShipmentDetails.pending is departed
- ShipmentDetails.Accepted is received
- ShipmentDetails.Rejected is closed

- PlacePurchaseOrder is create of Consignee
- ConfirmPurchaseOrder is sign of Shipper
- CreateShipmentNotice is depart of Carrier
- ConfirmShipmentReceive is receiveShipment of Consignee
*/

contract FormattedShipment is Shipment {
    string partnumber;
    uint requestedpartquantity;

    function setPartnumber(string memory _partnumber) public onlyStakeholder {
        partnumber = _partnumber;
    }

    function getPartnumber() public view returns (string memory) {
        return partnumber;
    }

    function setRequestedpartquantity(
        uint _requestedpartquantity
    ) public onlyStakeholder {
        requestedpartquantity = _requestedpartquantity;
    }

    function getRequestedpartquantity() public view returns (uint) {
        return requestedpartquantity;
    }

    constructor() payable {
        shipper = msg.sender;
        price = 0;
        down_payment = 0;
        transportation_fee = 0;
        escrow_thresholds[shipper] = 0;
        escrow_thresholds[consignee] = 0;
        escrow_thresholds[carrier] = 0;
        signatures[msg.sender] = true;
        balances[msg.sender] += msg.value;
    }

    function sign() external payable virtual override pre_sign {
        signatures[msg.sender] = true;
        balances[msg.sender] += msg.value;
        emit StakeholderSign(msg.sender, block.timestamp);
        if (
            signatures[shipper] == true &&
            signatures[carrier] == true &&
            signatures[consignee] == true
        ) {
            state = State.signed;
            emit ShipmentSigned(msg.sender, block.timestamp);
        }
    }

    modifier pre_depart() override {
        require(state == State.signed);
        _;
    }
    modifier pre_arrive() override {
        require(false, "deperated");
        _;
    }
    modifier pre_receiveShipment() override {
        require(state == State.departed);
        _;
    }
    modifier pre_close() override {
        require(
            (state == State.signed && msg.sender == shipper) ||
                state == State.received ||
                (state == State.departed && msg.sender == consignee)
        );
        _;
    }
}

contract FormattedShipper is Shipper {
    uint Availableinventory = 20;
    event PurchaseOrderConfirmed(
        uint PurchaseOrderID,
        address Receiver2,
        uint availableinventory,
        uint quantityrequested
    );

    /* custom variable here */

    function sign(
        address _shipment,
        uint quantitytoship,
        bool accepted
    ) public virtual onlyOwner returns (uint) {
        uint escrow_amount = FormattedShipment(_shipment).getEscrowThresholds(
            address(this)
        );
        require(Availableinventory >= quantitytoship);
        Availableinventory -= quantitytoship;
        if (accepted) {
            FormattedShipment(_shipment).sign{value: escrow_amount}();
        } else {
            FormattedShipment(_shipment).close();
        }
        emit PurchaseOrderConfirmed(
            uid_counter,
            FormattedShipment(_shipment).getConsignee(),
            Availableinventory,
            quantitytoship
        );

        FormattedShipment(_shipment).sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = _shipment;
        return uid_counter;
    }

    function close(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).close();
    }

    /* custom function here */
}

contract FormattedCarrier is Carrier {
    event ShipmentNoticeCreated(
        uint ShipmentNoticeID,
        address sender,
        address receiver1
    );

    function close(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).close();
    }

    function sign(address _shipment) public override onlyOwner returns (uint) {
        uint escrow_amount = FormattedShipment(_shipment).getEscrowThresholds(
            address(this)
        );
        uid_counter += 1;
        shipments[uid_counter] = _shipment;
        FormattedShipment(_shipment).sign{value: escrow_amount}();
        return uid_counter;
    }

    function depart(uint _UID) public override onlyOwner {
        FormattedShipment(shipments[_UID]).depart();
        emit ShipmentNoticeCreated(
            _UID,
            FormattedShipment(shipments[_UID]).getConsignee(),
            msg.sender
        );
    }
}

contract FormattedConsignee is Consignee {
    event PurchaseOrderPlaced(
        uint PurchaseOrderID,
        address receiver,
        address requestor,
        string Partnumber,
        uint requestedpartquantity
    );

    /* custom function here */
    function create(
        uint _escrow_amount,
        address receiver,
        string memory Partnumber,
        uint _requestedpartquantity
    ) public onlyOwner returns (uint) {
        FormattedShipment shipment = new FormattedShipment{
            value: _escrow_amount
        }();
        /* custom logic here */
        uid_counter += 1;
        shipment.setPartnumber(Partnumber);
        shipment.setRequestedpartquantity(_requestedpartquantity);
        shipments[uid_counter] = address(shipment);
        emit PurchaseOrderPlaced(
            uid_counter,
            receiver,
            msg.sender,
            Partnumber,
            _requestedpartquantity
        );
        return uid_counter;
    }

    function receiveShipment(
        uint _UID,
        bool received
    ) public override onlyOwner {
        if (received) {
            FormattedShipment(shipments[_UID]).receiveShipment(false);
        } else {
            FormattedShipment(shipments[_UID]).close();
        }
    }
}
