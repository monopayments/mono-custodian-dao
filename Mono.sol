// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Mono{

    address private owner;
    uint256 private expectedCost = 0.1 ether;
    uint256 public payedCost = 0 ether;
    uint256 public monosCost = 0 ether;
    bool public locked = true;
    uint256 public totalVipVoter = 0;
    uint256 private deadline;


    struct Person {
        address name;
        bool Payed;
        uint256 payedAmount;
        bool isVip;
    }

    mapping(address => Person) public registeredPerson;

    event Sent(address from, address to, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner,"Only owner");
        _;
    }

    modifier onlyUnlock() {
        require(locked == false,"Unlock the contract.");
        _;
    }
    
    modifier onlyOnce() {
        require(registeredPerson[msg.sender].Payed == false,"Each address pay only once.");
        _;
    }

    modifier onlyVip() {
        require(registeredPerson[msg.sender].isVip == true,"Only Vip persons can use this.");
        _;
    }

    modifier notDeadline() {
        require(block.timestamp<=deadline,"Deadline bro");
        _;
    }


    constructor(){
        owner =msg.sender;
        
    }

    function changeLock() external onlyOwner{
        locked = false;
    }

    function setExpectedCost(uint x) external onlyOwner  {
        expectedCost = x ;
    }

    function getExpectedCost() public view returns (uint256) {
        return expectedCost;
    }

    function setDeadline(uint256 numberOfDays) external onlyOwner  {
        deadline = block.timestamp + (numberOfDays * 100 seconds);
    }

    function getDeadline() public view returns (uint256) {
        return deadline;
    }


    function transferToArtist(address payable receiver) payable external onlyOwner onlyUnlock notDeadline{
        

        uint256 myBalance = owner.balance;   
        uint256 amount = msg.value;

        if (expectedCost <= payedCost+0.1 ether && amount == expectedCost){
            myBalance -= amount;
            receiver.transfer(amount);
            locked=true;
            
            emit Sent(msg.sender, receiver,amount);
            
        }else{
            revert();            
        }
    }

    function sendToMono(address payable mono) external  payable onlyOnce notDeadline{
        address sender=msg.sender;
        uint256 senderBalance = sender.balance;
        uint256 amount = msg.value;
        uint256 myBalance = owner.balance;
        Person memory  _person;  

        if (amount <= senderBalance && amount != 0){
            myBalance += amount;
            payedCost+= amount;
            mono.transfer(amount);

            _person.name = sender;
            _person.Payed = true;
            _person.isVip = false;
            _person.payedAmount = amount;
            registeredPerson[sender] =  _person;
            emit Sent(msg.sender, mono,amount);
       
        }
    }
    function addVip(address  _voterAddress) external onlyOwner notDeadline{
         Person memory  _person;
        _person.name = _voterAddress;
        _person.Payed = false;
        _person.isVip = true;
        _person.payedAmount=0;
        registeredPerson[_voterAddress] = _person;
        totalVipVoter++;
    }

    function sendToMonoPrivate(address payable mono) payable external  onlyVip notDeadline{ 
        address sender=msg.sender;
        uint256 senderBalance = sender.balance;
        uint256 amount = msg.value;
        uint256 myBalance = owner.balance;
        Person memory  _person;  

        if (amount <= senderBalance && amount != 0){
            myBalance += amount;
            payedCost+= amount;
            mono.transfer(amount);
           

            _person.name = sender;
            _person.Payed = true;
            _person.isVip = false;
            _person.payedAmount = amount;
            registeredPerson[sender] =  _person;
            emit Sent(msg.sender, mono,amount);
       
        }else{
            revert();            
        }
    }


}
