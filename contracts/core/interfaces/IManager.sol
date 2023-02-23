//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.10 <0.9.0;

interface IManager {

    event ManagerAssigned(address indexed manager, address indexed assignee, uint256 index);
    
    event ManagerChanged(address oldManager, address indexed newManager);

    event AssigneeRemoved(address assignee);

    error Manager_ZeroAddress();

    error Manager_AssigneeExists();

    error Manager_NotEmpty();

    error Manager_AssigneeNotExists();

    error Manager_SameAddress();

    error Manager_Mismatch();
    
    function assignManager(address manager, address assignee) external;

    function changeManager(address newManager, address prevManager, address assignee) external;

    function isManager(address manager, address assignee) external view returns(bool);

    function removeAssignee(address assignee, address manager) external;

    function allManagerAssignees(address manager) external view returns(address[] memory);

    function managerAssigneesCount(address manager) external view returns(uint256);

    function assigneeAddress(address manager, uint256 id) external view returns(address);

    function isAssignee(address assignee) external view returns(bool);
}