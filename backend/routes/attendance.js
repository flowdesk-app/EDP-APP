const express = require('express');
const router = express.Router();
const { spawn } = require('child_process');
const path = require('path');
const Attendance = require('../models/Attendance');
const User = require('../models/User');

const getTodayDateStr = () => {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(new Date());
};

const FACTORY_EMPLOYEES = [
  { empNo: "20004", name: "K.RAMA", designation: "WORKS MANAGER", department: "Production", email: "20004@flowdesk.com" },
  { empNo: "20005", name: "R.RAJESWARI", designation: "ADMIN MANAGER", department: "Admin", email: "20005@flowdesk.com" },
  { empNo: "20008", name: "DILSHATH PEGUM", designation: "PRODUCTION EXECUTIVE", department: "Production", email: "20008@flowdesk.com" },
  { empNo: "20011", name: "A.NAGARAJAN", designation: "MARKETING EXECUTIVE", department: "Marketing", email: "20011@flowdesk.com" },
  { empNo: "20026", name: "C.SUBHALAKSHMI", designation: "MANAGER - ACCOUNTS", department: "Accounts", email: "20026@flowdesk.com" },
  { empNo: "20028", name: "S.CHANDRAMOULI", designation: "MANAGER - PRODUCTION", department: "Production", email: "20028@flowdesk.com" },
  { empNo: "20029", name: "S.REBEKKA", designation: "PRODUCTION EXECUTIVE", department: "Production", email: "20029@flowdesk.com" },
  { empNo: "20034", name: "KAMAKSHI D", designation: "MANAGER - ADMIN", department: "Admin", email: "20034@flowdesk.com" },
  { empNo: "20036", name: "GHOSIA", designation: "PRODUCTION ASSISTANT", department: "Production", email: "20036@flowdesk.com" },
  { empNo: "20041", name: "PITHAM MARNDI", designation: "PRODUCTION ASSISTANT", department: "Production", email: "20041@flowdesk.com" },
  { empNo: "20042", name: "KANTHAROOPI", designation: "PRODUCTION ASSISTANT", department: "Production", email: "20042@flowdesk.com" },
  { empNo: "20043", name: "RAMAMURTHY", designation: "DRIVER", department: "Logistics", email: "20043@flowdesk.com" },
  { empNo: "20045", name: "RENTA", designation: "PRODUCTION ASSISTANT", department: "Production", email: "20045@flowdesk.com" },
  { empNo: "20046", name: "CHANDRAY SOREN", designation: "PRODUCTION ASSISTANT", department: "Production", email: "20046@flowdesk.com" },
  { empNo: "20047", name: "SURAI", designation: "PRODUCTION ASSISTANT", department: "Production", email: "20047@flowdesk.com" },
  { empNo: "20048", name: "MAHESH G", designation: "ADMIN EXECUTIVE", department: "Admin", email: "20048@flowdesk.com" }
];

async function ensureFactoryEmployees() {
  const count = await User.countDocuments({ empNo: { $exists: true } });
  if (count < 16) {
    for (const emp of FACTORY_EMPLOYEES) {
      let u = await User.findOne({ $or: [{ empNo: emp.empNo }, { email: emp.email }] });
      if (!u) {
        u = new User({
          empNo: emp.empNo,
          email: emp.email,
          name: emp.name,
          designation: emp.designation,
          department: emp.department,
          password: 'password123',
          role: 'employee',
          isFaceEnrolled: false,
          faceEmbeddings: []
        });
        await u.save();
      } else {
        u.empNo = emp.empNo;
        u.name = emp.name;
        u.designation = emp.designation;
        u.department = emp.department;
        await u.save();
      }
    }
  }
}

// Helper to extract real face embedding vector using python SFace
function extractEmbeddingFromBase64(b64) {
  return new Promise((resolve) => {
    try {
      const pyScript = path.join(__dirname, '..', 'scripts', 'face_recognizer.py');
      const pyProcess = spawn('python3', [pyScript, 'extract-base64']);
      let stdout = '';
      pyProcess.stdin.write(JSON.stringify({ image: b64 }));
      pyProcess.stdin.end();
      pyProcess.stdout.on('data', d => stdout += d.toString());
      pyProcess.on('close', code => {
        if (code === 0 && stdout) {
          try {
            const res = JSON.parse(stdout.trim().split('\n').pop());
            if (res.success && Array.isArray(res.feature)) {
              return resolve(res.feature);
            }
          } catch (_) {}
        }
        resolve(null);
      });
    } catch (_) {
      resolve(null);
    }
  });
}

// GET /api/attendance/enrolled-employees
router.get('/enrolled-employees', async (req, res) => {
  try {
    await ensureFactoryEmployees();
    const users = await User.find(
      { empNo: { $exists: true } },
      'empNo email name department designation role isFaceEnrolled faceEmbeddings facePhotoUrl lastEnrolledAt'
    ).sort({ empNo: 1 }).lean();

    const formatted = users.map(u => ({
      _id: u._id,
      empNo: u.empNo,
      email: u.email,
      name: u.name,
      department: u.department,
      designation: u.designation,
      role: u.role,
      isFaceEnrolled: !!u.isFaceEnrolled,
      faceEmbeddings: u.faceEmbeddings || [],
      facePhotoUrl: u.facePhotoUrl,
      lastEnrolledAt: u.lastEnrolledAt,
    }));

    res.json(formatted);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/attendance/enroll-face
router.post('/enroll-face', async (req, res) => {
  try {
    const { email, empNo, faceEmbeddings, facePhotoUrl, name, department } = req.body;
    const identifier = email || empNo;
    if (!identifier) {
      return res.status(400).json({ error: 'Employee email or empNo is required' });
    }

    const user = await User.findOne({
      $or: [{ email: identifier }, { empNo: identifier }]
    });
    if (!user) {
      return res.status(404).json({ error: 'Employee user not found' });
    }

    // Try extracting real SFace feature from the captured photo if provided
    let embeddingsToSave = faceEmbeddings;
    if (facePhotoUrl) {
      const extracted = await extractEmbeddingFromBase64(facePhotoUrl);
      if (extracted && extracted.length === 128) {
        embeddingsToSave = extracted;
      }
    }

    if (!Array.isArray(embeddingsToSave) || embeddingsToSave.length === 0) {
      return res.status(400).json({ error: 'No face detected in photo. Please ensure face is centered.' });
    }

    user.faceEmbeddings = embeddingsToSave;
    user.isFaceEnrolled = true;
    user.lastEnrolledAt = new Date();
    if (facePhotoUrl) user.facePhotoUrl = facePhotoUrl;
    if (name) user.name = name;
    if (department) user.department = department;

    await user.save();

    res.json({
      success: true,
      message: `Face enrolled successfully for ${user.name} (${user.empNo || user.email})`,
      user: {
        empNo: user.empNo,
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
      'empNo email name department designation role faceEmbeddings facePhotoUrl'
    ).lean();

    if (enrolledUsers.length === 0) {
      return res.json({
        success: false,
        matched: false,
        unregistered: true,
        error: 'Unregistered face detected. No employees have enrolled face biometrics yet. Attendance was NOT marked.',
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

    pyProcess.on('close', async (code) => {
      try {
        if (code !== 0) {
          console.error(`face_recognizer.py exited with code ${code}:`, stderrData);
          let friendlyError = 'Biometric AI engine encountered an error. Please try again.';
          if (stderrData.includes('No module named') || stderrData.includes('cv2')) {
            friendlyError = 'Face AI dependencies are initializing on the server. Please try again in 1-2 minutes.';
          }
          return res.status(500).json({ success: false, error: friendlyError, stderr: stderrData });
        }

        const lines = stdoutData.trim().split('\n');
        const lastLine = lines[lines.length - 1];
        if (!lastLine) {
          return res.status(500).json({ success: false, error: 'Recognition processing error', stderr: stderrData });
        }

        const matchResult = JSON.parse(lastLine);
        if (!matchResult.success || !matchResult.matched) {
          return res.json({
            success: false,
            matched: false,
            unregistered: true,
            error: 'Unregistered Face Detected. This face does not match any enrolled Exclusive Diamond Products employee. Attendance was NOT marked.',
          });
        }

        const matchedEmp = matchResult.employee;
        const email = matchedEmp.email;

        const user = await User.findOne({
          $or: [
            { email },
            ...(matchedEmp.empNo ? [{ empNo: matchedEmp.empNo }] : [])
          ]
        }).lean();
        const empName = user?.name || matchedEmp.name || email.split('@')[0];
        const dept = user?.department || matchedEmp.department || 'Production';

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
            return res.json({
              success: false,
              matched: true,
              employee: { ...matchedEmp, name: empName, department: dept, photoUrl: user.facePhotoUrl },
              error: `Cannot clock out. No clock-in record found for ${empName} today. Please scan Entry (Clock-In) first.`,
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
