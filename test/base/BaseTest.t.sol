pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Test.sol";
import "../../lib/forge-std/src/console.sol";
import "../cheatCodes/CheatCodes.t.sol";

import {FantasyCards} from "../../src/FantasyCards.sol";
import {Exchange} from "../../src/Exchange.sol";
import {ExecutionDelegate} from "../../src/ExecutionDelegate.sol";
import {Minter} from "../../src/Minter.sol";
import {WrappedETH} from "../tokens/WrappedETH.sol";

abstract contract BaseTest is Test {
    CheatCodes constant cheats = CheatCodes(HEVM_ADDRESS);

    FantasyCards fantasyCards;
    Exchange exchange;
    ExecutionDelegate executionDelegate;
    Minter minter;
    WrappedETH weth;

    uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 treasuryPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    uint256 pauserAndCancelerPrivateKey = 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6;
    uint256 user1PrivateKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
    uint256 user2PrivateKey = 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;

    address deployer = vm.addr(deployerPrivateKey);
    address treasury = vm.addr(treasuryPrivateKey);
    address pauserAndCanceler = vm.addr(pauserAndCancelerPrivateKey);
    address user1 = vm.addr(user1PrivateKey);
    address user2 = vm.addr(user2PrivateKey);

    uint256 protocolFeeBps = 300;
    uint256 cardsRequiredForLevelUp = 5;

    function setUpExchange(
        address _treasury,
        uint256 _protocolFeeBps,
        address _executionDelegate,
        address _weth,
        address _fantasyCards
    ) internal {
        exchange = new Exchange(_treasury, _protocolFeeBps, address(_executionDelegate));
        exchange.whiteListCollection(_fantasyCards);
        exchange.whiteListPaymentToken(_weth);
    }

    function deployExecutionDelegate() internal {
        executionDelegate = new ExecutionDelegate();
    }

    function setUpExecutionDelegate(address _minter, address _exchange) internal {
        executionDelegate.approveContract(_minter);
        executionDelegate.approveContract(_exchange);
        executionDelegate.grantRole(executionDelegate.PAUSER_ROLE(), pauserAndCanceler);
    }

    function setUpMinter(address _treasury, address _executionDelegate) internal {
        minter = new Minter(_treasury, address(_executionDelegate), 5, 15, 1);
        minter.grantRole(minter.CANCELER_ROLE(), pauserAndCanceler);
    }

    function deployWETH() internal {
        weth = new WrappedETH();
    }

    function deployFantasyCards() internal {
        fantasyCards = new FantasyCards();
    }

    function setUpFantasyCards(address _executionDelegate) internal {
        fantasyCards.grantRole(fantasyCards.EXECUTION_DELEGATE_ROLE(), _executionDelegate);
    }

    function setUp() public virtual {
        deployFantasyCards();
        deployExecutionDelegate();
        deployWETH();
        setUpMinter(treasury, address(executionDelegate));
        setUpExchange(treasury, protocolFeeBps, address(executionDelegate), address(weth), address(fantasyCards));
        setUpExecutionDelegate(address(minter), address(exchange));
        // setUpExecutionDelegate(address(minterVRGDA), address(exchange));
        setUpFantasyCards(address(executionDelegate));
    }
}
