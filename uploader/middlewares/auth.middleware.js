const moment = require("moment");
const crypto = require("crypto");
require('dotenv').config();
let salt = process.env.AUTH_SALT;

const authorize = (roles = []) => {
  return (req, res, next) => {
    try {
      console.log(`[${moment().add(3, 'hours').format("YYYY/MM/DD, hh:mm:ss")}] - AUTHORIZE - ${req.query["username"]}` );
      
      let expirationTime = 2 * 3600;
      let timestamp = req.query["timestamp"];
      res.setHeader("timestamp", timestamp);
      let username = req.query["username"];
      res.setHeader("username", username);
      let token = req.query["key"];

      if(timestamp + expirationTime < Date.now() / 1000) {
        console.log("Expired session!");
        throw "";
      }

      // TODO: This is a little insecure
      let computedDigest = crypto.createHash('md5').update(username + salt.trim() + timestamp).digest("hex");

      if(token !== computedDigest) {
        console.log("Invalid token!");
        return res.status(401).json({ error_message: "Access Denied" });
      }

      next();
    } catch (err) {
      console.log(err);
      return res.status(401).json({ error_message: "Access Denied" });
    }
  };
};

module.exports = authorize;
