const regex1 = new RegExp('ATC', 'i');
const regex2 = new RegExp('\\bATC\\b', 'i');

console.log(regex1.test("MATCODE")); // true
console.log(regex2.test("MATCODE")); // false
console.log(regex2.test("ATC-FLAT")); // true
console.log(regex2.test("ATC FLAT")); // true
console.log(regex2.test("ATC")); // true
