const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../lib/screens/owner');
const files = fs.readdirSync(dir).filter(f => f.endsWith('.dart') && f !== 'main_layout.dart');

for (const file of files) {
  const p = path.join(dir, file);
  let content = fs.readFileSync(p, 'utf8');
  
  let modified = false;
  
  // Find appBar: AppBar( ... )
  // This is a naive replace, but we only have standard AppBars.
  // Actually, we can search for `appBar: AppBar(` and then find the first `actions: [` inside it.
  
  const appBarRegex = /appBar:\s*AppBar\s*\(([\s\S]*?)(?=\n\s*(?:body|bottomNavigationBar|floatingActionButton|drawer|\]|\);))/g;
  
  content = content.replace(appBarRegex, (match, inner) => {
    if (inner.includes('actions: [')) {
      modified = true;
      return match.replace('actions: [', 'actions: [\n          const GlobalLogoutButton(),');
    } else {
      // If it doesn't have actions, we can add it right after title
      modified = true;
      return match.replace(/title:\s*([^\n]+),/, 'title: $1,\n        actions: [const GlobalLogoutButton()],');
    }
  });

  if (modified) {
    if (!content.includes('global_logout_button.dart')) {
      content = "import '../../widgets/global_logout_button.dart';\n" + content;
    }
    fs.writeFileSync(p, content);
    console.log('Modified ' + file);
  }
}
