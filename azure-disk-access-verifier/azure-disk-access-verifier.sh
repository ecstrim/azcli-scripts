#!/bin/bash
#
# Azure Disk Access Verifier
# Version: 1.0.0
# Description: Audits Azure managed disks to verify AllowPrivate network access policy
#              and correct Disk Access resource linkage.
#
# Author: Community
# License: Public Domain / The NonLicense
# Repository: https://github.com/your-username/azure-disk-access-verifier
#

# Configuration - Edit these variables for your environment
RG="your-resource-group-name"
DISK_ACCESS_NAME="diskaccess-name"

echo "🔍 Verifying disk access configuration for $RG..."
echo "======================================================="

# Get expected Disk Access ID
EXPECTED_DISK_ACCESS_ID=$(az disk-access show \
  --resource-group "$RG" \
  --name "$DISK_ACCESS_NAME" \
  --query "id" \
  -o tsv 2>/dev/null)

if [[ -z "$EXPECTED_DISK_ACCESS_ID" ]]; then
  echo "❌ Disk Access resource '$DISK_ACCESS_NAME' not found!"
  exit 1
fi

echo "Expected Disk Access ID: $EXPECTED_DISK_ACCESS_ID"
echo ""

# Counters for the final tally
TOTAL_DISKS=0
PRIVATE_DISKS=0
PROPER_ACCESS_ID=0

# Get all VMs
VM_LIST=$(az vm list --resource-group "$RG" --query "[].name" -o tsv)

for VM in $VM_LIST; do
  echo "🦙 Checking VM: $VM"
  
  # Check OS disk
  OS_DISK_INFO=$(az vm show \
    --resource-group "$RG" \
    --name "$VM" \
    --query "{id: storageProfile.osDisk.managedDisk.id, name: storageProfile.osDisk.name}" \
    -o json)
  
  OS_DISK_ID=$(echo "$OS_DISK_INFO" | jq -r '.id')
  OS_DISK_NAME=$(echo "$OS_DISK_INFO" | jq -r '.name')
  
  if [[ "$OS_DISK_ID" != "null" && -n "$OS_DISK_ID" ]]; then
    DISK_STATUS=$(az disk show \
      --ids "$OS_DISK_ID" \
      --query "{policy: networkAccessPolicy, diskAccess: diskAccessId}" \
      -o json)
    
    POLICY=$(echo "$DISK_STATUS" | jq -r '.policy')
    DISK_ACCESS_ID=$(echo "$DISK_STATUS" | jq -r '.diskAccess')
    
    ((TOTAL_DISKS++))
    
    printf "  OS Disk: %-50s " "$OS_DISK_NAME"
    if [[ "$POLICY" == "AllowPrivate" ]]; then
      ((PRIVATE_DISKS++))
      if [[ "$DISK_ACCESS_ID" == "$EXPECTED_DISK_ACCESS_ID" ]]; then
        ((PROPER_ACCESS_ID++))
        echo "✅ Private + Correct Access"
      else
        echo "⚠️  Private but Wrong Access ID"
      fi
    else
      echo "❌ Policy: $POLICY"
    fi
  fi
  
  # Check data disks
  DATA_DISK_IDS=$(az vm show \
    --resource-group "$RG" \
    --name "$VM" \
    --query "storageProfile.dataDisks[].managedDisk.id" \
    -o tsv)
  
  for DATA_DISK_ID in $DATA_DISK_IDS; do
    if [[ -n "$DATA_DISK_ID" ]]; then
      DATA_DISK_NAME=$(az disk show --ids "$DATA_DISK_ID" --query "name" -o tsv)
      DISK_STATUS=$(az disk show \
        --ids "$DATA_DISK_ID" \
        --query "{policy: networkAccessPolicy, diskAccess: diskAccessId}" \
        -o json)
      
      POLICY=$(echo "$DISK_STATUS" | jq -r '.policy')
      DISK_ACCESS_ID=$(echo "$DISK_STATUS" | jq -r '.diskAccess')
      
      ((TOTAL_DISKS++))
      
      printf "  Data Disk: %-49s " "$DATA_DISK_NAME"
      if [[ "$POLICY" == "AllowPrivate" ]]; then
        ((PRIVATE_DISKS++))
        if [[ "$DISK_ACCESS_ID" == "$EXPECTED_DISK_ACCESS_ID" ]]; then
          ((PROPER_ACCESS_ID++))
          echo "✅ Private + Correct Access"
        else
          echo "⚠️  Private but Wrong Access ID"
        fi
      else
        echo "❌ Policy: $POLICY"
      fi
    fi
  done
  
  echo ""
done

echo "=========================================="
echo "📊 FINAL TALLY:"
echo "   Total disks found: $TOTAL_DISKS"
echo "   Disks with AllowPrivate: $PRIVATE_DISKS"
echo "   Disks with correct Disk Access: $PROPER_ACCESS_ID"

if [[ $TOTAL_DISKS -eq $PRIVATE_DISKS && $PRIVATE_DISKS -eq $PROPER_ACCESS_ID ]]; then
  echo "✅ SUCCESS: All disks properly locked down!"
else
  echo "❌ ISSUES DETECTED: Some disks need attention"
  exit 1
fi