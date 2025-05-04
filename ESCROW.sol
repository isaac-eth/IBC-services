// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ServiceEscrow {
    using SafeERC20 for IERC20;

    address public owner;
    IERC20 public mxnb;
    uint256 public userCounter;
    uint256 public productCounter;
    uint256 public purchaseCounter;
    uint256 public marketingProductCounter;

    constructor() {
        owner = msg.sender;
        mxnb = IERC20(0x82B9e52b26A2954E113F94Ff26647754d5a4247D);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    enum ServiceType { Fiscal, Legal, Tecnologico, Marketing, Ventas, Gobernanza, Diseno, ModeloNegocio }

    struct MarketingProductInfo {
        string name;
        bool exists;
    }

    struct User {
        address wallet;
        string telegram;
        uint256 memberId;
    }

    struct ProductOffering {
        ServiceType serviceType;
        uint256 productCode;
        uint256 priceMXNB;
        address provider;
        uint256 cycleEnd;
        uint256 cycleCount;
    }

    struct Purchase {
        uint256 productId;
        address buyer;
        bool isRecurring;
        bool paymentReleased;
        bool secondPaymentMade;
        bool cancelled;
        uint256 cycleNumber;
        uint256 cycleEnd;
        uint256 discountPercent;
        uint256 fullCost;
        uint256 firstPayment;
    }

    mapping(uint256 => User) public users;
    mapping(address => uint256) public walletToUserId;
    mapping(uint256 => ProductOffering) public products;
    mapping(uint256 => Purchase) public purchases;
    mapping(uint256 => mapping(uint256 => uint256[])) public productCyclePurchases;
    mapping(uint256 => MarketingProductInfo) public marketingProducts;

    event UserRegistered(address wallet, string telegram, uint256 userId);
    event ProductRegistered(uint256 productId, ServiceType serviceType, uint256 productCode, uint256 priceMXNB, address provider, uint256 cycleEnd, uint256 cycleCount);
    event FirstHalfPaid(uint256 purchaseId, uint256 productId, address buyer, uint256 cycleNumber, uint256 firstPayment, uint256 fullCost, uint256 totalCyclePurchases);
    event SecondHalfPaid(uint256 purchaseId, uint256 productId, address buyer, uint256 secondPayment, uint256 discountPercent);
    event PaymentReleased(uint256 purchaseId, uint256 productId, address provider, uint256 amount);
    event RecurringPurchaseCancelled(uint256 purchaseId, address buyer);
    event MarketingProductAdded(uint256 productId);

    function registerUser(string calldata telegram) external {
        require(walletToUserId[msg.sender] == 0, "Ya registrado");
        userCounter++;
        users[userCounter] = User(msg.sender, telegram, userCounter);
        walletToUserId[msg.sender] = userCounter;

        emit UserRegistered(msg.sender, telegram, userCounter);
    }

    function addMarketingProduct(string calldata name) external onlyOwner {
        marketingProducts[marketingProductCounter] = MarketingProductInfo(name, true);
        emit MarketingProductAdded(marketingProductCounter);
        marketingProductCounter++;
    }

    function registerProduct(ServiceType serviceType, uint256 productCode, uint256 priceHumanMXN) external {
        require(serviceType == ServiceType.Marketing, "Solo Marketing permitido");
        require(marketingProducts[productCode].exists, "Producto no valido para Marketing");

        uint256 price = priceHumanMXN * 10**6;
        products[productCounter] = ProductOffering({
            serviceType: serviceType,
            productCode: productCode,
            priceMXNB: price,
            provider: msg.sender,
            cycleEnd: block.timestamp + 3 minutes,
            cycleCount: 0
        });

        emit ProductRegistered(productCounter, serviceType, productCode, price, msg.sender, block.timestamp + 2 minutes, 0);

        productCounter++;
    }

    function buyProduct(uint256 productId, bool isRecurring) external {
        ProductOffering memory offer = products[productId];
        require(offer.provider != address(0), "Producto no existe");

        if (block.timestamp > offer.cycleEnd) {
            offer.cycleCount++;
            offer.cycleEnd = block.timestamp + 2 minutes;
        }

        uint256 initialPayment = offer.priceMXNB / 2;
        mxnb.safeTransferFrom(msg.sender, address(this), initialPayment);

        purchases[purchaseCounter] = Purchase({
            productId: productId,
            buyer: msg.sender,
            isRecurring: isRecurring,
            paymentReleased: false,
            secondPaymentMade: false,
            cancelled: false,
            cycleNumber: offer.cycleCount,
            cycleEnd: offer.cycleEnd,
            discountPercent: 0,
            fullCost: offer.priceMXNB,
            firstPayment: initialPayment
        });

        productCyclePurchases[productId][offer.cycleCount].push(purchaseCounter);

        emit FirstHalfPaid(
            purchaseCounter,
            productId,
            msg.sender,
            offer.cycleCount,
            initialPayment,
            offer.priceMXNB,
            productCyclePurchases[productId][offer.cycleCount].length
        );

        purchaseCounter++;
    }

    function calculateDiscount(uint256 productId, uint256 cycleNumber) public view returns (uint256) {
        uint256 count = productCyclePurchases[productId][cycleNumber].length;
        if (count >= 4) return 15;
        if (count >= 3) return 10;
        if (count >= 2) return 5;
        return 0;
    }

    function payRemaining(uint256 purchaseId) external {
        Purchase storage p = purchases[purchaseId];
        
        require(msg.sender == p.buyer, "Solo el comprador");
        require(!p.secondPaymentMade, "Ya pagado");
        require(block.timestamp > p.cycleEnd, "Ciclo no ha terminado");

        uint256 discount = calculateDiscount(p.productId, p.cycleNumber);
        uint256 finalCost = p.fullCost * (100 - discount) / 100;
        uint256 secondPayment = finalCost - p.firstPayment;

        mxnb.safeTransferFrom(msg.sender, address(this), secondPayment);
        p.secondPaymentMade = true;
        p.discountPercent = discount;

        emit SecondHalfPaid(purchaseId, p.productId, msg.sender, secondPayment, discount);
    }

    function releasePayment(uint256 purchaseId) external {
        Purchase storage p = purchases[purchaseId];
        ProductOffering memory offer = products[p.productId];

        require(msg.sender == p.buyer, "Solo el comprador");
        require(p.secondPaymentMade, "Falta segundo pago");
        require(!p.paymentReleased, "Ya liberado");

        p.paymentReleased = true;
        mxnb.safeTransfer(offer.provider, p.fullCost);

        emit PaymentReleased(purchaseId, p.productId, offer.provider, p.fullCost);
    }

    function cancelRecurringPurchase(uint256 purchaseId) external {
        Purchase storage p = purchases[purchaseId];
        require(msg.sender == p.buyer, "Solo el comprador");
        require(p.isRecurring, "No es recurrente");
        require(!p.cancelled, "Ya cancelado");
        p.cancelled = true;

        emit RecurringPurchaseCancelled(purchaseId, msg.sender);
    }

    function getAllProducts() external view returns (ProductOffering[] memory) {
        ProductOffering[] memory all = new ProductOffering[](productCounter);
        for (uint i = 0; i < productCounter; i++) {
            all[i] = products[i];
        }
        return all;
    }

    function getMyPurchases(address user) external view returns (Purchase[] memory) {
        uint256 total = purchaseCounter;
        uint256 count = 0;
        for (uint i = 0; i < total; i++) {
            if (purchases[i].buyer == user) {
                count++;
            }
        }

        Purchase[] memory result = new Purchase[](count);
        uint256 index = 0;
        for (uint i = 0; i < total; i++) {
            if (purchases[i].buyer == user) {
                result[index] = purchases[i];
                index++;
            }
        }
        return result;
    }
}
