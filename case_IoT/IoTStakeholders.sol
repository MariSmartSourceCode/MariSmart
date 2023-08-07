// SPDX-License-Identifier: MIT
// a contract for maritime shipment
pragma solidity ^0.8.0;
import "../../Templates/Stakeholders.sol";
import "./IoTShipments.sol";

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

    function reportLoss(uint _UID, violationType _v) public onlyOwner {
        shipments[_UID].reportLoss();
        shipments[_UID].externalTransfer(
            shipments[_UID].getConsignee(),
            shipments[_UID].getDownPayment()
        );

        if (_v == violationType.Jerk) {
            emit SuddenJerk(_v, block.timestamp);
        } else if (_v == violationType.Open) {
            emit SuddenContainerOpening(_v, block.timestamp);
        } else if (_v == violationType.Temp) {
            emit TempertaureViolation(_v, block.timestamp);
        } else if (_v == violationType.Route) {
            emit OutofRoute(_v, block.timestamp);
        }
    }
}

contract IoTExportPortOperator is ExportPortOperator {}

contract IoTImportPortOperator is ImportPortOperator {}

contract IoTPreshipmentInspector is PreshipmentInspector {}

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
            IoTShipper(shipments[_UID].getShipper()).passcode_hashes(
                address(shipments[_UID])
            ) == keccak256(abi.encodePacked(_passcode))
        );
        require(
            block.timestamp <=
                shipments[_UID].getArriveTime() +
                    shipments[_UID].getReceiveValid()
        );
        shipments[_UID].receiveShipment(_is_passed);
    }
    /* custom function here */
}
