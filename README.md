# maxHTLC-me
Bash script allowing Lightning Node runners on LND to update the max HTLC values of their channels, en masse.
This script uses jq and LND to read a lightning node's channels and update the max HTLC value for each to the local balance, minus the local reserve.

## Prerequisites
- Lightning Node running [LND](https://github.com/lightningnetwork/lnd)
- [jq](https://github.com/jqlang/jq)
- access to the node with an account capable of running lncli commands

## Usage
- Copy the maxHTLC.sh script to your node
- From the command line, run `bash maxHTLC.sh`
- Alternatively, you can comment out Line 56 ( `lncli updatechanpolicy...` ) by adding a `#` to the beginning of the line, and uncomment Line 55 ( `echo "lncli updatechanpolicy...` ) by removing the `#` at the beginning of that line to view the output without making any changes.

## Forthcoming
- More robust comments
- A dryrun mode
