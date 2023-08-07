// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../Templates/Shipment.sol";

contract NFTShipment is Shipment {
    uint NFTID;

    constructor() {
        shipper = address(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
        consignee = address(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);
        carrier = address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
    }

    function setNFTID(uint _NFTID) external {
        require(msg.sender == shipper);
        NFTID = _NFTID;
    }

    function getNFTID() external view returns (uint) {
        return NFTID;
    }
}
