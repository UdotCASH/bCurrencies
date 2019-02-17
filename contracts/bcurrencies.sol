pragma solidity ^0.5.2;

import "./EIP20Factory.sol";
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function create(address recipient,uint _value) public returns (bool);
  function destroy(address recipient,uint _value) public returns (bool);
}

contract BCURRENCIES is EIP20Factory{

    address BNBAddress = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52;
    uint public ratioD = 10**18; //ratio denominator

    constructor() public {
        tokenRatios[BNBAddress] = ratioD;
        tokenList.push(BNBAddress);

    }
    mapping(address=>uint) public tokenRatios;
    address[] public tokenList;

    //allow users to create tokens
    //peg them to BNB up to a certain limit (allow trades)
    //BNBRatio is out of 10**contractDecimals. 10**contractDecimals means one BNB to one token.
    function createToken(uint _limit, uint8 decimals,string memory _name, string memory _symbol,uint BNBRatio) public{
        require(decimals<=18);
        require(_limit<=(
189,175,490.242498551714388965*10**decimals)); //make sure the limit is no greater than the total amount of BNB in existence
        address token = createEIP20(0, _name, decimals, _symbol,_limit);

        uint realTokenRatio = getRealTokenRatio(BNBRatio, decimals);
        tokenRatios[token] = realTokenRatio;
        tokenList.push(token);
    }



     function getRealTokenRatio(uint BNBRatio,uint decimals) public pure returns (uint){
        return ((BNBRatio*10**decimals)/10**contractDecimals);
    }

    function buyTokens(address token, uint amount) public{
        require(tokenRatios[token]!=0);

        ERC20(BNBAddress).transferFrom(msg.sender,address(this),amount);
        uint tokensToCredit = tokenRatios[token]*amount/ratioD;
        ERC20(token).create(msg.sender,tokensToCredit);
    }

    function redeemTokens(address token, uint amount) public{
        require(tokenRatios[token]!=0);

        ERC20(token).destroy(msg.sender,amount);

        uint BNBtoSend = ratioD*amount/tokenRatios[token];
        ERC20(BNBAddress).transfer(msg.sender,BNBtoSend);
    }

    function convertTokens(address _from, address _to, uint amount) public {
         require(tokenRatios[_from]!=0);

         if(_from == BNBAddress){
             buyTokens(_to,amount);
         }else if (_to == BNBAddress) {
             redeemTokens(_from,amount);
         } else {
             uint tokensToDebit = amount;
             uint tokensToCredit = tokenRatios[_to]*amount/tokenRatios[_from];

             ERC20(_from).destroy(msg.sender,tokensToDebit);
             ERC20(_to).create(msg.sender,tokensToCredit);
         }
     }

    function getTokenListLength() public view returns (uint) {
        return tokenList.length;
    }
}
