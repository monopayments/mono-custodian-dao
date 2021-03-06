// SPDX-License-Identifier: AGPL-3.0-only 
// MonoPayments Custodian DAO Contract
// Version: 0.0.1
// Author: @monopayments

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
     Counters.Counter public _itemIds;
     Counters.Counter public _itemsSold;
     uint256 public userID = 1;

    uint256 listingPrice = 0.025 ether;

    struct Admin {
        address AdminAddress;
    }

    struct WhiteListContract {
        address contractAddress;
        uint256 maxPayedAmount;
        bool isUsable;
    }

    struct Person {
        address name;
        bool Payed;
        uint256 payedAmount;
        uint256 lenderReturnPayment;
        bool isVip;
        uint item;
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        bool isArtistPayed;
        uint countResultTrue;
        uint256 nftDeadline;
        bool installmentPayedOption;
        uint256 lendersProfit;
        uint256 monosProfit;
        uint256 payedCost;
    }


    mapping(uint256 => MarketItem) public idToMarketItem;//make private
    mapping(uint => Person) public registeredPersonNumber;
    mapping(address => Admin) public registeredAdmin;

    mapping(address => WhiteListContract) public whiteListForNft;
    mapping(uint => Person) public whiteListForUser;

    event Sent(address from, address to, uint256 amount);
    event NewProfit(uint256 from,  uint256 to);
    event MarketItemCreated (uint indexed itemId,address indexed nftContract,uint256 indexed tokenId,address seller,address owner,uint256 price,bool sold);
       
    address payable owner;
    address payable public admin = payable(address(0x2Ee1CB29722ba8fB8F58F802e63c62c105F0b154));
    

    modifier onlyAdmin() {
        require(msg.sender == admin || registeredAdmin[msg.sender].AdminAddress != address(0) ,"Only Admin");
        _;
    }
    modifier notInstallmentDeadline(uint _itemId) {
        if(block.timestamp<=idToMarketItem[_itemId].nftDeadline){
            _;
        }else{
            MarketItem memory  _marketItem = idToMarketItem[_itemId];
            _marketItem.price = _marketItem.price + 0.1 ether;
            _marketItem.nftDeadline = block.timestamp+2592000 seconds;//added 30 days
            idToMarketItem[_itemId] = _marketItem;
        }
    
    }

    constructor(){
        owner=payable(msg.sender);
    }


    function showOwner()public view returns(address){
        return address(this);
    }
    
    function sendNFTtoMono(address nftContract,uint256 tokenId,uint256 expectedPrice,uint256 endDate,uint256 _lendersProfit) public payable nonReentrant {
        require(expectedPrice > 0, "Price must be at least 1 wei");
        require(endDate < 90, "Deadine should be less than 90 days ");
        //30 day 2628000 seconds 2592000
        //1 day 86400 seconds
        uint256 deadline = block.timestamp + (endDate * 86400 seconds);
        require(msg.value == listingPrice, "Price must be equal to listing price");


        
        _itemIds.increment();
        uint256 itemId = _itemIds.current();
     

        idToMarketItem[itemId] =  MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),//sender
            payable(address(this)),//mono
            expectedPrice,
            false,
            false,
            0,
            deadline,
            false,
             _lendersProfit,
            0,
            0

        );
       

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,//sender
            address(this),//mono
            expectedPrice,
            false
        );
    
    }

    function sendNFTtoMonoWithInstallment(address nftContract,uint256 tokenId,uint256 expectedPrice,uint256 endDate,uint256 _lendersProfit) public payable nonReentrant {
        require(expectedPrice > 0, "Price must be at least 1 wei");
        require(endDate == 30, "Deadine should be less than 30 days "); //change again
        //30 day 2628000 seconds 2592000
        //1 day 86400 seconds
        
        //uint256 deadline = block.timestamp + (endDate * 86400 seconds);
        uint256 deadline = block.timestamp + (endDate * 864 seconds);

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        require(msg.value == listingPrice, "Price must be equal to listing price");
     

        idToMarketItem[itemId] =  MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),//sender
            payable(address(this)),//mono
            expectedPrice,
            false,
            false,
            0,
            deadline,
            true,
             _lendersProfit,
            0,
            0

        );
       

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,//sender
            address(this),//mono
            expectedPrice,
            false
        );
    
    }

    /* Start the sale of a monos item */
    /* Transfers ownership */
    function transferNftToArtist(address nftContract,uint256 _itemId) public nonReentrant {
        require(idToMarketItem[_itemId].seller == msg.sender,"Only NFT Artist can add private person");
        require(idToMarketItem[_itemId].countResultTrue >= 2,"Make Consensus proof");
        uint tokenId = idToMarketItem[_itemId].tokenId;

        MarketItem memory  _marketItem = idToMarketItem[_itemId];
        
        
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        _marketItem.owner = payable(msg.sender);
        _marketItem.sold = true;
        idToMarketItem[_itemId] = _marketItem;
        _itemsSold.increment();
    }

    function transferNftToArtistWithInstallemnt(address nftContract,uint256 _itemId) public nonReentrant {
        require(idToMarketItem[_itemId].installmentPayedOption == true,"Installment option only");
        require(idToMarketItem[_itemId].seller == msg.sender,"Only NFT Artist can add private person");
        require(idToMarketItem[_itemId].price == 0,"Pay your installment amount");
        require(idToMarketItem[_itemId].countResultTrue >= 2,"Make Consensus proof");
        uint tokenId = idToMarketItem[_itemId].tokenId;
        
        MarketItem memory  _marketItem = idToMarketItem[_itemId];
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        _marketItem.owner = payable(msg.sender);
        _marketItem.sold = true;
        idToMarketItem[_itemId] = _marketItem;
        _itemsSold.increment();
    }

    function sendToMonoForNFT(uint _itemId) external payable{
        require(idToMarketItem[_itemId].itemId>0,"This nft not in our process");
        require(idToMarketItem[_itemId].sold == false,"This nft not in our process");
        require(idToMarketItem[_itemId].nftDeadline >= block.timestamp,"Deadline bro");
        require(msg.value != 0,"Amount can not be 0");

        MarketItem memory  _marketItem = idToMarketItem[_itemId];
        Person memory _person = registeredPersonNumber[userID];
        _person.name = msg.sender;
        _person.Payed = true;
        _person.isVip = false;
        _person.payedAmount += msg.value;
        _person.item=_itemId;
        _marketItem.payedCost+=msg.value;   
        registeredPersonNumber[userID] = _person;
        idToMarketItem[_itemId] = _marketItem;
        userID++;
        emit Sent(msg.sender, payable(owner),msg.value); 

    }

    // ****** Installment****
  
    function installmentMono(uint _itemId) payable external notInstallmentDeadline(_itemId){
        require(idToMarketItem[_itemId].itemId>0,"This nft not in our process.");
        require(idToMarketItem[_itemId].installmentPayedOption == true,"Installment option only");

        uint256 amount = msg.value;
        require(amount > 0, "Please enter your installment amount for one correctly");
        
        MarketItem memory  _marketItem = idToMarketItem[_itemId];
        //payable(owner).transfer(amount);
        _marketItem.price -= amount;
        _marketItem. nftDeadline = block.timestamp+2592000 seconds;//added 30 days
        //_marketItem. nftDeadline = block.timestamp+100 seconds;//added 30 days
        idToMarketItem[_itemId] = _marketItem;
    }

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

    function payBackForNFT(uint256 _itemId) payable public  {
        require(idToMarketItem[_itemId].itemId>0,"This nft not in our process");
        uint256 expectedPrice =idToMarketItem[_itemId].monosProfit;
        require(idToMarketItem[_itemId].seller == msg.sender,"You are not the owner");
        require(expectedPrice== msg.value,"not correct amount");
        require(block.timestamp <= idToMarketItem[_itemId].nftDeadline,"Deadline bro");

        MarketItem memory  _marketItem = idToMarketItem[_itemId];
        _marketItem.isArtistPayed = true;
        idToMarketItem[_itemId] = _marketItem;
    } 


    function setlendersProfit(uint256 x,uint _itemId) external {
        require(idToMarketItem[_itemId].seller == msg.sender,"Only NFT Artist can add private person");
        require(idToMarketItem[_itemId].itemId>0,"This nft not in our process.");
        require(idToMarketItem[_itemId].sold==false,"This nft sold out.");
        uint256 oldProfit = idToMarketItem[_itemId].lendersProfit;
        idToMarketItem[_itemId].lendersProfit = x ;
        emit NewProfit(oldProfit,idToMarketItem[_itemId].lendersProfit);
    }

    function setMonosProfit(uint256 _profit,uint _itemId) public onlyAdmin {
        require(idToMarketItem[_itemId].itemId>0,"This nft not in our process.");
        require(idToMarketItem[_itemId].sold==false,"This nft sold out.");
        idToMarketItem[_itemId].monosProfit = _profit ;
    }

    function getlendersProfit(uint _itemId) public view returns (uint256) {
        return idToMarketItem[_itemId].lendersProfit;
    }

    function getDeadline(uint _itemId) public view returns (uint256) {
        require(idToMarketItem[_itemId].itemId>0,"This nft not in our process.");
        require(idToMarketItem[_itemId].sold==false,"This nft sold out.");
        return idToMarketItem[_itemId].nftDeadline;
    }
    function getCurrentItem() public view returns (uint256) {
       
        return _itemIds.current();
    }

    /* Returns all unsold mono items */
   
    function fetchUserItems() public view returns (Person[] memory) {
        uint currentIndex = 0;

        Person[] memory users = new Person[](userID);
        for (uint i = 0; i < userID; i++) {
        if (registeredPersonNumber[i + 1].name == msg.sender) {
            uint currentId = i + 1;
            Person storage currentItem = registeredPersonNumber[currentId];
            users[currentIndex] = currentItem;
            currentIndex += 1;
        }
        }
        return users;
    }


    //****** THINK AGAIN FOR VIP's ****************************

    function addWhiteListUser(uint _itemId,address _name) external returns(uint256)  {
        
        require(idToMarketItem[_itemId].itemId > 0,"This NFT not in our process");
        require(idToMarketItem[_itemId].seller == msg.sender,"Only NFT Artist can add private person");

        Person memory _person = whiteListForUser[userID];
        //MarketItem memory  _marketItem = idToMarketItem[_itemId];
        _person.name = _name;
        _person.Payed = false;
        _person.isVip = true;
        _person.item= _itemId;
        whiteListForUser[userID] = _person;
        userID++;
        return userID;
        
    }


    function makeConsensius(uint _itemId,bool _choise) public onlyAdmin returns(bool result){
        bool voted = false;
        if(registeredAdmin[msg.sender].AdminAddress != address(0)){
            if(_choise==true){
                idToMarketItem[_itemId].countResultTrue++;
                voted=true;
            }
            else{
                idToMarketItem[_itemId].countResultTrue--;
            }
        
        }
        return voted;
    }
    

    function addAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0),"add address dam it!");
        Admin memory _admin = registeredAdmin[_newAdmin];
        _admin.AdminAddress =  _newAdmin;
        registeredAdmin[_newAdmin] = _admin;  
    }

    function addContractWhitelist(address _newContract,uint _maxPayedAmount,bool _isUsable) public onlyAdmin {
        WhiteListContract memory _contract = whiteListForNft[_newContract];
        _contract.contractAddress =  _newContract;
        _contract.maxPayedAmount=_maxPayedAmount;
        _contract.isUsable = _isUsable;
        whiteListForNft[_newContract] = _contract;
    }

    function showMyTotalProfit(uint _itemId)  public  view returns(uint256){
            require(idToMarketItem[_itemId].itemId>0,"This nft not in our process.");
            uint currentIndex = 0;

            uint256  myTotalProfit = 0 ether;
            uint256  myProfit = 0 ether;
            uint256  myAmount = 0 ether;
            uint256  myPay = 0 ether;

            //Person[] memory users = new Person[](userID);
            for (uint i = 0; i < userID; i++) {
                if (registeredPersonNumber[i + 1].name == msg.sender && registeredPersonNumber[i + 1].item == _itemId) {
                    uint currentId = i + 1;
                    uint256 currentItem = registeredPersonNumber[currentId].payedAmount;
                    myAmount+= currentItem;
                    currentIndex += 1;
                }
            }
            myPay = wdiv(myAmount,idToMarketItem[_itemId].payedCost);
            myProfit = wmul(myPay,idToMarketItem[_itemId].lendersProfit);
            myTotalProfit = add(myAmount,myProfit);

            return myTotalProfit;
    }

   
    
    function openToBuy(address _nftContract,uint256 _tokenId,uint _itemId) payable external{
        require(idToMarketItem[_itemId].sold == false, "This item is soled");
        require(idToMarketItem[_itemId].isArtistPayed == false, "User payed back!");
        require(idToMarketItem[_itemId].itemId>0,"This nft not in our process");
        uint256 expectedPriceForMono =idToMarketItem[_itemId].monosProfit;
        uint256 expectedPriceForSeller =idToMarketItem[_itemId].price;
        require(expectedPriceForMono + expectedPriceForSeller == msg.value,"not correct amount");

        MarketItem memory  _marketItem = idToMarketItem[_itemId];
        _marketItem.owner = payable(address(msg.sender));
        _marketItem.sold = true;
        idToMarketItem[_itemId] = _marketItem;
        payable(idToMarketItem[_itemId].seller).transfer(expectedPriceForSeller);

        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);

        

    }

    function withdraw() public nonReentrant {
        require(msg.sender == admin,"only admin");
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    function transferNFTtoAdmin(address _nftContract,uint256 _tokenId,uint256 _itemId) public {
        require(msg.sender == admin,"only admin");
        idToMarketItem[_itemId].owner = admin;
        IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenId);
    }

    function shareWithLenders(uint256 _itemId) public payable{
        require(idToMarketItem[_itemId].itemId > 0,"This nft not in our process."); 
        require(idToMarketItem[_itemId].sold == true,"This nft not sold"); 
        uint currentIndex = 0;

        uint256  myTotalProfit = 0 ether;
        uint256  myProfit = 0 ether;
        uint256  myAmount = 0 ether;
        uint256  myPay = 0 ether;

        //Person[] memory users = new Person[](userID);
        for (uint i = 0; i < userID; i++) {
            if (registeredPersonNumber[i + 1].name == msg.sender && registeredPersonNumber[i + 1].item == _itemId) {
                uint currentId = i + 1;
                uint256 currentItem = registeredPersonNumber[currentId].payedAmount;
                myAmount+= currentItem;
                currentIndex += 1;
            }
        }
        myPay = wdiv(myAmount,idToMarketItem[_itemId].payedCost);

        myProfit = wmul(myPay,idToMarketItem[_itemId].lendersProfit);
        myTotalProfit = add(myAmount,myProfit);
        payable(msg.sender).transfer(myTotalProfit);
    }
    function sendEtherToContract() payable public {
        // nothing else to do!
    }
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

}
