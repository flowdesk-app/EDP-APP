const mongoose = require('mongoose');
require('dotenv').config();
const Job = require('./models/Job');

mongoose.connect(process.env.MONGO_URI)
  .then(async () => {
    try {
      const payload = {
        "jobId": "TEST-131",
        "partNumber": null,
        "partDescription": null,
        "quantity": null,
        "numberOfBins": 0,
        "numberOfBoxes": 0,
        "logisticsName": null,
        "deliveredQuantity": null,
        "returnedQuantity": null,
        "destinationType": null,
        "destinationName": null,
        "processType": null,
        "vehicleNumber": null,
        "driverName": null,
        "driverMobile": null,
        "status": "Blank Order",
        "currentLocation": "EDP",
        "supplier": null,
        "supplierChain": [],
        "expectedReturnDate": null,
        "createdAt": "2026-06-27T13:00:00.000Z",
        "jobType": "New",
        "customerName": null,
        "wheelSize": null,
        "diamondPowderGritSize": null,
        "assignedWorker": null,
        "deliveryDate": null,
        "customerOrderDate": "2026-06-27T13:00:00.000Z",
        "customerSentDate": null,
        "receivedDate": null,
        "negotiationDone": null,
        "returnableGatePassNumber": null,
        "returnableGatePassDate": null,
        "extractionDate": null,
        "extractionCompletedDate": null,
        "productionDate": null,
        "purchaseOrderReceived": false,
        "purchaseOrderNumber": null,
        "purchaseOrderDate": null,
        "poNotGiven": true
      };
      const User = require('./models/User');
      const user = await User.findOne({role: 'admin'});
      const newJob = new Job({ ...payload, createdBy: user._id, initialDestinationName: payload.destinationName });
      newJob.statusHistory = [{ status: 'Created', date: new Date(), location: 'EDP' }];
      await newJob.save();
      console.log('Saved');
    } catch (e) {
      console.error(e.message);
    }
    process.exit();
  });
