// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadExp, wadLn, wadMul, unsafeWadMul, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";

/// @title  Modified Variable Rate Gradual Dutch Auction
/// @author transmissions11 <t11s@paradigm.xyz>
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @author Fantasy Labs <contact@fantasy.top>
/// @notice Modified code for the Fantasy Minter. Sell tokens roughly according to an issuance schedule.
abstract contract VRGDA {
    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
    /// @param sold The total number of sells that have been performed so far.
    /// @param targetPrice The target price for a sell if done on pace, scaled by 1e18, e.g 1e18 for one eth
    /// @param priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18, e.g 3e17 for 30%
    /// @param perTimeUnit The targeted number of sells to perform in 1 full unit of time, scaled by 1e18, e.g 1e18 for 1 pack
    /// @return The price of a token according to VRGDA, scaled by 1e18.
    function getVRGDAPrice(
        int256 timeSinceStart,
        uint256 sold,
        int256 targetPrice,
        int256 priceDecayPercent,
        int256 perTimeUnit
    ) public view virtual returns (uint256) {
        require(targetPrice > 0, "Non zero target price");
        int256 decayConstant = wadLn(1e18 - priceDecayPercent);
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
        unchecked {
            // prettier-ignore
            return uint256(wadMul(targetPrice, wadExp(unsafeWadMul(decayConstant,
                // Theoretically calling toWadUnsafe with sold can silently overflow but under
                // any reasonable circumstance it will never be large enough. We use sold + 1 as
                // the VRGDA formula's n param represents the nth token and sold is the n-1th token.
                timeSinceStart - getTargetSaleTime(toWadUnsafe(sold + 1), perTimeUnit)
            ))));
        }
    }

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @param perTimeUnit The total number of tokens to target selling every full unit of time.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold, int256 perTimeUnit) public view virtual returns (int256);
}
