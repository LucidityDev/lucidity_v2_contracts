// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.7.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IConditionalTokens {
    // how do we flexibly set outcomes? 
    // getConditionId
    // prepareCondition
    // getCollectionId
    // getPositionId

    function splitPosition(
        address collateralToken,
        bytes32 parentCollectionId,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 amount
    ) external;

    function reportPayouts(bytes32 questionId, uint256[] calldata payouts)
        external;
}

//to fill in
interface ISablier {}

contract BidTracker {
    bool public ownerApproval = false;
    uint16 public basePrice; 
    string public projectName;
    address public owner;
    address public winningBidder;
    address[] public all_bidders;
    uint256[] public speedtargetOwner;
    uint256[] public targetbountyOwner;

    IERC1155 private IERC1155C;
    IConditionalTokens private ICT;
    ISablier private ISB;

    event currentTermsApproved(address approvedBidder);

    //these need to be private
    mapping(address => uint256[]) private BidderToTargets;
    mapping(address => uint256[]) private BidderToBounties;

    constructor(
        address _owner,
        address _ConditionalToken,
        address _Sablier,
        string memory _name,
        uint256[] memory _speedtargets,
        uint256[] memory _bounties
    ) public {
        owner = _owner;
        projectName = _name;
        speedtargetOwner = _speedtargets;
        targetbountyOwner = _bounties;
        ISB = ISablier(_Sablier);
        IERC1155C = IERC1155(_ConditionalToken);
        ICT = IConditionalTokens(_ConditionalToken);
    }

    //called by bidder submit
    function newBidderTerms(
        uint256[] calldata _speedtargets,
        uint256[] calldata _bounties
    ) external {
        require(
            ownerApproval == false,
            "another proposal has already been accepted"
        );
        require(msg.sender != owner, "owner cannot create a bid");
        
        BidderToTargets[msg.sender] = _speedtargets;
        BidderToBounties[msg.sender] = _bounties;
        all_bidders.push(msg.sender);
    }

    //called by owner approval submit
    function approveBidderTerms(
        address _bidder
        // address _CTaddress,
        // address _ERC20address,
        // address auditor
    ) external {
        require(msg.sender == owner, "Only project owner can approve terms");
        require(ownerApproval == false, "A bid has already been approved");
        ownerApproval = true;
        winningBidder = _bidder;

        //adjust owner terms to be same as bidder terms
        targetbountyOwner = BidderToBounties[msg.sender];
        speedtargetOwner = BidderToTargets[msg.sender];

        //kick off sablier stream 
        //kick off CT setting loop, though this is going to be like 4 * # milestones of approvals

        emit currentTermsApproved(_bidder);
    }

    //CT functions, loop through length of milestones//
    function setPositions(

    ) external {
    // getConditionId
    // prepareCondition
    // getCollectionId
    // getPositionId
    // return all the gets? 
    }
    
    function callSplitPosition(
        address tokenaddress,
        bytes32 parent,
        bytes32 conditionId,
        uint256[] calldata partition,
        uint256 value //bytes32 approvalPositionId,
    ) external {
        ICT.splitPosition(
            tokenaddress,
            parent,
            conditionId,
            partition,
            value
        );
        //totalValue = totalValue.sub(value); figure out how this is being called (i.e. how is money getting to this contract in the first place)
    }

    //transfer CT tokens to bidder wallet for a certain positionId. There should be a way to transfer CT to owner too.
    function transferCTtoBidder(uint256 positionId) external payable {
        require(
            msg.sender == winningBidder,
            "only bidder can redeem conditional tokens"
        );
        uint256 heldAmount = IERC1155C.balanceOf(address(this), positionId); //need to make it so only approve position id is transferrable

        IERC1155C.safeTransferFrom(
            address(this),
            msg.sender,
            positionId,
            heldAmount,
            ""
        );
    }

    //reportPayouts() should call fetchOracle()
    function callReportPayouts(bytes32 questionID, uint256[] calldata outcome)
        external
    {
        require(msg.sender == owner, "not owner"); //later this should only be called from governance contract with a vote
        ICT.reportPayouts(questionID, outcome);
    }

    function fetchOracleData(uint256 speedtarget) internal {
        //still need to do this
    }

    // //winning bidder can propose new bid terms 
    // function adjustBidTerms(uint256[] memory _speedtargets, uint256[] memory _bounties) public {
    //     require(ownerApproval == true, "a bid has not been approved yet");
    //     require(msg.sender == winningBidder, "only approved bidder can submit new terms");
    //     BidderToBounties[msg.sender] = _bounties;
    //     BidderToTargets[msg.sender] = _speedtargets;
    // }

    // //owner needs to approve new terms
    // function approveNewTerms() public {
    //     require(ownerApproval == true, "a bid has not been approved yet");
    //     require(msg.sender == owner, "only owner can approve new terms");
    //     targetbountyOwner = BidderToBounties[msg.sender];
    //     speedtargetOwner = BidderToTargets[msg.sender];
    //     //this has to somehow affect stream? start and cancel again here? 
    // }

    //////Below are all external view functions

    //loads owner terms for bidder to see
    function loadOwnerTerms()
        external
        view
        returns (
            uint256[] memory _speedtargets,
            uint256[] memory _bounties
        )
    {
        return (speedtargetOwner, targetbountyOwner);
    }

    //loads all bidders addresses in an array
    function getAllBidderAddresses() external view returns (address[] memory) {
        return (all_bidders);
    }

    //loads bidder terms for owner to see
    function loadBidderTerms(address _bidder)
        external
        view
        returns (uint256[] memory _speedtargets, uint256[] memory _bounties)
    {
        require(
            msg.sender == owner,
            "Only project owner can see proposed terms"
        );
        return (BidderToTargets[_bidder], BidderToBounties[_bidder]);
    }
}