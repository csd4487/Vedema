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

//schemas
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

const profitSchema = new mongoose.Schema({
  sacks: Number,
  price: Number,
}, { _id: false });

const otherExpenseSchema = new mongoose.Schema({
  task: String,
  date: String,
  cost: Number,
  notes: String,
}, { _id: false });

const fieldSchema = new mongoose.Schema({
  location: String,
  size: Number,
  oliveNo: Number,
  cubics: Number,
  price: Number,
  species: String,
  expenses: [expenseSchema],
  profits: [profitSchema],
  totalExpenses: Number,
  totalProfits: Number,
}, { _id: false });

const userSchema = new mongoose.Schema({
  firstname: String,
  lastname: String,
  email: { type: String, required: true },
  password: { type: String, required: true },
  fields: [fieldSchema],
  totalExpenses: Number,
  totalProfits: Number,
  otherExpenses: [otherExpenseSchema],
  notes: [noteSchema],
});

const User = mongoose.model('User', userSchema);


app.get('/', (req, res) => {
  res.send('Backend server is running!');
});

app.post('/api/signup', async (req, res) => {
  try {
    const { email, firstname, lastname, password } = req.body;
    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(409).json({ message: 'Email already in use' });

    const newUser = new User({ firstname, lastname, email, password, fields: [] });
    await newUser.save();
    res.status(201).json({ message: 'SignUp completed successfully!' });
  } catch (error) {
    res.status(500).json({ message: 'Error creating user', error: error.message });
  }
});

app.post('/api/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
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
    const requiredFields = ['task', 'date', 'cost', 'synthesis', 'type', 'npk', 'notes', 'location'];
    for (const field of requiredFields)
      if (!expenseData[field]) return res.status(400).json({ message: `Missing: ${field}` });

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const field = user.fields.find(f => f.location === expenseData.location);
    if (!field) return res.status(404).json({ message: 'Field not found' });

    field.expenses.push({ ...expenseData });
    field.totalExpenses += Number(expenseData.cost);
    user.totalExpenses += Number(expenseData.cost);

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


app.post('/api/getDefaultAnalytics', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const expenseSummary = {
      Fertilization: 0,
      Spraying: 0,
      Irrigation: 0,
      Other: 0,
    };

    let fieldMostExpenses = '';
    let maxExpenses = 0;
    let fieldExpenseBreakdown = {};

    let fieldMostProfits = '';
    let maxProfits = 0;
    let sacksOfTopField = 0;

    // Process all fields
    user.fields.forEach(field => {
      let fieldExpenses = 0;
      const taskBreakdown = {
        Fertilization: 0,
        Spraying: 0,
        Irrigation: 0,
        Other: 0,
      };

      // Calculate field expenses
      field.expenses.forEach(expense => {
        const cost = expense.cost;
        fieldExpenses += cost;

        if (expense.task === 'Fertilization') {
          expenseSummary.Fertilization += cost;
          taskBreakdown.Fertilization += cost;
        } else if (expense.task === 'Spraying') {
          expenseSummary.Spraying += cost;
          taskBreakdown.Spraying += cost;
        } else if (expense.task === 'Irrigation') {
          expenseSummary.Irrigation += cost;
          taskBreakdown.Irrigation += cost;
        } else {
          expenseSummary.Other += cost;
          taskBreakdown.Other += cost;
        }
      });

      // field with most expenses
      if (fieldExpenses > maxExpenses || fieldMostExpenses === '') {
        maxExpenses = fieldExpenses;
        fieldMostExpenses = field.location;
        fieldExpenseBreakdown = taskBreakdown;
      }

      // Calculate profits 
      let fieldProfits = 0;
      let sacks = 0;
      field.profits.forEach(p => {
        fieldProfits += p.price * p.sacks;
        sacks += p.sacks;
      });

      if (fieldProfits > maxProfits || fieldMostProfits === '') {
        maxProfits = fieldProfits;
        fieldMostProfits = field.location;
        sacksOfTopField = sacks;
      }
    });

    // Process other expenses
    user.otherExpenses.forEach(other => {
      expenseSummary.Other += other.cost;
    });

    res.status(200).json({
      expenseSummary,
      fieldWithMostExpenses: fieldMostExpenses || 'No fields',
      maxExpenses,
      expenseBreakdown: fieldExpenseBreakdown,
      fieldWithMostProfits: fieldMostProfits || 'No fields',
      maxProfits,
      sacksSold: sacksOfTopField,
    });
  } catch (error) {
    res.status(500).json({ 
      message: 'Error generating analytics', 
      error: error.message 
    });
  }
});




app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running at: http://192.168.1.2:${PORT}`);
});
