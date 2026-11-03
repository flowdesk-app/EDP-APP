const mongoose = require('mongoose');
const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const CompanyStorage = require('../models/CompanyStorage');

const jsonPath = '/Users/siddarth-mac/.gemini/antigravity/brain/ed7196ec-da69-4194-986b-8cae9dfbf6e5/scratch/compiled_companies.json';
const companiesData = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

async function seed() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB.');

    console.log(`Seeding/updating ${companiesData.length} companies...`);
    let added = 0;
    let updated = 0;

    for (const item of companiesData) {
      const properName = item.proper_name.trim();
      const prevNames = item.prev_names || [];

      // Query by proper name or any previous name
      let company = await CompanyStorage.findOne({
        $or: [
          { name: properName },
          { name: { $in: prevNames } },
          { aliases: { $in: [properName, ...prevNames] } }
        ]
      });

      const prefixes = item.prefixes || [];
      const aliases = [...new Set([...prevNames, ...(company?.aliases || [])])].filter(a => a !== properName);

      if (company) {
        company.name = properName;
        company.aliases = aliases;
        company.prefixes = [...new Set([...company.prefixes, ...prefixes])];
        company.billingAddress = item.bill_address || '';
        company.shippingAddress = item.ship_address || '';
        company.gstin = item.gstin || '';
        company.vendorCode = item.vendor_code || '';
        company.placeOfSupply = item.place_of_supply || '';
        company.state = item.state || '';
        company.pincode = item.pincode || '';
        company.isDeleted = false;
        company.updatedAt = new Date();
        await company.save();
        updated++;
      } else {
        company = new CompanyStorage({
          name: properName,
          aliases,
          prefixes,
          billingAddress: item.bill_address || '',
          shippingAddress: item.ship_address || '',
          gstin: item.gstin || '',
          vendorCode: item.vendor_code || '',
          placeOfSupply: item.place_of_supply || '',
          state: item.state || '',
          pincode: item.pincode || '',
          isDeleted: false,
          updatedAt: new Date()
        });
        await company.save();
        added++;
      }
    }

    console.log(`Company database seeding complete: ${added} added, ${updated} updated.`);
    const total = await CompanyStorage.countDocuments({ isDeleted: false });
    console.log(`Total active companies in MongoDB now: ${total}`);

    process.exit(0);
  } catch (err) {
    console.error('Seeding error:', err);
    process.exit(1);
  }
}

seed();
