// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../Templates/Shipment.sol";

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
