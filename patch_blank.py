import sys

with open('lib/screens/owner/stock_at_edp_screen.dart', 'r') as f:
    content = f.read()

# Replace Tab(text: 'Blank') with Tab(text: 'Arrived') for both Re-coating and New
content = content.replace("Tab(text: 'Blank')", "Tab(text: 'Arrived')")

# Replace _buildList('Blank') with _buildList('Arrived')
content = content.replace("_buildList('Blank')", "_buildList('Arrived')")

# Replace status == 'Blank' with status == 'Arrived'
content = content.replace("status == 'Blank'", "status == 'Arrived'")

# Replace s['status'] ?? 'Blank' with s['status'] ?? 'Arrived'
content = content.replace("s['status'] ?? 'Blank'", "s['status'] == 'Blank' ? 'Arrived' : (s['status'] ?? 'Arrived')")

# Replace "Add Blank Spare" with "Add Spare (Arrived)"
content = content.replace("'Add Blank Spare'", "'Add Spare (Arrived)'")

# Replace "No Blank jobs found" with "No Arrived jobs found"
content = content.replace("'No Blank jobs found.'", "'No Arrived jobs found.'")

# The statuses array: const statuses = ['Finished', 'Production', 'Extraction', 'Blank'];
content = content.replace("'Extraction', 'Blank'", "'Extraction', 'Arrived'")
content = content.replace("'Production', 'Blank'", "'Production', 'Arrived'")

with open('lib/screens/owner/stock_at_edp_screen.dart', 'w') as f:
    f.write(content)
