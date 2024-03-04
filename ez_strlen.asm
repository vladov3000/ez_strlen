; ez_strlen
; By vladov3000

; Demonstrating the power of complex instruction sets (CISCs) by implementing
; strlen in less instructions. Includes a simple benchmark. Macho x86_64 only.

; From the benchmark, it seems as though the clever solutions is 10 times slower.
; Likely because it has to be decoded into microcode, decreasing the throughput
; of the processor's front end.

; To assemble and run:
; 	$ nasm nasm -fmacho64 ez_strlen.asm -o ez_strlen.o
;       $ ld -lSystem ez_strlen.o -o ez_strlen
;       $ ./ez_strlen
;
; I had to pass in the additional linker flags below to get it work on my system:
; 	-L/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/\
;	Developer/SDKs/MacOSX.sdk/usr/lib/ -platform_version macos 12.0.0 12.0


global _main

extern _exit
extern _mach_absolute_time
extern _mach_timebase_info
extern _write

; The amount of times we should compute the string length in the benchmark.
%define BENCHMARK_COUNT 100000000

%define STDOUT_FILENO 1

section .text

; Prints a number to standard output.
; Inputs:
; 	- rdi: the number to print
print_number:	
	push rbp
	mov  rbp, rsp
	sub  rsp, 32

	lea rsi, [rbp - 1]
	mov rax, rdi
	mov rcx, 10

	mov byte [rsi], 10

print_number_loop:
	mov  rdx, 0
	div  rcx
	dec  rsi
	mov  [rsi], dl
	add  byte [rsi], '0'
	test rax, rax
	jnz  print_number_loop

	mov rdi, STDOUT_FILENO
	mov rdx, rbp
	sub rdx, rsi
	call _write
	
	mov rsp, rbp
	pop rbp	
	ret

; Computes the length of a null-terminated string using a loop.
; Inputs:
; 	- rdi: the address of the string
; Outputs:
;	- rax: the size of the string
strlen_loop:	
	mov  rsi, -1
strlen_loop_inner:
	mov  al, [rdi]
	inc  rdi
	inc  rsi
	test al, al
	jnz  strlen_loop_inner	
	mov  rax, rsi
	ret

; Computes the length of a null-terminated string using a clever rep instruction.
; Inputs:
; 	- rdi: the address of the string
; Outputs:
;	- rax: the size of the string
strlen_rep:	
	mov rsi, rdi
	mov al, 0
	repne scasb
	mov rax, rdi
	sub rax, rsi
	dec rax
	ret

; Runs a benchmark with only a single string.
benchmark:	
	push rbp
	mov rbp, rsp

	call _mach_absolute_time
	mov [rel start], rax

	mov qword [rel benchmark_count], BENCHMARK_COUNT

benchmark_loop:	
	lea rdi, [rel message]
	lea rcx, [rel current_benchmark]
	call [rel current_benchmark]

	dec qword [rel benchmark_count]
	jnz benchmark_loop

	call _mach_absolute_time
	sub rax, [rel start]

	mov rdx, 0
	mov ecx, dword [rel timebase]
	mul rcx
	mov rdx, 0
	mov ecx, dword [rel timebase + 4]
	div rcx

	mov  rdi, rax
	call print_number

	mov rsp, rbp
	pop rbp
	ret

_main:	
	push rbp
	mov rbp, rsp
	sub rsp, 16
	
	lea rdi, [rel timebase]
	call _mach_timebase_info

	lea rdi, [rel strlen_loop]
	mov [rel current_benchmark], rdi
	call benchmark

	lea rdi, [rel strlen_rep]
	mov [rel current_benchmark], rdi
	call benchmark

	mov rsp, rbp
	pop rbp
	ret

message:	
	db "hello world", 0

section .data

current_benchmark:	
	dq 0

timebase:	
	times 2 dd 0

start:	
	dq 0

benchmark_count:	
	dq 0
