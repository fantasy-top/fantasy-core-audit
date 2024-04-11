pragma solidity ^0.8.20;

import "../base/BaseTest.t.sol";
import "../../src/interfaces/IMinter.sol";
import {toTimeUnitWadUnsafe} from "../../src/VRGDA/wadMath.sol";
import "../../lib/forge-std/src/console.sol";

contract VRGDA is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testTargetPrice() public {
        int256 targetPrice = 1 ether;
        int256 priceDecayPercent = 3e17;
        int256 perTimeUnit = 1e18;
        int256 secondsPerTimeUnit = 60; // 1 minute
        uint256 timeSinceStart = uint256(secondsPerTimeUnit) * 1;
        int256 wadTimeSinceStart = toTimeUnitWadUnsafe(timeSinceStart, secondsPerTimeUnit);
        uint256 sold = 0;
        uint256 price = minter.getVRGDAPrice(wadTimeSinceStart, sold, targetPrice, priceDecayPercent, perTimeUnit);
        assertEq(price, uint256(targetPrice));
    }

    function testTargetPriceDecays() public {
        int256 targetPrice = 1 ether;
        int256 priceDecayPercent = 3e17;
        int256 perTimeUnit = 1e18;
        int256 secondsPerTimeUnit = 60; // 1 minute
        uint256 timeSinceStart = uint256(secondsPerTimeUnit) * 2; // 2 minutes
        int256 wadTimeSinceStart = toTimeUnitWadUnsafe(timeSinceStart, secondsPerTimeUnit);
        uint256 sold = 0;
        uint256 price = minter.getVRGDAPrice(wadTimeSinceStart, sold, targetPrice, priceDecayPercent, perTimeUnit);
        uint256 decayedPrice = (uint256(targetPrice) * uint256((1e18 - uint256(priceDecayPercent)))) / 1e18;
        assertApproxEqAbs(price, decayedPrice, 1);
    }

    function testTargetPriceStaysOnTarget() public {
        int256 targetPrice = 1 ether;
        int256 priceDecayPercent = 3e17;
        int256 perTimeUnit = 1e18;
        int256 secondsPerTimeUnit = 60; // 1 minute
        uint256 timeSinceStart = uint256(secondsPerTimeUnit) * 10080; // 1 week (in minutes)
        int256 wadTimeSinceStart = toTimeUnitWadUnsafe(timeSinceStart, secondsPerTimeUnit);
        uint256 sold = 10079;
        uint256 price = minter.getVRGDAPrice(wadTimeSinceStart, sold, targetPrice, priceDecayPercent, perTimeUnit);
        assertEq(price, uint256(targetPrice));
    }

    function testTargetPriceDecaysToZeroAfterALongTime() public {
        int256 targetPrice = 1 ether;
        int256 priceDecayPercent = 3e17;
        int256 perTimeUnit = 1e18;
        int256 secondsPerTimeUnit = 60; // 1 minute
        uint256 timeSinceStart = uint256(secondsPerTimeUnit) * 10080; // 1 week (in minutes)
        int256 wadTimeSinceStart = toTimeUnitWadUnsafe(timeSinceStart, secondsPerTimeUnit);
        uint256 sold = 0;
        uint256 price = minter.getVRGDAPrice(wadTimeSinceStart, sold, targetPrice, priceDecayPercent, perTimeUnit);
        assertEq(price, 0);
    }
}
