#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#define pl printf("\n------------------------------------------------------------------------------\n");
#define phead pl;printf("Symbol\t\tAddress\t\tSize\t\tSection\t\tDef/Undef");pl;

struct node{
	char *sym;
	int size;
	int address;
	char *values;	
	char sect;	
	char def;
	struct node *left;
	struct node *right;
};

struct node* root=NULL;
struct node* head=NULL;

struct node* insert(struct node* point, char *sym, int size, int address, char *values, char sect, char def)
{
	if(point==NULL){
		struct node* tmp=(struct node*)malloc(sizeof(struct node));
		tmp->sym=strdup(sym);
		tmp->size=size;
		tmp->address=address;
		tmp->values=NULL;
		if(values)tmp->values=strdup(values);
		tmp->sect=sect;
		tmp->def=def;
		tmp->left=NULL;
		tmp->right=NULL;
		return tmp;
	}
	else if(strcmp(sym, point->sym)<0)
	{
		point->left=insert(point->left,sym,size,address,values,sect,def);
	}
	else if(strcmp(sym, point->sym)>0)
	{
		point->right=insert(point->right,sym,size,address,values,sect,def);
	}
	else if(strcmp(sym, point->sym)==0)
	{
		point->def = def;
		if(point->sect=='t') point->address=address;
	}
	return point;
}

struct node* search(struct node* point, char *sym)
{
	if(point==NULL){
		return NULL;
	}
	else if(strcmp(sym, point->sym)<0)
	{
		return search(point->left,sym);
	}
	else if(strcmp(sym, point->sym)>0)
	{
		return search(point->right,sym);
	}
	else if(strcmp(sym, point->sym)==0) return point;
}

void print(struct node* tmp)
{
	if(tmp)
	{
		print(tmp->left);
		if(tmp->sym[0]!=';')
		printf("%s\t\t%08X\t %d\t\t   %c\t\t   %d\n",tmp->sym, tmp->address, tmp->size, tmp->sect, tmp->def);
		print(tmp->right);
	}
}
