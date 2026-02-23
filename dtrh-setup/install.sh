# FOR KALI
# NOTE - requires dtrh-setup.sh in ~/.local/bin
# Then, just run dtrh-setup

# Save it
mkdir -p ~/.local/bin
cat > ~/.local/bin/dtrh-setup << 'EOF'
# ← paste the whole script here
EOF

chmod +x ~/.local/bin/dtrh-setup

# Optional: add alias
echo 'alias dtrh="dtrh-setup"' >> ~/.zshrc
source ~/.zshrc
