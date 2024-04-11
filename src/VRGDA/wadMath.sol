pragma solidity ^0.8.20;

/// @dev Takes an integer amount of seconds and converts it to a wad amount of time unit.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toTimeUnitWadUnsafe(uint256 x, int256 secondsPerTimeUnit) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 60.
        r := div(mul(x, 1000000000000000000), secondsPerTimeUnit)
    }
}
