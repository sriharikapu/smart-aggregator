pragma solidity ^0.4.24;

import "./Publisher.sol";

contract AdvertiserFactory {
    address[] deployedAdvertisers;
    mapping(address => address) advertisers; //owner to advertiser
    mapping(address => bool) owners;

    function isAdvertiserRegistered() public view returns(bool) {
        return owners[msg.sender];
    }

    function registerAdvertiser(string _profileHash) public {
        address advertiser = new Advertiser(_profileHash, msg.sender);
        deployedAdvertisers.push(advertiser);
        advertisers[msg.sender] = advertiser; 
        owners[msg.sender] = true;
    }

    function getDeployedAdvertisers() public view returns(address[]) {
        return deployedAdvertisers;
    }

    function getAdvertiserByOwner() public view returns(address) {
        return advertisers[msg.sender];
    }
}

contract Advertiser {
    address owner;
    string profileHash;
    address[] deployedOffers;

    modifier restricted() {
        require(msg.sender == owner, "You need to have advertiser owner credential for this operation");
        _;
    }
    constructor(string _profileHash, address _owner) public {
        owner = _owner;
        profileHash = _profileHash;
    }

    function getProfile() public view returns(string, address) {
        return(
           profileHash,
           owner 
        );
    }

    function updateProfile(string _profileHash) public restricted {
        profileHash = _profileHash;
    }

    function createOffer(string _offerProfileHash) public restricted {
        address offer = new Offer(_offerProfileHash, address(this), msg.sender);
        deployedOffers.push(offer);
    }

    function getDeployedOffers() public view returns(address[]) {
        return deployedOffers;
    }

}

contract Offer {
    string offerProfileHash;
    address advertiserContract;
    address advertiserowner;
    struct Conversion {
        string clickId;
        string conversionId;
        string conversionData;
        address publisherOfferContractAddress;
    }
    Conversion[] conversions;

    modifier restricted() {
        require(msg.sender == advertiserowner, "You need to have advertiser owner credential for this operation");
        _;
    }

    constructor(string _offerProfileHash, address _advertiserContract, address _advertiserowner) public {
        offerProfileHash = _offerProfileHash;
        advertiserContract = _advertiserContract;
        advertiserowner = _advertiserowner;
    }

    function getProfile() public view returns(string, address, address) {
        return(
            offerProfileHash,
            advertiserContract,
            advertiserowner
        );
    }

    function updateProfile(string _offerProfileHash) public restricted {
        offerProfileHash = _offerProfileHash;
    }

    function registerConversion(
        address _publishedOfferContractAddress,
        string _clickId,
        string _conversionId,
        string _conversionData) 
        public restricted 
    {
        require(_publishedOfferContractAddress != address(0), "Publisher Offer Contract Address is not found!");

        Conversion memory newConversion = Conversion({
            clickId : _clickId,
            conversionId : _conversionId,
            conversionData : _conversionData,
            publisherOfferContractAddress : _publishedOfferContractAddress
        });

        conversions.push(newConversion);

        PublisherOffer publisherOffer = PublisherOffer(_publishedOfferContractAddress);
        publisherOffer.registerConversion(_clickId, _conversionId, _conversionData);
    }

    function getConversionsCount() public view returns(uint) {
        return conversions.length;
    }

    function getConversionByIndex(uint index) public view returns(string, string, string, address) {
        require(index >= 0, "Index should be positive");

        Conversion storage conversion = conversions[index];

        return (
            conversion.clickId,
            conversion.conversionId,
            conversion.conversionData,
            conversion.publisherOfferContractAddress
        );
    }
}