
#include <iostream>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <cstring>
#include <vector>
#include <sstream>
#include "symbolStore.h"
#include "populateMainDL.h"
#include "utils.h"
using namespace std;

unordered_map<string, string> symbolTable;
unordered_map<string, string> varDeclarationTable;
vector<string> versionDeclarationVec;
unordered_map<string, string> versionVarAssocTable;
unordered_map<string, string> ruleReferenceTable;
unordered_map<string, unordered_map<string, string> > varFeildReferenceTable;
unordered_set<string> typeDeclarationSet;
unordered_set<string> outputVars;
unordered_set<string> notExistSpecifiedVariable;

/* APIs for Symbol Table */
void initializeSymbolTable() {
   symbolTable["MethodAccess"] = "(caller: String, getMethod: String, version: Version)";
   symbolTable["Method"] = "(method: String, getName: String, getClassName: String, getNumberOfParams: number, getReturn: String, isConstructor: String, version: Version)";
   symbolTable["AbstractClass"] = "(fqn: String, version: Version)";
   symbolTable["Reference"] = "(referer: String, getReferee: String, version: Version)";
   symbolTable["Version"] = "(version: Version)";
   return;
}

string getIdName(string type) {
   vector<pair<string, string> > fieldPairs = destructDLDecl(symbolTable[type]);
   if (fieldPairs.size() == 0 || fieldPairs[0].second != "String") {
      yyerror("There is something wrong during the translation process: type does not have id field");
   }
   return fieldPairs[0].first;
}

string QLObjToDLDecl(string key) {
   string result = "";
   if (symbolTable.find(key) != symbolTable.end()) {
      result = symbolTable[key];
   } 
   return result;
}

string QLObjToDLOutput(unordered_set<string> outputVars) {
   vector<pair<string, string> > resultPairs;
   for (auto iter = outputVars.begin(); iter != outputVars.end(); iter++) {
      string type = findVarDeclaration(*iter);
      if (symbolTable.find(type) != symbolTable.end()) {
         string intermediateResult = symbolTable[type];
         vector<pair<string, string> > fieldPairs = destructDLDecl(intermediateResult);
         // resultPairs.push_back(make_pair(fieldPairs.begin()->first, fieldPairs.begin()->second));
         for (auto it = fieldPairs.begin(); it != fieldPairs.end(); it++) {
            if (it->first == "version") {
               if (type == "Version") {
                  resultPairs.push_back(make_pair(it->first, it->second));
               }
               continue;
            } else if (it->first == getIdName(type)) {
               resultPairs.push_back(make_pair(it->first, it->second));
            }
         }
      }
   }
   return constructDLDecl(resultPairs);
}

string QLObjToDLRuleBegin(unordered_set<string> outputVars) {
   vector<string> resultPairs;
   for (auto iter = outputVars.begin(); iter != outputVars.end(); iter++) {
      string type = findVarDeclaration(*iter);
      if (symbolTable.find(type) != symbolTable.end()) {
         string intermediateResult = symbolTable[type];
         vector<pair<string, string> > fieldPairs = destructDLDecl(intermediateResult);
         // resultPairs.push_back(fieldPairs.begin()->first);
         for (auto it = fieldPairs.begin(); it != fieldPairs.end(); it++) {
            if (findVarFieldReferredName(*iter, fieldPairs[0].first) != "") {
               resultPairs.push_back(findVarFieldReferredName(*iter, getIdName(type)));
            } else if (it->first == "version" && type == "Version") {
               resultPairs.push_back(*iter);
            }
         }
      }
   }
   return constructDLRuleBegin(resultPairs);
}

/* APIs for Var Declaration Table */
void storeVarDeclarationTable(string type, string name) {
   varDeclarationTable[name] = type;
}

string findVarDeclaration(string name) {
   string result = "";
   if (varDeclarationTable.find(name) != varDeclarationTable.end()) {
      result = varDeclarationTable[name];
   } 
   return result;
}

/* APIs for Version Declaration Table */
void storeVersionDeclarationTable(string name) {
   versionDeclarationVec.push_back(name);
}

bool findVersionDeclaration(string name) {
   for (int i = 0; i < versionDeclarationVec.size(); i++) {
      if (versionDeclarationVec[i] == name) {
         return true;
      }
   }
   return false;
}

vector<string> getVersions() {
   return versionDeclarationVec;
}

/* APIs for Version Variable Association Table */
void storeVersionVarAssociationTable(string version, string name) {
   versionVarAssocTable[name] = version;
}

string findVersionVarAssociation(string name) {
   string result = "";
   if (versionVarAssocTable.find(name) != versionVarAssocTable.end()) {
      result = versionVarAssocTable[name];
   } 
   return result;
}

/* APIs for Which field of a variable is referred */
void storeVarFieldReferenceTable(string referred, string referer) {
   size_t pos = 0;
   vector<string> tokens; 
   while ((pos = referred.find(".")) != std::string::npos) {
      tokens.push_back(referred.substr(0, pos));
      referred.erase(0, pos + 1);
   }
   tokens.push_back(referred);

   if (tokens.size() == 2) {
      varFeildReferenceTable[tokens[0]][tokens[1]] = referer;
   } else {
      yyerror("Invalid function call");
   }
}

string findVarFieldReferredName(string name, string field) {
   unordered_map<string, string> referredFieldName = varFeildReferenceTable[name];
   if (referredFieldName.size() == 0) {
      return "";
   }

   if (referredFieldName.find(field) == referredFieldName.end()) {
      return "";
   }

   return referredFieldName[field];
}

/* APIs for avoiding redundant declaration */
void storeDeclaredType(string type) {
   typeDeclarationSet.insert(type);
}

bool isTypeDeclared(string type) {
   return (typeDeclarationSet.find(type) != typeDeclarationSet.end());
}

/* APIs for handling output related things */
void storeOutputVar(string output) {
    outputVars.insert(output);
}

unordered_set<string> getOutputVars() {
   return outputVars;
}

/* APIs for storing and searching in NOT EXIST reasoning opts in WHERE clause */
void storeNotExistSpecifiedVariable(string name) {
   notExistSpecifiedVariable.insert(name);
}

void clearNotExistSpecifiedVariable() {
   notExistSpecifiedVariable.clear();
}

bool isVariableSpecifiedInNotExist(string name) {
   return (notExistSpecifiedVariable.find(name) != notExistSpecifiedVariable.end());
}
