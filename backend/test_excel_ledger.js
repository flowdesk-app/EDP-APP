const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

const Job = require('./models/Job');

function getDaysInMonth(year, month) {
    return new Date(year, month, 0).getDate();
}

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    try {
        const jobs = await Job.find({ status: { $ne: 'Removed' } }).sort({ createdAt: 1 });
        
        let movements = [];
        jobs.forEach(job => {
            const part = job.partNumber;
            if (!part) return;

            const supplierName = job.initialDestinationName || job.destinationName || 'Unknown';
            const customerName = job.destinationName || 'Customer';

            if (job.status === 'Returned') {
                movements.push({
                    date: job.createdAt,
                    part: part,
                    type: 'rejected',
                    qty: job.quantity,
                    colName: 'REJECTION'
                });
            } else {
                movements.push({
                    date: job.createdAt,
                    part: part,
                    type: 'dispatched',
                    qty: job.quantity,
                    colName: `JAE TO ${supplierName}`.toUpperCase()
                });

                if (job.status === 'Delivered') {
                    let dDate = job.updatedAt; 
                    if (job.statusHistory) {
                        const delEntry = job.statusHistory.find(h => h.status === 'Delivered');
                        if (delEntry && delEntry.date) dDate = delEntry.date;
                    }
                    movements.push({
                        date: dDate,
                        part: part,
                        type: 'delivered',
                        qty: job.quantity,
                        colName: `${supplierName} TO ${customerName}`.toUpperCase()
                    });
                } else if (job.deliveredQuantity && job.deliveredQuantity > 0) {
                    movements.push({
                        date: job.updatedAt,
                        part: part,
                        type: 'delivered',
                        qty: job.deliveredQuantity,
                        colName: `${supplierName} TO ${customerName}`.toUpperCase()
                    });
                }
            }
        });

        const queryMonth = '2026-06';
        const [y, m] = queryMonth.split('-').map(Number);
        const startDate = new Date(y, m - 1, 1).getTime();
        const endDate = new Date(y, m, 0, 23, 59, 59, 999).getTime();
        const daysInMonth = getDaysInMonth(y, m);
        let daysToGenerate = [];
        for(let i=1; i<=daysInMonth; i++) {
            daysToGenerate.push(`${y}-${String(m).padStart(2,'0')}-${String(i).padStart(2,'0')}`);
        }

        // Build columns for each part
        const partNames = [...new Set(movements.map(m => m.part))].sort();
        const partsData = partNames.map(p => {
            const partMovs = movements.filter(m => m.part === p);
            
            // Get unique dispatch and delivery columns, ensuring consistent order
            const dispatchCols = [...new Set(partMovs.filter(m => m.type === 'dispatched').map(m => m.colName))].sort();
            const deliveryCols = [...new Set(partMovs.filter(m => m.type === 'delivered').map(m => m.colName))].sort();
            
            // If there are no dispatch cols but there's a part, we should probably still have a default JAE TO... 
            // But if it's strictly data driven:
            const cols = [...dispatchCols, ...deliveryCols, 'REJECTION', 'CLOSING STOCK'];

            return {
                partNumber: p,
                columns: cols,
                openingStock: 0
            };
        });

        let runningStock = {};
        partsData.forEach(p => runningStock[p.partNumber] = 0);
        
        let dailyAgg = {};
        movements.forEach(m => {
            const d = new Date(m.date);
            const t = d.getTime();
            
            if (t < startDate) {
                if (m.type === 'dispatched') runningStock[m.part] += m.qty;
                else if (m.type === 'delivered') runningStock[m.part] -= m.qty;
                else if (m.type === 'rejected') runningStock[m.part] -= m.qty;
            } else if (t <= endDate) {
                const dateStr = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
                if (!dailyAgg[dateStr]) dailyAgg[dateStr] = {};
                if (!dailyAgg[dateStr][m.part]) dailyAgg[dateStr][m.part] = {};
                
                dailyAgg[dateStr][m.part][m.colName] = (dailyAgg[dateStr][m.part][m.colName] || 0) + m.qty;
            }
        });

        partsData.forEach(p => p.openingStock = runningStock[p.partNumber]);

        const rows = [];
        daysToGenerate.forEach(dStr => {
            const row = { date: dStr, parts: {} };
            partsData.forEach(p => {
                const part = p.partNumber;
                let dayData = {};
                
                let dispatchedSum = 0;
                let deliveredSum = 0;
                let rejectedSum = 0;

                p.columns.forEach(col => {
                    if (col === 'CLOSING STOCK') return; // Handled later
                    
                    const qty = (dailyAgg[dStr] && dailyAgg[dStr][part] && dailyAgg[dStr][part][col]) || 0;
                    dayData[col] = qty;
                    
                    if (col.startsWith('JAE TO')) dispatchedSum += qty;
                    else if (col === 'REJECTION') rejectedSum += qty;
                    else deliveredSum += qty;
                });
                
                runningStock[part] = runningStock[part] + dispatchedSum - deliveredSum - rejectedSum;
                dayData['CLOSING STOCK'] = runningStock[part];
                
                row.parts[part] = dayData;
            });
            rows.push(row);
        });

        console.log(JSON.stringify({ parts: partsData, rows: rows.slice(0, 2) }, null, 2));

    } catch(e) { console.error("Error", e); }
    process.exit(0);
  })
  .catch(console.error);
