%{
#include "y.tab.h"
#include "binaryTree.h"
#include "linked.h"
#include<stdio.h>
#include<math.h>
#define eq(a,b) (!strcmp(a,b))
#define printAddr fprintf(f,"%08X ",address);
#define makeMod(a,b,c)  (((unsigned char)(a)<<6)|((unsigned char)(b)<<3)|((unsigned char)(c)));

int yylex();
void yyerror(char*);
FILE *f;
int size=0,address=0,num=0,type=0,count=0,symCount=0;
unsigned char status=0,sec=0,*values,modRm,addr=0,isRegMem=0,isNum=0,isDefined=0,inTable=0;
struct node* tmp; 
remain *rmn;
void addValue(unsigned char *val,int size)
{
	if(size>0){
		count += size;
		values = (unsigned char*)realloc(values,count);
		memcpy(values+(count-size),val,size);
	}
	else{
		values = (unsigned char*)realloc(values,0);
	}

}
void processRemain()
{
	while (lhead != NULL){
		tmp = search(root,lhead->sym);
		if(tmp){
        	for (int i = 0; i < lhead->n; i++) {
			fseek(f,lhead->offset[i],SEEK_SET);
			fprintf(f,"%02hhX",tmp->address - lhead->addr[i]);
		}
    		}
		lhead = lhead->next;
	}
}
%}


%union {
	unsigned char *data;
	int num;
};

%start S
%token OP0 END COLON DIRC COMMA section opn clos dwd
%token <data> SYM OP1 OP2 DbQt SEC 
%token <num> DEF NUM BDEF REG 
%type <data> MEM IMM SOME
%%

S:SYM 
 {
	insert(root,$1,-1,address,NULL,sec,1);
	symCount++;
 } COLON INS 
 |INS
 |DEFN
 |DIR
 |SECT
 |
 ;

DEFN:SYM DEF{ type = $2;} EXT
    {
	
	if(search(root,$1)==NULL){
	//fprintf(f,"%08X  %s  ",address,$1);
	fprintf(f,"%08X   ",address);
	for(int i=0;i<count;i++)fprintf(f,"%02X ",values[i]);fprintf(f,"\n");
	insert(root,$1,count,address,strdup(values),sec,1);
	symCount++;
	address+=count;
	count=0;
	addValue(NULL,-1);
	}
    } 
    |SYM BDEF NUM
    {
	if(search(root,$1)==NULL){
	fprintf(f,"%08X   <res %Xh>\n",address,$2*$3);
	insert(root,$1,$2*$3,address,NULL,sec,1);
	symCount++;
	address+=($2*$3);
	}
    } 
    ; 

DIR:DIRC SYM
    {
	if(search(root,$2)==NULL){
	if(sec!='t')
	fprintf(f,"%08X  %s\n",address,$2);
	insert(root,$2,-1,-1,NULL,sec,0);
	symCount++;
	}
    } 
   ;


SECT:section SEC
    {
	address=0;
	sec = yylval.data[0];
	if(sec=='d')fprintf(f,"\nSection Data\n\n");
	else if(sec=='b')fprintf(f,"\nSection Bss\n\n");
	else if(sec=='t')fprintf(f,"\nSection Text\n\n");
    } 
    ;

INS:OP_2
   |OP_1
   |OP_0
   ;

OP_0:OP0
    {
	printAddr
	fprintf(f,"C3\n");
	address+=1;
	phead;
	print(root);
	pl;
	processRemain();
	fclose(f);
    } 
    ;

OP_1:OP1 REG
    {
	printAddr
	if(eq($1,"mul")){
		modRm = makeMod(3,4,$2);
		fprintf(f,"F7%02X\n",modRm);
		address+=2;
	}
	else if(eq($1,"div")){
		modRm = makeMod(3,6,$2);
		fprintf(f,"F7%02X\n",modRm);
		address+=2;
	}
	else if(eq($1,"inc")){
		fprintf(f,"%02X\n",(64+$2));
		address+=1;		
	}
	else if(eq($1,"dec")){
		fprintf(f,"%02X\n",(72+$2));
		address+=1;		
	}
    } 
    |OP1 SOME
    {
	printAddr
	tmp=search(root,$2);
	if(eq($1,"mul")){
		modRm = makeMod(0,4,5);
		fprintf(f,"F7%02X[%08X]\n",modRm,tmp->address); 
		address+=6;
	}
	else if(eq($1,"div")){
		modRm = makeMod(0,6,5);
		fprintf(f,"F7%02X[%08X]\n",modRm,tmp->address); 
		address+=6;
	}
	else if(eq($1,"inc")){
		modRm = makeMod(0,0,5);
		fprintf(f,"FF%02X[%08X]\n",modRm,tmp->address);
		address+=6;		
	}
	else if(eq($1,"dec")){
		modRm = makeMod(0,1,5);
		fprintf(f,"FF%02X[%08X]\n",modRm,tmp->address);
		address+=6;		
	}
	if(eq($1,"jmp")||eq($1,"jz")||eq($1,"jnz")){
			
		if(eq($1,"jmp")) fprintf(f,"EB");	
		else if(eq($1,"jnz")) fprintf(f,"75");
		else if(eq($1,"jz")) fprintf(f,"74");
		address+=2;

		if(inTable && isDefined) fprintf(f,"%02hhX\n",(tmp->address)-address);	
		else{
			insertOfs($2,ftell(f),address);
			fseek(f,2,SEEK_CUR);
			fprintf(f,"\n");
		}
	}
    }
    ;

SOME:MEM
    {
	$$=$1;
    }
    |IMM
    {
	$$=$1;
    }
    ;

OP_2:OP2 REG COMMA REG
    {
	printAddr
	modRm = makeMod(3,$4,$2);
	if(eq($1,"add")) fprintf(f,"01%02X\n",modRm); 
	else if(eq($1,"sub")) fprintf(f,"29%02X\n",modRm); 
	else if(eq($1,"mov")) fprintf(f,"89%02X\n",modRm); 	
	else if(eq($1,"cmp")) fprintf(f,"39%02X\n",modRm); 
	address+=2;
    } 
    |OP2 REG COMMA MEM
    {
	printAddr
	if(isRegMem==0){
		modRm = makeMod(0,$2,5);
		tmp=search(root,$4);
		int t=$2;
		t+=0xB8;
		if(eq($1,"add")) fprintf(f,"03%02X[%08X]\n",modRm,tmp->address); 
		else if(eq($1,"sub")) fprintf(f,"2B%02X[%08X]\n",modRm,tmp->address); 
		else if(eq($1,"mov")&&addr) fprintf(f,"8B%02X[%08X]\n",modRm,tmp->address); 	
		else if(eq($1,"mov")&&(!addr)){fprintf(f,"%2X[%08X]\n",t,tmp->address);address--;} 	
		else if(eq($1,"cmp")) fprintf(f,"3B%02X[%08X]\n",modRm,tmp->address); 
		address+=6;
	}
	else{
		modRm = makeMod(0,$2,num);
		if(eq($1,"add")) fprintf(f,"03%02X\n",modRm); 
		else if(eq($1,"sub")) fprintf(f,"2B%02X\n",modRm); 
		else if(eq($1,"mov")) fprintf(f,"8B%02X\n",modRm); 	
		else if(eq($1,"cmp")) fprintf(f,"3B%02X\n",modRm); 
		address+=2;
	}

    } 
    |OP2 MEM COMMA REG
    {
	printAddr
	if(isRegMem==0){
		modRm = makeMod(0,$4,5);
		tmp=search(root,$2);
		if(eq($1,"add")) fprintf(f,"01%02X[%08X]\n",modRm,tmp->address); 
		else if(eq($1,"sub")) fprintf(f,"29%02X[%08X]\n",modRm,tmp->address); 
		else if(eq($1,"mov")) fprintf(f,"89%02X[%08X]\n",modRm,tmp->address); 	
		else if(eq($1,"cmp")) fprintf(f,"39%02X[%08X]\n",modRm,tmp->address); 
		address+=6;
	}
	else{
		modRm = makeMod(0,$4,num);
		if(eq($1,"add")) fprintf(f,"01%02X\n",modRm); 
		else if(eq($1,"sub")) fprintf(f,"29%02X\n",modRm); 
		else if(eq($1,"mov")) fprintf(f,"89%02X\n",modRm); 	
		else if(eq($1,"cmp")) fprintf(f,"39%02X\n",modRm); 
		address+=2;
	}
    } 
    |OP2 REG COMMA IMM
    {
	printAddr
	if(isNum==1){
	int t=$2; 
	if(eq($1,"mov")){ 
		t+=0xB8;
		fprintf(f,"%02X%08X\n",t,num);address-=1;
	} 
	else if(eq($1,"sub")){
		 modRm = makeMod(3,5,$2);	
		 if(num<256){fprintf(f,"83%02X%02X\n",modRm,num);address-=3;}
		 else fprintf(f,"81%02X%08X\n",modRm,num);
	}
	else if(eq($1,"add")){
		 modRm = makeMod(3,0,$2);	
		 if(num<256){fprintf(f,"83%02X%02X\n",modRm,num);address-=3;}
		 else fprintf(f,"81%02X%08X\n",modRm,num);
	}	
	else if(eq($1,"cmp")){
		 modRm = makeMod(3,7,$2);	
		 if(num<256){fprintf(f,"83%02X%02X\n",modRm,num);address-=3;}
		 else fprintf(f,"81%02X%08X\n",modRm,num);
	}
	address+=6;
	}
	else{
		tmp=search(root,$4);
		int t=$2; 
		if(eq($1,"mov")){ 
			t+=0xB8;
			fprintf(f,"%02X[%08X]\n",t,tmp->address);address-=1;
		}	 
		else if(eq($1,"sub")){
			 modRm = makeMod(3,5,$2);	
			 fprintf(f,"81%02X[%08X]\n",modRm,tmp->address);
		}
		else if(eq($1,"add")){
			 modRm = makeMod(3,0,$2);	
			 fprintf(f,"81%02X[%08X]\n",modRm,tmp->address);
		}	
		else if(eq($1,"cmp")){
			 modRm = makeMod(3,7,$2);	
			 fprintf(f,"81%02X[%08X]\n",modRm,tmp->address);
		}
		address+=6;
	}
    }
    ;

MEM:dwd opn SYM clos
   {
	isRegMem=0;
	addr=1;
	$$=$3;
	tmp = search(root,$3);
	if(tmp==NULL){
	inTable=0;
	insert(root,$3,-1,address,NULL,sec,0);
	symCount++;
	}else {inTable=1;isDefined=tmp->def;}
   }
   |opn SYM clos
   {
	isRegMem=0;
	addr=1;
	$$=$2;
	tmp = search(root,$2);
	if(tmp==NULL){
	inTable=0;
	insert(root,$2,-1,address,NULL,sec,0);
	symCount++;
	}else {inTable=1;isDefined=tmp->def;}
   }
   |dwd opn REG clos
   {
	isRegMem=1;
	addr=1;
	num=$3;
   }
   |opn REG clos
   {
	isRegMem=1;
	addr=1;
	num=$2;
   }
   ;


IMM: NUM 
   {
	isNum=1;
	addr=0;
	num=$1;
   } 
   | SYM
   {	
	isNum=0;
	addr=0;
	$$=$1;
	tmp = search(root,$1);
	if(tmp==NULL){
	inTable=0;
	insert(root,$1,-1,address,NULL,sec,0);
	symCount++;
	}else {inTable=1;isDefined=tmp->def;}
   }
   ;

EXT:NUM
  {
	if(type!=1)addValue((unsigned char*)&($1),4);
	else{
		unsigned char tmp=$1;
		addValue(&tmp,1);
	}
  }
  |DbQt
  {
	addValue($1,strlen($1));
  }
  |EXT COMMA NUM
  {
	if(type!=1)addValue((unsigned char*)&($3),4);
	else{
		unsigned char tmp=$3;
		addValue(&tmp,1);
	}
  }
  |EXT COMMA DbQt 
  {
	addValue($3,strlen($3));
  }
  ;

%%

void yyerror(char *a){
	yyparse();
}

int main()
{
	root=insert(root,";",0,0,NULL,0,0);
	f=fopen("result","w");
	yyparse();
	return 0;
}
