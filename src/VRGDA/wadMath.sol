pragma solidity ^0.8.20;

/// @dev Takes an integer amount of seconds and converts it to a wad amount of hours.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toHoursWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 3600.
        r := div(mul(x, 1000000000000000000), 3600)
    }
}

/// @dev Takes a wad amount of hours and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative hour amounts, it assumes x is positive.
function fromHoursWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 3600 and then divide it by 1e18.
        r := div(mul(x, 3600), 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of minutes.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toMinutesWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 60.
        r := div(mul(x, 1000000000000000000), 60)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of minutes.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toTimeUnitWadUnsafe(uint256 x, int256 secondsPerTimeUnit) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 60.
        r := div(mul(x, 1000000000000000000), secondsPerTimeUnit)
    }
}

/// @dev Takes a wad amount of minutes and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative minute amounts, it assumes x is positive.
function fromMinutesWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 60 and then divide it by 1e18.
        r := div(mul(x, 60), 1000000000000000000)
    }
}
