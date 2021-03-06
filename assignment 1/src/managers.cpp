#include <bits/stdc++.h>
#include "include/managers.h"
using namespace std;

extern int yylineno;

char* RegisterManager::Names[] = { "bx", "cx", "dx" };//"%rbx", "%rcx", "%rdx","%r8","%r9","%r10","%r11","%r12","%r13","%r14","%r15" }; //"%rax"

RegisterManager::RegisterManager()
{
	isUsed.clear();
	MAX=sizeof(Names)/sizeof(Names[0]);
	freeCount=MAX;
}

int RegisterManager::allocReg()
{
	if(freeCount)
	{
		for(int i = 0; i < MAX; i++)
		{
			if(isFree(i))
			{	
				freeCount--; 
				isUsed.insert(i); 
				fprintf(stderr, "Register %d allocated. freeCount=%d\n", i, freeCount); 
				return i; 
			}
		}
	}
	else
	{
		fprintf(stderr, "ERROR: Expression too complex to handle at %d. Exiting now.\n", yylineno);
		assert(1==0);
	}
	return 0;
}

void RegisterManager::deallocReg(int reg_num)
{
	// if(freeCount == MAX)
	// 	{ fprintf(stderr, "ERROR: %d: All registers already free.\n", yylineno); assert(2==1); }
	if(isFree(reg_num))
		{ fprintf(stderr, "ERROR: Invalid register deallocation at %d. Exiting now.\n", yylineno);assert(2==1);	}
	isUsed.erase(reg_num);
	freeCount++;
	fprintf(stderr, "Register %d deallocated. freeCount=%d\n", reg_num, freeCount);
}

bool RegisterManager::isFree(int reg_num)
{
	set<int>::iterator it = isUsed.find(reg_num);
	if(it == isUsed.end())
		return true;
	return false;
}

string RegisterManager::getRegName(int reg_num)
{
	string t(Names[reg_num]);
	return t;
}

int RegisterManager::checkReg(int regOne, int regTwo)
{
  int reg;
  while ( regOne != 0 ) {
     reg = regOne; regOne = regTwo%regOne;  regTwo = regOne;
  }
  if(reg < MAX && reg > 0 && freeCount)
  	return reg;
  else
  	return -1;
}


LabelManager::LabelManager()
{
	l_count=0;
}

string LabelManager::toString(int num)
{
	stringstream ss;
	ss << num;
	return ss.str();
}

string LabelManager::getLabel()
{
	return "Label" + this->toString(l_count++);
}

string LabelManager::freeLabel()
{
	return "Label" + this->toString(l_count-1); 
}
