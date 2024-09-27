pragma solidity ^0.4.24;

// Safe Math Interface
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ERC Token Standard #20 Interface
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// Contract function to receive approval and execute function in one call
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// Actual token contract with additional features
contract DIOToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    
    address public owner;
    bool public paused;
    uint public transactionFeePercent;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) public blacklisted;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Transfers are paused");
        _;
    }

    modifier notBlacklisted(address account) {
        require(!blacklisted[account], "Address is blacklisted");
        _;
    }

    constructor() public {
        symbol = "DIO";
        name = "DIO Coin";
        decimals = 2;
        _totalSupply = 100000;
        owner = msg.sender;
        balances[owner] = _totalSupply;
        transactionFeePercent = 1; // 1% transaction fee
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public whenNotPaused notBlacklisted(msg.sender) returns (bool success) {
        uint fee = safeDiv(safeMul(tokens, transactionFeePercent), 100);
        uint tokensToTransfer = safeSub(tokens, fee);

        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokensToTransfer);
        balances[owner] = safeAdd(balances[owner], fee); // Collect the fee for the owner
        
        emit Transfer(msg.sender, to, tokensToTransfer);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public whenNotPaused notBlacklisted(from) returns (bool success) {
        uint fee = safeDiv(safeMul(tokens, transactionFeePercent), 100);
        uint tokensToTransfer = safeSub(tokens, fee);

        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokensToTransfer);
        balances[owner] = safeAdd(balances[owner], fee); // Collect the fee for the owner
        
        emit Transfer(from, to, tokensToTransfer);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function () public payable {
        revert();
    }

    // New functionality: Mint new tokens
    function mint(uint amount) public onlyOwner {
        balances[owner] = safeAdd(balances[owner], amount);
        _totalSupply = safeAdd(_totalSupply, amount);
        emit Transfer(address(0), owner, amount);
    }

    // New functionality: Burn tokens
    function burn(uint amount) public onlyOwner {
        require(balances[owner] >= amount, "Burn amount exceeds balance");
        balances[owner] = safeSub(balances[owner], amount);
        _totalSupply = safeSub(_totalSupply, amount);
        emit Transfer(owner, address(0), amount);
    }

    // New functionality: Pause transfers
    function pause() public onlyOwner {
        paused = true;
    }

    // New functionality: Unpause transfers
    function unpause() public onlyOwner {
        paused = false;
    }

    // New functionality: Blacklist address
    function blacklistAddress(address account) public onlyOwner {
        blacklisted[account] = true;
    }

    // New functionality: Remove from blacklist
    function unBlacklistAddress(address account) public onlyOwner {
        blacklisted[account] = false;
    }

    // New functionality: Set transaction fee percentage
    function setTransactionFeePercent(uint percent) public onlyOwner {
        transactionFeePercent = percent;
    }
}
