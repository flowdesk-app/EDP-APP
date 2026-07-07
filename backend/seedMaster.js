const mongoose = require('mongoose');
const MasterData = require('./models/MasterData');

mongoose.connect('mongodb://127.0.0.1:27017/edp_db').then(async () => {
    await MasterData.create([
        { jobType: 'New', field: 'Customer Name', value: 'Genesis Motors' },
        { jobType: 'New', field: 'Part Number', value: 'GN-001' },
        { jobType: 'Re-coating', field: 'Customer Name', value: 'Global Tech' }
    ]);
    console.log('Seeded Master Data');
    process.exit(0);
}).catch(err => {
    console.error(err);
    process.exit(1);
});
