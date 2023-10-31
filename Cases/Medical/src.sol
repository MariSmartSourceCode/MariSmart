pragma solidity =0.6.0;

contract Registration {
    mapping(address => bool) Covid19ScreeningUnit;
    mapping(address => bool) WasteShipper;
    mapping(address => bool) WasteTreatmentUnit;
    mapping(address => uint) manufacturers_LIC;
    mapping(address => uint) distributors_LIC;
    mapping(address => uint) Covid19ScreeningUnit_LIC;
    mapping(address => uint) WasteShipper_LIC;
    mapping(address => bool) manufacturers;
    mapping(address => bool) distributors;
    mapping(address => uint) WasteTreatmentUnit_LIC;
    address owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not authorized.");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function register_Manufacturer(address a, uint licence) public onlyOwner {
        manufacturers_LIC[a] = licence;
        require(
            !manufacturers[a],
            "Cannot registor as Manufacturer already exists or licence number is invalid"
        );

        manufacturers[a] = true;
    }

    function register_Distributor(address b, uint licence) public onlyOwner {
        distributors_LIC[b] = licence;
        require(
            !distributors[b],
            "Cannot registor as Distributor already exists or licence number is invalid"
        );

        distributors[b] = true;
    }

    function register_Covid19ScreeningUnit(
        address c,
        uint licence
    ) public onlyOwner {
        Covid19ScreeningUnit_LIC[c] = licence;
        require(
            !Covid19ScreeningUnit[c],
            "Cannot registor as Covid19ScreeningUnit exists already or licence number is invalid"
        );

        Covid19ScreeningUnit[c] = true;
    }

    function register_WasteShipper(address d, uint licence) public onlyOwner {
        WasteShipper_LIC[d] = licence;
        require(
            !WasteShipper[d],
            "Cannot registor since WasteShipper exists already or licence number is invalid"
        );

        WasteShipper[d] = true;
    }

    function register_WasteTreatmentUnit(
        address e,
        uint licence
    ) public onlyOwner {
        WasteTreatmentUnit_LIC[e] = licence;
        require(
            !WasteTreatmentUnit[e],
            "Cannot registor since WasteTreatmentUnit exists already or licence number is invalid"
        );

        WasteTreatmentUnit[e] = true;
    }

    function isOwner(address s) public view returns (bool) {
        return (owner == s);
    }

    function manufacturerExists(address k) public view returns (bool) {
        return manufacturers[k];
    }

    function distributorExists(address x) public view returns (bool) {
        return distributors[x];
    }

    function covid19ScreeningUnitExists(address r) public view returns (bool) {
        return Covid19ScreeningUnit[r];
    }

    function wasteShipperExists(address q) public view returns (bool) {
        return WasteShipper[q];
    }

    function wasteTreatmentUnitExists(address y) public view returns (bool) {
        return WasteTreatmentUnit[y];
    }

    function manufacturerlicenceisValid(address k1) public view returns (bool) {
        if (manufacturers_LIC[k1] != 0 && manufacturers_LIC[k1] != 777) {
            return true;
        }
    }

    function distributorlicenceisValid(address x1) public view returns (bool) {
        //return distributors_LIC[x1];
        if (distributors_LIC[x1] != 0 && distributors_LIC[x1] != 777) {
            return true;
        }
    }

    function covid19ScreeningUnitlicenceisValid(
        address r1
    ) public view returns (bool) {
        // return Covid19ScreeningUnit_LIC[r1];
        if (
            Covid19ScreeningUnit_LIC[r1] != 0 &&
            Covid19ScreeningUnit_LIC[r1] != 777
        ) {
            return true;
        }
    }

    function wasteShipperlicenceisValid(address q1) public view returns (bool) {
        if (WasteShipper_LIC[q1] != 0 && WasteShipper_LIC[q1] != 777) {
            return true;
        }
    }

    function wasteTreatmentUnitlicenceisValid(
        address y1
    ) public view returns (bool) {
        if (
            WasteTreatmentUnit_LIC[y1] != 0 && WasteTreatmentUnit_LIC[y1] != 777
        ) {
            return true;
        }
    }

    function getshipperLicense(address S) public view returns (uint) {
        return WasteShipper_LIC[S];
    }
}

contract WasteShipmentHandler {
    uint flag;
    bytes32 RD;
    bool statusflag;
    bool penality;
    uint misbehaviorcount;
    uint threshold;
    uint difference;
    uint license;
    Registration RegistrationContract;

    enum statusOrder {
        pending,
        accepted,
        rejected,
        shipping,
        reached,
        received
    }

    struct shipmentdetails {
        string time;
        string location;
        statusOrder status;
        address receiver;
        uint weight;
        string wasteImageshash;
        uint sensorstate;
        address EquipmentID;
    }

    event ShippingRequestPlaced(
        bytes32 ShipmentID,
        address ShipperEA,
        address WasteGeneratorEA,
        uint WasteWeight,
        uint SensorState,
        address Equipment
    );
    event ShipmentRequestStatusUpdated(bytes32 ShipmentID, statusOrder stat);
    event ShipmentStateandlocationUpdated(
        bytes32 ShipmentID,
        statusOrder stat,
        string CurrentLocation,
        uint SensorState,
        uint256 Time
    );
    event WasteReceived(bytes32 ShipmentID, uint256 Time);
    event PenalityStatusUpdated(
        address ShipperEA,
        uint256 ViolationsCount,
        uint ShipperLicense
    );

    constructor(address reigstration) public {
        RegistrationContract = Registration(reigstration);
        misbehaviorcount = 0;
        threshold = 2;
        statusflag = false;
        flag = 0;
    }

    mapping(uint => bool) public shipmentconaintersstate;
    mapping(address => bool) public COVIDresult;

    mapping(bytes32 => shipmentdetails) public orders;

    modifier onlyHospital() {
        require(
            RegistrationContract.covid19ScreeningUnitExists(msg.sender),
            "Waste generator not authorized."
        );
        _;
    }
    modifier onlyTreatmentfacility() {
        require(
            RegistrationContract.wasteTreatmentUnitExists(msg.sender) &&
                RegistrationContract.wasteTreatmentUnitlicenceisValid(
                    msg.sender
                ),
            "COVID-19 waste treatment facility is not authorized."
        );
        _;
    }

    modifier onlyshipper() {
        require(
            RegistrationContract.wasteShipperExists(msg.sender) &&
                RegistrationContract.wasteShipperlicenceisValid(msg.sender),
            "Waste Shipper entity is not authorized."
        );
        _;
    }

    function UpdateHealthstatus(
        address ShipperEA,
        bool COVIDupdatedresult
    ) public onlyHospital {
        require(
            RegistrationContract.wasteShipperExists(ShipperEA),
            "Transporter not registered"
        );
        COVIDresult[ShipperEA] = COVIDupdatedresult;
    }

    function GetShipeOrderState(
        bytes32 shipID
    ) public view returns (statusOrder) {
        return (orders[shipID].status);
    }

    function GetSensorsState(bytes32 shipID) public view returns (uint256) {
        return (orders[shipID].sensorstate);
    }

    function GetWasteLocation(
        bytes32 shipID
    ) public view returns (string memory) {
        return (orders[shipID].location);
    }

    function GetHealthData(address ShipperEA) public view returns (bool) {
        return (COVIDresult[ShipperEA]);
    }

    function PlaceShipmentRequest(
        address ShipperEA,
        uint Weight,
        string memory Currentlocation,
        string memory Pickuptime,
        uint Sensstate,
        string memory WasteImageshash,
        address EquipID
    ) public onlyHospital {
        require(
            COVIDresult[ShipperEA],
            "Request not guranteed since COVID-19 result of shipper is not positive."
        );
        statusflag = false;
        bytes32 shipID = keccak256(
            abi.encodePacked(ShipperEA, address(this), Weight, Pickuptime, now)
        );
        orders[shipID] = shipmentdetails(
            Pickuptime,
            Currentlocation,
            statusOrder.pending,
            ShipperEA,
            Weight,
            WasteImageshash,
            Sensstate,
            EquipID
        );
        flag = Sensstate;
        RD = shipID;
        emit ShippingRequestPlaced(
            shipID,
            ShipperEA,
            msg.sender,
            Weight,
            Sensstate,
            EquipID
        );
    }

    function GetShipmentID() public view returns (bytes32) {
        return RD;
    }

    function ConfirmShipmentRequest(
        bytes32 ShipID,
        bool Accept
    ) public onlyshipper {
        //require(orders[ShipID].status==statusOrder.pending);

        require(
            keccak256(abi.encodePacked(orders[ShipID].status)) ==
                keccak256(abi.encodePacked(statusOrder.pending))
        );
        if (Accept == true) {
            orders[ShipID].status = statusOrder.accepted;
        } else {
            orders[ShipID].status = statusOrder.rejected;
        }
        statusflag = true;
        emit ShipmentRequestStatusUpdated(ShipID, orders[ShipID].status);
    }

    //function Getsttauscheck() public view returns(bytes32){
    //      return orders[shipID].status;
    //}
    function UpdateShipmentStatus(
        bytes32 ShipID,
        string memory Currentlocation,
        uint Sensordata,
        bool Reacheddestination
    ) public onlyshipper {
        statusOrder A = orders[ShipID].status;
        if (
            keccak256(abi.encodePacked(A)) ==
            keccak256(abi.encodePacked(statusOrder.rejected))
        ) {
            revert(
                "Action cannot be granted since the shipment request is rejected by the shipper! ."
            );
        }

        //require(orders[shipID].status!=statusOrder.reached, "Transporter not registered");
        if (statusflag == true && Reacheddestination == false) {
            //require(orders[shipID].status==statusOrder.Accepted);

            orders[ShipID].status = statusOrder.shipping;
            orders[ShipID].location = Currentlocation;
            orders[ShipID].sensorstate = Sensordata;
        }

        if (orders[ShipID].sensorstate != flag) {
            misbehaviorcount += 1;
            penality = true;
        }

        if (statusflag == true && Reacheddestination == true) {
            orders[ShipID].status = statusOrder.reached;
            orders[ShipID].location = Currentlocation;
            orders[ShipID].sensorstate = Sensordata;
        }
        emit ShipmentStateandlocationUpdated(
            ShipID,
            orders[ShipID].status,
            orders[ShipID].location,
            orders[ShipID].sensorstate,
            now
        );
    }

    function ConfirmShipmentReceiving(
        bytes32 ShipID,
        uint Weight_new
    ) public onlyTreatmentfacility {
        //(keccak256(abi.encodePacked(orders[shipID].status))==keccak256(abi.encodePacked(statusOrder.reached)))

        require(
            keccak256(abi.encodePacked(orders[ShipID].status)) ==
                keccak256(abi.encodePacked(statusOrder.reached)),
            "The Shipment carrying COVID-19 waste has not reached yet"
        );
        orders[ShipID].status = statusOrder.received;
        difference = Weight_new - orders[ShipID].weight;

        emit WasteReceived(ShipID, now);
    }

    function Getpenalty(
        address ShipperEA
    )
        public
        view
        returns (
            bool Result,
            uint256 Total_ViolationsCount,
            string memory Licence
        )
    {
        require(
            RegistrationContract.isOwner(msg.sender) == true,
            " Only Owner/FDA can perform this action."
        );
        if (
            RegistrationContract.wasteShipperExists(ShipperEA) &&
            penality == true
        ) {
            if (license == 777) {
                Licence = "Cancelled Code: 777";
                return (true, misbehaviorcount, Licence);
            } else {
                Licence = "Valid";
                return (true, misbehaviorcount, Licence);
            }
        }
    }

    function PenalityCalculationResult(address ShipperEA) public {
        require(
            RegistrationContract.isOwner(msg.sender) == true,
            " Only Owner/FDA can perform this action."
        );
        if (
            RegistrationContract.wasteShipperExists(ShipperEA) &&
            penality == true
        ) {
            if (misbehaviorcount >= threshold || difference != 0) {
                license = 777;
                emit PenalityStatusUpdated(
                    ShipperEA,
                    misbehaviorcount,
                    license
                );
            } else {
                emit PenalityStatusUpdated(
                    ShipperEA,
                    misbehaviorcount,
                    RegistrationContract.getshipperLicense(ShipperEA)
                );
            }
        }
    }
}

contract LotandOwnershipTransferManager {
    address public EquipmentID;
    string public EquipmentName;
    string public MaterialHash;
    string public BatchNumber;
    string public CertificateHash;
    uint public TotalQuantity;
    uint Call_Status;
    uint Call_OWnStatus;
    uint public Available_Balance;
    address registrationContract;
    string ownerType;
    address payable owner;
    Registration RegistrationContract;

    event OwnershipTransferred(
        address NewOwnerEA,
        string OwnerType,
        uint256 Time
    );
    event InventoryUpdated(
        address EquipmentEA,
        address ProviderEA,
        uint QuantitySold,
        uint256 Time
    );
    event EquipmentLotDispatched(
        address EquipmentEA,
        string EquipmentName,
        string MaterialHash,
        string BatchNumber,
        string CECertificateHash
    );
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not authorized.");
        _;
    }

    modifier onlysender() {
        require(
            RegistrationContract.manufacturerExists(msg.sender) ||
                RegistrationContract.distributorExists(msg.sender),
            "Medical supplies sender is not authorized."
        );
        _;
    }

    function transferOwnership(address payable NewOwner) public onlyOwner {
        require(Call_OWnStatus > 0, "Multiple callls are not allowed");
        Call_OWnStatus = 0;
        if (RegistrationContract.manufacturerExists(NewOwner))
            ownerType = "Manufacturer";
        else if (RegistrationContract.distributorExists(NewOwner))
            ownerType = "Distributor";
        else if (RegistrationContract.covid19ScreeningUnitExists(NewOwner))
            ownerType = "Covid19ScreeningUnit";
        else if (RegistrationContract.wasteShipperExists(NewOwner))
            ownerType = "WasteShipper";
        else revert("New Owner doesn't exist.");
        owner = NewOwner;
        emit OwnershipTransferred(owner, ownerType, now);
        Call_OWnStatus = 3;
    }

    constructor(
        address registration,
        address ID,
        string memory Name,
        string memory Material,
        string memory Batch,
        string memory CE,
        uint Quantity
    ) public {
        RegistrationContract = Registration(registration);

        if (!RegistrationContract.manufacturerExists(msg.sender))
            revert("Stakeholder is not authorized");
        registrationContract = registration;
        owner = msg.sender;
        EquipmentID = ID;
        EquipmentName = Name;
        BatchNumber = Batch;
        MaterialHash = Material;
        CertificateHash = CE;
        TotalQuantity = Quantity;
        Available_Balance = TotalQuantity;
        Call_Status = 34;
        Call_OWnStatus = 34;

        emit EquipmentLotDispatched(
            address(this),
            EquipmentName,
            MaterialHash,
            BatchNumber,
            CertificateHash
        );
    }

    function UpdateInventory(
        address ProviderEA,
        uint Requested_quantity
    ) public onlysender {
        require(Call_Status > 0, "Multiple callls are not allowed");
        Call_Status = 0;
        require(
            Available_Balance >= Requested_quantity,
            "Not enough Items available in the stock"
        );

        if (RegistrationContract.manufacturerExists(msg.sender)) {
            // ownerType="Manufacturer";
            require(
                RegistrationContract.distributorExists(ProviderEA),
                "Distributor stakeholder does not exist"
            );
        } else if (RegistrationContract.distributorExists(msg.sender)) {
            // ownerType="Distributor";
            require(
                RegistrationContract.covid19ScreeningUnitExists(ProviderEA),
                "Covid-19 Screening Unit stakeholder does not exist"
            );
        } else revert("New Owner is not authorized.");

        Available_Balance = Available_Balance - Requested_quantity;

        emit InventoryUpdated(
            address(this),
            ProviderEA,
            Requested_quantity,
            now
        );
        Call_Status = 5;
        if (Available_Balance == 0) {
            selfdestruct(owner);
        }
    }
}

contract OrderManager {
    struct order {
        address receiver;
        address medicalequipmentID;
        string medicalequipmentname; ///
        address orderer;
        uint quantity;
        string equipmenttype;
        status orderStatus;
    }

    Registration RegistrationContract;
    string name;
    bytes32 OdrID;

    mapping(bytes32 => order) public orders;
    modifier onlyOwner() {
        require(
            RegistrationContract.isOwner(msg.sender),
            "Sender not authorized."
        );
        _;
    }

    enum status {
        Awaiting,
        Approved,
        Rejected,
        Received
    }

    modifier onlyOrderer() {
        require(
            RegistrationContract.distributorExists(msg.sender) ||
                RegistrationContract.covid19ScreeningUnitExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }

    modifier onlyReceiver() {
        require(
            RegistrationContract.manufacturerExists(msg.sender) ||
                RegistrationContract.distributorExists(msg.sender),
            "Sender not authorized."
        );
        _;
    }

    event OrderPlaced(
        bytes32 OrderID,
        address ReceiverEA,
        string Medicalequipmentname,
        address MedicalequipmentEA,
        uint LotSize,
        address OrdererEA,
        uint time
    );
    event OrderStatusUpdated(bytes32 OrderID, status NewStatus);
    event OrderReceived(bytes32 OrderID);

    constructor(address reigstration) public {
        RegistrationContract = Registration(reigstration);

        if (!RegistrationContract.isOwner(msg.sender))
            revert("Sender not authorized");
    }

    //
    function PlaceOrderRequest(
        address MedicalequipmentID,
        uint LotSize,
        address Receiver,
        string memory Medicalequipmentname,
        string memory Equipmenttype
    ) public onlyOrderer {
        require(
            RegistrationContract.distributorExists(Receiver) ||
                RegistrationContract.manufacturerExists(Receiver),
            "Medical supplies provider's address is not valid"
        );

        if (RegistrationContract.distributorExists(msg.sender))
            name = "Distributor";
        else if (RegistrationContract.covid19ScreeningUnitExists(msg.sender))
            name = "Covid19ScreeningUnit";
        else revert("Invalid user.");

        //keccak256(abi. encodePacked(name)) == keccak256(abi. encodePacked("Distributor"))

        if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("Distributor"))
        ) {
            if (
                RegistrationContract.distributorlicenceisValid(msg.sender) !=
                true
            ) revert("Licence of the orderer is not valid");
        }
        if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("Covid19ScreeningUnit"))
        ) {
            if (
                RegistrationContract.covid19ScreeningUnitlicenceisValid(
                    msg.sender
                ) != true
            ) revert("Licence of the orderer is not valid");
        }

        bytes32 temp = keccak256(
            abi.encodePacked(
                msg.sender,
                now,
                address(this),
                MedicalequipmentID,
                Medicalequipmentname,
                Equipmenttype
            )
        );
        orders[temp] = order(
            Receiver,
            MedicalequipmentID,
            Medicalequipmentname,
            msg.sender,
            LotSize,
            Equipmenttype,
            status.Awaiting
        );
        OdrID = temp;

        emit OrderPlaced(
            temp,
            Receiver,
            Medicalequipmentname,
            MedicalequipmentID,
            LotSize,
            msg.sender,
            now
        );
    }

    function GetOrderID() public view returns (bytes32) {
        return OdrID;
    }

    function GetOrderState(bytes32 orderID) public view returns (status) {
        return (orders[orderID].orderStatus);
    }

    function ConfirmOrder(bytes32 orderID, bool accepted) public onlyReceiver {
        require(
            orders[orderID].receiver == msg.sender,
            "The receiver of the order is not authorized"
        );

        if (RegistrationContract.manufacturerExists(msg.sender))
            name = "manufacturer";
        else if (RegistrationContract.distributorExists(msg.sender))
            name = "distributor";
        else revert("Invalid user.");

        if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("manufacturer"))
        ) {
            if (
                RegistrationContract.manufacturerlicenceisValid(msg.sender) !=
                true
            ) revert("Licence of the manufacturer is not valid");
        }
        if (
            keccak256(abi.encodePacked(name)) ==
            keccak256(abi.encodePacked("distributor"))
        ) {
            if (
                RegistrationContract.distributorlicenceisValid(msg.sender) !=
                true
            ) revert("Licence of the distributor is not valid");
        }

        require(
            keccak256(abi.encodePacked(orders[orderID].orderStatus)) ==
                keccak256(abi.encodePacked(status.Awaiting))
        );

        if (accepted) {
            orders[orderID].orderStatus = status.Approved;
        } else {
            orders[orderID].orderStatus = status.Rejected;
        }
        emit OrderStatusUpdated(orderID, orders[orderID].orderStatus);
    }

    function confirmReceived(bytes32 orderID) public onlyOrderer {
        require(
            orders[orderID].orderer == msg.sender,
            "Sender not authorized."
        );
        /////////////////A part of this code is borrowed from https://github.com/MazenDB/TrackingPPE////////////////////////////////
        require(
            keccak256(abi.encodePacked(orders[orderID].orderStatus)) ==
                keccak256(abi.encodePacked(status.Approved)),
            "The shipment has not arrived yet"
        );

        orders[orderID].orderStatus = status.Received;

        emit OrderReceived(orderID);
    }
}
