// // SPDX-License-Identifier: GPL-3.0
pragma solidity >0.7.0 <0.9.0;

// The tax value of premium  
uint constant TX_PREMIUM = 1000 wei;

struct Asset {
    uint Value; // Give the valor of collateral
    string Name; // Give the Name
    string Description; // Give the description
    string Initials; // Give the Initiais
 } 

 struct PremiumOption  {
    uint Value;
    address From;
    address To;
    uint Date;   
 }   

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

abstract contract OptionBase 
{
    Asset public AssetObject;
    PremiumOption public Premium;
    StatusOption public Status;
    TypeParticipant public Type;

    uint public Strike;
    uint public MaturityDate;
    uint public AquisitionDate;

    //TODO this values made to be calculed in each operaction interaction 
    mapping(address => Collateral[]) public Collaterals;
    mapping(address => uint) public BalanceCollateral;

    //amount balance the contract has to garantee the finished transaction;
    uint private BalanceContract;

    //Events
    event Inited(address indexed _from, address indexed _to, uint256 _value);
    event Finished(address indexed _from, address indexed _to, uint256 _value);
    
    function Execute()  public virtual;

    modifier HasCollateral 
    {
        uint amountMinForOperacao = TX_PREMIUM + msg.value;
        require(amountMinForOperacao < BalanceCollateral[msg.sender], 'Without collateral to open the operation');
        _;
    }

    modifier AlredyFinishedTransaction {
        require(Status == StatusOption.Finished, 'Transaction already not Finish');
        _;
    }
    
    event AddedPremium(uint value, address _from, address _to, uint date);

    function AddPremium(uint _value, address _from, address payable _to, uint _date) payable public {

        require(msg.value != 0.1 ether);

        PremiumOption memory premium = PremiumOption({
                Value: _value,
                From: _from,
                To: _to,
                Date: _date
        });

        Premium = premium;

         _to.transfer(msg.value);

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

    function StartOption() payable HasCollateral public {
        this.AddCollateral();
        this.Execute();
    }

    function FinishOption() public {
        this.RetireCollateral();
        this.Execute();
    }
}

contract OptionCall is OptionBase {

    function Execute() public override {

    }
}

contract PutCall is OptionBase 
{
    function Execute() override public {

    }
}
