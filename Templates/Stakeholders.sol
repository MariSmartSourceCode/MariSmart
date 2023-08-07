// SPDX-License-Identifier: MIT
// a contract for maritime shipment
pragma solidity ^0.8.0;
import "./IShipment.sol";
import "./Shipment.sol";

contract Stakeholder {
    address owner;
    uint uid_counter;
    mapping(uint => IShipment) shipments;

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
        shipments[uid_counter] = IShipment(_shipment);
        return uid_counter;
    }

    function withdraw(uint _UID) public virtual onlyOwner {
        shipments[_UID].withdraw();
    }

    function externalTransfer(
        uint _UID,
        address _to,
        uint _amount
    ) public virtual onlyOwner {
        shipments[_UID].externalTransfer(_to, _amount);
    }
}

contract Shipper is Stakeholder {
    /* custom variable here */

    constructor() {
        /* custom initialization here */
    }

    function create() public virtual onlyOwner returns (uint) {
        IShipment shipment = new Shipment();
        uint escrow_amount = shipment.getEscrowThresholds(address(this));
        shipment.sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = shipment;
        return uid_counter;
    }

    function cancel(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        shipments[_UID].cancel();
    }

    function claim(
        uint _UID,
        uint _compensation_amount
    ) public virtual onlyOwner {
        /* custom logic here */
        shipments[_UID].claim(_compensation_amount);
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
        shipments[_UID].depart();
    }

    function reportLoss(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        shipments[_UID].reportLoss();
    }

    function reportDamage(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        shipments[_UID].reportDamage();
    }

    function arrive(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        shipments[_UID].arrive();
    }

    function compensate(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        shipments[_UID].compensate();
    }

    function rearrange(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        shipments[_UID].rearrange();
    }

    function close(uint _UID) public virtual onlyOwner {
        /* custom logic here */
        shipments[_UID].close();
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
        shipments[_UID].exportShipment();
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
        shipments[_UID].importShipment();
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
        if (_is_passed) {
            shipments[_UID].inspect();
        } else {
            shipments[_UID].close();
        }
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
        shipments[_UID].receiveShipment(_is_passed);
    }

    function claim(
        uint _UID,
        uint _compensation_amount
    ) public virtual onlyOwner {
        /* custom logic here */
        shipments[_UID].claim(_compensation_amount);
    }
    /* custom function here */
}
