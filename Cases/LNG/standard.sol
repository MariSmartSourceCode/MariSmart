// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../Templates/Shipment.sol";
import "../../Templates/Stakeholders.sol";

/* Originally implemented in MariSmart */

contract FormattedShipment is Shipment {
    constructor() payable {
        down_payment = price;
        receive_valid = 2 days;
        compensation_valid = 2 days;
        escrow_thresholds[shipper] = transportation_fee + price;
        escrow_thresholds[consignee] = price;
        escrow_thresholds[carrier] = compensation_limit + (price * 3) / 2;
        signatures[msg.sender] = true;
        balances[msg.sender] += msg.value;
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

contract FormattedShipper is Shipper {
    /* custom variable here */
    function create(
        uint _escrow_amount
    ) public override onlyOwner returns (uint) {
        FormattedShipment shipment = new FormattedShipment{
            value: _escrow_amount
        }();
        uid_counter += 1;
        shipments[uid_counter] = address(shipment);
        return uid_counter;
    }

    function withdraw(uint _UID) public override onlyOwner {
        FormattedShipment(shipments[_UID]).withdraw();
    }

    function claim(
        uint _UID,
        uint _compensation_amount
    ) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).claim(_compensation_amount);
    }

    function cancel(uint _UID, uint _cancellation_fee) public onlyOwner {
        FormattedShipment(shipments[_UID]).cancel();
        /* custom logic here */
        /* letter 7 */
        FormattedShipment(shipments[_UID]).externalTransfer(
            FormattedShipment(shipments[_UID]).getConsignee(),
            _cancellation_fee
        );
    }

    function close(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).close();
    }
    /* custom function here */
}

contract FormattedCarrier is Carrier {
    /* custom variable here */
    event estimatedTimeofArrival(uint timestamp, uint prior_time);

    function sign(address _shipment) public override onlyOwner returns (uint) {
        uint escrow_amount = FormattedShipment(_shipment).getEscrowThresholds(
            address(this)
        );
        FormattedShipment(_shipment).sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = _shipment;
        return uid_counter;
    }

    function withdraw(uint _UID) public override onlyOwner {
        FormattedShipment(shipments[_UID]).withdraw();
    }

    function depart(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).depart();
    }

    function reportLoss(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).reportLoss();
    }

    function reportDamage(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).reportDamage();
    }

    function compensate(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).compensate();
    }

    function close(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).close();
    }

    function arrive(uint _UID) public override onlyOwner {
        /* custom logic here */
        /* 7.1.1 */
        FormattedShipment(shipments[_UID]).arrive();
        emit estimatedTimeofArrival(block.timestamp, 0);
    }

    function rearrange(uint _UID, uint _sold_price) public onlyOwner {
        if (_sold_price > FormattedShipment(shipments[_UID]).getPrice()) {
            FormattedShipment(shipments[_UID]).externalTransfer(
                FormattedShipment(shipments[_UID]).getConsignee(),
                FormattedShipment(shipments[_UID]).getPrice()
            );
            FormattedShipment(shipments[_UID]).externalTransfer(
                FormattedShipment(shipments[_UID]).getShipper(),
                _sold_price - FormattedShipment(shipments[_UID]).getPrice()
            );
        } else {
            FormattedShipment(shipments[_UID]).externalTransfer(
                FormattedShipment(shipments[_UID]).getConsignee(),
                _sold_price
            );
        }
        FormattedShipment(shipments[_UID]).rearrange();
    }

    /* custom function here */
    function notify(uint _prior_time) public onlyOwner {
        emit estimatedTimeofArrival(block.timestamp, _prior_time);
    }
}

contract FormattedExportPortOperator is ExportPortOperator {
    function sign(address _shipment) public override onlyOwner returns (uint) {
        uint escrow_amount = FormattedShipment(_shipment).getEscrowThresholds(
            address(this)
        );
        FormattedShipment(_shipment).sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = _shipment;
        return uid_counter;
    }

    function withdraw(uint _UID) public override onlyOwner {
        FormattedShipment(shipments[_UID]).withdraw();
    }

    function exportShipment(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).exportShipment();
    }
}

contract FormattedImportPortOperator is ImportPortOperator {
    function sign(address _shipment) public override onlyOwner returns (uint) {
        uint escrow_amount = FormattedShipment(_shipment).getEscrowThresholds(
            address(this)
        );
        FormattedShipment(_shipment).sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = _shipment;
        return uid_counter;
    }

    function withdraw(uint _UID) public override onlyOwner {
        FormattedShipment(shipments[_UID]).withdraw();
    }

    function importShipment(uint _UID) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).importShipment();
    }
}

contract FormattedConsignee is Consignee {
    function sign(address _shipment) public override onlyOwner returns (uint) {
        uint escrow_amount = FormattedShipment(_shipment).getEscrowThresholds(
            address(this)
        );
        FormattedShipment(_shipment).sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = _shipment;
        return uid_counter;
    }

    function withdraw(uint _UID) public override onlyOwner {
        FormattedShipment(shipments[_UID]).withdraw();
    }

    function receiveShipment(
        uint _UID,
        bool _is_passed
    ) public virtual override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).receiveShipment(_is_passed);
    }

    function claim(
        uint _UID,
        uint _compensation_amount
    ) public override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).claim(_compensation_amount);
    }
}
