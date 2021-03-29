/**
 * @title: Cream DAI wrapper
 * @summary: Used for interacting with Cream Finance. Has
 *           a common interface with all other protocol wrappers.
 *           This contract holds assets only during a tx, after tx it should be empty
 * @author: Idle Labs Inc., idle.finance
 */
pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/ILendingProtocol.sol";
import "hardhat/console.sol";

interface IBarnBridge {
    function buyTokens(uint256 underlyingAmount_, uint256 minTokens_, uint256 deadline_) external;
    function sellTokens(uint256 tokens_, uint256 minUnderlying_, uint256 deadline_) external;
    function maxBondDailyRate() external returns (uint256);
    function price() external returns (uint256);
    function EXP_SCALE() external view returns (uint);
    function abondDebt() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function pool() external view returns (uint256);
}

// interface IBondModel {
//     function gain(uint256 total_, uint256 loanable_, uint256 dailyRate_, uint256 principal_, uint16 forDays_) external pure returns (uint256);
//     function maxDailyRate(uint256 total_, uint256 loanable_, uint256 dailyRate_) external pure returns (uint256);
// }


// interface IERC165 {
//     function supportsInterface(bytes4 interfaceId) external view returns (bool);
// }

// interface IERC721 is IERC165 {
//     event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
//     event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
//     event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
//     function balanceOf(address owner) external view returns (uint256 balance);
//     function ownerOf(uint256 tokenId) external view returns (address owner);
//     function safeTransferFrom(address from, address to, uint256 tokenId) external;
//     function transferFrom(address from, address to, uint256 tokenId) external;
//     function approve(address to, uint256 tokenId) external;
//     function getApproved(uint256 tokenId) external view returns (address operator);
//     function setApprovalForAll(address operator, bool _approved) external;
//     function isApprovedForAll(address owner, address operator) external view returns (bool);
//     function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
// }

// interface IBond is IERC721 {
//     function smartYield() external view returns (address);
//     function mint(address to, uint256 tokenId) external;
//     function burn(uint256 tokenId) external;
// }

interface IController2 {
  function FEE_BUY_JUNIOR_TOKEN() external view returns (uint);
}

// interface IProvider {

//     function smartYield() external view returns (address);

//     function controller() external view returns (address);

//     function underlyingFees() external view returns (uint256);

//     // deposit underlyingAmount_ into provider, add takeFees_ to fees
//     function _depositProvider(uint256 underlyingAmount_, uint256 takeFees_) external;

//     // withdraw underlyingAmount_ from provider, add takeFees_ to fees
//     function _withdrawProvider(uint256 underlyingAmount_, uint256 takeFees_) external;

//     function _takeUnderlying(address from_, uint256 amount_) external;

//     function _sendUnderlying(address to_, uint256 amount_) external;

//     function transferFees() external;

//     // current total underlying balance as measured by the provider pool, without fees
//     function underlyingBalance() external returns (uint256);

//     function setController(address newController_) external;
// }

// interface ISmartYield {

//     // a senior BOND (metadata for NFT)
//     struct SeniorBond {
//         // amount seniors put in
//         uint256 principal;
//         // amount yielded at the end. total = principal + gain
//         uint256 gain;
//         // bond was issued at timestamp
//         uint256 issuedAt;
//         // bond matures at timestamp
//         uint256 maturesAt;
//         // was it liquidated yet
//         bool liquidated;
//     }

//     // a junior BOND (metadata for NFT)
//     struct JuniorBond {
//         // amount of tokens (jTokens) junior put in
//         uint256 tokens;
//         // bond matures at timestamp
//         uint256 maturesAt;
//     }

//     // a checkpoint for all JuniorBonds with same maturity date JuniorBond.maturesAt
//     struct JuniorBondsAt {
//         // sum of JuniorBond.tokens for JuniorBonds with the same JuniorBond.maturesAt
//         uint256 tokens;
//         // price at which JuniorBonds will be paid. Initially 0 -> unliquidated (price is in the future or not yet liquidated)
//         uint256 price;
//     }

//     function controller() external view returns (address);

//     function buyBond(uint256 principalAmount_, uint256 minGain_, uint256 deadline_, uint16 forDays_) external returns (uint256);

//     function redeemBond(uint256 bondId_) external;

//     function unaccountBonds(uint256[] memory bondIds_) external;

//     function buyTokens(uint256 underlyingAmount_, uint256 minTokens_, uint256 deadline_) external;

//     /**
//      * sell all tokens instantly
//      */
//     function sellTokens(uint256 tokens_, uint256 minUnderlying_, uint256 deadline_) external;

//     function buyJuniorBond(uint256 tokenAmount_, uint256 maxMaturesAt_, uint256 deadline_) external;

//     function redeemJuniorBond(uint256 jBondId_) external;

//     function liquidateJuniorBonds(uint256 upUntilTimestamp_) external;

//     /**
//      * token purchase price
//      */
//     function price() external returns (uint256);

//     function abondPaid() external view returns (uint256);

//     function abondDebt() external view returns (uint256);

//     function abondGain() external view returns (uint256);

//     /**
//      * @notice current total underlying balance, without accruing interest
//      */
//     function underlyingTotal() external returns (uint256);

//     /**
//      * @notice current underlying loanable, without accruing interest
//      */
//     function underlyingLoanable() external returns (uint256);

//     function underlyingJuniors() external returns (uint256);

//     function bondGain(uint256 principalAmount_, uint16 forDays_) external returns (uint256);

//     function maxBondDailyRate() external returns (uint256);

//     function setController(address newController_) external;
// }

// abstract contract Governed {

//   address public dao;
//   address public guardian;

//   modifier onlyDao {
//     require(
//         dao == msg.sender,
//         "GOV: not dao"
//       );
//     _;
//   }

//   modifier onlyDaoOrGuardian {
//     require(
//       msg.sender == dao || msg.sender == guardian,
//       "GOV: not dao/guardian"
//     );
//     _;
//   }

//   constructor()
//   {
//     dao = msg.sender;
//     guardian = msg.sender;
//   }

//   function setDao(address dao_)
//     external
//     onlyDao
//   {
//     dao = dao_;
//   }

//   function setGuardian(address guardian_)
//     external
//     onlyDao
//   {
//     guardian = guardian_;
//   }

// }

// abstract contract IController is Governed {

//     uint256 public constant EXP_SCALE = 1e18;

//     address public pool; // compound provider pool

//     address public smartYield; // smartYield

//     address public oracle; // IYieldOracle

//     address public bondModel; // IBondModel

//     address public feesOwner; // fees are sent here

//     // max accepted cost of harvest when converting COMP -> underlying,
//     // if harvest gets less than (COMP to underlying at spot price) - HARVEST_COST%, it will revert.
//     // if it gets more, the difference goes to the harvest caller
//     uint256 public HARVEST_COST = 40 * 1e15; // 4%

//     // fee for buying jTokens
//     uint256 public FEE_BUY_JUNIOR_TOKEN = 3 * 1e15; // 0.3%

//     // fee for redeeming a sBond
//     uint256 public FEE_REDEEM_SENIOR_BOND = 100 * 1e15; // 10%

//     // max rate per day for sBonds
//     uint256 public BOND_MAX_RATE_PER_DAY = 719065000000000; // APY 30% / year

//     // max duration of a purchased sBond
//     uint16 public BOND_LIFE_MAX = 90; // in days

//     bool public PAUSED_BUY_JUNIOR_TOKEN = false;

//     bool public PAUSED_BUY_SENIOR_BOND = false;

//     function setHarvestCost(uint256 newValue_)
//       public
//       onlyDao
//     {
//         require(
//           HARVEST_COST < EXP_SCALE,
//           "IController: HARVEST_COST too large"
//         );
//         HARVEST_COST = newValue_;
//     }

//     function setBondMaxRatePerDay(uint256 newVal_)
//       public
//       onlyDao
//     {
//       BOND_MAX_RATE_PER_DAY = newVal_;
//     }

//     function setBondLifeMax(uint16 newVal_)
//       public
//       onlyDao
//     {
//       BOND_LIFE_MAX = newVal_;
//     }

//     function setFeeBuyJuniorToken(uint256 newVal_)
//       public
//       onlyDao
//     {
//       FEE_BUY_JUNIOR_TOKEN = newVal_;
//     }

//     function setFeeRedeemSeniorBond(uint256 newVal_)
//       public
//       onlyDao
//     {
//       FEE_REDEEM_SENIOR_BOND = newVal_;
//     }

//     function setPaused(bool buyJToken_, bool buySBond_)
//       public
//       onlyDaoOrGuardian
//     {
//       PAUSED_BUY_JUNIOR_TOKEN = buyJToken_;
//       PAUSED_BUY_SENIOR_BOND = buySBond_;
//     }

//     function setOracle(address newVal_)
//       public
//       onlyDao
//     {
//       oracle = newVal_;
//     }

//     function setBondModel(address newVal_)
//       public
//       onlyDao
//     {
//       bondModel = newVal_;
//     }

//     function setFeesOwner(address newVal_)
//       public
//       onlyDao
//     {
//       feesOwner = newVal_;
//     }

//     function yieldControllTo(address newController_)
//       public
//       onlyDao
//     {
//       IProvider(pool).setController(newController_);
//       ISmartYield(smartYield).setController(newController_);
//     }

//     function providerRatePerDay() external virtual returns (uint256);
// }

interface ICompoundProvider {
  function uToken() external view returns (uint256);
}

contract IdleBarnBridge is ILendingProtocol, Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // protocol token (BarnBridge junior cUSDC) address
  address public token; //0x4B8d90D68F26DEF303Dcb6CFc9b63A1aAEC15840
  // underlying token (token eg USDC) address
  address public underlying;
  address public idleToken;
  bool public initialized;

  address public controller = 0x41Ab25709e0C3EDf027F6099963fE9AD3EBaB3A3;

  /**
   * @param _token : BarnBridge junior cUSDC address
   * @param _idleToken : idleToken address
   */
  function initialize(address _token, address _idleToken, address _usdcToken) public {
    require(!initialized, "Already initialized");
    require(_token != address(0), 'cUSDC: addr is 0');

    token = _token;
    console.log('_token: ', _token);
    underlying = address(ICompoundProvider(IBarnBridge(_token).pool()).uToken());
    // underlying = _usdcToken;
    idleToken = _idleToken;
    IERC20(underlying).safeApprove(_token, uint256(-1));
    initialized = true;
  }

  /**
   * Throws if called by any account other than IdleToken contract.
   */
  modifier onlyIdle() {
    require(msg.sender == idleToken, "Ownable: caller is not IdleToken");
    _;
  }
  
  function nextSupplyRateWithParams(uint256[] calldata)
    external view
    returns (uint256) {
    return 0;
  }

  /**
   * Calculate next supply rate for crDAI, given an `_amount` supplied
   *
   * @param _amount : new underlying amount supplied (eg DAI)
   * @return : yearly net rate
   */
  function nextSupplyRate(uint256 _amount)
    external view
    returns (uint256) {
      return 0;
      // uint256 apy = IBarnBridge(token).maxBondDailyRate();
      // return apy;
  }

  /**
   * @return current price of Cream DAI in underlying, crDAI price is always 1
   */
  function getPriceInToken()
    external view
    returns (uint256) {
      return 10**6;
  }

  /**
   * @return apr : current yearly net rate
   */
  function getAPR()
    external view
    returns (uint256) {
        return 0;
  }

  /**
   * Gets all underlying tokens in this contract and mints barnBridgeJuniorCusdc Tokens
   * tokens are then transferred to msg.sender
   * NOTE: underlying tokens needs to be sent here before calling this
   * NOTE2: given that barnBridgeJuniorCusdc price is always 1 token -> underlying.balanceOf(this) == token.balanceOf(this)
   *
   * @return barnBridgeJuniorCusdc Tokens minted
   */
  function mint()
    external 
    onlyIdle
    returns (uint256 barnBridgeJuniorCusdc) {
      uint256 balance = IERC20(underlying).balanceOf(address(this));
      if (balance == 0) {
        return barnBridgeJuniorCusdc;
      }
      uint256 minTokens_ = _mintMinUnderlying(balance);

      IERC20(underlying).safeApprove(0xDAA037F99d168b552c0c61B7Fb64cF7819D78310, 0);
      IERC20(underlying).safeApprove(0xDAA037F99d168b552c0c61B7Fb64cF7819D78310, uint256(-1));
      IBarnBridge(token).buyTokens(balance, minTokens_, block.timestamp.add(3600));
      barnBridgeJuniorCusdc = IERC20(token).balanceOf(address(this));
      IERC20(token).safeTransfer(msg.sender, barnBridgeJuniorCusdc);
  }

  function _mintMinUnderlying(uint256 underlyingAmount_) internal returns(uint256 getsTokens) {
    // uint256 fee = MathUtils.fractionOf(underlyingAmount_, IController(controller).FEE_BUY_JUNIOR_TOKEN());
    uint256 fee =  underlyingAmount_.mul(IController2(controller).FEE_BUY_JUNIOR_TOKEN()).div(IBarnBridge(token).EXP_SCALE());

    // (underlyingAmount_ - fee) * EXP_SCALE / price()
    getsTokens = (underlyingAmount_.sub(fee)).mul(IBarnBridge(token).EXP_SCALE()).div(IBarnBridge(token).price());
  }

  /**
   * Gets all barnBridgeJuniorCusdc in this contract and redeems underlying tokens.
   * underlying tokens are then transferred to `_account`
   * NOTE: barnBridgeJuniorCusdc needs to be sent here before calling this
   *
   * @return underlying tokens redeemd
   */
  function redeem(address _account)
    external 
    onlyIdle
    returns (uint256 tokens) {
    uint256 minUnderlying_ = _redeemMinUnderlying(IERC20(token).balanceOf(address(this)));
    IBarnBridge(token).sellTokens(IERC20(token).balanceOf(address(this)), minUnderlying_, block.timestamp.add(3600));
    IERC20 _underlying = IERC20(underlying);
    tokens = _underlying.balanceOf(address(this));
    _underlying.safeTransfer(_account, tokens);
  }

  function _redeemMinUnderlying(uint256 tokenAmount_) internal returns(uint256 toPay) {
      // share of these tokens in the debt
        // tokenAmount_ * EXP_SCALE / totalSupply()
        uint256 debtShare = tokenAmount_.mul(IBarnBridge(token).EXP_SCALE()).div(IBarnBridge(token).totalSupply());
        // (abondDebt() * debtShare) / EXP_SCALE
        uint256 forfeits = IBarnBridge(token).abondDebt().mul(debtShare).div(IBarnBridge(token).EXP_SCALE());
        // debt share is forfeit, and only diff is returned to user
        // (tokenAmount_ * price()) / EXP_SCALE - forfeits
        toPay = tokenAmount_.mul(IBarnBridge(token).price()).div(IBarnBridge(token).EXP_SCALE()).sub(forfeits);
  }

  /**
   * Get the underlying balance on the lending protocol
   *
   * @return underlying tokens available
   */
  function availableLiquidity() external view returns (uint256) {
    return IERC20(underlying).balanceOf(token);
  }

  // function apyCalculate() external view returns(uint256) {

  //   uint256 underlyingTotal = 


  //   return IBondModel(IController(controller).bondModel()).maxDailyRate(
  //       underlyingTotal(),
  //       underlyingLoanable(),
  //       IController(controller).providerRatePerDay()
  //     );
  // }
}
