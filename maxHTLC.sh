#!/bin/bash
# maxHTLC.sh
# https://github.com/adamporter/maxHTLC-me
# This bash script uses jq and LND to read a lightning node's channels and update the max HTLC value for each to the local balance, minus the local reserve.

isDryrun=0

while test $# -gt 0; do
  case "$1" in
    -d|--d|-dryrun|--dryrun)
      isDryrun=1
      break
      ;;
    *)
      echo "maxHTLC.sh [options]"
      echo " "
      echo "options:"
      echo "-d, --d, -dryrun, --dryrun     run without making any changes"
      exit 1 ;;
  esac
done

# get the current node's pubkey
node=$(lncli getinfo | jq -r '. | {alias, identity_pubkey} | @base64')
nodeAlias=$(echo "${node}" | base64 --decode | jq -r '.alias')
nodePubkey=$(echo "${node}" | base64 --decode | jq -r '.identity_pubkey')

echo "------------------------"
echo "Adjusting Max HTLCs for Channels of :"
echo "$nodeAlias :: $nodePubkey"
echo "------------------------"
echo "------------------------"

# can also add ' --public_only' to the listchannels call to limit to public channels
for row in $(lncli listchannels | jq -r '.channels[] | {channel_point, chan_id, local_balance, local_chan_reserve_sat, peer_alias} | @base64'); do
#this is a function that we call for initial variable assignments, below
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

# get the current channel's details from the main list
    channelPoint=( $(_jq '.channel_point') )
    channelId=( $(_jq '.chan_id') )
    localBalance=( $(_jq '.local_balance') )
    localReserve=( $(_jq '.local_chan_reserve_sat') )
    peerAlias=( "$(_jq '.peer_alias')" )

# get the current channel's policy information
    channelInformation=$(lncli getchaninfo $channelId | jq -r '.')

    node1Pub=$(echo "$channelInformation" | jq -r '.node1_pub')
    if [ "$node1Pub" == "$nodePubkey" ]
    then
        channelInformation=$(echo "$channelInformation" | jq -r '.node1_policy')
    else
        channelInformation=$(echo "$channelInformation" | jq -r '.node2_policy')
    fi

    maxHTLCMsat=$(echo "${channelInformation}" | jq -r '.max_htlc_msat')
    timeLockDelta=$(echo "${channelInformation}" | jq -r '.time_lock_delta')
    feeBaseMsat=$(echo "${channelInformation}" | jq -r '.fee_base_msat')
    feeRateMilliMsat=$(echo "${channelInformation}" | jq -r '.fee_rate_milli_msat')

# calculate the new Max HTLC in msats for the current channel
    newMaxHTLCMsat=$((($localBalance-$localReserve)*1000))

# make sure we never set to a negative value
    if [ $newMaxHTLCMsat -lt 0 ]
    then
        $newMaxHTLCMsat=0
        echo "New max HTLC value would be negative. Setting to zero."
    fi

# call the update command on each channel
    echo "Checking the Max HTLC for $peerAlias :"

    if [ $maxHTLCMsat != $newMaxHTLCMsat ]
    then
        if [ $isDryrun -eq 1 ]
        then
            echo "Update command would be:"
            echo "lncli updatechanpolicy --max_htlc_msat $newMaxHTLCMsat --base_fee_msat $feeBaseMsat --fee_rate_ppm $feeRateMilliMsat --time_lock_delta $timeLockDelta --chan_point $channelPoint"
        else
	    echo "Updating max HTLC value: $maxHTLCMsat -> $newMaxHTLCMsat msats"
            lncli updatechanpolicy --max_htlc_msat $newMaxHTLCMsat --base_fee_msat $feeBaseMsat --fee_rate_ppm $feeRateMilliMsat --time_lock_delta $timeLockDelta --chan_point $channelPoint
        fi
    else
	echo "No HTLC change required: $maxHTLCMsat == $newMaxHTLCMsat msats"
    fi

    echo "------------------------"
done
echo "Complete"
echo "------------------------"
