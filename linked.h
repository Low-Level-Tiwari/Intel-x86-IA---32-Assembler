#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct remain {
    char* sym;
    int* offset;
    int* addr;
    int n;
    struct remain* next;
} remain;

remain *lhead=NULL;

remain* create(const char* sym) {
    remain* new_sym = (remain*)malloc(sizeof(remain));
    new_sym->sym = strdup(sym); 
    new_sym->offset = NULL;
    new_sym->addr = NULL;
    new_sym->n = 0;
    new_sym->next = NULL;
    return new_sym;
}
remain* searchRemain(char *sym){
	remain *tmp = lhead;
	while(tmp)
	{
		if(!strcmp(tmp->sym,sym))break;
		tmp=tmp->next;
	}
	return tmp;

}
void add_offset(remain* sym, int off,int lc) {
    	sym->offset = (int*) realloc(sym->offset, (sym->n + 1) * sizeof(int));
    	sym->offset[sym->n] = off;
	sym->addr = (int*) realloc(sym->addr, (sym->n + 1) * sizeof(int));
    	sym->addr[sym->n] = lc;
    	sym->n++;
}

void insertOfs(char* sym, int off, int lc) {
    remain* tmp = lhead;
    while (tmp != NULL) {
        if (!strcmp(tmp->sym, sym)) {
		add_offset(tmp,off,lc);
            	return;  
        }
        tmp = tmp->next;
    }
    remain* new_sym = create(sym);
    add_offset(new_sym,off,lc);
    new_sym->next = lhead;
    lhead = new_sym;
}


void printRemain(remain* lhead) {
    while (lhead != NULL) {
        printf("Symbol: %s\n", lhead->sym);
        printf("Offsets: ");
        for (int i = 0; i < lhead->n; i++) {
            printf("(%d,%02hhX) ", lhead->offset[i],lhead->addr[i]);
        }
        printf("\n");
        lhead = lhead->next;
    }
}

void freeRemain(remain* lhead) {
    while (lhead != NULL) {
        remain* temp = lhead;
        lhead = lhead->next;
        free(temp->sym);
        free(temp->offset);
        free(temp->addr);
        free(temp);
    }
}

