// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../Templates/Shipment.sol";
import "../../Templates/Stakeholders.sol";

/* already refactored by MariSmart */

contract FormattedShipment is Shipment {
    string pass_code;

    function getPassCode() public view onlyStakeholder returns (string memory) {
        return pass_code;
    }

    function setPassCode(string memory _pass_code) public onlyStakeholder {
        pass_code = _pass_code;
    }

    constructor() payable {
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

    modifier pre_depart() override {
        require(msg.sender == carrier && state == State.signed);
        _;
    }
    modifier pre_receiveShipment() override {
        require(
            msg.sender == consignee &&
                state == State.arrived &&
                block.timestamp <= arrive_time + receive_valid
        );
        _;
    }
    modifier pre_rearrange() override {
        require(
            msg.sender == carrier &&
                state == State.arrived &&
                block.timestamp > arrive_time + receive_valid
        );
        _;
    }
}

contract FormattedCarrier is Carrier {
    //Violation Events
    event TempertaureViolation(uint v, uint time); //temperature out of accepted range
    event SuddenJerk(uint v, uint time);
    event SuddenContainerOpening(uint v, uint time);
    event OutofRoute(uint v, uint time);

    uint violationType_None = 0;
    uint violationType_Temp = 1;
    uint violationType_Open = 2;
    uint violationType_Route = 3;
    uint violationType_Jerk = 4;

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

    function depart(uint _UID) public override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).depart();
    }

    function reportDamage(uint _UID) public override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).reportDamage();
    }

    function arrive(uint _UID) public override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).arrive();
    }

    function compensate(uint _UID) public override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).compensate();
    }

    function rearrange(uint _UID) public override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).rearrange();
    }

    function close(uint _UID) public override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).close();
    }

    function reportLoss(uint _UID, uint _v) public onlyOwner {
        FormattedShipment(shipments[_UID]).reportLoss();
        FormattedShipment(shipments[_UID]).externalTransfer(
            FormattedShipment(shipments[_UID]).getConsignee(),
            FormattedShipment(shipments[_UID]).getDownPayment()
        );

        if (_v == violationType_Jerk) {
            emit SuddenJerk(_v, block.timestamp);
        } else if (_v == violationType_Open) {
            emit SuddenContainerOpening(_v, block.timestamp);
        } else if (_v == violationType_Temp) {
            emit TempertaureViolation(_v, block.timestamp);
        } else if (_v == violationType_Route) {
            emit OutofRoute(_v, block.timestamp);
        }
    }
}

contract FormattedConsignee is Consignee {
    function sign(
        address _shipment,
        string memory _passcode
    ) public onlyOwner returns (uint) {
        uint escrow_amount = FormattedShipment(_shipment).getEscrowThresholds(
            address(this)
        );
        FormattedShipment(_shipment).sign{value: escrow_amount}();
        uid_counter += 1;
        shipments[uid_counter] = _shipment;
        /* custom logic here */
        FormattedShipment(_shipment).setPassCode(_passcode);

        return uid_counter;
    }

    function withdraw(uint _UID) public override onlyOwner {
        FormattedShipment(shipments[_UID]).withdraw();
    }

    function receiveShipment(
        uint _UID,
        string memory _passcode,
        bool _is_passed
    ) public onlyOwner {
        /* custom logic here */
        require(
            keccak256(
                abi.encodePacked(
                    FormattedShipment(shipments[_UID]).getPassCode()
                )
            ) == keccak256(abi.encodePacked(_passcode))
        );
        require(
            block.timestamp <=
                FormattedShipment(shipments[_UID]).getArriveTime() +
                    FormattedShipment(shipments[_UID]).getReceiveValid()
        );
        FormattedShipment(shipments[_UID]).receiveShipment(_is_passed);
    }

    function claim(
        uint _UID,
        uint _compensation_amount
    ) public override onlyOwner {
        /* custom logic here */
        FormattedShipment(shipments[_UID]).claim(_compensation_amount);
    }
    /* custom function here */
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
