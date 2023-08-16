const router = require("express").Router();
const authorize = require("../middlewares/auth.middleware");
const fs = require("fs");

const uploadsDir = "uploads";

router.post("/", authorize([]), async (req, res) => {
    try {
      // console.log(req.query)
      // console.log(req.headers)
      let task = req.query["task"];
      let username = req.query["username"];
      let timestamp = req.query["timestamp"];
      let currentTimestamp = Date.now();
      console.log(`username: ${username} task: ${task} timestamp: ${timestamp} currentTimestamp: ${currentTimestamp}`);
      
      try {
        // Create uploads dir if it doesn't exist
        if(!fs.existsSync(uploadsDir)) {
          fs.mkdirSync(uploadsDir);
        }

        
        let userFileUploadPath = uploadsDir + "/" + task + "#" + username + "@" + currentTimestamp;
        let file = req.files.file;
        if(file.size < 50000) {
          file.mv(userFileUploadPath, function(err) {
            if (err)
              return res.status(500).send(err);
            console.log('File uploaded!');
          })
        }

      } catch (error) {
        console.log(error);
      }


      // Extract query params for valid redirect
      let queryObject = req.query;
      let queryObjectPropsArray = [];
      for(var prop in queryObject)
        queryObjectPropsArray.push(prop + "=" + queryObject[prop]);
      let queryObjectString = queryObjectPropsArray.join('&');
  
      return res.redirect("/?" + queryObjectString);
      return res.redirect("/?" + queryObjectString + "&loading=true");
  
    } catch (error) {
      console.log(error);
      return res.status(500).json({ error_message: "Internal server error! You fu**ed up smth! :)" });
    }
  });

module.exports = router;
