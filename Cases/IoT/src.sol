pragma solidity ^0.4.0; //version 0.4 or higher

contract IoTContainer {
    //participating entities with Ethereum addresses
    address container;
    address public sender_owner;
    address public receiver;
    string public content; //description of container content
    bytes32 public passphrase; //recived passphrase when money is deposited
    string public receivedCode; //recived code to be hashed
    enum packageState {
        NotReady,
        PackageContainerReadyforSelfCheck,
        ReadyforShipment,
        MoneyDeposited,
        StartShippment,
        WaitingforPassphrase,
        ReceiverAuthentiated,
        WaitingForCorrectPasscode,
        ShipmentReceived,
        AuthenticationFailureAborted,
        Aborted
    }
    packageState public state;
    uint startTime;
    uint daysAfter;
    uint shipmentPrice;
    //sensors
    enum violationType {
        None,
        Temp,
        Open,
        Route,
        Jerk
    }
    violationType public violation;
    int selfcheck_result; //1 or 0 indicating the self check result of IoTContainer
    int tempertaure; //track the tempertaure any integer
    int open; //if the container opens 1 , 0
    int onTrack; //to track the route 1 , 0
    int jerk; //sudden jerk 1, 0

    //contructor
    function IoTContainer() {
        startTime = block.timestamp;
        daysAfter = 2; //2 days maximum for providing another passcode
        content = "This container is shipping frozen food.";
        shipmentPrice = 10 ether;
        container = 0x583031d1113ad414f02576bd6afabfb302140225;
        sender_owner = msg.sender; //address of sender
        receiver = 0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db;
        state = packageState.NotReady;
        selfcheck_result = 0;
    }

    //modifiers
    modifier OnlySender() {
        //only sender who is the owner
        require(sender_owner == msg.sender);
        _;
    }

    modifier OnlyReceiver() {
        //only receiver
        require(msg.sender == receiver);
        _;
    }
    modifier OnlyContainer() {
        require(msg.sender == container);
        _;
    }
    modifier costs() {
        require(msg.value == shipmentPrice);
        _;
    }
    //Tracking Events
    event PackageReadyforSelfCheck(address owner); //sender announces Package is Ready for selfcheck
    event SelfCheckDone(string msg); //to announce result of selfcheck
    event DepositMoneyDone(string msg, address receiver); //money is deposited
    event StarttedShippment(address sender); //shipment StartShippment
    event ShipmentArrivedToDestination(string msg, address container); //shipment arrived to destination
    event ReceiverAuthenticatedSuccessfully(string msg, address receiver);
    event ReceiverAuthenticationFailure(string msg, address receiver); //failure within 48 hours
    event AuthenticationFailureAborted(string msg, address receiver); //event when authentication failure after 48 hrs
    event ShipmentReceived(address receiver); //shipment ShipmentReceived Succesfully
    event ShipmentViolatedandRefund(address container); //shipment violated and refund occured
    event PaymentReceivedbySender(address sender); //payment received by manufacturer
    //Violation Events
    event TempertaureViolation(string msg, bool t, int v); //temperature out of accepted range
    event SuddenJerk(string msg, bool j, int v);
    event SuddenContainerOpening(string msg, bool o, int v);
    event OutofRoute(string msg, bool r, int v);

    function CreatePackage() OnlySender {
        require(state == packageState.NotReady);
        state = packageState.PackageContainerReadyforSelfCheck; //once locked the container will do a self check on the sensors
        PackageReadyforSelfCheck(msg.sender); //trigger event
    }

    function PerformmedSelfCheck(int result) OnlyContainer {
        require(state == packageState.PackageContainerReadyforSelfCheck);
        selfcheck_result = result;
        if (selfcheck_result == 1) {
            //indicating the result is OK
            state = packageState.ReadyforShipment;
            SelfCheckDone("Self Check result is Success"); //trigger event with result
        } else if (selfcheck_result == 0) {
            state = packageState.Aborted;
            SelfCheckDone(
                "Shipment Aborted: Failure , container must be fixed."
            ); //trigger event with result
            selfdestruct(msg.sender);
        }
    }

    //deposit money and send the hash
    function DepositMoneyforShipment(bytes32 hash) payable OnlyReceiver costs {
        require(state == packageState.ReadyforShipment); //this indicates that self check is OK
        state = packageState.MoneyDeposited;
        passphrase = hash;
        DepositMoneyDone(
            "Money deposited and passphrase hash provided",
            msg.sender
        ); //trigger event
    }

    function StartShippment() OnlySender {
        require(state == packageState.MoneyDeposited);
        state = packageState.StartShippment;
        StarttedShippment(msg.sender); //trigger event
    }

    function ShipmentArrived() OnlyContainer {
        //called when the shipment arrives to destination
        require(state == packageState.StartShippment); //only if no violations
        state = packageState.WaitingforPassphrase;
        ShipmentArrivedToDestination(
            "Please receiver provide your code",
            msg.sender
        );
    }

    function ProvidePassphrase(string code) OnlyReceiver {
        require(
            (state == packageState.WaitingforPassphrase ||
                state == packageState.WaitingForCorrectPasscode) &&
                violation == violationType.None
        );
        receivedCode = code;
        if (passphrase == keccak256(receivedCode)) {
            //authenticated
            state = packageState.ReceiverAuthentiated;
            ReceiverAuthenticatedSuccessfully(
                "Passphrase matched successfully",
                msg.sender
            );
        } else {
            state = packageState.WaitingForCorrectPasscode;
            ReceiverAuthenticationFailure(
                "You have 48 hours to provide the correct passphrase",
                msg.sender
            );
        }
    }

    function ProvidePassPhraseAfterTime(string phrase) OnlyReceiver {
        if (block.timestamp <= startTime + daysAfter * 1 days) {
            ProvidePassphrase(phrase);
        }
        //it will be more than 2 days
        else {
            state = packageState.AuthenticationFailureAborted;
            AuthenticationFailureAborted(
                "Failure to provide the correct passcode within 48 hours",
                msg.sender
            );
            receiver.transfer(shipmentPrice / 2); //only half of the shipment price is refunded
            ShipmentViolatedandRefund(msg.sender);
            selfdestruct(msg.sender);
        }
    }

    function UnlockShippment() OnlyContainer {
        require(state == packageState.ReceiverAuthentiated);
        state = packageState.ShipmentReceived;
        ShipmentReceived(msg.sender); //trigger event
    }

    function GetShipmentMoney() OnlySender {
        require(state == packageState.ShipmentReceived);
        sender_owner.transfer(shipmentPrice); //transfer the money to the manufacturer
        PaymentReceivedbySender(msg.sender);
        selfdestruct(msg.sender);
    }

    //after violation, a refund
    function Refund() OnlyContainer {
        require(state == packageState.Aborted); //violation occured
        if (violation != violationType.None) {
            receiver.transfer(shipmentPrice);
            ShipmentViolatedandRefund(msg.sender);
            selfdestruct(msg.sender);
        }
    }

    function violationOccurred(
        string msg,
        violationType v,
        int value
    ) OnlyContainer {
        require(state == packageState.StartShippment);
        violation = v;
        state = packageState.Aborted;
        if (violation == violationType.Temp) {
            tempertaure = value;
            TempertaureViolation(msg, true, tempertaure);
        } else if (violation == violationType.Jerk) {
            jerk = value;
            SuddenJerk(msg, true, jerk);
        } else if (violation == violationType.Open) {
            open = value;
            SuddenContainerOpening(msg, true, open);
        } else if (violation == violationType.Route) {
            onTrack = value;
            OutofRoute(msg, true, onTrack);
        }
        Refund();
    }
}
