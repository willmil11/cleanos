# Cleanos
## What is it?
Cleanos is an os written in Nim with a custom kernel. It's a hobby project of mine to learn how operating systems work and to learn Nim but I expect it to eventually become a real operating system that is actually daily drivable.

## What does it do right now?
Right now it just prints Hello Nim! on the screen but the only reason that it just does that is that I just began the project and wanted to post it to github before continuing building it because I was excited about the project.

## Is this a serious project?
Well, it's for fun, it's a hobby project, you can see how unprofessional the readme is but I feel like there's a high probability that this will become a real operating system someday.

## How to run
### Tested platforms
I tested building and running this os in debian 12 (but in wsl on windows but its basically the same thing).
### Dependencies
I'm not sure what the name of the dependencies exactly are on every platform so I'll just drop how to install them on debian:
```bash
# Add 32-bit architecture support
sudo dpkg --add-architecture i386
sudo apt update

# Core build tools and 32-bit libraries
sudo apt install -y build-essential gcc-multilib g++-multilib 

# Assembler, GRUB tools, emulation, and debugging
sudo apt install -y nasm grub-pc-bin grub-rescue-pc qemu-system-x86 gdb

# Nim installation using choosenim
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
# Note: Ensure to follow the prompts during installation
# You may need to add Nim to your PATH as instructed by the script
```

### Build and run
You can just run `make` to build the os. Then you can run it with `make run`. And clear build artifacts with `make clean`.

And you can also build and run it in one command super easily like that:
```bash
clear && make clean && make && make run
```

## How I'm building this and backstory
I'm a complete beginner to os developpement, normally I only code in python and javascript, I had never touched a statically typed language before this. But I wanted to build an OS and I'm forced to recognize that it's impossible to build an OS in python so I asked Claude what's the closest statically typed language to a dynamically typed one with a clean syntax like python and it said Nim. So I decided to give it a try and I liked it, so I asked Claude to help me build this OS. My plan is to let it build a system with a Canvas that matches the native screen resolution with a function to draw a pixel on it and then I'll do the rest myself using that canvas, it'll be easy as the heavy lifting (base system and canvas setup) will have been done by Claude and I'll just have to build the ui and the part of the os the user sees basically which is pretty easy it's just like harder frontend developpement. For the filesystem I'll let it handle it too (it'll give me a function to create a file, write to it, and delete it). And I hope everything will work out.

## What are .old and .old2 directories?
I didn't mention this in the backstory but previously before all this I already wanted to make an OS once so Claude built a hello world exemple for me in C and it worked but C is hard so I asked it to port it to Rust and it worked too except then I made some edits to some files and it had errors everywhere so I tried to go back to the version that worked but lost it so I gave up. You can see the C version in .old which works and the Rust version in .old2 which doesn't work. And then the events of the backstory happened.

## How you can help me
I like to dev solo with Claude but if you want to help me don't make a pull request I'm not good with git and all but you can contact me on discord at "willmil11" and I'll add you and you can help me there.
