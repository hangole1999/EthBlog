pragma solidity ^0.4.24;

// ----------------------- Public Network Part -----------------------

contract EthBlog {
    
    // Variables
    EthBlogCore internal privateNetwork;
    mapping (address => uint) private users;
    
    address internal owner;
    
    // Event
    event onCallbackShowForm(bytes32 _userName, bytes32 subject, bytes32 body);
    
    // Constructor
    constructor() public {
        owner = msg.sender;
    }
    
    // ModiFier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // Setter
    function setPrivateNetwork(address _address) public onlyOwner() {
        privateNetwork = EthBlogCore(_address);
    }
    
    // Public Interfaces
    function createBlog(bytes32 _nickname) public {
        privateNetwork.createBlog(_nickname, msg.sender);
    }
    
    function writeForm(bool _secret, bytes32 _subject, bytes32 _body) public {
        uint userId = users[msg.sender];
        privateNetwork.writeForm(userId, _secret, _subject, _body);
    }
    
    function showForm(uint _formId) public {
        uint userId = users[msg.sender];
        
        privateNetwork.getPost(userId, _formId);
    }
    
    // Callback Functions
    function _callbackCreateBlog(uint _userId, address _msgSender) public {
        users[_msgSender] = _userId;
    }
    
    function _callbackShowForm(bytes32 _userName, bytes32 _subject, bytes32 _body) public {
        emit onCallbackShowForm(_userName, _subject, _body);
    }
    
}

// ----------------------- Private Network Part -----------------------

contract EthBlogCore {
    
    // Events
    event onCreateBlog(uint userId, bytes32 nickname);
    event onWriteForm(uint userId, uint formId);
    event onCanShowFormList(uint userId, uint _showUserId, uint[] canshowIds);
    
    // Structures
    struct User{
        uint userId;
        bytes32 nickname;
        mapping (uint => uint) formM;
        uint formCount;
    }
    
    struct Form{
        uint formId;
        uint userId;
        bool secret;
        bytes32 subject;
        bytes32 body;
    }
    
    // Variables
    EthBlog internal publicNetwork;
    
    mapping (uint => User) private userM;
    mapping (uint => Form) private formM;
    
    address internal owner;
    
    uint private userIdCount = 0;
    uint private formIdCount = 0;
    
    // Constructor
    constructor(address _address) public {
        owner = msg.sender;
        publicNetwork = EthBlog(_address);
    }
    
    // ModiFier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // Transfer Ownership
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    // Interfaces
    function createBlog(bytes32 _nickname, address _msgSender) public {
        userIdCount++;
        
        userM[userIdCount] = User({
            userId: userIdCount,
            nickname: _nickname,
            formCount: 0
        });
        
        emit onCreateBlog(userIdCount, _nickname);
        
        publicNetwork._callbackCreateBlog(userIdCount, _msgSender);
    }
    
    function writeForm(uint _userId, bool _secret, bytes32 _subject, bytes32 _body) public {
        formIdCount++;
        
        formM[formIdCount] = Form({
            formId: formIdCount,
            userId: _userId,
            secret: _secret,
            subject: _subject,
            body: _body
        });
        
        userM[_userId].formCount++;
        
        userM[_userId].formM[userM[_userId].formCount] = formIdCount;
        
        emit onWriteForm(_userId, formIdCount);
    }
    
    function canShowFormList(uint _userId, uint _showUserId) public view {
        bool isSame = _userId == _showUserId;
        uint[] storage canShowIds;
        
        uint max = userM[_showUserId].formCount;
        for (uint i = 1; i <= max; i++) {
            if (isSame == formM[userM[_showUserId].formM[i]].secret) {
                canShowIds.push(formM[userM[_showUserId].formM[i]].formId);
            }
        }
        
        emit onCanShowFormList(_userId, _showUserId, canShowIds);
    }
    
    // Getters
    function getPost(uint _userId, uint _formId) public {
        (bool result1, bytes32 userName) = getFormUser(_userId, _formId);
        (bool result2, bytes32 subject) = getFormSubject(_userId, _formId);
        (bool result3, bytes32 body) = getFormBody(_userId, _formId);
        
        if (result1 && result2 && result3) {
            publicNetwork._callbackShowForm(userName, subject, body);
        }
    }
    
    function getFormUser(uint _userId, uint _formId) public view returns(bool, bytes32) {
        bool isSame = _userId == formM[_formId].userId;
        bytes32 nickname = userM[formM[_formId].userId].nickname;
        
        bool result = false;
        
        if (formM[_formId].secret) {
            if (isSame) {
                result = true;
            } else {
                nickname = 0x00;
            }
        } else {
            result = true;
        }
        
        return (result, nickname);
    }
    
    function getFormSubject(uint _userId, uint _formId) public view returns(bool, bytes32) {
        bool isSame = _userId == formM[_formId].userId;
        bytes32 subject = formM[_formId].subject;
        
        bool result = false;
        
        if (formM[_formId].secret) {
            if (isSame) {
                result = true;
            } else {
                subject = 0x00;
            }
        } else {
            result = true;
        }
        
        return (result, subject);
    }
    
    function getFormBody(uint _userId, uint _formId) public view returns(bool, bytes32) {
        bool isSame = _userId == formM[_formId].userId;
        bytes32 body = formM[_formId].body;
        
        bool result = false;
        
        if (formM[_formId].secret) {
            if (isSame) {
                result = true;
            } else {
                body = 0x00;
            }
        } else {
            result = true;
        }
        
        return (result, body);
    }
    
}
