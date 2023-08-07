// SPDX-License-Identifier: MIT
// a contract for maritime shipment
pragma solidity ^0.8.0;

interface IShipment {
    /* Events */
    event ShipmentCreated(address indexed caller, uint indexed time);
    event ShipmentSigned(address indexed caller, uint indexed time);
    event ShipmentEscrowed(address indexed caller, uint indexed time);
    event ShipmentInspectionPassed(address indexed caller, uint indexed time);
    event ShipmentInspectionFailed(address indexed caller, uint indexed time);
    event ShipmentExported(address indexed caller, uint indexed time);
    event ShipmentDeparted(address indexed caller, uint indexed time);
    event ShipmentLost(address indexed caller, uint indexed time);
    event ShipmentDamaged(address indexed caller, uint indexed time);
    event ShipmentArrivedInTime(address indexed caller, uint indexed time);
    event ShipmentArrivedDelayed(address indexed caller, uint indexed time);
    event ShipmentImported(address indexed caller, uint indexed time);
    event ShipmentReceived(address indexed caller, uint indexed time);
    event ShipmentClaimed(address indexed caller, uint indexed time);
    event ShipmentCompensated(address indexed caller, uint indexed time);
    event ShipmentAuctioned(address indexed caller, uint indexed time);
    event ShipmentClosed(address indexed caller, uint indexed time);
    event ShipmentRearranged(address indexed caller, uint indexed time);
    event StakeholderSign(address indexed caller, uint indexed time);
    event ShipmentCanceled(address indexed caller, uint indexed time);

    event StakeholderDeposit(
        address indexed caller,
        uint indexed amount,
        uint indexed time
    );
    event StakeholderWithdraw(
        address indexed caller,
        uint indexed amount,
        uint indexed time
    );
    event CarrierCheckFailed(address indexed caller, uint indexed time);
    event ConsigneeCheckFailed(address indexed caller, uint indexed time);
    event StakeholderTransfer(
        address indexed caller,
        address to,
        uint indexed amount,
        uint indexed time
    );

    /* Modifiers */
    modifier pre_sign() virtual;
    modifier pre_withdraw() virtual;
    modifier pre_inspect() virtual;
    modifier pre_exportShipment() virtual;
    modifier pre_depart() virtual;
    modifier pre_reportLoss() virtual;
    modifier pre_reportDamage() virtual;
    modifier pre_arrive() virtual;
    modifier pre_importShipment() virtual;
    modifier pre_receiveShipment() virtual;
    modifier pre_claim() virtual;
    modifier pre_compensate() virtual;
    modifier pre_rearrange() virtual;
    modifier pre_close() virtual;
    modifier pre_cancel() virtual;

    /* Functions */

    function sign() external payable;

    function withdraw() external;

    function inspect() external;

    function exportShipment() external;

    function depart() external;

    function reportLoss() external;

    function reportDamage() external;

    function arrive() external;

    function importShipment() external;

    function receiveShipment(bool _is_consignee_check_passed) external;

    function claim(uint _compensation_amount) external;

    function compensate() external;

    function rearrange() external;

    function close() external;

    function cancel() external;

    function externalTransfer(address _to, uint _amount) external;

    /* Getters */
    function getShipper() external view returns (address);

    function getCarrier() external view returns (address);

    function getConsignee() external view returns (address);

    function getPreShipmentInspector() external view returns (address);

    function getExportPortOperator() external view returns (address);

    function getImportPortOperator() external view returns (address);

    function getQuantity() external view returns (uint);

    function getWeight() external view returns (uint);

    function getVolume() external view returns (uint);

    function getPrice() external view returns (uint);

    function getDownPayment() external view returns (uint);

    function getTransportationFee() external view returns (uint);

    function getCompensationLimit() external view returns (uint);

    function getDepartDate() external view returns (uint);

    function getArriveDate() external view returns (uint);

    function getSignValid() external view returns (uint);

    function getReceiveValid() external view returns (uint);

    function getCompensationValid() external view returns (uint);

    function getCreateTime() external view returns (uint);

    function getDepartTime() external view returns (uint);

    function getArriveTime() external view returns (uint);

    function getIsDelayed() external view returns (bool);

    function getIsDamaged() external view returns (bool);

    function getCompensationAmount() external view returns (uint);

    function getCompensationClaimer() external view returns (address);

    function getEscrowThresholds(
        address _stakeholder
    ) external view returns (uint);
}
