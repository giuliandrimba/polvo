var colors, misc, pkg, single;
misc = {};
single = {};
colors = {};
pkg = function(ns) {
  var curr, index, part, parts, _len;
  curr = null;
  parts = [].concat = ns.split(".");
  for (index = 0, _len = parts.length; index < _len; index++) {
    part = parts[index];
    if (curr === null) {
      curr = eval(part);
      continue;
    } else {
      if (curr[part] == null) {
        curr = curr[part] = {};
      } else {
        curr = curr[part];
      }
    }
  }
  return curr;
};
document.write('<scri' + 'pt src="./toaster/src/misc/black.js"></scr' + 'ipt>');
document.write('<scri' + 'pt src="./toaster/src/single/script.js"></scr' + 'ipt>');
document.write('<scri' + 'pt src="./toaster/src/toplevel.js"></scr' + 'ipt>');
document.write('<scri' + 'pt src="./toaster/src/colors/black.js"></scr' + 'ipt>');
document.write('<scri' + 'pt src="./toaster/src/colors/red.js"></scr' + 'ipt>');
document.write('<scri' + 'pt src="./toaster/src/app.js"></scr' + 'ipt>');