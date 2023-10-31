pragma solidity =0.6.0;

contract Registration {
    address NHTSA; //0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

    mapping(address => bool) Customer; // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    mapping(address => bool) Dealer; // 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
    mapping(address => bool) InspectionDepartment; //0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    mapping(address => bool) Automaker; // 0x617F2E2fD72FD9D5503197092aC168c91465E7f2
    mapping(address => bool) AutomobilePartsSupplier; // 0x17F6AD8Ef982297579C203069C1DbfFE4348c372

    modifier onlyNHTSA() {
        require(msg.sender == NHTSA, "Sender not authorized.");
        _;
    }

    constructor() public {
        NHTSA = msg.sender;
    }

    function RegisterCustomer(address c) public onlyNHTSA {
        require(!Customer[c], "Customer exists already");

        Customer[c] = true;
    }

    function RegisterDealer(address d) public onlyNHTSA {
        require(!Dealer[d], "Dealer exists already");

        Dealer[d] = true;
    }

    function RegisterInspectionDepartment(address i) public onlyNHTSA {
        require(
            !InspectionDepartment[i],
            "InspectionDepartment exists already"
        );

        InspectionDepartment[i] = true;
    }

    function RegisterAutomaker(address a) public onlyNHTSA {
        require(!Automaker[a], "Automaker exists already");

        Automaker[a] = true;
    }

    function RegisterAutomobilePartsSupplier(address s) public onlyNHTSA {
        require(
            !AutomobilePartsSupplier[s],
            "AutomobilePartsSupplier exists already"
        );

        AutomobilePartsSupplier[s] = true;
    }

    function isNHTSA(address n) public view returns (bool) {
        return (NHTSA == n);
    }

    function CustomerExists(address c) public view returns (bool) {
        return Customer[c];
    }

    function DealerExists(address d) public view returns (bool) {
        return Dealer[d];
    }

    function InspectionDepartmentExists(address i) public view returns (bool) {
        return InspectionDepartment[i];
    }

    function AutomakerExists(address a) public view returns (bool) {
        return Automaker[a];
    }

    function AutomobilePartsSupplierExists(
        address s
    ) public view returns (bool) {
        return AutomobilePartsSupplier[s];
    }
}

contract RecallHandler {
    uint InitTime;
    uint CompTime;
    bool Penalty;
    address payable NHTSA;

    Registration RegistrationContract;

    enum status {
        Pending,
        Accepted,
        Rejected,
        Received
    }

    struct DefectComplaintRequestdetails {
        address receiver;
        address requestor;
        string VIN;
        string VehicleModelName;
        string FunctionalModuleName;
        string VehicleBuildYear;
        status DefectComplaintRequestdetailsStatus;
    }

    mapping(bytes32 => DefectComplaintRequestdetails)
        public GetDefectComplaintRequestID;

    constructor(address registration) public {
        RegistrationContract = Registration(registration);

        if (!RegistrationContract.CustomerExists(msg.sender))
            revert("Sender not authorized");
    }

    modifier onlyRequestor() {
        require(
            RegistrationContract.CustomerExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    modifier onlyReceiver() {
        require(
            RegistrationContract.isNHTSA(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    modifier onlySEnder() {
        require(
            RegistrationContract.AutomakerExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    modifier onlyReceiver1() {
        require(
            RegistrationContract.CustomerExists(msg.sender) ||
                RegistrationContract.DealerExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }

    event DefectComplaintPlaced(
        bytes32 DefectComplaintRequestID,
        address receiver,
        address requestor,
        string VIN,
        string FunctionalModuleName,
        string VehicleModelname,
        string BuildDate
    );
    event StatusUpdated(bytes32 DefectComplaintRequestID, status newStatus);

    function PlaceDefectComplaint(
        address receiver,
        string memory VIN,
        string memory FunctionalModuleName,
        string memory VehicleModelName,
        string memory VehicleBuildYear
    ) public onlyRequestor {
        require(
            RegistrationContract.isNHTSA(receiver),
            "NHTSA's address is not valid."
        );
        InitTime = 16;
        bytes32 temp = keccak256(
            abi.encodePacked(
                msg.sender,
                now,
                address(this),
                VIN,
                VehicleModelName,
                FunctionalModuleName,
                VehicleBuildYear
            )
        );
        GetDefectComplaintRequestID[temp] = DefectComplaintRequestdetails(
            receiver,
            msg.sender,
            VIN,
            VehicleModelName,
            FunctionalModuleName,
            VehicleBuildYear,
            status.Pending
        );

        emit DefectComplaintPlaced(
            temp,
            receiver,
            msg.sender,
            VIN,
            VehicleModelName,
            FunctionalModuleName,
            VehicleBuildYear
        );
    }

    function ConfirmDefectRequest(
        bytes32 DefectComplaintRequestID,
        bool accepted
    ) public onlyReceiver {
        require(
            GetDefectComplaintRequestID[DefectComplaintRequestID].receiver ==
                msg.sender,
            "Sender not authorized."
        );
        require(
            GetDefectComplaintRequestID[DefectComplaintRequestID]
                .DefectComplaintRequestdetailsStatus == status.Pending
        );

        if (accepted) {
            GetDefectComplaintRequestID[DefectComplaintRequestID]
                .DefectComplaintRequestdetailsStatus = status.Accepted;
        } else {
            GetDefectComplaintRequestID[DefectComplaintRequestID]
                .DefectComplaintRequestdetailsStatus = status.Rejected;
        }

        emit StatusUpdated(
            DefectComplaintRequestID,
            GetDefectComplaintRequestID[DefectComplaintRequestID]
                .DefectComplaintRequestdetailsStatus
        );
    }

    struct RecallNoticeDetails {
        address receipent1;
        address receipent2;
        address sender;
        string VIN;
        bytes32 InspectionReportID;
        status RecallNoticeStatus;
    }

    mapping(bytes32 => RecallNoticeDetails) public GetRecallNoticeNumber;

    event RecallNoticeCreated(
        bytes32 RecallNoticeNumber,
        bytes32 InspectionReportID,
        address receipent1,
        address receipent2,
        string VIN
    );
    event RecallNoticeReceived(bytes32 RecallNoticeNumber, status newStatus);

    function CreateRecallNotice(
        address receipent1,
        address receipent2,
        string memory VIN,
        bytes32 InspectionReportID
    ) public onlySEnder {
        require(
            RegistrationContract.CustomerExists(receipent1) ||
                RegistrationContract.DealerExists(receipent2),
            "Customer/Dealer address is not valid."
        );
        bytes32 temp2 = keccak256(
            abi.encodePacked(msg.sender, now, address(this), InspectionReportID)
        );

        GetRecallNoticeNumber[temp2] = RecallNoticeDetails(
            receipent1,
            receipent2,
            msg.sender,
            VIN,
            InspectionReportID,
            status.Pending
        );

        emit RecallNoticeCreated(
            temp2,
            InspectionReportID,
            receipent1,
            msg.sender,
            VIN
        );
    }

    function ReceiveRecallNotice(
        bytes32 RecallNoticeNumber,
        bool accepted
    ) public onlyReceiver1 {
        require(
            GetRecallNoticeNumber[RecallNoticeNumber].receipent1 == msg.sender,
            "Sender not authorized."
        );
        require(
            GetRecallNoticeNumber[RecallNoticeNumber].RecallNoticeStatus ==
                status.Pending
        );

        if (accepted) {
            GetRecallNoticeNumber[RecallNoticeNumber]
                .RecallNoticeStatus = status.Accepted;
        } else {
            GetRecallNoticeNumber[RecallNoticeNumber]
                .RecallNoticeStatus = status.Rejected;
        }
        emit RecallNoticeReceived(
            RecallNoticeNumber,
            GetRecallNoticeNumber[RecallNoticeNumber].RecallNoticeStatus
        );
    }

    struct ShipmentToDealerDetails {
        address receiver;
        address Sender;
        string Partnumber;
        status ShipmentDealerStatus;
    }
    mapping(bytes32 => ShipmentToDealerDetails) public GetShipmentNoticeNumber;
    modifier onlySENder() {
        require(
            RegistrationContract.AutomakerExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    modifier onlyREceiver() {
        require(
            RegistrationContract.DealerExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    event DealerPartShipmentCreated(
        bytes32 ShipmentNoticeNumber,
        address receiver,
        string PartNumber
    );
    event DealerPartShipmentReceived(
        bytes32 ShipmentNoticeNumber,
        status NewStatus
    );

    function CreateShipmentNoticeToDealer(
        address receiver,
        string memory Partnumber
    ) public onlySEnder {
        require(
            RegistrationContract.DealerExists(receiver),
            "Dealer address is not valid."
        );
        bytes32 temp3 = keccak256(
            abi.encodePacked(msg.sender, now, address(this))
        );
        GetShipmentNoticeNumber[temp3] = ShipmentToDealerDetails(
            receiver,
            msg.sender,
            Partnumber,
            status.Pending
        );

        emit DealerPartShipmentCreated(temp3, msg.sender, Partnumber);
    }

    function ReceiveDealerPartShipment(
        bytes32 ShipmentNoticeNumber,
        bool received
    ) public onlyREceiver {
        require(
            GetShipmentNoticeNumber[ShipmentNoticeNumber].receiver ==
                msg.sender,
            "Sender not authorized."
        );
        require(
            GetShipmentNoticeNumber[ShipmentNoticeNumber]
                .ShipmentDealerStatus == status.Pending
        );

        if (received) {
            GetShipmentNoticeNumber[ShipmentNoticeNumber]
                .ShipmentDealerStatus = status.Received;
        } else {
            GetShipmentNoticeNumber[ShipmentNoticeNumber]
                .ShipmentDealerStatus = status.Rejected;
        }
        emit DealerPartShipmentReceived(
            ShipmentNoticeNumber,
            GetShipmentNoticeNumber[ShipmentNoticeNumber].ShipmentDealerStatus
        );
    }

    struct ServicedVehicleDetails {
        address receiver1;
        address receiver2;
        address receiver3;
        address receiver4;
        address receiver;
        string VIN;
        status ServicedVehicleStatus;
    }
    mapping(bytes32 => ServicedVehicleDetails) public GetServicedVehicleID;
    modifier onlySENDer() {
        require(
            RegistrationContract.DealerExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    modifier onlyRECeiver() {
        require(
            RegistrationContract.CustomerExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    event ServicedVehicleNoticeCreated(
        bytes32 ServicedvehicleID,
        bytes32 ShipmentNoticeNumber,
        address receiver,
        string VIN
    );
    event ServicedVehicleReceived(bytes32 ServicedvehicleID, status newStatus);

    function CreateServicedVehicleNotice(
        address receiver1,
        address receiver2,
        address receiver3,
        address receiver,
        bytes32 ShipmentNoticeNumber,
        string memory VIN
    ) public onlySENDer {
        require(
            RegistrationContract.DealerExists(receiver),
            "Dealer address is not valid."
        );
        require(
            RegistrationContract.AutomakerExists(receiver1),
            "Automaker address is not valid."
        );
        require(
            RegistrationContract.isNHTSA(receiver2),
            "NHTSA address is not valid."
        );
        require(
            RegistrationContract.CustomerExists(receiver3),
            "Customer address is not valid."
        );
        bytes32 temp4 = keccak256(
            abi.encodePacked(
                msg.sender,
                now,
                address(this),
                ShipmentNoticeNumber
            )
        );
        GetServicedVehicleID[temp4] = ServicedVehicleDetails(
            receiver1,
            receiver2,
            receiver3,
            receiver,
            msg.sender,
            VIN,
            status.Pending
        );

        emit ServicedVehicleNoticeCreated(
            temp4,
            ShipmentNoticeNumber,
            msg.sender,
            VIN
        );
    }

    function ReceiveServicedVehicle(
        bytes32 ServicedvehicleID,
        bool received,
        address receiver1,
        address receiver2,
        address receiver4
    ) public onlyRECeiver {
        require(
            GetServicedVehicleID[ServicedvehicleID].receiver3 == msg.sender,
            "Sender not authorized."
        );
        require(
            GetServicedVehicleID[ServicedvehicleID].ServicedVehicleStatus ==
                status.Pending
        );
        require(
            RegistrationContract.AutomakerExists(receiver1),
            "Automaker address is not valid."
        );
        require(
            RegistrationContract.isNHTSA(receiver2),
            "NHTSA address is not valid."
        );
        require(
            RegistrationContract.DealerExists(receiver4),
            "Dealer address is not valid."
        );

        CompTime = 16;
        if (received) {
            GetServicedVehicleID[ServicedvehicleID]
                .ServicedVehicleStatus = status.Received;
        } else {
            GetServicedVehicleID[ServicedvehicleID]
                .ServicedVehicleStatus = status.Rejected;
        }
        emit ServicedVehicleReceived(
            ServicedvehicleID,
            GetServicedVehicleID[ServicedvehicleID].ServicedVehicleStatus
        );
    }

    event PenaltyStatusUpdated(address Automaker, bool penaltyStatus);

    function UpdatePenaltyStatusResult(
        uint TimetakentofinishtheRecall,
        uint thresholdtimetoservice,
        address Automaker
    ) public {
        require(
            RegistrationContract.isNHTSA(msg.sender) == true,
            "only NHTSA can perform this."
        );

        Penalty = false;

        if ((TimetakentofinishtheRecall) >= thresholdtimetoservice) {
            Penalty = true;
        }

        emit PenaltyStatusUpdated(Automaker, Penalty);
    }
}

contract InspectionHandler {
    Registration RegistrationContract;

    enum status {
        Pending,
        Accepted,
        Rejected,
        Uploaded,
        Available,
        NotAvailable
    }

    struct InspectionRequestDetails {
        address receiver;
        address requestor;
        bytes32 DefectComplaintRequestID;
        status InspectionRequestStatus;
    }

    struct InspectionReportDetails {
        address Uploader;
        address Receiver1;
        address Receiver2;
        bytes32 InspectionReportID;
        status InspectionReportStatus;
    }
    mapping(bytes32 => InspectionRequestDetails) public GetInspectionRequestID;
    mapping(bytes32 => InspectionReportDetails) public GetInspectionReportID;

    constructor(address registration) public {
        RegistrationContract = Registration(registration);

        if (!RegistrationContract.isNHTSA(msg.sender))
            revert("Sender not authorized");
    }

    modifier onlyRequestor7() {
        require(
            RegistrationContract.isNHTSA(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    modifier onlyReceiver7() {
        require(
            RegistrationContract.InspectionDepartmentExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    modifier onlyCreator() {
        require(
            RegistrationContract.InspectionDepartmentExists(msg.sender),
            "sender not authorized."
        );
        _;
    }
    modifier onlyUploader() {
        require(
            RegistrationContract.InspectionDepartmentExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    event InspectionRequestPlaced(
        bytes32 InspectionRequestID,
        address receiver,
        address requestor,
        bytes32 DefectComplaintRequestID
    );
    event InspectionRequestStatusupdated(
        bytes32 InspectionRequestID,
        status newStatus
    );

    function PlaceInspectionRequest(
        address receiver,
        bytes32 DefectComplaintRequestID
    ) public onlyRequestor7 {
        require(
            RegistrationContract.InspectionDepartmentExists(receiver),
            "InspectionDepartment's address is not valid."
        );
        bytes32 temp = keccak256(
            abi.encodePacked(
                msg.sender,
                now,
                address(this),
                DefectComplaintRequestID
            )
        );
        GetInspectionRequestID[temp] = InspectionRequestDetails(
            receiver,
            msg.sender,
            DefectComplaintRequestID,
            status.Pending
        );

        emit InspectionRequestPlaced(
            temp,
            receiver,
            msg.sender,
            DefectComplaintRequestID
        );
    }

    function ConfirmInspectionRequest(
        bytes32 InspectionRequestID,
        bool accepted
    ) public onlyReceiver7 {
        require(
            GetInspectionRequestID[InspectionRequestID].receiver == msg.sender,
            "Sender not authorized."
        );
        require(
            GetInspectionRequestID[InspectionRequestID]
                .InspectionRequestStatus == status.Pending
        );

        if (accepted) {
            (GetInspectionRequestID[InspectionRequestID]
                .InspectionRequestStatus = status.Accepted);
        } else {
            (GetInspectionRequestID[InspectionRequestID]
                .InspectionRequestStatus = status.Rejected);
        }
        emit InspectionRequestStatusupdated(
            InspectionRequestID,
            GetInspectionRequestID[InspectionRequestID].InspectionRequestStatus
        );
    }

    event InspectionReportCreated(
        bytes32 InspectionReportID,
        bytes32 InspectionRequestID,
        address Creator,
        address Receiver
    );
    event InspctionReportUploadRequested(
        bytes32 InspectionReportID,
        address Requestor,
        address Receiver
    );
    event InspectinReportUploaded(
        bytes32 InspectionReportID,
        status newStatus,
        address Uploader,
        address Receiver1,
        address Receiver2,
        string IPFS
    );

    function CreateInspectionReport(
        address Creator,
        address Receiver,
        bytes32 InspectionRequestID
    ) public onlyCreator {
        require(
            RegistrationContract.InspectionDepartmentExists(Creator),
            "Creator's address is not authorized."
        );
        require(
            RegistrationContract.isNHTSA(Receiver),
            "Receiver's address is not authorized."
        );
        bytes32 temp1 = keccak256(
            abi.encodePacked(
                msg.sender,
                now,
                address(this),
                InspectionRequestID
            )
        );
        GetInspectionReportID[temp1] = InspectionReportDetails(
            Creator,
            Receiver,
            msg.sender,
            InspectionRequestID,
            status.Pending
        );

        emit InspectionReportCreated(
            temp1,
            InspectionRequestID,
            Creator,
            Receiver
        );
    }

    function RequestInspectionReportUpload(
        address Requestor,
        address Receiver,
        bytes32 InspectionReportID
    ) public onlyRequestor7 {
        require(
            RegistrationContract.isNHTSA(Requestor),
            "Requestor's address is not valid."
        );
        require(
            RegistrationContract.InspectionDepartmentExists(Receiver),
            "Receiver's address is not valid."
        );

        emit InspctionReportUploadRequested(
            InspectionReportID,
            Requestor,
            Receiver
        );
    }

    function UploadInspectionReport(
        bytes32 InspectionReportID,
        bool Uploaded,
        address Uploader,
        address Receiver1,
        address Receiver2,
        string memory IPFS_Hash
    ) public onlyUploader {
        require(
            GetInspectionReportID[InspectionReportID].Uploader == msg.sender,
            "Sender not authorized."
        );
        require(
            RegistrationContract.isNHTSA(Receiver1),
            "Receiver1's address is not valid."
        );
        require(
            RegistrationContract.AutomakerExists(Receiver2),
            "Receiver2's address is not valid."
        );
        require(
            GetInspectionReportID[InspectionReportID].InspectionReportStatus ==
                status.Pending
        );

        if (Uploaded) {
            (GetInspectionReportID[InspectionReportID]
                .InspectionReportStatus = status.Available);
        } else {
            (GetInspectionReportID[InspectionReportID]
                .InspectionReportStatus = status.NotAvailable);
        }
        emit InspectinReportUploaded(
            InspectionReportID,
            GetInspectionReportID[InspectionReportID].InspectionReportStatus,
            Uploader,
            Receiver1,
            Receiver2,
            IPFS_Hash
        );
    }
}

contract Correctiveactionhandler {
    address payable owner;
    uint public Totalinventory;
    uint public Requestedpartquantity;
    uint public Availableinventory;
    string public PartID;

    Registration RegistrationContract;

    enum status {
        Pending,
        Accepted,
        Rejected,
        Received,
        Shipped
    }
    struct PurchaseOrderDetails {
        address receiver;
        address requestor;
        string Partnumber;
        uint RequestedPartQuantity;
        status PurchaseOrderStatus;
    }
    mapping(bytes32 => PurchaseOrderDetails) public GetPurchaseOrderID;
    event PurchaseOrderPlaced(
        bytes32 PurchaseOrderID,
        address receiver,
        address requestor,
        string Partnumber,
        uint requestedpartquantity
    );
    event InventoryUpdated(string PartID, uint Available);
    event PurchaseOrderConfirmed(
        bytes32 PurchaseOrderID,
        address Receiver2,
        uint availableinventory,
        uint quantityrequested,
        status newStatus
    );

    constructor(
        address registration,
        string memory Partnumber,
        uint requestedpartquantity
    ) public {
        RegistrationContract = Registration(registration);

        PartID = Partnumber;
        Requestedpartquantity = requestedpartquantity;

        if (!RegistrationContract.AutomakerExists(msg.sender))
            revert("Sender not authorized");
    }

    modifier onlyRequestor() {
        require(
            RegistrationContract.AutomakerExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    modifier onlyReceiver() {
        require(
            RegistrationContract.AutomobilePartsSupplierExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    modifier onlyReceiver2() {
        require(
            RegistrationContract.AutomakerExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    modifier onlyRequestor2() {
        require(
            RegistrationContract.AutomobilePartsSupplierExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }

    function PlacePurchaseOrder(
        address receiver,
        string memory Partnumber,
        uint requestedpartquantity
    ) public onlyRequestor {
        require(
            RegistrationContract.AutomobilePartsSupplierExists(receiver),
            "AutomobilePartsSupplier's address is not valid."
        );
        bytes32 temp = keccak256(
            abi.encodePacked(
                msg.sender,
                now,
                address(this),
                Partnumber,
                requestedpartquantity
            )
        );
        GetPurchaseOrderID[temp] = PurchaseOrderDetails(
            receiver,
            msg.sender,
            Partnumber,
            requestedpartquantity,
            status.Pending
        );

        emit PurchaseOrderPlaced(
            temp,
            receiver,
            msg.sender,
            Partnumber,
            requestedpartquantity
        );
    }

    function UpdateInventoryDatabase(
        string memory Partnumber,
        uint AvailableQuantity
    ) public onlyReceiver {
        if (!RegistrationContract.AutomobilePartsSupplierExists(msg.sender))
            revert("Sender not authorized");
        Totalinventory = AvailableQuantity;
        Availableinventory = Totalinventory;
        emit InventoryUpdated(Partnumber, Availableinventory);
    }

    function ConfirmPurchaseOrder(
        bytes32 PurchaseOrderID,
        address Receiver2,
        uint quantitytoship,
        bool accepted
    ) public onlyRequestor2 {
        require(
            Availableinventory >= quantitytoship,
            "Not enough stock available"
        );
        require(
            RegistrationContract.AutomakerExists(Receiver2),
            "Automaker doesnot exist"
        );
        Availableinventory -= quantitytoship;
        require(
            GetPurchaseOrderID[PurchaseOrderID].PurchaseOrderStatus ==
                status.Pending
        );

        if (accepted) {
            (GetPurchaseOrderID[PurchaseOrderID].PurchaseOrderStatus = status
                .Accepted);
        } else {
            (GetPurchaseOrderID[PurchaseOrderID].PurchaseOrderStatus = status
                .Rejected);

            emit PurchaseOrderConfirmed(
                PurchaseOrderID,
                Receiver2,
                Availableinventory,
                quantitytoship,
                GetPurchaseOrderID[PurchaseOrderID].PurchaseOrderStatus
            );
        }
    }

    struct ShipmentDetails {
        address receiver1;
        address requestor1;
        string Partnumber;
        uint Requestedpartquantity;
        uint quantitytoship;
        status ShipmentStatus;
    }
    mapping(bytes32 => ShipmentDetails) public GetShipmentNoticeID;

    modifier onlySEnder1() {
        require(
            RegistrationContract.AutomobilePartsSupplierExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    modifier onlyReceiver3() {
        require(
            RegistrationContract.AutomakerExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }
    event ShipmentNoticeCreated(
        bytes32 ShipmentNoticeID,
        address sender,
        address receiver1
    );
    event StatusUPdated(bytes32 ShipmentNoticeID, status newStatus);

    function CreateShipmentNotice(
        address receiver1,
        bytes32 PurchaseOrderID,
        uint quantitytoship
    ) public onlySEnder1 {
        require(
            RegistrationContract.AutomakerExists(receiver1),
            "Automaker's address is not valid."
        );
        bytes32 temp1 = keccak256(
            abi.encodePacked(
                msg.sender,
                now,
                address(this),
                PurchaseOrderID,
                quantitytoship
            )
        );
        GetShipmentNoticeID[temp1] = ShipmentDetails(
            receiver1,
            msg.sender,
            PartID,
            Requestedpartquantity,
            quantitytoship,
            status.Pending
        );

        emit ShipmentNoticeCreated(temp1, receiver1, msg.sender);
    }

    function ConfirmShipmentReceive(
        bytes32 ShipmentNoticeID,
        bool received
    ) public onlyReceiver3 {
        require(
            GetShipmentNoticeID[ShipmentNoticeID].receiver1 == msg.sender,
            "Sender not authorized."
        );
        require(
            GetShipmentNoticeID[ShipmentNoticeID].ShipmentStatus ==
                status.Pending
        );

        if (received) {
            GetShipmentNoticeID[ShipmentNoticeID].ShipmentStatus = status
                .Received;
        } else {
            GetShipmentNoticeID[ShipmentNoticeID].ShipmentStatus = status
                .Rejected;
        }
        emit StatusUPdated(
            ShipmentNoticeID,
            GetShipmentNoticeID[ShipmentNoticeID].ShipmentStatus
        );
    }
}
