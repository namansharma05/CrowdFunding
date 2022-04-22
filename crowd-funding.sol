//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Funding{
    //manager have all the rights
    address public manager;
    //mininum contribution a client can make
    uint public minContribution;
    //total number of contributors
    uint public noOfContributors;
    //end time of the project
    uint public deadline;
    //amount to be needed by the client to be raised
    uint public target;
    //amount currently raised
    uint public currBalance;

    //this code executes only once when contract is delployed
    constructor(uint _target,uint _deadline){
        manager = msg.sender;
        minContribution = 100 wei;
        deadline = block.timestamp+_deadline;
        target = _target;
    }

    //structure of the request(project) 
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }

    // all the requests(projects) mentioned here
    mapping(uint=>Request) public request;

    //key for all the requests
    uint public numRequest;

    //list of all the contributors with amount
    mapping(address=>uint) public fundraiser;

    //function to contribute ether
    function sendEth() public payable {
        require(block.timestamp < deadline,"you are late bro!");
        require(msg.value >= minContribution,"contribute atleast 100 wei");
        if(fundraiser[msg.sender] == 0){
            noOfContributors++;
        }
        fundraiser[msg.sender] += msg.value;
        currBalance+=msg.value;
    }

    //function to take refund
    function refund() public {
        require(block.timestamp>deadline && currBalance<target,"You can't refund right now!");
        require(fundraiser[msg.sender]>0,"You car not a fundraiser!");
        address payable user = payable(msg.sender);
        user.transfer(fundraiser[user]);
        currBalance-=fundraiser[user];
        fundraiser[user] = 0;
    }

    //used to add a constraint to some funtions that only manager can access
    modifier onlyManager(){
        require(msg.sender == manager,"Only manager have access!");
        _;
    }

    //creation of different request done using this
    function createRequest(string memory _description,address payable _recipient,uint _value) public onlyManager{
        Request storage newRequest = request[numRequest];
        numRequest++;
        newRequest.description = _description;
        newRequest.value = _value;
        newRequest.recipient = _recipient;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    //voting is done using this function
    function voteRequest(uint _requestNumber) public {
        require(fundraiser[msg.sender]>0,"You are not a fundraiser!");
        Request storage thisRequest = request[_requestNumber];
        require(thisRequest.voters[msg.sender] == false,"You have already voted!");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    //transfer raised amount to the request which won the voting
    function makePayment(uint _requestNumber) public onlyManager{
        require(currBalance>=target,"target does not fulfilled!");
        Request storage thisNewRequest = request[_requestNumber];
        require(thisNewRequest.completed == false,"Already completed raising funds!");
        require(thisNewRequest.noOfVoters > noOfContributors/2,"Majority does not support!");
        thisNewRequest.completed = true;
        thisNewRequest.recipient.transfer(thisNewRequest.value);
    }
}
