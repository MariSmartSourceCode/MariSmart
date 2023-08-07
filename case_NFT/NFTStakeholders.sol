// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../Templates/Stakeholders.sol";
import "./NFTShipment.sol";
import "./NFTLiabry.sol";

address constant ContainerNFT_addr = address(7);
address constant AuctionNFT_addr = address(8);

contract NFTShipper is Shipper {
    /* custom variable here */

    function create() public override onlyOwner returns (uint) {
        NFTShipment shipment = new NFTShipment();
        uint escrow_amount = shipment.getEscrowThresholds(address(this));
        shipment.sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = shipment;
        /* custom logic here */
        uint NFTId = ContainerNFT(ContainerNFT_addr).safeMint(address(this));
        ContainerNFT(ContainerNFT_addr).approve(shipment.getCarrier(), NFTId);
        shipment.setNFTID(NFTId);
        return uid_counter;
    }

    function cancel(uint _UID) public override onlyOwner {
        shipments[_UID].cancel();
        /* custom logic here */
        ContainerNFT(ContainerNFT_addr).burnNFT(
            NFTShipment(address(shipments[_UID])).getNFTID()
        );
    }
}

contract NFTCarrier is Carrier {
    /* custom variable here */

    function depart(uint _UID) public override onlyOwner {
        shipments[_UID].depart();
        /* custom logic here */
        ContainerNFT(ContainerNFT_addr).transferFrom(
            shipments[_UID].getShipper(),
            address(this),
            NFTShipment(address(shipments[_UID])).getNFTID()
        );
    }

    function arrive(uint _UID) public override onlyOwner {
        shipments[_UID].arrive();
        /* custom logic here */
        ContainerNFT(ContainerNFT_addr).approve(
            shipments[_UID].getConsignee(),
            NFTShipment(address(shipments[_UID])).getNFTID()
        );
    }

    function rearrange(uint _UID) public override onlyOwner {
        shipments[_UID].rearrange();
        /* custom logic here */
        ContainerNFT(ContainerNFT_addr).transferFrom(
            address(this),
            AuctionNFT_addr,
            NFTShipment(address(shipments[_UID])).getNFTID()
        );
        AuctionNFT(AuctionNFT_addr).start(
            NFTShipment(address(shipments[_UID])).getNFTID(),
            shipments[_UID].getPrice()
        );
    }

    function close(uint _UID) public override onlyOwner {
        shipments[_UID].close();
        /* custom logic here */
        AuctionNFT(AuctionNFT_addr).end(
            NFTShipment(address(shipments[_UID])).getNFTID()
        );
    }
    /* custom function here */
}

contract NFTExportPortOperator is ExportPortOperator {}

contract NFTImportPortOperator is ImportPortOperator {}

contract NFTPreshipmentInspector is PreshipmentInspector {}

contract NFTConsignee is Consignee {
    function receiveShipment(
        uint _UID,
        bool _is_passed
    ) public override onlyOwner {
        shipments[_UID].receiveShipment(_is_passed);
        ContainerNFT(ContainerNFT_addr).transferFrom(
            shipments[_UID].getCarrier(),
            address(this),
            NFTShipment(address(shipments[_UID])).getNFTID()
        );
        ContainerNFT(ContainerNFT_addr).burnNFT(
            NFTShipment(address(shipments[_UID])).getNFTID()
        );
    }
}
