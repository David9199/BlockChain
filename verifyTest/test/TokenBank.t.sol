// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {TokenBank} from "../src/TokenBank.sol";
import {MessageHashUtils} from "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

contract TokenBankTest is Test {
    error ERC2612InvalidSigner(address signer, address owner);
    error ERC2612ExpiredSignature(uint256 deadline);

    bytes32 private _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    MyToken public MT;

    TokenBank public bank;

    function setUp() public {
        MT = new MyToken();
        bank = new TokenBank();
    }

    function test_PermitDeposit() external {
        uint privateKey = 1;
        address owner = vm.addr(privateKey);
        address spender = address(bank);
        assertEq(MT.allowance(owner, spender), 0);
        assertEq(MT.nonces(owner), 0);

        uint256 amount = 10000;

        MT.mint(owner, amount);

        (uint8 v, bytes32 r, bytes32 s) = _getTypedDataSignature(
            privateKey,
            owner,
            spender,
            amount,
            MT.nonces(owner),
            1 hours
        );

        // case 1: owner is changed
        address owner2 = vm.addr(2);
        vm.startPrank(owner2);
        bytes memory errorInfo= abi.encodeWithSelector(ERC2612InvalidSigner.selector, 0x6C585aE31F202cda0b12342C76426cD53C5E161d, owner2);
        vm.expectRevert(errorInfo);
        bank.permitDeposit(address(MT), amount, 1 hours, v, r, s);
        vm.stopPrank();

        // case 2: value is changed
        vm.startPrank(owner);
        errorInfo= abi.encodeWithSelector(ERC2612InvalidSigner.selector, 0xC4d06Bf099E0e4687e22719315874C1b35eAf62b, owner);
        vm.expectRevert(errorInfo);
        bank.permitDeposit(address(MT), amount - 100, 1 hours, v, r, s);

        // case 3: nonce is changed
        (v, r, s) = _getTypedDataSignature(
            privateKey,
            owner,
            spender,
            amount,
            MT.nonces(owner) + 1,
            1 hours
        );

        errorInfo= abi.encodeWithSelector(ERC2612InvalidSigner.selector, 0xA4EFe2b8A5D77777E16234125De85e76Bb42D887, owner);
        vm.expectRevert(errorInfo);
        bank.permitDeposit(address(MT), amount, 1 hours, v, r, s);

        // case 4: not signed by the owner
        (v, r, s) = _getTypedDataSignature(
            privateKey + 1,
            owner,
            spender,
            amount,
            MT.nonces(owner),
            block.timestamp
        );

        errorInfo= abi.encodeWithSelector(ERC2612InvalidSigner.selector, 0x1c0B701a3bBD990dD258b74f0ec28941f1E07ED6, owner);
        vm.expectRevert(errorInfo);
        bank.permitDeposit(address(MT), amount, 1 hours, v, r, s);

        (v, r, s) = _getTypedDataSignature(
            privateKey,
            owner,
            spender,
            amount,
            MT.nonces(owner),
            1 hours
        );

        bank.permitDeposit(address(MT), amount, 1 hours, v, r, s);
        assertEq(bank.userDeposit(owner, address(MT)), amount);
    }

    function _getTypedDataSignature(
        uint signerPrivateKey,
        address owner,
        address spender,
        uint value,
        uint nonce,
        uint deadline
    ) private view returns (uint8, bytes32, bytes32){
        bytes32 structHash = keccak256(abi.encode(
            _PERMIT_TYPEHASH,
            owner,
            spender,
            value,
            nonce,
            deadline
        ));

        bytes32 digest = MessageHashUtils.toTypedDataHash(MT.DOMAIN_SEPARATOR(), structHash);
        return vm.sign(signerPrivateKey, digest);
    }
}
