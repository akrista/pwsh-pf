# 🎨 Pretty PowerShell

A clean, modern PowerShell profile designed to make Windows terminals feel fast, polished, and closer to a modern Linux shell experience.

## Requirements

The setup script will automatically verify these prerequisites before installation:

- **Git SCM** (https://git-scm.com/install/windows) - Required for version control
- **PowerShell 7+** (https://github.com/powershell/powershell/releases) - PowerShell Core is required to run this profile

If either prerequisite is missing, the script will provide installation instructions and exit.

## ⚡ One Line Install (Elevated PowerShell Recommended)

Execute the following command in an elevated PowerShell window to install the PowerShell profile:

```
irm "https://github.com/akrista/pwsh-pf/raw/master/setup.ps1" | iex
```

## 📦 What Gets Installed

The setup script intelligently checks for existing installations and only installs what's missing:

### Package Managers
- **Chocolatey** - Windows package manager
- **Scoop** - Command-line installer (with extras bucket)

### Terminal Tools & Utilities
- **Oh My Posh** - Prompt theme engine
- **Terminal-Icons** - PowerShell module for file/folder icons
- **zoxide** - Smarter cd command with frecency
- **bat** - Cat clone with syntax highlighting
- **gsudo** - Sudo for Windows
- **ripgrep** - Extremely fast text search
- **fd** - Simple, fast alternative to find
- **gitui** - Blazing fast terminal UI for git

### Fonts & Themes
- **CaskaydiaCove NF** - Nerd Font automatically installed
- **lambdageneration** Oh My Posh theme

### Configuration
- PowerShell profile automatically configured
- Execution policy set to `Unrestricted` for CurrentUser scope (allows profiles to run)

**Note:** The setup script will skip any programs already installed on your system, making it safe to run multiple times.

## 🛠️ Fix the Missing Font (Alternative Methods)

After running the script, you'll have two options for installing a font patched to support icons in PowerShell:

### 1) You will find a downloaded `cove.zip` file in the folder you executed the script from. Follow these steps to install the patched `Caskaydia Cove` nerd font family:

1. Extract the `cove.zip` file.
2. Locate and install the nerd fonts.

### 2) With `oh-my-posh` (loaded automatically through the PowerShell profile script hosted on this repo):
1. Run the command `oh-my-posh font install`
2. A list of Nerd Fonts will appear like so:
<pre>
PS> oh-my-posh font install

   Select font

  > 0xProto
    3270
    Agave
    AnonymousPro
    Arimo
    AurulentSansMono
    BigBlueTerminal
    BitstreamVeraSansMono

    •••••••••
    ↑/k up • ↓/j down • q quit • ? more</pre>
3. With the up/down arrow keys, select the font you would like to install and press <kbd>ENTER</kbd>
4. DONE!
   
## Customize this profile

**Do not make any changes to the `Microsoft.PowerShell_profile.ps1` file**, since it's hashed and automatically overwritten by any commits to this repository.

After the profile is installed and active, run the `Edit-Profile` function to create a separate profile file [`profile.ps1`] for your current user. Add any custom code, and/or override VARIABLES/FUNCTIONS in `Microsoft.PowerShell_profile.ps1` by adding any of the following Variable or Function names:

THE FOLLOWING VARIABLES RESPECT _Override:
<pre>
$EDITOR_Override
$debug_Override
$repo_root_Override  [To point to a fork, for example]
$timeFilePath_Override
$updateInterval_Override
</pre>

THE FOLLOWING FUNCTIONS RESPECT _Override: _(do not call the original function from your override function, or you'll create an infinite loop)_
<pre>
Debug-Message_Override
Update-Profile_Override
Update-PowerShell_Override
Clear-Cache_Override
Get-Theme_Override
WinUtilDev_Override [To call a fork, for example]
</pre>
