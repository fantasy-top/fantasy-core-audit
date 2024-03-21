# Some audit guidelines

- We want to ensure our contracts are safe for our users. We don't want malicious actors to be able to take our users' tokens.
- We want to ensure our users can trade our NFTs only through our exchange contract.
- We want to ensure our exchange fees cannot be bypassed.
- We want to ensure nobody can mint new NFTs without following our minter configurations (rules).
- We don't really care about gas optimization, please don’t waste your precious audit time on them.

# Fantasy Gameplay 
- Fantasy is a Trading Card Game in which players collect cards featuring crypto influencers to compete and earn ETH, BLAST, more cards, and FAN Points.
- Players acquire cards on the Fantasy marketplace, using them to assemble a deck and compete in the Fantasy Tournaments.
- Players are ranked based on their influencers' performance on Twitter. At the end of a competition, rewards are distributed according to the players' rankings.
- Newly distributed cards are minted, completing the initial distribution of cards, which was initiated through an airdrop and a sale.
- A VRGDA allows players to buy cards from the Fantasy Shop.
- Details can be found here https://aaa-angel.notion.site/fantasy-top-1b35a92e51934478bb542a5115469302?pvs=4


# Fantasy Contracts

**ExecutionDelegate** contract is responsible for executing token transfers on behalf of the user. It is therefore the only contract the user needs to approve for token transfers. It is also the only contract allowed to transfer and mint fantasy cards. The ExecutionDelegate functions are opened to whitelisted contracts (aka Exchange and Minter)

**FantasyCards** contract is an ERC721; it can only be transferred and minted by the ExecutionDelegate contract. This is to ensure only contracts approved by the protocol have access to these functions.

**Exchange** contract is responsible for trading fantasy cards. When buying or selling a card, a fee is taken and sent to the protocol's treasury address. The buy and sell functions of this contract can only be called by EOAs

**Minter** contract is responsible for minting new fantasy cards. The owner of the Minter contract can configure the minting dynamics. The minter can be configured to use a fixed price or a linear gradual dutch auction.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Run local node Anvil

```shell
$ anvil
```

### Deploy Local

Run local node first:

```shell
$ anvil
```

In an other terminal run:

```shell
$ forge script script/deploy_local.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
