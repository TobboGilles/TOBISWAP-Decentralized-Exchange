// SPDX-License-Identifier: MIT 

pragma solidity ^0.7.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "./LPToken.sol";

contract Pair {
    using SafeMath for uint256;
    
    address public factory;
    address public tokenA;
    address public tokenB;
    
    uint256 private reserveTokenA;
    uint256 private reserveTokenB;
    
    LPToken lpToken;

    constructor(address _tokenA, address _tokenB){
        tokenA = _tokenA;
        tokenB = _tokenB;
        
        factory = msg.sender;
        lpToken = LPToken(0xd9145CCE52D386f254917e481eB44e9943F39138);
    }
    
    function getReserves() public view returns(uint256 reserveA, uint256 reserveB) {
        reserveA = reserveTokenA;
        reserveB = reserveTokenB;
    }
    
    function updateReserves() public onlyFactory {
        uint256 balanceOfTokenA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceOfTokenB = IERC20(tokenB).balanceOf(address(this));
        
        reserveTokenA = balanceOfTokenA;
        reserveTokenB = balanceOfTokenB;
    }
    
    modifier onlyFactory {
        require(msg.sender == factory, "Only factory can update reserves");
        _;
    }
    
    function swap(uint256 _amountTokenAOut, uint256 _amountTokenBOut, address _to) public {
        require(_amountTokenAOut > 0 || _amountTokenBOut > 0, "Insufficient output amount");
        
        require(_amountTokenAOut < reserveTokenA, "Insufficient reserve A");
        require(_amountTokenBOut < reserveTokenB, "Insufficient reserve B");
        
        if(_amountTokenAOut > 0){
            IERC20(tokenA).transfer(_to, _amountTokenAOut);
        }
        
        if(_amountTokenBOut > 0){
            IERC20(tokenB).transfer(_to, _amountTokenBOut);
        }
        
        uint256 balanceTokenA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceTokenB = IERC20(tokenB).balanceOf(address(this));
        
        require(balanceTokenA.mul(balanceTokenB) >= reserveTokenA.mul(reserveTokenB), "K Constant failed");
        
        reserveTokenA = balanceTokenA;
        reserveTokenB = balanceTokenB;
    } 
    
    function getProductConstant() public view returns (uint256) {
        return reserveTokenA.mul(reserveTokenB);
    }
    
    function burn(address _to, uint256 _liquidity) public {
        uint256 totalSupply = reserveTokenA.add(reserveTokenB);
        uint256 amountAToTransfer = _liquidity.mul(reserveTokenA).div(totalSupply);
        uint256 amountBToTransfer = _liquidity.mul(reserveTokenB).div(totalSupply);
        
        IERC20(tokenA).approve(address(this), amountAToTransfer);
        IERC20(tokenB).approve(address(this), amountBToTransfer);
        
        IERC20(tokenA).transferFrom(address(this), _to, amountAToTransfer);
        IERC20(tokenB).transferFrom(address(this), _to, amountBToTransfer);
        
        lpToken.burn(_to, _liquidity);
        
        updateReserves();
    }
    
    function mint(address _to, uint256 _amount) public {
        lpToken.mint(_to, _amount);
    }
}
