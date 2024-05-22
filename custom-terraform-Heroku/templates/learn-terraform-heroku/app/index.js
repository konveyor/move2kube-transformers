/**
 * Copyright (c) HashiCorp, Inc.
 * SPDX-License-Identifier: MPL-2.0
 */

const express = require('express');
const pgp = require('pg-promise')();
// Set SSL to false
pgp.pg.defaults.ssl = {
  rejectUnauthorized: false
};

const port = process.env.PORT || 3000;
const db = pgp(process.env.DATABASE_URL)

var app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', function (_, res) {
  res.send('Hello World\n')
});

app.get('/db', async (_, res) => {
  db.any('SELECT key, value FROM test_table')
    .then(data => {
      res.send(data);
    })
    .catch(e => {
      res.send(`Unable to retrieve items from database: ${e}`);
    })
})

app.post('/db/seed', async (_, res) => {
  db.any('CREATE TABLE test_table(id SERIAL PRIMARY KEY, key VARCHAR NOT NULL UNIQUE, value VARCHAR);')
    .then(_ => {
      res.send("Successfully seeded database");
    })
    .catch(e => {
      res.send(`Unable to seed database: ${e}`);
    })
})


app.get('/db/query/:id', function (req, res) {
  const id = req.params.id;

  if (!id) {
    res.send("Please specify an ID")
    return;
  }
  db.any('SELECT key, value FROM test_table WHERE key=$1', id)
    .then(data => {
      res.send(data[0]);
    })
    .catch(e => {
      res.send(`Unable to retrieve item from database: ${e}`);
    })
});

app.post('/db/upsert', function (req, res) {
  for (const [key, value] of Object.entries(req.body)) {
    db.any('INSERT INTO test_table (key, value) VALUES($1, $2) ON CONFLICT (key) DO UPDATE SET value = $2', [key, value])
      .catch(e => {
        res.send(`Unable to insert item from database: ${e}`);
        return
      })
  }

  res.send("Added data to database");
});


app.listen(port, () => {
  console.log(`Server running on port :${port}`);
});
