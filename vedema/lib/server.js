const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const nodemailer = require('nodemailer');
const moment = require('moment');

const app = express();
const PORT = 5000;

// CORS setup for mobile testing
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(bodyParser.json());

// MongoDB connection
const username = 'VedemaUser01';
const password = 'cDCDrP2bNSPL0UTH';
const clusterUrl = 'vedema.ykvag.mongodb.net';
const dbName = 'Vedema';

const mongoURI = `mongodb+srv://${username}:${password}@${clusterUrl}/${dbName}?retryWrites=true&w=majority&appName=Vedema`;

mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('MongoDB connected successfully!'))
.catch(err => console.error('MongoDB connection error:', err));

const noteSchema = new mongoose.Schema({
  text: String,
  date: String,
  emailSent: Boolean,
}, { _id: false });

const expenseSchema = new mongoose.Schema({
  task: String,
  date: String,
  cost: Number,
  synthesis: String,
  type: String,
  npk: String,
  notes: String,
}, { _id: false });

const otherExpenseSchema = new mongoose.Schema({
  task: String,
  date: String,
  cost: Number,
  notes: String,
}, { _id: false });


const otherProfitSchema = new mongoose.Schema({
  type: String,
  date: String,
  profitNo: Number,
  notes: String,
}, { _id: false });

const sackProductionSchema = new mongoose.Schema({
  sacks: Number,
  dateProduced: String,
}, { _id: false });

const oilProductionSchema = new mongoose.Schema({
  sacksUsed: Number,
  oilKg: Number,
  dateGrinded: String,
}, { _id: false });

const oilProfitSchema = new mongoose.Schema({
  oilKgSold: Number,
  pricePerKg: Number,
  totalEarned: Number,
  dateSold: String,
}, { _id: false });

const fieldSchema = new mongoose.Schema({
  location: String,
  size: Number,
  oliveNo: Number,
  cubics: Number,
  price: Number,
  species: String,
  expenses: [expenseSchema],
  sackProductions: [sackProductionSchema],
  oilProductions: [oilProductionSchema],
  oilProfits: [oilProfitSchema],
  totalExpenses: { type: Number, default: 0 },
  totalProfits: { type: Number, default: 0 },
  availableSacks: { type: Number, default: 0 },
  oilKg: { type: Number, default: 0 },
}, { _id: false });

const userSchema = new mongoose.Schema({
  firstname: String,
  lastname: String,
  email: { type: String, required: true },
  password: { type: String, required: true },
  fields: [fieldSchema],
  totalExpenses: { type: Number, default: 0 },
  totalProfits: { type: Number, default: 0 },
  otherExpenses: { type: [otherExpenseSchema], default: [] },
  otherProfits: { type: [otherProfitSchema], default: [] }, 
  notes: { type: [noteSchema], default: [] },
});

module.exports = mongoose.model('User', userSchema);


const User = mongoose.model('User', userSchema);



app.get('/', (req, res) => {
  res.send('Backend server is running!');
});

app.post('/api/signup', async (req, res) => {
  try {
    const { email, firstname, lastname, password } = req.body;
    const normalizedEmail = email.toLowerCase();

    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) return res.status(409).json({ message: 'Email already in use' });

    const newUser = new User({
      firstname,
      lastname,
      email: normalizedEmail,
      password,
      fields: [],
    });

    await newUser.save();
    res.status(201).json({ message: 'SignUp completed successfully!' });
  } catch (error) {
    res.status(500).json({ message: 'Error creating user', error: error.message });
  }
});


app.post('/api/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    const normalizedEmail = email.toLowerCase();

    const user = await User.findOne({ email: normalizedEmail });
    if (!user || password !== user.password)
      return res.status(401).json({ message: 'Invalid email or password' });

    res.status(200).json({
      message: 'Sign-in successful',
      user: {
        firstname: user.firstname,
        lastname: user.lastname,
        email: user.email,
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Error signing in', error: error.message });
  }
});


app.post('/api/addField', async (req, res) => {
  try {
    const { email, location, size, oliveNo, cubics, price, species } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.fields.push({
      location, size, oliveNo, cubics, price, species,
      expenses: [], profits: [], totalExpenses: 0, totalProfits: 0,
    });

    await user.save();
    res.status(200).json({ message: 'Field added successfully', user });
  } catch (error) {
    res.status(500).json({ message: 'Error adding field', error: error.message });
  }
});

app.post('/api/getFields', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.status(200).json({ fields: user.fields });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching fields', error: error.message });
  }
});

app.post('/api/addExpense', async (req, res) => {
  try {
    const { email, expenseData } = req.body;
    const requiredFields = ['task', 'date', 'cost', 'location'];

    for (const field of requiredFields) {
      if (!expenseData[field]) {
        return res.status(400).json({ message: `Missing: ${field}` });
      }
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const field = user.fields.find(f => f.location === expenseData.location);
    if (!field) return res.status(404).json({ message: 'Field not found' });


    const expenseToAdd = {
      task: expenseData.task,
      date: expenseData.date,
      cost: Number(expenseData.cost),
      location: expenseData.location,
      synthesis: expenseData.synthesis || '',
      type: expenseData.type || '',
      npk: expenseData.npk || '',
      notes: expenseData.notes || '',
    };

    field.expenses.push(expenseToAdd);
    field.totalExpenses = (field.totalExpenses || 0) + expenseToAdd.cost;
    user.totalExpenses = (user.totalExpenses || 0) + expenseToAdd.cost;

    await user.save();
    res.status(200).json({ message: 'Expense added successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error adding expense', error: error.message });
  }
});


app.post('/api/addExpenseSeparate', async (req, res) => {
  try {
    const { email, expenseData } = req.body;
    const requiredFields = ['task', 'date', 'cost'];

    for (const field of requiredFields) {
      if (!expenseData[field]) {
        return res.status(400).json({ message: `Missing: ${field}` });
      }
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const isOtherExpense = !expenseData.location || expenseData.location.trim() === '';

    if (isOtherExpense) {

      const otherExpenseToAdd = {
        task: expenseData.task,
        date: expenseData.date,
        cost: Number(expenseData.cost),
        notes: expenseData.notes || '',
      };

      user.otherExpenses.push(otherExpenseToAdd);
      user.totalExpenses = (user.totalExpenses || 0) + otherExpenseToAdd.cost;

      await user.save();
      return res.status(200).json({ message: 'Other expense added successfully' });
    }


    const field = user.fields.find(f => f.location === expenseData.location);
    if (!field) return res.status(404).json({ message: 'Field not found' });

    const expenseToAdd = {
      task: expenseData.task,
      date: expenseData.date,
      cost: Number(expenseData.cost),
      location: expenseData.location,
      synthesis: expenseData.synthesis || '',
      type: expenseData.type || '',
      npk: expenseData.npk || '',
      notes: expenseData.notes || '',
    };

    field.expenses.push(expenseToAdd);
    field.totalExpenses = (field.totalExpenses || 0) + expenseToAdd.cost;
    user.totalExpenses = (user.totalExpenses || 0) + expenseToAdd.cost;

    await user.save();
    res.status(200).json({ message: 'Expense added successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error adding expense', error: error.message });
  }
});


app.post('/api/getSingleField', async (req, res) => {
  const { email, location } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(404).json({ message: 'User not found' });

  const field = user.fields.find(f => f.location === location);
  if (!field) return res.status(404).json({ message: 'Field not found' });

  res.send({ field });
});

app.post('/api/addNote', async (req, res) => {
  try {
    const { user, note } = req.body;
    const { text, date, sendEmail } = note;

    if (!text || !date || !user?.email)
      return res.status(400).json({ message: 'Missing required fields' });

    const foundUser = await User.findOne({ email: user.email });
    if (!foundUser) return res.status(404).json({ message: 'User not found' });

    const newNote = { text, date, emailSent: false };
    foundUser.notes.push(newNote);
    await foundUser.save();

    const today = moment().format('YYYY-MM-DD');

    if (sendEmail && date === today) {
      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: 'vedema.notifications@gmail.com',
          pass: 'bmvxugxwuqnjkqwf',
        },
      });

      const mailOptions = {
        from: 'vedema.notifications@gmail.com',
        to: foundUser.email,
        subject: 'New Note from Vedema',
        text: `You have a new note: \n\n${text}\n\nDate: ${date}`,
      };

      transporter.sendMail(mailOptions, async (error) => {
        if (!error) {
          const addedNote = foundUser.notes.find(n => n.text === text && n.date === date);
          if (addedNote) addedNote.emailSent = true;
          await foundUser.save();
        }
        return res.status(200).json({ message: 'Note added', emailStatus: error ? 'failed' : 'sent' });
      });
    } else {
      res.status(200).json({ message: 'Note added without email' });
    }
  } catch (error) {
    res.status(500).json({ message: 'Error adding note', error: error.message });
  }
});

app.post('/api/getNotes', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.status(200).json({ notes: user.notes });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching notes', error: error.message });
  }
});

app.post('/api/checkTodayNotes', async (req, res) => {
  try {
    const { user } = req.body;
    const foundUser = await User.findOne({ email: user.email });
    if (!foundUser) return res.status(404).json({ message: 'User not found' });

    const today = moment().format('YYYY-MM-DD');
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: 'vedema.notifications@gmail.com',
        pass: 'bmvxugxwuqnjkqwf',
      },
    });

    let anyEmailSent = false;

    for (const note of foundUser.notes) {
      if (note.date === today && !note.emailSent) {
        await transporter.sendMail({
          from: 'vedema.notifications@gmail.com',
          to: foundUser.email,
          subject: 'Reminder Note from Vedema',
          text: `Reminder:\n\n${note.text}\n\nDate: ${note.date}`,
        });
        note.emailSent = true;
        anyEmailSent = true;
      }
    }

    if (anyEmailSent) await foundUser.save();
    res.status(200).json({ message: 'Today\'s notes checked' });
  } catch (error) {
    res.status(500).json({ message: 'Error checking notes', error: error.message });
  }
});

app.post('/api/deleteNote', async (req, res) => {
  try {
    const { email, text, date } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.notes = user.notes.filter(
      note => !(note.text === text && note.date === date)
    );

    await user.save();
    res.status(200).json({ message: 'Note deleted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error deleting note', error: error.message });
  }
});


app.post('/api/deleteField', async (req, res) => {
  try {
    const { email, location, size, oliveNo, cubics, price, species } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.fields = user.fields.filter(field =>
      !(
        field.location === location &&
        field.size === size &&
        field.oliveNo === oliveNo &&
        field.cubics === cubics &&
        field.price === price &&
        field.species === species
      )
    );

    await user.save();
    res.status(200).json({ message: 'Field deleted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error deleting field', error: error.message });
  }
});

function parseCustomDate(dateStr) {
  if (!dateStr || typeof dateStr !== 'string') return new Date('Invalid');
  const parts = dateStr.split('-');
  if (parts.length !== 3) return new Date('Invalid');

  const [day, month, year] = parts;
  return new Date(`${year}-${month}-${day}`);
}







app.post('/api/getAvailablePeriods', async (req, res) => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const allDates = [];

    user.fields.forEach(field => {
      field.expenses?.forEach(exp => allDates.push(new Date(exp.date)));
      field.profits?.forEach(profit => allDates.push(new Date(profit.date)));
    });

    user.otherExpenses?.forEach(exp => allDates.push(new Date(exp.date)));

    const periods = new Set();

    allDates.forEach(date => {
      const year = date.getFullYear();
      const month = date.getMonth() + 1;

      const startYear = month >= 9 ? year : year - 1;
      const endYear = startYear + 1;

      periods.add(`${startYear}-${endYear}`);
    });

    const sortedPeriods = Array.from(periods).sort((a, b) => {
      const [aStart] = a.split('-').map(Number);
      const [bStart] = b.split('-').map(Number);
      return bStart - aStart;
    });

    res.status(200).json({ periods: sortedPeriods });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error fetching periods', error: error.message });
  }
});


app.post('/api/getDefaultAnalytics', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const expenseSummary = {
      fertilization: 0,
      spraying: 0,
      irrigation: 0,
      other: 0,
    };

    const profitSummary = {
      oilsales: 0,
      sacksales: 0,
      other: 0,
    };

    let fieldMostExpenses = '';
    let maxExpenses = 0;
    let fieldExpenseBreakdown = {};

    let fieldMostProfits = '';
    let maxProfits = 0;
    let sacksOfTopField = 0;
    let oilKgOfTopField = 0;

    const fieldExpenseDetails = {};
    const fieldProfitDetails = {};

    const seasonStart = new Date('2024-09-01');
    const seasonEnd = new Date('2025-08-31');

    user.fields.forEach(field => {
      let fieldExpenses = 0;
      const taskBreakdown = {
        fertilization: 0,
        spraying: 0,
        irrigation: 0,
        other: 0,
      };

      fieldExpenseDetails[field.location] = {
        fertilization: 0,
        spraying: 0,
        irrigation: 0,
        other: 0,
      };

      fieldProfitDetails[field.location] = {
        oilsold: 0,
        sackssold: 0,
        other: 0,
      };

      field.expenses.forEach(expense => {
        const expenseDate = new Date(expense.date);
        if (isNaN(expenseDate)) return;

        if (expenseDate >= seasonStart && expenseDate <= seasonEnd) {
          const cost = parseFloat(expense.cost) || 0;
          fieldExpenses += cost;

          const task = expense.task?.toLowerCase();
          if (task === 'fertilization') {
            expenseSummary.fertilization += cost;
            taskBreakdown.fertilization += cost;
            fieldExpenseDetails[field.location].fertilization += cost;
          } else if (task === 'spraying') {
            expenseSummary.spraying += cost;
            taskBreakdown.spraying += cost;
            fieldExpenseDetails[field.location].spraying += cost;
          } else if (task === 'irrigation') {
            expenseSummary.irrigation += cost;
            taskBreakdown.irrigation += cost;
            fieldExpenseDetails[field.location].irrigation += cost;
          } else {
            expenseSummary.other += cost;
            taskBreakdown.other += cost;
            fieldExpenseDetails[field.location].other += cost;
          }
        }
      });

      if (fieldExpenses > maxExpenses || fieldMostExpenses === '') {
        maxExpenses = fieldExpenses;
        fieldMostExpenses = field.location;
        fieldExpenseBreakdown = taskBreakdown;
      }

      let fieldProfits = 0;
      let sacks = 0;
      let oilKg = 0;

      if (Array.isArray(field.oilProfits)) {
        field.oilProfits.forEach(p => {
          const profitDate = new Date(p.dateSold);
          if (isNaN(profitDate)) return;

          if (profitDate >= seasonStart && profitDate <= seasonEnd) {
            const oilQty = parseFloat(p.oilKgSold) || 0;
            const oilPrice = parseFloat(p.pricePerKg) || 0;
            const total = oilQty * oilPrice;
            fieldProfits += total;
            oilKg += oilQty;

            profitSummary.oilsales += total;
            fieldProfitDetails[field.location].oilsold += oilQty;
          }
        });
      }

      if (Array.isArray(field.sackProfits)) {
        field.sackProfits.forEach(p => {
          const profitDate = new Date(p.date);
          if (isNaN(profitDate)) return;

          if (profitDate >= seasonStart && profitDate <= seasonEnd) {
            const sacksNum = parseInt(p.sacks) || 0;
            const sackPrice = parseFloat(p.price) || 0;
            const total = sacksNum * sackPrice;
            fieldProfits += total;
            sacks += sacksNum;

            profitSummary.sacksales += total;
            fieldProfitDetails[field.location].sackssold += sacksNum;
          }
        });
      }

      if (fieldProfits > maxProfits || fieldMostProfits === '') {
        maxProfits = fieldProfits;
        fieldMostProfits = field.location;
        sacksOfTopField = sacks;
        oilKgOfTopField = oilKg;
      }
    });

    user.otherExpenses.forEach(other => {
      const otherDate = new Date(other.date);
      if (isNaN(otherDate)) return;

      if (otherDate >= seasonStart && otherDate <= seasonEnd) {
        expenseSummary.other += parseFloat(other.cost) || 0;
      }
    });

    user.otherProfits.forEach(other => {
      const otherDate = new Date(other.date);
      if (isNaN(otherDate)) return;

      if (otherDate >= seasonStart && otherDate <= seasonEnd) {
        const profit = parseFloat(other.profitNo) || 0;
        profitSummary.other += profit;

        const location = other.fieldLocation;
        if (location && fieldProfitDetails[location]) {
          fieldProfitDetails[location].other += profit;
        }
      }
    });

    const totalExpenses = Object.values(expenseSummary).reduce((a, b) => a + b, 0);
    const totalProfits = Object.values(profitSummary).reduce((a, b) => a + b, 0);

    res.status(200).json({
      expenseSummary,
      profitSummary,
      fieldWithMostExpenses: fieldMostExpenses || 'No fields',
      maxExpenses,
      expenseBreakdown: fieldExpenseBreakdown,
      fieldWithMostProfits: fieldMostProfits || 'No fields',
      maxProfits,
      sacksSold: sacksOfTopField,
      oilKgSold: oilKgOfTopField,
      totalExpenses,
      totalProfits,
      netProfit: totalProfits - totalExpenses,
      fieldExpenseDetails,
      fieldProfitDetails
    });
  } catch (error) {
    res.status(500).json({
      message: 'Error generating analytics',
      error: error.message,
    });
  }
});


app.post('/api/getFilteredAnalytics', async (req, res) => {
  try {
    const { email, period, viewType, selectedTasks, selectedFields } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const [startYear, endYear] = period.split('-').map(Number);
    const seasonStart = new Date(`${startYear}-09-01`);
    const seasonEnd = new Date(`${endYear}-08-31`);

    const expenseSummary = {
      fertilization: 0,
      spraying: 0,
      irrigation: 0,
      other: 0
    };
    const profitSummary = {
      oilsales: 0,
      sacksales: 0,
      other: 0
    };

    let fieldMostExpenses = '';
    let maxExpenses = 0;
    let fieldExpenseBreakdown = {};
    let fieldMostProfits = '';
    let maxProfits = 0;
    let sacksOfTopField = 0;
    let oilKgOfTopField = 0;

    const fieldExpenseDetails = {};
    const fieldProfitDetails = {};

    const fieldsToProcess = selectedFields?.length > 0
      ? user.fields.filter(field => selectedFields.includes(field.location))
      : user.fields;

    fieldsToProcess.forEach(field => {
      fieldExpenseDetails[field.location] = {
        fertilization: 0,
        spraying: 0,
        irrigation: 0,
        other: 0
      };

      fieldProfitDetails[field.location] = {
        oilsold: 0,
        sackssold: 0,
        other: 0
      };

      let fieldExpenses = 0;
      const taskBreakdown = {
        fertilization: 0,
        spraying: 0,
        irrigation: 0,
        other: 0
      };

      field.expenses.forEach(expense => {
        const expenseDate = new Date(expense.date);
        if (expenseDate >= seasonStart && expenseDate <= seasonEnd) {
          const cost = parseFloat(expense.cost) || 0;
          fieldExpenses += cost;

          const task = expense.task?.toLowerCase();
          switch (task) {
            case 'fertilization':
              expenseSummary.fertilization += cost;
              taskBreakdown.fertilization += cost;
              fieldExpenseDetails[field.location].fertilization += cost;
              break;
            case 'spraying':
              expenseSummary.spraying += cost;
              taskBreakdown.spraying += cost;
              fieldExpenseDetails[field.location].spraying += cost;
              break;
            case 'irrigation':
              expenseSummary.irrigation += cost;
              taskBreakdown.irrigation += cost;
              fieldExpenseDetails[field.location].irrigation += cost;
              break;
            default:
              expenseSummary.other += cost;
              taskBreakdown.other += cost;
              fieldExpenseDetails[field.location].other += cost;
              break;
          }
        }
      });

      if (fieldExpenses > maxExpenses || fieldMostExpenses === '') {
        maxExpenses = fieldExpenses;
        fieldMostExpenses = field.location;
        fieldExpenseBreakdown = taskBreakdown;
      }

      let fieldProfits = 0;
      let sacks = 0;
      let oilKg = 0;

      if (Array.isArray(field.oilProfits)) {
        field.oilProfits.forEach(p => {
          const profitDate = new Date(p.dateSold);
          if (profitDate >= seasonStart && profitDate <= seasonEnd) {
            const oilQty = parseFloat(p.oilKgSold) || 0;
            const oilPrice = parseFloat(p.pricePerKg) || 0;
            const total = oilQty * oilPrice;
            fieldProfits += total;
            oilKg += oilQty;

            profitSummary.oilsales += total;
            fieldProfitDetails[field.location].oilsold += oilQty;
          }
        });
      }

      if (Array.isArray(field.sackProfits)) {
        field.sackProfits.forEach(p => {
          const profitDate = new Date(p.date);
          if (profitDate >= seasonStart && profitDate <= seasonEnd) {
            const sacksNum = parseInt(p.sacks) || 0;
            const sackPrice = parseFloat(p.price) || 0;
            const total = sacksNum * sackPrice;
            fieldProfits += total;
            sacks += sacksNum;

            profitSummary.sacksales += total;
            fieldProfitDetails[field.location].sackssold += sacksNum;
          }
        });
      }

      if (fieldProfits > maxProfits || fieldMostProfits === '') {
        maxProfits = fieldProfits;
        fieldMostProfits = field.location;
        sacksOfTopField = sacks;
        oilKgOfTopField = oilKg;
      }
    });

    if (viewType === 'Both' || viewType === 'Expenses') {
      user.otherExpenses.forEach(other => {
        const otherDate = new Date(other.date);
        if (otherDate >= seasonStart && otherDate <= seasonEnd) {
          expenseSummary.other += parseFloat(other.cost) || 0;
        }
      });
    }

    if (viewType === 'Both' || viewType === 'Profits') {
      user.otherProfits.forEach(other => {
        const otherDate = new Date(other.date);
        if (otherDate >= seasonStart && otherDate <= seasonEnd) {
          const profit = parseFloat(other.profitNo) || 0;
          profitSummary.other += profit;
          const location = other.fieldLocation;
          if (location && fieldProfitDetails[location]) {
            fieldProfitDetails[location].other += profit;
          }
        }
      });
    }

    const filteredExpenseSummary = viewType === 'Profits' ? null : expenseSummary;
    const filteredProfitSummary = viewType === 'Expenses' ? null : profitSummary;

    const filteredFieldExpenseDetails = {};
    const filteredFieldProfitDetails = {};

    const fieldsToInclude = selectedFields?.length > 0
      ? selectedFields
      : user.fields.map(f => f.location);

    fieldsToInclude.forEach(location => {
      if (fieldExpenseDetails[location]) {
        filteredFieldExpenseDetails[location] = fieldExpenseDetails[location];
      }
      if (fieldProfitDetails[location]) {
        filteredFieldProfitDetails[location] = fieldProfitDetails[location];
      }
    });

    const totalExpenses = filteredExpenseSummary
      ? Object.values(filteredExpenseSummary).reduce((a, b) => a + b, 0)
      : null;

    const totalProfits = filteredProfitSummary
      ? Object.values(filteredProfitSummary).reduce((a, b) => a + b, 0)
      : null;

    const netProfit = (viewType === 'Both' && totalExpenses !== null && totalProfits !== null)
      ? totalProfits - totalExpenses
      : null;

    res.status(200).json({
      expenseSummary: filteredExpenseSummary,
      profitSummary: filteredProfitSummary,
      fieldWithMostExpenses: viewType === 'Profits' ? null : fieldMostExpenses || 'No fields',
      maxExpenses: viewType === 'Profits' ? null : maxExpenses,
      expenseBreakdown: viewType === 'Profits' ? null : fieldExpenseBreakdown,
      fieldWithMostProfits: viewType === 'Expenses' ? null : fieldMostProfits || 'No fields',
      maxProfits: viewType === 'Expenses' ? null : maxProfits,
      sacksSold: viewType === 'Expenses' ? null : sacksOfTopField,
      oilKgSold: viewType === 'Expenses' ? null : oilKgOfTopField,
      totalExpenses,
      totalProfits,
      netProfit,
      fieldExpenseDetails: viewType === 'Profits' ? null : filteredFieldExpenseDetails,
      fieldProfitDetails: viewType === 'Expenses' ? null : filteredFieldProfitDetails
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      message: 'Error fetching filtered analytics',
      error: error.message
    });
  }
});



app.post('/api/addFieldSacks', async (req, res) => {
  try {
    const { email, sackData } = req.body;
    const { location, sacks, date } = sackData;

    if (!email || !location || sacks == null || !date) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const field = user.fields.find(f => f.location === location);
    if (!field) return res.status(404).json({ message: 'Field not found' });


    field.sackProductions.push({ sacks, dateProduced: date });


    field.availableSacks = (field.availableSacks || 0) + sacks;

    await user.save();

    res.status(200).json({ message: 'Sacks added successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error adding sacks', error: error.message });
  }
});




app.post('/api/getAvailableSacks', async (req, res) => {
  try {
    const { email, location } = req.body;

    if (!email || !location) {
      return res.status(400).json({ message: 'Missing email or location' });
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const field = user.fields.find(f => f.location === location);
    if (!field) return res.status(404).json({ message: 'Field not found' });

    res.status(200).json({
      availableSacks: field.availableSacks,
      harvestDates: field.sackProductions.map(sp => sp.dateProduced),
    });
  } catch (error) {
    res.status(500).json({ message: 'Error retrieving available sacks', error: error.message });
  }
});


app.post('/api/grindSacks', async (req, res) => {
  try {
    const { email, location, sacksToGrind, oilKg, date } = req.body;

    if (!email || !location || sacksToGrind == null || oilKg == null || !date) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const field = user.fields.find(f => f.location === location);
    if (!field) return res.status(404).json({ message: 'Field not found' });

    if ((field.availableSacks || 0) < sacksToGrind) {
      return res.status(400).json({ message: 'Not enough sacks to grind' });
    }


    field.availableSacks -= sacksToGrind;


    field.oilKg = (field.oilKg || 0) + oilKg;


    field.oilProductions.push({
      sacksUsed: sacksToGrind,
      oilKg,
      dateGrinded: date,
    });

    await user.save();

    res.status(200).json({ message: 'Sacks ground into oil successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error grinding sacks', error: error.message });
  }
});




app.post('/api/getAvailableOil', async (req, res) => {
  try {
    const { email, location } = req.body;

    if (!email || !location) {
      return res.status(400).json({ message: 'Missing email or location' });
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const field = user.fields.find(f => f.location === location);
    if (!field) return res.status(404).json({ message: 'Field not found' });

    res.status(200).json({
      availableOilKg: field.oilKg,
      grindDates: field.oilProductions.map(op => op.dateGrinded),
    });
  } catch (error) {
    res.status(500).json({ message: 'Error retrieving available oil', error: error.message });
  }
});


app.post('/api/addSale', async (req, res) => {
  try {
    const { email, location, oilKgSold, pricePerKg, dateSold } = req.body;
    console.log('oilKgSold:', oilKgSold, 'pricePerKg:', pricePerKg);
    
    if (!email || !location || !oilKgSold || !pricePerKg || !dateSold) {
      console.log('Status: 400');
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      console.log('Status: 404 - User not found');
      return res.status(404).json({ message: 'User not found' });
    }

    const fieldIndex = user.fields.findIndex(f => f.location === location);
    if (fieldIndex === -1) {
      console.log('Status: 404 - Field not found');
      return res.status(404).json({ message: 'Field not found' });
    }

    const totalEarned = oilKgSold * pricePerKg;

    const newSale = {
      oilKgSold,
      pricePerKg,
      totalEarned,
      dateSold,
    };

    user.fields[fieldIndex].oilProfits.push(newSale);
    user.fields[fieldIndex].totalProfits += totalEarned;
    user.totalProfits += totalEarned;

    await user.save();
    
    console.log('Status: 200 - Sale recorded successfully');
    res.status(200).json({ 
      message: 'Sale recorded successfully',
      totalProfits: user.totalProfits
    });
  } catch (error) {
    console.log('Status: 500 - Error recording sale:', error.message);
    res.status(500).json({ 
      message: 'Error recording sale', 
      error: error.message 
    });
  }
});



app.post('/api/removeOil', async (req, res) => {
  try {
    const { email, location, oilKgToRemove } = req.body;
    
    if (!email || !location || !oilKgToRemove) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const fieldIndex = user.fields.findIndex(f => f.location === location);
    if (fieldIndex === -1) {
      return res.status(404).json({ message: 'Field not found' });
    }

    if (user.fields[fieldIndex].oilKg < oilKgToRemove) {
      return res.status(400).json({ message: 'Not enough oil available' });
    }

    user.fields[fieldIndex].oilKg -= oilKgToRemove;

    await user.save();

    res.status(200).json({ 
      message: 'Oil removed successfully',
      remainingOil: user.fields[fieldIndex].oilKg
    });
  } catch (error) {
    res.status(500).json({ 
      message: 'Error removing oil', 
      error: error.message 
    });
  }
});



app.post('/api/getProfitHistory', async (req, res) => {
  try {
    const { email, location } = req.body;


    if (!email || !location) {
      return res.status(400).json({ message: 'Missing email or location' });
    }


    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });


    const field = user.fields.find(f => f.location === location);
    if (!field) return res.status(404).json({ message: 'Field not found' });


    const history = [];


    field.sackProductions.forEach(production => {
      if (production.sacks > 0) {
        history.push({
          type: 'sacks',
          date: production.dateProduced || 'No date',
          sacks: production.sacks,
        });
      }
    });

  
    field.oilProductions.forEach(production => {
      if (production.oilKg > 0) {
        history.push({
          type: 'grind',
          date: production.dateGrinded || 'No date',
          sacksUsed: production.sacksUsed,
          oilKg: production.oilKg,
        });
      }
    });


    field.oilProfits.forEach(sale => {
      if (sale.oilKgSold > 0) {
        history.push({
          type: 'sale',
          date: sale.dateSold || 'No date',
          oilKg: sale.oilKgSold,
          pricePerKg: sale.pricePerKg,
          totalEarned: sale.totalEarned,
        });
      }
    });


    res.status(200).json({ history });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Error retrieving history', error: error.message });
  }
});


app.post('/api/deleteProfit', async (req, res) => {
  try {
    const { email, location, type, date, oilKg, sacks } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const oilKgNum = Number(oilKg);
    const sacksNum = Number(sacks);

    user.fields = user.fields.map(field => {
      if (field.location === location) {
        if (type === 'grind' && Array.isArray(field.oilProductions)) {

          field.oilProductions = field.oilProductions.filter(p => !(p.dateGrinded === date && p.oilKg === oilKgNum));
        } else if (type === 'sacks' && Array.isArray(field.sackProductions)) {
          field.sackProductions = field.sackProductions.filter(p => !(p.dateProduced === date && p.sacks === sacksNum));
        }
      }
      return field;
    });

    await user.save();
    res.status(200).json({ message: 'Profit deleted successfully' });
  } catch (error) {
    console.error('Error deleting profit:', error);
    res.status(500).json({ message: 'Error deleting profit', error: error.message });
  }
});

app.post('/api/deleteSale', async (req, res) => {
  try {
    const { email, location, date, oilKg } = req.body;
    

    if (!email || !location || !date || !oilKg) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });


    const field = user.fields.find(f => f.location === location);
    if (!field) return res.status(404).json({ message: 'Field not found' });


    const saleIndex = field.oilProfits.findIndex(
      s => s.dateSold === date && s.oilKgSold === oilKg
    );

    if (saleIndex === -1) {
      return res.status(404).json({ message: 'Sale not found' });
    }


    field.oilProfits.splice(saleIndex, 1);
    field.oilKg += parseFloat(oilKg); 

    await user.save();
    res.status(200).json({ message: 'Sale deleted successfully' });
  } catch (error) {
    console.error('Error deleting sale:', error);
    res.status(500).json({ 
      message: 'Error deleting sale', 
      error: error.message 
    });
  }
});



app.post('/api/deleteExpense', async (req, res) => {
  try {
    const { email, location, date, task, cost } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.fields = user.fields.map(field => {
      if (field.location === location && Array.isArray(field.expenses)) {
        field.expenses = field.expenses.filter(e => !(e.date === date && e.task === task && e.cost === cost));
      }
      return field;
    });

    await user.save();
    res.status(200).json({ message: 'Expense deleted successfully' });
  } catch (error) {
    console.error('Error deleting expense:', error);
    res.status(500).json({ message: 'Error deleting expense', error: error.message });
  }
});


app.post('/api/updateField', async (req, res) => {
  const { email, field } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const fieldIndex = user.fields.findIndex(f => f.location === field.location);
    if (fieldIndex === -1) return res.status(404).json({ message: 'Field not found' });


    user.fields[fieldIndex].size = field.size;
    user.fields[fieldIndex].oliveNo = field.oliveNo;
    user.fields[fieldIndex].species = field.species;
    user.fields[fieldIndex].cubics = field.cubics;
    user.fields[fieldIndex].price = field.price;

    await user.save();

    res.send({ message: 'Field updated successfully' });
  } catch (err) {
    console.error('Error updating field:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});



app.post('/api/getTotalAvailableSacks', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const totalSacks = user.fields.reduce((sum, field) => sum + field.availableSacks, 0);
    res.status(200).json({ totalAvailableSacks: totalSacks });
  } catch (error) {
    res.status(500).json({ message: 'Error retrieving total sacks', error: error.message });
  }
});


app.post('/api/getTotalAvailableOil', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const totalOil = user.fields.reduce((sum, field) => sum + field.oilKg, 0);
    res.status(200).json({ totalAvailableOilKg: totalOil });
  } catch (error) {
    res.status(500).json({ message: 'Error retrieving total oil', error: error.message });
  }
});


app.post('/api/getOtherProfits', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    res.status(200).json({ 
      otherProfits: user.otherProfits 
    });
  } catch (error) {
    res.status(500).json({ 
      message: 'Error retrieving other profits', 
      error: error.message 
    });
  }
});


app.post('/api/getAllProfitHistory', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const history = [];


    user.fields.forEach(field => {

      field.sackProductions.forEach(production => {
        if (production.sacks > 0) {
          history.push({
            location: field.location,
            type: 'sacks',
            date: production.dateProduced || 'No date',
            sacks: production.sacks,
          });
        }
      });


      field.oilProductions.forEach(production => {
        if (production.oilKg > 0) {
          history.push({
            location: field.location,
            type: 'grind',
            date: production.dateGrinded || 'No date',
            sacksUsed: production.sacksUsed,
            oilKg: production.oilKg,
          });
        }
      });


      field.oilProfits.forEach(sale => {
        if (sale.oilKgSold > 0) {
          history.push({
            location: field.location,
            type: 'sale',
            date: sale.dateSold || 'No date',
            oilKg: sale.oilKgSold,
            pricePerKg: sale.pricePerKg,
            totalEarned: sale.totalEarned,
          });
        }
      });
    });


    user.otherProfits.forEach(profit => {
      history.push({
        type: 'other',
        location: 'General',
        profitType: profit.type,
        date: profit.date || 'No date',
        profitNo: profit.profitNo,
        notes: profit.notes,
      });
    });


    history.sort((a, b) => new Date(b.date) - new Date(a.date));

    res.status(200).json({ history });
  } catch (error) {
    res.status(500).json({ 
      message: 'Error retrieving profit history', 
      error: error.message 
    });
  }
});


app.post('/api/getOtherExpenses', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({
      otherExpenses: user.otherExpenses || [],
    });
  } catch (error) {
    res.status(500).json({ 
      message: 'Error fetching other expenses',
      error: error.message 
    });
  }
});


app.post('/api/getAllHistory', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const history = [];


    user.fields.forEach(field => {
      field.expenses.forEach(expense => {
        history.push({
          type: 'expense',
          location: field.location,
          task: expense.task,
          date: expense.date,
          cost: expense.cost,
          synthesis: expense.synthesis,
          notes: expense.notes,
          isOther: false,
        });
      });
    });


    user.otherExpenses.forEach(expense => {
      history.push({
        type: 'expense',
        location: 'General',
        task: expense.task,
        date: expense.date,
        cost: expense.cost,
        notes: expense.notes,
        isOther: true,
      });
    });


    user.fields.forEach(field => {
      field.sackProductions.forEach(production => {
        if (production.sacks > 0) {
          history.push({
            type: 'sacks',
            location: field.location,
            date: production.dateProduced || 'No date',
            sacks: production.sacks,
          });
        }
      });

      field.oilProductions.forEach(production => {
        if (production.oilKg > 0) {
          history.push({
            type: 'grind',
            location: field.location,
            date: production.dateGrinded || 'No date',
            sacksUsed: production.sacksUsed,
            oilKg: production.oilKg,
          });
        }
      });

      field.oilProfits.forEach(profit => {
        if (profit.oilKgSold > 0) {
          history.push({
            type: 'sale',
            location: field.location,
            date: profit.dateSold || 'No date',
            oilKg: profit.oilKgSold,
            pricePerKg: profit.pricePerKg,
            totalEarned: profit.totalEarned,
          });
        }
      });
    });


    history.sort((a, b) => new Date(b.date) - new Date(a.date));

    res.status(200).json({ history });
  } catch (error) {
    res.status(500).json({ 
      message: 'Error fetching combined history',
      error: error.message 
    });
  }
});


app.post('/api/addOtherProfit', async (req, res) => {
  try {
    const { email, otherProfitData } = req.body;


    const requiredFields = ['type', 'date', 'profitNo'];
    for (const field of requiredFields) {
      if (!otherProfitData[field]) {
        return res.status(400).json({ message: `Missing: ${field}` });
      }
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });


    const profitToAdd = {
      type: otherProfitData.type,
      date: otherProfitData.date,
      profitNo: Number(otherProfitData.profitNo),
      notes: otherProfitData.notes || ''
    };

    console.log(Number(otherProfitData.profitNo))
    user.otherProfits.push(profitToAdd);
    user.totalProfits = (user.totalProfits || 0) + profitToAdd.profitNo;

    await user.save();

    res.status(200).json({ message: 'Other profit added successfully' });
  } catch (error) {
    console.error('Error saving other profit:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});





app.post('/api/deleteOtherProfit', async (req, res) => {
  try {
    const { email, type, date, profitNo } = req.body;
    
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });


    const profitIndex = user.otherProfits.findIndex(
      p => p.type === type && p.date === date && p.profitNo === profitNo
    );

    if (profitIndex === -1) {
      return res.status(404).json({ message: 'Profit not found' });
    }

    user.otherProfits.splice(profitIndex, 1);
    await user.save();

    res.status(200).json({ message: 'Profit deleted successfully' });
  } catch (error) {
    res.status(500).json({ 
      message: 'Error retrieving profit history', 
      error: error.message 
    });
  }
});


app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running at: http://192.168.1.2:${PORT}`);
});