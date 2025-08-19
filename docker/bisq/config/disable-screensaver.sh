#!/bin/bash

# Enable strict error handling  
set -euo pipefail

# Disable xfce4-screensaver by creating a no-op script
touch /usr/local/bin/xfce4-screensaver
chmod +x /usr/local/bin/xfce4-screensaver
echo '#!/bin/bash' > /usr/local/bin/xfce4-screensaver
echo 'exit 0' >> /usr/local/bin/xfce4-screensaver
echo "xfce4-screensaver disabled"