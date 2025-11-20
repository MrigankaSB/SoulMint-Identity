// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title SoulMint Identity - On-chain Soulbound Identity & Verifiable Credential System
/// @author

contract SoulMintIdentity {
    struct Attribute {
        string key;
        string value;
    }

    struct SoulboundID {
        uint256 id;
        string name;
        string dataURI;
        address owner;
        bool minted;
        Attribute[] attributes;
        VC[] credentials;
        uint256 createdAt;
    }

    struct VC {
        string issuer;
        string credentialURI;
        uint256 issuedAt;
    }

    uint256 public nextId;
    mapping(address => SoulboundID) public identities;
    mapping(uint256 => address) public idToOwner;
    mapping(address => bool) public delegatedIssuers;
    mapping(bytes32 => bool) public usedProofs;

    // Events
    event IdentityMinted(uint256 indexed id, address indexed owner, string name, string dataURI, uint256 createdAt);
    event IdentityAttributeAdded(uint256 indexed id, string key, string value);
    event VerifiableCredentialAdded(uint256 indexed id, string issuer, string credentialURI, uint256 issuedAt);
    event DelegatedIssuerSet(address indexed issuer, bool enabled);

    // Modifiers
    modifier notMinted() {
        require(!identities[msg.sender].minted, "Identity already minted");
        _;
    }
    modifier onlyOwner(uint256 _id) {
        require(idToOwner[_id] == msg.sender, "Not owner of identity");
        _;
    }
    modifier onlyIssuer() {
        require(msg.sender == owner() || delegatedIssuers[msg.sender], "Not an authorized issuer");
        _;
    }

    // Ownership pattern for contract admin
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }
    function owner() public view returns (address) { return _owner; }

    function transferOwnership(address newOwner) external {
        require(msg.sender == _owner, "Not authorized");
        require(newOwner != address(0), "Zero address");
        _owner = newOwner;
    }

    // Mint a new soulbound identity
    function mintIdentity(string memory _name, string memory _dataURI) external notMinted {
        require(bytes(_name).length > 0, "Name required");
        require(bytes(_dataURI).length > 0, "Data URI required");
        nextId++;
        SoulboundID storage idObj = identities[msg.sender];
        idObj.id = nextId;
        idObj.name = _name;
        idObj.dataURI = _dataURI;
        idObj.owner = msg.sender;
        idObj.minted = true;
        idObj.createdAt = block.timestamp;
        idToOwner[nextId] = msg.sender;
        emit IdentityMinted(nextId, msg.sender, _name, _dataURI, idObj.createdAt);
    }

    // Add custom attributes to identity
    function addAttribute(string memory key, string memory value) external {
        require(identities[msg.sender].minted, "No identity minted");
        require(bytes(key).length > 0 && bytes(value).length > 0, "Invalid attribute");
        SoulboundID storage idObj = identities[msg.sender];
        idObj.attributes.push(Attribute(key, value));
        emit IdentityAttributeAdded(idObj.id, key, value);
    }

    // Get attributes for an identity ID
    function getAttributes(uint256 _id) external view returns (Attribute[] memory) {
        address ownerAddr = idToOwner[_id];
        SoulboundID storage idObj = identities[ownerAddr];
        return idObj.attributes;
    }

    // Add Verifiable Credential (only issuer or admin)
    function addVerifiableCredential(
        uint256 _id,
        string memory issuer,
        string memory credentialURI
    ) external onlyIssuer {
        require(_id != 0 && _id <= nextId, "Invalid identity ID");
        SoulboundID storage idObj = identities[idToOwner[_id]];
        idObj.credentials.push(VC(issuer, credentialURI, block.timestamp));
        emit VerifiableCredentialAdded(_id, issuer, credentialURI, block.timestamp);
    }

    // Retrieve verifiable credentials
    function getCredentials(uint256 _id) external view returns (VC[] memory) {
        address ownerAddr = idToOwner[_id];
        SoulboundID storage idObj = identities[ownerAddr];
        return idObj.credentials;
    }

    // Delegate issuer rights (admin only)
    function setDelegatedIssuer(address issuer, bool enable) external {
        require(msg.sender == _owner, "Only admin");
        delegatedIssuers[issuer] = enable;
        emit DelegatedIssuerSet(issuer, enable);
    }

    // Off-chain proof usage pattern for credential
    function submitProof(
        uint256 _id,
        string memory statement,
        uint8 v, bytes32 r, bytes32 s
    ) public {
        require(_id != 0 && _id <= nextId, "Invalid identity ID");
        bytes32 proofHash = keccak256(abi.encodePacked(_id, statement));
        require(!usedProofs[proofHash], "Proof already used");
        address idOwner = idToOwner[_id];
        bytes32 ethSigned = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", proofHash)
        );
        address signer = ecrecover(ethSigned, v, r, s);
        require(signer == idOwner, "Signature does not match identity");
        usedProofs[proofHash] = true;
        // Add to logs or take relevant action as needed (demo only)
    }

    // Viewers/readers
    function getMyIdentity() external view returns (
        uint256 id,
        string memory name,
        string memory dataURI,
        address ownerAddr,
        bool minted,
        uint256 createdAt
    ) {
        SoulboundID storage identity = identities[msg.sender];
        return (
            identity.id,
            identity.name,
            identity.dataURI,
            identity.owner,
            identity.minted,
            identity.createdAt
        );
    }

    function getIdentityById(uint256 _id) external view returns (
        uint256 id,
        string memory name,
        string memory dataURI,
        address ownerAddr,
        bool minted,
        uint256 createdAt
    ) {
        address ownerAddr = idToOwner[_id];
        SoulboundID storage identity = identities[ownerAddr];
        return (
            identity.id,
            identity.name,
            identity.dataURI,
            identity.owner,
            identity.minted,
            identity.createdAt
        );
    }

    // Recovery: (future expansion, disabled here for soulbound principle)
    // function recoverIdentity(address lostAddr, address newAddr) external {...}

    // For demonstration: total identities
    function totalIdentities() external view returns (uint256) {
        return nextId;
    }
}
