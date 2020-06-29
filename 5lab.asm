.model small
.stack 100h

.data
    file_name db 80 dup(0)
    fileId dw 0  
    numbers dw 0
    
    string_word db 80 dup('$')
    
    buffer db ?
    found_msg db 'Found searchable word in line',0dh,0ah,'$'
    enter_string_word db 'Enter word to search:',0dh,0ah,'$'
    new_line db 0dh,0ah,'$'
    count db 'Number of lines contains such word:$'
    no_lines db 'No lines which have such word in this file$' 
    end_file_msg db 'End file!',0dh,0ah,'$'
    files_error_msg db 'Error create or open files',0dh,0ah,'$'
    cmd_error_msg db 'Error cmd arguments',0dh,0ah,'$' 
    finish_program db 'End program',0dh,0ah,'$'
.code
.386

print macro out_str
    mov ah,9
    mov dx,offset out_str
    int 21h
endm



getFileName proc
    pusha 
    mov di,offset file_name
    xor ax,ax
    xor cx,cx 
    mov si,80h
    mov cl,es:[si];
    cmp cl,0
    je cmdError
    add si,2
    mov al,es:[si]
    cmp al,' '
    je cmdError
    cmp al,0dh
    je cmdError
copyCmd:
    mov ds:[di],al ;copy to file_name
    inc di
    inc si
    mov al,es:[si]
    cmp al,' '
    je cmdError
    cmp al,0dh
    je endCmd
    loop copyCmd
cmdError:
    print cmd_error_msg 
    jmp exit
endCmd: 
    mov byte ptr ds:[di],'$'
    popa
    ret      
getFileName endp   
 
 
enterString proc                                            
    pusha 
    print enter_string_word
    xor ax,ax
    mov ah,0ah
    mov dx,offset string_word
    int 21h
    print new_line
    popa
    ret
enterString endp   


openFile proc                                    
    pusha     
    xor cx,cx
    mov dx,offset file_name
    mov ah,3dh;open existing
    mov al,0;open for read 
    int 21h
    jc error_in_files; if cf=1   
    mov fileId,ax
    jmp success_in_files 
error_in_files:
    print files_error_msg     
    jmp exit
success_in_files:   
    popa
    ret
openFile endp


main_read_file proc                                    
    pusha 
new_str:
    mov si,2    
skip_endl:    
    mov ah,3fh 
    mov bx,fileId 
    mov cx,1 
    mov dx,offset buffer 
    int 21h
    cmp ax,cx ;if ax<cx => end of file
    jnz end_file_found 
    cmp buffer,0ah 
    je skip_endl
    cmp buffer,0dh 
    je skip_endl  
new_word:
    cmp buffer,' '
    jne x
    mov ah,3fh
    mov bx,fileId
    mov cx,1
    mov dx,offset buffer
    int 21h      
    cmp ax,cx
    jnz end_file_found   
    jmp new_word
x:
    mov bl,buffer
    cmp string_word[si],bl 
    jnz bad_symbol
good_symbol:
    mov ah,3fh ; read from file
    mov bx,fileId            
    mov cx,1
    mov dx,offset buffer
    int 21h     
    cmp ax,cx
    jnz end_file_found     
    inc si
    cmp string_word[si],0dh 
    je final_check
    jmp x            
bad_symbol:
    mov si,2
a:
    cmp buffer,0dh 
    je new_line_found
    mov ah,3fh
    mov bx,fileId
    mov cx,1
    mov dx,offset buffer
    int 21h  
    cmp ax,cx
    jnz end_file_found    
    cmp buffer,' '
    je new_word
    jmp a  
final_check:
    cmp buffer,' '
    je found
    cmp buffer,0dh
    je found
    jmp bad_symbol
found:
    inc numbers  
to_new_str:
    mov ah,3fh
    mov bx,fileId
    mov cx,1
    mov dx,offset buffer
    int 21h  
    cmp ax,cx
    jnz end_file_found
    cmp buffer,0ah
    je new_str
    jmp to_new_str
new_line_found:  
    jmp new_str     
end_file_found:
    print end_file_msg       
end_main_read_file:         
    popa                                    
    ret
main_read_file endp    


to_string proc 
    pusha
    xor cx,cx
    mov bx,10
again:
    xor dx,dx
    div bx
    inc cx
    push dx
    cmp ax,0
    jne again
loop_output:
    pop dx
    add dx,30h; '0'
    cmp dx,39h
    jle less_than_nine
    add dx,7
less_than_nine:
    mov ah,2
    int 21h
    loop loop_output
    popa  
    ret
to_string endp


start:
    mov ax,@data
    mov ds,ax
    call getFileName
    print new_line  
    call enterString
    call openFile   
    call main_read_file
    mov ax,numbers
    cmp ax,0
    je no_such_lines 
    print count  
    mov ax,numbers  
    call to_string 
    print new_line     
    jmp exit
no_such_lines:
    print no_lines
    print new_line    
exit: 
    print finish_program
    mov ah,4ch
    int 21h
end start