#!/usr/bin/env bash
set -euo pipefail

# Check if start, end, and rollup config arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <start_block> <end_block> <rollup_config_path>"
    echo "Example: $0 4596300 4796300 ./rollup.json"
    exit 1
fi

ROLLUP_CONFIG=$1
START_BLOCK=$2
END_BLOCK=$3

# Check if rollup.json exists
if [ ! -f "$ROLLUP_CONFIG" ]; then
    echo "Error: rollup config not found at $ROLLUP_CONFIG"
    exit 1
fi

# Extract values from rollup.json
INBOX=$(jq -r '.batch_inbox_address' "$ROLLUP_CONFIG")
SENDER=$(jq -r '.genesis.system_config.batcherAddr' "$ROLLUP_CONFIG")
L2_CHAIN_ID=$(jq -r '.l2_chain_id' "$ROLLUP_CONFIG")
L2_GENESIS_TIMESTAMP=$(jq -r '.genesis.l2_time' "$ROLLUP_CONFIG")

echo "> Fetching L1 txs..."

# Run fetch command
go run . fetch \
    --inbox "$INBOX" \
    --l1 http://localhost:8545 \
    --start "$START_BLOCK" \
    --end "$END_BLOCK" \
    --sender "$SENDER"

echo "> Reassembling channels..."

# Run reassemble command
go run . reassemble \
    --l2-chain-id "$L2_CHAIN_ID" \
    --l2-genesis-timestamp "$L2_GENESIS_TIMESTAMP" \
    --inbox "$INBOX" \
    --rollup-config "$ROLLUP_CONFIG"

echo "Extracting batches with transactions..."

# Extract batches with transactions
jq '.batches[] | select(.Transactions != null)' /tmp/batch_decoder/channel_cache/*.json

echo "Done!"
