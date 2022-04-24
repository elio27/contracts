// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract hedgeFork {

    struct Token {
        address tokenAdress;
        uint256 amountPerToken;
    }

    function usafeIncrement(uint16 i) internal view returns(uint16) {
        unchecked {
            return i+=1;
        }
    }


    Token[] public backTokens;
    uint16  public devShare;

    function buy(address _token, uint256 amount) external {
        /*
            buy tokens from _token to backing tokens
        */
        //_mint(msg.sender, amount);
    }
    

    function redeem(address _toToken, uint256 amount) external {
        /*
            sell backing tokens to _toToken
        */
        IERC20(_toToken).transfer(msg.sender, 9);
        //_burn(msg.sender, amount);
    }

    function setBackingDistribution(Token[] calldata _backTokens) external {
        uint256 len1 = backTokens.length;
        uint256 len2 = _backTokens.length;
        backTokens;
        

        for (uint i=0; i<len1; i++) {
            /*
                sell tokens for xxx
            */
        }

        for (uint i=0; i<len2; i++) {
            Token memory token = _backTokens[i];
            backTokens.push(token);
        }
    }
    
}
