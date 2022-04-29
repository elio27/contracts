// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IEmprunteur {
    function doStuff(
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata params
        ) external;
}

contract EmpruntEclair {

    function unsafeIncrement(uint8 i) internal pure returns(uint8) {
        unchecked {
            return i+1;
        }
    }

    function flashloan(address _nftContract, address _executor, uint _type, uint[] calldata _ids, uint[] calldata _amounts, bytes calldata _params) external {

        if (_type == 721) {
            _flashloan721(_nftContract, _executor, _ids, _params);
        }
        else {
            _flashloan1155(_nftContract, _executor,  _ids, _amounts, _params);
        }
    }

    function _flashloan721(address _nftContract, address _executor, uint[] calldata _ids, bytes calldata _params) internal {
        uint8 len = uint8(_ids.length);
        for (uint8 i; i<len; i=unsafeIncrement(i)) {
            IERC721(_nftContract).transferFrom(address(this), _executor, _ids[i]);
        }
    }

    function _flashloan1155(address _nftContract, address _executor, uint[] calldata _ids, uint[] calldata _amounts, bytes calldata _params) internal {
        IERC1155(_nftContract).safeBatchTransferFrom(address(this), _executor, _ids, _amounts,"0x0");
    }

}
