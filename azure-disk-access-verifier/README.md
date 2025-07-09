# Azure Disk Access Verifier

Audits Azure managed disks to verify they're properly configured with `AllowPrivate` network access policy and correctly linked to Disk Access resources.

## What It Does

- ✅ Verifies disk access resource exists
- 🔍 Checks each VM's OS and data disks for proper `AllowPrivate` configuration  
- 🔗 Validates disks are linked to the correct Disk Access resource
- 📊 Provides summary report with pass/fail status
- 🦙 Includes helpful emojis because Azure is painful enough

## Prerequisites

- Azure CLI installed and authenticated
- `jq` command-line JSON processor
- Read permissions on target resource group and disk resources

## Usage

1. Edit the script variables:

   ```bash
   RG="your-resource-group-name"
   DISK_ACCESS_NAME="your-disk-access-name"
   ```

2. Run the script:

   ```bash
   chmod +x azure-disk-access-verifier.sh
   ./azure-disk-access-verifier.sh
   ```

## Sample Output

```
🔍 Verifying disk access configuration for RG-LOL-NP2-ITN-CAT...
==========================================
Expected Disk Access ID: /subscriptions/.../diskaccess-lol-cat

🦙 Checking VM: vm-lol-cat-ita-auth-PI-01
  OS Disk: vm-lol-cat-ita-auth-PI-01_OsDisk_1_52629a9f...   ✅ Private + Correct Access
  Data Disk: vm-lol-cat-ita-auth-PI-01_disk2_5562e8d0...   ✅ Private + Correct Access

==========================================
📊 FINAL TALLY:
   Total disks found: 12
   Disks with AllowPrivate: 12
   Disks with correct Disk Access: 12
✅ SUCCESS: All disks properly locked down!
```

## Exit Codes

- `0` - All disks properly configured
- `1` - Issues detected or disk access resource not found

## Use Cases

- Post-deployment security validation
- Compliance auditing
- Troubleshooting disk access issues
- Verifying security lockdown scripts worked correctly

## Related Tools

This script pairs well with disk lockdown automation tools that set disks to `AllowPrivate` policy.

## Contributing

Feel free to submit issues or pull requests. This script was born from Azure's delightfully inconsistent CLI behavior.

## License

Public Domain - Use it, break it, fix it, whatever makes your Azure life easier.