// // SPDX-License-Identifier: GPL-3.0
pragma solidity >0.7.0 <0.9.0;

// The tax value of premium  
uint constant TX_PREMIUM = 1000 wei;

 struct Collateral {
    address Address;   
    uint Value; // Assets/Ether of Collateral
    TypeCollateral Type;
    uint CreateDate; // Date of CreateDate
 }

 //@Acquisition => when the participant add the collateral
 //@Redemption => when the participant remove the collateral
 enum TypeCollateral {Acquisition, Redemption}

 //@Titular => has the rigth about the asset
 //@Laucher => has of duty to buy
 enum Participant { Launcher, Titular }

 enum TypeParticipant { Put, Call}
 
 //When init of transaction the status is Opened
 //When finish of transaction the status is Opened
 enum StatusOption { Opened, Finished }

 struct Option {
    uint Value;
    uint Premium;
    StatusOption Status;
    TypeParticipant Type;
    uint Strike;
    uint MaturityDate;
    uint AquisitionDate;
    address Titular;
    address payable Laucher;
 }

abstract contract AppBase 
{    
    address public Manager;

    //TODO this values made to be calculed in each operaction interaction 
    mapping(address => Collateral[]) public Collaterals;
    mapping(address => uint) public BalanceCollateral;
    mapping(address => Option[]) public Options;  

    //amount balance the contract has to garantee the finished transaction;
    uint private BalanceContract;
    
    //Events
    event Inited(address indexed _from, address indexed _to, uint256 _value);
    event Finished(address indexed _from, address indexed _to, uint256 _value);
    
    modifier HasCollateral 
    {
        uint amountMinForOperacao = TX_PREMIUM + msg.value;
        require(amountMinForOperacao < BalanceCollateral[msg.sender], 'Without collateral to open the operation');
        _;
    }

    modifier OnlyOwner (address _address) 
    {
        require(_address == msg.sender || _address == Manager);
        _;
    }

    event AddedPremium(uint value, address _from, address _to, uint date);

    function AddPremium(uint _value, address _from, address payable _to, uint _date) payable public {

        require(msg.value != 0.1 ether);

        uint value = msg.value;

         _to.transfer(value);

        emit AddedPremium(_value, _from, _to, _date);
    }

    function AddCollateral() payable public {
        
        Collateral memory collateral = Collateral({
            Address: msg.sender,
            Value: msg.value,
            Type: TypeCollateral.Acquisition,
            CreateDate: block.timestamp                
        });
        
        Collaterals[msg.sender].push(collateral);
        CalculateCollateral(Collaterals[msg.sender]);
    }

    function RetireCollateral() payable public {
        
        Collateral memory collateral = Collateral({
            Address: msg.sender,
            Value: msg.value,
            Type: TypeCollateral.Redemption,
            CreateDate: block.timestamp                
        });
        
        Collaterals[msg.sender].push(collateral);
        CalculateCollateral(Collaterals[msg.sender]);
    }

    function RetireCollateral(address _to, uint value) public {
        
        Collateral memory collateral = Collateral({
            Address: _to,
            Value: value,
            Type: TypeCollateral.Redemption,
            CreateDate: block.timestamp                
        });
        
        Collaterals[msg.sender].push(collateral);
        CalculateCollateral(Collaterals[msg.sender]);
    }

    function CalculateCollateral(Collateral[] storage collaterals) private {

        uint counter = collaterals.length;
        BalanceCollateral[msg.sender] = 0;

        for (uint i = 0; i < counter; i ++) {

            if (collaterals[i].Type == TypeCollateral.Acquisition)
            {
                BalanceCollateral[msg.sender] += collaterals[i].Value;
            }
            else if (collaterals[i].Type == TypeCollateral.Redemption) 
            {
                BalanceCollateral[msg.sender] -= collaterals[i].Value;
            }
            else 
            {
                revert();
            }
        }
    }
}

//CALL => the o titular has the option of buy the asset by price of contract (strike). 
contract OptionCall is AppBase {

    function StartOption(address payable _laucher, uint _value, uint _maturityDate, uint _strike) payable HasCollateral public 
    {   
        Option memory option = Option({
            Value: _value,
            Premium: TX_PREMIUM,
            Status: StatusOption.Opened,
            Type: TypeParticipant.Call,
            Strike: _strike,
            MaturityDate: _maturityDate,
            AquisitionDate: block.timestamp,
            Titular: msg.sender,
            Laucher: _laucher
        });

        Options[msg.sender].push(option);
    }

    function  FinishOption(address _titular) OnlyOwner(_titular) public 
    {
        Option[] memory optionsTitular = Options[_titular];
        uint counteri = optionsTitular.length;
        
        for(uint i = 0;  i < counteri; i++) {

            if (optionsTitular[i].Status == StatusOption.Opened)
            {   
                Collateral[] memory collateralsTitular = Collaterals[optionsTitular[i].Titular];
                
                uint counterj = collateralsTitular.length;

                uint valueToPay = 0; 

                for(uint j = 0; j < counterj; j++) {

                    valueToPay += collateralsTitular[j].Value;
                    
                    if (valueToPay >= optionsTitular[i].Strike)
                    {
                        break;
                    }

                    RetireCollateral(optionsTitular[i].Titular, valueToPay);
                }

                optionsTitular[i].Laucher.transfer(valueToPay);
                optionsTitular[i].Status = StatusOption.Finished;     
                //TODO Transfer other CryptoCurrency to Titular  
            }
        }
    }
}

contract PutCall is AppBase 
{
    function StartOption(address payable _laucher, uint _value, uint _maturityDate, uint _strike) payable HasCollateral public 
    {
        Option memory option = Option({
            Value: _value,
            Premium: TX_PREMIUM,
            Status: StatusOption.Opened,
            Type: TypeParticipant.Put,
            Strike: _strike,
            MaturityDate: _maturityDate,
            AquisitionDate: block.timestamp,
            Titular: msg.sender,
            Laucher: _laucher
        });

        Options[msg.sender].push(option);
    }

    function  FinishOption(address _titular) OnlyOwner(_titular) public 
    {
        Option[] memory optionsTitular = Options[_titular];
        uint counteri = optionsTitular.length;
        
        for(uint i = 0;  i < counteri; i++) {

            if (optionsTitular[i].Status == StatusOption.Opened)
            {   
                Collateral[] memory collateralsTitular = Collaterals[optionsTitular[i].Titular];
                
                uint counterj = collateralsTitular.length;

                uint valueToPay = 0; 

                for(uint j = 0; j < counterj; j++) {

                    valueToPay += collateralsTitular[j].Value;
                    
                    if (valueToPay >= optionsTitular[i].Strike)
                    {
                        break;
                    }

                    RetireCollateral(optionsTitular[i].Titular, valueToPay);
                }

                optionsTitular[i].Laucher.transfer(valueToPay);
                optionsTitular[i].Status = StatusOption.Finished;     
                //TODO Transfer other CryptoCurrency to Titular  
            }
        }
    }
}