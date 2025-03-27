const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const PORT = 5000;

app.use(cors({
  origin: 'http://10.0.2.2', // for android emulator
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(bodyParser.json());

// MongoDB Atlas Connection
const username = 'VedemaUser01'; // MongoDB Atlas username
const password = 'cDCDrP2bNSPL0UTH'; // MongoDB Atlas password
const clusterUrl = 'vedema.ykvag.mongodb.net'; // Cluster URL
const dbName = 'Vedema'; // Database name

const mongoURI = `mongodb+srv://${username}:${password}@${clusterUrl}/${dbName}?retryWrites=true&w=majority&appName=Vedema`;

mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('MongoDB connected successfully!'))
.catch(err => console.error('MongoDB connection error:', err));

// Define the Field schema
const fieldSchema = new mongoose.Schema({
  location: String,
  size: Number,
  oliveNo: Number,
  cubics: Number,
  price: Number,
});

// Define the User schema
const userSchema = new mongoose.Schema({
  firstname: String,
  lastname: String,
  email: String,
  password: String,
  fields: [fieldSchema], 
});

// Create the User model
const User = mongoose.model('User', userSchema);

// Root endpoint
app.get('/', (req, res) => {
  res.send('Backend server is running!');
});

// Signup 
app.post('/api/signup', async (req, res) => {
  try {
    const { email, firstname, lastname, password } = req.body;

    // Check if the email already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ message: 'Email already in use' });
    }

    // If email doesn't exist, create a new user
    const newUser = new User({
      firstname,
      lastname,
      email,
      password,
      fields: [], 
    });

    await newUser.save();
    res.status(201).json({ message: 'SignUp completed successfully!' });
  } catch (error) {
    res.status(500).json({ message: 'Error creating user', error: error.message });
  }
});

// Signin 
app.post('/api/signin', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Check if the user exists
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    if (password !== user.password) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

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

//add new field
app.post('/api/addField', async (req, res) => {
  try {
    const { email, location, size, oliveNo, cubics, price } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const newField = {
      location,
      size,
      oliveNo,
      cubics,
      price,
    };

    user.fields.push(newField);

    // Save the updated user
    await user.save();

    res.status(200).json({ message: 'Field added successfully', user });
  } catch (error) {
    res.status(500).json({ message: 'Error adding field', error: error.message });
  }
});


// Get all fields for a user
app.post('/api/getFields', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({ fields: user.fields });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching fields', error: error.message });
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});