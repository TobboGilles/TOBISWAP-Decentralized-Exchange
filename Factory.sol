// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./Pair.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract Factory {
    using SafeMath for uint256;

    // {  tokenA Address => {  tokenB Address => address Pair  } }
    mapping(address => mapping(address => address)) public getPair;

    address[] public allPairs;

    uint256 public numberOfPairs;

    function createPair(address _tokenA, address _tokenB)
        internal
        returns (address pair)
    {
        require(_tokenA != _tokenB, "token addresses are equal");

        pair = address(new Pair(_tokenA, _tokenB));

        getPair[_tokenA][_tokenB] = pair;

        numberOfPairs++;

        allPairs.push(pair);
    }

    function quote(
        uint256 _amountA,
        uint256 _reserveA,
        uint256 _reserveB
    ) internal returns (uint256 amountB) {
        require(_amountA > 0, "Insufficient amount");
        require(_reserveA > 0, "Insufficient liquidity");

        amountB = _amountA.mul(_reserveB).div(_reserveA);
    }

    function getReserves(address _tokenA, address _tokenB)
        internal
        returns (uint256 reserveA, uint256 reserveB)
    {
        address pair = getPair[_tokenA][_tokenB];

        (reserveA, reserveB) = Pair(pair).getReserves();
    }

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountOfADesired,
        uint256 _amountOfBDesired
    ) public returns (uint256 amountA, uint256 amountB) {
        if (getPair[_tokenA][_tokenB] == address(0)) {
            createPair(_tokenA, _tokenB);

            (amountA, amountB) = (_amountOfADesired, _amountOfBDesired);
        } else {
            (uint256 reserveA, uint256 reserveB) =
                getReserves(_tokenA, _tokenB);

            if (reserveA == 0 && reserveB == 0) {
                (amountA, amountB) = (_amountOfADesired, _amountOfBDesired);
            } else {
                uint256 amountOfBOptimal =
                    quote(_amountOfADesired, reserveA, reserveB);

                if (amountOfBOptimal <= _amountOfBDesired) {
                    (amountA, amountB) = (_amountOfADesired, amountOfBOptimal);
                } else {
                    uint256 amountOfAOptimal =
                        quote(_amountOfBDesired, reserveB, reserveA);
                    (amountA, amountB) = (amountOfAOptimal, _amountOfBDesired);
                }
            }
        }

        address pair = getPair[_tokenA][_tokenB];
        IERC20(_tokenA).transferFrom(msg.sender, pair, amountA);
        IERC20(_tokenB).transferFrom(msg.sender, pair, amountB);

        Pair(pair).updateReserves();

        Pair(pair).mint(msg.sender, amountA.add(amountB));
    }

    function tradeBforA(
        uint256 _amountOfTokenA,
        uint256 _minTokensBToGet,
        address _tokenA,
        address _tokenB
    ) public {
        (uint256 reserveA, uint256 reserveB) = getReserves(_tokenA, _tokenB);

        uint256 numerator = _amountOfTokenA.mul(reserveB);

        uint256 denominator = reserveA.add(_amountOfTokenA);

        uint256 amountOut = numerator.div(denominator);

        require(amountOut >= _minTokensBToGet, "Not enough output as desired");

        address pair = getPair[_tokenA][_tokenB];

        IERC20(_tokenA).transferFrom(msg.sender, pair, _amountOfTokenA);

        Pair(pair).swap(uint256(0), amountOut, msg.sender);
    }

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity
    ) public {
        address pair = getPair[_tokenA][_tokenB];
        Pair(pair).burn(msg.sender, _liquidity);
    }
}
