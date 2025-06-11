// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";


abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {

    //记录每个地址的余额
    mapping(address account => uint256) private _balances;

    //记录每个地址的授权额度
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    // 全网流通的代币总量
    uint256 private _totalSupply;

    //代币名称和代币符号
    string private _name;
    string private _symbol;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * 代币信息
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }


    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    // decimals 默认为 18，模仿以太坊的 Wei 与 Ether 关系，子合约可重写以调整。    
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    // 总流通
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    // 余额
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    // 转账
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    // 转移授权额度
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    // 授权
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    // 委托转账
    // 如果授权额度等于 type(uint256).max，表示“无限授权”，则不消耗额度，以节省 gas。
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    // 基础转账检查
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    // 统一的余额与总量更新
    // 铸造：from == address(0) 分支，增加 _totalSupply 并走后面 to != 0 的接收逻辑。
    //燃烧：to == address(0) 分支，减少 _totalSupply。

    //其余均为标准的余额扣减与增加。
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    // 铸币与燃币快捷入口
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }


    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    // 授权管理
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }


    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }


    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            // 不触发 Approval 事件以节省gas
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}
