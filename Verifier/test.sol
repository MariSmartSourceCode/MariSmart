// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IoTShipment is Shipment {
    constructor() {
        shipper = msg.sender;
        consignee = address(0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB);
        carrier = address(0x583031D1113aD414F02576BD6afaBfb302140225);
        price = 10 ether;
        down_payment = 5 ether;
        receive_valid = 2 days;
        escrow_thresholds[shipper] = transportation_fee;
        escrow_thresholds[consignee] = price;
        escrow_thresholds[carrier] = compensation_limit + down_payment;
    }
}

contract IoTShipper is Shipper {
    /* custom variable here */
    mapping(address => bytes32) public passcode_hashes;

    /* custom function here */
    function create() public override onlyOwner returns (uint) {
        // compared to model, only change the type of the shipment to IoTShipment
        IShipment shipment = new IoTShipment();
        uint escrow_amount = shipment.getEscrowThresholds(address(this));
        shipment.sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = shipment;
        return uid_counter;
    }
}

contract IoTCarrier is Carrier {
    //Violation Events
    event TempertaureViolation(violationType v, uint time); //temperature out of accepted range
    event SuddenJerk(violationType v, uint time);
    event SuddenContainerOpening(violationType v, uint time);
    event OutofRoute(violationType v, uint time);

    enum violationType {
        None,
        Temp,
        Open,
        Route,
        Jerk
    }

    function reportLoss(uint _UID) public onlyOwner {
        shipments[_UID].reportLoss();
        shipments[_UID].externalTransfer(
            shipments[_UID].getConsignee(),
            shipments[_UID].getDownPayment()
        );
    }
}

contract IoTConsignee is Consignee {
    mapping(uint => bytes32) public passcode_hashes;

    function sign(
        address _shipment,
        bytes32 _hash
    ) public onlyOwner returns (uint) {
        uint escrow_amount = IShipment(_shipment).getEscrowThresholds(
            address(this)
        );

        IShipment(_shipment).sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = IShipment(_shipment);
        /* custom logic here */
        passcode_hashes[uid_counter] = _hash;
        return uid_counter;
    }

    function receiveShipment(
        uint _UID,
        string calldata _passcode,
        bool _is_passed
    ) public onlyOwner {
        /* custom logic here */

        require(
            block.timestamp <=
                shipments[_UID].getArriveTime() +
                    shipments[_UID].getReceiveValid()
        );
        shipments[_UID].receiveShipment(_is_passed);
    }
    /* custom function here */
}
