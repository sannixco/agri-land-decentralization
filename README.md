# Agricultural Land Decentralization

A decentralized platform for agricultural land parcel registration and management using Clarity smart contracts. This project enables secure registration, ownership tracking, and transfer of agricultural land parcels. The system supports crop registration, parcel quarantine, access permissions, and land-area calculations.

## Features
- **Parcel Registration**: Secure registration of land parcels with details such as title, area, soil type, and crops.
- **Ownership & Transfer**: Farmers can register their parcels, transfer ownership, and update details.
- **Crop Management**: Add and update seasonal crops for a specific parcel.
- **Access Permissions**: Define who can view parcel details, with owner-controlled access.
- **Parcel Quarantine**: Set quarantine status for parcels when necessary.
- **Ownership Verification**: Verify ownership of a parcel and track the duration of ownership.

## Smart Contracts

### Core Data Structures
- **Farm Parcels**: Stores information about each land parcel (title, area, soil type, crops).
- **Parcel Permissions**: Manages access control for viewing parcel details.

### Functions
- **register-farm-parcel**: Registers a new land parcel.
- **add-seasonal-crops**: Adds new crops to an existing parcel.
- **quarantine-farm-parcel**: Quarantines a parcel, restricting its use.
- **update-parcel-details**: Updates parcel information.
- **verify-parcel-ownership**: Verifies the ownership and history of a parcel.
- **deregister-farm-parcel**: Removes a parcel from the registry.
- **transfer-parcel-ownership**: Transfers ownership of a parcel to another farmer.
- **check-parcel-status**: Checks the current status of a parcel.
- **calculate-farmer-holdings**: Calculates the total land area registered by a specific farmer.
- **generate-parcel-report**: Generates a detailed report of a parcel's information.

## How to Use

1. **Deploy the Smart Contract**: Deploy the Clarity smart contract to a blockchain network.
2. **Register Parcels**: Farmers can register their land parcels using the `register-farm-parcel` function.
3. **Manage Crops**: Add seasonal crops using the `add-seasonal-crops` function.
4. **Transfer Ownership**: Farmers can transfer parcel ownership using `transfer-parcel-ownership`.
5. **Check Status**: View the status of a parcel, including whether it's under quarantine using `check-parcel-status`.

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/agri-land-decentralization.git
   cd agri-land-decentralization
   ```

2. Deploy the smart contract on the Stacks testnet or mainnet using the Stacks CLI.

3. Interact with the smart contract using the Stacks wallet or via the Stacks CLI.

## License
MIT License. See [LICENSE](LICENSE) for details.

## Contributing
Feel free to fork the repository and submit pull requests for improvements or new features.
