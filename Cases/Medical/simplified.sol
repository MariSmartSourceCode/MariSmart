// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FormattedShipment {
    address shipper;
    address carrier;
    address consignee;
    uint status = 0;
    uint quantity;
    uint weight;
    uint volume;
    uint price;
    uint down_payment;
    uint transportation_fee;
    uint depart_date;
    uint arrive_date;
    uint sign_valid;
    uint receive_valid;
    uint compensation_valid;

    bool is_delayed;
    bool is_damaged;
    bool is_lost;

    uint compensation_limit;
    uint compensation_amount;
    address compensation_claimer;

    uint create_time;
    uint depart_time;
    uint arrive_time;
    uint receive_time;

    mapping(address => bool) signatures;
    mapping(address => uint) balances;
    mapping(address => uint) escrow_thresholds;

    modifier onlyStakeholder() virtual {
        require(
            msg.sender == shipper ||
                msg.sender == carrier ||
                msg.sender == consignee
        );
        _;
    }

    constructor() payable {
        shipper = msg.sender;
        price = 0;
        down_payment = 0;
        transportation_fee = 0;
        escrow_thresholds[shipper] = 0;
        escrow_thresholds[consignee] = 0;
        escrow_thresholds[carrier] = 0;
        depart_date = 10;
        arrive_date = 30;
        sign_valid = 5 days;
        receive_valid = 60 days;
        compensation_valid = 60 days;

        status = 0;
        create_time = block.timestamp;
        signatures[shipper] = true;
        balances[shipper] = msg.value;
    }

    modifier pre_sign() {
        require(msg.sender == carrier || msg.sender == consignee);
        require(status == 0);
        _;
    }

    // 2. after the shipment creation, the shipper, carrier,  all of performing-parties, consignee, pre-shipment inspector, export port operator, import port operator should all sign the contract
    function sign() external payable pre_sign {
        signatures[msg.sender] = true;
        balances[msg.sender] += msg.value;
        if (
            signatures[shipper] == true &&
            signatures[carrier] == true &&
            signatures[consignee] == true
        ) {
            status = 5;
        }
    }

    modifier pre_depart() virtual {
        require(msg.sender == carrier);
        require(status != 4);
        _;
    }

    // 6. the carrier check the shipment, if it's ok, send it to the import port operator and finish paying price and transportation fee, else send it back to the shipper and close the shipment
    function depart() external virtual pre_depart {
        balances[consignee] -= down_payment;
        balances[carrier] += down_payment;
        depart_time = block.timestamp;
        status = 1;
    }

    modifier pre_arrive() virtual {
        require(msg.sender == carrier);
        require(status != 4);
        _;
    }

    // 8. carrier arrived import port, if it's later than arrive_date, the shipment is turned to delayed
    function arrive() external virtual pre_arrive {
        balances[shipper] -= transportation_fee;
        balances[carrier] += transportation_fee;
        arrive_time = block.timestamp;
        status = 2;
        if (arrive_time > arrive_date) {
            is_delayed = true;
        }
    }

    modifier pre_receiveShipment() virtual {
        require(msg.sender == consignee);
        require(status != 4);
        _;
    }

    function receiveShipment(
        bool _is_damaged
    ) external virtual pre_receiveShipment {
        receive_time = block.timestamp;
        if (_is_damaged == true) {
            is_damaged = true;
        }
        balances[consignee] -= price - down_payment;
        balances[shipper] += price - down_payment;
        status = 3;
    }

    modifier pre_close() virtual {
        require(
            (block.timestamp > arrive_time + compensation_valid &&
                status == 3) ||
                (msg.sender == shipper &&
                    status == 0 &&
                    block.timestamp > create_time + sign_valid)
        );
        _;
    }

    // 14. after compensation period, anyone can close the shipment if it's lost or received
    function close() external virtual pre_close {
        status = 4;
    }
}
