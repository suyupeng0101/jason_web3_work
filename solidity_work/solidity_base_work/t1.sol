// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


contract Voting {

    // 所有被投票的候选人
    string[] public votedCandidates;

    // 来存储候选人的得票数
    mapping(string  => uint256) public votesReceived;

    // 允许用户投票给某个候选人
    function vote (string calldata candidate) public {
        require(bytes(candidate).length > 0, "Candidate name cannot be empty");
        // 如果是第一次收到票，加入跟踪列表
        if (votesReceived[candidate] == 0) {
            votedCandidates.push(candidate);
        }
        
        votesReceived[candidate] += 1;
    }

    // 返回某个候选人的得票数
    function getVoteCount(string calldata candidate) public view returns (uint256) {
        return votesReceived[candidate];
    } 


    // 重置所有候选人的得票数
    function resetVotes() public {
        for (uint256 i = 0; i < votedCandidates.length; i++) {
            // 清空该候选人得票数
            delete votesReceived[votedCandidates[i]];
        }
        // 重置跟踪列表
        delete votedCandidates;
    }

}