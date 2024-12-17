require('dotenv').config();
const express = require("express");
const mongoose = require("mongoose");
const bcrypt = require("bcrypt");
const bodyParser = require("body-parser");
const jwt = require("jsonwebtoken");
const multer = require("multer");
const path = require("path");
const cors = require('cors');
const nodemailer = require("nodemailer");

const app = express();
app.use(bodyParser.json());
app.use(cors());
const PORT = process.env.PORT || 3000;

// Static folder to serve uploaded images
app.use("/uploads", express.static(path.join(__dirname, "uploads")));
const apkPath = path.join(__dirname, "uploads/app-release.apk");
// MongoDB connection
mongoose.connect("mongodb://127.0.0.1:27017/zucol")
  .then(() => console.log("MongoDB Connected"))
  .catch((err) => console.log(err));

const userSchema = new mongoose.Schema({
  username: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  profileImage: { type: String }, // For storing image path
});

const User = mongoose.model("User", userSchema);

// Multer configuration for image uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "uploads/"); // Save images to the 'uploads' folder
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + path.extname(file.originalname)); // Unique file name
  },
});
const upload = multer({ storage });
// const upload = multer({
//   storage,
//   fileFilter: function (req, file, cb) {
//     // Define valid file types
//     // const fileTypes = /jpeg|jpg|png/;
//     // const extName = fileTypes.test(path.extname(file.originalname).toLowerCase());
//     const mimeType = file.mimetype.startsWith('image/');

//     // Check if file is an image
//     if (mimeType) {
//       return cb(null, true);
//     } else {
//       // Reject non-image files
//       return cb(new Error("Only images are allowed (JPEG, JPG, PNG)"));
//     }
//   },
// });

// Signup Route with Profile Image
app.post("/api/signup", upload.single("profileImage"), async (req, res) => {
  const { username, email, phone, password } = req.body;

  if (!username || !email || !phone || !password) {
    return res.status(400).json({ message: "All fields are required" });
  }

  try {
    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: "Email already exists" });
    }

    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Handle profile image
    const profileImagePath = req.file ? `/uploads/${req.file.filename}` : "";

    // Save the user to the database
    const newUser = new User({
      username,
      email,
      phone,
      password: hashedPassword,
      profileImage: profileImagePath,
    });

    await newUser.save();

    // Generate a JWT token (optional)
    const token = jwt.sign({ id: newUser._id }, "your_jwt_secret", {
      expiresIn: "1d",
    });

    res.status(201).json({
      message: "User registered successfully",
      user: {
        id: newUser._id,
        username: newUser.username,
        email: newUser.email,
        phone: newUser.phone,
        profileImage: profileImagePath,
      },
      token,
    });
  } catch (error) {
    res.status(500).json({ message: "Internal server error", error: error.message });
  }
});

app.get('/user-details', (req, res) => {
  const token = req.headers['authorization']?.split(' ')[1]; // Expecting "Bearer <token>"

  if (!token) {
    return res.status(403).json({ message: 'No token provided' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(403).json({ message: 'Invalid token' });
    }

    const userId = decoded.userId;
    const user = users.find(u => u.id === userId);

    if (user) {
      res.json({
        username: user.username,
        email: user.email,
        phoneNumber: user.phoneNumber,
        profileImage: user.profileImage,
      });
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  });
});

app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    // Check if the user exists
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'User not found' });
    }

    // Compare the entered password with the stored password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // Send user details (No token, just user details)
    const userDetails = {
      id: user._id,  // Send the user ID
      username: user.username,
      email: user.email,
      phoneNumber: user.phoneNumber,
      profileImage: user.profileImage || '',
    };

    res.status(200).json({ userDetails });
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});




// Error handling for multer errors
app.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    return res.status(400).json({ message: err.message });
  } else if (err) {
    return res.status(400).json({ message: err.message });
  }
  next();
});

app.get('/user-details/:id', async (req, res) => {
  const userId = req.params.id;

  try {
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const userDetails = {
      username: user.username,
      email: user.email,
      phone: user.phone,
      profileImage: user.profileImage || '',
    };

    res.status(200).json(userDetails);
  } catch (err) {
    res.status(500).json({ message: 'Error retrieving user details' });
  }
});

app.put('/update-profile/:userId', upload.single('profileImage'), async (req, res) => {
  try {
    const userId = req.params.userId;

    // Find the user in the database
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Update user details
    if (req.body.username) user.username = req.body.username;
    if (req.body.email) user.email = req.body.email;
    if (req.body.phone) user.phone = req.body.phone;

    // Update profile image if a new one is uploaded
    if (req.file) {
      user.profileImage = `/uploads/${req.file.filename}`;
    }

    // Save the updated user
    await user.save();

    return res.status(200).json({
      message: 'Profile updated successfully',
      user,
    });
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ message: 'Failed to update profile', error });
  }
});
app.delete('/delete-user/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;

    // Find and delete the user
    const result = await User.findByIdAndDelete(userId);

    if (result) {
      res.status(200).json({ message: 'User deleted successfully' });
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});


app.get("/get-users", async (req, res) => {
  try {
    const users = await User.find();
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ error: "Failed to fetch users" });
  }
});

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "m.sethia465@gmail.com", // Replace with your email
    pass: "tkef xivi yqou hqeg",  // Replace with your app-specific password
  },
});

// Route to download APK
app.get("/download-apk", (req, res) => {
  res.download(apkPath, "app-release.apk", (err) => {
    if (err) {
      console.error("Error downloading APK:", err);
      res.status(500).send("Unable to download APK file.");
    }
  });
});

// Route to send email with APK link
app.get("/send-apk", async (req, res) => {
  const testerEmails = ["jmudit467@gmail.com", "jmudit66@gmail.com"]; // Add tester emails here

  const mailOptions = {
    from: "m.sethia65@gmail.com",
    to: testerEmails.join(", "),
    subject: "Download the Latest APK",
    text: `Hi, \n\nPlease click the link below to download the latest APK:\n\nhttp://localhost:${PORT}/download-apk\n\nThank you!`,
  };

  try {
    await transporter.sendMail(mailOptions);
    res.send("APK download link has been sent to testers!");
  } catch (error) {
    console.error("Error sending email:", error);
    res.status(500).send("Failed to send email.");
  }
});
// Start the server
app.listen(3000, () => {
  console.log("Server is running on port 3000");
});
