// SPDX-License-Identifier: MIT
// a contract for maritime shipment
pragma solidity ^0.8.0;
import "./IShipment.sol";

contract Shipment is IShipment {
    // a shipment has several states, the state of the shipment is set to be created at construction
    enum State {
        created,
        signed,
        inspected,
        exported,
        departed,
        lost,
        arrived,
        imported,
        rearranged,
        received,
        claimed,
        closed
    }
    State state;

    // there are 6 stakeholders in the contract, including shipper, carrier, consignee, pre_shipment_inspector, export_port_operator, import_port_operator
    // the shipper is the one who sends the shipment
    // the carrier is the one who carries the shipment
    // the consignee is the one who receives the shipment
    // the pre-shipment inspector is the one who inspects the shipment before it is shipped
    address shipper;
    address carrier;
    address consignee;
    address pre_shipment_inspector;
    address export_port_operator;
    address import_port_operator;

    // the shipment is a product that is being shipped, it has a quantity, a price, a weight, a volume, a price, an amount of down payment, a transportation fee, a date to ship, a date to arrive, a valid period to receive and a another to claim for compensation after actual arrival, all of which are set at construction
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

    // a shipment has 3 exceptions, including lost, delayed, damaged.
    // lost should be denoted as the state of lost, and the other two expections are denoted by boolen variable, is_delayed and is_damaged
    bool is_delayed;
    bool is_damaged;
    bool is_lost;

    // when exceptions occur, consignee and shipper should claim for compensation and carrier shoule pay for it.a shipment has a compensation limit, which is set at construction. the compensation amount is set to be 0 at construction, and the address of compensation claimer is set to be 0 at construction
    uint compensation_limit;
    uint compensation_amount;
    address compensation_claimer;

    // a shipment has a create time, a depart time, an arrive time, a receive time, all of which are set to be 0 at construction, and updated when the corresponding event occurs
    uint create_time;
    uint depart_time;
    uint arrive_time;
    uint receive_time;

    // the shipment contract maintain an escrow for stakeholders, so that the transactions between PPs will be implemented as update of escrow balances conducted by the shipment contract. all PPs should deposit into the escrow as required by escrow_thresholds as the contract is signed, and the balances will be locked until the shipment is closed
    mapping(address => bool) signatures;
    mapping(address => uint) balances;
    mapping(address => uint) escrow_thresholds;

    modifier onlyStakeholder() virtual override {
        require(
            msg.sender == shipper ||
                msg.sender == carrier ||
                msg.sender == consignee ||
                msg.sender == pre_shipment_inspector ||
                msg.sender == export_port_operator ||
                msg.sender == import_port_operator
        );
        _;
    }

    // a shipment is finished in following steps:

    // 1. at construction, the addresses are set to refer to the corresponding roles, the shipment is set to be the shipment that is being shipped, and the signatures of all roles are set to be false, and the balances of all roles are set to be 0
    constructor() payable {
        shipper = address(0x1);
        carrier = address(0x2);
        consignee = address(0x3);
        pre_shipment_inspector = address(0x4);
        export_port_operator = address(0x5);
        import_port_operator = address(0x6);

        quantity = 1;
        weight = 1000;
        volume = 10;
        price = 100;
        down_payment = 50;
        transportation_fee = 10;
        compensation_limit = 100;
        depart_date = 10;
        arrive_date = 30;
        sign_valid = 5 days;
        receive_valid = 60 days;
        compensation_valid = 60 days;
        escrow_thresholds[shipper] = transportation_fee;
        escrow_thresholds[consignee] = price;
        escrow_thresholds[carrier] = compensation_limit;

        state = State.created;
        create_time = block.timestamp;
        signatures[shipper] = true;
        balances[shipper] = msg.value;

        emit ShipmentCreated(msg.sender, block.timestamp);
    }

    modifier pre_sign() virtual override {
        require(
            msg.sender == carrier ||
                msg.sender == consignee ||
                msg.sender == pre_shipment_inspector ||
                msg.sender == export_port_operator ||
                msg.sender == import_port_operator
        );
        require(
            state == State.created &&
                signatures[msg.sender] == false &&
                msg.value == escrow_thresholds[msg.sender]
        );
        _;
    }

    // 2. after the shipment creation, the shipper, carrier,  all of performing-parties, consignee, pre-shipment inspector, export port operator, import port operator should all sign the contract
    function sign() external payable virtual override pre_sign {
        signatures[msg.sender] = true;
        balances[msg.sender] += msg.value;
        emit StakeholderSign(msg.sender, block.timestamp);
        if (
            signatures[shipper] == true &&
            signatures[carrier] == true &&
            signatures[consignee] == true &&
            signatures[pre_shipment_inspector] == true &&
            signatures[export_port_operator] == true &&
            signatures[import_port_operator] == true
        ) {
            state = State.signed;
            emit ShipmentSigned(msg.sender, block.timestamp);
        }
    }

    modifier pre_inspect() virtual override {
        require(msg.sender == pre_shipment_inspector);
        require(state == State.signed);
        _;
    }

    // 4. the pre-shipment inspector inspect the shipment and if passed, send it to the export port operator, else send it back to the shipper and close the shipment
    function inspect(bool is_passed) external virtual override pre_inspect {
        if (is_passed == false) {
            state = State.closed;
            emit ShipmentClosed(msg.sender, block.timestamp);
        } else {
            state = State.inspected;
            emit ShipmentInspectionPassed(msg.sender, block.timestamp);
        }
    }

    modifier pre_exportShipment() virtual override {
        require(msg.sender == export_port_operator);
        require(state == State.inspected);
        _;
    }

    // 5. the export port operator send the shipment to the carrier
    function exportShipment() external virtual override pre_exportShipment {
        state = State.exported;
        emit ShipmentExported(msg.sender, block.timestamp);
    }

    modifier pre_depart() virtual override {
        require(msg.sender == carrier);
        require(state == State.exported);
        _;
    }

    // 6. the carrier check the shipment, if it's ok, send it to the import port operator and finish paying price and transportation fee, else send it back to the shipper and close the shipment
    function depart() external virtual override pre_depart {
        internalTransfer(consignee, shipper, down_payment);
        depart_time = block.timestamp;
        state = State.departed;
        emit ShipmentDeparted(msg.sender, block.timestamp);
    }

    modifier pre_reportLoss() virtual override {
        require(msg.sender == carrier);
        require(state == State.departed);
        _;
    }

    // 7. during shipping, the shipment cloud be lost, update its state to lost
    function reportLoss() external virtual override pre_reportLoss {
        state = State.lost;
        is_lost = true;
        emit ShipmentLost(msg.sender, block.timestamp);
    }

    modifier pre_arrive() virtual override {
        require(msg.sender == carrier);
        require(state == State.departed);
        _;
    }

    // 8. carrier arrived import port, if it's later than arrive_date, the shipment is turned to delayed
    function arrive() external virtual override pre_arrive {
        internalTransfer(shipper, carrier, transportation_fee);
        arrive_time = block.timestamp;
        state = State.arrived;
        if (arrive_time > arrive_date) {
            is_delayed = true;
            emit ShipmentArrivedDelayed(msg.sender, block.timestamp);
        } else emit ShipmentArrivedInTime(msg.sender, block.timestamp);
    }

    modifier pre_importShipment() virtual override {
        require(msg.sender == import_port_operator);
        require(state == State.arrived);
        _;
    }

    function importShipment() external virtual override pre_importShipment {
        state = State.imported;
        emit ShipmentImported(msg.sender, block.timestamp);
    }

    modifier pre_reportDamage() virtual override {
        require(msg.sender == carrier);
        require(state == State.departed && is_damaged == false);
        _;
    }

    // 17. during transportation, the shipment coule be damaged for different reasons
    function reportDamage() external virtual override pre_reportDamage {
        is_damaged = true;
        emit ShipmentDamaged(msg.sender, block.timestamp);
    }

    modifier pre_receiveShipment() virtual override {
        require(msg.sender == consignee);
        require(state == State.imported);
        require(block.timestamp <= arrive_time + receive_valid);
        _;
    }

    // 9. consignee receives the shipment, if it's damaged, the shipment is turned to damaged
    function receiveShipment(
        bool _is_damaged
    ) external virtual override pre_receiveShipment {
        receive_time = block.timestamp;
        if (_is_damaged == true) {
            is_damaged = true;
            emit ConsigneeCheckFailed(msg.sender, block.timestamp);
        }
        internalTransfer(consignee, shipper, price - down_payment);
        state = State.received;
        emit ShipmentReceived(msg.sender, block.timestamp);
    }

    modifier pre_claim() virtual override {
        require(
            ((state == State.received &&
                msg.sender == consignee &&
                (is_damaged == true || is_delayed == true)) &&
                block.timestamp <= arrive_time + compensation_valid) ||
                (state == State.lost && msg.sender == shipper)
        );
        _;
    }

    // 10. if the shipment is lost, delayed or damaged, the consignee could claim compensation, and the state of the shipment is set to claimed
    // the consignee could also claim extra compensation with the carrier's approval
    function claim(
        uint _compensation_amount
    ) external virtual override pre_claim {
        if (_compensation_amount > compensation_limit)
            compensation_amount = compensation_limit;
        else compensation_amount = _compensation_amount;
        compensation_claimer = msg.sender;
        state = State.claimed;
        emit ShipmentClaimed(msg.sender, block.timestamp);
    }

    modifier pre_compensate() virtual override {
        require(msg.sender == carrier);
        require(state == State.claimed);
        require(compensation_amount >= 0);
        require(balances[carrier] >= compensation_amount);
        _;
    }

    // 11. the carrier confirm and pay for the compensation by editing the balances of himself and the consignee
    function compensate() external virtual override pre_compensate {
        internalTransfer(carrier, compensation_claimer, compensation_amount);
        compensation_amount = 0;
        state = State.closed;
        emit ShipmentCompensated(msg.sender, block.timestamp);
    }

    modifier pre_rearrange() virtual override {
        require(msg.sender == carrier);
        require(
            state == State.imported &&
                block.timestamp > arrive_date + receive_valid
        );
        _;
    }

    // 12. if consignee doesn't claim to receive the shipment, carrier can auction or resell the shipment
    function rearrange() external virtual override pre_rearrange {
        state = State.rearranged;
        emit ShipmentRearranged(msg.sender, block.timestamp);
    }

    modifier pre_close() virtual override {
        require(
            ((msg.sender == carrier &&
                ((block.timestamp > arrive_date + compensation_valid &&
                    state == State.lost) ||
                    (block.timestamp > arrive_time + compensation_valid &&
                        state == State.received))) ||
                state == State.rearranged) ||
                (msg.sender == shipper &&
                    state == State.created &&
                    block.timestamp > create_time + sign_valid) ||
                (msg.sender == pre_shipment_inspector && state == State.signed)
        );
        _;
    }

    // 14. after compensation period, anyone can close the shipment if it's lost or received
    function close() external virtual override pre_close {
        state = State.closed;
        emit ShipmentClosed(msg.sender, block.timestamp);
    }

    modifier pre_withdraw() virtual override {
        require(state == State.closed);
        require(balances[msg.sender] > 0);
        _;
    }

    // 15. if shipment is closed, anyone can withdrawEscrow the balance
    function withdraw() external virtual override pre_withdraw {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit StakeholderWithdraw(msg.sender, amount, block.timestamp);
    }

    modifier pre_cancel() virtual override {
        require(msg.sender == shipper);
        require(state == State.exported);
        _;
    }

    // 16. duing transportation, the shipment could be canceled, half of transportation fee is refunded and the shipment is closed
    function cancel() external virtual override pre_cancel {
        internalTransfer(shipper, carrier, transportation_fee / 2);
        state = State.closed;
        emit ShipmentCanceled(msg.sender, block.timestamp);
    }

    function internalTransfer(
        address _from,
        address _to,
        uint _amount
    ) internal {
        require(balances[_from] >= _amount);
        require(_amount >= 0);
        balances[_from] -= _amount;
        balances[_to] += _amount;
        emit StakeholderTransfer(_from, _to, _amount, block.timestamp);
    }

    function externalTransfer(
        address _to,
        uint _amount
    ) external virtual override {
        require(_amount >= 0);
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit StakeholderTransfer(msg.sender, _to, _amount, block.timestamp);
    }

    /* Getters */
    function getShipper()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (address)
    {
        return shipper;
    }

    function getCarrier()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (address)
    {
        return carrier;
    }

    function getConsignee()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (address)
    {
        return consignee;
    }

    function getPreShipmentInspector()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (address)
    {
        return pre_shipment_inspector;
    }

    function getExportPortOperator()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (address)
    {
        return export_port_operator;
    }

    function getImportPortOperator()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (address)
    {
        return import_port_operator;
    }

    function getQuantity()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return quantity;
    }

    function getWeight()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return weight;
    }

    function getVolume()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return volume;
    }

    function getPrice()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return price;
    }

    function getDownPayment()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return down_payment;
    }

    function getTransportationFee()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return transportation_fee;
    }

    function getCompensationLimit()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return compensation_limit;
    }

    function getDepartDate()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return depart_date;
    }

    function getArriveDate()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return arrive_date;
    }

    function getSignValid()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return sign_valid;
    }

    function getReceiveValid()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return receive_valid;
    }

    function getCompensationValid()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return compensation_valid;
    }

    function getCreateTime()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return create_time;
    }

    function getDepartTime()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return depart_time;
    }

    function getArriveTime()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return arrive_time;
    }

    function getIsDelayed()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (bool)
    {
        return is_delayed;
    }

    function getIsDamaged()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (bool)
    {
        return is_damaged;
    }

    function getCompensationAmount()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (uint)
    {
        return compensation_amount;
    }

    function getCompensationClaimer()
        external
        view
        virtual
        override
        onlyStakeholder
        returns (address)
    {
        return compensation_claimer;
    }

    function getEscrowThresholds(
        address _stakeholder
    ) external view virtual override onlyStakeholder returns (uint) {
        return escrow_thresholds[_stakeholder];
    }
}
