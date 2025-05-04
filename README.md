# IBC-services
Escrow type smart contract that allows service trade to a comunity, where services prices are based in a inverted bonding price curve causing that as more buyers acquire a respective service, price will go down for everyone, pushing more buyers to acquire the product and more sales for sellers at a fair price.

# Used Technologies
Program built in remix, deployed on Sepolia Arbitrum Testnet, MXNB stablecoin integrated and Escrow type smart contract features.

# How it works
Wallet owner creates a standarized product/service, such as "20post1month" meaning a marketing campaing of 20 posts in clients social media through a month.
After this, registered users will be able to offer their product/service based on the standarized one created by owner, when user creates their product they select what kind of service are they offering (for this example we´ll use Marketing), a product code number and the cost of the product in MXNB. When products are created, a cycle will start, during this cycle all further users will be able to buy the product by transfering 50% of the total cost to the contract address, this is where escrow functions and the inverted bonding curve take place.
Inverted bonding curve: as more users buy the product during a cycle, the final cost will reduce foe everyone, this way the protocol pushes more buyers to acquire the product and the seller gets more service requests, taking advantage of escalable finances.
After the cycle ends, the second payment must be transfer, this payment will be reduce depending on the total amount of requests during the cycle, then the service supplier will deliver requested services to their clients and only them will be able to release the full payment to the service supplier, ensuring quality on their services.

Arbitrum Sepolia Tesnet scan link: https://sepolia.arbiscan.io/address/0x3ff2d5238f797611ff7a9e6b7ade19105cf6b86d#code
Arbitrum Sepolia Testnet Contract address: 0x3ff2D5238f797611FF7a9E6B7ADe19105cf6b86d

Scroll Sepolia Testnet scan Link: https://sepolia.scrollscan.com/address/0x0f337e1abd18618d62b603b0cab37135762a175a
Scroll Sepolia Testnet Contract address: 0x0F337e1abd18618d62B603B0cAB37135762A175a
