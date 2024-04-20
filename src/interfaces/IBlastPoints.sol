pragma solidity ^0.8.20;

interface IBlastPoints {
    function configurePointsOperator(address operator) external;
    function configurePointsOperatorOnBehalf(address contractAddress, address operator) external;
}
