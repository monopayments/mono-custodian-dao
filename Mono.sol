// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


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
 

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract Mono is DSMath,ReentrancyGuard{

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    address public owner;
    address public admin;

    uint256 private expectedCost = 1 ether;
    uint256 public payedCost = 0 ether;
    uint256 public monosCost = 0 ether;
    uint256 public lendersWidthrawPay = 0 ether;

    uint256 public lendersProfit = 1 ether;
    bool public locked = true;
    
    uint256 public totalVipVoter = 0;

    uint256 public nftCase = 0;
    uint256 public userID = 1;


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

    struct Vote {
        address voterAddress;
        bool result;
        uint MarketItemId;
    }

    struct Voter {
        address voterAddress;
        bool isVoted;
        uint MarketItemId;
    }

    struct Person {
        address name;
        bool Payed;
        uint256 payedAmount;
        uint256 lenderReturnPayment;
        bool isVip;
        uint _itemId;
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        uint countResultTrue;
    }

    Person[] public usersArray;

    mapping(uint256 => MarketItem) public idToMarketItem;//make private

    mapping(address => Person) public registeredPerson;

    mapping(uint => Person) public registeredPersonNumber;

    mapping(uint => Person[]) public users;

    mapping(address => Voter) public registeredVoter;

    mapping(address => uint256) public registeredLenders;

    event Sent(address from, address to, uint256 amount);
    event NewProfit(uint256 from,  uint256 to);
    event MarketItemCreated (uint indexed itemId,address indexed nftContract,uint256 indexed tokenId,address seller,address owner,uint256 price,bool sold);


    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == admin,"Only owner or admin");
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin,"Only Admin");
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
        admin=msg.sender;
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


    function sendNFTtoMono(address nftContract,uint256 tokenId,uint256 expectedPrice) public payable nonReentrant {

        require(expectedPrice > 0, "Price must be at least 1 wei");
        require(msg.value == expectedPrice, "Price must be equal to listing price");
        owner =msg.sender;

        _itemIds.increment();
        uint256 itemId = _itemIds.current();
  
        idToMarketItem[itemId] =  MarketItem(itemId,nftContract,tokenId,
        payable(msg.sender),//sender
        payable(address(0)),//mono
        expectedPrice,
        false,
        0
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,//sender
            address(0),//mono
            expectedPrice,
            false
        );
    
    }

  /* Start the sale of a monos item */
  /* Transfers ownership */
  function transferNftToArtist(address nftContract,uint256 itemId) public payable nonReentrant notDeadline{
    uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");

    require(idToMarketItem[itemId].countResultTrue >= 2,"First consensius decide");

    idToMarketItem[itemId].seller.transfer(msg.value);
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    idToMarketItem[itemId].owner = payable(msg.sender);
    idToMarketItem[itemId].sold = true;
    _itemsSold.increment();
    payable(owner).transfer(expectedCost);
  }

  /* Returns all unsold mono items */
  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].owner == address(0)) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

    function sendToMono(uint _itemId) external  payable notDeadline returns(uint256) { 
        //simdilik kullanmiyorum
        //uint itemId = idToMarketItem[_itemId].itemId;

        uint256 senderBalance = msg.sender.balance;
        uint256 amount = msg.value;
        //uint256 myBalance = owner.balance;
        
        //DAO memory _DAO = registeredDAO[id];
        //_DAO.expectedCountTrue = newTrueAmount;
        //registeredDAO[id]=_DAO;
        Person memory _person = registeredPersonNumber[userID];
       
        if (amount <= senderBalance && amount != 0){

            _person.name = msg.sender;
            _person.Payed = true;
            _person.isVip = false;
            _person.payedAmount = amount;
            _person._itemId = _itemId;
            registeredPersonNumber[userID] = _person;
            userID++;
            emit Sent(msg.sender, payable(owner),amount);
        }
        return userID;
       
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

   function voteForAdmins(uint _itemId,bool _choise) public onlyAdmin notDeadline returns(bool result){
       bool voted = false;
        if(!registeredVoter[msg.sender].isVoted && registeredVoter[msg.sender].MarketItemId == _itemId ){
            registeredVoter[msg.sender].isVoted = true;
            
             Voter memory _voter = registeredVoter[msg.sender];
             registeredVoter[msg.sender]=_voter;

            if(_choise==true){
                idToMarketItem[_itemId].countResultTrue++;
            }
            voted=true;
        }
        return voted;
    }


    function addVoterForOneNFT(uint8 _itemId,address _newAdmin) public onlyAdmin notDeadline{
        Voter memory _voter;
        _voter.voterAddress = _newAdmin;
        _voter.isVoted = false;
        _voter.MarketItemId = _itemId;
        registeredVoter[_newAdmin] = _voter;
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

    function balance(address x) public view returns(uint accountBalance){
        accountBalance = x.balance;
    }

    function installmentMono() payable external notInstallmentDeadline{
        uint256 amount = msg.value;
        require(amount == installmentAmountForOne, "Please enter your installment amount for one correctly");
     
        sendValue(payable(owner),amount);
        installmentAmount -=amount;
    }


}
