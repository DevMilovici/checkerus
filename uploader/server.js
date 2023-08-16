const dotenv = require("dotenv");
dotenv.config();
const path = require("path");
const fs = require("fs");
require('dotenv').config();

const authorize = require("./middlewares/auth.middleware");

const express = require("express");

const app = express();
app.set('view engine', 'ejs')

const https = require("https");
const fileUpload = require("express-fileupload");
const cors = require("cors");
const moment = require("moment");

// Middlewares
app.use(express.json());

// File upload middleware
app.use(fileUpload());

// CORS
app.use(cors());

// Basic stdout logger
let logger = (req, res, next) => {
    console.log(
        `[${moment().add(3, 'hours').format("YYYY/MM/DD, hh:mm:ss")}] - ${req.method} ${req.path}`
    );
    next();
};

app.use(logger);

// let's encrypt route
// app.use(express.static("public", { dotfiles: 'allow' }));
// ("/.well-known/acme-challenge/MTQrHCJ-Rxb08gm0gtVCiiJwPYA6TVRVbhaK_H3e0yI", (req, res) => {

// })

// Upload routes
const uploadRoute = require("./routes/upload");
app.use("/upload", uploadRoute);

// (B1) UPLOAD PAGE
app.get("/", authorize([]), (req, res) => { 
  try {
    let queryObject = req.query;
    let queryObjectPropsArray = [];
    for(var prop in queryObject)
      queryObjectPropsArray.push(prop + "=" + queryObject[prop]);
    let queryObjectString = queryObjectPropsArray.join('&');
    // console.log(queryObjectString)

    let rezultsArray = [];
    let rezultsFolder = "rezults" + "/" + req.query["task"] + "/" + req.query["username"];
    let uploadsFolder = "uploads";
    let bufferFolder = "buffer";
    let loading = req.query["loading"];

    if(fs.existsSync(uploadsFolder)) {
      let uploadsFolderEntries = fs.readdirSync(uploadsFolder);

      try {
        uploadsFolderEntries.forEach(file => {
          // console.log(`${uploadsFolder}/${file}`)
          if(file.includes(req.query.username)) {
            loading = 'true';
            return;
          }
        });      
      } catch (error) {
        console.log("ERROR: fs.existsSync(uploadsFolder)");
        loading = 'true';
      }
    }

    if(fs.existsSync(bufferFolder)) {
      let bufferFolderEntries = fs.readdirSync(bufferFolder);

      try {
        bufferFolderEntries.forEach(entry => {
          // console.log(`${bufferFolder}/${entry}`)
          let fileEntries = fs.readdirSync(`${bufferFolder}/${entry}`);
            fileEntries.forEach(file => {
              // console.log(`${bufferFolder}/${entry}/${file}`);
              if(file.includes(req.query["task"]) && file.includes(req.query["username"])) {
                loading = 'true';
                return;
              }
            })
        })
      } catch (error) {
        console.log("ERROR: fs.existsSync(bufferFolder)");
        loading = 'true';
      }
    }

    if(fs.existsSync(rezultsFolder)) {
      fs.readdirSync(rezultsFolder).forEach(file => {
        let rezultFile = rezultsFolder + "/" + file + "/rezult.txt";

        if(fs.existsSync(rezultFile)) {
          // console.log(rezultFile);
          let date = moment.unix(file / 1000).add(3, 'hours').format("YYYY.MM.DD HH:mm:ss");
          let rezultFileContent = fs.readFileSync(rezultFile, { encoding: 'utf8', flag: 'r' });
          rezultsArray.unshift({
            content: rezultFileContent,
            date: date
          });
        }
      });
    }


    res.render("upload", { queryObjectString: queryObjectString, rezults: rezultsArray, loading: loading });
  } catch (error) {
    console.log(error);
    return res.status(500).json({ error_message: "Internal server error! You f***ed up smth! :)" });
  }
});

let port = 443;

// Certificate
try {
  let sslActive = process.env.SSL_ACTIVE;
  if(sslActive == true) {
    let privateKeyPath = process.env.SSL_PRIVATE_KEY_PATH;
    const privateKey = fs.readFileSync(privateKeyPath, 'utf8');
    let certificatePath = process.env.SSL_CERTIFICATE_PATH;
    const certificate = fs.readFileSync(certificatePath, 'utf8');
    let chainPath = process.env.SSL_CHAIN_PATH;
    const ca = fs.readFileSync(chainPath, 'utf8');
    const credentials = {
      key: privateKey,
      cert: certificate,
      ca: ca
    };
    
    https
      .createServer(
        credentials, 
        app
      )
      .listen(port, () => {
        console.log(`Server up and listening on ${port}...`)
      });
  } else {
    throw "WARNING: SSL is not active!"
  }
} catch(error) {
  console.log(error);
  port = 88;
  app.listen(port, () => {
    console.log(`Server up and listening on ${port}...`);
  })
}