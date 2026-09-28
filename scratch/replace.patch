  Widget _buildItemCard(ItemDatabaseModel item) {
    return InkWell(
      onTap: () => _showItemDetails(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.itemType != null && item.itemType!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.itemType!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Info Rows
            _buildInfoRow(Icons.tag, 'ID: ${item.itemId}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.inventory_2_outlined, 'Vendor: ${item.vendor ?? 'N/A'}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.pin_drop_outlined, 'SKU: ${item.sku ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(ItemDatabaseModel item) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Item Type', item.itemType ?? 'N/A'),
                  _buildDetailRow('HSN Code', item.hsnSac ?? 'N/A'),
                  _buildDetailRow('Unit', item.usageUnit ?? item.unitName ?? 'N/A'),
                  _buildDetailRow('Tax Preference', item.taxable ?? 'N/A'),
                  _buildDetailRow('Intra State Tax Rate', '${item.intraStateTaxRate ?? '0'} %'),
                  _buildDetailRow('Inter State Tax Rate', '${item.interStateTaxRate ?? '0'} %'),
                  _buildDetailRow('Status', item.status ?? 'N/A'),
                  const SizedBox(height: 24),
                  const Text('Sales Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Selling Price', (item.rate ?? '0.00').replaceAll('INR ', '')),
                  _buildDetailRow('Description', item.description ?? 'N/A'),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
