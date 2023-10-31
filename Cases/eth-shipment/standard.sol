// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../Templates/Stakeholders.sol";
import "../../Templates/Shipment.sol";

/* 
The source code is fetched from https://github.com/ajb413/eth-shipment-tracking/blob/master/contracts/ShipmentTracking.sol

No access control is implemented in the original code, so we apply the default stakeholders and their access control in the case.

- ShipmentTracking is create
- depart is depart
- arrive is arrive
- deliver is receiveShipment

The information about location is recorded in Locations in orginal contract, which is refactored as parameters in shipment contract in the case.

The origin contract is designed to record a chain of departure and arrival, we focus on the first and the last one in the case.
*/

contract FormattedShipment is Shipment {
    string from;
    string to;
    string origin_name;
    string destination_name;
    string custodian;

    function setFrom(string memory _from) public onlyStakeholder {
        from = _from;
    }

    function setTo(string memory _to) public onlyStakeholder {
        to = _to;
    }

    function setOriginName(string memory _origin_name) public onlyStakeholder {
        origin_name = _origin_name;
    }

    function setDestinationName(
        string memory _destinationName
    ) public onlyStakeholder {
        destination_name = _destinationName;
    }

    function setCustodian(string memory _custodian) public onlyStakeholder {
        custodian = _custodian;
    }

    function getFrom() public view returns (string memory) {
        return from;
    }

    function getTo() public view returns (string memory) {
        return to;
    }

    function getOriginName() public view returns (string memory) {
        return origin_name;
    }

    function getDestinationName() public view returns (string memory) {
        return destination_name;
    }

    function getCustodian() public view returns (string memory) {
        return custodian;
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
        require(
            state == State.signed,
            "Shipment must be signed before departing."
        );
        _;
    }
    modifier pre_receiveShipment() {
        require(state == State.arrived);
        _;
    }
}

contract FormattedShipper is Shipper {
    event Departed(string location, string custodian, uint time);
    /* custom variable here */

    mapping(address => uint) public passcode_hashes;
    event ShippingRequestPlaced(uint ShipmentID, address WasteGeneratorEA);

    function close(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).close();
    }

    /* custom function here */
    function create(
        uint _escrow_amount,
        string memory _from,
        string memory _to,
        string memory _originName,
        string memory _destinationName,
        string memory _custodian
    ) public onlyOwner returns (uint) {
        FormattedShipment shipment = new FormattedShipment{
            value: _escrow_amount
        }();
        /* custom logic here */
        uid_counter += 1;
        shipment.setFrom(_from);
        shipment.setTo(_to);
        shipment.setOriginName(_originName);
        shipment.setDestinationName(_destinationName);
        shipment.setCustodian(_custodian);
        emit Departed(_originName, _custodian, block.timestamp);
        shipments[uid_counter] = address(shipment);
        return uid_counter;
    }
}

contract FormattedCarrier is Carrier {
    event Departed(string location, string custodian, uint time);
    event Arrived(string location, string custodian, uint time);
    event ShipmentStateandlocationUpdated(
        uint UID,
        Shipment.State state,
        uint Time
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

    function depart(uint _UID, uint _departure) public onlyOwner {
        FormattedShipment(shipments[_UID]).depart();
        if (_departure == 0) {
            _departure = block.timestamp;
        }

        emit Departed(
            FormattedShipment(shipments[_UID]).getOriginName(),
            FormattedShipment(shipments[_UID]).getCustodian(),
            _departure
        );
    }

    function arrive(
        uint _UID,
        string memory _name,
        string memory _custodian,
        uint _arrival
    ) public onlyOwner {
        FormattedShipment(shipments[_UID]).arrive();
        if (_arrival == 0) {
            _arrival = block.timestamp;
        }
        FormattedShipment(shipments[_UID]).setCustodian(_custodian);
        FormattedShipment(shipments[_UID]).setDestinationName(_name);
        emit Arrived(_name, _custodian, _arrival);
    }
}

contract FormattedConsignee is Consignee {
    /* custom function here */
    event Delivered(string location, string custodian, uint time);

    function sign(
        address _shipment
    ) public virtual override onlyOwner returns (uint) {
        uint escrow_amount = FormattedShipment(_shipment).getEscrowThresholds(
            address(this)
        );
        FormattedShipment(_shipment).sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = _shipment;
        return uid_counter;
    }

    function receiveShipment(
        uint _UID,
        string memory _name,
        string memory _custodian,
        uint _arrival
    ) public onlyOwner {
        FormattedShipment(shipments[_UID]).receiveShipment(true);
        if (_arrival == 0) {
            _arrival = block.timestamp;
        }
        FormattedShipment(shipments[_UID]).setCustodian(_custodian);
        FormattedShipment(shipments[_UID]).setDestinationName(_name);
        emit Delivered(_name, _custodian, _arrival);
    }
}
