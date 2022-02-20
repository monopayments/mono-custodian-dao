// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}
contract Mono is DSMath{

    address private owner;
    uint256 private expectedCost = 0.1 ether;
    uint256 public payedCost = 0 ether;
    uint256 public monosCost = 0 ether;
    uint256 public lendersWidthrawPay = 0 ether;

    uint256 public lendersProfit = 1 ether;
    bool public locked = true;
    uint256 public totalVipVoter = 0;

    uint256 private deadline;
    uint256 public installmentDeadline;

    uint256 public installmenMounth=10;

    //10 ayda 1 ether gonderilmeli

    uint256 public installmentAmount = 10 ether;
    uint256 public installmentAmountForOne = (installmentAmount/installmenMounth);

    //expected cost - payed cost = monos profit
    //monos cost - payed cost = lendersProfit

    enum DAOState{Created,Started ,Ended}

    DAOState public daoState;

    struct Person {
        address name;
        bool Payed;
        uint256 payedAmount;
        uint256 lenderReturnPayment;
        bool isVip;
    }

    mapping(address => Person) public registeredPerson;
    mapping(address => uint256) public registeredLenders;

    event Sent(address from, address to, uint256 amount);
    event NewProfit(uint256 from,  uint256 to);


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

     modifier onlyLenders() {
        require(registeredPerson[msg.sender].name != address(0),"Only lenders can use");
        _;
    }
     
    modifier notDeadline() {
        require(block.timestamp<=deadline,"Deadline bro");
        _;
    }

    modifier notInstallmentDeadline() {
        require(block.timestamp<=installmentDeadline,"Installment Deadline bro");
        _;
        installmentAmountForOne = installmentAmountForOne + 1 ether;
    }

    modifier State(DAOState _daoState){
        require(daoState == _daoState);
        _;
    }

    constructor(){
        owner =msg.sender;
        daoState = DAOState.Created;
    }

    function startPaying() external State(DAOState.Created) onlyOwner{
        daoState = DAOState.Started;
    }

    function endPaying() external State(DAOState.Started) onlyOwner{
        daoState = DAOState.Ended;
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

    function setlendersProfit(uint256 x) external onlyOwner  {
        uint256 oldProfit=lendersProfit;
        lendersProfit = x ;
        emit NewProfit(oldProfit,lendersProfit);
    }

    function getlendersProfit() public view returns (uint256) {
        return lendersProfit;
    }

    function setDeadline(uint256 numberOfDays) external onlyOwner  {
        deadline = block.timestamp + (numberOfDays * 100 seconds);
    }

    function getDeadline() public view returns (uint256) {
        return deadline;
    }

    function setInstallmentDeadline(uint256 numberOfDays) external onlyOwner  {
        installmentDeadline = block.timestamp + (numberOfDays * 100 seconds);
    }

    function getInstallmentDeadline() public view returns (uint256) {
        return installmentDeadline;
    }

    function transferToArtist(address payable receiver) payable external onlyOwner onlyUnlock notDeadline{
        uint256 myBalance = owner.balance;   
        uint256 amount = msg.value;

        if (expectedCost <= payedCost+0.1 ether && amount == expectedCost){
            myBalance -= amount;
            receiver.transfer(amount);
            locked=true;
            
            emit Sent(owner, receiver,amount);
            
        }else{
            revert();            
        }
    }

    function sendToMono() external  payable onlyOnce notDeadline{
        address sender=msg.sender;
        uint256 senderBalance = sender.balance;
        uint256 amount = msg.value;
        //uint256 myBalance = owner.balance;
        Person memory  _person;  

        if (amount <= senderBalance && amount != 0){
            //myBalance += amount;
            //payedCost+= amount;
            //mono.transfer(amount);
            sendValue(payable(owner),amount);
            payedCost +=amount;

            _person.name = sender;
            _person.Payed = true;
            _person.isVip = false;
            _person.payedAmount = amount;
            registeredPerson[sender] = _person;
            emit Sent(msg.sender, payable(owner),amount);
       
        }
    }

    function addVip(address  _voterAddress) external onlyOwner  notDeadline{
         Person memory  _person;
        _person.name = _voterAddress;
        _person.Payed = false;
        _person.isVip = true;
        _person.payedAmount=0;
        registeredPerson[_voterAddress] = _person;
        totalVipVoter++;
    }

    function sendToMonoPrivate() payable external  onlyVip notDeadline{ 
        address sender=msg.sender;
        uint256 senderBalance = sender.balance;
        uint256 amount = msg.value;
        //uint256 myBalance = owner.balance;
        Person memory  _person;  

        if (amount <= senderBalance && amount != 0){
            sendValue(payable(owner),amount);
           
            _person.name = sender;
            _person.Payed = true;
            _person.payedAmount = amount;
            registeredPerson[sender] =  _person;
            emit Sent(msg.sender, payable(owner),amount);
       
        }else{
            revert();            
        }
    }

    function showMyProfit()  external  view returns(uint256){
        uint256  myProfit = 0 ether;
        uint256  myAmount = 0 ether;
        uint256  myPay = 0 ether;

        require(registeredPerson[msg.sender].name != address(0),"Only lenders can use");

        myAmount = registeredPerson[msg.sender].payedAmount;
        
        myPay = wdiv(myAmount,payedCost);

        myProfit = wmul(myPay,lendersProfit);

        return myProfit;
    }

     function showMyTotalProfit() onlyLenders external  view returns(uint256){
        uint256  myTotalProfit = 0 ether;
        uint256  myProfit = 0 ether;
        uint256  myAmount = 0 ether;
        uint256  myPay = 0 ether;

        myAmount = registeredPerson[msg.sender].payedAmount;
       
        myPay = wdiv(myAmount,payedCost);

        myProfit = wmul(myPay,lendersProfit);

        myTotalProfit = add(myAmount,myProfit);

        return myTotalProfit;
    }

    function showResultAmount() onlyLenders external  view returns(uint256){
        uint256  myTotalProfit = 0 ether;
        uint256  myProfit = 0 ether;
        uint256  myAmount = 0 ether;
        uint256  myPay = 0 ether;
        uint256  result = 0 ether;

        myAmount = registeredPerson[msg.sender].payedAmount;

        myPay = wdiv(myAmount,payedCost);

        myProfit = wmul(myPay,lendersProfit);

        myTotalProfit = add(myAmount,myProfit);
        result = sub(myTotalProfit,lendersWidthrawPay);

        return result;
    }

    function shareTheProfitWithLenders(address payable receiver) payable external onlyOwner notDeadline{
        uint256 amount = msg.value;
        uint256 ownerBalance = owner.balance;

        require(registeredPerson[receiver].name != address(0),"no user in this registered address");
        require(owner != address(0), "Cannot transfer from the zero address");
        require(receiver != address(0), "Cannot transfer to the zero address");
        require(ownerBalance >= amount, "Transfer amount exceeds balance");

        uint256  myTotalProfit = 0 ether;
        uint256  myProfit = 0 ether;
        uint256  myAmount = 0 ether;
        uint256  myPay = 0 ether;
        
        myAmount = registeredPerson[receiver].payedAmount;
        myPay = wdiv(myAmount,payedCost);
        myProfit = wmul(myPay,lendersProfit);
        myTotalProfit = add(myAmount,myProfit);

        require(amount == myTotalProfit, "Please enter your prfit correctly");
        require(lendersWidthrawPay <= payedCost, "Users profit must be less than total amount.");

        sendValue(receiver,amount);
        lendersWidthrawPay += amount;
        emit Sent(owner,receiver,amount);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(recipient.balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function balance(address x) public view returns(uint accountBalance)
    {
        accountBalance = x.balance;
    }

    function installmentMono() payable external notInstallmentDeadline{
        uint256 amount = msg.value;
        require(amount == installmentAmountForOne, "Please enter your installment amount for one correctly");
     
        sendValue(payable(owner),amount);
        installmentAmount -=amount;
    }

}
