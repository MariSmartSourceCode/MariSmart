// SPDX-License-Identifier: MIT
// a contract for maritime shipment
pragma solidity ^0.8.0;
import "./IShipment.sol";
import "./Shipment.sol";

contract Stakeholder {
    address owner;
    uint uid_counter;
    mapping(uint => address) shipments;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        uid_counter = 0;
    }

    function sign(address _shipment) public virtual onlyOwner returns (uint) {
        uint escrow_amount = IShipment(_shipment).getEscrowThresholds(
            address(this)
        );
        IShipment(_shipment).sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = _shipment;
        return uid_counter;
    }

    function withdraw(uint _UID) public virtual onlyOwner {
        (IShipment(shipments[_UID])).withdraw();
    }

    function externalTransfer(
        uint _UID,
        address _to,
        uint _amount
    ) public virtual onlyOwner {
        Shipment(shipments[_UID]).externalTransfer(_to, _amount);
    }
}

contract Shipper is Stakeholder {
    /* custom variable here */

    constructor() {
        /* custom initialization here */
    }

    function create(
        uint escrow_amount
    ) public virtual onlyOwner returns (uint) {
        IShipment shipment = new Shipment{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = address(shipment);
        return uid_counter;
    }

    function cancel(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).cancel();
    }

    function claim(
        uint _UID,
        uint _compensation_amount
    ) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).claim(_compensation_amount);
    }

    function close(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).close();
    }
    /* custom function here */
}

contract Carrier is Stakeholder {
    /* custom variable here */

    constructor() {
        /* custom initialization here */
    }

    function depart(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).depart();
    }

    function reportLoss(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).reportLoss();
    }

    function reportDamage(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).reportDamage();
    }

    function arrive(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).arrive();
    }

    function compensate(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).compensate();
    }

    function rearrange(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).rearrange();
    }

    function close(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).close();
    }

    /* custom function here */
}

contract ExportPortOperator is Stakeholder {
    /* custom variable here */

    constructor() {
        /* custom initialization here */
    }

    function exportShipment(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).exportShipment();
    }
    /* custom function here */
}

contract ImportPortOperator is Stakeholder {
    /* custom variable here */

    constructor() {
        /* custom initialization here */
    }

    function importShipment(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).importShipment();
    }

    /* custom function here */
}

contract PreshipmentInspector is Stakeholder {
    /* custom variable here */

    constructor() {
        /* custom initialization here */
    }

    function inspect(uint _UID, bool _is_passed) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).inspect(_is_passed);
    }
    /* custom function here */
}

contract Consignee is Stakeholder {
    /* custom variable here */

    constructor() {
        /* custom initialization here */
    }

    function receiveShipment(
        uint _UID,
        bool _is_passed
    ) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).receiveShipment(_is_passed);
    }

    function claim(
        uint _UID,
        uint _compensation_amount
    ) public virtual onlyOwner {
        /* custom logic here */
        Shipment(shipments[_UID]).claim(_compensation_amount);
    }
    /* custom function here */
}
