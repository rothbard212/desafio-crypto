// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address spender, address recipient, uint256 amount) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Paused(address account);
    event Unpaused(address account);
}

contract ProjectCoin is IERC20 {
    string public constant name = "Project Coin";
    string public constant symbol = "Project";
    uint8 public constant decimals = 18;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    uint256 private totalSupply_;
    
    address public owner;
    bool private paused;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Transfers are paused");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalSupply_ = 10 ether;
        balances[msg.sender] = totalSupply_;
    }

    // Implementação correta da função totalSupply()
    function totalSupply() public override view returns(uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns(uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override whenNotPaused returns(bool) {
        require(numTokens <= balances[msg.sender], "Balance not sufficient");
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns(uint256) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override whenNotPaused returns(bool) {
        require(numTokens <= balances[owner], "Owner balance not sufficient");
        require(numTokens <= allowed[owner][msg.sender], "Allowance exceeded");

        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    // Cunhagem de novos tokens (somente o proprietário)
    function mint(uint256 amount) public onlyOwner {
        totalSupply_ += amount;
        balances[owner] += amount;
        emit Mint(owner, amount);
        emit Transfer(address(0), owner, amount); // Transferência fictícia para sinalizar criação
    }

    // Queima de tokens (diminuir o total e a quantidade do emissor)
    function burn(uint256 amount) public {
        require(amount <= balances[msg.sender], "Burn amount exceeds balance");
        balances[msg.sender] -= amount;
        totalSupply_ -= amount;
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount); // Transferência fictícia para sinalizar destruição
    }

    // Pausar todas as transferências
    function pause() public onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    // Retomar as transferências
    function unpause() public onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }
}
