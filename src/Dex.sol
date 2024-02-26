//SPDX-License-Identifier : MIT
pragma solidity ^0.8.20;
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Dex{

error useOnlyToken1orToken0();
error swapInFailed();
error swapOutFailed();
error failedtoaddtoken0liq();
error failedtoaddtoken1liq();
error liquiditypricechangeaffected();
error sharesisZero();
error enterValidAmount();
error token0liqremovalfailed();
error token1liqremovalfailed();


IERC20 public immutable token0;
IERC20 public immutable token1;
uint256 public constant FEE_PERCENTAGE = 999;//0.1% Fee
uint256 public constant FEE_PRECISION = 1000;
uint256 public reserve0; //total reserve of token0
uint256 public reserve1; //total reserve of token1
uint256 public totalSupply;
mapping(address => uint256) public balanceOf;

event swapComplete(address indexed tokenIn, uint256 indexed _amountIn, uint256 indexed amountOut);
event  liquidityAdded();
event liquidityRemoved();

//functions
constructor(address _token0, address _token1){
token0 = IERC20(_token0);
token1 = IERC20(_token1);
owner = payable(msg.sender);
}

//donations are welcome lol
fallback() external payable{
 owner.transfer(msg.value);
}

//swap
function swap(address _tokenIn, uint256 _amountIn) external nonReentrant returns (uint256 amountOut) {
    if(_tokenIn != address(token0) && _tokenIn != address(token1))
    {
        revert useOnlyToken1orToken0();
    }
    if(_amountIn < 0)       
    {
        revert enterValidAmount();
    } //gotta do more checks
    bool isToken0 = _tokenIn == address(token0);
    (IERC20 tokenIn, IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut) = isToken0 ? (token0, token1, reserve0, reserve1) : (token1, token0, reserve0, reserve0);
    
    bool success = tokenIn.transferFrom(msg.sender, address(this),_amountIn);
    if(!success)
    {
        revert swapInFailed();
    }
    //fee 0.3% of amountIn
    uint256 amountInWithFee = (_amountIn * FEE_PERCENTAGE)/FEE_PRECISION;
    //ydx/(x+dx) = dy
    amountOut = (reserveOut * amountInWithFee)/(reserveIn + amountInWithFee);
    bool succeed = tokenOut.transfer(msg.sender,amountOut);
    if(!succeed)
    {
        revert swapOutFailed();
    }
    _update(token0.balanceOf(address(this)),token1.balanceOf(address(this)));
    emit swapComplete(_tokenIn, _amountIn, amountOut);
    }


function addLiquidity(uint256 _amount0, uint256 _amount1) external nonReentrant returns (uint shares){
    (bool success) = token0.transferFrom(msg.sender, address(this), _amount0);
    {
        if(!success){
            revert failedtoaddtoken0liq();
        }
    }
    (bool succeed) = token1.transferFrom(msg.sender, address(this), _amount1);
    {
        if(!succeed)
        {
            revert failedtoaddtoken1liq();
        }
    }
    //dy/dx = y/x
    // dy(x) = y(dx)
    if(reserve0 > 0 || reserve1 > 0){
        if(reserve0 * _amount1 != reserve1 * _amount0)
            {
                revert liquiditypricechangeaffected();
            }
    }
    //mint shares
    //f(x,y) = value of liquidity = sqrt(xy)
    //s=dx/x * = dy/y * T
    if(totalSupply == 0){
        shares = _sqrt(_amount0 * _amount1);
    }
    else{
        shares = _min((_amount0 * totalSupply)/reserve0,(_amount1* totalSupply)/reserve1);
    }
    if(shares < 0)
    {
        revert sharesisZero();
    }
    _mint(msg.sender, shares);
    _update(token0.balanceOf(address(this)),token1.balanceOf(address(this)));
    emit liquidityAdded();

}
function removeLiquidity(uint _shares) external nonReentrant returns (uint256 amount0, uint256 amount1){
    //dy = s/T*y
    //calculate amount0 and amount1 to withdraw
    uint256 bal0 = token0.balanceOf(address(this));
    uint256 bal1 = token1.balanceOf(address(this));
    amount0 = (_shares * bal0) / totalSupply;
    amount1 = (_shares * bal1) /  totalSupply;
    //burn shares
    _burn(msg.sender, _shares);
    //update reserves
    _update(bal0 -amount0,bal1 - amount1);
    bool success = token0.transfer(msg.sender,amount0);
    if(!success)
    {
        revert token0liqremovalfailed();
    }
    
    bool succeed = token1.transfer(msg.sender,amount1);
    if(!succeed)
    {
        revert token1liqremovalfailed();
    }

   emit liquidityRemoved();
}
//helper functions
function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
function _min(uint256 x, uint256 y) private pure returns (uint256) {
    return x <= y ? x : y;
    }
//other private functions
function _mint(address _to, uint256 _amount) private {
     balanceOf[_to] += _amount;
     totalSupply += _amount;
    
}
function _burn(address _from, uint256 _amount) private {
    balanceOf[_from] = _amount;
    totalSupply -= _amount;
}
function _update(uint256 _reserve0, uint256 _reserve1) private {
    reserve0 = _reserve0;
    reserve1 = _reserve1;
}

}