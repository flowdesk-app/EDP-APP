const r1 = new RegExp('\\bFLA', 'i');
const r2 = new RegExp('\\bFLA\\b', 'i');

console.log(r1.test("ATC-FLAT")); // true
console.log(r2.test("ATC-FLAT")); // false
