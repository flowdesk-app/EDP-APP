const express = require('express');
const router = express.Router();
const Estimate = require('../models/Estimate');
const Job = require('../models/Job');
const auth = require('../middleware/auth');

function cleanAlphanumeric(text) {
  if (!text) return '';
  return String(text).toLowerCase().replace(/[^a-z0-9]/g, '');
}

function extractDrawingNo(text) {
  if (!text) return null;
  const patterns = [
    /(?:DRG\.?\s*NO\.?|DRAWING\s*NO\.?|DRG\s*NO|DRG\s*NUMBER)[:;\s]+([A-Za-z0-9_\-\.\/\s]+?)(?=\r|\n|Material|Mat\.?\s*code|Line\s*Item|Partys|Model|\(|$)/i,
    /(?:Drg\.?\s*No\.?)[:;\s]*([A-Za-z0-9_\-\.\/\s]+?)(?=\r|\n|Material|Mat\.?\s*code|Line\s*Item|Partys|Model|\(|$)/i,
    /\(([A-Za-z0-9_\-\.\/]{4,})\)/
  ];
  for (const p of patterns) {
    const m = p.exec(text);
    if (m && m[1]) {
      const val = m[1].trim();
      if (val.length >= 3 && !val.toLowerCase().startsWith('dia') && !val.toLowerCase().startsWith('edp')) {
        return val.replace(/[\s;,\.\-]+$/, '');
      }
    }
  }
  return null;
}

function isSameCustomer(c1, c2) {
  if (!c1 || !c2) return false;
  const a = cleanAlphanumeric(c1);
  const b = cleanAlphanumeric(c2);
  if (!a || !b) return false;
  if (a === b) return true;

  if (a.length >= 4 && b.length >= 4) {
    if (a.includes(b) || b.includes(a)) return true;
  }

  if ((a.includes('bil') || a.includes('brakesindia')) &&
      (b.includes('bil') || b.includes('brakesindia'))) {
    if (a.includes('solingar') && b.includes('solingar')) return true;
    if ((a.includes('sricity') || a.includes('sri')) && (b.includes('sricity') || b.includes('sri'))) return true;
    if (!a.includes('solingar') && !b.includes('solingar') && !a.includes('sricity') && !b.includes('sri')) return true;
  }

  if ((a.includes('rbl') || a.includes('ranebrakelining')) &&
      (b.includes('rbl') || b.includes('ranebrakelining'))) {
    if (a.includes('trichy') && b.includes('trichy')) return true;
    if (a.includes('ambattur') && b.includes('ambattur')) return true;
    if (a.includes('pondicherry') && b.includes('pondicherry')) return true;
    if (a.includes('medak') && b.includes('medak')) return true;
    if (a.includes('ponneri') && b.includes('ponneri')) return true;
  }

  return false;
}

function isMatchingWheel(job, estimate) {
  if (!isSameCustomer(job.customerName, estimate.customerName)) {
    return false;
  }

  const jobDrg = job.drawingNo || extractDrawingNo(job.wheelSize) || extractDrawingNo(job.partNumber) || extractDrawingNo(job.partDescription);
  const estDrg = estimate.drawingNo || extractDrawingNo(estimate.itemDescription) || extractDrawingNo(estimate.calculationsNotes);

  if (jobDrg && estDrg) {
    const cJobDrg = cleanAlphanumeric(jobDrg);
    const cEstDrg = cleanAlphanumeric(estDrg);
    if (cJobDrg && cEstDrg && (cJobDrg === cEstDrg || cJobDrg.includes(cEstDrg) || cEstDrg.includes(cJobDrg))) {
      return true;
    }
  }

  if (job.partNumber && String(job.partNumber).trim().length >= 4) {
    const cleanJobPart = cleanAlphanumeric(job.partNumber);
    const cleanEstDesc = cleanAlphanumeric(estimate.itemDescription);
    const cleanEstDrg = estDrg ? cleanAlphanumeric(estDrg) : '';

    if (cleanEstDesc.includes(cleanJobPart) || (cleanEstDrg && cleanEstDrg.includes(cleanJobPart))) {
      return true;
    }

    const codeInPart = extractDrawingNo(job.partNumber);
    if (codeInPart) {
      const cleanCode = cleanAlphanumeric(codeInPart);
      if (cleanCode.length >= 4 && (cleanEstDesc.includes(cleanCode) || cleanEstDrg.includes(cleanCode))) {
        return true;
      }
    }
  }

  if (job.wheelSize && estimate.itemDescription) {
    const firstLine = String(job.wheelSize).split(/[\r\n]+/)[0].trim();
    const cleanJobWheel = cleanAlphanumeric(firstLine);
    const cleanEstDesc = cleanAlphanumeric(estimate.itemDescription);

    if (cleanJobWheel.length >= 15 && cleanEstDesc.includes(cleanJobWheel)) {
      return true;
    }

    const diaMatch = /Dia\s*(\d+(?:\.\d+)?)\s*mm/i.exec(firstLine);
    const boreMatch = /(\d+(?:\.\d+)?)\s*mm\s*Bore|Bore\s*(\d+(?:\.\d+)?)\s*mm/i.exec(firstLine);
    if (diaMatch && boreMatch) {
      const dia = diaMatch[1];
      const bore = boreMatch[1] || boreMatch[2];
      if (new RegExp(`Dia\\s*${dia}\\s*mm`, 'i').test(estimate.itemDescription) &&
          new RegExp(`(${bore}\\s*mm\\s*Bore|Bore\\s*${bore}\\s*mm)`, 'i').test(estimate.itemDescription)) {
        return true;
      }
    }
  }

  return false;
}

function findMatchingEstimateForJob(job, estimates) {
  for (const est of estimates) {
    if (est.jobId && est.jobId === job.jobId) continue;
    if (isMatchingWheel(job, est)) {
      return est;
    }
  }
  return null;
}

// @route   GET api/estimates
// @desc    Get all estimates (optional ?jobId=... or ?search=...)
router.get('/', auth, async (req, res) => {
  try {
    const filter = {};
    if (req.query.jobId) {
      filter.jobId = req.query.jobId;
    }
    if (req.query.search) {
      const q = req.query.search.trim();
      filter.$or = [
        { calculationNo: { $regex: q, $options: 'i' } },
        { customerName: { $regex: q, $options: 'i' } },
        { itemDescription: { $regex: q, $options: 'i' } },
        { jobId: { $regex: q, $options: 'i' } },
        { drawingNo: { $regex: q, $options: 'i' } },
      ];
    }
    const estimates = await Estimate.find(filter).sort({ createdAt: -1 });
    res.json(estimates);
  } catch (err) {
    console.error('Error fetching estimates:', err);
    res.status(500).json({ msg: 'Server error fetching estimates' });
  }
});

// @route   POST api/estimates/auto-sync-repeats
// @desc    Auto-detect repeat wheel jobs and generate estimates from existing templates
router.post('/auto-sync-repeats', auth, async (req, res) => {
  try {
    const estimates = await Estimate.find({ isDeleted: { $ne: true } }).sort({ createdAt: -1 });
    if (estimates.length === 0) {
      return res.json({ created: [], count: 0 });
    }

    const estimatedJobIds = new Set(estimates.map(e => e.jobId).filter(Boolean));
    const grantedJobs = await Job.find({
      accessGranted: true,
      status: { $ne: 'Removed' },
      isDeleted: { $ne: true },
    }).lean();

    const unestimatedJobs = grantedJobs.filter(j => !estimatedJobIds.has(j.jobId));
    const createdEstimates = [];

    let maxCalc = 112;
    for (const e of estimates) {
      const num = parseInt(e.calculationNo, 10);
      if (!isNaN(num) && num > maxCalc) maxCalc = num;
    }

    for (const job of unestimatedJobs) {
      const template = findMatchingEstimateForJob(job, estimates);
      if (template) {
        maxCalc++;
        const nextCalcNo = String(maxCalc).padStart(8, '0');
        const jobDate = job.receivedDate || job.customerOrderDate || job.createdDate || new Date();

        let drgNo = template.drawingNo;
        if (!drgNo || drgNo.trim() === '') {
          drgNo = extractDrawingNo(job.wheelSize) || extractDrawingNo(job.partNumber);
        }

        const newEstData = {
          calculationNo: nextCalcNo,
          date: jobDate,
          jobId: job.jobId,
          customerName: job.customerName || template.customerName,
          itemDescription: template.itemDescription || job.wheelSize || '',
          drawingNo: drgNo || '',
          type: template.type || 'N',
          calculationsNotes: template.calculationsNotes || '',
          effectiveCoatingArea: template.effectiveCoatingArea || 0,
          gritSize: job.diamondPowderGritSize || template.gritSize,
          factor: template.factor || 0.3,
          diamondRequirement: template.diamondRequirement || 0,
          diamondRate: template.diamondRate || 25,
          diamondCost: template.diamondCost || 0,
          blankCost: template.blankCost || 0,
          grindingCost: template.grindingCost || 0,
          extractionCost: template.extractionCost || 0,
          balancingCost: template.balancingCost || 0,
          transportationCost: template.transportationCost || 0,
          directCostSum: template.directCostSum || 0,
          marginPercentage: template.marginPercentage || 25,
          subTotalInclMargin: template.subTotalInclMargin || 0,
          processCost: template.processCost || 0,
          totalCost: template.totalCost || 0,
          discountProvisionPercentage: template.discountProvisionPercentage || 15,
          provisionForDiscount: template.provisionForDiscount || 0,
          discountPercentage: template.discountPercentage || 0,
          qtnPrice: template.qtnPrice || 0,
          minOrderQty: template.minOrderQty || '1 set',
          delivery: template.delivery || '4 - 6 Weeks',
          qtnNoAndDate: template.qtnNoAndDate || '',
          isAutoEstimated: true,
          createdBy: req.user?.id,
        };

        const newEst = new Estimate(newEstData);
        await newEst.save();
        createdEstimates.push(newEst);
        estimates.unshift(newEst);
        estimatedJobIds.add(job.jobId);

        if (newEst.qtnPrice) {
          try {
            await Job.findOneAndUpdate(
              { jobId: job.jobId },
              { $set: { remarks: `Estimated QTN Price: ₹${newEst.qtnPrice} (Repeat Wheel)` } }
            );
          } catch (jobErr) {
            console.error('Could not update job note:', jobErr);
          }
        }
      }
    }

    res.json({ created: createdEstimates, count: createdEstimates.length });
  } catch (err) {
    console.error('Error auto-syncing repeat estimates:', err);
    res.status(500).json({ msg: 'Server error during repeat sync', error: err.message });
  }
});

// @route   GET api/estimates/job/:jobId
// @desc    Get estimate for a specific jobId
router.get('/job/:jobId', auth, async (req, res) => {
  try {
    const estimate = await Estimate.findOne({ jobId: req.params.jobId }).sort({ createdAt: -1 });
    if (!estimate) {
      return res.status(404).json({ msg: 'Estimate not found for this job' });
    }
    res.json(estimate);
  } catch (err) {
    console.error('Error fetching estimate by jobId:', err);
    res.status(500).json({ msg: 'Server error' });
  }
});

// @route   GET api/estimates/:id
// @desc    Get single estimate by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const estimate = await Estimate.findById(req.params.id);
    if (!estimate) {
      return res.status(404).json({ msg: 'Estimate not found' });
    }
    res.json(estimate);
  } catch (err) {
    console.error('Error fetching estimate:', err);
    res.status(500).json({ msg: 'Server error' });
  }
});

// @route   POST api/estimates
// @desc    Create new estimate
router.post('/', auth, async (req, res) => {
  try {
    const payload = { ...req.body };
    if (req.user && req.user.id) {
      payload.createdBy = req.user.id;
    }

    // Auto-generate calculation number if not provided or empty
    if (!payload.calculationNo || payload.calculationNo.trim() === '') {
      const count = await Estimate.countDocuments();
      payload.calculationNo = String(count + 1).padStart(8, '0');
    }

    const estimate = new Estimate(payload);
    await estimate.save();

    // If linked to a job, update the job record
    if (payload.jobId) {
      try {
        await Job.findOneAndUpdate(
          { jobId: payload.jobId },
          { $set: { remarks: (payload.qtnPrice ? `Estimated QTN Price: ₹${payload.qtnPrice}` : undefined) } }
        );
      } catch (jobErr) {
        console.error('Could not update job note:', jobErr);
      }
    }

    res.status(201).json(estimate);
  } catch (err) {
    console.error('Error saving estimate:', err);
    res.status(500).json({ msg: 'Server error saving estimate', error: err.message });
  }
});

// @route   PUT api/estimates/:id
// @desc    Update existing estimate
router.put('/:id', auth, async (req, res) => {
  try {
    const estimate = await Estimate.findByIdAndUpdate(
      req.params.id,
      { $set: req.body },
      { new: true }
    );
    if (!estimate) {
      return res.status(404).json({ msg: 'Estimate not found' });
    }

    // If linked to a job, update the job record
    if (estimate.jobId && req.body.qtnPrice) {
      try {
        await Job.findOneAndUpdate(
          { jobId: estimate.jobId },
          { $set: { remarks: `Estimated QTN Price: ₹${req.body.qtnPrice}` } }
        );
      } catch (jobErr) {
        console.error('Could not update job note:', jobErr);
      }
    }

    res.json(estimate);
  } catch (err) {
    console.error('Error updating estimate:', err);
    res.status(500).json({ msg: 'Server error updating estimate' });
  }
});

// @route   DELETE api/estimates/:id
// @desc    Delete an estimate
router.delete('/:id', auth, async (req, res) => {
  try {
    const estimate = await Estimate.findByIdAndDelete(req.params.id);
    if (!estimate) {
      return res.status(404).json({ msg: 'Estimate not found' });
    }
    res.json({ msg: 'Estimate deleted successfully', id: req.params.id });
  } catch (err) {
    console.error('Error deleting estimate:', err);
    res.status(500).json({ msg: 'Server error deleting estimate' });
  }
});

module.exports = router;
