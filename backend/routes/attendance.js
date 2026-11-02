const express = require('express');
const router = express.Router();
const { spawn } = require('child_process');
const path = require('path');
const Attendance = require('../models/Attendance');
const User = require('../models/User');

const getTodayDateStr = () => {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(new Date());
};

const DEFAULT_EMPLOYEE_DETAILS = {
  'owner@flowdesk.com': { name: 'Owner / Executive', department: 'Management' },
  'admin@flowdesk.com': { name: 'Operations Admin', department: 'Operations' },
  'employee1@flowdesk.com': { name: 'Siddarth (Employee 1)', department: 'Inventory & Operations' },
  'employee2@flowdesk.com': { name: 'Friend (Employee 2)', department: 'Shop Floor & Production' },
  'employee3@flowdesk.com': { name: 'Employee 3 (Dispatch)', department: 'Quality & Dispatch' },
  'payroll@flowdesk.com': { name: 'Payroll Manager', department: 'Accounts & HR' },
};

// GET /api/attendance/enrolled-employees
router.get('/enrolled-employees', async (req, res) => {
  try {
    const users = await User.find(
      { role: { $ne: 'payroll' } },
      'email name department role isFaceEnrolled faceEmbeddings facePhotoUrl lastEnrolledAt'
    ).lean();

    const formatted = users.map(u => {
      const def = DEFAULT_EMPLOYEE_DETAILS[u.email] || {};
      return {
        _id: u._id,
        email: u.email,
        name: u.name || def.name || u.email.split('@')[0],
        department: u.department || def.department || 'Production',
        role: u.role,
        isFaceEnrolled: !!u.isFaceEnrolled,
        faceEmbeddings: u.faceEmbeddings || [],
        facePhotoUrl: u.facePhotoUrl,
        lastEnrolledAt: u.lastEnrolledAt,
      };
    });

    res.json(formatted);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/attendance/enroll-face
router.post('/enroll-face', async (req, res) => {
  try {
    const { email, faceEmbeddings, facePhotoUrl, name, department } = req.body;
    if (!email) {
      return res.status(400).json({ error: 'Employee email is required' });
    }

    if (!Array.isArray(faceEmbeddings) || faceEmbeddings.length === 0) {
      return res.status(400).json({ error: 'Valid faceEmbeddings vector array is required' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: 'Employee user not found' });
    }

    user.faceEmbeddings = faceEmbeddings;
    user.isFaceEnrolled = true;
    user.lastEnrolledAt = new Date();
    if (facePhotoUrl) user.facePhotoUrl = facePhotoUrl;
    if (name) user.name = name;
    if (department) user.department = department;

    await user.save();

    res.json({
      success: true,
      message: `Face enrolled successfully for ${user.email}`,
      user: {
        email: user.email,
        name: user.name,
        department: user.department,
        isFaceEnrolled: user.isFaceEnrolled,
        lastEnrolledAt: user.lastEnrolledAt,
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/attendance/scan (Clock-In / Clock-Out)
router.post('/scan', async (req, res) => {
  try {
    const { email, scanType = 'auto', scanMethod = 'face_recognition', notes } = req.body;
    if (!email) {
      return res.status(400).json({ error: 'Employee email is required' });
    }

    const user = await User.findOne({ email }).lean();
    if (!user) {
      return res.status(404).json({ error: 'Employee not found' });
    }

    const def = DEFAULT_EMPLOYEE_DETAILS[email] || {};
    const empName = user.name || def.name || email.split('@')[0];
    const dept = user.department || def.department || 'Production';

    const todayDate = getTodayDateStr();
    const now = new Date();

    let record = await Attendance.findOne({ employeeEmail: email, date: todayDate });

    let actionTaken = 'in';

    if (scanType === 'in') {
      if (record && record.clockInTime) {
        return res.json({
          alreadyClockedIn: true,
          message: `${empName} is already clocked in today at ${new Date(record.clockInTime).toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata' })}`,
          record,
        });
      }
      record = new Attendance({
        employeeId: user._id,
        employeeEmail: email,
        employeeName: empName,
        role: user.role,
        department: dept,
        date: todayDate,
        clockInTime: now,
        scanMethod,
        notes,
      });
      record.calculateShift();
      await record.save();
      actionTaken = 'in';
    } else if (scanType === 'out') {
      if (!record || !record.clockInTime) {
        return res.status(400).json({
          error: `Cannot clock out. No clock-in record found for ${empName} today.`,
        });
      }
      record.clockOutTime = now;
      record.scanMethod = scanMethod;
      if (notes) record.notes = notes;
      record.calculateShift();
      await record.save();
      actionTaken = 'out';
    } else {
      // Auto-detect: if no record or no clockInTime -> clock in. If clocked in without clockOutTime -> clock out.
      if (!record) {
        record = new Attendance({
          employeeId: user._id,
          employeeEmail: email,
          employeeName: empName,
          role: user.role,
          department: dept,
          date: todayDate,
          clockInTime: now,
          scanMethod,
          notes,
        });
        record.calculateShift();
        await record.save();
        actionTaken = 'in';
      } else if (!record.clockOutTime) {
        // Enforce at least 1 minute between In and Out scans
        const diffSecs = (now.getTime() - new Date(record.clockInTime).getTime()) / 1000;
        if (diffSecs < 30) {
          return res.json({
            alreadyClockedIn: true,
            message: `Just clocked in ${Math.round(diffSecs)}s ago. Please wait before clocking out.`,
            record,
            actionTaken: 'already_in',
          });
        }
        record.clockOutTime = now;
        record.scanMethod = scanMethod;
        if (notes) record.notes = notes;
        record.calculateShift();
        await record.save();
        actionTaken = 'out';
      } else {
        // Already clocked in and out
        return res.json({
          alreadyCompleted: true,
          message: `${empName} has already completed shift today (${record.regularHours}h regular, ${record.overtimeHours}h OT).`,
          record,
          actionTaken: 'already_completed',
        });
      }
    }

    res.json({
      success: true,
      actionTaken,
      message: actionTaken === 'in'
        ? `Clock-In Recorded for ${empName} at ${now.toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata' })}`
        : `Clock-Out Recorded for ${empName}. Total: ${(record.totalDurationMinutes / 60).toFixed(1)} hrs (${record.regularHours}h Basic, ${record.overtimeHours}h OT)`,
      record,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/attendance/verify-camera-frame (Live webcam biometric recognition)
router.post('/verify-camera-frame', async (req, res) => {
  try {
    const { image, scanType = 'auto', notes } = req.body;
    if (!image) {
      return res.status(400).json({ success: false, error: 'Camera image frame is required' });
    }

    // 1. Fetch enrolled employees
    const enrolledUsers = await User.find(
      { isFaceEnrolled: true, faceEmbeddings: { $exists: true, $ne: [] } },
      'email name department role faceEmbeddings facePhotoUrl'
    ).lean();

    if (enrolledUsers.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No employees are enrolled with face biometrics in database yet.',
      });
    }

    // 2. Run face_recognizer.py match
    const pyScript = path.join(__dirname, '..', 'scripts', 'face_recognizer.py');
    const pyProcess = spawn('python3', [pyScript, 'match']);

    let stdoutData = '';
    let stderrData = '';

    const payload = JSON.stringify({
      queryImage: image,
      enrolled: enrolledUsers,
    });

    pyProcess.stdin.write(payload);
    pyProcess.stdin.end();

    pyProcess.stdout.on('data', data => {
      stdoutData += data.toString();
    });

    pyProcess.stderr.on('data', data => {
      stderrData += data.toString();
    });

    pyProcess.on('close', async () => {
      try {
        const lines = stdoutData.trim().split('\n');
        const lastLine = lines[lines.length - 1];
        if (!lastLine) {
          return res.status(500).json({ success: false, error: 'Recognition processing error', stderr: stderrData });
        }

        const matchResult = JSON.parse(lastLine);
        if (!matchResult.success || !matchResult.matched) {
          return res.json({
            success: true,
            matched: false,
            message: matchResult.error || matchResult.message || 'Face not recognized. Please face the camera squarely.',
          });
        }

        const matchedEmp = matchResult.employee;
        const email = matchedEmp.email;

        const user = await User.findOne({ email }).lean();
        const def = DEFAULT_EMPLOYEE_DETAILS[email] || {};
        const empName = user.name || def.name || email.split('@')[0];
        const dept = user.department || def.department || 'Production';

        const todayDate = getTodayDateStr();
        const now = new Date();

        let record = await Attendance.findOne({ employeeEmail: email, date: todayDate });
        let actionTaken = 'in';

        if (scanType === 'in') {
          if (record && record.clockInTime) {
            return res.json({
              success: true,
              matched: true,
              alreadyClockedIn: true,
              employee: { ...matchedEmp, name: empName, department: dept, photoUrl: user.facePhotoUrl },
              message: `${empName} is already clocked in today at ${new Date(record.clockInTime).toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata' })}`,
              record,
              actionTaken: 'already_in',
            });
          }
          record = new Attendance({
            employeeId: user._id,
            employeeEmail: email,
            employeeName: empName,
            role: user.role,
            department: dept,
            date: todayDate,
            clockInTime: now,
            scanMethod: 'face_recognition',
            notes,
          });
          record.calculateShift();
          await record.save();
          actionTaken = 'in';
        } else if (scanType === 'out') {
          if (!record || !record.clockInTime) {
            return res.status(400).json({
              success: false,
              matched: true,
              error: `Cannot clock out. No clock-in record found for ${empName} today.`,
            });
          }
          record.clockOutTime = now;
          record.scanMethod = 'face_recognition';
          if (notes) record.notes = notes;
          record.calculateShift();
          await record.save();
          actionTaken = 'out';
        } else {
          // Auto
          if (!record) {
            record = new Attendance({
              employeeId: user._id,
              employeeEmail: email,
              employeeName: empName,
              role: user.role,
              department: dept,
              date: todayDate,
              clockInTime: now,
              scanMethod: 'face_recognition',
              notes,
            });
            record.calculateShift();
            await record.save();
            actionTaken = 'in';
          } else if (!record.clockOutTime) {
            const diffSecs = (now.getTime() - new Date(record.clockInTime).getTime()) / 1000;
            if (diffSecs < 10) {
              return res.json({
                success: true,
                matched: true,
                alreadyClockedIn: true,
                employee: { ...matchedEmp, name: empName, department: dept, photoUrl: user.facePhotoUrl },
                message: `Just clocked in ${Math.round(diffSecs)}s ago. Please wait before clocking out.`,
                record,
                actionTaken: 'already_in',
              });
            }
            record.clockOutTime = now;
            record.scanMethod = 'face_recognition';
            if (notes) record.notes = notes;
            record.calculateShift();
            await record.save();
            actionTaken = 'out';
          } else {
            return res.json({
              success: true,
              matched: true,
              alreadyCompleted: true,
              employee: { ...matchedEmp, name: empName, department: dept, photoUrl: user.facePhotoUrl },
              message: `${empName} has already completed shift today (${record.regularHours}h regular, ${record.overtimeHours}h OT).`,
              record,
              actionTaken: 'already_completed',
            });
          }
        }

        return res.json({
          success: true,
          matched: true,
          actionTaken,
          score: matchResult.score,
          employee: {
            ...matchedEmp,
            name: empName,
            department: dept,
            photoUrl: user.facePhotoUrl,
          },
          message: actionTaken === 'in'
            ? `Clock-In Verified for ${empName} at ${now.toLocaleTimeString('en-IN', { timeZone: 'Asia/Kolkata' })}`
            : `Clock-Out Verified for ${empName}. Total: ${(record.totalDurationMinutes / 60).toFixed(1)} hrs (${record.regularHours}h Basic + ${record.overtimeHours}h Overtime)`,
          record,
        });
      } catch (err) {
        return res.status(500).json({ success: false, error: err.message });
      }
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// GET /api/attendance/today
router.get('/today', async (req, res) => {
  try {
    const today = getTodayDateStr();
    const records = await Attendance.find({ date: today }).sort({ updatedAt: -1 }).lean();
    res.json(records);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/attendance/history
router.get('/history', async (req, res) => {
  try {
    const { date, month, email } = req.query;
    const filter = {};
    if (date) filter.date = date;
    if (month) filter.date = { $regex: `^${month}` }; // e.g. "2026-11"
    if (email) filter.employeeEmail = email;

    const records = await Attendance.find(filter).sort({ date: -1, clockInTime: -1 }).lean();
    res.json(records);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/attendance/summary?month=YYYY-MM
router.get('/summary', async (req, res) => {
  try {
    const { month } = req.query;
    const currentMonth = month || getTodayDateStr().slice(0, 7); // e.g. "2026-11"

    const records = await Attendance.find({
      date: { $regex: `^${currentMonth}` },
    }).lean();

    const summaryByEmployee = {};

    for (const r of records) {
      if (!summaryByEmployee[r.employeeEmail]) {
        summaryByEmployee[r.employeeEmail] = {
          employeeEmail: r.employeeEmail,
          employeeName: r.employeeName,
          role: r.role,
          department: r.department,
          daysWorked: 0,
          totalDurationMinutes: 0,
          totalRegularHours: 0,
          totalOvertimeHours: 0,
          records: [],
        };
      }

      const s = summaryByEmployee[r.employeeEmail];
      if (r.clockInTime) s.daysWorked += 1;
      s.totalDurationMinutes += r.totalDurationMinutes || 0;
      s.totalRegularHours += r.regularHours || 0;
      s.totalOvertimeHours += r.overtimeHours || 0;
      s.records.push(r);
    }

    const summaryList = Object.values(summaryByEmployee).map(s => ({
      ...s,
      totalRegularHours: parseFloat(s.totalRegularHours.toFixed(2)),
      totalOvertimeHours: parseFloat(s.totalOvertimeHours.toFixed(2)),
      totalHours: parseFloat(((s.totalDurationMinutes || 0) / 60.0).toFixed(2)),
    }));

    res.json({
      month: currentMonth,
      summary: summaryList,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/attendance/:id
router.delete('/:id', async (req, res) => {
  try {
    const deleted = await Attendance.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Record not found' });
    res.json({ success: true, message: 'Attendance record deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
