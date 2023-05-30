const mysql = require('mysql2/promise');
require('dotenv').config()

const {
  DB_HOSTNAME: host,
  DB_USERNAME: user,
  DB_PASSWORD: password,
  DB_DATABASE: database,
  DB_PORT: port = 33306
} = process.env;

console.log("process.env = ", process.env)

const connectDb = async (req, res, next) => {
  try {
    req.conn = await mysql.createConnection({ host, user, password, database, port })
    console.log("DB연결 완료");
    next()
  }
  catch(e) {
    console.log(e)
    res.status(500).json({ message: "데이터베이스 연결 오류" })
  }
}

const getProduct = (sku) => `
  SELECT BIN_TO_UUID(product_id) as product_id, name, price, stock, BIN_TO_UUID(factory_id), BIN_TO_UUID(ad_id)
  FROM product
  WHERE sku = "${sku}"
`

const setStock = (productId, stock) => `
  UPDATE product SET stock = ${stock} WHERE product_id = UUID_TO_BIN('${productId}')
`

module.exports = {
  connectDb,
  queries: {
    getProduct,
    setStock
  }
}