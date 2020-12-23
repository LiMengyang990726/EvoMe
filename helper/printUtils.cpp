#include <iostream>
#include <string>
#include <unordered_map>
#include <cstring>
#include <vector>
#include <sstream>
#include "printUtils.h"
#include "symbolStore.h"
#include "utils.h"
using namespace std;
#define CURRENT_VERSION "\"831fcb0\""

void printTemplate() {
    cout << "#include \"types.dl\"" << endl;
    cout << "#include \"objectMapping.dl\"" << endl;
    cout << "#define __VERSION " << CURRENT_VERSION << endl << endl; 
}

void printDecl(string type) {
    cout << ".decl " << type << QLObjToDLDecl(type) << endl;
}

void printOutputDecl(string type) {
    cout << ".decl " << getOutputVar() << QLObjToDLOutput(type) << endl;
}

void printInput(string type) {
    cout << ".input " << type << endl << endl;
}

void printOutput() {
    cout << ".output " << getOutputVar() << endl;
}

void printRuleBegin() {
    cout << getOutputVar() << QLObjToDLRuleBegin(findVarDeclaration(getOutputVar())) << ":- ";
}

void printRuleTermination() {
    cout << "." << endl << endl;
}

void printRule(string name, string field, string value) {
    string type = findVarDeclaration(name);

    string varRange = findVarRange(name);

    string ruleReference = findRuleReference(name);
    bool isReferenced = !ruleReference.empty();

    string fields = QLObjToDLDecl(type);
    vector<pair<string, string> > fieldsVector = destructDLDecl(fields);

    string result = type;
    result += "(";
    for (pair<string, string> fieldPair : fieldsVector) {
        string currFieldCharP = fieldPair.first.c_str();
        if (currFieldCharP == field) {
            if (value.empty()) {
                result += field;
            } else {
                result += value;
            }
        } else if (currFieldCharP == "version") {
            if (varRange.empty() || varRange == CURRENT_VERSION) {
                result += "__VERSION"; 
            } else {
                result += varRange;
            }
        } else if (isReferenced) {
            result += ruleReference;
        } else if (currFieldCharP == "fqn") {
            result += "fqn";
        } else {
            result += "_";
        }
        result += ",";
    }
    result[result.length()-1] = ')';
    cout << result;
}
