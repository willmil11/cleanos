echo "This script requires gcc, nasm and qemu-system to run."
echo "Please run the reset.sh script after running this one :)"
echo "--"
echo "Building..."
nasm -f bin boot.asm -o boot.bin
gcc -m32 -ffreestanding -fno-pic -nostdlib -c kernel.c -o kernel.o
ld -m elf_i386 -Ttext 0x1000 kernel.o --oformat binary -o kernel.bin
cat boot.bin kernel.bin > os.img
echo "Built"
echo "Running..."
qemu-system-x86_64 -drive format=raw,file=os.img