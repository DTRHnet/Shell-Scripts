---

# Windows Environment Bootstrap Scripts

## Overview

This repository aims to provide a **quick and automated** way to set up a Windows environment with all the tools, configurations, and tweaks that I (the author) personally use. By cloning this repository and running the provided script(s), you can easily spin up a new system with minimal manual intervention.

> **Note**: This project is currently in development (v0.0.1). Although it is already functional (particularly the hardening portion), it is recommended to wait for an official release for a more complete setup experience.

## Project Status & Stages

The setup process is divided into logical “stages,” which help organize and resume progress across system restarts. Windows often requires reboots during driver installations, system updates, etc. To handle this:

- **State Tracking**: A JSON file in the root directory records the progress of each stage.  
- **Automatic Continuation**: The script uses the Windows Registry to trigger itself after restarts, allowing the process to resume where it left off.

Planned stages include (in no particular order):

1. **System Updates**  
   - Check and install the latest Windows patches.
2. **System Drivers and Firmware**  
   - Install/update drivers (graphics, sound, etc.) and supporting frameworks (e.g., C++ redistributables).
3. **System Hardening** (currently ~90% implemented)  
   - Apply host blacklisting/whitelisting, set security restrictions, and more. (See “Credits” section for references.)
4. **System Tweaks**  
   - Adjust various Windows settings for performance improvements.
5. **WSL and Linux Distro Installation**  
   - Installs a base OS via WSL. (No further Linux environment configuration is provided at this time.)
6. **SSH Server**  
   - Install and configure an SSH server, pull in keys, and set up the SSH agent.
7. **Python Environments**  
   - Set up multiple `venv` environments for Python (including Python 2.7).
8. **Network**  
   - Configure VPN, TOR, and other network-related services.
9. **Other**  
   - Any additional tasks or refinements that may be added over time.

## How It Works

1. **Initial Launch**  
   - You run `setup.bat` (a Windows Batch script).  
   - This step is crucial because it leverages the native Windows shell environment to set Execution Policy bypasses for the main PowerShell script.

2. **Primary Script Execution**  
   - The main script, `[dtrh.net]Win10-bootstrap.ps1`, orchestrates the entire setup process.  
   - It dynamically creates folders and files as needed (e.g., a `hardening` folder for security scripts).

3. **Utilities & Logging**  
   - `utility.ps1` (in the root folder) houses all utility functions used by the script.  
   - A `logs` folder is created for log files, which are date-stamped to keep track of script outputs and errors.

4. **State Persistence**  
   - The script maintains a `state.json` file that records which stage was completed and which is next.  
   - Upon reboot, the script can detect its progress and continue from the correct stage without user intervention.

### Current Version (v0.0.1)

- **Focus**: This version primarily includes **system hardening scripts**.  
- **Recommendation**: Although functional for its specific purpose, you may want to wait for a more comprehensive release if you need a fuller environment setup.

---

## Credits

- Portions of the hardening scripts are sourced or inspired by:  
  - [atlantsecurity/windows-hardening-scripts](https://github.com/atlantsecurity/windows-hardening-scripts)  
  - [Alirobe’s Reclaim Windows 10](https://gist.github.com/alirobe/7f3b34ad89a159e6daa1)

---

## License

MIT

---

> **Disclaimer**: Use these scripts at your own risk. While they aim to streamline a Windows setup, changes applied—particularly in the hardening process—can significantly alter system behavior. Always review the code and scripts to ensure they align with your security and workflow requirements.
