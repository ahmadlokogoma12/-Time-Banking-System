# Time Banking System Smart Contract

## Overview

This Clarity smart contract implements a decentralized Time Banking platform on the Stacks blockchain, enabling community members to exchange services, contribute to projects, and build reputation through time-based credits.

## Key Features

- User registration with skill tracking
- Service offering and acceptance
- Time credit exchanges
- Community project collaboration
- Reputation system
- Skill-based matching

## Contract Components

### Constants
- `contract-owner`: Initial deployer of the contract
- Error constants for various validation scenarios

### Data Variables
- `user-id-nonce`: Tracks total number of registered users
- `service-id-nonce`: Tracks total number of created services
- `project-id-nonce`: Tracks total number of community projects

### Data Maps
- `users`: Stores user profiles with time balance, reputation, and skills
- `services`: Manages service exchange details
- `projects`: Tracks community project information
- `project-participants`: Records individual contributions to projects

## Primary Functions

### User Management
`register-user(skills)`
- Registers a new user with specified skills
- Assigns initial reputation
- Generates unique user ID

### Service Exchange
`offer-service(description, duration)`
- Users can list services they're willing to provide
- Generates unique service ID

`accept-service(service-id)`
- Allows users to accept offered services

`complete-service(service-id)`
- Facilitates time credit transfer upon service completion
- Updates user time balances

`rate-service(service-id, rating)`
- Enables participants to rate service quality
- Adjusts user reputation based on ratings

### Community Projects
`create-project(name, description, required-skills, total-hours)`
- Establishes community projects with skill requirements

`contribute-to-project(project-id, hours)`
- Users can contribute time credits to community projects
- Tracks individual and total project contributions
- Automatically marks projects as completed when hours goal is met

## Read-Only Functions
- `get-user-details(user-id)`: Retrieve user profile
- `get-service-details(service-id)`: Fetch service information
- `get-project-details(project-id)`: Get project specifics
- `get-project-contribution(project-id, user-id)`: Check individual project contributions

## Usage Example

```clarity
;; Register a user with skills
(register-user (list "programming" "gardening"))

;; Offer a service
(offer-service u"Web design assistance" u4)

;; Accept and complete a service
(accept-service u1)
(complete-service u1)

;; Create a community project
(create-project 
  "Community Garden" 
  u"Develop neighborhood green space" 
  (list "gardening" "landscaping") 
  u20
)

;; Contribute to project
(contribute-to-project u1 u5)
```

## Reputation & Time Credit System
- Initial user reputation: 100
- Reputation calculated via weighted average of ratings
- Time credits exchanged based on service duration
- Users can build reputation through quality service

## Error Handling
- Custom error codes for:
    - Owner-only actions
    - Resource not found
    - Resource already exists
    - Insufficient time balance

## Security Considerations
- Permissioned service and project interactions
- User identity verification
- Reputation-based trust mechanism

## Dependencies
- Stacks blockchain
- Clarity smart contract language

## Potential Improvements
- Skill matching algorithm
- More sophisticated reputation calculation
- Multi-party service collaborations

## Contributing
1. Review contract implementation
2. Test thoroughly
3. Submit pull requests with detailed descriptions

## License
[Insert appropriate open-source license]

## Contact
[Project maintainer contact information]
