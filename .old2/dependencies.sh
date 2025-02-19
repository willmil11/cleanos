# Create a directory for OS development
mkdir -p ~/os-dev
cd ~/os-dev

# Install necessary build tools
sudo apt-get update
sudo apt-get install -y build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo wget tar gzip gcc g++ make

# Download required sources
wget https://ftp.gnu.org/gnu/binutils/binutils-2.39.tar.gz
wget https://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.gz

# Extract sources
tar -xzf binutils-2.39.tar.gz
tar -xzf gcc-12.2.0.tar.gz

# Set up environment
export PREFIX="$HOME/os-dev/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"

# Create build directories
mkdir -p build-binutils build-gcc
cd build-binutils

# Configure and build binutils
../binutils-2.39/configure \
    --target=$TARGET \
    --prefix="$PREFIX" \
    --with-sysroot \
    --disable-nls \
    --disable-werror

make -j$(nproc)
make install

# Prepare GCC build
cd ../build-gcc

# Configure GCC
../gcc-12.2.0/configure \
    --target=$TARGET \
    --prefix="$PREFIX" \
    --disable-nls \
    --enable-languages=c \
    --without-headers

make all-gcc -j$(nproc)
make install-gcc

# Add to PATH permanently
echo 'export PATH=$HOME/os-dev/cross/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Verify installation
$HOME/os-dev/cross/bin/i686-elf-gcc --version