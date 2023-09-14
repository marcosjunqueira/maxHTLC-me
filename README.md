# maxHTLC-me
Bash script allowing Lightning Node runners on LND to update the max HTLC values of their channels, en masse.
This script uses jq and LND to read a lightning node's channels and update the max HTLC value for each to the local balance, minus the local reserve.

## What it does
The script:
1. queries the running node's information
2. queries for the list of channels the node has
3. queries for details about each channel from that list
4. calculates what the max HTLC should be set to (local balance - local reserve)
5. if the new max HTLC is different than the current max HTLC, the channel is updated with the new max HTLC value

## Prerequisites
- Lightning Node running [LND](https://github.com/lightningnetwork/lnd)
- [jq](https://github.com/jqlang/jq)
- access to the node with an account capable of running lncli commands

## Usage
- Copy the maxHTLC.sh script to your node
- From the command line, run `bash maxHTLC.sh`
- Alternatively, you can comment out Line 56 ( `lncli updatechanpolicy...` ) by adding a `#` to the beginning of the line, and uncomment Line 55 ( `echo "lncli updatechanpolicy...` ) by removing the `#` at the beginning of that line to view the output without making any changes.

## Responses
For each channel being updated, there are 2 possible outcomes. If the max HTLC is already set as it should be, a simple `No change required.` message will appear. However, if the max HTLC has been updated, you will get the lncli response of that call written to the screen. The output should be:
```json
{
	"failed_updates": []
}
```
This indicates that the update was successful and did not fail.

## Forthcoming
- More robust comments
- A dryrun mode
