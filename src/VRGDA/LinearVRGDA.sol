// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {unsafeWadDiv} from "solmate/utils/SignedWadMath.sol";

import {VRGDA} from "./VRGDA.sol";

/// @title  Modifed Linear Variable Rate Gradual Dutch Auction
/// @author transmissions11 <t11s@paradigm.xyz>
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @author Fantasy Labs <contact@fantasy.top>
/// @notice Modified code for the Fantasy Minter. VRGDA with a linear issuance curve.
abstract contract LinearVRGDA is VRGDA {
    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @param perTimeUnit The targeted number of sells in 1 full unit of time, scaled by 1e18, e.g 1e18 for 1 sell
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold, int256 perTimeUnit) public view virtual override returns (int256) {
        return unsafeWadDiv(sold, perTimeUnit);
    }
}
