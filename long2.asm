section .data
	msg db "maam",0

	format db "palindrome ",10,0
	format1 db "not palindrome ",10,0
section .text
	global main
	extern puts
main:
	mov esi,msg
	mov edi,msg
loop:
	mov ebx,dword[edi]
	cmp ebx,256
	jz compare
	inc edi
	jmp loop
compare:
	dec edi
check:
	mov eax,dword[esi]
	mov ebx,dword[edi]
	cmp ecx,ebx
	jnz false
	cmp esi,edi
	mov edx,dword[format]
	jz true
	inc esi
	dec edi
	mov edx,dword[format1]
	jmp check
true:
	add esp,4
	jmp end
false:
	add esp,4
end:	ret
