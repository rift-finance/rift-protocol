# rift-protocol

See the [Rift Documentation](https://docs.rift.finance/protocol-overview/smart-contract-overview) for more information.

## Getting Started

1. Install [foundry](https://github.com/gakonst/foundry#installation)
2. Install dependencies with `yarn` and `forge update`
3. Compile contracts with `make build`
4. Add your RPC URL API key to `foundry.toml`
5. Run tests with `make test`

## Contract Structure

### Core

The `Core.sol` contract is only deployed once per chain. It maintains important parameters across all vault deployments (and any future Rift contracts). In particular, it maintains:

- `protocolFee`: protocol wide fee out of 10_000.
- `feeTo`: the beneficiary of the protocol fee, i.e. the treasury.
- `registeredVaults`: a list of Rift Vaults that have been registered.
- `paused`: state of the Rift Protocol, paused in dire circumstances.

Additionally, it manages permissions.

- `Governor`: can register vaults, set the `protocolFee` & `feeTo`, and add and revoke roles, can enable or disable the whitelist.
- `Strategist`: can move vaults to the next epoch, set floor variables for a vault.
- `Pauser`: can pause the Rift Protocol, or a specific vault.
- `Guardian`: can rescue funds from a vault, only if the vault (or protocol) is paused.
- `Whitelisted`: can interact with Rift Vaults as a user. Whitelist can be disabled.

### Refs

- Any contract that wishes to interact with the Core contract and use its state / parameters / permissions can do so by inheriting the `CoreReference.sol` contract, which provides a useful interface to the `Core`.

### Vaults

This stores the important logic for accepting deposits and withdraws, does the accounting for returns, and interacts with DEXs.

`Vault` is the base class inherited by each DEX type's contract. Parameters defined on initializaiton:

- `coreAddress`: the address of the core contract
- `epochDuration`: length of each epoch in seconds
- `token0`: token that receives the interest rate floor (in practice, the ETH side)
- `token1`: token that receives the interest rate ceiling (in practice, the DAO side)
- `token0FloorNum`: interest rate floor for the `token0` side, out of 10000. This will be set to ~10000, to guarantee lossless returns for the token0 side.
- `token1FloorNum`: interest rate floor for the `token1` side, out of 10000. This will be set to a low amount, just to keep internal accounting consistent.
- `isNativeVault`: this indicates if a vault accepts the native token for this chain on the `token0` side. If yes, `token0` is the wrapped native token, otherwise, `token0` can be an arbitrary ERC20 token.

Note: Vaults do not currently support fee on transfer / deflationary tokens.

#### Deposits

Users can deposit into a Vault by calling `depositToken0` or `depositToken1`. Users must have approved the token before this transaction, unless it is an ETH Vault, in which case they can include the amount being deposited in `msg.value`. The contract updates the accounting balances for this user accordingly, and queues up their deposit to be included in the next epoch.

The deposit accounting checks if the user had previously deposited. If they had already requested a deposit for the current epoch, it simply adds their new deposit to the queued amount. If the user deposited in an epoch that has completed, we now know the exchange rate for that epoch. So we can convert their fulfilled token deposit amount to "day 0" tokens, and add it to their total day0Token balance.

#### Withdraws

Users can withdraw from a Vault by calling `withdrawToken0` or `withdrawToken1`. Users specify the amount being withdrawn in units of Day 0 Balance. They cannot specify the withdraw amount in absolute tokens, because we won't know the exchange rate for their Day 0 Tokens until this epoch closes. But they do have a Day 0 Balance, so they can choose to withdraw some or all of it for the end of the epoch. This withdraw pattern allows the protocol to prevent frontrunning in DEXs.

Similar to the way we do deposit accounting, we first need to check previous deposit and withdraw requests, and mark them as having been fulfilled if they were from a previous epoch. We then add on the new withdraw request to any other withdraw requests submitted for the current epoch.

#### Claims

After users submit a withdraw request, and the current epoch finishes, they can claim their tokens by calling `claimToken0` or `claimToken1`. These functions check the users claimable balance, zeros out their claim, and sends them their tokens.

#### Moving to the next epoch

This function allows the Vault's strategist role to move the Vault to its next epoch, collecting new deposit and withdraw requests, and pairing up the newly available amounts of `token0` and `token1` into the DEX pool. The strategist specifies the expected pool balances in the DEX pool, and the Vault checks that the current balances are within that expected range, preventing any potential frontrunning. This allows us to set minAmounts to 0 when interacting with DEX routers to add liquidity, remove liquidity, and makes swaps, because we already guaranteed certain pool balances, and any of these calls are in the same transaction without any untrusted external calls.

The `nextEpoch` function withdraws liquidity from the DEX, and if necessary, makes a swap from `token0` to `token1` or vice versa, depending on the initial and final balances of the pool and swap fees accrued during the period. It then updates the current exchange rate for "Day 0 Tokens". For example, if someone deposited 100 TOKEN0 in the first epoch when the exchange rate was 1:1, and at the end of this epoch the new exchange rate is 10:11, the user would have a claim on 110 TOKEN0 if they would choose to withdraw. We store the historical exchange rate for each epoch, for both `token0`, and `token1`, so that requests can be claimed in the future.

Then it calculates the amount of each token being withdrawn during this epoch, calculated as the total amount of "Day 0 Tokens" withdrawn times the current exchange rate. It aggregates that with the total amount of deposits requests for each token. Now we know how much of each token is currently available (after withdraws and deposits) to be paired up in the DEX. The Vault contract now redeposits the available tokens into the DEX.

There are 5 functions that are left undefined in the Vault contract. These functions are specific to the DEX type that the instance of the vault interacts with.

- `getPoolBalances`: returns the reserve amounts of each token currently in the DEX pool
- `calcAmountIn`: calculates the amount of tokenA that must be swapped to get some amount of tokenB given the current reserves of the DEX pool
- `withdrawLiquidity`: withdraws all LP tokens from the DEX pool
- `depositLiqudity`: deposits tokens into the DEX pool and receives LP tokens
- `swap`: swaps some amount of tokenA for tokenB in the DEX.

### Vault Types

#### Uniswap Vault

The Uniswap Vault inherits the Vault parent contract, and simply defines these 5 virtual functions so that they interact with the Uniswap Router. It can also be used for Sushiswap, because there is no dependency on the `UniswapV2Library` with a different init code hash.

#### MasterChef Vault

The MasterChef Vault inherits from the Uniswap Vault and is used for token pairs that receive rewards from Sushi's MasterChef contract. Upon depositing liquidity into the DEX, it takes the received LP Tokens and stakes them in the MasterChef contract to receive `SUSHI` staking rewards. Before withdrawing liqudity, it unstakes its tokens from the MasterChef, harvests Sushi rewards, then removes its liquidity from the DEX pool.

#### MasterChefV2 Vault

The MasterChefV2 Vault inherits from the Uniswap Vault and is used for token pairs that receive rewards from Sushi's MasterChefV2 contract. Upon depositing liquidity into the DEX, it takes the received LP Tokens and stakes them in the MasterChefV2 contract to receive both `SUSHI` and `MasterChefV2` staking rewards, which are typically denominated as the token paired with ETH. For example, a DAO may incentivize its Pool 2 by providing liquidity mining rewards of its own token for users who provide liquidity and stake with MasterChefV2. Before withdrawing liqudity, the contract unstakes its tokens from the MasterChefV2, harvests Sushi and MasterChefV2 rewards, then removes its liquidity from the DEX pool.

#### Other

New vault types can be added easily by inheriting the `Vault` class and defining the 5 function listed above.
