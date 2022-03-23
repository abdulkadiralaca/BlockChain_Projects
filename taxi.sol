pragma solidity >=0.7.0 <0.8.0;

contract Taxi{

    // Structure definitions of "Paticipant, TaxiDriver, CarDealer, Propeses".

    struct Participant{
        address payable pID;
        uint balance;
    }

    struct TaxiDriver{
        address payable tID;
        uint balance;
        uint salary;
        uint salaryTime;
        uint state;
        uint fireState;
        bool hired;
    }

    struct CarDealer{
        address payable cdID;
    }

    struct OwnedCar{
        uint256 carID;
    }

    struct ProposedCar{
        uint256 carID;
        uint price;
        uint offerValidTime;
        uint state;
    }

    struct ProposedCarRepurchase{
        uint carID;   // for owned car ID
        uint price;
        uint offerValidTime;
        uint state;
    }

    //------------- Variables --------------
    uint maintenanceAndTaxPay;
    uint maintenanceTime;
    uint dividendPayTime;
    uint participationFee;
    uint totalBalance;
    
    uint carID;

    address private owner;   // Owner is the person that deploys the contract first.
    address[] participantAddress;

    address payable carDealer;
    ProposedCar proposedCar;
    ProposedCarRepurchase proposedCarRepurchase;
    TaxiDriver taxiDriver;

    // Dicionarys for votes and participants addresses.
    mapping (address => Participant) participants;
    mapping (address => bool) proposedCarVotes;
    mapping(address => bool) taxiDriverVotes;
    mapping(address => bool) taxiDriverFireVotes;
    mapping (address => bool) repurchesCarVotes;


    // Modifiers
    modifier onlyOwner(){
        require(msg.sender == owner, "You are not the owner!");
        _ ;
    }

    modifier onlyParticipants(){
        require(participants[msg.sender].pID != address(0), "Only participants call this function!");
        _ ;
    }

    modifier onlyCarDealer(){
        require(msg.sender == carDealer, "You are not a carDealer!");
        _ ;
    }

    modifier onlyDriver(){
        require(msg.sender == taxiDriver.tID,  "You are not a taxi driver!");
        _ ;
    }

    // Functions
    constructor(address payable newCarDealer) {
        maintenanceAndTaxPay = 10 ether;
        totalBalance = 0 ether;
        participationFee = 100 ether;
        maintenanceTime = block.timestamp;
        dividendPayTime = block.timestamp;
        owner = msg.sender;
        setCarDealer(newCarDealer);
    }

     function setCarDealer(address payable newCarDealer) private{
        carDealer = newCarDealer;
    }

    function join() public payable{
        require(participantAddress.length < 9, "There are already 9 participants!");
        require(participants[msg.sender].pID == address(0), "Participant already exists!");
        require(msg.value >= participationFee, "Participant does not have enough ether to join!");
        participants[msg.sender] = Participant(msg.sender, 0 ether);
        participantAddress.push(msg.sender);
        totalBalance += participationFee;
        uint refund = msg.value - participationFee;
        if(refund > 0) {
            msg.sender.transfer(refund);
        }
    }

    function carProposeToBusiness(uint32 id, uint price, uint validTime) public onlyCarDealer{
        proposedCar = ProposedCar(id, price, validTime, 0);
        
        for(uint i = 0; i < participantAddress.length; i++){
            proposedCarVotes[participantAddress[i]] = false;
        }
    }

    function approvePurchaseCar() public onlyParticipants payable{
        require(!proposedCarVotes[msg.sender], "You have already voted!");
    
        proposedCar.state +=1;
        proposedCarVotes[msg.sender] = true;

        if(proposedCar.state > (participantAddress.length / 2)){
            require(carID == 0, "Already bought!");
            purchaseCar();
        }
        
    }

    function purchaseCar() private{
        require(totalBalance >= proposedCar.price, "Car is too expensive!");
        require(block.timestamp <= proposedCar.offerValidTime, "Car's valid time is exceed!");
        require(proposedCar.state > (participantAddress.length / 2), "Proposed car is not approved by prarticipants!");
        totalBalance = totalBalance - proposedCar.price;
        if(!carDealer.send(proposedCar.price)){
            totalBalance += proposedCar.price;
            revert();
        }
        carID = proposedCar.carID;
    }
    
    function repurchesCarPropose(uint32 id, uint price, uint validTime) public onlyCarDealer{
        require(carID == id);
        proposedCarRepurchase = ProposedCarRepurchase(id, price, validTime, 0);
        for(uint i = 0; i < participantAddress.length; i++){
            proposedCarVotes[participantAddress[i]] = false;
        }
    }

    function approveSellProposal() public onlyParticipants{
        require(!repurchesCarVotes[msg.sender], "Your vote is already taken!");
        proposedCarRepurchase.state += 1;
        repurchesCarVotes[msg.sender] = true;

        if(proposedCarRepurchase.state > (participantAddress.length / 2)){
            require(carID != 0, "Already sold!");
            repurchaseCar();
        }
    }

    function repurchaseCar() public payable onlyCarDealer{
        require(block.timestamp <= proposedCarRepurchase.offerValidTime, "Time is up!");
        require(proposedCarRepurchase.state > (participantAddress.length / 2), "Proposed car is not approved by prarticipants!");
        require(msg.value >= proposedCarRepurchase.price, "no money");
        totalBalance += msg.value;
        delete carID;
    }

    function proposeDriver(address payable tID, uint salary) public onlyOwner{
        taxiDriver = TaxiDriver(tID, salary , 0, 0, 0, 0, false);
        for(uint i = 0; i < participantAddress.length; i++){
            taxiDriverVotes[participantAddress[i]] = false;
        }
    }

    function approveDriver() public onlyParticipants{
        require(!taxiDriverVotes[msg.sender], "Each participant can vote only once!");
        taxiDriver.state += 1;
        taxiDriverVotes[msg.sender] = true;

        if(taxiDriver.state > (participantAddress.length / 2)){
            require(taxiDriver.hired != true, "Already hired :)");
            setDriver();
        }
    }
    
    function setDriver() private {
        taxiDriver.hired = true;
    }

    function proposeFireDirever() public onlyParticipants{
        require(taxiDriver.hired = true, "First, you should hire a driver, then you can fire him/her!");
        require(!taxiDriverFireVotes[msg.sender], "Each participant can vote only once!");
        taxiDriver.fireState += 1;
        taxiDriverFireVotes[msg.sender] = true;

        if(taxiDriver.fireState > (participantAddress.length / 2)){
            require(taxiDriver.hired = true, "Already fired :)");
            fireDriver();
        }

    }

    function fireDriver() private {
        delete taxiDriver;
    }

    function leaveJob()public onlyDriver{
        fireDriver();
    }

    function getCharge() public payable{
        totalBalance = totalBalance + msg.value;
    }

    function getSalary() public onlyDriver{
        require(block.timestamp - taxiDriver.salaryTime > 2629746, "You already get your salary!"); // 1 month equals to 2,629,746 seconds.
        require(taxiDriver.hired == true);
        require(totalBalance >= taxiDriver.balance, "Contract does not have enough money to pay!");
        require(taxiDriver.balance > 0, "There is no ether in driver balance");
        totalBalance -= taxiDriver.salary;
        taxiDriver.balance += taxiDriver.salary;
        taxiDriver.tID.transfer(taxiDriver.balance);
        taxiDriver.salaryTime = block.timestamp;
    }

    function carExpenses() public onlyParticipants{
        require(block.timestamp - maintenanceTime >= 15778476, "6 month");   // 6 months equal to 15778476 seconds.
        require(carID != 0, "First, buy a car!");
        require(totalBalance >= maintenanceAndTaxPay, "No money, no maintenance!");
        totalBalance -= maintenanceAndTaxPay;
        if(!carDealer.send(maintenanceAndTaxPay)){
            totalBalance += maintenanceAndTaxPay;
            revert();
        }
        maintenanceTime = block.timestamp;
    }

    function payDividend() public onlyParticipants{
        require(block.timestamp - dividendPayTime >= 15778476, "6 month");
        require(totalBalance > participationFee * participantAddress.length, "There is no profit right now");
        
        uint divideProfit = (totalBalance - (participationFee * participantAddress.length)) / participantAddress.length;
        for(uint i = 0; i < participantAddress.length; i++){
            participants[participantAddress[i]].balance += divideProfit;
        }
        totalBalance = 0;
        dividendPayTime = block.timestamp;
    }

    function getDividend() public onlyParticipants{
        require(participants[msg.sender].balance > 0 , "You do not have enough ether to get paid!");
        if(!msg.sender.send(participants[msg.sender].balance)){
            revert();
        }
        participants[msg.sender].balance = 0;
    }

    fallback() external payable{}
}