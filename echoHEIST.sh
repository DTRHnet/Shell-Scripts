#!/usr/bin/env sh                                     
#                                          Jan 14, 2025                                          
#                                 ADMIN]at[DTRH]dot[NET
#        █▀▀ █▀▀ █░░█ █▀▀█ ▒█░▒█ ▒█▀▀▀ ▀█▀ ▒█▀▀▀█ ▀▀█▀▀ 
#        █▀▀ █░░ █▀▀█ █░░█ ▒█▀▀█ ▒█▀▀▀ ▒█░ ░▀▀▀▄▄ ░▒█░░ 
#        ▀▀▀ ▀▀▀ ▀░░▀ ▀▀▀▀ ▒█░▒█ ▒█▄▄▄ ▄█▄ ▒█▄▄▄█ ░▒█░░
#  
#
#  REPLAY THE REQUEST AND OWN THE RESPONSE - EVERY SINGLE TIME!
#
# #############################################################

# PoC - Full writeup can be found at https://dtrh.net



# This code does the minimum to prove the concepts worth.
# While it would be fairly easy to implement web scraping techniques, or to
# parse lists of links, etc, at this moment its outside the scope. Therefore
# usage is simple. Execute the command from a linux shell, follow up with one
# parameter in the form of a URL, ideally 'quoated'  

usage() {
  echo "Usage: $0 <URL>"
  exit 1
}

# Check for URL argument
[ -z "$1" ] && usage

# URL Validation
# would go here..


# The input URL will be the easiest to rip the band name and song from so, lets
# handle that now. We will name the output file oFile, ensure it has the band and song name, as well
# as maintain its ID from Ultimate Guitar in case that may be important down the road.
iURL="$1"
oName=$(echo "$iURL" | sed -E 's|https://tabs.ultimate-guitar.com/tab/||' | sed 's|/|_|g' | sed -E 's/_GP.*//')

# Set the output file name with .gp5 extension
# NOTE  . Some of these files will be gpx, etc. That is functionality not added.
oFile="${oName}.gp5"
echo  "Generated file name: $oFile"

# Short and Sweet
echoHEIST() {
  # shellcheck disable=SC3037
  echo -e "Listening for web requests directed towards \033[1m'tabs.ultimate-guitar.com/download/public/'\033[0m"

  # Start Puppeteer to listen for network requests
  node -e "
    const puppeteer = require('puppeteer');
    const { exec } = require('child_process');

    (async () => {
      const browser = await puppeteer.launch({
        headless: false,
        executablePath: '/opt/chrome/chrome-linux/chrome',            // Path to your browser
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
      });

      const page = await browser.newPage();

      // Enable network request interception
      await page.setRequestInterception(true);
      page.on('request', (request) => {
        const url = request.url();

        // Match the desired request
        if (url.includes('tabs.ultimate-guitar.com/download/public/')) {
          console.log('Captured request: ' + url);

          // Rebuild the curl command
          const headers = Object.entries(request.headers())
            .map(([key, value]) => \`-H '\${key}: \${value}'\`)
            .join(' \\\n  ');

          const curlCommand = \`
            curl -s -k '\${url}' \\
              \${headers} \\
              --output ${oFile}
          \`;

          console.log('Executing curl command...');
          exec(curlCommand, (error, stdout, stderr) => {
            if (error) {
              console.error('Error:', error.message);
              return;
            }
            if (stderr) {
              console.error('Stderr:', stderr);
            }
            console.log('Download complete: ${oFile}');
            // vconsole.log('\x07'); // Beep on completion
          });
        }
        request.continue();
      });

      // Navigate to the provided URL
      console.log('Navigating to ' + '${iURL}');
      await page.goto('${iURL}', { waitUntil: 'networkidle2' });

      // Wait to ensure all requests are captured
      console.log('Waiting for network activity...');
      // await page.waitForTimeout(30000);

      await browser.close();
    })();
  "
}

echoHEIST   # Run it!
