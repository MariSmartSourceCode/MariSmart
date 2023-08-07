// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../Templates/Shipment.sol";

contract LNGShipment is Shipment {
    constructor() {
        down_payment = price;
        receive_valid = 2 days;
        compensation_valid = 2 days;
        escrow_thresholds[shipper] = transportation_fee + price;
        escrow_thresholds[consignee] = price;
        escrow_thresholds[carrier] = compensation_limit + (price * 3) / 2;
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

    modifier pre_inspect() override {
        require(false, "pre-shipment inspection has already been deperacated");
        _;
    }
    modifier pre_exportShipment() override {
        require(state == State.signed);
        require(msg.sender == export_port_operator);
        _;
    }
}
