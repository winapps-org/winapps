class Winapps < Formula
  desc "Run Windows apps on macOS via RDP RemoteApp"
  homepage "https://github.com/dingyifei/winapps-macos"
  url "https://github.com/dingyifei/winapps-macos.git", branch: "main"
  version "1.0.0"
  license "GPL-3.0-only"

  depends_on "bash"    # setup.sh uses bash 4+ features (declare -A, readarray)
  depends_on "dialog"  # interactive installer menus
  depends_on "freerdp" # installer uses xfreerdp (RemoteApp requires X11 backend, not SDL)
  depends_on :macos

  def install
    # Install main launcher
    bin.install "bin/winapps"

    # Install setup script
    bin.install "setup.sh" => "winapps-setup"

    # Install app definitions
    pkgshare.install "apps"

    # Install Windows-side scripts
    pkgshare.install "install"
  end

  def caveats
    <<~EOS
      WinApps requires:
      1. Microsoft "Windows App" from the Mac App Store
      2. A Windows machine with RDP and RemoteApp enabled

      Create a configuration file:
        mkdir -p ~/.config/winapps
        cat > ~/.config/winapps/winapps.conf << 'EOF'
        RDP_IP=<your-windows-ip>
        RDP_USER=<your-windows-user>
        RDP_PASS=<your-windows-password>
        EOF
        chmod 600 ~/.config/winapps/winapps.conf

      Then run the installer to detect Windows apps:
        winapps-setup --user

      See: #{homepage}/blob/main/docs/macOS.md
    EOS
  end

  test do
    assert_match "winapps", shell_output("#{bin}/winapps 2>&1", 1)
  end
end
