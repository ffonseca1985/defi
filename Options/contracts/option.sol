pragma solidity 0.8.0;

contract OptionBase 
{
    struct Asset {
        uint Value;
        string Name;
        string Description;
        string Initials;
    }

    Asset public AssetObject;
    
    uint public Strike;
    uint public Premium;
    uint public MaturityDate;
    uint public AquisitionDate;

    enum Participant { Launcher, Titular }
    enum typeParticipant { Put, Call}
}

contract Option is OptionBase {

   function Validate() private{

   } 

   function AddCall() public {

   }

    function AddPut() private {

    }
}
