#!/bin/bash

# Check for Homebrew, install if we don't have it.
if [[ ! $(command -v brew) ]]; then
    echo "Installing Homebrew..."
    CI=true /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    # Turn off analytics.
    brew analytics off
fi

# Check for oh-my-zsh, install if we don't have it.
if [[ ! -d ~/.oh-my-zsh ]]; then
    echo "Installing oh-my-zsh..."
    RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

# Ask for super user permissions.
sudo -v

# Keep the sudo session alive for the duration of this script.
while true; do sudo -n true; sleep 60; kill -0 $$ || exit; done 2>/dev/null &

# Keep the computer awake for the duration of this script.
[[ $(command -v caffeinate) ]] && caffeinate -dusw $$ &

# Set up vars.
export MODEL_NAME=$(system_profiler SPHardwareDataType -detailLevel mini | grep "Model Name:" | sed -E 's/^.*:[[:space:]]+//')
export MACOS_VERSION=$(sw_vers -productVersion)
export ICLOUD_DRIVE=$(test -d ~/Library/Mobile\ Documents/com~apple~CloudDocs && echo "$_")

# Disable macOS update notifications.
test -d /Library/Bundles/OSXNotification.bundle && mv "$_" "$_.ignored"

# Copy keyboard layout.
test -f ../Amalgamation.keylayout/Amalgamation.keylayout \
    && sudo cp "$_" "/Library/Keyboard Layouts/" \
    && echo "Copied keyboard layout"

# Create iCloud shortcut.
[[ $ICLOUD_DRIVE ]] \
    && test ! -e ~/iCloud\ Drive \
    && ln -s "$ICLOUD_DRIVE" "$_" \
    && chflags -h hidden "$_"

# Kick off iCloud download for config directory.
find "$ICLOUD_DRIVE/.config" -name '*.icloud' -exec brctl download {} \;
secrets() { test -x "$ICLOUD_DRIVE/.config/secrets.sh" && "$_" "$1" || exit 1; }
secrets pre

# Configuring macOS ......................................................{{{1

# Close System Preferences so nothing gets overwritten again.
osascript -e 'tell application "System Preferences" to quit' >/dev/null 2>&1

# System
sudo pmset -b tcpkeepalive 0                                                                          # Disable TCP keep alives when asleep (like from Find My Mac)
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist AutomaticDownload -bool false # Disable automatic update downloads
#sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName                # Display IP address, hostname or OS version when pressing the login's clock (doesn't work)
#sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true              # Show language in menu at login
#sudo nvram SystemAudioVolume=" "                                                                     # Disable boot sound

# General
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false                                    # Enable repeating when holding a key down.
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"                             # Hide thicker column lines and show scrollbars only when scrolling
defaults write NSGlobalDomain NSCloseAlwaysConfirmsChanges -bool true                                 # Ask whether changes should be kept
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool true                                     # Restore a program's opened tabs on its next launch

# Dock
defaults write com.apple.dock magnification -bool true                                                # Magnify dock on hover
defaults write com.apple.dock tilesize -int 45                                                        # Regular size
defaults write com.apple.dock largesize -int 70                                                       # Magnification size
#defaults write com.apple.dock launchanim -bool false                                                 # Don???t animate opening apps
defaults write com.apple.dock minimize-to-application -bool true                                      # Minimize apps to their dock icon
defaults write com.apple.dock show-process-indicators -bool true                                      # Show little dots under dock icons
defaults write com.apple.dock show-recents -bool false                                                # Don't show recent apps
defaults write com.apple.dock autohide -bool true                                                     # Automatically hide dock
#defaults write com.apple.dock autohide-delay -float 0                                                # Adjust autohide reaction delay
#defaults write com.apple.dock autohide-time-modifier -float 0                                        # Adjust autohide delay
defaults write NSGlobalDomain AppleWindowTabbingMode -string "always"                                 # Always open documents in tabs

# Mission Control
defaults write com.apple.dock mru-spaces -bool false                                                  # Don't automatically rearrange spaces based on most recent use
#defaults write NSGlobalDomain AppleSpacesSwitchOnActivate -bool false                                # Don't switch to a space with open windows for the application when switching to an application
defaults write com.apple.dock expose-group-apps -bool true                                            # Group windows by app
if [[ "v$MACOS_VERSION" < "v10.15" ]]; then
    defaults write com.apple.dashboard mcx-disabled -bool true                                        # Disable dashboard completely
fi

# Keyboard
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true                                   # Enable using f-keys directly
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2                                              # Enable Tab in system dialogs

# Trackpad
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2                                     # Change pointer speed, requires logging out!
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true                                  # Enable tapping for clicking
defaults write com.apple.AppleBluetoothMultitouch.trackpad Clicking -bool true                        # ^
defaults write com.apple.dock showAppExposeGestureEnabled -bool true                                  # Enable App-Expos??

# Mouse
defaults write com.apple.universalaccess mouseDriverCursorSize -float 1.25                            # Change cursor size, requires logging out!
defaults write NSGlobalDomain com.apple.mouse.scaling -float 1.6                                      # Change pointer speed
defaults write com.apple.AppleMultitouchMouse MouseButtonMode -string "TwoButton"                     # Enable right-click

# Sound
#defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -bool false                            # Disable system sounds

# Menu
if [[ "v$MACOS_VERSION" < "v10.15" ]]; then
    defaults write com.apple.menuextra.battery ShowPercent -string "YES"                              # Show battery percentage
    defaults write com.apple.menuextra.textinput ModeNameVisible -bool false                          # Don't show input-layout
else
    defaults write com.apple.TextInputMenu visible -bool false                                        # Don't show input-layout
fi

# Finder
defaults write com.apple.finder QuitMenuItem -bool true                                               # Make it closable
defaults write com.apple.finder NewWindowTarget -string "PfHm"                                        # Set the default location for new windows
                                                                                                      # PfCm for Computer
                                                                                                      # PfVo for HDD
                                                                                                      # PfHm for Home
                                                                                                      # PfDe for Desktop
                                                                                                      # PfLo for Custom
#defaults write com.apple.finder NewWindowTargetPath -string "file:///fullpath/"                      # ^ when PfLo
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"                                   # Change view in all windows by default
                                                                                                      # icnv for icon view
                                                                                                      # Nlsv for list view
                                                                                                      # clmv for column view
                                                                                                      # Flwv for gallery view
defaults write com.apple.finder ShowPathbar -bool true                                                # Show path breadcrumbs by default
defaults write com.apple.finder ShowStatusBar -bool true                                              # Show status at bottom by default
#defaults write com.apple.finder AppleShowAllFiles -bool true                                         # Show hidden files by default (Cmd-Shift-period)

if [[ "v$MACOS_VERSION" < "v10.14" ]]; then
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true                                # Display full POSIX path as window title
fi
defaults write com.apple.finder QLEnableTextSelection -bool true                                      # Allow text selection in Quick Look/Preview by default (doesn't work anymore)

defaults write NSGlobalDomain AppleShowAllExtensions -bool true                                       # Show all filename extensions by default
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false                            # Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableRemoveFromICloudDriveWarning -bool false                      # Disable the warning when removing from iCloud
defaults write com.apple.finder WarnOnEmptyTrash -bool false                                          # Disable the warning when emptying the thrash
defaults write com.apple.finder FXRemoveOldTrashItems -bool true                                      # Delete files in trash after 30 days
defaults write com.apple.finder _FXSortFoldersFirst -bool true                                        # Pin folders when sorting by name
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"                                   # Search the current folder by default

defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true                           # Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true                          # ^
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true                              # Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true                             # ^
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false                           # Save to disk (not to iCloud) by default

/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist # Enable snap-to-grid for icons on the desktop
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true                          # Avoid creation of .DS_Store files on network volumes
#defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true                             # Avoid creation of .DS_Store files on removable media
#chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library                                # Show the ~/Library folder
sudo chflags nohidden /Volumes                                                                        # Show the /Volumes folder

# Mail
defaults write com.apple.mail AutoFetch -bool true
defaults write com.apple.mail polltime -string "-1"                                                   # Automatically fetch new mails
defaults write com.apple.mail CalendarInviteRuleEnabled -bool true                                    # Automatically add invites to calender
defaults write com.apple.mail SuppressDeliveryFailure -bool true                                      # Retry sending later
defaults write com.apple.mail IndexJunk -bool true                                                    # Also search in spam
defaults write com.apple.mail ExpandPrivateAliases -bool true                                         # Show a group's members
defaults write com.apple.mail ColumnLayoutMessageList -bool true                                      # View mails in columns
defaults write com.apple.mail HighlightClosedThreads -bool true                                       # Highlight conversations
defaults write com.apple.mail ShowBccHeader -bool true                                                # Show extra fields when writing a mail
defaults write com.apple.mail ShowCcHeader -bool true                                                 # ^
defaults write com.apple.mail ShowReplyToHeader -bool true                                            # ^
defaults write com.apple.mail BccSelf -bool true                                                      # Send copy to oneself

# iBooks
if [[ "v$MACOS_VERSION" < "v10.15" ]]; then
    defaults write com.apple.iBooksX BKPreventScreenDimmingPreferenceKey -bool true                   # Delay dimming while reading
    defaults write com.apple.iBooksX BKJustificationPreferenceKey -int 0                              # Naturally justify lines
    defaults write com.apple.iBooksX BKBookshelfViewControllerShowLabels -bool true                   # Show title and author
    defaults write com.apple.iBooksX BKBookshelfViewControllerSortAction -int 2                       # Sort by title instead of last time read
fi

# iCal
defaults write com.apple.iCal "Show Week Numbers" -bool true                                          # Show week numbers
defaults write com.apple.iCal "scroll by weeks in week view" -int 2                                   # Stop at today in week view
defaults write com.apple.iCal "Show heat map in Year View" -bool true                                 # Show dates in year view
defaults write com.apple.iCal CalendarSidebarShown -bool true                                         # Show sidebar
defaults write com.apple.iCal SharedCalendarNotificationsDisabled -bool false                         # Show notifications for shared calenders
defaults write com.apple.iCal "TimeZone support enabled" -bool true                                   # Show time zones

# Terminal
defaults write com.apple.terminal StringEncodings -array 4                                            # Enable UTF-8 ONLY
#defaults write com.apple.terminal "Default Window Settings" -string "Pro"                            # Select the Pro theme by default
#defaults write com.apple.terminal "Startup Window Settings" -string "Pro"                            # ^
#defaults write com.apple.terminal SecureKeyboardEntry -bool true                                     # Enable Secure Keyboard Entry, see: https://security.stackexchange.com/a/47786/8918

# Restart Apps to apply changes
killall Finder
killall Dock
killall Mail 2>/dev/null

# Reset apps' access rights.
#tccutil reset CoreLocationAgent # /var/db/locationd/clients.plist
#tccutil reset AddressBook
#tccutil reset Reminders
#tccutil reset Calendar

# .........................................................................}}}

# Set up hotkeys .........................................................{{{1

# Extra app hotkeys
#   ^ = Ctrl
#   @ = Cmd
#   $ = Shift
#   ~ = Option
test ! -e custommenu.hotkeys && defaults read com.apple.universalaccess com.apple.custommenu.apps -array NSGlobalDomain >"$_"
defaults write com.apple.universalaccess com.apple.custommenu.apps -array NSGlobalDomain \
    com.apple.finder         \
    com.apple.Notes          \
    com.apple.Preview        \
    com.operasoftware.Opera  \
    com.apple.mail           \
    com.apple.ActivityMonitor

# Global hotkeys
test ! -e global.hotkeys && defaults read NSGlobalDomain NSUserKeyEquivalents >"$_"
defaults delete NSGlobalDomain             NSUserKeyEquivalents 2>/dev/null
defaults write  NSGlobalDomain             NSUserKeyEquivalents -dict-add "Sleep"                           "@$\\Uf70f"
defaults write  NSGlobalDomain             NSUserKeyEquivalents -dict-add "Ruhezustand"                     "@$\\Uf70f"

# Finder hotkeys
test ! -e finder.hotkeys && defaults read com.apple.finder NSUserKeyEquivalents >"$_"
defaults delete com.apple.finder           NSUserKeyEquivalents 2>/dev/null
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Bring All to Front"              "~\\Uf70e"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Alle nach vorne bringen"         "~\\Uf70e"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Print"                           "@~r"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Drucken"                         "@~r"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "New Finder Window"               "@~^n"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Neues Fenster"                   "@~^n"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Tags..."                         "^t"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Tags ..."                        "^t"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Forward"                         "@'"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Vorw\\U00e4rts"                  "@'"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Back"                            "@;"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Zur\\U00fcck"                    "@;"

defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Recents"                         "@\$y"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Zuletzt benutzt"                 "@\$y"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Documents"                       "@\$s"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Dokumente"                       "@\$s"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Desktop"                         "@\$h"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Schreibtisch"                    "@\$h"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Downloads"                       "@~p"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Home"                            "@\$j"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Benutzerordner"                  "@\$j"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Library"                         "@\$p"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Computer"                        "@\$i"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "AirDrop"                         "@\$o"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Network"                         "@\$v"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Netzwerk"                        "@\$v"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "iCloud Drive"                    "@\$f"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Applications"                    "@\$a"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Programme"                       "@\$a"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Utilities"                       "@\$g"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Dienstprogramme"                 "@\$g"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Go to Folder"                    "@\$u"
defaults write  com.apple.finder           NSUserKeyEquivalents -dict-add "Gehe zum Ordner ..."             "@\$u"

# Notes hotkeys
test ! -e notes.hotkeys && defaults read com.apple.Notes NSUserKeyEquivalents >"$_"
defaults delete com.apple.Notes            NSUserKeyEquivalents 2>/dev/null
defaults write  com.apple.Notes            NSUserKeyEquivalents -dict-add "Strikethrough"                   "@\$u";
defaults write  com.apple.Notes            NSUserKeyEquivalents -dict-add "Durchgestrichen"                 "@\$u";

# Preview hotkeys
test ! -e preview.hotkeys && defaults read com.apple.Preview NSUserKeyEquivalents >"$_"
defaults delete com.apple.Preview          NSUserKeyEquivalents 2>/dev/null
defaults write  com.apple.Preview          NSUserKeyEquivalents -dict-add "Export as PDF..."                "~\$o"
defaults write  com.apple.Preview          NSUserKeyEquivalents -dict-add "Als PDF exportieren ..."         "~\$o"
defaults write  com.apple.Preview          NSUserKeyEquivalents -dict-add "Export As..."                    "@~s"
defaults write  com.apple.Preview          NSUserKeyEquivalents -dict-add "Exportieren ..."                 "@~s"
defaults write  com.apple.Preview          NSUserKeyEquivalents -dict-add "Adjust Size..."                  "@~g"
defaults write  com.apple.Preview          NSUserKeyEquivalents -dict-add "Gr\\U00f6\\U00dfenkorrektur ..." "@~g"
defaults write  com.apple.Preview          NSUserKeyEquivalents -dict-add "Save As..."                      "@\$s"
defaults write  com.apple.Preview          NSUserKeyEquivalents -dict-add "Sichern unter ..."               "@\$s"

# Opera hotkeys
test ! -e opera.hotkeys && defaults read com.operasoftware.Opera NSUserKeyEquivalents >"$_"
defaults delete com.operasoftware.Opera    NSUserKeyEquivalents 2>/dev/null
defaults write  com.operasoftware.Opera    NSUserKeyEquivalents -dict-add "Developer Tools"                 "@\$i"
defaults write  com.operasoftware.Opera    NSUserKeyEquivalents -dict-add "Entwicklerwerkzeuge"             "@\$i"
defaults write  com.operasoftware.Opera    NSUserKeyEquivalents -dict-add "Close Window"                    "@~w"
defaults write  com.operasoftware.Opera    NSUserKeyEquivalents -dict-add "Fenster schlie\\U00dfen"         "@~w"

# Mail hotkeys
test ! -e mail.hotkeys && defaults read com.apple.mail NSUserKeyEquivalents >"$_"
defaults delete com.apple.mail             NSUserKeyEquivalents 2>/dev/null
defaults write  com.apple.mail             NSUserKeyEquivalents -dict-add "Date"                            "@k"
defaults write  com.apple.mail             NSUserKeyEquivalents -dict-add "Datum"                           "@k"
defaults write  com.apple.mail             NSUserKeyEquivalents -dict-add "From"                            "@\$k"
defaults write  com.apple.mail             NSUserKeyEquivalents -dict-add "Von"                             "@\$k"
defaults write  com.apple.mail             NSUserKeyEquivalents -dict-add "Remove Style"                    "@\$b"
defaults write  com.apple.mail             NSUserKeyEquivalents -dict-add "Stil entfernen"                  "@\$b"

# Activity Monitor hotkeys
test ! -e activity_monitor.hotkeys && defaults read com.apple.ActivityMonitor NSUserKeyEquivalents >"$_"
defaults delete com.apple.ActivityMonitor  NSUserKeyEquivalents 2>/dev/null
defaults write  com.apple.ActivityMonitor  NSUserKeyEquivalents -dict-add "All Processes, Hierarchically"   "@1"
defaults write  com.apple.ActivityMonitor  NSUserKeyEquivalents -dict-add "Alle Prozesse, hierarchisch"     "@1"
defaults write  com.apple.ActivityMonitor  NSUserKeyEquivalents -dict-add "Windowed Processes"              "@2"
defaults write  com.apple.ActivityMonitor  NSUserKeyEquivalents -dict-add "Prozesse mit Fenstern"           "@2"

# .........................................................................}}}

# Install software and tools .............................................{{{1

# Install formulae and casks.
Brewfile=$(sed '1,/^__DATA__$/d' "$0"; secrets brewfile)
echo "$Brewfile" | brew bundle install --file=-
echo "$Brewfile" | brew bundle cleanup --file=- --force --zap
brew cleanup

# Install plug.vim.
test ! -e ~/.vim/autoload/plug.vim \
    && curl -fLo "$_" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install tpm for tmux.
[[ $(brew ls --versions tmux) ]] && test ! -e ~/.tmux/plugins/tpm \
    && git clone https://github.com/tmux-plugins/tpm "$_"

# Install flutter and dart.
if [[ ! -e ~/flutter ]]; then
    echo "Installing flutter..."
    suffix=$([[ $(uname -m) == "arm64" ]] && echo "_arm64")
    wget -O ~/dl.zip https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos"${suffix}"_3.3.4-stable.zip
    unzip -d ~ ~/dl.zip >/dev/null
    rm -f ~/dl.zip

    ~/flutter/bin/flutter config --no-analytics
    ~/flutter/bin/dart --disable-analytics

    if [[ $suffix ]]; then
        sudo softwareupdate --install-rosetta --agree-to-license
        sudo gem uninstall ffi
        sudo gem install ffi -- --enable-libffi-alloc
    fi
fi

# .........................................................................}}}

# Install various packages ...............................................{{{1

RUBY_GEMS=(
    #bundler
    #filewatcher
    #neovim-ruby-host
    #xcpretty
    asciidoctor
    cocoapods
    iStats
)

NPM_PACKAGES=(
    #marked
    bash-language-server
    dot-language-server
    neovim
    npm
    vim-language-server
    vscode-langservers-extracted
)

PIP3_PACKAGES=(
    #markdown
    #neovim-remote
    #virtualenv
    #virtualenvwrapper
    pynvim
)

PIP2_PACKAGES=(
    #ipython
    #pygments                  # for ccat
    #six                       # for lldb
    #virtualenv
    #virtualenvwrapper
)

CPAN_PACKAGES=(
    #Neovim::Ext               # broken since nvim 0.8, NVIM_LISTEN_ADDRESS is deprecated
    #Perl::LanguageServer
    Perl::Critic
    Perl::Tidy
    PLS
)

PUB_PACKAGES=(
    #dart_ctags
    dart_language_server
    devtools
    webdev
)

COMPOSER_PACKAGES=(
    #friendsofphp/php-cs-fixer
    #phpactor/phpactor
    #phploc/phploc
    #phpmd/phpmd
    #phpstan/phpstan
    #sebastian/phpcpd
    #squizlabs/php_codesniffer
)

GO_PACKAGES=(
    #github.com/technosophos/dashing@latest
    github.com/go-delve/delve/cmd/dlv@latest
    github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    github.com/mattn/efm-langserver@latest
    github.com/mgechev/revive@latest
    golang.org/x/tools/gopls@latest
    mvdan.cc/sh/v3/cmd/shfmt@latest
)

RUSTUP_COMPONENTS=(
    #llvm-tools-preview
    clippy
    rust-analyzer
    rust-src
)

CARGO_PACKAGES=(
    #cargo-audit
    #cargo-c
    #cargo-docset
    #cargo-duplicates
    #cargo-edit
    #cargo-expand
    #cargo-make
    #cargo-outdated
    #cargo-watch
    #evcxr_repl
    #simple-http-server
)

if [[ ${RUBY_GEMS[*]} ]]; then
    echo "Installing Ruby gems"

    # Fix for Xcode toolchain's Ruby 12.3 on Catalina.
    if [[ "v$MACOS_VERSION" == "v10.15"* ]]; then
        (test -d "$(xcode-select -p)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/include/ruby-2.6.0" \
            && cd "$_" && sudo ln -s universal-darwin20 universal-darwin19 2>/dev/null)
        (test -d "$(xcode-select -p)/SDKs/MacOSX.sdk/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/include/ruby-2.6.0" \
            && cd "$_" && sudo ln -s universal-darwin20 universal-darwin19 2>/dev/null)
    fi

    for pkg in "${RUBY_GEMS[@]}"; do
        sudo gem install "$pkg"
    done
fi

if [[ $(brew ls --versions python) && ${PIP3_PACKAGES[*]} ]]; then
    echo "Installing Python3 packages..."
    python3 -m pip install --upgrade pip
    for pkg in "${PIP3_PACKAGES[@]}"; do
        python3 -m pip install "$pkg"
    done
fi

if [[ $(brew ls --versions python@2) && ${PIP2_PACKAGES[*]} ]]; then
    echo "Installing Python2 packages..."
    python -m pip install --upgrade pip setuptools
    for pkg in "${PIP2_PACKAGES[@]}"; do
        python -m pip install "$pkg"
    done
fi

if [[ $(brew ls --versions npm) && ${NPM_PACKAGES[*]} ]]; then
    echo "Installing Nodejs packages..."
    for pkg in "${NPM_PACKAGES[@]}"; do
        npm install -g "$pkg"
    done
fi

if [[ $(brew ls --versions cpanm) && ${CPAN_PACKAGES[*]} ]]; then
    echo "Installing CPAN packages..."
    for pkg in "${CPAN_PACKAGES[@]}"; do
        cpanm "$pkg"
    done
fi

if [[ -x ~/flutter/bin/dart && ${PUB_PACKAGES[*]} ]]; then
    echo "Installing pub packages..."
    for pkg in "${PUB_PACKAGES[@]}"; do
        ~/flutter/bin/dart pub global activate "$pkg"
    done
fi

if [[ $(brew ls --versions composer) && ${COMPOSER_PACKAGES[*]} ]]; then
    echo "Installing Composer packages..."
    for pkg in "${COMPOSER_PACKAGES[@]}"; do
        composer global require "$pkg"
    done
fi

if [[ $(brew ls --versions go) && ${GO_PACKAGES[*]} ]]; then
    echo "Installing Go packages..."
    for pkg in "${GO_PACKAGES[@]}"; do
        go install "$pkg"
    done
fi

if [[ $(brew ls --versions rustup) ]]; then
    rustup-init --default-toolchain nightly -y --no-modify-path

    if [[ ${RUSTUP_COMPONENTS[*]} ]]; then
        echo "Installing Rust components..."
        for pkg in "${RUSTUP_COMPONENTS[@]}"; do
            rustup component add "$pkg"
        done
    fi

    if [[ ${CARGO_PACKAGES[*]} ]]; then
        echo "Installing Cargo packages..."
        for pkg in "${CARGO_PACKAGES[@]}"; do
            cargo install "$pkg"
        done
    fi
fi

# .........................................................................}}}

secrets

# Restore dotfiles.
(
    test -d ../dotfiles && pushd "$_" || exit
    find . -type d -depth 1 \
        -not \( -name ".*" -or -name "*.nostow" -or -name "windows" \) \
        -print0 | xargs -0 basename | xargs stow
)

# Install neovim plugins.
test ! -e ~/.vim/swap && mkdir "$_"
test ! -e ~/.vim/undo && mkdir "$_"
git clone --depth 1 https://github.com/wbthomason/packer.nvim \
    ~/.local/share/nvim/site/pack/packer/start/packer.nvim
git clone --depth 1 https://github.com/rktjmp/hotpot.nvim \
    ~/.local/share/nvim/site/pack/packer/start/hotpot.nvim
nvim --headless -c 'autocmd User PackerComplete qa' +PackerSync

# Install tmux plugins.
test -x ~/.tmux/plugins/tpm/bin/install_plugins && "$_"

echo "Installing Quicklook & Services..."
find "$ICLOUD_DRIVE/.config/Apps/Quicklook" -name '*.qlgenerator' -maxdepth 1 -exec cp -a -n {} "$HOME/Library/Quicklook/" \;
find "$ICLOUD_DRIVE/.config/Apps/Services"  -name '*.workflow'    -maxdepth 1 -exec cp -a -n {} "$HOME/Library/Services/"  \;

secrets post

echo
echo "Done"
exit

__DATA__
# Brewfile ...............................................................{{{1

tap "homebrew/core"
tap "homebrew/bundle"
tap "homebrew/services"
tap "homebrew/cask"
tap "homebrew/cask-fonts"
tap "homebrew/cask-versions"

tap "aws/tap"
tap "clojure-lsp/brew"
tap "koekeishiya/formulae"
tap "universal-ctags/universal-ctags"

# Core
brew "cowsay"
brew "fortune"
brew "neovim"
brew "rsync"
brew "stow"
brew "telnet"
brew "tmux"
brew "tree"
brew "watch"
brew "wget"

# Utilities
brew "archey"
brew "asciinema"
brew "bat"
brew "broot"
brew "cloc"
brew "entr"
brew "fd"
brew "fdupes"
brew "fzf"
brew "ghq"
brew "git-delta"
brew "httpie"
brew "jq"
brew "ncdu"
brew "rclone"
brew "rename"
brew "ripgrep"
brew "terminal-notifier"
brew "trash"
brew "universal-ctags/universal-ctags/universal-ctags", args: ["HEAD"]
brew "youtube-dl"
brew "z"

# Compilers
brew "clojure"
brew "deno"
brew "discount"
brew "go"
brew "lua"
brew "node"
brew "perl"
brew "python"
brew "rustup-init"
brew "scala"

# Package managers and build systems
brew "composer"
brew "cpanminus"
brew "leiningen"
brew "luarocks"
brew "wasm-pack"

# Linters and formatters
brew "clojure-lsp/brew/clojure-lsp-native"
brew "shellcheck"
brew "texlab"

# Security
brew "nmap"

# Storage
brew "git"

# DevOps
brew "aws/tap/aws-sam-cli"
brew "awscli"
brew "minikube"
brew "terraform"

# Conversion
brew "ffmpeg"
brew "graphviz"

# Essentials
cask "iterm2"
cask "karabiner-elements"
cask "keka"
cask "kekaexternalhelper"
cask "opera"

# Tiling window manager
cask "amethyst"

# Window Tools
cask "spectacle"

# QuickLook
cask "qlmarkdown"
cask "qlmobi"
cask "qlstephen"
cask "quicklook-json"

# Security
cask "macpass"
cask "tunnelblick"

# Development
cask "android-studio"
cask "bit-slicer"
cask "boop"
cask "cutter"
cask "goland"
cask "hex-fiend"
cask "meld"
cask "vimr"
cask "visual-studio-code"

# Storage
cask "db-browser-for-sqlite"
cask "gitup"
cask "robo-3t"
cask "sequel-ace"

# DevOps
cask "docker"

# Multimedia
cask "anki"
cask "basictex"
cask "drawio"
cask "iina"
cask "kap"
cask "sf-symbols"

# Communication
cask "skype"

# osxfuse
cask "osxfuse"
brew "sshfs"
brew "gocryptfs"

# Fonts
cask "font-clear-sans"
cask "font-fira-code-nerd-font"
cask "font-inconsolata"
cask "font-metropolis"
cask "font-monoid"
cask "font-work-sans"

# .........................................................................}}}

