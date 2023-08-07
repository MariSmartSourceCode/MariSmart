// SPDX-License-Identifier: MIT
// a contract for maritime shipment
pragma solidity ^0.8.0;
import "../../Templates/Stakeholders.sol";
import "./LNGShipment.sol";

contract LNGShipper is Shipper {
    /* custom variable here */
    function create() public override onlyOwner returns (uint) {
        // compared to model, only change the type of the shipment to IoTShipment
        IShipment shipment = new LNGShipment();
        uint escrow_amount = shipment.getEscrowThresholds(address(this));
        shipment.sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = shipment;
        return uid_counter;
    }

    function cancel(uint _UID, uint _cancellation_fee) public onlyOwner {
        shipments[_UID].cancel();
        /* custom logic here */
        /* letter 7 */
        shipments[_UID].externalTransfer(
            shipments[_UID].getConsignee(),
            _cancellation_fee
        );
    }

    /* custom function here */
}

contract LNGCarrier is Carrier {
    /* custom variable here */
    event estimatedTimeofArrival(uint timestamp, uint prior_time);

    constructor() {
        /* custom initialization here */
    }

    function arrive(uint _UID) public override onlyOwner {
        /* custom logic here */
        /* 7.1.1 */
        shipments[_UID].arrive();
        emit estimatedTimeofArrival(block.timestamp, 0);
    }

    function rearrange(uint _UID, uint _sold_price) public onlyOwner {
        if (_sold_price > shipments[_UID].getPrice()) {
            shipments[_UID].externalTransfer(
                shipments[_UID].getConsignee(),
                shipments[_UID].getPrice()
            );
            shipments[_UID].externalTransfer(
                shipments[_UID].getShipper(),
                _sold_price - shipments[_UID].getPrice()
            );
        } else {
            shipments[_UID].externalTransfer(
                shipments[_UID].getConsignee(),
                _sold_price
            );
        }
        shipments[_UID].close();
    }

    /* custom function here */
    function notify(uint _prior_time) public onlyOwner {
        emit estimatedTimeofArrival(block.timestamp, _prior_time);
    }
}

contract LNGExportPortOperator is ExportPortOperator {}

contract LNGImportPortOperator is ImportPortOperator {}

contract LNGConsignee is Consignee {}
