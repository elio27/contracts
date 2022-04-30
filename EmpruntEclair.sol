// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IEmprunteur {
    function doStuff(
        address _nftContract,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _params
        ) external;
}

contract EmpruntEclair {

    function unsafeIncrement(uint256 i) internal pure returns(uint256) {
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
        uint256 len = uint256(_ids.length);
        IERC721 _contract = IERC721(_nftContract);

        // Envoie les NFTs voulus au contrat executeur
        for (uint256 i; i<len; i=unsafeIncrement(i)) {
            _contract.transferFrom(address(this), _executor, _ids[i]);
        }

        // Execute le code du flashloan
        IEmprunteur(_executor).doStuff(_nftContract, _ids, _ids, _params);

        // Verifie que les NFTs sont bien revenus au contrat et les reprend si ce n'est pas le cas
        for (uint256 i; i<len; i=unsafeIncrement(i)) {
            if (_contract.ownerOf(_ids[i]) != address(this)) {
                _contract.safeTransferFrom(_executor, address(this), _ids[i]);
            }
        }

    }

    function _flashloan1155(address _nftContract, address _executor, uint[] calldata _ids, uint[] calldata _amounts, bytes calldata _params) internal {

        IERC1155 _contract = IERC1155(_nftContract);

        // Envoie les NFTs voulus au contrat executeur
        _contract.safeBatchTransferFrom(address(this), _executor, _ids, _amounts,"0x0");

        // Execute le code du flashloan
        IEmprunteur(_executor).doStuff(_nftContract, _ids, _amounts, _params);

        // Recupere les NFTs empruntés
        _contract.safeBatchTransferFrom(_executor, address(this), _ids, _amounts, "0x0");
    }

}
