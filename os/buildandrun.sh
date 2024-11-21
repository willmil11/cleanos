echo "This script requires gcc, nasm, and qemu-system to run."
echo "Please run the reset.sh script after running this one :)"
echo "--"
echo "Building..."
nasm -f bin boot.asm -o boot.bin
gcc -m32 -ffreestanding -fno-pic -nostdlib -c kernel.c -o kernel.o
ld -m elf_i386 -Ttext 0x1000 kernel.o --oformat binary -o kernel.bin
cat boot.bin kernel.bin > os.img
echo "Built"
echo "Verifying kernel offset..."
xxd os.img | grep -A 10 "0000200"   # Check if kernel starts at Sector 2
echo "Running..."
qemu-system-i386 -drive format=raw,file=os.img
