// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IRouter {

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

}

contract hedgeFork is ERC20{

    struct Token {
        address tokenAdress;
        uint256 amountPerToken;
    }

    function usafeIncrement(uint16 i) internal pure returns(uint16) {
        unchecked {
            return i+=1;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not allowed to do that.");
        _;
    }

    Token[] public backTokens;
    uint16  public devShare;
    address public owner;
    address public spookyRouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address public wETH = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    mapping(address => bool) public whitelisted;

    constructor(uint256 initialSupply) ERC20("Fund token", "FUND") {
        _mint(msg.sender, initialSupply);
        owner = msg.sender;
    }

    function buy(address _token, uint256 amount) external {
        uint256 len = backTokens.length;
        uint256 balance = IERC20(_token).balanceOf(msg.sender);
        for (uint16 i=0; i<len; i=usafeIncrement(i)) {
            Token memory token = backTokens[i];
            address[] memory _path = new address[](3);
            _path[0] = _token;
            _path[1] = wETH;
            _path[2] = token.tokenAdress;

            IRouter(spookyRouter).swapTokensForExactTokens(
                token.amountPerToken * amount / 10**18,
                balance,
                _path,
                msg.sender,
                block.timestamp + 1
            );
        }

        _mint(msg.sender, amount);
    }
    

    function redeem(address _toToken, uint256 amount) external {
        uint256 len = backTokens.length;
        uint256 iniBalance = IERC20(_toToken).balanceOf(address(this));

        for (uint16 i=0; i<len; i=usafeIncrement(i)) {
            Token memory token = backTokens[i];
            address[] memory _path = new address[](3);
            _path[0] = token.tokenAdress;
            _path[1] = wETH;
            _path[2] = _toToken;

            IRouter(spookyRouter).swapExactTokensForTokens(
                token.amountPerToken * amount / 10**18,
                0,
                _path,
                address(this),
                block.timestamp + 1
            );
        }

        uint256 diff = IERC20(_toToken).balanceOf(address(this)) - iniBalance;

        IERC20(_toToken).transfer(msg.sender, diff);
        _burn(msg.sender, amount);
    }

    function setBackingDistribution(Token[] calldata _backTokens) external {
        uint256 len1 = backTokens.length;
        uint256 len2 = _backTokens.length;
        backTokens;
        

        for (uint16 i=0; i<len1; i=usafeIncrement(i)) {
            /*
                sell tokens for xxx
            */
        }

        for (uint16 i=0; i<len2; i=usafeIncrement(i)) {
            Token memory token = _backTokens[i];
            backTokens.push(token);
        }
    }
    
}
