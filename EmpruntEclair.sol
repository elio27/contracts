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

    mapping(address => mapping(uint256 => address)) public erc721Owners;
    mapping(address => mapping(uint256 => mapping(address => uint256))) public erc1155Owners;

    /*
        DEPOSER et RECUPERER des NFTs de type ERC721
    */
    function depositERC721(address _nftContract, uint256[] memory _ids) external {
        
        IERC721 _contract = IERC721(_nftContract);
        uint256 len = _ids.length;
        
        for (uint256 i; i<len; i=unsafeIncrement(i)) {
            uint256 id = _ids[i];
            _contract.transferFrom(msg.sender, address(this), id);
            erc721Owners[_nftContract][id] = msg.sender;
        }
    }

    function withdrawERC721(address _nftContract, uint256[] memory _ids) external {
        IERC721 _contract = IERC721(_nftContract);
        uint256 len = _ids.length;
        
        for (uint256 i; i<len; i=unsafeIncrement(i)) {
            uint256 id = _ids[i];
            _contract.transferFrom(address(this), msg.sender, id);
            erc721Owners[_nftContract][id] = address(0x0);
        }
    }


    /*
        DEPOSER et RECUPERER des NFTs de type ERC1155
    */
    function depositERC1155(address _nftContract, uint256[] memory _ids, uint[] memory _amounts) external {
        
        IERC1155 _contract = IERC1155(_nftContract);
        _contract.safeBatchTransferFrom(msg.sender, address(this), _ids, _amounts, "0x0");

        uint256 len = _ids.length;
        
        for (uint256 i; i<len; i=unsafeIncrement(i)) {
            erc1155Owners[_nftContract][_ids[i]][msg.sender] = _amounts[i];
        }
    }

    function withdrawERC1155(address _nftContract, uint256[] memory _ids, uint256[] memory _amounts) external {
        IERC1155 _contract = IERC1155(_nftContract);
        _contract.safeBatchTransferFrom(address(this), msg.sender, _ids, _amounts, "0x0");

        uint256 len = _ids.length;
        
        for (uint256 i; i<len; i=unsafeIncrement(i)) {
            erc1155Owners[_nftContract][_ids[i]][msg.sender] -= _amounts[i];
        }
    }



    function flashloan(address _nftContract, address _executor, uint256 _type, uint[] calldata _ids, uint[] calldata _amounts, bytes calldata _params) external {

        // Le fonctionnement est similaire mais le code est different en fonction du type de NFT voulu
        if (_type == 721) {
            _flashloan721(_nftContract, _executor, _ids, _params);
        }
        else {
            _flashloan1155(_nftContract, _executor,  _ids, _amounts, _params);
        }
    }

    function _flashloan721(address _nftContract, address _executor, uint[] calldata _ids, bytes calldata _params) internal {
        
        IERC721 _contract = IERC721(_nftContract);
        uint256 len = _ids.length;

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
