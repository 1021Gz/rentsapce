const app = require('./app');

const port = Number(process.env.PORT || 3000);
if (require.main === module) {
  app.listen(port, () => {
    console.log('RentSpace MySQL API Server listening on http://localhost:' + port);
  });
}

module.exports = app;
