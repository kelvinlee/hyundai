// Generated by CoffeeScript 1.7.1
var admin, home;

home = require('./controllers/home');

admin = require('./controllers/admin');

module.exports = function(app) {
  app.get('/', home.index);
  app.get('/success', home.success);
  app.get('/backcode', home.backcode);
  app.post("/regs", home.post);
  app.get('/super', admin.superlogin);
  app.post('/super', admin.superloginpost);
  app.get('/super/index', admin["super"]);
  app.get('/dealer', admin["in"]);
  app.get('/admin/*', admin.before);
  app.get('/admin/index', admin.index);
  app.get('/admin/next', admin.next);
  app.get('/admin/dealer', admin.dealer);
  app.get('/admin/password', admin.changepassword);
  app.get('/admin/out', admin.out);
  app.post('/admin/password', admin.pocp);
  app.post('/admin/dealer/reser/:user_id', admin.dealerreser);
  app.get('/admin/dealer/active', admin.dealeractive);
  app.get('/admin/dealer/info', admin.dealerinfo);
  app.get('/admin/dealer/nine', admin.nine);
  app.get('/admin/dealer/nine/:id', admin.nineid);
  app.post('/admin/dealer/nine', admin.ninepost);
  app.post('/admin/dealer/infopost', admin.dealerinfopost);
  app.post('/admin/in', admin.inpost);
  return app.get('*', home.notfind);
};
