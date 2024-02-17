;Trabalho Intel - Arq1
;Professor Matheus Grellert
;Larissa Furtado Helfer - 00577752
		
		.model small
		.stack

; ########################
; #         DADOS        #
; ########################

		.data

CR			equ		13  				
LF			equ		10  				
SPC			equ		32					
TAB			equ		9	


MAXSTRING 	equ		200 				

String		db		MAXSTRING dup (?)	
sw_n	dw	0 							
sw_f	db	0							
sw_m	dw	0							
FileBuffer		db		10 dup (?)		


CMDLINE 	db 	MAXSTRING dup (0) 
buffer		db	10 dup (0)		
token		db	10 dup (0)

filePtr		dw	0	


inName		db	MAXSTRING dup (?)
outName		db	MAXSTRING dup (?)
tensao		dw	127

aux			dw	0

inDefault	db	"a.in",0
outDefault	db	"a.out",0

flagIn		db 0
flagOut		db 0

numBuffer	db	10 dup (0)

linhas		dw	0			
linhasNulo		dw 	0
linhasValidas	dw	0

erroNmr		db	10 dup (0)

flagErro	db 	0
flagErroGeral	db 	0
flagFimFile	db	0
flagNewLine	db	0

num1 		dw 	0
num2 		dw 	0
num3 		dw 	0

flagNum1	db	0
flagNum2	db	0
flagNum3	db	0

result		db	0
resto		db	0

horas		db	0
minutos 	db 	0
segundos	db 	0

dig1		db	0
dig2		db	0	

failOpen	db	"O arquivo de entrada nao existe.",CR,LF,0
outMsg		db	"Opcao [-o] sem parametro",CR,LF,0
inMsg		db	"Opcao [-i] sem parametro",CR,LF,0
tMsg		db	"Opcao [-v] sem parametro",CR,LF,0
tensaoMsg	db	"Parametro -v invalido. Deve ser 127 ou 220",CR,LF,0
erroMsg		db	"Erro na linha",SPC,0
CRLF		db	CR,LF,0
line		db	"‿︵‿︵‿︵‿︵‿︵‿︵‿︵‿︵‿︵‿︵‿︵",CR,LF,0
par1		db	"Arquivo de entrada:",SPC,0
par2		db	"Arquivo de saida:",SPC,0
par3		db	"Tensao:",SPC,0
tempo1		db	"Tempo total lido:",SPC,0
tempo2		db	"Tempo total de tensao adequada:",SPC,0
tempo3		db	"Tempo total de tensao baixa:",SPC,0


; ########################
; #        CÓDIGO        #
; ########################

		.code
		.startup

; ----------------------------------------------------------------------------------- ;
		push ds ; Salva as informações de segmentos
		push es
		mov ax,ds ; Troca DS com ES para poder usa o REP MOVSB
		mov bx,es
		mov ds,bx
		mov es,ax
		mov si,80h ; Obtém o tamanho do string da linha de comando e coloca em CX
		mov ch,0
		mov cl,[si]
		mov ax,cx ; Salva o tamanho do string em AX, para uso futuro
		mov si,82h ; Inicializa o ponteiro de origem
		lea di,CMDLINE ; Inicializa o ponteiro de destino
		rep movsb	
		pop es ; retorna as informações dos registradores de segmentos
		pop ds
; ----------------------------------------------------------------------------------- ;
		
		call	fileNames

		cmp		flagErroGeral,1
		je		exit

		lea		dx,inName				
		call 	fopen					
		
		jc		errorOpen				
		mov		filePtr,bx				
		
		mov		bx,filePtr

	mainLoopStart:
		mov		bx,filePtr
		call	findNumber			

		cmp		flagErro,1
		jne 	cmpFlagFimFile		

		mov		flagNum1,0
		mov		flagNum2,0
		mov		flagNum3,0

		mov		flagErro,0

		jmp		mainLoopStart

	cmpFlagFimFile:
		cmp		flagFimFile,1
		jne		putNum1

		jmp		fimProg

	putNum1:
		cmp		flagNum1,0
		jne		putNum2

		xor		ax,ax
		lea		bx,numBuffer
		call	atoi
		mov		num1,ax

		mov		flagNum1,1

		cmp		flagNewLine,1
		je		erroLineMsg

		jmp 	mainLoopStart

	putNum2:
		cmp		flagNum2,0
		jne		putNum3

		xor		ax,ax
		lea		bx,numBuffer
		call	atoi
		mov		num2,ax

		mov		flagNum2,1

		cmp		flagNewLine,1
		je		erroLineMsg

		jmp 	mainLoopStart

	putNum3:
		xor		ax,ax
		lea		bx,numBuffer
		call	atoi
		mov		num3,ax

		mov		flagNum3,1

		cmp		flagNewLine,1
		je		trataLinha

		jmp 	mainLoopStart


	trataLinha:			

		mov		flagNum1,0
		mov		flagNum2,0
		mov		flagNum3,0

		call 	trataInfo

		jmp		mainLoopStart


	erroLineMsg:
		mov		flagErroGeral,1

		mov		ah,0

		mov		ax,linhas
		lea		bx,erroNmr
		call	sprintf_w

		lea		bx,erroNmr
		call	printf_s

		lea		bx,CRLF
		call 	printf_s

		mov		flagNum1,0
		mov		flagNum2,0
		mov		flagNum3,0

		jmp		mainLoopStart

	errorOpen:
		lea		bx,failOpen
		call 	printf_s

		.exit

	fimProg:		;coisas pra gerar arquivo out e etc
		cmp		flagErroGeral,1		;se houve qualquer erro na leitura, nao gera a.out
		je		exit

		mov		bx,filePtr
		call	fclose

		lea		dx,outName
		call	fcreate

		mov		filePtr,bx

		call	escreveRlt

	exit:
		.exit

; ########################
; #        FUNCOES       #
; ########################

setString 	proc near

		mov		bx,filePtr

	setStringLoop:
		mov		dl,[si]
		cmp		dl,0
		je		endSetString

		call	setchar
		inc		si

		jmp		setStringLoop

	endSetString:
		ret

setString	endp
		

escreveRlt	proc near		;Escreve coisas no relatorio. Ficou enorme por causa da parte de converter os segundos pra horas e minutos, e pra colocar isso corretamente na tela.

		mov		bx,filePtr
		lea		si,line
		call	setString

		lea		si,par1
		call	setString

		lea		si,inName
		call	setString

		lea		si,CRLF
		call	setString

		lea		si,par2
		call	setString

		lea		si,outName
		call	setString

		lea		si,CRLF
		call	setString

		lea		si,par3
		call	setString

		mov		ax,tensao
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		lea		si,String
		call	setString	

		lea		si,CRLF
		call	setString

		lea		si,line
		call	setString

		;escreve linhas lidas

		lea		si,tempo1
		call	setString
		

		mov		ax,linhas
		mov		dx,0
		mov		cx,3600
		div		cx

		mov		horas,al

		mov		ax,dx
		mov		dx,0
		mov		cx,60
		div		cx 

		mov		minutos,al

		mov		segundos,dl

		mov		al,horas
		mov		ah,0
		mov		dx,0
		mov		cx,10
		div		cx

		mov		dig1,al
		mov		dig2,dl

		mov		al,dig1
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		mov		al,dig2
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		mov		dl,":"
		call	setChar

		mov		al,minutos
		mov		ah,0
		mov		dx,0
		mov		cx,10
		div		cx

		mov		dig1,al
		mov		dig2,dl

		mov		al,dig1
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr	
		mov		dl,String
		call	setChar

		mov		al,dig2
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		mov		dl,":"
		call	setChar

		mov		al,segundos
		mov		ah,0
		mov		dx,0
		mov		cx,10
		div		cx

		mov		dig1,al
		mov		dig2,dl

		mov		al,dig1
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		mov		al,dig2
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar


		lea		si,CRLF
		call	setString

		;-

		lea		si,tempo2
		call	setString

		mov		ax,linhasValidas
		mov		dx,0
		mov		cx,3600
		div		cx

		mov		horas,al

		mov		ax,dx
		mov		dx,0
		mov		cx,60
		div		cx 

		mov		minutos,al

		mov		segundos,dl

		mov		al,horas
		mov		ah,0
		mov		dx,0
		mov		cx,10
		div		cx

		mov		dig1,al
		mov		dig2,dl

		mov		al,dig1
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		mov		al,dig2
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		mov		dl,":"
		call	setChar

		mov		al,minutos
		mov		ah,0
		mov		dx,0
		mov		cx,10
		div		cx

		mov		dig1,al
		mov		dig2,dl

		mov		al,dig1
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr	
		mov		dl,String
		call	setChar

		mov		al,dig2
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		mov		dl,":"
		call	setChar

		mov		al,segundos
		mov		ah,0
		mov		dx,0
		mov		cx,10
		div		cx

		mov		dig1,al
		mov		dig2,dl

		mov		al,dig1
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		mov		al,dig2
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		lea		si,CRLF
		call	setString

		;-

		lea		si,tempo3
		call	setString

		mov		ax,linhasNulo
		mov		dx,0
		mov		cx,3600
		div		cx

		mov		horas,al

		mov		ax,dx
		mov		dx,0
		mov		cx,60
		div		cx 

		mov		minutos,al

		mov		segundos,dl

		mov		al,horas
		mov		ah,0
		mov		dx,0
		mov		cx,10
		div		cx

		mov		dig1,al
		mov		dig2,dl

		mov		al,dig1
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		mov		al,dig2
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		mov		dl,":"
		call	setChar

		mov		al,minutos
		mov		ah,0
		mov		dx,0
		mov		cx,10
		div		cx

		mov		dig1,al
		mov		dig2,dl

		mov		al,dig1
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr	
		mov		dl,String
		call	setChar

		mov		al,dig2
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		mov		dl,":"
		call	setChar

		mov		al,segundos
		mov		ah,0
		mov		dx,0
		mov		cx,10
		div		cx

		mov		dig1,al
		mov		dig2,dl

		mov		al,dig1
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		mov		al,dig2
		mov		ah,0
		lea		bx,String
		call	sprintf_w

		mov		bx,filePtr
		mov		dl,String
		call	setChar

		lea		si,CRLF
		call	setString

		mov		bx,filePtr
		lea		si,line
		call	setString

		ret

escreveRlt	endp


trataInfo	proc near

		cmp		num1,0
		jb		tensaoInv
		cmp		num1,499
		ja		tensaoInv

		cmp		num2,0
		jb		tensaoInv
		cmp		num2,499
		ja		tensaoInv

		cmp		num3,0
		jb		tensaoInv
		cmp		num3,499
		ja		tensaoInv

		;A partir daqui, só valores entre 0 e 499 passaram.

		cmp		tensao,220
		je		tensao220
		
		;tensao = 127

		cmp		num1,117
		jb		num2_127
		cmp		num1,137
		ja		tensaoInv

	num2_127:
		cmp		num2,117
		jb		num3_127
		cmp		num2,137
		ja		tensaoInv

	num3_127:
		cmp		num3,117
		jb		tensaoBaixa
		cmp		num3,137
		ja		tensaoInv

		inc		linhasValidas
		ret


	tensao220:
		cmp		num1,210
		jb		num2_220
		cmp		num1,230
		ja		tensaoInv

	num2_220:
		cmp		num2,210
		jb		num3_220
		cmp		num2,230
		ja		tensaoInv

	num3_220:
		cmp		num3,210
		jb		tensaoBaixa
		cmp		num3,230
		ja		tensaoInv

		inc		linhasValidas
		ret

	tensaoBaixa:
		inc		linhasNulo
		ret

	tensaoInv:
		mov		flagErroGeral,1

		lea		bx,erroMsg
		call	printf_s

		mov		ax,linhas
		lea		bx,erroNmr
		call	sprintf_w

		lea		bx,erroNmr
		call	printf_s

		lea		bx,CRLF
		call 	printf_s

		ret


trataInfo	endp

findNumber	proc near		;encontra e coloca no buffer um numero de uma linha encontrado ate uma virgula

		lea		si,numBuffer
		mov		flagNewLine,0


		findNumLoop:
			call	getchar

			cmp		dl,"f"
			je		fimFile

			cmp		dl,'0'
			jb		findNumLoop			;procura um numero para começar a pega-lo
			cmp		dl, '9'
			ja		findNumLoop

		bufferNumLoop:
			mov		[si],dl
			inc 	si
			call	getchar

			cmp		dl,'0'
			jb		findEnd
			cmp		dl, '9'
			jbe		bufferNumLoop

		findEnd:
			cmp		dl,','
			je		endNumero
			cmp		dl,LF
			je		newLine
			cmp		dl,CR
			je		newLine
			cmp		dl,SPC
			je		loopFindEnd
			cmp		dl,TAB
			je 		loopFindEnd
			cmp		dl,"f"
			je		fimFile

			jmp		erroLine

		loopFindEnd:
			call	getchar
			jmp 	findEnd

		newLine:
			inc 	linhas
			mov		flagNewLine,1

		endNumero:
			inc		si
			mov		[si],0
			ret
			
		erroLine:
			inc 	linhas
			
			lea		bx,erroMsg
			call	printf_s

			mov		ax,linhas
			lea		bx,erroNmr
			call	sprintf_w

			lea		bx,erroNmr
			call	printf_s

			lea		bx,CRLF
			call 	printf_s
			
		erroLineLoop:
			mov		bx,filePtr
			call	getchar
			cmp		dl,CR
			je		fimErroLine
			cmp		dl,LF
			je		fimErroLine

			jmp		erroLineLoop

		fimErroLine:
			mov 	flagErro, 1
			mov		flagErroGeral,1
			ret

		fimFile:
			mov		flagFimFile,1
			ret

findNumber	endp
		


fileNames	proc near

			mov		dx,ds		; Ajusta ES=DS para poder usar o MOVSB
			mov		es,dx

			mov		tensao,127
		
			cmp		[CMDLINE], 0	;se nada estiver escrito, fim
			je		endNames

			lea		ax, CMDLINE

		namesLoop:				;pega um "-o" ou "-i" ou "-t" 
			mov		si,ax
			mov		cx,2
			lea		di,token
			rep		movsb		;passa informação do ax(cmdline)(SI) pra 'token'(DI) 2 vezes
			add		ax,3		;ax guarda nossa posicao atual em CMDLINE. ax+3 representa ax+token+espaco		

			cmp		byte ptr[token], 0
			je		endNames

			cmp		byte ptr[token], '-'
			jne		endNames

			cmp		byte ptr[token+1], 'o'
			je 		fileOut

			cmp		byte ptr[token+1], 'i'
			je 		fileIn

			cmp		byte ptr[token+1], 'v'
			je 		fileTensao

		fileOut:
			mov		flagOut, 1
			lea		di,outName
			mov		si,ax
			cld
			cmp		byte ptr[si],'-'		;Se, após '-o', tiver outro hifen, CR, ou nada
			je 		erroOut
			cmp		byte ptr[si],CR
			je		erroOut
			cmp		byte ptr[si],0
			je		erroOut
			cmp		byte ptr[si],SPC
			je		erroOut

		outLoop:	
			cmp		byte ptr[si], SPC
			je		fileOutEnd
			cmp		byte ptr[si], CR		;voce nao tem nocao do sofrimento que foi pra eu achar o erro aqui. Foi mais de uma hora pra perceber que eu tinha que comparar com "Carriage Return" e não "\0". Um pouco da minha alma ficou aqui.
			je		fileOutEnd
			movsb
			jmp 	outLoop

		erroOut:
			lea		bx,outMsg
			call	printf_s
			mov		flagErroGeral,1
			jmp		namesLoop


		fileOutEnd:			
			inc		di
			mov		byte ptr[di],0

			mov		ax,si		;guardando nossa posição em "CMDLINE"
			inc		ax			;pula o espaco apos a string

			jmp 	namesLoop

		fileIn:
			mov		flagIn, 1
			lea		di,inName
			mov		si,ax
			cld
			cmp		byte ptr[si],'-'		;Se, após '-o', tiver outro hifen, CR, ou nada
			je 		erroIn
			cmp		byte ptr[si],CR
			je		erroIn
			cmp		byte ptr[si],0
			je		erroIn
			cmp		byte ptr[si],SPC
			je		erroIn


		inLoop:	
			cmp		byte ptr[si], SPC
			je		fileInEnd
			cmp		byte ptr[si], CR		
			je		fileInEnd
			movsb
			jmp 	inLoop

		erroIn:
			lea		bx,inMsg
			call	printf_s
			mov		flagErroGeral,1
			jmp		namesLoop

		fileInEnd:
			inc		di
			mov		byte ptr[di],0

			mov		ax,si		;guardando nossa posição em "CMDLINE"
			inc		ax			;pula o espaco apos a string

			jmp 	namesLoop

		fileTensao:
			lea		di,buffer
			mov		si,ax
			cld
			cmp		byte ptr[si],'-'		;Se, após '-o', tiver outro hifen, CR, ou nada
			je 		erroT
			cmp		byte ptr[si],CR
			je		erroT
			cmp		byte ptr[si],0
			je		erroT
			cmp		byte ptr[si],SPC
			je		erroT


		tensaoLoop:	
			cmp		byte ptr[si], SPC
			je		tensaoEnd
			cmp		byte ptr[si], CR		
			je		tensaoEnd
			movsb
			jmp 	tensaoLoop

		erroT:
			lea		bx,Tmsg
			call	printf_s
			mov		flagErroGeral,1
			jmp		namesLoop

		tensaoEnd:
			inc		di
			mov		byte ptr[di],0

			mov		ax,si		;guardando nossa posição em "CMDLINE"
			inc		ax			;pula o espaco apos a string

			mov		aux,ax

			lea 	bx,buffer
			call	atoi

			mov		ah,0

			cmp 	al,127
			je 		tensaoEnd2
			cmp		al,220			
			jne		erroTensao

		tensaoEnd2:
			mov		tensao,ax
			mov		ax,aux
			jmp 	namesLoop

		erroTensao:
			mov		flagErroGeral,1
			lea		bx,tensaoMsg
			call	printf_s
			jmp		namesLoop

		endNames:
			cmp		flagOut,0
			jne		cmpIn

			lea		si,outDefault
			lea		di,outName
			mov		cx,7
			rep 	movsb

		cmpIn:
			cmp		flagIn,0
			jne		endNames2

			lea		si,inDefault
			lea		di,inName
			mov		cx,5
			rep 	movsb

		endNames2:
			ret


fileNames	endp

; Funcoes do Cechin

; atoi: String (bx) -> Inteiro (ax)
atoi	proc near

		; A = 0;
		mov		ax,0
		
atoi_2:
		; while (*S!='\0') {
		cmp		byte ptr[bx], 0
		jz		atoi_1

		; 	A = 10 * A
		mov		cx,10
		mul		cx

		; 	A = A + *S
		mov		ch,0
		mov		cl,[bx]
		add		ax,cx

		; 	A = A - '0'
		sub		ax,'0'

		; 	++S
		inc		bx
		
		;}
		jmp		atoi_2

atoi_1:
		; return
		ret

atoi	endp

; printf_s: String (bx) -> void
printf_s	proc	near

;	While (*s!='\0') {
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

;		putchar(*s)
	push	bx
	mov		ah,2
	int		21H
	pop		bx

;		++s;
	inc		bx
		
;	}
	jmp		printf_s
		
ps_1:
	ret
	
printf_s	endp


; sprintf_w: Inteiro (ax) String (bx) -> void
sprintf_w	proc	near

;void sprintf_w(char *string, WORD n) {
	mov		sw_n,ax

;	k=5;
	mov		cx,5
	
;	m=10000;
	mov		sw_m,10000
	
;	f=0;
	mov		sw_f,0
	
;	do {
sw_do:

;		quociente = n / m : resto = n % m;	// Usar instru  o DIV
	mov		dx,0
	mov		ax,sw_n
	div		sw_m
	
;		if (quociente || f) {
;			*string++ = quociente+'0'
;			f = 1;
;		}
	cmp		al,0
	jne		sw_store
	cmp		sw_f,0
	je		sw_continue
sw_store:
	add		al,'0'
	mov		[bx],al
	inc		bx
	
	mov		sw_f,1
sw_continue:
	
;		n = resto;
	mov		sw_n,dx
	
;		m = m/10;
	mov		dx,0
	mov		ax,sw_m
	mov		bp,10
	div		bp
	mov		sw_m,ax
	
;		--k;
	dec		cx
	
;	} while(k);
	cmp		cx,0
	jnz		sw_do

;	if (!f)
;		*string++ = '0';
	cmp		sw_f,0
	jnz		sw_continua2
	mov		[bx],'0'
	inc		bx
sw_continua2:


;	*string = '\0';
	mov		byte ptr[bx],0
		
;}
	ret
		
sprintf_w	endp

; fopen: String (dx) -> File* (bx) Boolean (CF)		(Passa o File* para o ax tambem, mas por algum motivo ele move pro bx)
fopen	proc	near
	mov		al,0
	mov		ah,3dh
	int		21h
	mov		bx,ax
	ret
fopen	endp

; fcreate: String (dx) -> File* (bx) Boolean (CF)
 fcreate	proc	near
	mov		cx,0
	mov		ah,3ch
	int		21h
	mov		bx,ax
	ret
fcreate	endp

; fclose: File* (bx) -> Boolean (CF)
fclose	proc	near
	mov		ah,3eh
	int		21h
	ret
fclose	endp

; getChar: File* (bx) -> Char (dl) Inteiro (AX) Boolean (CF)
getChar	proc	near
	mov		ah,3fh
	mov		cx,1
	lea		dx,FileBuffer
	int		21h
	mov		dl,FileBuffer
	ret
getChar	endp

; setChar: File* (bx) Char (dl) -> Inteiro (ax) Boolean (CF)
setChar	proc	near
	mov		ah,40h
	mov		cx,1
	mov		FileBuffer,dl
	lea		dx,FileBuffer
	int		21h
	ret
setChar	endp	

		end